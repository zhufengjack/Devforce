/**
* It's used to sync the email/phone/mobilephone in opportunity and actual from contact
* Pony Ma Created 2011-12-12
*/
trigger SyncContactInfo on Contact (after update) {	
	Map<Id,Contact> mapContact=new Map<Id,Contact>();
	List<Opportunity> lstOpp=new List<Opportunity>();
	List<Actual__c> lstActual=new List<Actual__c>();
	
	//if email,phone or mobile phone is changed in contact
	for(Contact c:trigger.new){
		if(c.Email!=trigger.oldMap.get(c.Id).Email ||
		   c.Phone!=trigger.oldMap.get(c.Id).Phone ||
		   c.MobilePhone!=trigger.oldMap.get(c.Id).MobilePhone){
		   		mapContact.put(c.Id,c);
		   }
	}
	
	if(mapContact.keyset().size()>0){
		lstOpp=[select Email__c,Phone2__c,Mobile__c,Contact__c from Opportunity where Contact__c in :mapContact.keyset()];	
		lstActual=[select Email__c,Phone__c,Mobile__c,Opportunity__r.Contact__c from Actual__c where Opportunity__r.Contact__c in :mapContact.keyset()];
		
		for(Opportunity opp:lstOpp){
			opp.Email__c=trigger.newMap.get(opp.Contact__c).Email;
			opp.Phone2__c=trigger.newMap.get(opp.Contact__c).Phone;
			opp.Mobile__c=trigger.newMap.get(opp.Contact__c).MobilePhone;
		}		
		
		for(Actual__c act:lstActual){
			act.Email__c=trigger.newMap.get(act.Opportunity__r.Contact__c).Email;
			act.Phone__c=trigger.newMap.get(act.Opportunity__r.Contact__c).Phone;
			act.Mobile__c=trigger.newMap.get(act.Opportunity__r.Contact__c).MobilePhone;
		}
		if(lstOpp.size()>0) update lstOpp;
		if(lstActual.size()>0) update lstActual;
	}	
		
}