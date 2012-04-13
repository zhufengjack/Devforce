public class OwnerReassignUtility {
    
    public Integer TransferAccountAmount = 0;
    public Integer TransferOppsCount = 0;
    public Integer TransferEventAmount = 0;
    public Integer TransferTaskAmount = 0;
    public Integer TransferActualAmount = 0;

    public Integer UserBatchCount()
    {
        String OwnerReassignmentClassId = [select Id, Name from ApexClass where Name = 'OwnerReassignment'].Id;
        Integer intCount = [SELECT count() FROM AsyncApexJob WHERE (Status='Queued' or Status='Processing') and JobType='batchApex' and ApexClassID = :OwnerReassignmentClassId];
        return intCount;
    }
    
    public Integer getCurrentUserBatchCount()
    {
        String OwnerReassignmentClassId = [select Id, Name from ApexClass where Name = 'OwnerReassignment'].Id;
        Integer intCount = [select count() from AsyncApexJob where (Status='Queued' or Status='Processing') and JobType='batchApex' and ApexClassID = :OwnerReassignmentClassId and CreatedById = :UserInfo.getUserId()];
        return intCount;
    }
    
    public Map<Id,String> GetToUsersName(List<String> userIds)
    {
        Map<Id, String> userNameMap = new Map<Id, String>();
        List<User> users = [select Id, Name from User where Id in :userIds];
        for(User u : users)
        {
            userNameMap.put(u.Id, u.Name);
        }
        return userNameMap;
    }
    
    public void TransferAccountByOwner(List<Account> tempAccs,List<Opportunity> tempOpps,String ownerId)
    {
        if(ownerId != null)
        {
            Set<Id> accountAndOppIds = new Set<Id>(); // Stores acc and opp ids.
            Set<Id> transferActualOppIds = new Set<Id>(); 
            List<Account> updateAccounts = new List<Account>();
            List<Opportunity> updateOpportunities = new List<Opportunity>();
            for(Account acc:tempAccs)
            {
                acc.OwnerId = ownerId;
                updateAccounts.add(acc);
                AccountAndOppIds.add(acc.Id);
            }
            for(Opportunity opp:tempOpps)
            {
                opp.OwnerId = ownerId;
                updateOpportunities.add(opp);
                AccountAndOppIds.add(opp.Id);
                if(opp.StageName == 'Payment Pending')
                {
                    transferActualOppIds.add(opp.Id);
                }
            }
            if(tempAccs != null)
            {
                update updateAccounts;
            }
            if(tempOpps != null)
            {
                update updateOpportunities;
            }
            
            TransferAccountAmount += updateAccounts.size();
            TransferOppsCount += updateOpportunities.size();
            
            // Changes associated actual opportunity owner field.
            List<Actual__c> actualList = [select Id, Opportunity_owner__c, Opportunity__c from Actual__c where Opportunity__c in :accountAndOppIds and Opportunity__c != null];
            List<Actual__c> updateActualList = new List<Actual__c>();
            for(Actual__c actual : actualList)
            {
                 actual.Opportunity_owner__c = ownerId;
                 if(transferActualOppIds.contains(actual.Opportunity__c))
                 {
                     actual.OwnerId = ownerId;
                     TransferActualAmount++;
                 }
                 updateActualList.add(actual);
            }
            if(updateActualList.size() > 0)
            {
               update updateActualList;
            }
            
            // Changes events owner.
            List<Event> eventList = [select Id, OwnerId from Event where WhatId in :accountAndOppIds];
            List<Event> updateEventList = new List<Event>();
            for(Event e : eventList)
            {
                e.OwnerId = ownerId;
                updateEventList.add(e);
            }
            if(updateEventList.size() > 0)
            {
                update updateEventList;
            }
            TransferEventAmount = eventList.size();
            
            // Changes tasks owner;
            List<Task> taskList = [select Id, OwnerId from Task where WhatId in :accountAndOppIds];
            List<Task> updateTaskList = new List<Task>();
            for(Task t : taskList)
            {
                t.OwnerId = ownerId;
                updateTaskList.add(t);
            }
            if(updateTaskList.size() > 0)
            {
                update updateTaskList;
            }
            TransferTaskAmount = taskList.size();
        }
    }
    
    @isTest
    static void testOwnerReassignUtility()
    {
        OwnerReassignUtility utility = new OwnerReassignUtility();
        utility.getCurrentUserBatchCount();
        utility.UserBatchCount();
    }
}