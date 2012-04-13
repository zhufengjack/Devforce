/**
 * when a Event (or an event) is created, check the source object,find the related contact from the source object
*/
trigger ConnectWithContactOfEvent on Event (before insert) 
{/*
    String opportunityObjPrefix = '006';
    String actualObjPrefix = 'a00';
    String collectionProcessObjPrefix = 'a0V';
    map<Id, List<Event>> opportunityMap = new map<Id, List<Event>>();
    map<Id, List<Event>> actualMap = new map<Id, List<Event>>();
    map<Id, List<Event>> collectionProcessMap = new map<Id, List<Event>>();
    map<Id, List<Event>> accountMap = new Map<Id, List<Event>>();//key AccountId value:List<Event>
    for(Event currentEvent : trigger.new)
    {
        if(currentEvent.WhatId != null)
        {
            String currentWateId = currentEvent.WhatId;
            if(currentWateId.startsWith(opportunityObjPrefix))
            {
                if(opportunityMap.containsKey(currentEvent.WhatId))
                {
                    List<Event> items = opportunityMap.get(currentEvent.WhatId);
                    items.add(currentEvent);
                }
                else
                {
                    opportunityMap.put(currentEvent.WhatId, new List<Event>{currentEvent});
                }
            }
            else if(currentWateId.startsWith(actualObjPrefix))
            {
                if(actualMap.containsKey(currentEvent.WhatId))
                {
                    List<Event> items = actualMap.get(currentEvent.WhatId);
                    items.add(currentEvent);
                }
                else
                {
                    actualMap.put(currentEvent.WhatId, new List<Event>{currentEvent});
                }
            }
            else if(currentWateId.startsWith(collectionProcessObjPrefix))
            {
                if(collectionProcessMap.containsKey(currentEvent.WhatId))
                {
                    List<Event> items = collectionProcessMap.get(currentEvent.WhatId);
                    items.add(currentEvent);
                }
                else
                {
                    collectionProcessMap.put(currentEvent.WhatId, new List<Event>{currentEvent});
                }
            }
        }
    }
    if(!opportunityMap.keyset().isEmpty())
    {
        List<Opportunity> opps = [select Id, AccountId from Opportunity where Id in :opportunityMap.keyset() and AccountId != null];
        for(Opportunity opp : opps)
        {
            List<Event> currentEvents = opportunityMap.get(opp.Id);
            if(accountMap.containsKey(opp.AccountId))
            {
                List<Event> subEvents = accountMap.get(opp.AccountId);
                subEvents.addAll(currentEvents);
            }
            else
            {
                accountMap.put(opp.AccountId, currentEvents);
            }
        }
    }
    if(!actualMap.keyset().isEmpty())
    {
        List<Actual__c> actuals = [select Id, Account__c from Actual__c where Id in :actualMap.keyset() and Account__c != null];
        for(Actual__c actual : actuals)
        {
            List<Event> currentEvents = actualMap.get(actual.Id);
            if(accountMap.containsKey(actual.Account__c))
            {
                List<Event> subEvents = accountMap.get(actual.Account__c);
                subEvents.addAll(currentEvents);
            }
            else
            {
                accountMap.put(actual.Account__c, currentEvents);
            }
        }
    }
    if(!collectionProcessMap.keyset().isEmpty())
    {
        List<Collection_Process__c> collectionHostories = [select Id, PaymentRecord__r.Actual__r.Account__c from Collection_Process__c where Id in :collectionProcessMap.keyset() and PaymentRecord__r.Actual__r.Account__c != null];
        for(Collection_Process__c collectionHostory : collectionHostories)
        {
            List<Event> currentEvents = collectionProcessMap.get(collectionHostory.Id);
            if(accountMap.containsKey(collectionHostory.PaymentRecord__r.Actual__r.Account__c))
            {
                List<Event> subEvents = accountMap.get(collectionHostory.PaymentRecord__r.Actual__r.Account__c);
                subEvents.addAll(currentEvents);
            }
            else
            {
                accountMap.put(collectionHostory.PaymentRecord__r.Actual__r.Account__c, currentEvents);
            }
        }
    }
    List<Account> currentAccounts = [select Id, (Select Id From Contacts limit 1) from Account where id in :accountMap.keyset()];
    for(Account currentAccount : currentAccounts)
    {
        if(!currentAccount.Contacts.isEmpty())
        {
            List<Event> currentEvents = accountMap.get(currentAccount.Id);
            for(Event currentEvent : currentEvents)
            {
                currentEvent.WhoId = currentAccount.Contacts[0].Id;
            }
        }
    }*/
}