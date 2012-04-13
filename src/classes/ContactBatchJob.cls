global class ContactBatchJob implements Database.Batchable<SObject>,Database.Stateful {
	global String output='';
	global Database.QueryLocator start(Database.BatchableContext BC){
      output='Id,FirstName,LastName,Email,EtownMemberId__c,Comment';
      String query='select Id,FirstName,LastName,Email,EtownMemberId__c,(select oldvalue,newvalue,createdBy.Name,createddate from Histories where field=\'EtownmemberId__c\') from Contact where EtownMemberId__c!=null';
      return Database.getQueryLocator(query);
   }

   global void execute(Database.BatchableContext BC, List<SObject> scope){
     	for(SObject obj:scope){
     		Contact c=(Contact)obj;
     		for(ContactHistory ch:c.Histories){
     			if(ch.OldValue!=null && ch.NewValue!=null && ch.OldValue!=ch.NewValue){
     				output=output + '\n';
     				String comment='From ' + ch.OldValue + ' to ' + ch.NewValue + ' by ' + ch.CreatedBy.Name + ' on ' + ch.CreatedDate.format();
     				output=output + c.Id + ',' + c.FirstName + ',' + c.LastName + ',' + c.Email + ',' + c.EtownMemberId__c + ',' + comment;		
     			}
     		}
     	}	
    }

   global void finish(Database.BatchableContext BC){
   		Messaging.Emailfileattachment et=new Messaging.Emailfileattachment();
   		et.setBody(Blob.valueOf(output));
   		et.setContentType('Text/CSV');
   		et.setFileName('ContactBatchJobResult.csv');
   		
   		Messaging.Singleemailmessage mail=new Messaging.Singleemailmessage();
   		mail.setToAddresses(new String[]{'weiyu.ma@gmail.com','pony.ma@ef.com'});
   		mail.setSubject('MemberId Changed Report');
   		mail.setHtmlBody(output);   		
   		mail.setFileAttachments(new Messaging.Emailfileattachment[]{et});
   		
   		Messaging.sendEMail(new Messaging.Singleemailmessage[]{mail});   		 
   }
	
}