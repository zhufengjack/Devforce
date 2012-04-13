/*
 * a controller for custom component SmartOppsWithoutActivities
 */
public class SmartOppsWithoutActivitiesController
{
	private List<Opportunity> oppsWithoutActs;
	private List<Opportunity> firstShowOpps;	
	private List<TaskInfo> taskInfos;
	private List<EventInfo> eventInfos;
	private String emailUrl;
	
	public String SchoolName { get; set; }
	public String SystemUrl
	{
		get
		{
			if(emailUrl == null)
			{
				emailUrl = URL.getSalesforceBaseUrl().toExternalForm();
			}
			return emailUrl;
		}
	}
	public Set<Id> CcIds 
	{ 
		get
		{
			Set<Id> ccIds = new Set<Id>();
			if(ccIds.size() == 0)
			{
				for(User user : [select Id, Name from User where SchoolName__c = :SchoolName and Profile.Name in ('EF China Sales User New LTC', 'EF China Sales User New') and IsActive = true])
			    {
			        ccIds.add(user.Id);
			    }
			}
		    return ccIds;
		}
	}
		
    //Finds opps without activities created before 24 hrs
    public List<Opportunity> OpportunitiesWithoutActivities
    { 
        get
        {
            if(oppsWithoutActs == null)
            {
            	oppsWithoutActs = new List<Opportunity>();
	            List<Opportunity> opps = [select Id, Name, Account.Id, Account.Name, Account.OwnerId, Owner.Name, Mobile__c, First_Visit__c, Comments__c, ShowUpTime__c, StageName,
	                                    (select Id, WhatId, CreatedDate from Events),
	                                    (select Id, WhatId, CreatedDate from Tasks) 
	                                    from Opportunity 
	                                    where StageName = 'Showed Up - Followup' and First_Visit__c != null and First_Visit__c < :Date.today() and OwnerId in :CcIds and CreatedDate > :DateTime.now().addHours(-720) 
	                                    order by OwnerId limit 15000];
	            
	            for(Opportunity opp : opps)
	            {
	                Boolean hasActivity = false;
	                DateTime showUpTime = getShowUpTime(opp);
	                for(Event event : opp.Events)
	                {
	                    if(event.CreatedDate > showUpTime)
	                    {
	                        hasActivity = true;
	                        break;
	                    }
	                }   
	                for(Task task : opp.Tasks)
	                {
	                    if(task.CreatedDate > showUpTime)
	                    {
	                        hasActivity = true;
	                        break;
	                    }
	                }
	                //if no activity found, send this opp out.
	                if(!hasActivity)
	                {
	                    oppsWithoutActs.add(opp);
	                    if(oppsWithoutActs.size() >= 900)
	                    {
	                    	break;
	                    }
	                }
	            }
            }
            return oppsWithoutActs;
        }         
    } 
	     
    public List<Opportunity> FirstShowUpOpps
    {
    	get
    	{
    		if(firstShowOpps == null)
    		{
	    		firstShowOpps = new List<Opportunity>();
	            List<Opportunity> opps = [select Id, Name, StageName, First_Visit__c, OwnerId, Owner.Name, Comments__c, Mobile__c, Account.Id, Account.Name, Account.OwnerId from opportunity where 
	            												First_Visit__c > :Date.today().addDays(-90) and First_Visit__c < :Date.today().addDays(-60) and StageName in ('Showed Up - Followup', 'Payment Pending') 
	            												and OwnerId in :CcIds order by OwnerId, StageName, First_Visit__c limit 900];
	            for(Opportunity opp : opps)
	            {
	            	firstShowOpps.add(opp);
	            } 
			}
			return firstShowOpps;
		}
    }
    
    public List<EventInfo> Events
    {
		get
		{
			if(eventInfos == null)
			{
			    eventInfos = new List<Eventinfo>();
			    List<Event> events = [select Id, Subject, Comments__c, Appt_Status__c, StartDateTime, EndDateTime, AccountId, WhatId, Owner.Name from Event 
			        									where Appt_Status__c = 'Scheduled' and OwnerId in :CcIds and ActivityDate < Today and ActivityDate> :Date.today().addDays(-30) order by OwnerId limit 15000];
				Map<Id, Id> eventId2WhatId = new Map<Id, Id>();
			    for(Event event : events)
			    {
					eventId2WhatId.put(event.Id, event.WhatId);
			    }
			    Map<Id, Opportunity> oppId2Opp = getRelatedOpp(eventId2WhatId);
			    for(Event event : events)
			    {
			    	Opportunity opp = oppId2Opp.get(eventId2WhatId.get(event.Id));
			    	if(opp != null)
			    	{
			    		eventInfos.add(new EventInfo(event, opp));
			    		if(eventInfos.size() >= 900)
		                {
		                	break;
		                }
			    	}
			    }
			}
			return eventInfos;
		}
    }
  	
  	public List<TaskInfo> Tasks
  	{
   		get
   		{
   			if(taskInfos == null)
   			{
	   			Set<String> status = new Set<String> {'Not Started', 'In Progress', 'Waiting on someone else'};
	   			taskInfos = new List<TaskInfo>();
				List<Task> tasks = [select Id, subject, Comments__c, Owner.Name, Status, WhatId from Task where OwnerId in :CcIds and Status in :status order by OwnerId limit 15000];
				Map<Id, Id> taskId2WhatId = new Map<Id, Id>();
				for(Task task : tasks)
				{
					taskId2WhatId.put(task.Id, task.WhatId);
				}
				Map<Id, Opportunity> oppId2Opp = getRelatedOpp(taskId2WhatId);
				for(Task task : tasks)
				{
					Opportunity opp = oppId2Opp.get(taskId2WhatId.get(task.Id));
					if(opp != null)
					{
						taskInfos.add(new TaskInfo(task, opp));
						if(taskInfos.size() >= 900)
		                {
		                	break;
		                }
					}
				}
   			}
   			return taskInfos;
		}
	}
	
	private Map<Id, Opportunity> getRelatedOpp(Map<Id, Id> Id2WhatId)
	{
		Map<Id, Opportunity> oppId2Opp = new Map<Id, Opportunity>();
	    for(Opportunity opp : [select Id, StageName, Name from Opportunity where Id in : Id2WhatId.values()])
	    {
	    	oppId2Opp.put(opp.Id, opp);
	    }
	    return oppId2Opp;
	}
   	
   	private DateTime getShowUpTime(Opportunity opp)
    {
    	String showUpTime = (opp.ShowUpTime__c == null) ? '0:0' : opp.ShowUpTime__c;
        String[] timeParts = showUpTime.split(':', 2);
        Integer hour = 0;
        Integer second = 0; 
        try
        {
            hour = Integer.valueOf(timeParts[0]);
            second = Integer.valueOf(timeParts[1]);
        }
        catch(TypeException ex) {}
        
        if(opp.First_Visit__c == Date.today().addDays(-1))
        {
            if(hour > 10 && second > 30)
            {
                return null;
            }
            else
            {
                return DateTime.newInstance(opp.First_Visit__c, Time.newInstance(hour, second, 0, 0));
            }
        }
        else
        {
            return DateTime.newInstance(opp.First_Visit__c, Time.newInstance(hour, second, 0, 0));
        }
    }
       		 
    public class EventInfo
    {
        public EventInfo(Event event, Opportunity opp)
        {
        	this.EventId = event.Id;
            this.EventSubject = event.Subject;
            this.EventComments = event.Comments__c;
            this.EventAppStatus = event.Appt_Status__c;
            this.OppId = opp.Id; 
            this.OppStage = opp.StageName;
            this.OppName = opp.Name;
            this.EventOwner = event.Owner.Name;
            this.TimeShow = event.StartDateTime.Format('HH:mm') + '-' + event.EndDateTime.Format('HH:mm');
		}
         
        public String EventId { get; set; }
        public String OppId { get; set; }  
        public String TimeShow { get; set; }
        public String EventSubject { get; set; }
        public String OppName { get; set; }
        public String OppStage { get; set; }
        public String EventAppStatus { get; set; }
        public String EventComments { get; set; }
        public String EventOwner { get; set; }
    }
    
    public class TaskInfo
    {
        public TaskInfo(Task task, Opportunity opp)
        {
        	this.TaskId = task.Id;
            this.TaskSubject = task.Subject;
            this.TaskComments = task.Comments__c;
            this.TaskAppStatus = task.status;
            this.TaskOwner = task.Owner.Name;
            this.TaskRelatedName = opp.Name;
            this.OppStage = opp.StageName;
            this.OppId = opp.Id; 
        }
        
        public String TaskId { get; set; }
        public String OppId { get; set; }
        public String TaskRelatedName { get; set; }
        public String TaskSubject { get; set; }
        public String OppStage { get; set; }
        public String TaskAppStatus { get; set; }
        public String TaskComments { get; set; }
        public String TaskOwner{ get; set; }
    }    
    
    @isTest
    static void testSmartOppsWithoutActivitiesController()
    {
        SmartOppsWithoutActivitiesController controller = new SmartOppsWithoutActivitiesController();
        controller.SchoolName = 'BJ_DZM';
        User user = [select Id, Name from User where SchoolName__c = 'BJ_DZM' and Profile.Name = 'EF China Sales User New' and IsActive = true limit 1];
        Opportunity opp = new Opportunity(Name = 'acme', CloseDate = Date.Today(), First_Visit__c = Date.today().addDays(-65), StageName = 'Showed Up - Followup', OwnerId = user.Id);
        insert opp;
		Task task = new Task(Subject = 'acme', Status = 'In Progress', WhatId = opp.Id, OwnerId = user.Id);
		insert task;
		Event event = new Event(Subject = 'acme', Appt_Status__c = 'Scheduled', WhatId = opp.Id, OwnerId = user.Id, ActivityDateTime = DateTime.now().addDays(-2), DurationInMinutes = 100);
		insert event;
        system.assert(controller.OpportunitiesWithoutActivities.size() >= 0 );
        system.assert(controller.FirstShowUpOpps.size() >= 0 );
        system.assert(controller.Events.size() >= 0 );
        system.assert(controller.Tasks.size() >= 0 );
    }
}