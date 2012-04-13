global class OppSyncConactBatchJob implements Database.batchable<SObject>,Database.Stateful{
	global String outputPhone='';
	global String outputMobile='';
	global String outputEmail='';
	global String dt;
	
	global OppSyncConactBatchJob(String pdt){
		dt=pdt;	
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC){      
      outputPhone='Opp Id,Opp Name,Contact ID,Contact Name,Opp Phone,Contact Phone, Opp UpdatedBy,Opp UpdatedDate,Contact UpdatedBy,Contact UpdatedDate';
      outputMobile='Opp Id,Opp Name,Contact ID,Contact Name,Opp Mobile,Contact Mobile, Opp UpdatedBy,Opp UpdatedDate,Contact UpdatedBy,Contact UpdatedDate';
      outputEmail='Opp Id,Opp Name,Contact ID,Contact Name,Opp Email,Contact Email, Opp UpdatedBy,Opp UpdatedDate,Contact UpdatedBy,Contact UpdatedDate';
      
      //dt='2010-02-07T00:00:00Z';
      String query='select Id,Name,Contact__c,Phone2__c,Mobile__c,Email__c,(select Field,CreatedBy.Name,CreatedDate from Histories where Field=\'Phone2__c\' or Field=\'Mobile__c\' or Field=\'created\') from Opportunity  where Contact__c!=null and LastModifiedDate>' + dt;
      return Database.getQueryLocator(query);
   }
	
   global void execute(Database.BatchableContext BC, List<SObject> scope){
   		Set<String> setContactId=new Set<String>();
   		for(SObject obj:scope){
   			Opportunity opp=(Opportunity)obj;
   			setContactId.add(opp.Contact__c);
   		}
   		
   		List<Contact> lstContact=[select Id,Name,Email,Phone,MobilePhone,(select Field,CreatedBy.Name,CreatedDate from Histories where Field='Email' or Field='Phone' or Field='MobilePhone' or Field='created') from Contact where Id in :setContactId];
   		Map<String,Contact> mapContact=new Map<String,Contact>();
   		for(Contact c:lstContact){
   			mapContact.put(c.Id,c);
   		}
   		
     	for(SObject obj:scope){
     		Opportunity o=(Opportunity)obj;
     		Contact c=mapContact.get(o.Contact__c);
     		     		
     		if(c!=null && (c.Phone!=null && c.Phone!='' && o.Phone2__c!=null && o.Phone2__c!='' && c.Phone!=o.Phone2__c)){
     			outputPhone=outputPhone + '\n';	
     			ContactHistory lch=null;
     			OpportunityFieldHistory loh=null;
     			
     			for(ContactHistory ch:c.Histories){
     				if((ch.Field=='created' || ch.Field=='Phone') && (lch==null || lch.Createddate<ch.CreatedDate)){
     					lch=ch;	
     				}
     			}
     			
     			for(OpportunityFieldHistory oh:o.Histories){
     				if((oh.Field=='created' || oh.Field=='Phone2__c') && (loh==null || loh.CreatedDate<oh.CreatedDate)){
     					loh=oh;
     				}
     			}
     			
     			outputPhone=outputPhone + o.Id + ',' + o.Name + ',' + c.Id + ',' + c.Name + ',' + o.Phone2__c + ',' + c.Phone;
     			
     			if(loh!=null){
     				outputPhone=outputPhone + ',' + loh.CreatedBy.Name + ',' + loh.CreatedDate.format();
     			}else{
     				outputPhone=outputPhone + ',' + '' + ',' + '';	
     			}
     			
     			if(lch!=null){
     				outputPhone=outputPhone + ',' + lch.CreatedBy.Name + ',' + lch.CreatedDate.format();	
     			}else{
     				outputPhone=outputPhone + ',' + '' + ',' + '';		
     			}
     			
     		}
     		
     		if(c!=null && (c.MobilePhone!=null && c.MobilePhone!='' && o.Mobile__c!=null && o.Mobile__c!='' && c.MobilePhone!=o.Mobile__c)){
     			outputMobile=outputMobile + '\n';	
     			ContactHistory lch=null;
     			OpportunityFieldHistory loh=null;
     			
     			for(ContactHistory ch:c.Histories){
     				if((ch.Field=='created' || ch.Field=='MobilePhone') && (lch==null || lch.Createddate<ch.CreatedDate)){
     					lch=ch;	
     				}
     			}
     			
     			for(OpportunityFieldHistory oh:o.Histories){
     				if((oh.Field=='created' || oh.Field=='Mobile__c') && (loh==null || loh.CreatedDate<oh.CreatedDate)){
     					loh=oh;
     				}
     			}
     			
     			outputMobile=outputMobile + o.Id + ',' + o.Name + ',' + c.Id + ',' + c.Name + ',' + o.Mobile__c + ',' + c.MobilePhone;
     			if(loh!=null){
     				outputMobile=outputMobile + ',' + loh.CreatedBy.Name + ',' + loh.CreatedDate.format();
     			}else{
     				outputMobile=outputMobile + ',' + '' + ',' + '';	
     			}
     			
     			if(lch!=null){
     				outputMobile=outputMobile + ',' + lch.CreatedBy.Name + ',' + lch.CreatedDate.format();	
     			}else{
     				outputMobile=outputMobile + ',' + '' + ',' + '';		
     			}
     			
     		}
     		
     		if(c!=null && (c.Email!=null && c.Email!='' && o.Email__c!=null && o.Email__c!='' && c.Email!=o.Email__c)){
     			outputEmail=outputEmail + '\n';	
     			ContactHistory lch=null;     			
     			OpportunityFieldHistory loh=null;
     			system.debug(c.Id);
     			system.debug(c.Histories.size());
     			for(ContactHistory ch:c.Histories){
     				if((ch.Field=='created' || ch.Field=='Email') && (lch==null || lch.Createddate<ch.CreatedDate)){
     					lch=ch;	
     				}
     			}
     			system.debug(lch);
     			outputEmail=outputEmail + o.Id + ',' + o.Name + ',' + c.Id + ',' + c.Name + ',' + o.Email__c + ',' + c.Email;
     			if(loh!=null){
     				outputEmail=outputEmail + ',' + loh.CreatedBy.Name + ',' + loh.CreatedDate.format();
     			}else{
     				outputEmail=outputEmail + ',' + '' + ',' + '';	
     			}
     			
     			if(lch!=null){
     				outputEmail=outputEmail + ',' + lch.CreatedBy.Name + ',' + lch.CreatedDate.format();	
     			}else{
     				outputEmail=outputEmail + ',' + '' + ',' + '';		
     			}
     			
     		}     		     		    		
     	}	
    }

   global void finish(Database.BatchableContext BC){
   		Messaging.Emailfileattachment et1=new Messaging.Emailfileattachment();
   		et1.setBody(Blob.valueOf(outputPhone));
   		et1.setContentType('Text/CSV');
   		et1.setFileName('OppContactPhone.csv');
   		
   		Messaging.Emailfileattachment et2=new Messaging.Emailfileattachment();
   		et2.setBody(Blob.valueOf(outputMobile));
   		et2.setContentType('Text/CSV');
   		et2.setFileName('OppContactMobile.csv');
   		
   		Messaging.Emailfileattachment et3=new Messaging.Emailfileattachment();
   		et3.setBody(Blob.valueOf(outputEmail));
   		et3.setContentType('Text/CSV');
   		et3.setFileName('OppContactEmail.csv');
   		
   		
   		Messaging.Singleemailmessage mail=new Messaging.Singleemailmessage();
   		mail.setToAddresses(new String[]{'weiyu.ma@gmail.com','pony.ma@ef.com'});
   		mail.setSubject('Opp Sync Contact Report');
   		mail.setHtmlBody('see attached output');   		
   		mail.setFileAttachments(new Messaging.Emailfileattachment[]{et1,et2,et3});
   		
   		Messaging.sendEMail(new Messaging.Singleemailmessage[]{mail});   		 
   }

}