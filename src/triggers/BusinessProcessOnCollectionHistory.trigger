/**
 * trigger for delete tasks or add new tasks for collection history record when updated the status of this record
*/
trigger BusinessProcessOnCollectionHistory on Collection_Process__c (before insert, after update) 
{
    String phoneCallRecordTypeId = '0123000000095jN';
    List<Task> toBeDeletedTasks = new List<Task>();
    List<Task> toBeAddedTasks = new List<Task>();
    List<Id> toBeDeletedTaskCollectionIds = new List<Id>();
    List<Collection_Process__c> toBeAddedTaskCollectionHistories = new List<Collection_Process__c>();
    map<Id, List<Collection_Process__c>> collectionHistoryMap = new map<Id, List<Collection_Process__c>>();
    if(trigger.isBefore)
    {
        for(Collection_Process__c collectionHistory : trigger.new)
        {           
            if(collectionHistory.paymentRecord__c != null)
            {
                collectionHistory.Responsible_staff__c = UserInfo.getUserId();
                if(collectionHistoryMap.containskey(collectionHistory.paymentRecord__c))
                {
                    List<Collection_Process__c> items = collectionHistoryMap.get(collectionHistory.paymentRecord__c);
                    items.add(collectionHistory);
                    collectionHistoryMap.put(collectionHistory.paymentRecord__c, items);
                }
                else
                {
                    List<Collection_Process__c> items = new List<Collection_Process__c>();              
                    items.add(collectionHistory);
                    collectionHistoryMap.put(collectionHistory.paymentRecord__c, items);
                }
            }
        }
    }
    else if(trigger.isUpdate)
    {
        for(Collection_Process__c collectionHistory : trigger.new)
        {
            Collection_Process__c oldCollectionHistory = trigger.oldMap.get(collectionHistory.Id);
            if(collectionHistory.Collection_status__c != oldCollectionHistory.Collection_status__c && collectionHistory.Collection_status__c == 'In Negotiation')
            {
                toBeDeletedTaskCollectionIds.add(collectionHistory.Id);
                toBeAddedTaskCollectionHistories.add(collectionHistory);
            }
            else if(collectionHistory.Collection_status__c != oldCollectionHistory.Collection_status__c && collectionHistory.Collection_status__c == 'Collected - verified')
            {
                toBeDeletedTaskCollectionIds.add(collectionHistory.Id);
            }
            else if(collectionHistory.Collection_status__c != oldCollectionHistory.Collection_status__c && collectionHistory.Collection_status__c == 'Collected - not verified')
            {
                toBeDeletedTaskCollectionIds.add(collectionHistory.Id);
            }
        }
    }
    List<Payment_Record__c> payments = [Select Id, (Select Id From Collection_Histories__r where (Collection_status__c != 'In collection' and Collection_status__c != 'In Negotiation' and Collection_status__c != 'Sent to retention') order by CreatedDate desc limit 1) From Payment_Record__c where Id in :collectionHistoryMap.keyset()];
    if(!payments.isEmpty())
    {
        for(Payment_Record__c payment : payments)
        {
            List<Collection_Process__c> items = collectionHistoryMap.get(payment.Id);
            if(!payment.Collection_Histories__r.isEmpty())
            {               
                for(Collection_Process__c item : items)
                {
                    item.addError('Error Message:You can not create a new collection record,because of the status of last collection record is not "In collection" or "In Negotiation" or "sent to retention".');
                }
            }
        }
    }
    
    if(!toBeDeletedTaskCollectionIds.isEmpty())
    {
        toBeDeletedTasks = [select Id from Task where Status != 'Completed' and WhatId in :toBeDeletedTaskCollectionIds];
        delete toBeDeletedTasks;
    }
    for(Collection_Process__c toBeAddedTaskCollectionHistorie : toBeAddedTaskCollectionHistories)
    {
        toBeAddedTasks.Add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call', OwnerId = toBeAddedTaskCollectionHistorie.CreatedById, Status = 'Not Started', Priority = 'Normal', WhatId = toBeAddedTaskCollectionHistorie.Id, ActivityDate = date.today().addDays(5)));
    }
    if(!toBeAddedTasks.isEmpty())
    {
        insert toBeAddedTasks;
    }
}