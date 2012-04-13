/*
*   When we change sales type(to 'New', 'Upgrade 1', 'Upgrade 2', 'Upgrade 3', 'Upgrade 4', 'Downgrade', 'Renewal') for an Actual that record type is "China Smart Actual Record Type", 
*   we will change the stage of the related opportunity to "Closed Won"; 
*/
trigger ChangeOpportunityStageToCloseWon on Actual__c (before insert, before update) 
{
    Id ChinaSmartActualRecordTypeId = '0124000000098F6'; // This is china smart record type id.
    List<Actual__c> currentActualList = trigger.new;
    Set<Id> oppIdSet = new Set<Id>(); // Store related opp id.
    // If actual sales type value in this set, We should set the stage of related opp to 'Closed Won';
    Set<String> salesTypeValues = new Set<String>{'New', 'Upgrade 1', 'Upgrade 2', 'Upgrade 3', 'Upgrade 4', 'Downgrade', 'Renewal'}; 
    
    for(Actual__c tempActual : currentActualList)
    {
        if(tempActual.RecordTypeId != null && tempActual.RecordTypeId == ChinaSmartActualRecordTypeId)
        {
            Boolean checkResult = checkSalesTypeChange(tempActual);
            if(checkResult == true)
            {
                oppIdSet.add(tempActual.opportunity__c);
            }
        }
    }
    
    if(oppIdSet.size() > 0)
    {
        List<Opportunity> relatedOpps = [select Id, StageName from Opportunity where Id in :oppIdSet and StageName != 'Closed Won'];
        for(Opportunity opp : relatedOpps)
        {
            opp.StageName = 'Closed Won';
        }
        // Updated opp stage. 
        if(relatedOpps.size() > 0)
        {
            update relatedOpps;
        }
    }
    
    public Boolean checkSalesTypeChange(Actual__c tempActual)
    {
        Boolean result = false;
        if(tempActual != null && salesTypeValues.contains(tempActual.China_Sales_Type__c))
        {
            result = true;
        }
        return result;
    }
}