/**
 *controller for page: NewCalltracking
*/
public class NewCallTrackingController 
{
    private static final Id chinaSmartOppRecordTypeId = '0124000000099sY';
    private static final Id EFChinaOperatorProfileid = '00e30000000hjwF';
    private static final Id EFChinaOperatorLeadProfileid = '00e30000000hq1u';
    private String currentOpportunityId = ApexPages.currentPage().getParameters().get('oppId');
    private Event newSalesDemoEvent;
    private String currentRoleName = null;
    private String oringalSchool = '';
    private Datetime oringalDatetime = null;  
    
    public NewCalltrackingController()
    {
        init();       
    }
    
    public Opportunity CurrentOpportunity { get; set; }
    public Task NewPhoneTask { get;set; }
    public Boolean IsSucceeded { get; set; }
    public Boolean IsRenderedEventBlock { get; set; }
    public Boolean IsRenderSalesDemo { get; set; }
    public Boolean IsCreateSalesDemo { get; set; }
    public List<Event> SalesDemoEvents { get; set; }
    public String CurrentSelectSchool { get; set; }
    
    public List<SelectOption> AllSchoolOptions   
    {
        get
        {
			User currentUser = [select UserRole.Name from User where Id =:UserInfo.getUserId()];
			currentRoleName = currentUser.UserRole.Name;
			String cityRole = '';
			if(currentUser.UserRole.Name == 'China SH Telemarketing Leader' || currentUser.UserRole.Name == 'China SH Telemarketing User')
			{
			  	cityRole = 'SH';
			}
			else if(currentUser.UserRole.Name == 'China BJ Telemarketing Leader' || currentUser.UserRole.Name == 'China BJ Telemarketing User')
			{
			  	cityRole = 'BJ';
			}
			else if(currentUser.UserRole.Name == 'China GZ Telemarketing Leader' || currentUser.UserRole.Name == 'China GZ Telemarketing User')
			{
			  	cityRole = 'GZ';
			}
			else if(currentUser.UserRole.Name == 'China SZ Telemarketing Leader' || currentUser.UserRole.Name == 'China SZ Telemarketing User')
			{
			  	cityRole = 'SZ';
			}
			else if(currentUser.UserRole.Name == 'China HZ Telemarketing Leader' || currentUser.UserRole.Name == 'China HZ Telemarketing User')
			{
			  	cityRole = 'HZ';
			}
	        else //if(currentUser.UserRole.Name == 'China Operator' || currentUser.UserRole.Name == 'China SZ Telemarketing User')
	        {
            	cityRole = 'ALL';
		    }
            return getSchoolOptonsByRole(cityRole);
        }
    }
    
    /**
     * create new phone event and check remaining appts.
    */
    public PageReference CreateNewPhoneTask()
    {
		if(currentOpportunity.NextCallTime__c == null)
		{
			currentOpportunity.NextCallTime__c.addError('You must enter a value!');	
			return null;
		}
		if(currentOpportunity.NextCallTime__c.date().daysBetween(Date.today().addDays(45)) < 0)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The date can only be in the range from now until 45 days.'));
			return null;
		}
        if(currentOpportunity.Location__c != null && currentOpportunity.Location__c != '' && currentOpportunity.Reschedule_appt_Date_Time__c != null)
        {
            if(IsRenderSalesDemo)
            {
                Boolean isChanged = false;
                if(oringalDatetime == null || (oringalDatetime != null && oringalDatetime.format() != currentOpportunity.Reschedule_appt_Date_Time__c.format()) || oringalSchool != currentOpportunity.Location__c)
                {
                  	isChanged = true;
                }
                if(IsCreateSalesDemo)
                {
                  	if(currentOpportunity.Reschedule_appt_Date_Time__c.date() >= Date.today())
                  	{  
                      	Boolean isBlockedByCapping = true;
                      	if((currentRoleName == 'China Operator' && userInfo.getProfileId() == EFChinaOperatorProfileid)|| (currentRoleName == 'China Operator Group Supervisor' && UserInfo.getProfileId() == EFChinaOperatorLeadProfileid))
                      	{
                        	isBlockedByCapping = false;
                      	}   
                      	else
                      	{                                                      
                        	Integer remainAppCount = RemainingApptsHelper.getRemainingApptCount(currentOpportunity.Location__c, currentOpportunity.Reschedule_appt_Date_Time__c.date());
                        	if(remainAppCount > 0)
                        	{    
                            	isBlockedByCapping = false;                                              
                        	}                   
                      	}
                      	if(!isBlockedByCapping)
                      	{
                        	try
                          	{
                              	update currentOpportunity;                            
                              	//copy demo subject and demo time to phone task
                              	NewPhoneTask.Demo_Subject__c = newSalesDemoEvent.Subject;
                              	NewPhoneTask.Demo_time__c = newSalesDemoEvent.ActivityDateTime;   
                              	insert SalesDemoEvents; 
                              	deleteNonHappenedSalesDemoEvents(SalesDemoEvents[0]);  
                              	insert NewPhoneTask;                      
                              	isSucceeded = true; 
                              	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The events have been successfully created.'));
                          	}
                          	catch(Exception ex)
                          	{
                              	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create a sales demo event.' + ex.getMessage()));
                          	}
                      	}
                      	else
                      	{
                          	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no remaining appts for the school: ' + currentOpportunity.Location__c + ' on ' + currentOpportunity.Reschedule_appt_Date_Time__c.date().format() + '.Pls select another date.'));
                      	}
                  	}
                  	else
                  	{
                      	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pls make sure the schedule date is after today.'));
                  	}
                }
                else
                {
                  	if(!isChanged)
                  	{
                      	try
                      	{
                         	insert NewPhoneTask;
                         	updateNextCallTimeToOpp();
                        	isSucceeded = true;
                        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The phone task has been successfully created.')); 
                      	}
                      	catch(Exception ex)
                      	{
                        
                      	}
                  	}
                  	else
                  	{
                    	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pls make sure the sales Demo checkbox is checked.'));
                  	}     
                }
            }        
            else
            {                           
                try
                {
                    update currentOpportunity;                                        
                    insert NewPhoneTask;
                    isSucceeded = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The phone task has been successfully created.'));      
                }
                catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create a phone task.' + ex.getMessage()));
                }
            }
        }
        else
        {
            try
            {
                insert NewPhoneTask;
                updateNextCallTimeToOpp();
                isSucceeded = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'The phone task has been successfully created.'));
                //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'School or schedule date must be enter a value,Pls check again.'));
           	}
            catch(Exception ex)
            { 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create a phone task.' + ex.getMessage()));
            }
        }
        return null;
    }
    
    private void updateNextCallTimeToOpp()
    {
        update new Opportunity(Id = CurrentOpportunity.Id, NextCallTime__c = CurrentOpportunity.NextCallTime__c);
    }
    
    public pageReference Refresh()
    {
        IsRenderSalesDemo = false;
        newSalesDemoEvent.ActivityDateTime = currentOpportunity.Reschedule_appt_Date_Time__c;   
        currentOpportunity.Location__c = CurrentSelectSchool;          
        if(CurrentSelectSchool != null && CurrentSelectSchool != '')
        {
            IsRenderSalesDemo = RemainingApptsHelper.isLeadToShowSchool(CurrentSelectSchool);
            if(!IsRenderSalesDemo)
            {                 
              IsCreateSalesDemo = false;
            }
        }      
        return null;
    }
    
    //inits function
    private void init()
    {
        SalesDemoEvents = new List<Event>();
        isSucceeded = false;
        IsRenderSalesDemo = false;
        IsCreateSalesDemo = false;
        IsRenderedEventBlock = false;
        NewPhoneTask = new Task(ActivityDate = date.today(), Status = 'completed');
        if(currentOpportunityId != null && currentOpportunityId != '')
        {
            List<Opportunity> opportunities = [select Id, Location__c, NextCallTime__c, Reschedule_appt_Date_Time__c from Opportunity where Id =:currentOpportunityId and RecordTypeId =:chinaSmartOppRecordTypeId limit 1];
            if(!opportunities.isEmpty())
            {
                IsRenderedEventBlock = true;
                CurrentOpportunity = opportunities[0];
                oringalSchool = CurrentOpportunity.Location__c;
                oringalDatetime = CurrentOpportunity.Reschedule_appt_Date_Time__c;
                if(CurrentOpportunity.Location__c != null && CurrentOpportunity.Location__c != '')
                {
                    CurrentSelectSchool = CurrentOpportunity.Location__c;                                        
                }
                Integer phoneTasksCount = [select count() from Task where Subject Like 'Phone %' and WhatId =:currentOpportunityId];
                NewPhoneTask.Subject = 'Phone ' + String.valueof(phoneTasksCount + 1);
                NewPhoneTask.WhatId = currentOpportunityId;
                NewPhoneTask.OwnerId = UserInfo.getUserId();
                // init salesDemo events
                newSalesDemoEvent = new Event(ActivityDateTime = currentOpportunity.Reschedule_appt_Date_Time__c);   
                List<Event> existedEvents = [select Subject from Event where Subject Like 'sales demo %' and WhatId =:currentOpportunityId];
                List<String> existedEventSubjects = new List<String>();
                for(Event existedEvent : existedEvents)
                {
                    existedEventSubjects.add(existedEvent.Subject);
                }               
                Integer salesDemoEventCount = [select count() from Task where Demo_Subject__c Like 'sales demo %' and WhatId =:currentOpportunityId];//and Demo_Subject__c not in :existedEventSubjects 
                newSalesDemoEvent.WhatId = currentOpportunity.Id;
                newSalesDemoEvent.Subject = 'sales demo ' + String.valueof(salesDemoEventCount + existedEvents.size()  + 1);
                newSalesDemoEvent.ActivityDateTime = currentOpportunity.Reschedule_appt_Date_Time__c;
                newSalesDemoEvent.OwnerId = UserInfo.getUserId();
                newSalesDemoEvent.DurationInMinutes = 1;
                SalesDemoEvents.add(newSalesDemoEvent);
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No opportunity specified，Please take care this page only works for China Opportunities.'));
            }           
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No opportunity specified，Please check it.'));
        }
    }
    
    //gets school options by current user's role
    private List<SelectOption> getSchoolOptonsByRole(String cityRole)
    {
		List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
		List<SchoolAddress__c> allSchools = [select Name from SchoolAddress__c];
        if(cityRole == 'ALL')
        {
           	for(SchoolAddress__c school : allSchools)
           	{
           		if(!school.Name.contains('All'))
            	{
                	options.add(new SelectOption(school.Name.replace('_', ' '), school.Name.replace('_', ' ')));
            	}
          	}
        }
        else
        {
          	for(SchoolAddress__c school : allSchools)
          	{
            	if(school.Name.contains(cityRole) && (!school.Name.contains('All')))
            	{
              		options.add(new SelectOption(school.Name.replace('_', ' '), school.Name.replace('_', ' ')));
            	}
          	}
        }     
        return options;
    }
    
    //deletes non-happened Sales demo events 
    private void deleteNonHappenedSalesDemoEvents(Event newSalesDemoEvent)
    {
        List<Event> nonHappenedSalesDemoEvents = [select Id from Event where Subject Like 'sales demo%' and id != :newSalesDemoEvent.Id and WhatId = :currentOpportunityId];
        if(!nonHappenedSalesDemoEvents.isEmpty())
        {
          	delete nonHappenedSalesDemoEvents;
        }
    }
    
    
    @isTest
    static void testController()
    {
        Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
        Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', NextCallTime__c = Date.today().addDays(10), Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
        insert testOpportunity1;
        Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
        insert testTarget1;
        PageReference testPage = new PageReference('/NewCalltracking?oppId=' + testOpportunity1.Id);
        test.setCurrentPage(testPage);
        NewCallTrackingController controller = new NewCallTrackingController();
        List<Event> events = controller.SalesDemoEvents;
        system.assert(events != null);
        controller.CurrentSelectSchool = 'SH PSQ';
        controller.Refresh();
        controller.IsCreateSalesDemo = true;
        controller.CreateNewPhoneTask();

		controller.IsRenderSalesDemo = false;
		controller.IsCreateSalesDemo = false;
		controller.CreateNewPhoneTask();
		controller.updateNextCallTimeToOpp();

		User user1 = [select Id, UserRole.Name from User where UserRole.Name = 'China SH Telemarketing Leader' and IsActive = true limit 1]; //gets the current user
		system.runAs(user1)
		{
			system.assert(controller.AllSchoolOptions != null);
		}
		User user2 = [select Id, UserRole.Name from User where UserRole.Name = 'China BJ Telemarketing Leader' and IsActive = true limit 1]; //gets the current user
		system.runAs(user2)
		{
			system.assert(controller.AllSchoolOptions != null);
		}
		User user3 = [select Id, UserRole.Name from User where UserRole.Name = 'China GZ Telemarketing Leader' and IsActive = true limit 1]; //gets the current user
		system.runAs(user3)
		{
			system.assert(controller.AllSchoolOptions != null);
		}
		User user4 = [select Id, UserRole.Name from User where UserRole.Name = 'China SZ Telemarketing Leader' and IsActive = true limit 1]; //gets the current user
		system.runAs(user4)
		{
			system.assert(controller.AllSchoolOptions != null);
		}
    }
}