/**
 * for project SFT042, performing on ChinaSmartOpportunity, doing the following:
 * #1. clears the Check_Confirmation field when Reschedule_ApptDate or Location is updating
 */
trigger LeadToShow on Opportunity (before update) 
{
    final Id ChinaSmartOppRecordTypeId = '0124000000099sY';
    Map<String, List<Opportunity>> schoolOpportintyMap = new Map<String, List<Opportunity>>();
    for(Opportunity currentOpportunity : trigger.new)
    {
	    	if(currentOpportunity.RecordTypeId == ChinaSmartOppRecordTypeId && currentOpportunity.Location__c != null)
	    	{		    		
	    		Opportunity oldOpportunity = trigger.oldmap.get(currentOpportunity.Id);
            if(!isChanged(oldOpportunity, currentOpportunity, new String[] {'Reschedule_appt_Date_Time__c', 'Location__c'}))
            {
                //only when the specified fields changed, the opp will get processed.
                continue;
            } 
            if(schoolOpportintyMap.containsKey(currentOpportunity.Location__c))
            {
            		schoolOpportintyMap.get(currentOpportunity.Location__c).add(currentOpportunity);
            }
            else
            {
            		schoolOpportintyMap.put(currentOpportunity.Location__c, new List<Opportunity>{currentOpportunity});
            }
	    	}
    }
	if(schoolOpportintyMap.keyset().size() > 0)
	{
		List<String> leadToShowSchools = new List<String>();
		for(String school : schoolOpportintyMap.keyset())
		{
			leadToShowSchools.add(school);
		}
		if(leadToShowSchools.size() > 0)
		{
			leadToShowSchools = RemainingApptsHelper.getValidSchools(leadToShowSchools);
			for(String leadToShowSchool : leadToShowSchools)
			{
				List<Opportunity> items = schoolOpportintyMap.get(leadToShowSchool);
				for(Opportunity item : items)
				{
					item.Check_confirmation__c = false;
				}
			}
		}
	}
     //checks if the fields are changed in the sObjects
    private Boolean isChanged(sObject oldObj, sObject newObj, String[] fields)
    {
        for(String field : fields)
        {
            Object oldValue = oldObj.get(field);
            Object newValue = newObj.get(field);
            if(oldValue != newValue)
            {
                return true;
            }
        }
        return false;
    }
}