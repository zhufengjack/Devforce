/**
*	Pony Ma  2012-02-03 Added logic to prevent mobile/phone being updated by webservice if the values have been updated by other user accounts
*   Pony Ma  2012-02-06 Removed the contact query out of the loop
*/
global class ContactService 
{
    private static Pattern emailPattern = Pattern.compile('^[\\w-]+(\\.[\\w-]+)*@[\\w-]+(\\.[\\w-]+)+$');
    
    webservice static List<UpdateContactResult> UpdateContacts(List<UpdateContactParam> paramList)
    {
        if (paramList == null || paramList.size() == 0)
        {
            return null;
        }
        List<UpdateContactResult> resultList = new List<UpdateContactResult>();
        List<UpdateContactResult> tempResultList = new List<UpdateContactResult>();
        List<Contact> contacts = new List<Contact>();
        Map<String,Contact> mapContact=new Map<String,Contact>();
        UpdateContactResult result = null;
               
        Set<Integer> setMemberId=new Set<Integer>();
        for (UpdateContactParam param : paramList){
        	if(param.BasicMemberInfo!=null && param.BasicMemberInfo.Member_id!=null){
        		setMemberId.add(param.BasicMemberInfo.Member_id);
        	}	
        }
               
        try
        {          	
          	List<Contact> tempContacts = [select
                          Id
                        , EtownMemberId__c
                        , FirstName
                        , LastName
                        , Email
                        , Phone
                        , MobilePhone
                        , CountryCode__c
                        , Salutation
                        , PreferredLanguage__c
                        , IsSocial__c
                        , PartnerCode__c
                        , DivisionCode__c
                        , EtownSyncCount__c
                        ,(select CreatedById,CreatedDate,Field from Histories where Field='Phone' or Field='MobilePhone' or Field='created' order by CreatedDate desc)
                        from Contact where EtownMemberId__c in :setMemberId];  
            
            for(Contact con:tempContacts){
            	mapContact.put(string.valueOf(con.EtownMemberId__c),con);
            }
            
                                             
            List<EtownPartner__c> partners = [select Id, Code__c, Name, CountryCode__c, ServerName__c, BusinessUnit__c from EtownPartner__c];
            
            for (UpdateContactParam param : paramList)
            {
                if (param.BasicMemberInfo != null && param.BasicMemberInfo.Member_id!=null)
                {
                    String memberId=string.valueOf(param.BasicMemberInfo.Member_id);
                    Contact contact=mapContact.get(memberId);
                    if (contact!=null)
                    {                        
                        ContactHistory PhoneLastChangedHistory=null;
                        ContactHistory MobileLastChangedHistory=null;
                                                                                        
                        for(ContactHistory ch:contact.Histories){
                        	if((ch.Field=='Phone' || ch.Field=='created') && (PhoneLastChangedHistory==null || PhoneLastChangedHistory.CreatedDate<ch.CreatedDate)){
                        		PhoneLastChangedHistory=ch;	
                        	}	
                        	
                        	if((ch.Field=='MobilePhone' || ch.Field=='created') && (MobileLastChangedHistory==null || MobileLastChangedHistory.CreatedDate<ch.CreatedDate)){
                        		MobileLastChangedHistory=ch;
                        	}
                        }
                        
                        //phone and mobile will only be updated if it's empty or last modified by the same account                                                  
                    	if(contact.Phone==null || contact.Phone=='' || PhoneLastChangedHistory==null || PhoneLastChangedHistory.CreatedById==UserInfo.getUserId()){
                    		contact.Phone = param.BasicMemberInfo.Phone;		
                    	}
                        
                        
                        //mobile will only be updated if it's empty or last modified by the same account                                                
                    	if(contact.MobilePhone==null || contact.MobilePhone=='' || MobileLastChangedHistory==null || MobileLastChangedHistory.CreatedById==UserInfo.getUserId()){
                    		contact.MobilePhone = param.BasicMemberInfo.Mobile;	
                    	}
                                                                                                
                        contact.CountryCode__c = param.BasicMemberInfo.CountryCode;
                        if (param.BasicMemberInfo.Gender != null && param.BasicMemberInfo.Gender != '')
                        {
                            contact.Salutation =
                                param.BasicMemberInfo.Gender == 'M'
                                    ? 'Mr.'
                                    : (param.BasicMemberInfo.Gender == 'F' ? 'Ms.' : '');
                        }
                        contact.PreferredLanguage__c = param.BasicMemberInfo.LanguageCode;
                        contact.IsSocial__c = param.BasicMemberInfo.IsSocialMember;
                        if (param.PartnerInfo != null)
                        {
                            contact.PartnerCode__c = param.PartnerInfo.PartnerCode;
                            // upsert partner
                            EtownMemberInfoServiceHelper.PartnerInfo partnerInfo = new EtownMemberInfoServiceHelper.PartnerInfo();
                            partnerInfo.PartnerCode = param.PartnerInfo.PartnerCode;
                            partnerInfo.TrackName = param.PartnerInfo.TrackName;
                            partnerInfo.BusinessUnit = param.PartnerInfo.BusinessUnit;
                            partnerInfo.ServerName = param.PartnerInfo.ServerName;
                            partnerInfo.CountryCode = param.PartnerInfo.CountryCode;
                            if (IsPartnerNeedUpsert(partners, partnerInfo))
                            {
                                PartnerSvc.upsertPartner(partnerInfo);
                            }
                        }
                        
                        if (param.CorporateInfo != null)
                        {
                            contact.DivisionCode__c = param.CorporateInfo.DivisionCode;
                            // upsert corporate and division
                            EtownMemberInfoServiceHelper.CorporateInfo corporateInfo = new EtownMemberInfoServiceHelper.CorporateInfo();
                            corporateInfo.CorporateCode = param.CorporateInfo.CorporateCode;
                            corporateInfo.CorporateName = param.CorporateInfo.CorporateName;
                            corporateInfo.DivisionCode = param.CorporateInfo.DivisionCode;
                            corporateInfo.DivisionName = param.CorporateInfo.DivisionName;
                            CorporateSvc.upsertCorporate(corporateInfo);
                            DivisionSvc.upsertDivision(corporateInfo);
                        }
                        
                        if (contact.EtownSyncCount__c == null)
                        {
                            contact.EtownSyncCount__c = 1;
                        }
                        else
                        {
                            contact.EtownSyncCount__c += 1;
                        }
                        
                        result = new UpdateContactResult();
                        result.IsSucceed = true;
                        result.Member_id = param.BasicMemberInfo.Member_id;
                        String newEmail = param.BasicMemberInfo.Email;
                        if (emailPattern.matcher(newEmail).matches())
                        {
                            contact.Email = newEmail;
                        }
                        else
                        {
                            result.ErrorCode = 'EmailInvalid';
                            result.ErrorMessage = 'Email is invalid, but other fields are updated. [Email:' + newEmail + ']';
                        }
                        contacts.add(contact);
                        tempResultList.add(result);
                    }
                    else
                    {
                        result = new UpdateContactResult();
                        result.IsSucceed = false;
                        result.Member_id = param.BasicMemberInfo.Member_id;
                        result.ErrorCode = 'NoContactFound';
                        result.ErrorMessage = 'No contact found';
                        
                        resultList.add(result);
                    }
                }
            }
            
            // update
            if (contacts.size() > 0)
            {
                update contacts;
                resultList.addAll(tempResultList);
            }
        }
        catch(Exception ex)
        {
            System.debug(ex);
            return resultList;
        }
        return resultList;
    }
    
    // If the partner need update or insert
    private static Boolean IsPartnerNeedUpsert(List<EtownPartner__c> partners, EtownMemberInfoServiceHelper.PartnerInfo partnerInfo)
    {
        for (EtownPartner__c partner : partners)
        {
            if (partner.Code__c == partnerInfo.PartnerCode)
            {
                if (partner.Name == partnerInfo.TrackName
                    && partner.CountryCode__c == partnerInfo.CountryCode
                    && partner.ServerName__c == partnerInfo.ServerName
                    && partner.BusinessUnit__c == partnerInfo.BusinessUnit)
                    {
                        return false;
                    }
                return true;
            }
        }
        return true;
    }
    
    
    global class UpdateContactResult 
    {
        webservice Integer Member_id;
        webservice Boolean IsSucceed;
        webservice String ErrorCode;
        webservice String ErrorMessage;
    }
    
    global class UpdateContactParam
    {
        webservice BasicMemberInfo BasicMemberInfo;
        webservice PartnerInfo PartnerInfo;
        webservice CorporateInfo CorporateInfo;
    }
    
    global class BasicMemberInfo
    {
        webservice Integer Member_id;
        webservice String FirstName;
        webservice String LastName;
        webservice String Email;
        webservice String Phone; 
        webservice String Mobile;
        webservice String CountryCode;
        webservice String Gender;
        webservice String LanguageCode;
        webservice Boolean IsSocialMember;
    }
    
    global class PartnerInfo
    {
        webservice String PartnerCode;
        webservice String TrackName;
        webservice String BusinessUnit;
        webservice String ServerName;
        webservice String CountryCode;
    }

    global class CorporateInfo
    {
        webservice String CorporateCode;
        webservice String CorporateName;
        webservice String DivisionCode;
        webservice String DivisionName;
    }   
}