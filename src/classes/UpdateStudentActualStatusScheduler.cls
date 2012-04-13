/*
 * A schedule job to update status of student’s actual and product automatically
 */
global class UpdateStudentActualStatusScheduler implements Database.Batchable<sObject>, Schedulable
{
	public String queryString = 'select Id from StudentActual__c where Status__c = \'Activated\' and OrderEndDate__c != null and OrderEndDate__c <= :currentDay';
	
	// The schedulable Database.Batchable interface contains 3 methods that must be implemented.
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
    	Date currentDay = Date.today();
    	return Database.getQueryLocator(queryString); //limit 500 [select Id from StudentActual__c where Status__c = 'Activated' and OrderEndDate__c <= :Date.today()] 
    }
    
    global void execute(Database.BatchableContext BC, List<StudentActual__c> studentActuals)
    {
		if(studentActuals.size() > 0)
		{
			Set<String> studentActualIds = new Set<String>();
			List<StudentActual__c> updateStudentActuals = new List<StudentActual__c>();
			for(StudentActual__c studentActual : studentActuals)
			{
			   studentActualIds.add(studentActual.Id);
			   updateStudentActuals.add(new StudentActual__c(Id = studentActual.Id, Status__c = 'Expired'));
			}
			List<StudentProduct__c> studentProducts = [select Id from StudentProduct__c where StudentActual__c in :studentActualIds and Status__c = 'Activated'];
			List<StudentProduct__c> updateStudentProducts = new List<StudentProduct__c>();
			for(StudentProduct__c studentProduct : studentProducts)
			{
			    studentProduct.Status__c = 'Expired';
			    updateStudentProducts.add(studentProduct);
			} 
			try 
			{
				update updateStudentActuals;
				update updateStudentProducts;
			}
			catch(Exception ex)
			{
				String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
				String subject = 'Error occurred on UpdateStudentActualStatusScheduler';
                EtownCourseHelper.sendErrorInfoEmail(subject, error);
			}
		}
	}
	
	global void finish(Database.BatchableContext BC)
    {
    	
    }
    
    // The schedulable interface contains a method that must be implemented.
    global void execute(SchedulableContext SC)
    {
    	Database.executeBatch(new UpdateStudentActualStatusScheduler());
    }
	
	@isTest
	static void testUpdateStudentActualStatusScheduler()
	{
		Actual__c testActual = new Actual__c();
		insert testActual;
		StudentActual__c testSA = new StudentActual__c(Actual__c = testActual.Id, Status__c = 'Activated', OrderEndDate__c = Date.today());
		insert testSA;
		StudentProduct__c testSP = new StudentProduct__c(Name = 'acme test', Status__c = 'Activated', StudentActual__c = testSA.Id);
		insert testSP;
		Test.startTest();
        UpdateStudentActualStatusScheduler batch = new UpdateStudentActualStatusScheduler();
        batch.queryString = batch.queryString + ' and Name like \'acme%\'';
        Database.executeBatch(batch);
        SchedulableContext contenx;
        batch.execute(contenx);
        Test.stopTest();    
	}
}