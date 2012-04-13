/*
 * class used to generate report for SA attempt times by Call Result.
 */
public class SAAttemptByCallResultReportController
{
	private static List<User> allSAdvisors;
	private List<Task> allTasks;
	
	static
	{
		allSAdvisors = [select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive = true order by Name limit :(Test.isRunningTest()? 20 : (Limits.getLimitQueryRows() - Limits.getQueryRows()))];
	}
	
    public SAAttemptByCallResultReportController()
    {
    	StartTask = new Task(ActivityDate=Date.today());
        EndTask = new Task(ActivityDate=Date.today());
        Result2FirstAttempt = new Map<String, Integer>();
        Result2SecondAttempt = new Map<String, Integer>();
        Result2ThirdAttempt = new Map<String, Integer>();
        CallResults = new Set<String>();
        allTasks = new List<Task>();
        ResultData = new List<DataInfo>();
        generate();
    }
    
    public Map<String, Integer> Result2FirstAttempt { get; set; }
    public Map<String, Integer> Result2SecondAttempt { get; set; }
    public Map<String, Integer> Result2ThirdAttempt { get; set; }
    public Set<String> CallResults { get; set; }
    public Task StartTask { get; set; }
    public Task EndTask { get; set; }
    public List<DataInfo> ResultData { get; set; }

    private void populateMapWithTasks()
    {
    	for(Task tsk : allTasks)
    	{
        	if(!CallResults.contains(tsk.CallResult__c))
        	{
        		CallResults.add(tsk.CallResult__c);
        		if(tsk.Attempt__c == 1)
        		{
        			Result2FirstAttempt.put(tsk.CallResult__c, 1);
        		}
        		else if(tsk.Attempt__c == 2)
        		{
        			Result2SecondAttempt.put(tsk.CallResult__c, 1);
        		}
        		else
        		{
        			Result2ThirdAttempt.put(tsk.CallResult__c, 1);
        		}
        	}
        	else
        	{
        		if(tsk.Attempt__c == 1)
        		{
        			if(Result2FirstAttempt.get(tsk.CallResult__c) == null)
        			{
        				Result2FirstAttempt.put(tsk.CallResult__c, 0);
        			}
        			Result2FirstAttempt.put(tsk.CallResult__c, Result2FirstAttempt.get(tsk.CallResult__c)+1);
        		}
        		else if(tsk.Attempt__c == 2)
        		{
        			if(Result2SecondAttempt.get(tsk.CallResult__c) == null)
        			{
        				Result2SecondAttempt.put(tsk.CallResult__c, 0);
        			}
        			Result2SecondAttempt.put(tsk.CallResult__c, Result2SecondAttempt.get(tsk.CallResult__c)+1);
        		}
        		else
        		{
        			if(Result2ThirdAttempt.get(tsk.CallResult__c) == null)
        			{
        				Result2ThirdAttempt.put(tsk.CallResult__c, 0);
        			}
        			Result2ThirdAttempt.put(tsk.CallResult__c, Result2ThirdAttempt.get(tsk.CallResult__c)+1);
        		}
        	}
    	}
    }
    
    public PageReference generate()
    {
    	try
    	{
    		ResultData.clear();
    		allTasks = [select Id, CallResult__c, Attempt__c from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and CallResult__c != null and Attempt__c in (1, 2, 3) and ActivityDate >= :StartTask.ActivityDate and ActivityDate <= :EndTask.ActivityDate limit :(Test.isRunningTest()? 20 : 50000)];
			populateMapWithTasks();
    		for(String str : sortByName(CallResults))
    		{
    			ResultData.add(new DataInfo(str, Result2FirstAttempt, Result2SecondAttempt, Result2ThirdAttempt));
    		}
    	}
    	catch(Exception ex)
    	{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
    	}
    	return null;
    }

	private List<String> sortByName(Set<String> callResults)
	{
		List<String> result = new List<String>();
		if(callResults != null)
		{
			for(String str : callResults)
			{
				result.add(str);
			}
			result.sort();
		}
		return result;
	}
	
    public class DataInfo
    {
        public DataInfo(String callResult, Map<String, Integer> varFirst, Map<String, Integer> varSecond, Map<String, Integer> varThird)
        {
            this.ResultName = callResult;
            this.FirstAttempt = varFirst.get(callResult);
            this.SecondAttempt = varSecond.get(callResult);
            this.ThirdAttempt = varThird.get(callResult);
        }
        
        public String ResultName { get; set; }
        public Integer FirstAttempt { get; set; }
        public Integer SecondAttempt { get; set; }
        public Integer ThirdAttempt { get; set; }
    }
    
    @isTest
    static void testSAAttemptByCallResultReportController()
    {
    	//create data.
    	List<String> callResult = new List<String>{'Successfully discussed study', 'Out of office', 'Hang up', 'Requested call back', 'Disconnected', 'Chatted but not about study', 'Left company'};		
		List<Task> tasks = new List<Task>();
		String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType='Task' limit 1].Id;
		Date initialTestDate = Date.today().addYears(10);
		for(Integer i =0; i < callResult.size(); i++)
		{
			tasks.add(new Task(CallResult__c=callResult[i], RecordTypeId=recTypeId, Attempt__c=Math.mod(i, 3), ActivityDate= initialTestDate.addDays(i)));
		}
		insert tasks;
		
		SAAttemptByCallResultReportController controller = new SAAttemptByCallResultReportController();
		controller.StartTask.ActivityDate = initialTestDate;
		controller.EndTask.ActivityDate = initialTestDate.addDays(20);
		controller.generate();
		System.assert(controller.ResultData != null);
    }
}