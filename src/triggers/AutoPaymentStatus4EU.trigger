/*
 * for EU actuals, updates the actual status according to the financial fields
 * Author Jerry Hong
 */
trigger AutoPaymentStatus4EU on Actual__c (after insert, after update) 
{
  String FranceActualRecordTypeId = '0124000000099Xa';
    String GermanyActualRecordTypeId = '012400000009Axj';
    String ItalyActualRecordTypeId = '012400000009BQb';
    String SpainActualRecordTypeId = '012400000009Axe';
    
  //String MeastActualRecordTypeId = '012O00000004JHJ'; //RecordTypeId in Sandbox
    String MeastActualRecordTypeId = '01290000000LahC';   //RecordTypeId in Production
    //String UkActualRecordTypeId = '012O00000004JtS';    //RecordTypeId in Sandbox
    String UkActualRecordTypeId = '01290000000MDyo';      //RecordTypeId in Production
    
    String KoreanActualRecordTypeId='0124000000098X5';
    String JapanActualRecordTypeId='012N000000008wR';
     

    List<Actual__c> actuals = 
    [select Id, CollectedAmount__c, Collected__c, RecordTypeId, Opportunity__r.Name, 
    Approved__c, Bad_debt_write_off_date__c, Refund_Date__c, Discount_Amount__c, Final_Price__c, Email_2__c, 
    Product_Changed__c, Failed_Payment_Records__c,Refund_Amount_from_after_sales__c,  Status__c, 
    (Select Due_Date__c, Status__c From Payment_Record__r where Status__c = 'Due' and Due_Date__c >= :date.today()) 
    from Actual__c where Id in :Trigger.new 
    and 
    (RecordTypeId = :FranceActualRecordTypeId
    or RecordTypeId = :GermanyActualRecordTypeId
    or RecordTypeId = :ItalyActualRecordTypeId
    or RecordTypeId = :SpainActualRecordTypeId
    or RecordTypeId = :MeastActualRecordTypeId
    or RecordTypeId = :UkActualRecordTypeId
    or RecordTypeId = :KoreanActualRecordTypeId
    or RecordTypeId = :JapanActualRecordTypeId)];
    
    
    
    List<Actual__c> newActuals = new List<Actual__c>();
    List<Payment_Record__c> payments = new List<Payment_Record__c>();
    List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
    if(Trigger.isAfter)
    {
        if(Trigger.isUpdate) 
        {
            for(Actual__c actual : actuals)
            {
                Actual__c oldActual = Trigger.oldMap.get(actual.Id);
                if(!isChanged(oldActual, actual, new String[] 
                { 'CollectedAmount__c', 'Collected__c', 'Approved__c', 'Refund_Amount_from_after_sales__c', 'Discount_Amount__c', 
                  'Final_Price__c', 'Failed_Payment_Records__c', 'Refund_Date__c', 'Bad_debt_write_off_date__c', 'Product_Changed__c'}))
                {
                    //only when the specified fields changed, the actual will get processed.
                    continue;
                }
                if(actual.Approved__c == true)
                {
                  if(actual.Collected__c == null)
                  {
                      actual.Collected__c = 0;
                  }
                  actual.Collected__c = actual.CollectedAmount__c;
                  if(actual.Refund_Amount_from_after_sales__c != oldActual.Refund_Amount_from_after_sales__c)
                  {
                      actual.Refund_Amount__c = actual.Refund_Amount_from_after_sales__c;
                  }
                  //David added 2011-6-20
                  if(actual.Failed_Payment_Records__c == 0 && oldActual.Failed_Payment_Records__c == 1)
	              {
	                  actual.Status__c = 'In Progress';
	              } 
	              //end added                                
                  if(actual.Collected__c + actual.Discount_Amount__c == actual.Final_Price__c)
                  {
                      actual.Status__c = 'Paid in Full';
                  }
                  if(actual.Failed_Payment_Records__c == 1)
                  {
                      actual.Status__c = 'Delinquent';
                  }
                  if(actual.Failed_Payment_Records__c >= 2)
                  {
                      actual.Status__c = 'Defaulted';
                  }
                  if(actual.Product_Changed__c == true && oldActual.Product_Changed__c != true)
                  {
                      actual.Status__c = 'Cancelled-Product Change';
                  }
                  if(actual.Bad_debt_write_off_date__c != null)
                  {
                      actual.Status__c = 'Bad debt-written off';
                  }
                  if(actual.Status__c == 'Cancelled-In Guarantee' && oldActual.Status__c != 'Cancelled-In Guarantee')
                  {
                    if(!actual.Payment_Record__r.isEmpty())
                    {
                      for(Payment_Record__c record : actual.Payment_Record__r) 
                      {
                        record.Status__c = 'cancelled';
                        payments.add(record);
                      }
                    }
                  }
                  newActuals.add(actual);
                }
            }
            update newActuals;
            if(!payments.isEmpty()) 
            {
              update payments;
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