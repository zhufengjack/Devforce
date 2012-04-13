/*
 * for Brazil actuals, updates the actual status according to the financial fields
 * Pony Ma Added support for ROLA record type
 * Pony Ma 2012-02-25 Refactored the trigger
 */
trigger AutoPaymentStatus on Actual__c (before insert, after insert, after update) 
{
    String BrazilActualRecordTypeId = '0124000000098gR';
    String MexicoActualRecordTypeId = '0124000000099IB';
    String USActualRecordTypeId = '012400000009A3C';    
    //String ROLAActualRecordTypeId='01290000000NWkv';
    
    Set<String> setCancelStatus=new Set<String>();
  	setCancelStatus.add('Cancelled-In Guarantee');
  	setCancelStatus.add('Cancelled-Product Change');
  	setCancelStatus.add('Cancelled-no Penalty');
  	setCancelStatus.add('Cancelled-90 Days');
  	setCancelStatus.add('Cancelled with Penalty');
  	setCancelStatus.add('Bad debt-written off');
    
    if(Trigger.isAfter && Trigger.isUpdate){
    	List<Actual__c> lstActualToUpdate=new List<Actual__c>();
    	List<Payment_Record__c> lstPaymentToUpdate=new List<Payment_Record__c>();
    	List<Messaging.SingleEmailMessage> lstMail = new List<Messaging.SingleEmailMessage>();
    	
    	List<Actual__c> lstActual = [select Id, T_C__c,CollectedAmount__c, Collected__c, RecordTypeId, Opportunity__r.Name, Approved__c, Bad_debt_write_off_date__c, Refund_Date__c, Discount_Amount__c, Final_Price__c, Email_2__c, Product_Changed__c, Failed_Payment_Records__c,Refund_Amount_from_after_sales__c,  Status__c, (Select Due_Date__c, Status__c From Payment_Record__r where Status__c = 'Due' and Due_Date__c >= :date.today()) from Actual__c where Id in :Trigger.new];
    	for(Actual__c actual:lstActual){
    		Actual__c oldActual = Trigger.oldMap.get(actual.Id);
    		if(actual.Approved__c && isChanged(oldActual, actual, new String[] {'T_C__c', 'CollectedAmount__c', 'Collected__c', 'Approved__c', 'Refund_Amount_from_after_sales__c', 'Discount_Amount__c', 'Final_Price__c', 'Failed_Payment_Records__c', 'Refund_Date__c', 'Bad_debt_write_off_date__c', 'Product_Changed__c'}))
            {
            	actual.Collected__c = actual.CollectedAmount__c;
            	actual.Refund_Amount__c = actual.Refund_Amount_from_after_sales__c;
            	
            	//BR needs to check T&C
            	if(!setCancelStatus.contains(actual.Status__c) && (actual.T_C__c || actual.RecordTypeId!=BrazilActualRecordTypeId)){
	            	if(actual.Failed_Payment_Records__c == 0)
	              	{
	                    if((actual.Payment_Record__r.size()>1) && oldActual.Failed_Payment_Records__c == 1){
	                    	actual.Status__c = 'In Progress';
	                    }
	              	}else if(actual.Failed_Payment_Records__c == 1){
	              		actual.Status__c = 'Delinquent';			
	              	}else if(actual.Failed_Payment_Records__c >= 2){
	              		actual.Status__c = 'Defaulted';		
	              	}
	              	
	              	if(actual.Collected__c + actual.Discount_Amount__c == actual.Final_Price__c){
	              		actual.Status__c = 'Paid in Full';		
	              	}
            	}
              	              	              	
              	if(actual.Product_Changed__c == true && oldActual.Product_Changed__c != true){
              		actual.Status__c = 'Cancelled-Product Change';	
              	}
              	
              	if(actual.Bad_debt_write_off_date__c != null){
              		actual.Status__c = 'Bad debt-written off';	
              	}	            	            	             
	            
	            if(oldActual.Approved__c != true && (actual.RecordTypeId == MexicoActualRecordTypeId || actual.RecordTypeId == USActualRecordTypeId) && actual.Email_2__c != null)
              	{
                  	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();                 
                  	String mexicoUSEmailTemplateId;//a existed email template for mexico or USA
                  	if(actual.RecordTypeId == MexicoActualRecordTypeId)
                  	{
                    	mexicoUSEmailTemplateId = '00X40000000wj7q';
                  	}
                  	else
                  	{
                    	mexicoUSEmailTemplateId = '00X40000000w91W';
                  	}                      
                  	EmailTemplate template = [select Subject, HtmlValue, Body from EmailTemplate where Id = :mexicoUSEmailTemplateId limit 1];
                  	mail.setToAddresses(new String[]{actual.Email_2__c});//actual.Email_2__c = Opportunity__r.Email__c
                  	String emailBody = template.Body.replace('{Lead First Name}', actual.Opportunity__r.Name);
                  	//String HtmlEmailValue = template.HtmlValue.replace('{Lead First Name}', actual.Opportunity__r.Name);
                  	mail.setPlainTextBody(emailBody);
                  	mail.setHtmlBody(emailBody);
                  	mail.setSubject(template.Subject);
                  	mail.setSenderDisplayName('EnglishTown Support');
                  	mail.setReplyTo('no-reply@Englishtown.com');
                   	lstMail.add(mail);
              }
              
              lstActualToUpdate.add(actual);	                           			   
            }
            
            if(actual.Status__c!=oldActual.Status__c && setCancelStatus.contains(actual.Status__c)){
            	if(!actual.Payment_Record__r.isEmpty())
                {
                  for(Payment_Record__c record : actual.Payment_Record__r) 
                  {
                    record.Status__c = 'Cancelled';
                    lstPaymentToUpdate.add(record);
                  }
                }	
            }
            	
    	}
    	
    	if(!lstActualToUpdate.isEmpty()){
    		update lstActualToUpdate;        		
    		if(!lstMail.isEmpty()){
    			//Messaging.sendEmail(lstMail);	
    		}
    	}  
    	
    	if(!lstPaymentToUpdate.isEmpty()){
			update lstPaymentToUpdate;
		}  	   	
    }
    
    if(Trigger.isBefore && Trigger.isInsert){
    	map<Id, Actual__c> oppActualMap = new Map<Id, Actual__c>();
		for(Actual__c actual : trigger.new)
		{
			if(actual.Opportunity__c != null)
			{
				oppActualMap.put(actual.Opportunity__c, actual);
			}
		}
		List<Opportunity> currentOpps = [select Id, Email__c from Opportunity where Id in :oppActualMap.keyset()];
		for(Opportunity currentOpp : currentOpps)
		{
			Actual__c currentActual = oppActualMap.get(currentOpp.Id);
			if(currentActual != null)
			{
				currentActual.Email__c = currentOpp.Email__c;
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