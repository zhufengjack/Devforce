/**
 * when a task (or an event) is created, check the source object,find the related contact from the source object
*/
trigger ConnectWithContact on Task (before insert) 
{
    String opportunityObjPrefix = '006';
    String actualObjPrefix = 'a00';
    String collectionProcessObjPrefix = 'a0V';
    map<Id, List<Task>> opportunityMap = new map<Id, List<Task>>();
    map<Id, List<Task>> actualMap = new map<Id, List<Task>>();
    map<Id, List<Task>> collectionProcessMap = new map<Id, List<Task>>();
    map<Id, List<Task>> accountMap = new Map<Id, List<Task>>();//key AccountId value:List<Task>
    for(Task currentTask : trigger.new)
    {
        if(currentTask.WhatId != null)
        {
            String currentWateId = currentTask.WhatId;
            if(currentWateId.startsWith(opportunityObjPrefix))
            {
                if(opportunityMap.containsKey(currentTask.WhatId))
                {
                    List<Task> items = opportunityMap.get(currentTask.WhatId);
                    items.add(currentTask);
                }
                else
                {
                    opportunityMap.put(currentTask.WhatId, new List<Task>{currentTask});
                }
            }
            else if(currentWateId.startsWith(actualObjPrefix))
            {
                if(actualMap.containsKey(currentTask.WhatId))
                {
                    List<Task> items = actualMap.get(currentTask.WhatId);
                    items.add(currentTask);
                }
                else
                {
                    actualMap.put(currentTask.WhatId, new List<Task>{currentTask});
                }
            }
            else if(currentWateId.startsWith(collectionProcessObjPrefix))
            {
                if(collectionProcessMap.containsKey(currentTask.WhatId))
                {
                    List<Task> items = collectionProcessMap.get(currentTask.WhatId);
                    items.add(currentTask);
                }
                else
                {
                    collectionProcessMap.put(currentTask.WhatId, new List<Task>{currentTask});
                }
            }
        }
    }
    if(!opportunityMap.keyset().isEmpty())
    {
        List<Opportunity> opps = [select Id, AccountId from Opportunity where Id in :opportunityMap.keyset() and AccountId != null];
        for(Opportunity opp : opps)
        {
            List<Task> currentTasks = opportunityMap.get(opp.Id);
            if(accountMap.containsKey(opp.AccountId))
            {
                List<Task> subTasks = accountMap.get(opp.AccountId);
                subTasks.addAll(currentTasks);
            }
            else
            {
                accountMap.put(opp.AccountId, currentTasks);
            }
        }
    }
    if(!actualMap.keyset().isEmpty())
    {
        List<Actual__c> actuals = [select Id, Account__c from Actual__c where Id in :actualMap.keyset() and Account__c != null];
        for(Actual__c actual : actuals)
        {
            List<Task> currentTasks = actualMap.get(actual.Id);
            if(accountMap.containsKey(actual.Account__c))
            {
                List<Task> subTasks = accountMap.get(actual.Account__c);
                subTasks.addAll(currentTasks);
            }
            else
            {
                accountMap.put(actual.Account__c, currentTasks);
            }
        }
    }
    if(!collectionProcessMap.keyset().isEmpty())
    {
        List<Collection_Process__c> collectionHostories = [select Id, PaymentRecord__r.Actual__r.Account__c from Collection_Process__c where Id in :collectionProcessMap.keyset() and PaymentRecord__r.Actual__r.Account__c != null];
        for(Collection_Process__c collectionHostory : collectionHostories)
        {
            List<Task> currentTasks = collectionProcessMap.get(collectionHostory.Id);
            if(accountMap.containsKey(collectionHostory.PaymentRecord__r.Actual__r.Account__c))
            {
                List<Task> subTasks = accountMap.get(collectionHostory.PaymentRecord__r.Actual__r.Account__c);
                subTasks.addAll(currentTasks);
            }
            else
            {
                accountMap.put(collectionHostory.PaymentRecord__r.Actual__r.Account__c, currentTasks);
            }
        }
    }
    List<Account> currentAccounts = [select Id, (Select Id From Contacts limit 1) from Account where id in :accountMap.keyset()];
    for(Account currentAccount : currentAccounts)
    {
        if(!currentAccount.Contacts.isEmpty())
        {
            List<Task> currentTasks = accountMap.get(currentAccount.Id);
            for(Task currentTask : currentTasks)
            {
                currentTask.WhoId = currentAccount.Contacts[0].Id;
            }
        }
    }
}