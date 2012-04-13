/*
 * Middle layer of Lead object
 * Pony Ma	2011-12-05	rewrote the class
 */ 
global class LeadSvc  
{			
	class ConvertStagingLeadResult{
		String Status;
		String Message;
		List<Lead> LeadsCreated=new List<Lead>();
		List<Lead> LeadsUpdated=new List<Lead>();
		List<Lead> LeadsDuplicate=new List<Lead>();
		List<Lead> LeadsContactExisted=new List<Lead>();				
	}
		
	class StagingLeadConfigData{
		String CountryName;
		String ContactRT;
		String CountryMgt;
		String CountrySales;
		String LeadQueue;
		String LeadQueueId;
		String LeadRT;
		String LeadRTId;
		String OppoRT;			
	}
	
	webservice static String convertStagingLeads(List<Id> StagingLeadIds){
		
		String STATUS_IMPORT_OK='OK';
		String STATUS_IMPORT_ERROR='Error';
		String ERROR_MESSAGE_COUNTRY_REQUIRERD='Staging lead[Lead Id={0}] does not belong to any country.';
		String ERROR_MESSAGE_COMPANY_REQUIRERD='Staging lead[Lead Id={0}] does not have a company value.';
		String ERROR_MESSAGE_EMAIL_REQUIRERD='Staging lead[Lead Id={0}] does not have an email value.';
		String ERROR_MESSAGE_COUNTRY_NOT_SUPPORTED='Country({1})[Lead Id={0}] is not supported yet.';
		String ERROR_MESSAGE_NO_STAGING_LEAD_PASSED='No Staging Lead is passed.';
		String MESSAGE_PROCESS_SUCCESS='{0} staging lead(s) have been processed successfully.';
		String STATUS_LEAD_CREATED='Lead Created';
		String STATUS_LEAD_UPDATED='Lead Updated';
		String STATUS_LEAD_DUPLICATE='Lead Duplicate';
		String STATUS_CONTACT_EXISTED='Contact Existed';
		
		
		ConvertStagingLeadResult convertResult=new ConvertStagingLeadResult();
		convertResult.Status=STATUS_IMPORT_OK;
		
		List<StagingLead__c> lstStagingLead=new List<StagingLead__c>();
		List<Lead> lstLead=new List<Lead>();
		List<Contact> lstContact=new List<Contact>();
		List<Opportunity> lstOpportunity=new List<Opportunity>();
		
		Map<String,StagingLeadConfigData> mapStagingLeadConfigData=new Map<String,StagingLeadConfigData>();
		Map<String,String> mapLeadRecordTypeId=new Map<String,String>();
		Map<String,String> mapLeadQueueId=new Map<String,String>();
		Map<String,StagingLead__c> mapStagingLead=new Map<String,StagingLead__c>();
		Map<String,Lead> mapLead=new Map<String,Lead>();
		Map<String,Opportunity> mapOpportunity=new Map<String,Opportunity>();
		
		//which fields we need to compare in staging lead and lead to define a duplicate		
		Map<String,String> mapDuplicateKeyField=new Map<String,String>();
		mapDuplicateKeyField.put('Age__c','Age__c');
		mapDuplicateKeyField.put('Company__c','Company');
		mapDuplicateKeyField.put('Country__c','Country');
		mapDuplicateKeyField.put('English_Level__c','English_Level__c');
		mapDuplicateKeyField.put('Etag_Ad_Number__c','Etag_Ad_Number__c');
		mapDuplicateKeyField.put('FirstName__c','FirstName');
		mapDuplicateKeyField.put('Grammar_score__c','Grammar_score__c');
		mapDuplicateKeyField.put('Industry__c','Industry');
		mapDuplicateKeyField.put('Initial_Visit_Date__c','Initial_Visit_Date__c');
		mapDuplicateKeyField.put('LastName__c','LastName');
		mapDuplicateKeyField.put('Lead_ID__c','Lead_ID__c');
		mapDuplicateKeyField.put('LeadForm_ID__c','LeadForm_ID__c');
		mapDuplicateKeyField.put('LeadSource__c','LeadSource');
		mapDuplicateKeyField.put('Listening_score__c','Listening_score__c');
		mapDuplicateKeyField.put('Living_District__c','Living_District__c');
		mapDuplicateKeyField.put('MobilePhone__c','MobilePhone');
		mapDuplicateKeyField.put('Partner_Ad_Channel__c','Partner_Ad_Channel__c');
		mapDuplicateKeyField.put('Phone__c','Phone');
		mapDuplicateKeyField.put('Office_Phone__c','Office_Phone__c');
		mapDuplicateKeyField.put('Preferred_Time_to_Call__c','Preferred_Time_to_Call__c');
		mapDuplicateKeyField.put('Reading_score__c','Reading_score__c');
		mapDuplicateKeyField.put('Skill_Level__c','Skill_Level__c');
		mapDuplicateKeyField.put('Skill_Score__c','Skill_Score__c');
		mapDuplicateKeyField.put('State__c','State');
		mapDuplicateKeyField.put('User_Name__c','User_Name__c');
		mapDuplicateKeyField.put('WantCall__c','WantCall__c');
		
					
		if(StagingLeadIds==null || StagingLeadIds.size()==0){
			convertResult.Status=STATUS_IMPORT_ERROR;
			convertResult.Message=ERROR_MESSAGE_NO_STAGING_LEAD_PASSED;	
		}	
		
		if(convertResult.Status==STATUS_IMPORT_OK){			
			lstStagingLead=[Select ID, IsDeleted, Age__c, Company__c, Country__c,Email__c,
			English_Level__c,Etag_Ad_Number__c, 
			FirstName__c,Grammar_score__c,Industry__c,Initial_Visit_Date__c,
			LastName__c,LeadForm_ID__c, Lead_ID__c,LeadSource__c, 
			Listening_score__c,Living_District__c,MobilePhone__c,Partner_Ad_Channel__c, 
			Phone__c,Office_Phone__c,Preferred_Time_to_Call__c, Reading_score__c,State__c,Skill_Level__c,
			Skill_Score__c,User_Name__c,WantCall__c,Import_Status__c,IsImported__c from StagingLead__c where ID IN : 
			StagingLeadIds and IsImported__c=false];
			
							
			//field value validation and init staging lead config data
			for(StagingLead__c sl:lstStagingLead){
				//country is required
				if(sl.Country__c==null || sl.Country__c==''){
					convertResult.Status=STATUS_IMPORT_ERROR;
					convertResult.Message=String.format(ERROR_MESSAGE_COUNTRY_REQUIRERD,new String[]{String.valueOf(sl.Lead_ID__c)});		
					break;
				}			
				//company is required
				if(sl.Company__c==null || sl.Company__c==''){
					convertResult.Status=STATUS_IMPORT_ERROR;
					convertResult.Message=String.format(ERROR_MESSAGE_COMPANY_REQUIRERD,new String[]{String.valueOf(sl.Lead_ID__c)});		
					break;	
				}			
				//email is required
				if(sl.Email__c==null || sl.Email__c==''){
					convertResult.Status=STATUS_IMPORT_ERROR;
					convertResult.Message=String.format(ERROR_MESSAGE_EMAIL_REQUIRERD,new String[]{String.valueOf(sl.Lead_ID__c)});		
					break;
				}			
				//if the country is supported
				StagingLeadConfig__c SLConfig = StagingLeadConfig__c.getInstance(sl.Country__c);
				if(SLConfig==null){
					convertResult.Status=STATUS_IMPORT_ERROR;
					convertResult.Message=String.format(ERROR_MESSAGE_COUNTRY_NOT_SUPPORTED,new String[]{String.valueOf(sl.Lead_ID__c),sl.Country__c});		
					break;	
				}else{
					if(mapStagingLeadConfigData.get(sl.Country__c)==null){
						StagingLeadConfigData sld=new StagingLeadConfigData();
						sld.CountryName=SLConfig.CountryName__c;
						sld.ContactRT=SLConfig.ContactRt__c;
						sld.CountryMgt=SLConfig.CountryMgt__c;
						sld.CountrySales=SLConfig.CountrySales__c;
						sld.LeadQueue=SLConfig.LeadQueue__c;
						sld.LeadRT=SLConfig.LeadRt__c;
						sld.OppoRT=SLConfig.OppoRt__c;						
						
						mapStagingLeadConfigData.put(sl.Country__c,sld);	
					}
				}				
				mapStagingLead.put(sl.Email__c,sl);							
			}
		}
				
		if(convertResult.Status==STATUS_IMPORT_OK){
			//setup LeadRecordTypeId and LeadQueueId by country
			Set<String> setLeadRTName=new Set<String>();
			Set<String> setLeadQueueName=new Set<String>();
			for(String country:mapStagingLeadConfigData.keyset()){
				setLeadRTName.add(mapStagingLeadConfigData.get(country).LeadRT);
				setLeadQueueName.add(mapStagingLeadConfigData.get(country).LeadQueue);			
			}
			List<RecordType> lstRT=[select Id,Name from RecordType where Name IN :setLeadRTName and SObjectType='Lead'];
			List<QueueSobject> lstQueue=[select QueueId,Queue.Name from QueueSobject where Queue.Name IN :setLeadQueueName and SobjectType='Lead'];
			for(String country:mapStagingLeadConfigData.keyset()){						
				for(RecordType rt:lstRT){
					if(mapStagingLeadConfigData.get(country).LeadRT==rt.Name){
						mapStagingLeadConfigData.get(country).LeadRTId=rt.Id;
						break;
					}
				}
				for(QueueSobject qs:lstQueue){
					if(mapStagingLeadConfigData.get(country).LeadQueue==qs.Queue.Name){
						mapStagingLeadConfigData.get(country).LeadQueueId=qs.QueueId;
					}
				}		
			}
					
			//query leads by mail			
			lstLead = [Select l.Name,l.ID, l.Age__c, l.Company, l.Country, l.Email, l.English_Level__c, l.Etag_Ad_Number__c, 
			l.FirstName, l.Grammar_score__c, l.Industry, l.Initial_Visit_Date__c, l.LastName, l.Lead_ID__c, 
			l.LeadForm_ID__c, l.LeadSource, l.Listening_score__c, l.Living_District__c, l.MobilePhone, 
			l.Partner_Ad_Channel__c, l.Phone,l.Office_Phone__c, l.Preferred_Time_to_Call__c, l.Reading_score__c, l.Skill_Level__c, 
			l.Skill_Score__c, l.State, l.User_Name__c, l.WantCall__c,l.RecordType.Name,l.IsConverted from Lead l
			where l.Email IN :mapStagingLead.keyset()];		
			for(Lead l:lstLead){
				mapLead.put(l.Email,l);				
			}
			
			//query opportunitys by email
			lstOpportunity=[select Id,Contact__r.Email from Opportunity where Contact__r.Email IN :mapStagingLead.keyset()];
			for(Opportunity opp:lstOpportunity){
				mapOpportunity.put(opp.Contact__r.Email,opp);				
			}
			
			//process staging lead
			//if opp & converted lead exists, mark as contact existed
			//if lead exists and not converted, if any field in key fields map has been changed, update lead and mark as lead updated
			//if lead exists and not converted, if no field in key fields map has been changed, mark  lead duplicate
			//if lead does not exist, create new lead and mark as lead created
			for(String mail:mapStagingLead.keyset()){
				StagingLead__c sl=mapStagingLead.get(mail);
				Lead l=mapLead.get(mail);
				Opportunity opp=mapOpportunity.get(mail);
				if((l!=null && l.IsConverted) && opp!=null){										
					//status value contact existed(rather than convertedleadexisted) is more understanding to user
					sl.Import_Status__c=STATUS_CONTACT_EXISTED;
					convertResult.LeadsContactExisted.add(l);						
				}else if(l!=null && !l.IsConverted){
					if(checkDuplicate(sl,l,mapDuplicateKeyField)){
						sl.Import_Status__c=STATUS_LEAD_DUPLICATE;
						convertResult.LeadsDuplicate.add(l);
					}else{
						sl.Import_Status__c=STATUS_LEAD_UPDATED;
						updateLead(sl,l,mapDuplicateKeyField);
						l.updated__c = true;
						l.UpdateTime__c = system.now();
						convertResult.LeadsUpdated.add(l);	
					}										
				}else{
					sl.Import_Status__c=STATUS_LEAD_CREATED;
					l=new Lead();					
					l.Email=sl.Email__c;										
					l.RecordTypeId=mapStagingLeadConfigData.get(sl.Country__c).LeadRTId;
					l.OwnerId=mapStagingLeadConfigData.get(sl.Country__c).LeadQueueId;	
					updateLead(sl,l,mapDuplicateKeyField);									
					convertResult.LeadsCreated.add(l);
				}
				//mark staging lead as imported
				sl.IsImported__c=true;
			}
			
			//DML for leads updating and inserting
			SavePoint sp;
			try{
				sp=Database.setSavePoint();
				
				insert convertResult.LeadsCreated;
				update convertResult.LeadsUpdated;
				update lstStagingLead;
				
				convertResult.Status=STATUS_IMPORT_OK;
				convertResult.Message=String.format(MESSAGE_PROCESS_SUCCESS,new String[]{String.valueOf(mapStagingLead.size())});
							
			}catch(Exception ex){
				Database.rollback(sp);		
				convertResult.Status=STATUS_IMPORT_ERROR;
				convertResult.Message=ex.getMessage();	
			}
		}	
				
		return JSON.serialize(convertResult);				
	}
	
	private static Boolean checkDuplicate(StagingLead__c sl,Lead l,Map<String,String> mapKeyField){
		for(String stagingLeadField:mapKeyField.keyset()){
			String leadField=mapKeyField.get(stagingLeadField);
			if(sl.get(stagingLeadField)!=l.get(leadField)) return false;
		}
		return true;
	}
	
	private static void updateLead(StagingLead__c sl,Lead l,Map<String,String> mapKeyField){
		for(String stagingLeadField:mapKeyField.keyset()){
			String leadField=mapKeyField.get(stagingLeadField);
			if(sl.get(stagingLeadField)!=null && sl.get(stagingLeadField)!=l.get(leadField)){
				l.put(leadField,sl.get(stagingLeadField));
			}
		}	
	}
	
		
	@isTest
	static void testLeadSvc(){
		String convertResult;
		//no leads passed
		List <Id> SLeadIds = new List <Id>();
		convertResult=LeadSvc.convertStagingLeads(SLeadIds);
		
		StagingLead__c SleadTemp = new StagingLead__c();		
		SleadTemp.Company__c='abc company';
		SleadTemp.Country__c = 'mx';		
		SleadTemp.Email__c='abc@test.com';
		insert SleadTemp;		
		SLeadIds.add(SleadTemp.Id);
		
		//normal import
		LeadSvc.convertStagingLeads(SLeadIds);
		
		//company is null
		SleadTemp.Company__c=null;
		SleadTemp.Country__c = 'mx';		
		SleadTemp.Email__c='abc@test.com';
		update SleadTemp;
		LeadSvc.convertStagingLeads(SLeadIds);
		
		//country is null		
		SleadTemp.Company__c='abc company';
		SleadTemp.Country__c = null;		
		SleadTemp.Email__c='abc@test.com';
		update SleadTemp;
		LeadSvc.convertStagingLeads(SLeadIds);
		
		//email is null
		SleadTemp.Company__c='abc company';
		SleadTemp.Country__c ='mx';		
		SleadTemp.Email__c=null;
		update SleadTemp;
		LeadSvc.convertStagingLeads(SLeadIds);
		
		//country is not supported
		SleadTemp.Company__c='abc company';
		SleadTemp.Country__c = 'not_supported_country';		
		SleadTemp.Email__c='abc@test.com';
		update SleadTemp;
		LeadSvc.convertStagingLeads(SLeadIds);						
	}	
}