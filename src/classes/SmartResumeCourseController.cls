/*
 *controller of page resume course  
 */
public class SmartResumeCourseController 
{
	private CourseReschedule__c courseReschedule;
	
    public SmartResumeCourseController()
    {
        String courseRescheduleId = ApexPages.currentPage().getParameters().get('id');
    	List<CourseReschedule__c> courseReschedules = [select Id, Status__c, Duration__c, Type__c, ScheduleDate__c, ScheduleJobId__c, ActionStatus__c, Contact__c, Contact__r.EtownMemberId__c, Contact__r.Status__c, StudentActual__c, StudentActual__r.Status__c from CourseReschedule__c where Id = :courseRescheduleId and Type__c = 'Resume' and Contact__c != null limit 1];
        if(courseReschedules.size() > 0)
        {
        	courseReschedule = courseReschedules[0];
        	RescheduleStatus = courseReschedule.Status__c;
        	CurrentContactUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/' + courseReschedule.Contact__c; // get url
        	CourseReschedule__c suspendReschedule = EtownCourseHelper.getCorrectSchedule(courseReschedule.Contact__c, 'Resume', courseReschedule.ScheduleDate__c);
        	if(suspendReschedule.Status__c == 'Completed' && courseReschedule.Status__c == 'Not start yet')
        	{
        		IsInProgress = true;
        	}
        }
        IsResumeSuccessed = false;
        Reschedule = new RescheduleInfo();
        ResumeNow = false;
    }
    
    public Boolean IsResumeSuccessed { get; set; }
    public Boolean ResumeNow { get; set; }
    public Boolean IsInProgress { get; set; }    
    public RescheduleInfo Reschedule { get; set;}
    public String RescheduleStatus { get; set; }
    public String CurrentContactUrl { get; set; }
    public String DateToday
    {
    	get
    	{
    		return DateTime.now().format('dd/MM/yyyy');
    	}
    }
    
    public PageReference submit()
    {
        if(courseReschedule != null)
        {
        	EtownCourseService.EtownResumeResult resumeResult = requestEtownSystem(courseReschedule);
        	EtownCourseHelper.StudentActionParams params = new EtownCourseHelper.StudentActionParams();
        	if(courseReschedule.Contact__r.EtownMemberId__c != null)
        	{
        		params.MemberId = Integer.valueOf(courseReschedule.Contact__r.EtownMemberId__c);
        	}
        	params.OperateId = Integer.valueOf(courseReschedule.ScheduleJobId__c);
        	params.ActionTypeName = EtownCourseHelper.ActionType.RESUME;
	        if(ResumeNow)
	    	{
	    		if(resumeResult != null && resumeResult.IsSuccess)
	            {
	            	updateCourseReschedule(courseReschedule, Date.today());
	            	EtownCourseHelper.updateStatusAndDate(params);
	            	IsResumeSuccessed = true;
	            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have resumed it now.'));
	            }
	            else
	            {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occurred on requesting Etown server. \r\n Error Message:'+ ((resumeResult == null) ? 'Server Error' : resumeResult.ErrorMessage)));
	            }
	        }
	        else if(isValidResumeDate(courseReschedule, Reschedule.ResumeDate))
	        {
	            if(resumeResult != null && resumeResult.IsSuccess)
	            {
	                updateCourseReschedule(courseReschedule,Reschedule.ResumeDate);
	                IsResumeSuccessed = true;
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have resumed it successfully!'));
	            }
	            else
	            {
	                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error occurred on requesting Etown server. \r\n Error Message:'+ ((resumeResult == null)? 'Server Error' : resumeResult.ErrorMessage)));
	            }
	        }
        }
        return null;
    }
    
    // sends memberId new resume date to etown before you request
    private EtownCourseService.EtownResumeResult requestEtownSystem(CourseReschedule__c validCourseReschedule)
    {
        EtownCourseService.EtownResumeParams params = new EtownCourseService.EtownResumeParams();
        if(validCourseReschedule != null)
        {
        	if(validCourseReschedule.Contact__r.EtownMemberId__c != null)
	        {
	        	params.MemberId = Integer.valueOf(validCourseReschedule.Contact__r.EtownMemberId__c);
	        }
	        if(validCourseReschedule.ScheduleJobId__c == null)
	        {
	        	throw new ResumeCourseException('Failed to resume the course, the resumeId is null!');
	        }
	        else
	        {
	        	params.ResumeId = Integer.valueOf(validCourseReschedule.ScheduleJobId__c);
	        }
        	if(ResumeNow)
			{
			 	params.IsResumeNow = true;
		        params.ResumeDate = DateTime.Now();
			}
			else
			{
				params.IsResumeNow = false;
		        params.ResumeDate = EtownCourseHelper.getGMTDateTime(Reschedule.ResumeDate);
			}
        }
        EtownCourseService.EtownResumeResult result = null;
        try
        {
        	result = EtownCourseService.resumeInEtown(params);
        }
        catch(Exception ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Failed to resume the student from Etown, the error message is: ' + ex.getMessage()));
		}
        return result;
    }
    
    // if the date is a valid resume date
    private Boolean isValidResumeDate(CourseReschedule__c courseResumeReschedule, Date inputtedDate)
    {
        Boolean result = false;
        if(courseResumeReschedule != null)
        {
        	CourseReschedule__c courseStartReschedule = EtownCourseHelper.getCorrectSchedule(courseResumeReschedule.Contact__c, courseResumeReschedule.Type__c, courseResumeReschedule.ScheduleDate__c);
        	if(courseStartReschedule != null)
        	{
		    	if(inputtedDate > courseStartReschedule.ScheduleDate__c && inputtedDate < courseResumeReschedule.ScheduleDate__c && inputtedDate >= Date.today())
		    	{
		    	    result = true;
		    	}
		        else 
		        {
		            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Invalid date, please choose again.'));
		            result = false;
		        }
        	}
        }
        return result;
    }
    
    // updates student service 
    private void updateCourseReschedule(CourseReschedule__c courseStatusReschedule, Date resumeDate)
    {
        if(courseStatusReschedule != null && courseStatusReschedule.ScheduleDate__c != null && resumeDate != null )
        {
            try  
            {   
            	Integer duration = courseStatusReschedule.ScheduleDate__c.daysBetween(resumeDate) + ((courseStatusReschedule.Duration__c==null)? 0: Integer.valueOf(courseStatusReschedule.Duration__c));
                update new CourseReschedule__c(Id = courseStatusReschedule.Id, ActionStatus__c = 'Manually', ScheduleDate__c = resumeDate, Duration__c = duration);
            }
            catch(Exception ex)
            {
                String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                String subject = 'Error occurred on updateCourseReschedule';
                EtownCourseHelper.sendErrorInfoEmail(subject, error);
            }
        }
    }
    
    public class RescheduleInfo
    {
    	public Date ResumeDate;
    	public String ResumeDateInputValue 
    	{
    		get
    		{
    			String result = '';
    		    if(ResumeDate != null) 
    		    {
    		        result = ResumeDate.format(); 
    		    }
    		    return result;
    		} 
    		set
    		{
    		    if(value != null)
    		    {
    		        ResumeDate = Date.parse(value);
    		    }
    		}
    	}
    }
    
    public class ResumeCourseException extends Exception {}
    
    @isTest
    static void testSmartResumeCourseController()
    {
        Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName = 'acme', AccountId = account.Id, EtownMemberId__c = 98014356);
        insert contact;
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>
        {
			new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Suspend', ScheduleJobId__c = 4356, Duration__c = 7, ScheduleDate__c = Date.today()),
			new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Resume', ScheduleJobId__c = 5436, Duration__c = 7, ScheduleDate__c = Date.today().addDays(7))
		};
		insert courseReschedules;
		
		PageReference pageRef = new PageReference('/apex/SmartResumeCourse?id=' + courseReschedules[1].Id);
		Test.setCurrentPage(pageRef);
		SmartResumeCourseController controller = new SmartResumeCourseController();
		system.assert(controller.DateToday != null);
		controller.ResumeNow = true;
		controller.submit();
		controller.updateCourseReschedule(courseReschedules[1], Date.today());
		controller.isValidResumeDate(courseReschedules[1], Date.today());
    }
    
    @isTest
    static void testRescheduleInfo()
    {
    	SmartResumeCourseController.RescheduleInfo info = new SmartResumeCourseController.RescheduleInfo();
    	info.ResumeDateInputValue = '01/12/2011';
    	system.assert(info.ResumeDateInputValue != null);
    	SmartResumeCourseController controller = new SmartResumeCourseController();
    	controller.ResumeNow = false;
    	controller.submit();
    }
}