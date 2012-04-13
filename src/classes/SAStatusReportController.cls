/*
 * class used to show the Status by Advisor.
 */
public class SAStatusReportController
{
	private static Map<String, String> userId2Name;
	private static List<User> allSAdvisors;
	private static Set<String> partStatus = new Set<String>{'Open', 'On-Hold', 'Closed by System', 'Closed by Manager'};
	private Map<String, Integer> id2AccFirst;  // key: userId, value: task count(include Attempt__c = null and Attempt__c = 1),  the same as follows.
	private Map<String, Integer> id2AccSecond;
	private Map<String, Integer> id2AccThird;
	private Map<String, Integer> id2UnaccFirst;  // include Attempt__c = null and Attempt__c = 1
	private Map<String, Integer> id2UnaccSecond;
	private Map<String, Integer> id2UnaccThird;
	private Map<String, List<StatusInfo>> id2GroupedStatus; // key: user id, value: groupedResult. 
	
	static
	{
		userId2Name = new Map<String, String>();
		allSAdvisors = [select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive = true order by Name limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows()))];
		for(User usr : allSAdvisors)
		{
			userId2Name.put(usr.Id, usr.Name);
		}
	}
	
	public SAStatusReportController()
	{
		StartTask = new Task(ActivityDate = Date.today());
		EndTask = new Task(ActivityDate = Date.today());
		id2AccFirst = new Map<String, Integer>();
		id2AccSecond = new Map<String, Integer>();
		id2AccThird = new Map<String, Integer>();
		id2UnaccFirst = new Map<String, Integer>();
		id2UnaccSecond = new Map<String, Integer>();
		id2UnaccThird = new Map<String, Integer>();
		id2GroupedStatus = new Map<String, List<StatusInfo>>();
		generate();
	}
	
	public Task StartTask { get; set; }
	public Task EndTask { get; set; }
	public List<TaskInfo> TaskInfos { get; set; }
	
	private void initAllMap()
	{
		id2AccFirst.clear();
		id2AccSecond.clear();
		id2AccThird.clear();
		id2UnaccFirst.clear();
		id2UnaccSecond.clear();
		id2UnaccThird.clear();
		id2GroupedStatus.clear();
		for(User usr : allSAdvisors)
		{
			id2AccFirst.put(usr.Id, 0);
			id2AccSecond.put(usr.Id, 0);
			id2AccThird.put(usr.Id, 0);
			id2UnaccFirst.put(usr.Id, 0);
			id2UnaccSecond.put(usr.Id, 0);
			id2UnaccThird.put(usr.Id, 0);
		}
	}
	
	private void populateMapWithData()
	{
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Accomplished' and (Attempt__c = 1 or Attempt__c = null) group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2AccFirst.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Accomplished' and Attempt__c = 2 group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2AccSecond.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Accomplished' and Attempt__c = 3 group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2AccThird.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Unaccomplished' and (Attempt__c = 1 or Attempt__c = null) group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2UnaccFirst.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Unaccomplished' and Attempt__c = 2 group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2UnaccSecond.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select count(Id) c, OwnerId o from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status = 'Unaccomplished' and Attempt__c = 3 group by OwnerId limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			id2UnaccThird.put((String)result.get('o'), (Integer)result.get('c'));
		}
		for(AggregateResult result : [select OwnerId o, Status s, count(Id) c from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :EndTask.ActivityDate and ActivityDate >= :StartTask.ActivityDate and Status in :partStatus group by OwnerId, Status limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows() - 1))])
		{
			if(id2GroupedStatus.get((String)result.get('o')) != null)
			{
				id2GroupedStatus.get((String)result.get('o')).add(new StatusInfo((String)result.get('o'), (String)result.get('s'), (Integer)result.get('c')));
			}
			else
			{
				id2GroupedStatus.put((String)result.get('o'), new List<StatusInfo>{ new StatusInfo((String)result.get('o'), (String)result.get('s'), (Integer)result.get('c'))});
			}
		}
	}
	
	public PageReference generate()
	{
		try
		{
			initAllMap();
			populateMapWithData();
			fillTasks();
		}
		catch(Exception ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
		}
		return null;
	}
	
	private void fillTasks()
	{
		List<TaskInfo> result = new List<TaskInfo>();
		Integer count = 0;
		for(User usr : allSAdvisors)
		{
			count = 0;
			TaskInfo tskInfo = new TaskInfo();
			tskInfo.UserName = userId2Name.get(usr.Id);
			tskInfo.AccFirstAttempt = id2AccFirst.get(usr.Id);
			tskInfo.AccSecondAttempt = id2AccSecond.get(usr.Id);
			tskInfo.AccThirdAttempt = id2AccThird.get(usr.Id);
			tskInfo.UnaccFirstAttempt = id2UnaccFirst.get(usr.Id);
			tskInfo.UnaccSecondAttempt = id2UnaccSecond.get(usr.Id);
			tskInfo.UnaccThirdAttempt = id2UnaccThird.get(usr.Id);
						
			count += id2AccFirst.get(usr.Id) + id2AccSecond.get(usr.Id) + id2AccThird.get(usr.Id);
			count += id2UnaccFirst.get(usr.Id) + id2UnaccSecond.get(usr.Id) + id2UnaccThird.get(usr.Id);
			if(id2GroupedStatus.get(usr.Id) != null)
			{
				tskInfo.OpenNum = returnCountByStatusName(id2GroupedStatus.get(usr.Id), 'Open');
				tskInfo.OnHoldNum = returnCountByStatusName(id2GroupedStatus.get(usr.Id), 'On-Hold');
				tskInfo.ClosedBySystemNum = returnCountByStatusName(id2GroupedStatus.get(usr.Id), 'Closed by System');
				tskInfo.ClosedByManagerNum = returnCountByStatusName(id2GroupedStatus.get(usr.Id), 'Closed by Manager');
				count += tskInfo.OpenNum + tskInfo.OnHoldNum + tskInfo.ClosedBySystemNum + tskInfo.ClosedByManagerNum;
			}
			else
			{
				tskInfo.OpenNum = 0;
				tskInfo.OnHoldNum = 0;
				tskInfo.ClosedBySystemNum = 0;
				tskInfo.ClosedByManagerNum = 0;
			}
			tskInfo.TaskTotal = count;
			
			tskInfo.TotalAttempts = tskInfo.AccFirstAttempt + tskInfo.AccSecondAttempt + tskInfo.AccThirdAttempt + tskInfo.UnaccFirstAttempt + tskInfo.UnaccSecondAttempt + tskInfo.UnaccThirdAttempt + tskInfo.OnHoldNum;
			tskInfo.TotalAccomplished = tskInfo.AccFirstAttempt + tskInfo.AccSecondAttempt + tskInfo.AccThirdAttempt;
			tskInfo.TotalClosed = tskInfo.AccFirstAttempt + tskInfo.AccSecondAttempt + tskInfo.AccThirdAttempt + tskInfo.UnaccThirdAttempt;
			
			if(tskInfo.TotalClosed > 0)
			{
				tskInfo.PickUpRate = string.valueOf(Math.round((tskInfo.TotalAccomplished * 1.0 / tskInfo.TotalClosed) * 100)) + '%';
			}
			else
			{
			    tskInfo.PickUpRate = '0%';
			}
			
			result.add(tskInfo);
		}
		TaskInfos = result;
	}
	
	private Integer returnCountByStatusName(List<StatusInfo> varStatus, String statusName)
	{
		Integer result = -1;
		for(StatusInfo status : varStatus)
		{
			if(status.StatusName == statusName)
			{
				result = status.Count;
			}
		}
		return (result == -1)? 0 : result;
	}
	
	public class StatusInfo
	{
		public StatusInfo(String userId, String name, Integer num)
		{
			this.UserId = userId;
			this.StatusName = name;
			this.Count = (num == null)? 0 : num;
		}
		
		public String UserId { get; set; }
		public String StatusName { get; set; }
		public Integer Count { get; set; }
	}
	
    public class TaskInfo
    {
    	public TaskInfo()
    	{
    	}
    	
    	public String UserName { get; set; }
    	public Integer TaskTotal { get; set; }
    	public Integer AccFirstAttempt { get; set; }
    	public Integer AccSecondAttempt { get; set; }
    	public Integer AccThirdAttempt { get; set; }
    	public Integer UnaccFirstAttempt { get; set; }
    	public Integer UnaccSecondAttempt { get; set; }
    	public Integer UnaccThirdAttempt { get; set; }
    	public Integer OpenNum { get; set; }
    	public Integer OnHoldNum { get; set; }
    	public Integer ClosedBySystemNum { get; set; }
    	public Integer ClosedByManagerNum { get; set; }
    	public Integer TotalAttempts { get; set; }
    	public Integer TotalAccomplished { get; set; }
    	public Integer TotalClosed { get; set; }
    	public String PickUpRate { get; set; }
    }
    
    @isTest
    static void testSAStatusReportController()
    {
    	//create data.
    	List<String> status = new List<String>{'Accomplished', 'Unaccomplished', 'Open', 'On-Hold', 'Closed by System', 'Closed by Manager'};
    	List<User> testAllSA = [select Id, Name from User where (Profile.Name='EnglishTown Study Advisor' or Profile.Name='EnglishTown Study Advisor Manager') and IsActive = true order by Name];
        String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType='Task' limit 1].Id;
        List<Task> testTasks = new List<Task>();
        for(User usr : testAllSA)
        {
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[0], Attempt__c=1, ActivityDate=Date.today()));
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[1], Attempt__c=2, ActivityDate=Date.today()));
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[2], ActivityDate=Date.today()));
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[3], ActivityDate=Date.today()));
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[4], ActivityDate=Date.today()));
        	testTasks.add(new Task(OwnerId=usr.Id, RecordTypeId=recTypeId, Status=status[5], ActivityDate=Date.today()));
        }
        insert testTasks;
        //test logic.
        SAStatusReportController controller = new SAStatusReportController();
        controller.generate();
    }
}