/*
 *A controller of OverrideCourseRescheduleDetail page and OverrideCourseRescheduleEdit page
 */
public class OverrideCourseReschedulePageController
{
	public OverrideCourseReschedulePageController(ApexPages.StandardController controller)
    {
        String suspendId = ApexPages.currentPage().getParameters().get('supid');
        String resumeId = ApexPages.currentPage().getParameters().get('resid');
        if(suspendId != null && resumeId != null)
        {
        	List<CourseReschedule__c> courseReschedules = [select Id, Name, CreatedDate, CreatedById, LastModifiedDate, ScheduleDate__c, Status__c, SuspendReason__c, ScheduleJobId__c, ActionStatus__c, ActionDate__c, Duration__c, Type__c, Subject__c, StudentActual__c, Contact__c from CourseReschedule__c where Id = :suspendId];
        	if(courseReschedules.size() > 0)
        	{
        		SuspendReschedule = courseReschedules[0];
        		ResumeReschedule = getCorrectReschedule(resumeId);
        		SuspendReschedule.Duration__c = SuspendReschedule.ScheduleDate__c.daysBetween(ResumeReschedule.ScheduleDate__c);
        		if(SuspendReschedule.Status__c == 'Completed' && ResumeReschedule.Status__c == 'Not start yet')
        		{
        			Status = 'In progress';
        		}
        		else
        		{
        			Status = SuspendReschedule.Status__c;
        		}
        	}
        }
    }
    
    public String Status { get; set; }
	public CourseReschedule__c SuspendReschedule { get; set; }
	public CourseReschedule__c ResumeReschedule { get; set; }

	public PageReference del()
	{    
		PageReference contactPage;
		if(SuspendReschedule != null && ResumeReschedule != null)
		{
			List<CourseReschedule__c> delReschedules = new List<CourseReschedule__c>{
										    		new CourseReschedule__c(Id = SuspendReschedule.Id),
										        	new CourseReschedule__c(Id = ResumeReschedule.Id) };
			try
			{
				delete delReschedules;
				contactPage = new PageReference('/apex/OverrideContactView?id=' + SuspendReschedule.Contact__c);
			}
			catch(Exception ex)
	        {
	            ApexPages.addMessages(ex);
	        }
		}
        return contactPage; //back to contact page
	}
	
	public PageReference save()
	{
		PageReference detailPage; 
		if(SuspendReschedule != null && ResumeReschedule != null)
		{
			if(SuspendReschedule.ScheduleDate__c == null || ResumeReschedule.ScheduleDate__c == null)
			{
			    SuspendReschedule.ScheduleDate__c.addError('You must enter a value');
			    ResumeReschedule.ScheduleDate__c.addError('You must enter a value');
			    return null;
			}
	    	List<CourseReschedule__c> updatingCourseReschedules = new List<CourseReschedule__c>
	    	{
	        	new CourseReschedule__c(Id = SuspendReschedule.Id, Subject__c = SuspendReschedule.Subject__c, Contact__c = SuspendReschedule.Contact__c, StudentActual__c = SuspendReschedule.StudentActual__c, ScheduleDate__c = SuspendReschedule.ScheduleDate__c, Status__c = (Status == 'In progress')? 'Completed': Status, ActionStatus__c = SuspendReschedule.ActionStatus__c, SuspendReason__c = SuspendReschedule.SuspendReason__c, Duration__c = SuspendReschedule.ScheduleDate__c.daysBetween(ResumeReschedule.ScheduleDate__c), ScheduleJobId__c = SuspendReschedule.ScheduleJobId__c),
	        	new CourseReschedule__c(Id = ResumeReschedule.Id, Subject__c = SuspendReschedule.Subject__c, Contact__c = SuspendReschedule.Contact__c, StudentActual__c = SuspendReschedule.StudentActual__c, ScheduleDate__c = ResumeReschedule.ScheduleDate__c, Status__c = (Status == 'In progress')? 'Not start yet': Status, ActionStatus__c = ResumeReschedule.ActionStatus__c, SuspendReason__c = SuspendReschedule.SuspendReason__c, Duration__c = SuspendReschedule.ScheduleDate__c.daysBetween(ResumeReschedule.ScheduleDate__c), ScheduleJobId__c = ResumeReschedule.ScheduleJobId__c)
	    	};
	    	try
	        {
	            upsert updatingCourseReschedules;
		        detailPage = new PageReference('/Apex/OverrideCourseRescheduleDetail?supid=' + SuspendReschedule.Id + '&resid=' + ResumeReschedule.Id);
		        detailPage.setRedirect(true);
			}
	        catch(Exception ex)
	        {
	            ApexPages.addMessages(ex);
	        }
		}
		return detailPage;
	}
	
	 // gets CourseReschedule from the same group
    private CourseReschedule__c getCorrectReschedule(String id)
	{
		CourseReschedule__c result;
        List<CourseReschedule__c> courseReschedules = [select Id, Name, CreatedDate, CreatedById, LastModifiedDate, Type__c, Duration__c, SuspendReason__c, ScheduleJobId__c, ScheduleDate__c, Contact__c, Subject__c, StudentActual__c, ActionStatus__c, ActionDate__c, Status__c from CourseReschedule__c where Id =:id];
        if(courseReschedules.size() > 0)
        {
        	result = courseReschedules[0];
        }
		return result;
	}
	
    @isTest
    static void testOverrideCourseReschedulePageController()
    {
    	Contact contact = new Contact(LastName='Acme', OwnerId = UserInfo.getUserId());
        insert contact;
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>
											        {
														new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Suspend', ScheduleJobId__c = 4356, Duration__c = 7, ScheduleDate__c = Date.today()),
														new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Resume', ScheduleJobId__c = 5436, Duration__c = 7, ScheduleDate__c = Date.today().addDays(7))
													};
		insert courseReschedules;
        PageReference page = new PageReference('apex/OverrideCourseRescheduleDetail?supid=' + courseReschedules[0].Id + '&resid=' + courseReschedules[1].Id);
        Test.setCurrentPage(page);
        ApexPages.StandardController controller = new ApexPages.StandardController(courseReschedules[0]);
		OverrideCourseReschedulePageController courseReschedulePageController = new OverrideCourseReschedulePageController(controller);
		courseReschedulePageController.save();
        courseReschedulePageController.del();
    }
}