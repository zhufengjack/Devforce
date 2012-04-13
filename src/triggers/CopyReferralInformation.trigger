/**
* 1.after insert a new student product, get the referee information from Parent Account.
* 2.after active a student product, create a Task on Parent Account.
**/
trigger CopyReferralInformation on StudentProduct__c (after insert, after update) 
{
    //after update
    if(trigger.isUpdate)
    {
        Set<Id> activatingProducts = new Set<Id>();
        for(StudentProduct__c prod : Trigger.new)
        {
            StudentProduct__c oldProd = Trigger.oldMap.get(prod.Id);
            if(oldProd.Status__c != prod.Status__c && prod.Status__c == 'Activated')
            {
                activatingProducts.add(prod.Id);
            }
        }
        if(activatingProducts.size() > 0)
        {
            Map<Id, Id> prodRefreeMap = new Map<Id, Id>();//key: Referee Id, value: ownerId
            for(StudentProduct__c stuProd : [select Id, Status__c, Product__r.Family, (select Id, Referee__c, Referee__r.OwnerId, Referee__r.Owner.IsActive, Referee__r.Owner.ManagerId from ProductReferrals__r) from StudentProduct__c where Product__r.IsMain__c=1 and Id in :activatingProducts])
            {
                if(stuProd.ProductReferrals__r.size() > 0 && stuProd.ProductReferrals__r[0].Referee__c != null)
                {
                	//put user manager id into map, if user is inacitve
                	if(!stuProd.ProductReferrals__r[0].Referee__r.Owner.IsActive && stuProd.ProductReferrals__r[0].Referee__r.Owner.ManagerId != null)
                	{
                    	prodRefreeMap.put(stuProd.ProductReferrals__r[0].Referee__c, stuProd.ProductReferrals__r[0].Referee__r.Owner.ManagerId);
                	}
                	else if(stuProd.ProductReferrals__r[0].Referee__r.Owner.IsActive)
                	{
                		prodRefreeMap.put(stuProd.ProductReferrals__r[0].Referee__c, stuProd.ProductReferrals__r[0].Referee__r.OwnerId);
                	}
                }
            }

            if(prodRefreeMap.size() > 0)
            {
                List<Task> tasks = new List<Task>();
                String taskRecordTypeId = null;
                List<RecordType> recordtypes =[select Id, Name from RecordType where Name = 'Phone Call' and SObjectType='Task' limit 1];
                if(!recordtypes.isEmpty())
                {
                    taskRecordTypeId = recordtypes[0].Id;
                }
                for(Id parentAccountId : prodRefreeMap.keySet())
                {
                    Task newTask = new Task(Subject = 'Referral prize notification', OwnerId = prodRefreeMap.get(parentAccountId), WhatId = parentAccountId, ActivityDate = Date.today().addDays(14), Status = 'Not Started', RecordTypeId = taskRecordTypeId);
                    tasks.add(newTask);
                }
                if(tasks.size() > 0)
                {
                	try
                	{
                    	insert tasks;
                	}
                	catch(Exception ex) {}
                }
            }
        }
    }
    
    //after insert
    if(trigger.isInsert)
    {
        Map<Id, Id> accountProdMap = new Map<Id, Id>();//key:AccountId  value: Student product Id
        
        List<StudentProduct__c> prods = [select Id, StudentActual__r.Actual__r.Account__c from StudentProduct__c where Id in :Trigger.New and Product__r.IsMain__c=1 and StudentActual__r.Actual__r.China_Sales_Type__c = 'New' and StudentActual__r.Actual__r.Account__c != null];
        for(StudentProduct__c stuProd : prods)
        {
            accountProdMap.put(stuProd.StudentActual__r.Actual__r.Account__c, stuProd.Id);
        }
        if(accountProdMap.size() > 0)
        {
            List<Referral__c> referrals = new List<Referral__c>();
            for(Referral__c referral : [select Id, ReferralName__c, Product__c from Referral__c where ReferralName__c in : accountProdMap.keySet()])
            {
                if(referral.Product__c == null)
                {
                    referral.Product__c = accountProdMap.get(referral.ReferralName__c);
                    referrals.add(referral);
                }
            }
            if(referrals.size() > 0)
            {
                update referrals;
            }
        }
    }
}