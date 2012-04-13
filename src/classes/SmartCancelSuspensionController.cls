/*
 *controller of page cancel suspension 
 */
public class SmartCancelSuspensionController 
{
    private String rescheduleId;
    private CourseReschedule__c courseReschedule;
    
    public SmartCancelSuspensionController()
    {
        IsCancelSuccessed = false;
        rescheduleId = ApexPages.currentPage().getParameters().get('id');
        List<CourseReschedule__c> courseReschedules = [select Id, Status__c, Type__c, Contact__c, Contact__r.EtownMemberId__c, ScheduleJobId__c, ScheduleDate__c from CourseReschedule__c where Type__c = 'Suspend' and Status__c = 'Not start yet' and Id = :rescheduleId and Contact__c != null limit 1];
        if(courseReschedules.size() > 0)
        {
            courseReschedule = courseReschedules[0];
            RescheduleStatus = courseReschedule.Status__c;
            CurrentContactUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/' + courseReschedule.Contact__c;
        }
    }
    
    public String RescheduleStatus { get; set; }
    public Boolean IsCancelSuccessed { get; set; }
    public String CurrentContactUrl { get; set; }
    
    public PageReference cancel()
    {
        EtownCourseService.EtownCancelSuspendResult cancelSuspendResult = requestEtownService(courseReschedule);
        if(cancelSuspendResult != null && cancelSuspendResult.IsSuccess)
        { 
            cancelCourseReschedule(courseReschedule);
            IsCancelSuccessed = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have cancelled the suspension successfully!'));
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occurred on requesting Etown server. \r\nError Message: ' + ((cancelSuspendResult == null) ? '' : cancelSuspendResult.ErrorMessage)));
        }
        return null;
    }
    
    private void cancelCourseReschedule(CourseReschedule__c Reschedule)
    {
        if(Reschedule != null)
        {
            CourseReschedule__c courseStartReschedule = EtownCourseHelper.getCorrectSchedule(Reschedule.Contact__c, Reschedule.Type__c, Reschedule.ScheduleDate__c);
            List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>{ new CourseReschedule__c(Id = Reschedule.Id, Status__c = 'Cancelled'), new CourseReschedule__c(Id = courseStartReschedule.Id, Status__c = 'Cancelled')};
            try
            {
                update courseReschedules;
            }
            catch(Exception ex)  
            {
                EtownCourseHelper.sendErrorInfoEmail('Error occurred on CancelSuspensionController', ex.getMessage() + '\r\n' + ex.getStackTraceString());
            }
        } 
    }

    // requests etown system
    private EtownCourseService.EtownCancelSuspendResult requestEtownService(CourseReschedule__c validCourseReschedule)
    {
        EtownCourseService.EtownCancelSuspendParams params = new EtownCourseService.EtownCancelSuspendParams();
        if(validCourseReschedule != null)
        {
            if(validCourseReschedule.Contact__r.EtownMemberId__c != null)
            {
                params.MemberId = Integer.valueOf(validCourseReschedule.Contact__r.EtownMemberId__c);
            }
            if(validCourseReschedule.ScheduleJobId__c == null)
            {
                throw new CancelSuspensionException('Failed to cancel, the ScheduleJobId is null!');
            }
            else
            {
                params.SuspendOperateId = Integer.valueOf(validCourseReschedule.ScheduleJobId__c); 
                CourseReschedule__c courseStartReschedule = EtownCourseHelper.getCorrectSchedule(validCourseReschedule.Contact__c, validCourseReschedule.Type__c, validCourseReschedule.ScheduleDate__c);
                params.ResumeOperateId = Integer.valueOf(courseStartReschedule.ScheduleJobId__c);
            }
        }
        EtownCourseService.EtownCancelSuspendResult result = null;
        try
        {
            result = EtownCourseService.cancelSuspendInEtown(params);
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Failed to cancel the suspension request from Etown, the error message is: ' + ex.getMessage()));
        }
        return result;
    }
    
    public class CancelSuspensionException extends Exception {}
       
    @isTest 
    static void testSmartCancelSuspensionController()
    {
        Account account = new Account(Name = 'acme ef');
        insert account;
        Contact contact = new Contact(LastName = 'acmeMr', AccountId = account.Id, EtownMemberId__c = 980154340);
        insert contact;
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>
        {
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Suspend', ScheduleJobId__c = 4356, Duration__c = 7, ScheduleDate__c = Date.today()),
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Resume', ScheduleJobId__c = 5436, Duration__c = 7, ScheduleDate__c = Date.today().addDays(7))
        };
        insert courseReschedules;
        
        PageReference pageRef = new PageReference('/apex/SmartCancelSuspension?id=' + courseReschedules[0].Id);
        Test.setCurrentPage(pageRef);
        SmartCancelSuspensionController controller = new SmartCancelSuspensionController();
        controller.Cancel(); 
        controller.cancelCourseReschedule(courseReschedules[0]);  
    }
}