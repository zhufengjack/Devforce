/*
 * a controller for override case new page 
 Change History Log:
 Pony Ma 2011-11-03 Get profiles from custom setting 'ETown Student Case Profiles' instead of defining them directly in controller
 Pony Ma 2011-11-15 Try to auto populate the contact field if the case is created from contact page(get def_contact_id in URL)
 */
public class OverrideCaseNewController
{
    private Case caseInfo;
    /* 
     * This variable records the steps of operation
     * 0 means that user fills an email address in Contact Lable or chooses contact from Lookup page
     * 1 means that user chooses one contact from PopUp page
     * 2 means that user chooses Country/Language/Partner infomation from PopUp page
     */
    private Integer step = 0;
    //get the profile list from custom setting, no longer need it.
    /** 
    private Set<String> crProfiles = new Set<String> { 
                                                            'Englishtown CR',
                                                            'Englishtown CR manager', 
                                                            'EF Europe Country Manager',
                                                            'EF France and Italy CR',
                                                            'EF France Sales Manager',
                                                            'EF France Sales User',
                                                            'EF Germany Sales Manager',
                                                            'EF Germany Sales User',
                                                            'EF Italy Sales Manager',
                                                            'EF Italy Sales User',
                                                            'EF MEAST Sales Manager',
                                                            'EF Spain Sales Manager',
                                                            'EF Spain Sales User'};
    */
    
    public OverrideCaseNewController(ApexPages.StandardController stdController)
    {       
        caseInfo = (Case)stdController.getRecord();
        caseInfo.OwnerId = UserInfo.getUserId();
        
        //try to find if the def_contact_id is defined in URL
        Integer index=ApexPages.currentPage().getUrl().indexOf('def_contact_id');
        if(index>-1){
        	//get the 15 digits contact id
        	String contactId=ApexPages.currentPage().getUrl().substring(index+15,index+30);        	
        	system.debug(contactId);        	
        	if(contactId!=null){
        		List<Contact> caseContactList=[select Id,Name,Email from Contact where Id=:contactId];
        		if(caseContactList.size()>0){
        			//caseInfo.ContactId=caseContactList[0].Id;        			
        			ContactEmail=caseContactList[0].Name;
        			SelectedContactId=caseContactList[0].Id;        			
        		}	
        	}
        }
    }
    
    public Integer SavedStep
    {
        get
        {
            return step;
        }
    }
    
    public List<Contact> Contacts
    {
        get
        {
            List<Contact> foundContacts = new List<Contact>();
            if(ContactEmail != null && (SelectedContactId == null || SelectedContactId == ''))
            {
                foundContacts = ContactSvc.getContactByEmail(ContactEmail);
            }
            return foundContacts;
        }
    }
    
    public Contact ContactInfo { get; set; }
    public String SelectedContactId { get; set; }
    public String TempLanguage
    { 
    	get
    	{
    		return '';
    	}
    	set; 
    }
    
    public String ContactEmail
    {
    	get;
    	set
    	{
    		if(value != null)
    		{
    			ContactEmail = value.trim();
    		}
    	}
	}
	
    public List<SelectOption> LanguageItems
    {
    	get
    	{
    		List<SelectOption> result = new List<SelectOption>();
    		result.add(new SelectOption('', ' '));
    		for(EtownLanguage__c language : [select Name, Code__c from EtownLanguage__c where Name != null and Code__c != null order by Name])
    		{
    			result.add(new SelectOption(language.Code__c, language.Name));
    		}
    		return result;
    	}
    }
    
    public List<SelectOption> BuItems
    {
    	get
    	{
    		List<SelectOption> result = new List<SelectOption>();
    		Set<String> buSet = new Set<String>();
    		List<String> buList = new List<String>();
    		for(EtownPartner__c partner : [select Id, BusinessUnit__c from EtownPartner__c where Code__c != null and BusinessUnit__c != null order by BusinessUnit__c])
    		{
    			buSet.add(partner.BusinessUnit__c);
    		}
    		buList.addAll(buSet);
    		buList.sort();
    		for(String currBU : buList)
    		{
    			result.add(new SelectOption(currBU, currBU));
    		}
    		return result;
    	}
    }
    
    public List<SelectOption> CountryItems
    {
        get
        {
            List<SelectOption> result = new List<SelectOption>();
            for(EtownCountry__c country : [select Name, Code__c from EtownCountry__c where Name != null and Code__c != null order by Name])
            {
				result.add(new SelectOption(country.Code__c, country.Name));
            }
            return result;
        }
    }
    
    //redirect user to standard new case page if record type of case is not ETown User Case
    public PageReference redirect()
    {       
        if(caseInfo.RecordTypeId != null)
        {
            RecordType reType = [select Id, Name from RecordType where Id = :caseInfo.RecordTypeId];
            if(reType.Name != 'ETown Student Case')
            {                                 
                 return new PageReference('/500/e?retURL=%2F500%2Fo&RecordType=' + caseInfo.RecordTypeId + '&ent=Case&nooverride=1');
            }
        }
        else
        {                                    
            Set<String> profiles=new Set<String>();
            Map<String,ETown_Student_Case_Profile__c> profileSetMap=ETown_Student_Case_Profile__c.getAll();
            for(String profileSetName:profileSetMap.keyset()){
            	profiles.add(profileSetMap.get(profileSetName).Profile_Name__c);
            }            
            String userProfile=[select Name from Profile where Id = :UserInfo.getProfileId()].Name;
            //if the profile is not in ETown Student Case Profiles, direct the page to standard case new page.
            if(!profiles.contains(userProfile)){            	
            	return new PageReference('/500/e?retURL=%2F500%2Fo&ent=Case&nooverride=1');	
            } 
                              
        }
        return null;
    }
    
    public PageReference save()
    {
        String relatedContactId;
        try
        {
            if((SelectedContactId == null || SelectedContactId == '') && !ContactSvc.checkEmailAddress(ContactEmail))
            {
                throw(new EtownException('Invalid email address', 0));
            }
            
            if(step == 2) //user click save button again after having selected Country/Partner infomation
            {
                fillContactInfoWithContact(ContactInfo);
                if(step == 0)
                {
                	if(ContactInfo.PartnerCode__c == '' || ContactInfo.PartnerCode__c == null)
                	{
                		update new Contact(Id=ContactInfo.Id, BU__c=ContactInfo.BU__c, CountryCode__c=ContactInfo.CountryCode__c);
                	}
                	else
                	{
	                	update new Contact(Id=ContactInfo.Id, BU__c=ContactInfo.BU__c, CountryCode__c=ContactInfo.CountryCode__c, PartnerCode__c=ContactInfo.PartnerCode__c);
                	}
	                relatedContactId = ContactInfo.Id;
                }
            }
            else if(SelectedContactId != null && SelectedContactId != '') //user select one contact in lookup page or popup page
            {
                if(step == 0 || step == 1) 
                {
                    List<Contact> contacts = [select EtownMemberId__c, Email, CountryCode__c, IsInitiallySynced__c, PartnerCode__c, PreferredLanguage__c, BU__c from Contact where Id = :SelectedContactId];
                    if(contacts.size() > 0)
                    {
                        ContactInfo = contacts[0];
                        fillContactInfoWithContact(ContactInfo);
                        relatedContactId = ContactInfo.Id;
                    }
                    else
                    {
                        throw(new EtownException('Invaid Contact Id', 0));
                    }
                }
            }
            else if(Contacts.size() == 0) //find none contact by email
            {
                relatedContactId = fillContactInfoWithoutContact(ContactEmail);
            }
            else if(Contacts.size() == 1) //find only one contact
            {
                if(step == 0)
                {
                    ContactInfo = Contacts[0];
                }
                
                fillContactInfoWithContact(ContactInfo);
                relatedContactId = ContactInfo.Id;
            }
            else //find more than one
            {
                Contact mappedContact = fillContactInfoWithContacts(ContactEmail, Contacts);
                if(mappedContact.Id != null)
                {
                    ContactInfo = mappedContact;
                    //map one contact 
                    fillContactInfoWithContact(mappedContact);
                }
                if(step == 0)
                {
                    relatedContactId = ContactInfo.Id;
                }
            }
            if(step != 0)
            {
                return null;
            }
            
            createCase(relatedContactId);
        }
        catch(Exception ex)
        {
            step = 0;
            String errorMessage = ex.getMessage();
            if(errorMessage != null && errorMessage.contains('DUPLICATE_VALUE'))
            {
            	errorMessage = 'Failed to create a new case, please contact system admin and copy the error message to them. Error Message: ' + errorMessage;
            	DatabaseHelper.dmlRollback();
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, errorMessage));
            return null;
        }
        return new PageReference('/' + caseInfo.Id);
    }
    
    public PageReference saveAndNew()
    {
        PageReference page;
        if(save() == null)
        {
            page = null;
        }
        else
        {
            page = new PageReference('/apex/OverrideCaseNew?retURL=%2F500%2Fo&RecordType=' + caseInfo.RecordTypeId + '&ent=Case&save_new=1&sfdc.override=1');
            page.setRedirect(true);
        }
        return page;
    }
    
    //maps a contact with full member info, otherwise creates a new contact with email or full member info
    private Id fillContactInfoWithoutContact(String email)
    {
        String newContactId;
        EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByEmaiFromEtown(email);
		DatabaseHelper.startDml(); //set datebase savepoint
        if(fullMemberInfo == null)
        {
            newContactId = ContactSvc.createContactByEmail(email);
        }
        else
        {
            newContactId = ContactSvc.mapContactWithFullMemberInfo(fullMemberInfo);
            //finds only one contact that will be updated with full memberinfo 
            if(newContactId != null)
            {
                ContactSvc.updateContactByMemberInfo(fullMemberInfo, newContactId);
            }
            else
            {
                newContactId = ContactSvc.createContactByMemberInfo(fullMemberInfo);
            }
        }
        return newContactId;
    }
    
    private void fillContactInfoWithContact(Contact confirmedContact)
    {
    	Boolean isFound = false;
    	EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo;
    	if(ContactInfo.IsInitiallySynced__c == false)
    	{
    		if(ContactInfo.EtownMemberId__c != null)
    		{
    			fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(confirmedContact.EtownMemberId__c);
    		}
    		else
    		{
	    		fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByEmaiFromEtown(confirmedContact.Email);
    		}
    		isFound = (fullMemberInfo != null)? true : isFound;
    	}
    	if(isFound)
    	{
    		DatabaseHelper.startDml(); //set datebase savepoint
    		ContactSvc.updateContactByMemberInfo(fullMemberInfo, confirmedContact.Id);
    	}
    	else
    	{
    		if(confirmedContact.CountryCode__c == null || confirmedContact.BU__c == null)
            {
                //tips user to select Country/Bu items
                step = 2;
            }
            else
            {
                step = 0;
            }
    	}
    }
    
    private Contact fillContactInfoWithContacts(String email, List<Contact> foundContacts)
    {
        Contact mappedContact = new Contact();
        EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByEmaiFromEtown(email);
        List<Contact> mappedContacts = new List<Contact>();
        if(fullMemberInfo != null)
        {
            mappedContacts = ContactSvc.mapFullMemberInfoWithContact(fullMemberInfo, foundContacts);
        }
        
        if(mappedContacts.size() == 1)
        {
            mappedContact = mappedContacts[0];
        }
        else
        {
            //tips user to select one contact
            step = 1;
        }
        return mappedContact;
    }
    
    private void createCase(String contactId)
    {
		List<Contact> contacts = [select PreferredLanguage__c from Contact where Id = :contactId];
		if(contacts.size() > 0)
		{
			caseInfo.ContactId = contactId;
			if(contacts[0].PreferredLanguage__c == '' || contacts[0].PreferredLanguage__c == null)
			{
				upsert new Contact(Id=ContactId, PreferredLanguage__c=caseInfo.LanguageCode__c);
			}
		}
        caseInfo.Subject = caseInfo.Category__c + '_' + caseInfo.Subcategory__c;
        try
        {
            upsert caseInfo;
        }
        catch(Exception ex)
        {
            throw(ex);
        }
    }
    
    @isTest
    static void testNotFindContactInSF()
    {
        Id recordTypeId = [select Id from RecordType where Name = 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
        Case caseInfo = new Case(Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email', RecordTypeId = recordTypeId);
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(caseInfo);
        OverrideCaseNewController controller = new OverrideCaseNewController(stdController);
        controller.redirect();
        //input a invaild email
        controller.ContactEmail = 'acme';
        controller.saveAndNew();
        //not find contact in SF but Etwon has one, no mapped contact in SF
        controller.ContactEmail = 'acme.acme@acme.com';
        controller.saveAndNew();
        //not find contact in SF but Etonw has one, mapped contact in SF
        List<Account> accounts = new List<Account>{
                                                    new Account(Name = 'acme'),
                                                    new Account(Name = 'acme1'),
                                                    new Account(Name = 'amce2') };
        insert accounts;
        List<Contact> contacts = new List<Contact>{
                                                    new Contact(LastName = 'acme', FirstName = 'acme', Phone = '12312345678', AccountId = accounts[0].Id),
                                                    new Contact(LastName = 'acme', Email = 'acme@acme.com', AccountId = accounts[1].Id)
                                                };
        insert contacts;
        controller.saveAndNew();
        //find more than one contacts
        Contact contact1 = new Contact(LastName='acme', Email='acme@acme.com', AccountId = accounts[2].Id);
        insert contact1;
    }
    
    @isTest
    static void testFindContactInSF()
    {
        Case caseInfo = new Case(Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email');
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(caseInfo);
        OverrideCaseNewController controller = new OverrideCaseNewController(stdController);
        Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName='acme', Email='acme.acme.acme.123@acme.com', AccountId = account.Id);
        insert contact;
        //find only one contact in the SF
        controller.ContactEmail = 'acme.acme.acme.123@acme.com';
        controller.saveAndNew();
        //user input the Country/Language/Parnter
        controller.ContactInfo.CountryCode__c = 'cc';
        controller.ContactInfo.PartnerCode__c = 'pc';
        controller.ContactInfo.PreferredLanguage__c = 'lc';
        controller.saveAndNew();
        //syn the contact info with Etown Etwon
        contact.EtownMemberId__c = 123123123;
        contact.IsInitiallySynced__c = false;
        update contact;
        controller.saveAndNew();
    }
    
    @isTest
    static void testFindContactsInSF()
    {
        Case caseInfo = new Case(Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email');
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(caseInfo);
        OverrideCaseNewController controller = new OverrideCaseNewController(stdController);
        List<Account> accounts = new List<Account>{
                                new Account(Name = 'acme'),
                                new Account(Name = 'acme1') };
        
        insert accounts;
        List<Contact> contacts = new List<Contact>{
                                                    new Contact(LastName = 'acme1', Email = 'acme@acme.com', AccountId = accounts[0].Id),
                                                    new Contact(LastName = 'acme2', Email = 'acme@acme.com', AccountId = accounts[1].Id)
                                                };
        insert contacts;
        controller.ContactEmail = 'acme@acme.com';
        controller.saveAndNew();
        //user select on contact
        controller.SelectedContactId = contacts[0].Id;
        controller.saveAndNew();
    }
    
    @isTest
    static void testPropertyFunction()
    {
        Id recordTypeId = [select Id from RecordType where Name != 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
        Case caseInfo = new Case(Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email', RecordTypeId = recordTypeId);
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(caseInfo);
        OverrideCaseNewController controller = new OverrideCaseNewController(stdController);
        controller.redirect();
        system.assert(controller.CountryItems.size() > 0);
        system.assert(controller.SavedStep == 0);
        system.assert(controller.LanguageItems.size() > 0);
        system.assert(controller.BuItems.size() > 0);
    }
}