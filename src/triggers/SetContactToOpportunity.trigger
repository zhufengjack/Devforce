/*
*	Copy contact to opportunity if just one contact existed under the account
*/
trigger SetContactToOpportunity on Opportunity (before insert, before update) 
{
	Set<Opportunity> accountChangedSet = new Set<Opportunity>();
	Set<Id> accountIds = new Set<Id>();
	
	if(trigger.isInsert)
	{
		for(Opportunity opp : trigger.new)
		{
			if(opp.AccountId != null)
			{
				accountChangedSet.add(opp);
				accountIds.add(opp.AccountId);
			}
		}
	}

	if(trigger.isUpdate)
	{
		for(Opportunity opp : trigger.new)
		{
			if(opp.AccountId != null && opp.AccountId != trigger.oldMap.get(opp.Id).AccountId)
			{
				accountChangedSet.add(opp);
				accountIds.add(opp.AccountId);
			}
		}
	}
	
	if(accountChangedSet.size() > 0)
	{
		Map<Id, Id> account2Contact = new Map<Id, Id>();
		List<Account> accounts = [select Id, (select Id from Contacts limit 2) from Account where Id in :accountIds];
		for(Account acc : accounts)
		{
			if(acc.Contacts.size() == 1)
			{
				account2Contact.put(acc.Id, acc.Contacts[0].Id);
			}
		}
		
		// Copy contact to opportunity
		for(Opportunity opp : accountChangedSet)
		{
			if(account2Contact.containsKey(opp.AccountId))
			{
				opp.Contact__c = account2Contact.get(opp.AccountId);
			}
			else
			{
				opp.Contact__c = null;
			}
		}
	}
}