/*
* Invoke "DailyDiscrepancyReportService" class.
*/
global class DailyDiscrepancyReportBatch implements Database.Batchable<sObject> 
{
    public List<String> schoolNameList;
	
	public String query = 'select Id, Name, UserRoleId, SchoolName__c from User where ProfileId = \'00e40000000jdzW\' and IsActive = true limit 1';
	 
	global Database.QueryLocator Start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<User> users)
	{ 
		if(users.size() > 0)
		{   
			DailyDiscrepancyReportService reportService = new DailyDiscrepancyReportService(schoolNameList);
			reportService.sendEmail();
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
	
	}
	
	@isTest
	static void testDailyDiscrepancyReportBatch()
	{
		List<String> nameList = new List<String>{'BJ DWL', 'SH DNR', 'SZ NSD'};
		DailyDiscrepancyReportBatch batch = new DailyDiscrepancyReportBatch();
		batch.schoolNameList = nameList;
		Test.startTest();
		Database.executeBatch(batch);
		Test.stopTest();
	}
}