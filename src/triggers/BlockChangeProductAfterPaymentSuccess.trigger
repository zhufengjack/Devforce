trigger BlockChangeProductAfterPaymentSuccess on OpportunityLineItem (after delete, before insert, before update) 
{
    List<OpportunityLineItem> opportunityProducts = (Trigger.isDelete) ? Trigger.old : Trigger.new;
    if(opportunityProducts.size() > 0)
    {   
        Map<Id, List<OpportunityLineItem>> opp2OpportunityLineItem = new Map<Id, List<OpportunityLineItem>>();
        for(OpportunityLineItem lineItem : opportunityProducts)
        {
            if(lineItem.OpportunityId != null && opp2OpportunityLineItem.keySet().contains(lineItem.OpportunityId))
            {
                opp2OpportunityLineItem.get(lineItem.OpportunityId).add(lineItem);
            }
            else if(lineItem.OpportunityId != null)
            {
                opp2OpportunityLineItem.put(lineItem.OpportunityId, new List<OpportunityLineItem>{lineItem});
            }
        }
        List<Opportunity> opportunities = [select Id, Name, StageName, (select Id from Actuals__r limit 1) from Opportunity where Id in :opp2OpportunityLineItem.keySet() and RecordType.Name = 'China Telesales Record Type'];
        if(opportunities.size() > 0)
        {
            for(Opportunity opp : opportunities)
            {
                if(opp.Actuals__r.size() > 0)
                {
                    for(OpportunityLineItem lineItem : opp2OpportunityLineItem.get(opp.Id))
                    {
                        lineItem.addError('After creating actual, you can\'t change product.');
                    }
                } 
            }
        }
    }
}