global class OwnerReassignment implements Database.Batchable<sObject>,Database.Stateful
{
	global String query;
	global Id fromUserId;
	global String strObjectType;//Account,Opportunity,Task,Event
	global String strSchoolRoleName;

	global List<String> toUserIds;
	global Map<Id,Integer> mapUserTransAmount;
	global String summaryId;
	
	global Integer totalAccsCount;
	Integer queryAccsCount;
	Integer TransferAccountAmount;
	Integer TransferOppsAmount;
	Integer TransferEventAmount;
	Integer TransferTaskAmount;
	String strTransferTo;

	Set<Id> userIds = new Set<Id>();
	Map<Id, Integer> userTransferAmountMap = new Map<Id, Integer>();
	Map<Id, Integer> userAssignedAmountMap = new Map<Id, Integer>();
	Set<Id> transferCompleteUserIds = new Set<Id>();

	global OwnerReassignment(){
		
		toUserIds = null;
		summaryId = '';
		totalAccsCount = 0;
		queryAccsCount = 0;
		TransferAccountAmount = 0;
		TransferOppsAmount = 0;
		TransferEventAmount = 0;
		TransferTaskAmount = 0;
		strTransferTo = '';
	}
	
	global database.querylocator start(Database.BatchableContext BC)
	{
		userTransferAmountMap = mapUserTransAmount;
		for(Id userId : userTransferAmountMap.keySet())
		{
			userIds.add(userId);
		}

		if(query != '')
			query = 'select Id,Orginal_OwnerId__c,Reassign_Data_ID__c from Reassign_Request__c where Reassign_Request_Summary__c=\'' + summaryId + '\' limit 200';
		else
			query = 'select Id,Orginal_OwnerId__c,Reassign_Data_ID__c from Reassign_Request__c where Reassign_Request_Summary__c=\'' + summaryId + '\'';
		return Database.getQueryLocator(query);
	}
	global void execute(Database.BatchableContext BC, List<Reassign_Request__c> reassignRequests)
	{
		Integer currentBatchIndex = 0;
		Integer batchListSize = reassignRequests.size();
		
		for(Id userId : userIds)
		{
			if(transferCompleteUserIds.contains(userId))
			{
				continue;
			}
			Integer transferAmount = userTransferAmountMap.get(userId);
			Integer i = 0;
			Boolean isBatchScopeBounds = false;
			Set<Id> transferAccoutIds = new Set<Id>();
			
			while(i < transferAmount && !isBatchScopeBounds)
			{
				if(currentBatchIndex < batchListSize)
				{
					transferAccoutIds.add(reassignRequests[currentBatchIndex].Reassign_Data_ID__c);
					i++;
					currentBatchIndex++;
				}
				else
				{
					isBatchScopeBounds = true;
				}
			}
			
			Integer remainAmount = transferAmount - i;
			remainAmount = (remainAmount > 0) ? remainAmount : 0;
			userTransferAmountMap.put(userId, remainAmount);
			
			if(remainAmount == 0)
			{
				transferCompleteUserIds.add(userId);
			}

			if(userAssignedAmountMap.keySet().contains(userId))
			{
				Integer previousAmount = userAssignedAmountMap.get(userId);
				userAssignedAmountMap.put(userId, previousAmount + i);
			}
			else
			{
				userAssignedAmountMap.put(userId, i);
			}
			
			if(transferAccoutIds.size() > 0)
			{
				List<Account> accs = [select Id,OwnerId,Name from Account where Id in :transferAccoutIds];
				List<Opportunity> opps = [select Id,OwnerId,StageName,Name,AccountId from Opportunity where AccountId in :transferAccoutIds and StageName != 'Closed Won'];
				OwnerReassignUtility ownerUtility = new OwnerReassignUtility();
				ownerUtility.TransferAccountByOwner(accs, opps, userId);
				TransferAccountAmount += ownerUtility.TransferAccountAmount;
				TransferOppsAmount += ownerUtility.TransferOppsCount;
				TransferEventAmount += ownerUtility.TransferEventAmount;
				TransferTaskAmount += ownerUtility.TransferTaskAmount;
			}
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
		//Delete Stored Data
		List<Reassign_Request_Summary__c> listSummary = [select Id from Reassign_Request_Summary__c where Id=:summaryId];
		if(listSummary != null)
		{
			delete listSummary;
		}
		//Insert Report Data
		String strTransferToIds = '';
		String strTransferToAmount = '';
		OwnerReassignUtility ownerUtility = new OwnerReassignUtility();
		Map<Id, String> userNameMap = ownerUtility.GetToUsersName(toUserIds);
		for(Id userId : userTransferAmountMap.keySet())
		{
			Integer intMapCount = userAssignedAmountMap.get(userId);
			strTransferToIds += userNameMap.get(userId)+',';
			strTransferToAmount += String.valueOf(intMapCount)+',';
		}
		if(strSchoolRoleName != null)
		{
		    String tempRoleName = strSchoolRoleName.toLowerCase();
		    if(Pattern.matches('^china \\w{6} sales consultant$', tempRoleName))
		    {
		        strSchoolRoleName = tempRoleName.replace('china','').replace('sales consultant','').replace(' ','');
		    }
		}
		Reassignment_Report__c report = new Reassignment_Report__c();
		report.OwnerId = UserInfo.getUserId();
		report.Everyone_Amount__c = strTransferToAmount;
		report.School_Name__c = strSchoolRoleName;
		report.Transfer_From_User__c = fromUserId;
		report.Transfer_To_Users__c = strTransferToIds;
		report.Total_Account_Amount__c = TransferAccountAmount;
		report.Total_Event_Amount__c = TransferEventAmount;
		report.Total_Opportunity_Amount__c = TransferOppsAmount;
		report.Total_Task_Amount__c = TransferTaskAmount;
		report.Transfer_Goal_Count__c = totalAccsCount;
		insert report;
	}

	
    public static testMethod void testTransfer() 
    { 
    	List<Account> accounts = new List<Account>();
    	List<Opportunity> opps = new List<Opportunity>();
    	List<Event> aEvents = new List<Event>(); // Account events;
    	List<Task> aTasks = new List<Task>(); // Account tasks;
    	List<Event> oEvents = new List<Event>(); // Opportunity events;
    	List<Task> oTasks = new List<Task>(); // Opportunity tasks;
    	
    	Integer testSize = 50;
    	String accRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and sObjectType = 'Account'].Id;
    	for(Integer i = 0; i < 50; i++)
    	{
    		accounts.add(new Account(Name = 'OR_Account_' + i, RecordTypeId = accRecordTypeId));
    	}
    	insert accounts;
    	
    	for(Integer j = 0; j < accounts.size(); j++)
    	{
    		Event newEvent = new Event();
			newEvent.DurationInMinutes = 15;
			newEvent.ActivityDateTime = Datetime.now();
			newEvent.ActivityDate = Date.today();
			newEvent.WhatId = accounts[j].Id;
	        newEvent.Subject = 'Web Demo';
			aEvents.add(newEvent);
			
			Task newTask = new Task();
			newTask.WhatId = accounts[j].Id;
			newTask.Priority = 'Normal';
			newTask.Status = 'In Progress';
			aTasks.add(newTask);
			
    		opps.add(new Opportunity(Name = 'OR_Opp_' + j, AccountId = accounts[j].Id, StageName = 'Set Appt', CloseDate = Date.today().addDays(6), China_Sales_Type__c = 'New'));
    	}
    	insert opps;
    	insert aEvents;
    	insert aTasks;
    	
    	List<Actual__c> actuals = new List<Actual__c>();
    	for(Opportunity opp : opps)
    	{
    		Event newEvent = new Event();
			newEvent.DurationInMinutes = 15;
			newEvent.ActivityDateTime = Datetime.now();
			newEvent.ActivityDate = Date.today();
			newEvent.WhatId = opp.Id;
	        newEvent.Subject = 'Web Demo';
			oEvents.add(newEvent);
			
			Task newTask = new Task();
			newTask.WhatId = opp.Id;
			newTask.Priority = 'Normal';
			newTask.Status = 'In Progress';
			oTasks.add(newTask);
			
			actuals.add(new Actual__c(Opportunity__c = opp.Id, Account__c = opp.AccountId));
    	}
    	insert oEvents;
    	insert oTasks; 
    	insert actuals;
    	
    	Reassign_Request_Summary__c requestSummary = new Reassign_Request_Summary__c();
    	insert requestSummary;
    	
		List<Reassign_Request__c> requests = new List<Reassign_Request__c>();
    	for(Account acc : accounts)
    	{
    		requests.add(new Reassign_Request__c(Reassign_Data_ID__c = acc.Id, Reassign_Request_Summary__c = requestSummary.Id));
    	}
    	insert requests;
    	
    	List<User> users = [select Id from User where Profile.Name = 'EF China Sales User New' and IsActive = true limit 3];
    	if(users.size() == 3)
    	{
    		Map<Id, Integer> user2Amount = new Map<Id, Integer>{users[0].Id => 9, users[1].Id => 21, users[2].Id => 20};
    		OwnerReassignment batch = new OwnerReassignment();
    		batch.mapUserTransAmount = user2Amount;
    		batch.summaryId = requestSummary.Id;
    		batch.toUserIds = new List<String>{users[0].Id, users[1].Id, users[2].Id};
    		batch.strSchoolRoleName = 'Test School Name';
    		Test.startTest();
    		Database.executeBatch(batch);
    		Test.stopTest();
    		Reassignment_Report__c assignReport = [select Id, Total_Account_Amount__c, Total_Event_Amount__c, Total_Opportunity_Amount__c, Total_Task_Amount__c from Reassignment_Report__c where School_Name__c = 'Test School Name'];
    		System.assertEquals(testSize, assignReport.Total_Account_Amount__c);
    		System.assertEquals(testSize * 2, assignReport.Total_Event_Amount__c);
    	}
    }
}