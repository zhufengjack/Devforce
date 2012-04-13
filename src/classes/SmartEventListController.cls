/*
 * A controller of show Event list in home page.
 */
public class SmartEventListController 
{
    public List<EventInfo> Events
    {
        
        get
        {
            List<EventInfo> result = new List<EventInfo>();
            List<Event> eventList = new List<Event>();
            Id currentUserProfileId = UserInfo.getProfileId();
            set<Id> SHTmUserProfileIds = new set<Id>{'00e90000000UVtx', '00e90000000UeEp', '00e30000000hjwF','00e30000000hq1u'};
            if(SHTmUserProfileIds.contains(currentUserProfileId))
            {
                eventList = [select Id, whatId, CreatedDate, Subject, StartDateTime, EndDateTime, Comments__c, Appt_Status__c, ActivityDate from Event where OwnerId =:UserInfo.getUserId() and ActivityDate >= :Date.today() order by ActivityDate, StartDateTime];
            }
            else
            {
                eventList = [select Id, whatId, CreatedDate, ActivityDate, Subject, StartDateTime, EndDateTime, Comments__c, Appt_Status__c from Event where OwnerId =:UserInfo.getUserId() and ActivityDate = :Date.Today() ];
            }
            Map<Id, Id> event2Opp = new Map<Id, Id>();  //key: eventId, value: oppId
            for(Event event : eventList) 
            {
                event2Opp.put(event.Id, event.WhatId);
            }
            
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();  //key: oppId, value: opp
            for(Opportunity opp : [select Id, StageName, Mobile__c, Student_Ranking__c, Location__c, Name from Opportunity where Id in :event2Opp.values()])
            {
                oppMap.put(opp.Id, opp);
            }
            for(Event event : eventList)
            {
                Opportunity opp = oppMap.get(event2Opp.get(event.Id));
                if(opp != null)
                {
                    result.add(new EventInfo(event, opp));
                }
            }
            return result;
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
            this.Mobile = opp.Mobile__c;
            this.School = opp.Location__c;
            this.Ranking = opp.Student_Ranking__c;
            this.CreateDate = event.CreatedDate.Format('M/dd/yyyy');
            this.OppId = opp.Id; 
            String startTime = event.StartDateTime.Format('HH:mm');
            String endTime = event.EndDateTime.Format('HH:mm');
            this.TimeShow = startTime + '-' + endTime;
            this.ActivityDate = event.ActivityDate.format();
            if(event.Appt_Status__c != 'Scheduled' && event.Comments__c != null  &&  event.Comments__c != '')
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
        public String School { get; set; }
        public String Mobile { get; set; }
        public String Ranking { get ; set; }
        public String CreateDate { get; set; }
        public String ActivityDate {get; set;}      
    }
    
    @isTest
    static void testSmartEventListController()
    {
        Opportunity opp = new Opportunity(Name = 'acme', StageName = 'acme', CloseDate = Date.Today());
        insert opp;
        Event eventInstance = new Event();
        eventInstance.DurationInMinutes = 10;
        eventInstance.OwnerId = UserInfo.getUserId();
        eventInstance.ActivityDateTime = DateTime.now();
        eventInstance.WhatId = opp.Id;
        insert eventInstance;
        SmartEventListController newInstance = new SmartEventListController();
        system.assert(newInstance.Events.size() > 0); 
    }
}