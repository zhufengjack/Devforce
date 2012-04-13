/*
 * this class used to offer service to other components within salesforce. 
 */
global class SAServiceHelper
{
	private static List<User> allSAdvisors = [select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive = true order by Name];
	
    webservice static Boolean serviceForSAStatusReport(String dateFrom, String dateTo)
    {
    	Boolean result = false;
		list<Task> tasks = [select Id from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :date.parse(dateTo) and ActivityDate >= :date.parse(dateFrom) and Status in ('Accomplished', 'Unaccomplished', 'Open', 'On-Hold', 'Closed by System', 'Closed by Manager') limit :(Limits.getLimitQueryRows() - Limits.getQueryRows() - 1)];
    	if(Limits.getLimitQueryRows() - Limits.getQueryRows() >= 100)
		{
			result = true;
		}
    	return result;
    }
    
    webservice static Boolean serviceForSAAttemptByCallResultReport(String dateFrom, String dateTo)
    {
    	Boolean result = false;
		list<Task> tasks = [select Id from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :date.parse(dateTo) and ActivityDate >= :date.parse(dateFrom) and CallResult__c != null and Attempt__c in (1, 2, 3) limit :(Limits.getLimitQueryRows() - Limits.getQueryRows() - 1)];
    	if(Limits.getLimitQueryRows() - Limits.getQueryRows() >= 100)
		{
			result = true;
		}
    	return result;
    }
    
    webservice static Boolean serviceForSATaskCompletionReport(String dateFrom, String dateTo)
    {
    	Boolean result = false;
		list<Task> tasks = [select Id from Task where OwnerId in :allSAdvisors and RecordType.Name = 'Study Advise' and ActivityDate <= :date.parse(dateTo) and ActivityDate >= :date.parse(dateFrom) and (Status = 'Accomplished' or (Status =  'Unaccomplished' and Attempt__c = 3)) limit :(Limits.getLimitQueryRows() - Limits.getQueryRows() - 1)];
    	if(Limits.getLimitQueryRows() - Limits.getQueryRows() >= 100)
		{
			result = true;
		}
    	return result;
    }
    
    @isTest
    static void testSAServiceHelper()
    {
    	String dateFrom = '18/09/2011';
    	String dateTo = '24/08/2011';
    	test.startTest();
    	SAServiceHelper.serviceForSAStatusReport(dateFrom, dateTo);
    	SAServiceHelper.serviceForSAAttemptByCallResultReport(dateFrom, dateTo);
    	SAServiceHelper.serviceForSATaskCompletionReport(dateFrom, dateTo);
    	test.stopTest();
    }
}