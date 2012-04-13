/*
*	When a lead convert to opportuntiy, account and contact, Copy contact to opportunity.
*/
trigger SetContactToConvertOpportunity on Lead (after update) 
{
	List<Opportunity> oppList = new List<Opportunity>();
	for(Lead lead : trigger.new)
	{
		if(lead.IsConverted && lead.ConvertedOpportunityId != null && lead.ConvertedContactId != null)
		{
			oppList.add(new Opportunity(Id = lead.ConvertedOpportunityId, Contact__c = lead.ConvertedContactId));
		}
	}
	
	if(oppList.size() > 0)
	{
		try
		{
			update oppList;
		}
		catch(DmlException ex)
		{
				for(Lead lead : trigger.new)
				{
					lead.addError(ex.getMessage());
				}
		}
	}
}