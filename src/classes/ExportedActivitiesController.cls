/*
 * controller for ExportedActivities page
 */
public class ExportedActivitiesController 
{
    public ExportedActivitiesController()
    {
        HeaderTitle = ApexPages.currentPage().getParameters().get('name') != null ? ApexPages.currentPage().getParameters().get('name') : 'Activity';
        String id = ApexPages.currentPage().getParameters().get('id');
        String whatId = convertToCaseInsensitiveId(id);
        if(whatId != null)
        {           
            Activities = new List<ActivityInfo>();
            //invokes Etown WebService method
            EventTaskServiceStub.BasicHttpBinding_IDataService stub = new EventTaskServiceStub.BasicHttpBinding_IDataService();
            EventTaskServiceToken.UsernameToken_element token = new EventTaskServiceToken.UsernameToken_element();
            stub.timeout_x = 120*1000;
            token.Username = 'SFService';
            token.Password = '12@c03f@3t0wn';
            EventTaskServiceToken.Security_element security = new EventTaskServiceToken.Security_element();
            security.UsernameToken = token;
            stub.Security = security;
            
            EventTaskServiceContract.ArrayOfEvent events = new EventTaskServiceContract.ArrayOfEvent();
            events.Event = new List<EventTaskServiceContract.Event>();
            try
            {
                events = stub.GetEventsByWhatId(whatId);
            }
            catch(Exception ex)
            { 
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.FATAL, 'Some errors occur: ' + ex.getMessage());
                ApexPages.addMessage(message);
                //for testing method 
                events = new EventTaskServiceContract.ArrayOfEvent();
                EventTaskServiceContract.Event testEvent = new EventTaskServiceContract.Event();
                testEvent.CREATEDBYID='000000000000000AAA';
                events.Event = new List<EventTaskServiceContract.Event>();
                events.Event.add(testEvent);
            }
            
            Set<Id> userList = new Set<Id>();
            if(events !=null && events.Event != null)
            {
                for(EventTaskServiceContract.Event e : events.Event)
                {
                    userList.add(e.CreatedById);
                }
            }
            
            EventTaskServiceContract.ArrayOfTask tasks = new EventTaskServiceContract.ArrayOfTask();
            tasks.Task = new List<EventTaskServiceContract.Task>();
            try
            {
                tasks = stub.GetTasksByWhatId(whatId);
            }
            catch(Exception ex)
            {
                ApexPages.Message message = new ApexPages.Message(ApexPages.Severity.FATAL, 'Some errors occur: ' + ex.getMessage());
                ApexPages.addMessage(message);
                //for testing method 
                tasks = new EventTaskServiceContract.ArrayOfTask();
                EventTaskServiceContract.Task testTask = new EventTaskServiceContract.Task();
                tasks.Task = new List<EventTaskServiceContract.Task>();
                tasks.Task.add(testTask);
            }
            if(tasks != null && tasks.Task != null)
            {
                for(EventTaskServiceContract.Task t : tasks.Task)
                {
                    userList.add(t.CreatedById);
                }
            }
            
            Map<String, String> userNameMap = initializeUserMap(userList);
            
            if(events != null && events.Event != null)
            {
                for(EventTaskServiceContract.Event e : events.Event)
                {
                    ActivityInfo eInfo = new ActivityInfo();
                    eInfo.Id = e.ID;
                    eInfo.Owner = e.OWNER_xC;
                    eInfo.LocalActivityDate = (e.ACTIVITYDATETIME != null) ? e.ACTIVITYDATETIME.format('dd/MM/yyyy') : '';
                    eInfo.ApptStatus = e.APPT_STATUS_xC;
                    eInfo.CreatedById = e.CREATEDBYID;
                    eInfo.CreatedByName = userNameMap.get(e.CREATEDBYID);
                    eInfo.LocalCreatedDate = (e.CREATEDDATE != null) ? e.CREATEDDATE.format('dd/MM/yyyy') : '';
                    eInfo.Subject = e.SUBJECT;
                    eInfo.Description = e.Description;
                    eInfo.Comment = e.Comments_xc;
                    Activities.add(eInfo);
                }
            }
            
            if(tasks != null && tasks.Task != null)
            {
                for(EventTaskServiceContract.Task t : tasks.Task)
                {
                    ActivityInfo tInfo = new ActivityInfo();
                    tInfo.Id = t.ID;
                    tInfo.Owner = t.OWNER_xC;
                    tInfo.LocalActivityDate = (t.ACTIVITYDATE != null) ? t.ACTIVITYDATE.format('dd/MM/yyyy') : '';
                    tInfo.ApptStatus = t.APPT_STATUS_xC;
                    tInfo.CreatedById = t.CREATEDBYID;
                    tInfo.CreatedByName = userNameMap.get(t.CREATEDBYID);
                    tInfo.LocalCreatedDate = (t.CREATEDDATE != null) ? t.CREATEDDATE.format('dd/MM/yyyy') : '';
                    tInfo.Subject = t.SUBJECT;
                    tInfo.Description = t.Description;
                    tInfo.Comment = t.Comments_xc;
                    Activities.add(tInfo);
                }
            }
            //sort by activitydate in descending order
            if(Activities.size() > 0)
            {
                isHasRecord = true;
                for(Integer i = 0; i < Activities.size(); i++)
                {
                    for(Integer j = 0; j < Activities.size(); j++)
                    {
                        ActivityInfo temp = new ActivityInfo();
                        if(Activities[i].LocalActivityDate.compareTo(Activities[j].LocalActivityDate) < 0)
                        {
                            temp = Activities[i];
                            Activities[i] = Activities[j];
                            Activities[j] = temp;
                        }
                    }
                }
            }
        }
    }
    
    public List<ActivityInfo> Activities { get; set; }
    public String HeaderTitle { get; set; }
    public Boolean isHasRecord { get; set; }
    
    private Map<String, String> initializeUserMap(Set<Id> userList)
    {
        Map<String, String> results = new Map<String, String>();
        for(User u : [select Id, Name from User where Id in :userList])
        {
            results.put(u.Id, u.Name);
        }
        return results;
    }
    //Convert 15 to 18 digit ids
    private String convertToCaseInsensitiveId(String id) 
    {
        String hash = '';
        if(id.length() == 15)
        {
            //divides the 15 char into 3 chunks of 5 chars each
            for(Integer i = 0; i < 3; i++)
            {
                Integer n = 0;
                
                for(Integer j = 0; j < 5; j++)
                {
                    String singleChar = id.substring(j + i*5, j + i*5 +1);
                    if(singleChar.compareTo('9') > 0 && singleChar.compareTo('a') < 0)//the char is uppercase 
                    {
                        double d = 2.0;
                        double exp = j;
                        n += Math.pow(d, exp).intValue();
                    }
                }
                if(n >= 0 && n <= 31)
                {
                    hash = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ012345'.substring(n, n + 1);
                    id += hash;
                }
            }
        }
        return id;
    }
    
    public class ActivityInfo
    {
        public String Id { get; set; }
        public String Subject { get; set; }
        public String LocalActivityDate { get; set; }
        public String LocalCreatedDate { get; set; }
        public String CreatedById { get; set; }
        public String CreatedByName { get; set; }
        public String ApptStatus { get; set; }
        public String Owner { get; set; }
        public String Description { get; set; }
        public String Comment { get; set; }
    }
    
    @isTest
    static void testExprotActivities()
    {
        String Id = '00000000000A000';
        PageReference page = new PageReference('/apex/ExportActivities?id=' + Id);
        Test.setCurrentPage(page);
        ExportedActivitiesController controller = new ExportedActivitiesController();
    }
}