global class QueryReassignmentData implements Database.Batchable<sObject>,Database.Stateful
{
    global String email;
    global String replyEmail;
    global String query;
    global String summaryId;
    global Reassign_Request_Summary__c summaryRecord;

    global String ownerId = '';
    global String stageName = '';
    global String schoolRoleId = '';
    global String initialApptDateOpType = '';
    global String lastModifiedDateOpType = '';
    global String initialApptDate = '';
    global String lastModifiedDate = '';  
    
    global String sinitialApptDateOpType = '';
    global String slastModifiedDateOpType = '';
    global String sinitialApptDate = '';
    global String slastModifiedDate = ''; 
    
    global String strQueryString = '';
    global String strOperatorId = '';
    global Integer oppsCount;
    public String queryForTesting = '';
    global QueryReassignmentData()
    {
        summaryId = '';
        oppsCount = 0;
        replyEmail = 'salesforce@ef.com';
    }
    
    global database.querylocator start(Database.BatchableContext BC)
    {
        strQueryString = ReassignmentUtility.GenerateSOQL(stageName, initialApptDateOpType, lastModifiedDateOpType, initialApptDate, lastModifiedDate, sinitialApptDateOpType, slastModifiedDateOpType, sinitialApptDate, slastModifiedDate); 
        if(Test.isRunningTest())
        {
            query = 'select Id,OwnerId from Account where ownerid=\'' + ownerId + '\'' + queryForTesting;
        }
        else
        {
            query = 'select Id,OwnerId from Account where ownerid=\'' + ownerId + '\'';
        }
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
    	if(scope != null && scope.size() >0)
    	{
	        List<Opportunity> opps = null;
	        List<Account> accs = null;
	        if(scope != null && scope.size()>0)
	        {
	            opps = ReassignmentUtility.QueryMatchItems(strQueryString,scope);
	            if(opps != null && opps.size()>0)
	            { 
	                oppsCount += opps.size();
	            }
	            accs = ReassignmentUtility.FindTranAccByOpp(opps);
	        }
	        
	        if(summaryId == '')
	        {
	            //Generate Summary Record
	            summaryRecord = new Reassign_Request_Summary__c();
	            summaryRecord.OwnerId = strOperatorId;
	            summaryRecord.Status__c = 'Started';
	            summaryRecord.Orginal_Owner_Name__c = ReassignmentUtility.getOwnerName(ownerId);
	            summaryRecord.Orginal_OwnerId__c = ownerId; 
	            summaryRecord.School_Role_Id__c = schoolRoleId;
	            if(initialApptDate != '')
	                summaryRecord.Initial_Appt_Date_1__c = initialApptDateOpType+' ' + initialApptDate;
	            if(sinitialApptDate != '')
	                summaryRecord.Initial_Appt_Date_2__c = sinitialApptDateOpType+' '+sinitialApptDate;
	            if(lastModifiedDate != '')
	                summaryRecord.Last_Modified_Date_1__c = lastModifiedDateOpType+' ' + lastModifiedDate;
	            if(slastModifiedDate != '')
	                summaryRecord.Last_Modified_Date_2__c = slastModifiedDateOpType + ' ' +slastModifiedDate;
	            summaryRecord.Opportunity_Stage__c = stageName;
	            insert summaryRecord;
	            summaryId = summaryRecord.Id;
	        }
	        if(accs != null && accs.size()>0)
	        {
	            List<Reassign_Request__c> reassignAccs = new List<Reassign_Request__c>();
	            for(Account acc:accs)
	            {
	                Reassign_Request__c reassignAcc = new Reassign_Request__c();
	                reassignAcc.Orginal_OwnerId__c = ownerId;
	                reassignAcc.Data_Type__c = 'Account';
	                reassignAcc.Reassign_Data_ID__c = acc.Id;
	                reassignAcc.Reassign_Request_Summary__c = summaryId;
	                reassignAccs.add(reassignAcc);
	            }
	            if(reassignAccs.size()>0)
	            {
	                insert reassignAccs;
	            }
	        }
        }
    }
    
    global void finish(Database.BatchableContext BC)
    {
        if(summaryRecord != null)
        {
            summaryRecord.status__c = 'Completed';
            summaryRecord.Opportunity_Count__c = String.valueOf(oppsCount);
            update summaryRecord;
        }
		else
		{
		    //Generate Summary Record
		    summaryRecord = new Reassign_Request_Summary__c();
		    summaryRecord.OwnerId = strOperatorId;
		    summaryRecord.Status__c = 'Completed';
		    summaryRecord.Orginal_Owner_Name__c = ReassignmentUtility.getOwnerName(ownerId);
		    summaryRecord.Orginal_OwnerId__c = ownerId; 
		    summaryRecord.School_Role_Id__c = schoolRoleId;
		    if(initialApptDate != '')
			summaryRecord.Initial_Appt_Date_1__c = initialApptDateOpType+' ' + initialApptDate;
		    if(sinitialApptDate != '')
			summaryRecord.Initial_Appt_Date_2__c = sinitialApptDateOpType+' '+sinitialApptDate;
		    if(lastModifiedDate != '')
			summaryRecord.Last_Modified_Date_1__c = lastModifiedDateOpType+' ' + lastModifiedDate;
		    if(slastModifiedDate != '')
			summaryRecord.Last_Modified_Date_2__c = slastModifiedDateOpType + ' ' +slastModifiedDate;
		    summaryRecord.Opportunity_Stage__c = stageName;
		    insert summaryRecord;
		}
    }
    
    @isTest
    static void testQueryReassignmentData()
    {
        // Creates test data.
        Integer size = 10;
        String accRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and sObjectType = 'Account'].Id;
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < size; i++)
        {
            accounts.add(new Account(RecordTypeId = accRecordTypeId, Name = 'Test_Acc_00' + i));
        }
        insert accounts;
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < size; i++)
        {
            opps.add(new Opportunity(Name = 'Test_Opp_00' + i, Email__c = 'test.' + i + '@m.com', AccountId = accounts[i].Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate, StageName = 'Set Appt', China_Sales_Type__c = 'New'));
        }
        insert opps;
        
        QueryReassignmentData batch = new QueryReassignmentData();
        batch.ownerId = UserInfo.getUserId();
        batch.strOperatorId = UserInfo.getUserId();
        batch.stageName = '*';
        batch.email = 'reassignment.test@m.com';
        batch.queryForTesting = batch.queryForTesting + ' and Name like \'Test_Acc_00%\'';
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testBatch()
    {
    	// Creates test data.
        Integer size = 10;
        String accRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and sObjectType = 'Account'].Id;
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < size; i++)
        {
            accounts.add(new Account(RecordTypeId = accRecordTypeId, Name = 'Test_Acc_00' + i));
        }
        insert accounts;
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < size; i++)
        {
            opps.add(new Opportunity(Name = 'Test_Opp_00' + i, Email__c = 'test.' + i + '@m.com', AccountId = accounts[i].Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate, StageName = 'Set Appt', China_Sales_Type__c = 'New'));
        }
        insert opps;
        QueryReassignmentData batch = new QueryReassignmentData();
        batch.ownerId = UserInfo.getUserId();
        batch.strOperatorId = UserInfo.getUserId();
        batch.stageName = '*';
        batch.email = 'reassignment.test@m.com';
        batch.queryForTesting = batch.queryForTesting + ' and Name like \'Test_Acc_Acme_00\' limit 0';
        Test.startTest();
        Database.executeBatch(batch);
        Test.stopTest();
    }
}