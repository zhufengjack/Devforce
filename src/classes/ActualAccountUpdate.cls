global class ActualAccountUpdate implements Database.Batchable<sObject>
{
	public String query = 'select Id, Account__c, Opportunity__r.AccountId, Contract_Type__c from Actual__c' +  
							' where RecordType.Name = \'China Smart Actual Record Type\'' + 
							' and StudentActualCount__c = 1 and CreatedDate < 2008-08-01T00:00:00Z and CreatedDate > 2008-06-30T00:00:00Z and Account__c = null';
	
	global Database.QueryLocator Start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<Actual__c> actuals)
	{
		if(actuals != null)
		{
			//System.debug('##### actuals size ### : ' + actuals.size());
			List<Actual__c> results = new List<Actual__c>();
			for(Actual__c actual : actuals)
			{
				if(actual.opportunity__r.AccountId != null)
				{
					actual.Account__c = actual.opportunity__r.AccountId;
					if(actual.Contract_Type__c == null)
					{
						actual.Contract_Type__c = 'B2C';
					}
					results.add(actual);
				}
			}
			if(results.size() > 0)
			{
				update results;
			}
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
	
	}
	
	@isTest
	static void testActualAccountUpdate()
	{
		Account acc = new Account(Name = 'test');
		insert acc;
		Contact con = new Contact(LastName = 'con', AccountId = acc.Id);
		insert con;
		Opportunity opp = new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name = 'o1', AccountId = acc.Id, Location__c = 'BJ CYM');
		insert opp;
		Actual__c actual = new Actual__c(Opportunity__c = opp.Id);
		insert actual;
		test.startTest();
		ActualAccountUpdate aa = new ActualAccountUpdate();
		aa.query = 'select Id, Account__c, Opportunity__r.AccountId, Contract_Type__c from Actual__c where id = \'' + actual.Id + '\'';
		Id batchProcessId = Database.executeBatch(aa);
		test.stopTest();
		//System.assertEquals(acc.Id, [select Account__c from Actual__c where Id = :actual.Id].Account__c);
		//System.assertEquals('B2C', [select Contract_Type__c from Actual__c where Id = :actual.Id].Contract_Type__c);
	}
}