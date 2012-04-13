/**
*	Pony Ma 2011-11-16	Change to throw exception whenever there is an issue, e.g invalid data or DML fails and roll back the whole transaction
*	Pony Ma 2011-12-14	Added a short solution to monitor the failed lead and changed not to roll back the transaction. 
*	we can remove the monitor once Etown implemnts the logic to process the failed ones.
*	Pony Ma 2011-12-26 assign the staging lead to country queue
* 	Pony Ma 2012-03-01 Removed email validation logic, lead with invalid email will be sent back to Etown
*/
global class EtownStagingLeadService 
{    
    webservice static list<CreateLeadResult> CreateLeadBySlead(list<SleadInfo> SleadsInfo)
    {
        try{
	        Database.SaveResult[] lsr;
	        list<CreateLeadResult> CreateLeadsResult = new list<CreateLeadResult>();
	        
	        Savepoint sp;
	        Integer i;
	        
	        //initial country lead queue ids
	        Map<String,String> mapCountryLeadQueueId=new Map<String,String>();
	        Map<String,String> mapLeadQueueNameCountry=new Map<String,String>();
	        Set<String> setQueueName=new Set<String>();
	        for(String country:StagingLeadConfig__c.getAll().keyset()){
	        	setQueueName.add(StagingLeadConfig__c.getAll().get(country).LeadQueue__c);	        	
	        	mapleadQueueNameCountry.put(StagingLeadConfig__c.getAll().get(country).LeadQueue__c,country);        	
	        }
	        List<QueueSobject> lstQueue=[Select QueueId,Queue.Name from QueueSobject where Queue.Name in :setQueueName and SobjectType='StagingLead__c'];
	        for(QueueSobject qs:lstQueue){
	        	mapCountryLeadQueueId.put(mapLeadQueueNameCountry.get(qs.Queue.Name),qs.QueueId);
	        }
	        
	        	        
	        list <StagingLead__c> SLeads2Insert = new list <StagingLead__c> ();        
	        if (SleadsInfo.size()>0)        
	        {
	            for(i=0; i<SleadsInfo.size(); i++)
	            {
	                StagingLead__c SleadTemp = new StagingLead__c();
	                                
	                SleadTemp.Age__c = SleadsInfo[i].Age;
	                SleadTemp.Company__c = SleadsInfo[i].Company ;
	                SleadTemp.Country__c = SleadsInfo[i].Country ;
	                SleadTemp.City__c = SleadsInfo[i].City ;
	                
	                //if the email is invalid, clear it. As we can not save it into an Email field               
	                //if(SleadsInfo[i].Email!=null && ContactSvc.checkEmailAddress(SleadsInfo[i].Email)){
	                	SleadTemp.Email__c = SleadsInfo[i].Email ;
	                //}
	                                
	                SleadTemp.English_Level__c = SleadsInfo[i].English_Level ;
	                SleadTemp.Etag_Ad_Number__c = SleadsInfo[i].Etag_Ad_Number ;
	                SleadTemp.FirstName__c = SleadsInfo[i].FirstName ;
	                	                
	                try{
	                	if(SleadsInfo[i].Grammar_score!=null && SleadsInfo[i].Grammar_score!=''){
	                		SleadTemp.Grammar_score__c = Decimal.valueof(SleadsInfo[i].Grammar_score) ;
	                	}
	                }catch(Exception e){
	                	//throw new CreateLeadException('Invalid value for Grammar Score, it must be a number(leadid=' + SleadsInfo[i].LeadId + ').');	
	                }
	                
	                SleadTemp.Industry__c = SleadsInfo[i].Industry ;
	                SleadTemp.LastName__c = SleadsInfo[i].LastName;
	                
	                try{
	                	if(SleadsInfo[i].Initial_Visit_YYYY!=null && SleadsInfo[i].Initial_Visit_YYYY!='' && SleadsInfo[i].Initial_Visit_MM!=null && SleadsInfo[i].Initial_Visit_MM!='' && SleadsInfo[i].Initial_Visit_DD!=null && SleadsInfo[i].Initial_Visit_DD!=''){
		                	Date myDate = date.newinstance(Integer.valueof(SleadsInfo[i].Initial_Visit_YYYY), 
		                                               	   Integer.valueof(SleadsInfo[i].Initial_Visit_MM), 
		                                                   Integer.valueof(SleadsInfo[i].Initial_Visit_DD));
		                 	SleadTemp.Initial_Visit_Date__c = mydate;                                
	                	}
	                }catch(Exception e){
	                	//throw new CreateLeadException('Invalid initial visit date(leadid=' + SleadsInfo[i].LeadId + ').');		
	                }                              
	                
	                
	                SleadTemp.LeadForm_ID__c = SleadsInfo[i].LeadForm_ID ;
	                SleadTemp.Lead_ID__c = Decimal.valueof(SleadsInfo[i].LeadId);
	                SleadTemp.LeadSource__c = SleadsInfo[i].LeadSource ;
	                
	                try{
	                	if(SleadsInfo[i].Listening_score!=null && SleadsInfo[i].Listening_score!=''){
	                		SleadTemp.Listening_score__c = Decimal.valueof(SleadsInfo[i].Listening_score) ;	
	                	}	
	                }catch(Exception e){
	                	//throw new CreateLeadException('Invalid value for Listening Score, it must be a number(leadid=' + SleadsInfo[i].LeadId + ').');		
	                }
	                
	                
	                SleadTemp.Living_District__c = SleadsInfo[i].Living_District ;
	                SleadTemp.MobilePhone__c = SleadsInfo[i].MobilePhone ;
	                SleadTemp.Office_Phone__c = SleadsInfo[i].Office_Phone ;
	                SleadTemp.Partner_Ad_Channel__c = SleadsInfo[i].Partner_Ad_Channel;
	                SleadTemp.Phone__c = SleadsInfo[i].Phone ;
	                SleadTemp.Preferred_Time_to_Call__c = SleadsInfo[i].Preferred_Time_to_Call ;
	                
	                try{
	                	if(SleadsInfo[i].Reading_score!=null && SleadsInfo[i].Reading_score!=''){
	                		SleadTemp.Reading_score__c = Decimal.valueof(SleadsInfo[i].Reading_score) ;	
	                	}	
	                }catch(Exception e){
	                	//throw new CreateLeadException('Invalid value for reading score, it must be a number(leadid=' + SleadsInfo[i].LeadId + ').');		
	                }
	                
	                
	                SleadTemp.State__c = SleadsInfo[i].State ;
	                SleadTemp.Skill_Level__c = SleadsInfo[i].Skill_Level ;
	                
	                try{
	                	if(SleadsInfo[i].Skill_Score!=null && SleadsInfo[i].Skill_Score!=''){
	                		SleadTemp.Skill_Score__c = Decimal.valueof(SleadsInfo[i].Skill_Score) ;	
	                	}
	                }catch(Exception e){
	                	//throw new CreateLeadException('Invalid value for skill score, it must be a number(leadid=' + SleadsInfo[i].LeadId + ').');		
	                }
	                
	                
	                SleadTemp.State__c = SleadsInfo[i].State ;
	                SleadTemp.User_Name__c = SleadsInfo[i].User_Name;
	                SleadTemp.WantCall__c = SleadsInfo[i].WantCall;
	                
	                //set owner to country queue
	                if(SleadTemp.Country__c!=null && mapCountryLeadQueueId.get(SleadTemp.Country__c)!=null){
	                	SleadTemp.OwnerId=mapCountryLeadQueueId.get(SleadTemp.Country__c);
	                }
	                
	                SLeads2Insert.add(SleadTemp);
	            }
	        }
	        
	        try
	        {
	            sp = Database.setSavepoint(); 
	            lsr = Database.insert(SLeads2Insert,false);
	                        
	            for(i=0;i<lsr.size();i++)
	            {
	                CreateLeadResult TempResult = new CreateLeadResult();
	                
	                TempResult.Succeeded = lsr[i].isSuccess();
	                TempResult.SleadId = String.valueOf(SLeads2Insert[i].Lead_ID__c);
	                if(TempResult.Succeeded == false)
	                {
	                    Database.Error err = lsr[i].getErrors()[0]; 
	                    TempResult.ErrorCode = err.getMessage();
	                }
	                CreateLeadsResult.add(TempResult);
	            }
	            
	        }
	        catch(DMLException ex)
	        {
	            Database.rollback(sp);
	            reportError(ex.getMessage());            
	            throw new CreateLeadException(ex.getMessage());            
	        }
	        
	        String errorMsg='';
			for(CreateLeadResult cr:CreateLeadsResult){
				if(!cr.Succeeded){
					errorMsg=errorMsg + cr.ErrorCode + ' ';		
				}
			}
			
			//it's a temporarily solution to monitor the error by ourselves. We'll remove it after Etown adds logic to process the failed leads.
			if(errorMsg!='') reportError(errorMsg);
	        
	        return CreateLeadsResult;
        }catch(Exception ex){
        	reportError(ex.getMessage()); 
        	throw new CreateLeadException(ex.getMessage());		
        }
    }
    
    
    global class SleadInfo
    {
        webservice String Age;      
        webservice String Company;
        webservice String Country;
        webservice String City;
        webservice String Email;
        webservice String English_Level;
        webservice String Etag_Ad_Number;
        webservice String FirstName;
        webservice String Grammar_score;
        webservice String Industry;
        
        //webservice Datetime Initial_Visit_Date;
        webservice String Initial_Visit_YYYY;
        webservice String Initial_Visit_MM;
        webservice String Initial_Visit_DD;
        
        webservice String LastName;
        webservice String LeadId;
        webservice String LeadForm_ID;
        webservice String LeadSource;
        webservice String Listening_score;
        webservice String Living_District;
        webservice String MobilePhone;
        webservice String Office_Phone;
        webservice String Partner_Ad_Channel;
        webservice String Phone;
        webservice String Preferred_Time_to_Call;
        webservice String Reading_score;
        webservice String State;
        webservice String Skill_Level;
        webservice String Skill_Score;
        webservice String User_Name;
        webservice String WantCall;
    }
    
    global class CreateLeadResult
    {
       webservice Boolean Succeeded;    
       webservice String ErrorCode;     
       webservice String SleadId;           
    }
    
      
    private static void reportError(String errorMsg){
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		
		String[] toAddresses = new String[] {'pony.ma@ef.com'};		
		mail.setToAddresses(toAddresses);		
		mail.setSenderDisplayName('Staging Lead Error Monitor');
		mail.setSubject('Error Happened in SF Staging Lead Service');
		
		// Set to True if you want to BCC yourself on the email.
		mail.setBccSender(false);
		mail.setUseSignature(false);
				
		mail.setPlainTextBody(errorMsg);		
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });	
    }
    
    global class CreateLeadException extends Exception {}
       
    @isTest
    static void testEtownStagingLeadService()
    {
    	list <SleadInfo> SLeadstoInsertTest = new list <SleadInfo> ();
    	
    	SleadInfo SleadTemp1 = new SleadInfo();
    	SleadTemp1.Company = 'Apple';
    	SleadTemp1.Country = 'mx';
    	SLeadstoInsertTest.add(SleadTemp1);
    	
    	SleadInfo SleadTemp2 = new SleadInfo();
    	SleadTemp2.Company = 'Apple2';
    	SleadTemp2.Country = 'mx';
    	SLeadstoInsertTest.add(SleadTemp2);
    	try{
    		EtownStagingLeadService.CreateLeadBySlead(SLeadstoInsertTest);
    	}catch(Exception ex){
    		//	
    	}
    }
      
}