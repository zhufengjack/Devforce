/**
*	Pony Ma 2012-02-08	use getContactByEmailWithoutMemberId to match contact when member id is passed and can not be matched by member id
*/
global class EtownCaseInfoService 
{   
    private static String EtownCaseRecordTypeId = [select Id from RecordType where Name = 'ETown Student Case' and SobjectType = 'Case'].Id;    																				  
    public webservice static CreateCaseResult CreateCaseFromContactus(CreateCaseParam param)
    {
        System.debug(param);
        System.debug(param.Context);
        EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo;
        							
        String contactId;
        String contactId2;
        Boolean rslt;
        List<Contact> Econtacts;
        
        CreateCaseResult result = new CreateCaseResult();
              
        try
        {             
            String memberId = param.CaseInfo.Member_id;
            System.debug(memberId);
            String Email = param.CaseInfo.Email;
                       
            System.debug((memberId.length() == 1) && (Email != null));
                       
            if (memberId != '-1')
            {
                //Create case by memberid
                Contact Econtact = ContactSvc.getContactByMemberId(double.valueof(memberId));
                
                if(Econtact.id != null)//find
                {
                    contactId = Econtact.id;
                                        
                    if(Econtact.IsInitiallySynced__c == true)
                    {
                        //Create a new case
                        result = createNewCase(param, contactId);
                    }
                    else
                    {
                        //ETown Service: get full member info
                        fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(Integer.valueof(memberId));
                        
                        //Update contact
                        rslt = ContactSvc.updateContactByMemberInfo(fullMemberInfo,contactId); 
                        
                        //Create a new case    
                        result = createNewCase(param, contactId);
                      
                    }
                }
                else
                {
                    //ETown Service
                    fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(Integer.valueof(memberId));
                    //Map
                    String contactIdbySearched = ContactSvc.mapContactWithFullMemberInfo(fullMemberInfo);

                    if(contactIdbySearched == null)
                    {   
                    	//Map Failed.
                        Econtacts = ContactSvc.getContactByEmailWithoutMemberId(Email);
                		System.debug(Econtacts);
                		if (Econtacts.size()==1)
                		{
                    		contactId = Econtacts[0].id;
                    		rslt = ContactSvc.updateContactByMemberInfo(fullMemberInfo, contactId);
                    	}
                    	else
                    	{
                    		contactId = ContactSvc.createContactByMemberInfo(fullMemberInfo);
                    	}
                        
                    }
                    else
                    {   
                        ContactSvc.updateContactByMemberInfo(fullMemberInfo, contactIdbySearched);
                        rslt = ContactSvc.updateContactByMemberInfo(fullMemberInfo, contactIdbySearched);
                        contactId = contactIdbySearched;
                        
                    }
                    //Create a new case 
                    result = createNewCase(param, contactId);
                }
            }
            
            if ((memberId == '-1') && (Email != null))
            {
                //Create case by email address
                Econtacts = ContactSvc.getContactByEmail(Email);
                System.debug(Econtacts);
                if (Econtacts.size()==1)
                {
                    contactId = Econtacts[0].id;
                    //Create a new case
                    updateContactByContext(contactId, param.Context);
                    result = createNewCase(param, contactId);
                }
                else
                {
                    contactId = ContactSvc.createContactByEmail(Email);
                    //Create a new case 
                    updateContactByContext(contactId, param.Context);
                    result = createNewCase(param, contactId);
                }
            }
        }
        catch(Exception ex)
        {
        	throw ex;
            //result.Succeeded = false;
            //result.ErrorMessage = ex.getMessage();
        }
        return result;
    }
        
    //Update contact by Context
    private static Id updateContactByContext(String conId, Context conx)
    {
    	Id rId;
		
    	Contact TempCon = [Select CountryCode__c, PartnerCode__c, PreferredLanguage__c, IsSocial__c from Contact where Id =:conId limit 1];
    	
    	if(TempCon.CountryCode__c == null)
    	{TempCon.CountryCode__c = conx.Locale;}
    	if(TempCon.PartnerCode__c == null) 
    	{TempCon.PartnerCode__c = conx.Partner;}
    	if(TempCon.PreferredLanguage__c == null) 
    	{TempCon.PreferredLanguage__c = conx.Language;}
    	
    	if(conx.IsSocial == 'true')
    	{TempCon.IsSocial__c = true;}
    	else
    	{TempCon.IsSocial__c = false;}
    		         	   	
    	Database.SaveResult lsr = Database.update(TempCon,false);
    	
		if(lsr.isSuccess()) {rId = lsr.getId();}
		else {rId = null;}
		
		return rId;
    }
    //Update contact by Context End
    
    
    //create a case
    private static CreateCaseResult createNewCase(CreateCaseParam param, String contactId)
    {
        Case newCase;
        CreateCaseResult result = new CreateCaseResult();
        if(param != null)
        {   
            newCase = new Case
            (
                ContactId = contactId,
                Origin ='Contact Us', 
                category__c = param.CaseInfo.Category,
                subcategory__c = param.CaseInfo.SubCategory,
                Subject = param.CaseInfo.Category + '-' + param.CaseInfo.SubCategory, 
                Description = param.CaseInfo.Description,
                RecordTypeId = EtownCaseRecordTypeId,
                LanguageCode__c = param.Context.Language 
             );
            
            CaseExtensionXmlHelper xmlhelper = new CaseExtensionXmlHelper();
            newCase.TechCheck__c = xmlhelper.TechCheckToXml(param.TechCheck);
            newCase.QwithA__c = xmlhelper.QwithAToXml(param.CaseInfo.QandA);
            
            //Context Info
            newCase.Context__c = param.Context.Locale + ' ' + param.Context.Language + ' ' + param.Context.Partner + ' ' + param.Context.IsSocial;
     
            
            Database.SaveResult lsr = Database.insert(newCase,false);
            Id rId;
            if(lsr.isSuccess()) 
            {
            	rId = lsr.getId();
            	result.Succeeded = true;
        		result.ContactId = contactId;
        		result.CaseId = rId;
        		String QueueId = AutoAssignmentLogic.assignCase(rId);
        		Case CaseTmp = [Select ownerId from case where Id=:rId limit 1];
        		CaseTmp.OwnerId = QueueId;
        		Database.update(CaseTmp,false);
            }
            else 
            {
            	result.Succeeded = false;
            	//error message to elaborate
            }
            	
            
            if (param.CaseAttachs != null)
            {
	            //Attachments
	            integer k = param.CaseAttachs.size();
	            integer l;
	            Blob attach;
	            for(l=0; l<k ; l++) 
	            {
	                attach = EncodingUtil.base64Decode(param.CaseAttachs[l].Base64FileString);
	                Attachment newAttach = new Attachment
	                (
	                    Body = attach,
	                    ParentId = rId,
	                    Name = param.CaseAttachs[l].FileName
	                );
	                insert newAttach;
	            }
	            //Attachments End
            }
        }
        else
        {
            throw new CreateCaseException('Case Info is null.');
        }
        return result;
    }
        
    global class CreateCaseParam
    {
       public webservice CaseInfo CaseInfo;
       public webservice Context Context;
       public webservice list<CaseAttach> CaseAttachs;
       public webservice TechCheck TechCheck;
    }
    
    
    global class TechCheck
    {
        public webservice String Refurl {get;set;}
        public webservice String Server {get;set;}
        public webservice String Os {get;set;}
        public webservice String Browser {get;set;}
        public webservice String ConnectionSpeed {get;set;}
        public webservice String Flash {get;set;}
        public webservice String JVM {get;set;}
        public webservice String Aol {get;set;}
        public webservice String ASR {get;set;}
        public webservice String PageUrl {get;set;}
        public webservice String NumberTimes {get;set;}
        public webservice String TechnicalErrorTextUrl {get;set;}
        public webservice String TechCheck {get;set;}
    }
        
    
    global class QuestionWithAnswer
    {
        public webservice String SurfingFromHome {get;set;}
        public webservice String ErrorMessage {get;set;}
        public webservice String AccessEVC {get;set;}
        public webservice String LevelUnit {get;set;}
        public webservice String LevelUnitPage {get;set;}
        public webservice String Teacher {get;set;}
    } 
    
    global class Context
    {
        public webservice String Locale;
        public webservice String Language;
        public webservice String Partner;
        public webservice String IsSocial;
    }

    global class CaseAttach
    {
        public webservice String Base64FileString;
        public webservice String FileName;
        public webservice String ContentType;
    }
        
    global class CaseInfo
    {
       public webservice String Member_id;
       public webservice String Email ;
       public webservice String Category;
       public webservice String SubCategory;
       public webservice String Description;
       public webservice QuestionWithAnswer QandA;
    }
    
    global class CreateCaseResult
    {
       public webservice Boolean Succeeded;    
       public webservice Integer ErrorCode;    //applicable when Succeeded=false
       public webservice String ErrorMessage;  //applicable when Succeeded=false
       public webservice String ContactId;     //applicable when Succeeded=true
       public webservice String CaseId;        //applicable when Succeeded=true
    }
    
    global class CreateCaseException extends Exception {}
    ///////////////////////////////////////
   
    @isTest
    
    static void testEtownCaseInfoService()
    {
		/*
        CreateCaseParam TestParam = new CreateCaseParam();
        CaseInfo TestCaseInfo = new CaseInfo();
        TechCheck TestTechCheck = new TechCheck();
        //List<CaseAttach> TestCaseAttachs = new List <CaseAttach>;
        QuestionWithAnswer TestQa = new QuestionWithAnswer();
        Context TestContext = new Context();
        
        TestParam.CaseInfo = TestCaseInfo;
        //TestParam.CaseAttachs = TestCaseAttach;
        TestParam.Context = TestContext;
        TestParam.TechCheck = TestTechCheck;
        TestCaseInfo.QandA = TestQa;
        
        TestCaseInfo.Member_id = '10370701';
        TestCaseInfo.Email = 'biscuit1999@hotmail.com';
        TestCaseInfo.Category = 'Conversation';
        TestCaseInfo.SubCategory = 'cant enter';
        TestCaseInfo.Description = 'Can not see content';
        
        TestContext.Locale = 'cc';
        TestContext.IsSocial = 'null';
        TestContext.Language= 'cs';
        TestContext.Partner = 'None';
        
        
        TestTechCheck.ASR = 'true';
       	TestTechCheck.Aol = 'False';
       	TestTechCheck.Browser = 'Chrome8.0.552.237';
       	TestTechCheck.ConnectionSpeed = '442459';
       	TestTechCheck.Flash = 'Passed(10.1 r103)';
       	TestTechCheck.JVM = 'True';
       	TestTechCheck.NumberTimes = 'NA';
       	TestTechCheck.Os = 'Windows 7';
       	TestTechCheck.PageUrl = 'USB-ETOWNSPQA/customerservice/contactus/contactus.aspx';
       	TestTechCheck.Refurl = '';
       	TestTechCheck.Server = 'USB-ETOWNSPQA';
       	TestTechCheck.TechCheck = 'NA';
       	TestTechCheck.TechnicalErrorTextUrl = '';
       	
       	TestQa.AccessEVC = 'Yes';
       	TestQa.ErrorMessage = '';
       	TestQa.LevelUnit = '';
       	TestQa.LevelUnitPage = '';
       	TestQa.SurfingFromHome = 'No';
       	TestQa.Teacher = '';	
       	            	
       	EtownCaseInfoService.CreateCaseFromContactus(TestParam);
       	
       	
       	TestCaseInfo.Member_id = '-1';
        TestCaseInfo.Email = 'biscuit2000@hotmail.com';
        TestCaseInfo.Category = 'Conversation';
        TestCaseInfo.SubCategory = 'cant enter';
        TestCaseInfo.Description = 'Can not see content';
        
        TestContext.Locale = 'cc';
        TestContext.IsSocial = 'null';
        TestContext.Language= 'cs';
        TestContext.Partner = 'None';
        
        
        TestTechCheck.ASR = 'true';
       	TestTechCheck.Aol = 'False';
       	TestTechCheck.Browser = 'Chrome8.0.552.237';
       	TestTechCheck.ConnectionSpeed = '442459';
       	TestTechCheck.Flash = 'Passed(10.1 r103)';
       	TestTechCheck.JVM = 'True';
       	TestTechCheck.NumberTimes = 'NA';
       	TestTechCheck.Os = 'Windows 7';
       	TestTechCheck.PageUrl = 'USB-ETOWNSPQA/customerservice/contactus/contactus.aspx';
       	TestTechCheck.Refurl = '';
       	TestTechCheck.Server = 'USB-ETOWNSPQA';
       	TestTechCheck.TechCheck = 'NA';
       	TestTechCheck.TechnicalErrorTextUrl = '';
       	
       	TestQa.AccessEVC = 'Yes';
       	TestQa.ErrorMessage = '';
       	TestQa.LevelUnit = '';
       	TestQa.LevelUnitPage = '';
       	TestQa.SurfingFromHome = 'No';
       	TestQa.Teacher = '';
       	
       	EtownCaseInfoService.CreateCaseFromContactus(TestParam);
       	*/
    }
    
}