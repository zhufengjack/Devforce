//when user transfers account to a FTM user, sets the FTMName of the related opportunities to the new owner
trigger SetOpportunityFTMName on Account (after update) 
{
    String Profile_EF_China_Sales_FTM = '00e40000001BNBh';
    Set<Id> accIds = new Set<Id>();
    for(Account acc : Trigger.new)
    {
        Account oldAcc = Trigger.oldMap.get(acc.Id);
        if(oldAcc.OwnerId != acc.OwnerId)
        {   //changing Owner
            accIds.add(acc.Id);
        }
    }
    if(accIds.size() > 0)
    {
        //select open opportunities
        List<Account> ftmAccounts = [select Id, OwnerId, (select Id from Opportunities where StageName in ('Set Appt', 'Showed Up - Followup', 'Appt No Show - Rescheduled', 'Appt No Show - Call Later', 'Payment Pending', 'Free Trial') and RecordType.Name='China Smart Record Type') 
                                    from Account where Id in :accIds and Owner.ProfileId=:Profile_EF_China_Sales_FTM];  
        List<Opportunity> opps = new List<Opportunity>();
        for(Account ftmAccount : ftmAccounts)
        {
            for(Opportunity opp : ftmAccount.Opportunities)
            {
                opp.FTM_Name__c = ftmAccount.OwnerId;
                opps.add(opp);
                if(opps.size() > 900)
                {
                    update opps;
                    opps = new List<Opportunity>();
                }
            }
        }
        if(opps.size() > 0)
        {
            update opps;
        }
    }
}