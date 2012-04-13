/*
* when a payment is failed, create a collection record.
* Pony Ma 2012-01-30 Added support for ROLA record type
*/
trigger CreateCollectionRecord on Payment_Record__c (before update, after update)
{
	Id brazilCollectionUserId = '00590000000ZdGh'; 
    List<Id> allAffectedTypeId = new List<Id>();
    //actuals of Countries Affected
    Id brazilActualTypeId = '0124000000098gR';
    Id mexicoActualTypeId = '0124000000099IB';
    Id usActualTypeId = '012400000009A3C';
    Id italyActualTypeId = '012400000009BQb';
    Id franceActualTypeId = '0124000000099Xa';
    Id germanyActualTypeId = '012400000009Axj';    
    Id ROLAActualTypeId='01290000000NWkv';
    
    //Id in QA
    //Id ROLAActualTypeId='012N00000000AhO';
    Id KoreanActualTypeId='0124000000098X5';
    Id JapanActualTypeId='012N000000008wR';
    
    allAffectedTypeId.add(brazilActualTypeId);
    allAffectedTypeId.add(mexicoActualTypeId);
    allAffectedTypeId.add(usActualTypeId);
    allAffectedTypeId.add(italyActualTypeId);
    allAffectedTypeId.add(franceActualTypeId);
    allAffectedTypeId.add(germanyActualTypeId);
    allAffectedTypeId.add(ROLAActualTypeId);
    allAffectedTypeId.add(KoreanActualTypeId);
    allAffectedTypeId.add(JapanActualTypeId);
    
    
    List<Collection_Process__c> collections = new List<Collection_Process__c>();
    List<Payment_Record__c> failedPayments = new List<Payment_Record__c>();
    for(Payment_Record__c record : trigger.new)
    {
    		if(Trigger.isBefore)
    		{
    			if(record.Collection_staff__c == null)
        		{
        			record.Collection_staff__c = brazilCollectionUserId;
        		}
    		}
    		else
    		{
	        Payment_Record__c oldRecord = trigger.oldMap.get(record.Id);
	        if(record.Failed_date__c != null && oldRecord.Failed_date__c == null)
	        {
	            //record.Status__c = 'Failed';
	            failedPayments.add(record);
	        }
    		}
    }
    if(!failedPayments.isEmpty())
    {
        failedPayments = [select Id from Payment_Record__c where Id in :failedPayments and Actual__r.RecordTypeId in :allAffectedTypeId];
        for(Payment_Record__c record : failedPayments)
        {
            Collection_Process__c collection = new Collection_Process__c(Collection_date__c = date.today(), OwnerId = brazilCollectionUserId, Collection_status__c = 'In collection', paymentRecord__c = record.Id, Responsible_staff__c = brazilCollectionUserId);
            collections.add(collection);
        }
        if(!collections.isEmpty())
        {
            insert collections;
        }
        for(Payment_Record__c record : failedPayments)
        {       		
            record.Status__c = 'Failed';
        }
        update failedPayments;
    }
}