//Pony Ma 2012-01-21 Rewrote the class and added logic to setup region value
trigger ContactBusinessUnit on Contact (before insert, before update) 
{		
	List<Contact> lstContactBU=new List<Contact>();
	List<Contact> lstContactRegion=new List<Contact>();
	
	if(trigger.isInsert){
		for(Contact c:Trigger.new){
			if(c.PartnerCode__c!=null){
				lstContactBU.add(c);
			}
			if(c.CountryCode__c!=null){
				lstContactRegion.add(c);	
			}	
		}	
	}
	
	if(trigger.isUpdate){
		for(Contact c:Trigger.new){
			if(c.PartnerCode__c!=trigger.oldMap.get(c.Id).PartnerCode__c){
				lstContactBU.add(c);
			}
			if(c.CountryCode__c!=trigger.oldMap.get(c.Id).CountryCode__c){
				lstContactRegion.add(c);		
			}
		}	
	}
	
	if(lstContactBU.size()>0){
		Map<String,String> mapPartnerBu = new Map<String,String>();
		list<EtownPartner__c> lstEtownPartner =[Select BusinessUnit__c, Code__c from EtownPartner__c];
		for(EtownPartner__c partner:lstEtownPartner){
			if(partner.Code__c!=null){
				 mapPartnerBu.put(partner.Code__c.toLowerCase(),partner.BusinessUnit__c);
			}
		}
		
		for(Contact c:lstContactBU){
	    	if(c.PartnerCode__c!=null) {
	    		c.BU__c=mapPartnerBu.get(c.PartnerCode__c.toLowerCase());
	    	}else{
	    		c.BU__c=null;
	    	}	    	
	    }					    		   
	} 
	
	if(lstContactRegion.size()>0){
		Map<String,String> mapCountry=new Map<String,String>();					
		List<EtownCountry__c> lstEtownCountry =[select Id,Code__c from EtownCountry__c];						
		for(EtownCountry__c country:lstEtownCountry){
			if(country.Code__c!=null){
				mapCountry.put(country.Code__c.toLowerCase(),country.Id);
			}
		}
		
		for(Contact c:lstContactRegion){	    	
	    	if(c.CountryCode__c!=null) {
	    		c.EtownCountry__c=mapCountry.get(c.CountryCode__c.toLowerCase());
	    	}else{
	    		c.EtownCountry__c=null;
	    	}	
	    }	
	}
	 
}