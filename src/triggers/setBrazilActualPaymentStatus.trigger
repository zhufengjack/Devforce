/*
 * for Brazil actuals only, sets actual status according to the status of student-after_sales
 * Also for EU actuals (Modified by Jerry Hong EF)
 * Pony Ma 2012-01-30 Added support for ROLA Record type
 * Pony Ma 2012-02-23 refactor the class
 */
trigger setBrazilActualPaymentStatus on student_after_sales__c (after insert, after update) 
{  
  	Set<String> setActualId=new Set<String>();
  	Map<String,Actual__c> mapActual=new Map<String,Actual__c>();  
  	List<Actual__c> lstActualToUpdate=new List<Actual__c>();	
  	
  	Set<String> setCancelStatus=new Set<String>();
  	setCancelStatus.add('Cancelled-In Guarantee');
  	setCancelStatus.add('Cancelled-Product Change');
  	setCancelStatus.add('Cancelled-no Penalty');
  	setCancelStatus.add('Cancelled-90 Days');
  	setCancelStatus.add('Cancelled with Penalty');
  	
  	for(student_after_sales__c retention:Trigger.new){
  		if(Trigger.isUpdate){  		
	  		student_after_sales__c oldRetention=Trigger.oldMap.get(retention.Id);  		
	  		if(isChanged(oldRetention, retention, new String[] {'Cancellation_reasons__c', 'Cancellation_status__c', 'Info_for_Payments_Status__c', 
	                  'Refund_date_local_finance__c', 'Course_deactivation_date__c', 'Retention_status__c'})){
	        	setActualId.add(retention.Actual__c);          	
	        }	
  		}else{
  			setActualId.add(retention.Actual__c);
  		}
  	}
  	
    if(setActualId.size()>0){
    	List<Actual__c> lstActual = [select Id, Cancellation_Reason__c, Refund__c, RecordTypeId, Refund_Date__c,Cancellation_Date__c, Retention_Status__c, Status__c, Product_Changed__c from Actual__c where Id in :setActualId]; 	     	      	
    	for(Actual__c act:lstActual){
    		mapActual.put(act.Id,act);
    	}
    	
    	for(student_after_sales__c retention:Trigger.new){
	    	Actual__c actual=mapActual.get(retention.Actual__c);
	    	if(actual!=null){
	    		actual.Cancellation_Reason__c = retention.Cancellation_reasons__c;	    		
	    		actual.Cancellation_Date__c=retention.Course_deactivation_date__c;
	    		actual.Refund_Date__c=retention.Refund_date_local_finance__c;
	    		actual.Retention_Status__c=retention.Retention_Status__c;
	    		
	    		if(retention.Info_for_Payments_Status__c!=null && setCancelStatus.contains(retention.Info_for_Payments_Status__c)){
	    			actual.Status__c=retention.Info_for_Payments_Status__c;
	    		} 
	    		
	    		if(retention.Info_for_Payments_Status__c=='Cancelled-Product Change' || retention.Cancellation_reasons__c=='Would like to upgrade/downgrade to another product'){
	    			actual.Product_Changed__c=true;
	    			actual.Status__c = 'Cancelled-Product Change';	
	    		}
	    		
	    		actual.Refund__c=(actual.Refund_Date__c!=null); 	
	    		lstActualToUpdate.add(actual);	
	    	}
	    }    	
    	update lstActualToUpdate;
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