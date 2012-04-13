public with sharing class ContactEmbeddedController {
	private Boolean isEditMode=false;	
	public Contact OppContact{get;set;}
	
	public Boolean getIsEditMode(){
		return isEditMode;
	}
	
	public ContactEmbeddedController(){		
		String opportunityId=system.currentPageReference().getParameters().get('opportunityId');
		String actualId=system.currentPageReference().getParameters().get('actualId');
		String retentionId=system.currentPageReference().getParameters().get('retentionId');	
		String collectionProcessId=system.currentPageReference().getParameters().get('collectionProcesId');				
		
		if(opportunityId!=null && opportunityId!=''){
			initContact(opportunityId,'Opportunity');			
		}else if(actualId!=null && actualid!=''){
			initContact(actualId,'Actual');	
		}else if(retentionId!=null && retentionId!=''){
			initContact(retentionId,'student_after_sales');			
		}else if(collectionProcessId!=null && collectionProcessId!=''){
			initContact(collectionProcessId,'Collection_Process');		
		}			
	}
			
	public ContactEmbeddedController(ApexPages.StandardController std){	
		if(std!=null && std.getId()!=null){
			if(std.getRecord() instanceof Opportunity){
				initContact(std.getId(),'Opportunity');	
			}else if(std.getRecord() instanceof Actual__c){
				initContact(std.getId(),'Actual');	
			}else if(std.getRecord() instanceof student_after_sales__c){
				initContact(std.getId(),'student_after_sales');	
			}else if(std.getRecord() instanceof Collection_Process__c){
				initContact(std.getId(),'Collection_Process');	
			}	
		}			
	}
	
	public void editContact(){
		isEditMode=true;
	}	
	
	public PageReference cancel(){		
		String retUrl=system.currentPageReference().getParameters().get('retURL');
		if(retURL!=null && retURL!=''){
			PageReference pr=new PageReference(retUrl);
			pr.setRedirect(true);
			return pr;
		}
		return null;
	}
	
	public PageReference saveContact(){
		if(OppContact!=null){
			update OppContact;			
		}
		
		String retUrl=system.currentPageReference().getParameters().get('retURL');
		if(retURL!=null && retURL!=''){
			PageReference pr=new PageReference(retUrl);
			pr.setRedirect(true);
			return pr;	
		}
		return null;		
	}
	
	private void initContact(String sourceObjectId,String sourceObjectType){
		system.debug(sourceObjectId);
		system.debug(sourceObjectType);
		String contactId=null;
		if(sourceObjectId!=null && sourceObjectId!=''){
			if(sourceObjectType=='Opportunity'){
				List<Opportunity> lstOpportunity=[select Contact__c from Opportunity where Id=:sourceObjectId];
				if(lstOpportunity.size()>0){
					contactId=lstOpportunity[0].Contact__c;
				}	
			}else if(sourceObjectType=='Actual'){
				List<Actual__c> lstActual=[select Opportunity__r.Contact__c from Actual__c where Id=:sourceObjectId];
				if(lstActual.size()>0){
					contactId=lstActual[0].Opportunity__r.Contact__c;
				}		
			}else if(sourceObjectType=='student_after_sales'){
				List<student_after_sales__c> lstRetention=[select Actual__r.Opportunity__r.Contact__c from student_after_sales__c where Id=:sourceObjectId];
				if(lstRetention.size()>0){
					contactId=lstRetention[0].Actual__r.Opportunity__r.Contact__c;
				}		
			}else if(sourceObjectType=='Collection_Process'){
				List<Collection_Process__c> lstCollectionProcess=[select PaymentRecord__r.Actual__r.Opportunity__r.Contact__c from Collection_Process__c where Id=:sourceObjectId];
				if(lstCollectionprocess.size()>0){
					contactId=lstCollectionProcess[0].PaymentRecord__r.Actual__r.Opportunity__r.Contact__c;
				}		
			}
		}
		system.debug(contactId);
		if(contactId!=null){
			OppContact=[select Name,FirstName,LastName,OwnerId,Phone,Email,MobilePhone from Contact where Id=:contactId];	
		}				
	}
}