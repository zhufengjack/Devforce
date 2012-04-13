/*
 * Conreoller for OverrideOpportunityView page
 */
global class OverrideOpportunityViewController
{
	private String oppId = '';
	public enum SobjectName { Event, Task }

	public OverrideOpportunityViewController(ApexPages.StandardController controller)
	{
		oppId = controller.getId();
		setPermissionToProfile();
	}

	public List<ActivityInfo> CallMobilePhone { get; set; }
	public List<ActivityInfo> SMS { get; set; }
	public List<ActivityInfo> NewCallTracking { get; set; }
	public List<ActivityInfo> Others { get; set; }

	public PageReference setPermissionToProfile()
	{
		String profileName = '';
		List<Profile> profiles = [select Id, Name from Profile where Id = : UserInfo.getProfileId()];
        if(!profiles.isEmpty())
        {
            profileName = profiles[0].Name;
        }
        Set<String> profilesRender = getProfiles();
        if(!profilesRender.contains(profileName))
        {
        	return new PageReference('/' + oppId + '?nooverride=1');
        }
        initActivitiesInfo();
        return null;
	}

	private Set<String> getProfiles()
	{
		Set<String> result = new Set<String>
		{'EF China Operator', 'EF China Operator Lead', 'EF China Telemarketing Lead', 'EF China Telemarketing Manager', 'EF China Telemarketing User', 'EF China Smart OA', 'System Administrator New'};
		return result;
	}

	private void initActivitiesInfo()
	{
		CallMobilePhone = new List<ActivityInfo>();
		SMS = new List<ActivityInfo>();
		NewCallTracking = new List<ActivityInfo>();
		Others = new List<ActivityInfo>();
		initEventsInfo();
		initTasksInfo();
	}

	private void initEventsInfo()
	{
		List<Event> events = [select Id, Type, Subject, ActivityDate, OwnerId, Owner.Name, RecordTypeName__c, LastModifiedDate, WhatId, ActivityDateTime from Event where WhatId = :oppId order by LastModifiedDate];
		for(Event event : events)
		{
			if(Datetime.now() > event.ActivityDateTime)
			{
				ActivityInfo activity = new ActivityInfo(event);
				if(event.RecordTypeName__c == 'Call')
				{
					CallMobilePhone.add(activity);
				}
				else if(event.RecordTypeName__c == 'CN F2F Sales Meeting')
				{
					NewCallTracking.add(activity);
				}
				else
				{
					Others.add(activity);
				}
			}
		}
	}

	private void initTasksInfo()
	{
		Set<String> taskStatus = getClosedTaskStatus();
		List<Task> tasks = [select Id, Type, Subject, ActivityDate, OwnerId, Owner.Name, RecordTypeName__c, LastModifiedDate, WhatId, Status from Task where WhatId = :oppId order by LastModifiedDate];
		for(Task task : tasks)
		{
			if(taskStatus.contains(task.Status))
			{
				ActivityInfo activity = new ActivityInfo(task);
				if(task.RecordTypeName__c == 'Phone Call')
				{
					NewCallTracking.add(activity);
				}
				else if(task.RecordTypeName__c == 'Send SMS')
				{
					SMS.add(activity);
				}
				else
				{
					Others.add(activity);
				}
			}
		}
	}

	private Set<String> getClosedTaskStatus()
	{
		Set<String> result = new Set<String>();
		List<TaskStatus> status = [select Id, MasterLabel from TaskStatus where IsClosed = true];
		for(TaskStatus taskStatus : status)
		{
			result.add(taskStatus.MasterLabel);
		}
		return result;
	}

	@RemoteAction
    global static void deleteActivityInfo(String objectId)
    {
    	//Integer objectType = checkoutObjectIsEventOrTask(objectId);
    	SobjectName objectType = checkoutObjectIsEventOrTask(objectId);
    	if(objectType == SobjectName.Event)
    	{
    		Event event = new Event(Id = objectId);
    		delete event;
    	}
    	else if(objectType == SobjectName.Task)
    	{
    		Task task = new Task(Id = objectId);
    		delete task;
    	}
    }

    private static SobjectName checkoutObjectIsEventOrTask(String objectId)
    {
        //Integer result = 1;
        SobjectName name;
        String subObjectId = objectId.substring(0, 3);
        if(subObjectId == '00U')
        {
            name = SobjectName.Event;
        }
        else if(subObjectId == '00T')
        {
        	name = SobjectName.Task;
        }
        return name;
    }

	public class ActivityInfo
	{
		public ActivityInfo(Event event)
		{
			this.ObjectId = event.Id;
			this.Type = event.Type;
			this.IsTask = false;
			this.Subject = event.Subject;
			this.DueDate = event.ActivityDate;
			this.OwnerId = event.OwnerId;
			this.OwnerName = event.Owner.Name;
			this.RecordTypeName = event.RecordTypeName__c;
			this.LastModified = event.LastModifiedDate;
		}

		public ActivityInfo(Task task)
		{
			this.ObjectId = task.Id;
			this.Type = task.Type;
			this.IsTask = true;
			this.Subject = task.Subject;
			this.DueDate = task.ActivityDate;
			this.OwnerId = task.OwnerId;
			this.OwnerName = task.Owner.Name;
			this.RecordTypeName = task.RecordTypeName__c;
			this.LastModified = task.LastModifiedDate;
		}

		public Id ObjectId { get; set; }
		public String Type { get; set; }
		public Boolean IsTask { get; set; }
		public String Subject { get; set; }
		public Date DueDate { get; set; }
		public String OwnerName { get; set; }
		public Id OwnerId { get; set; }
		public String RecordTypeName { get; set; }
		public DateTime LastModified { get; set; }
	}

	@isTest
	static void testOverrideOpportunityViewController()
	{
        User testUser = [select Id from User where Id = :UserInfo.getUserId()];
        system.runAs(testUser)
        {
	        Opportunity opp = new Opportunity(Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
	        insert opp;
	        RecordType testRecordType = new RecordType();
	        List<RecordType> recordTypes = [select Id from RecordType where Name = 'Call' limit 1];
	        if(!recordTypes.isEmpty())
	        {
	        	testRecordType = recordTypes[0];
	        }
	        RecordType testTaskRecordType = new RecordType();
	        List<RecordType> recordTaskTypes = [select Id from RecordType where Name = 'Phone Call' limit 1];
	        if(!recordTaskTypes.isEmpty())
	        {
	        	testTaskRecordType = recordTaskTypes[0];
	        } 

	        RecordType testEventRecordType = new RecordType();
	        List<RecordType> recordEventTypes = [select Id from RecordType where Name = 'CN F2F Sales Meeting' limit 1];
	        if(!recordEventTypes.isEmpty())
	        {
	        	testEventRecordType = recordEventTypes[0];
	        }
	        RecordType taskSMSType = new RecordType();
	        List<RecordType> recordSMSTypes = [select Id from RecordType where Name = 'Send SMS' limit 1];
	        if(!recordSMSTypes.isEmpty())
	        {
	        	taskSMSType = recordSMSTypes[0];
	        }
	        Event event = new Event(RecordTypeId = testRecordType.Id, Subject = 'acme11 event', ActivityDate = date.today(), DurationInMinutes = 30, OwnerId = testUser.Id, WhatId = opp.Id, ActivityDateTime = dateTime.now());
	        Event event2 = new Event(RecordTypeId = testEventRecordType.Id, Subject = 'acme22 event', ActivityDate = date.today(), DurationInMinutes = 30, OwnerId = testUser.Id, WhatId = opp.Id, ActivityDateTime = dateTime.now());
	        insert new List<Event>{ event, event2};

	        Task task = new Task(RecordTypeId = testTaskRecordType.Id, Subject = 'acme11 task', ActivityDate = date.today(), OwnerId = testUser.Id, WhatId = opp.Id, Status = 'Completed');
	        Task task2 = new Task(RecordTypeId = taskSMSType.Id, Subject = 'acme22 task', ActivityDate = date.today(), OwnerId = testUser.Id, WhatId = opp.Id, Status = 'Completed');
	        insert new List<Task>{task, task2};

	        ApexPages.StandardController controller = new ApexPages.StandardController(opp);
	        OverrideOpportunityViewController testOverride = new OverrideOpportunityViewController(controller);
	        OverrideOpportunityViewController.DeleteActivityInfo(task2.Id);
        }
	}
}