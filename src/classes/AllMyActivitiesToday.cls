public class AllMyActivitiesToday {
public string userid{get;set;}

public List<TaskInfo> allmytasktoday{
get{
    List<TaskInfo> result=new List<TaskInfo>();
    List<Task> mytasks=[select Id, WhatId, Subject, Comments__c, Status, Appt_Status__c from Task where OwnerId = :userid and ActivityDate=:Date.Today()];
    Set<Id> taskid=new Set<Id>();
    map<Id,Opportunity> oppmap=new map<Id,Opportunity>();
    for(Task mytask: mytasks)
    {
        taskid.add(mytask.WhatId);
    }
     List<Opportunity> listopp=[select Id,Name,StageName from Opportunity where id in :taskid];
     for(Opportunity myopp:listopp)
        {
            oppmap.put(myopp.Id,myopp);
            
        }
     for(Task task:mytasks)
     {
     Opportunity opp=oppmap.get(task.WhatId);
     if(opp!=null)
     {
        result.add(new TaskInfo(task,opp));
     }
     }
      
     
     return result;
}
}
public Integer allmytasktodaylength{
    get{
    return allmytasktoday.size();
    }
    }
    public List<EventInfo> allmyeventtoday{
    get{
    List<EventInfo> eventresult=new List<EventInfo>();
    List<Event> eventList = [select Id, whatId, Subject, StartDateTime, EndDateTime, Comments__c, Appt_Status__c from Event where OwnerId =:userid and ActivityDate = :Date.Today() ];
    Set<Id> eventid=new Set<Id>();
    map<Id,Opportunity> oppmap=new map<Id,Opportunity>();
    for(Event myevent:eventList){
        eventid.add(myevent.WhatId);
    }
    List<Opportunity> eventlistopp=[select Id,Name,StageName from Opportunity where id in :eventid];
    for(Opportunity opp: eventlistopp)
        {
            oppmap.put(opp.Id,opp);
        }
     
    for(Event e:eventList) 
    {
    Opportunity opp=oppmap.get(e.WhatId);
    if(opp!=null){
    eventresult.add(new EventInfo(e,opp));
    }

    }
    
    return eventresult;
    }

}
public Integer allmyeventtodaylength{
get{
return allmyeventtoday.size();
}
}
    public List<OppInfo> sixtyopp{
    get{
            List<OppInfo> sixoppinfo=new List<OppInfo>();
            Date firstdate=Date.today().addDays(-60);
            Date seconddate=Date.today().addDays(-90);
            List<Opportunity> result = [select Id,Name,StageName,First_Visit__c,OwnerId,Comments__c,Mobile__c,Account.Id,Account.Name,Owner.Name from opportunity where First_Visit__c > :seconddate and First_Visit__c <:firstdate and(StageName = 'Showed Up - Followup' or StageName='Payment Pending') and OwnerId=:userid order by OwnerId,StageName];
            for(Opportunity opp:result)
            {
            sixoppinfo.add(new OppInfo(opp));
            } 
            
    return sixoppinfo;
    }
    }

public Integer sixtyopplength{
get{
return sixtyopp.size();
}
}



  public class EventInfo
    {
            
        public EventInfo(Event event, Opportunity opp)
        {
            
            this.EventSubject = event.Subject;
            this.EventComments = event.Comments__c;
            this.EventAppStatus = event.Appt_Status__c;
            this.EvnId = event.Id;
            this.OppStage = opp.StageName;
            this.OppName = opp.Name;
            this.OppId = opp.Id; 
            String startTime = event.StartDateTime.Format('h:mm');
            String endTime = event.EndDateTime.Format('h:mm');
            this.TimeShow = startTime + '-' + endTime;
            if(event.Comments__c != null  && event.Comments__c != '' && event.Appt_Status__c != 'scheduled')
            {
                this.isDone = true ;
            }
    }
         
        public Boolean IsDone { get; set; }
        public String EvnId { get; set; }
        public String OppId { get; set; }  
        public String TimeShow { get; set; }
        public String EventSubject { get; set; }
        public String OppName { get; set; }
        public String OppStage { get; set; }
        public String EventAppStatus { get; set; }
        public String EventComments { get; set; }
            
    }
    
    public class TaskInfo
    {
        private Task internalTask;
        private Opportunity internalOpp;
        private Set<String> closedStatusList;
            
        public TaskInfo(Task task, Opportunity opp)
        {
            this.internalTask = task;
            this.internalOpp = opp;
            this.TaskSubject = task.Subject;
            this.TaskComments = task.Comments__c;
            this.TaskAppStatus = task.status;
            this.TaskId = task.Id;
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
        
    }
      public class OppInfo{
    public String oppname{set;get;}
    public String oppstage{set;get;}
    public String oppcomments{set;get;}
    public String firstshowup{set;get;}
    public String Accountowner{set;get;}
    public String mobile{set;get;}
    public String Id{Set;get;}
    
    public OppInfo(Opportunity opp){
        this.oppname=opp.Name;
        this.oppstage=opp.StageName;
        this.oppcomments=opp.Comments__c;
        this.firstshowup=opp.First_Visit__c.format();
        this.Accountowner=opp.Owner.Name;
        this.mobile=opp.Mobile__c;
        this.Id=opp.Id;
    }
    
    
    }    
    @isTest
    static void testAllMyActivitiesToday()
    {
    AllMyActivitiesToday allmy=new AllMyActivitiesToday();
    Opportunity opp=[select Id,Name,StageName from Opportunity limit 1];
    Task t=[select Id,subject,WhoId,WhatId,Status,Comments__c from Task limit 1];
    Event e=[Select Subject,Comments__c,Appt_Status__c,Id,StartDateTime,EndDateTime from Event limit 1 ];
    EventInfo ei=new EventInfo(e,opp);
    TaskInfo ti=new TaskInfo(t,opp);
   
    
    }
}