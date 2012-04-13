/*
 * Middle layer of Contact object
 * Pony Ma 2012-02-06 Added EtownMemberId__c=null filter in getContactByEmail method
 * Pony Ma 2012-02-07 Added a new mehtod getContactByEmailWithoutMemberID
 */ 
public class ContactSvc 
{
    public static List<Contact> getContactByEmail(String email)
    {
        List<Contact> contacts = new List<Contact>();
        if(email != null && email != '')
        {
            contacts = [select Id, Name, FirstName, LastName, BU__c, Account.Name, Owner.Name, Email, EtownMemberId__c, CountryCode__c, PreferredLanguage__c, PartnerCode__c, IsSocial__c, IsInitiallySynced__c, MobilePhone, Phone from Contact where Email != null and Email = :email ];
        }
        return contacts;
    }
    
    //used EtownCaseInfoService webservice
    public static List<Contact> getContactByEmailWithoutMemberId(String email)
    {
        List<Contact> contacts = new List<Contact>();
        if(email != null && email != '')
        {
            contacts = [select Id, Name, FirstName, LastName, BU__c, Account.Name, Owner.Name, Email, EtownMemberId__c, CountryCode__c, PreferredLanguage__c, PartnerCode__c, IsSocial__c, IsInitiallySynced__c, MobilePhone, Phone from Contact where EtownMemberId__c = null and Email != null and Email = :email ];
        }
        return contacts;
    }
    
    public static Contact getContactByMemberId(Double memberId)
    {
        List<Contact> contacts = new List<Contact>();
        if(memberId != null)
        {
            contacts = [select Id, IsInitiallySynced__c, EtownMemberId__c from Contact where EtownMemberId__c != null and EtownMemberId__c = :memberId ];
        }
        Contact contact = new Contact();
        if(contacts.size() > 0)
        {
            contact = contacts[0];
        }
        return contact;
    }
    
    //matches contact if only one contact matched, othrewise return null
    public static Id mapContactWithFullMemberInfo(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo)
    {
        Id contactId;
        if(fullMemberInfo != null && fullMemberInfo.MemberInfo != null)
        {
            List<Contact> contacts = new List<Contact>();
            EtownMemberInfoServiceHelper.MemberInfo basicInfo = fullMemberInfo.MemberInfo;
            
            contacts = [select Id from Contact where EtownMemberId__c != null and EtownMemberId__c = :basicInfo.MemberId limit 1];
            if(contacts.size() > 0)
            {
                contactId = contacts[0].Id;
            }
            else
            {
                String firstName = basicInfo.FirstName;
                String lastName = basicInfo.LastName;
                String email = basicInfo.Email;
                String phone = basicInfo.Phone; 
                String mobile = basicInfo.Mobile;
                
                Set<String> phoneSet = new Set<String>();
                if(phone != null && phone != '')
                {
                    phoneSet.add(phone);
                }
                if(mobile != null && mobile != '')
                {
                    phoneSet.add(mobile);
                }
                contacts = [select Id from Contact where EtownMemberId__c = null and 
                                                            ((FirstName = :firstName and FirstName != null and LastName = :lastName and LastName != null and ((Phone in :phoneSet or MobilePhone = : phoneSet) or (Email != null and Email = :email))) 
                                                                or (Email = :email and Email != null and (Phone in :phoneSet or MobilePhone = : phoneSet))
                                                              ) ];
                if(contacts.size() == 1)
                {
                    contactId = contacts[0].Id;
                }
            }
        }
        return contactId;
    }
    
    //macthes full member infomation with the specified contacts
    public static List<Contact> mapFullMemberInfoWithContact(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo, List<Contact> foundContacts)
    {
        List<Contact> result = new List<Contact>();
        if(fullMemberInfo != null && fullMemberInfo.MemberInfo != null && foundContacts.size() > 0)
        {
            EtownMemberInfoServiceHelper.MemberInfo basicInfo = fullMemberInfo.MemberInfo;
            String firstName = basicInfo.FirstName;
            String lastName = basicInfo.LastName;
            String email = basicInfo.Email;
            String phone = basicInfo.Phone; 
            String mobile = basicInfo.Mobile;
            
            result = [select Id, Name, BU__c, FirstName, LastName, Account.Name, Owner.Name, Email, EtownMemberId__c, CountryCode__c, PreferredLanguage__c, PartnerCode__c, IsSocial__c, IsInitiallySynced__c, MobilePhone, Phone from Contact where EtownMemberId__c != null and EtownMemberId__c = :basicInfo.MemberId limit 1];

            if(result.size() == 0)
            {
                Set<String> phoneSet = new Set<String>();
                if(phone != null && phone != '')
                {
                    phoneSet.add(phone);
                }
                if(mobile != null && mobile != '')
                {
                    phoneSet.add(mobile);
                }
                for(Contact contact : foundContacts)
                {   
                    if(contact.EtownMemberId__c == null)
                    {
                        Boolean isMatchedPhone = (phoneSet.contains(contact.Phone) || phoneSet.contains(contact.MobilePhone));
                        if(contact.FirstName == firstName && contact.LastName == lastName && ((contact.Email != null && contact.Email == email) || isMatchedPhone))
                        {
                            result.add(contact);
                        }
                        else if(contact.Email != null && contact.Email == email && isMatchedPhone)
                        {
                            result.add(contact);
                        }
                    }
                }
            }
        }
        return result;
    }   
    
    public static Boolean updateContactByMemberInfo(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo, String contactId)
    {
        Boolean isSuccess = false;
        if(fullMemberInfo != null && fullMemberInfo.MemberInfo != null)
        {
            EtownMemberInfoServiceHelper.MemberInfo basicInfo = fullMemberInfo.MemberInfo;
            List<Contact> contacts = [select Id, Account.Type from Contact where Id = :contactId];
            
            if(contacts.size() > 0)
            {
                Contact contact = contacts[0];
                contact = basicInfo2Contact(fullMemberInfo, contact);
                if(contact.AccountId != null && contact.Account.Type == 'Visitor')
                {
                    Account account = createStudentAccount(basicInfo);
                    if(account.Id != null)
                    {
                        contact.AccountId = account.Id;
                        contact.FirstName = basicInfo.FirstName;
                        contact.LastName = basicInfo.LastName;
                    }
                }
                
                try
                {
                    update contact;
                    isSuccess = true;
                    EtownMemberInfoServiceHelper.markMemberAsSalesforceMember(contact.EtownMemberId__c);
                    updateCorpoAndPartner(fullMemberInfo);
                }
                catch(DMLException ex)
                {
                    isSuccess = false;
                    throw(new EtownException(ex.getMessage(), 0));
                }
            }
        }
        return isSuccess;
    }
    
    public static Id createContactByMemberInfo(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo)
    {
        Contact contact = new Contact();
        if(fullMemberInfo != null && fullMemberInfo.MemberInfo != null)
        {
            EtownMemberInfoServiceHelper.MemberInfo basicInfo = fullMemberInfo.MemberInfo;
            if(basicInfo.LastName != null)
            {
                contact = basicInfo2Contact(fullMemberInfo, contact);
                contact.FirstName = basicInfo.FirstName;
                contact.LastName = basicInfo.LastName;
                
                Account account = createStudentAccount(basicInfo);
                contact.AccountId = account.Id;
                contact.RecordTypeId = getRecordTypeId('ETown_User_Contact_record_type', 'Contact');
                Id ownerId = getEtownSystemUserId();
                if(ownerId != null)
                {
                    contact.OwnerId = ownerId;
                }
                
                try
                {
                    insert contact;
                    EtownMemberInfoServiceHelper.markMemberAsSalesforceMember(contact.EtownMemberId__c);
                    updateCorpoAndPartner(fullMemberInfo);
                }
                catch(DMLException ex)
                {
                    throw(new EtownException(ex.getMessage(), 0));
                }
            }
        }
        return contact.Id;
    }
        
    //creates a contact by email address
    public static Id createContactByEmail(String email)
    {
        Contact contact = new Contact();
        String trimEmail = (email != null) ? email.trim() : email;
        if(checkEmailAddress(trimEmail))
        {
            List<Account> accounts = [select Id from Account where Type = 'Visitor' and RecordType.DeveloperName = 'Etown_Teacher_account_record_type' limit 1];
            if(accounts.size() > 0)
            {
                contact.LastName = email.subString(0, trimEmail.indexOf('@'));
                contact.Email = trimEmail;
                contact.AccountId = accounts[0].Id;
                contact.RecordTypeId = getRecordTypeId('ETown_User_Contact_record_type', 'Contact');
                Id ownerId = getEtownSystemUserId();
                if(ownerId != null)
                {
                    contact.OwnerId = ownerId;
                }
                try
                {
                    insert contact;
                }
                catch(DMLException ex)
                {
                    throw(new EtownException(ex.getMessage(), 0));
                }
            }
            else
            {
                throw(new EtownException('Not find Visitor Account, please contact admin to create it', 0));
            }
        }
        else 
        {
            throw(new EtownException('Invalid email address', 0));
        }
        return contact.Id;
    } 
    
    public static Boolean checkEmailAddress(String email)
    {
        String reg = '^[\\w-\\.!#\\$%\\^&\\*\\(\\)\\-=_\\+/|\\?`~\']+@(?:\\w+-*\\.?)+[\\w-]+$';
        Boolean isAvailable = false;
        if(email != null)
        {
            isAvailable = Pattern.matches(reg, email);
        }
        return isAvailable;
    }
    
    private static Contact basicInfo2Contact(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo, Contact contact)
    {
        EtownMemberInfoServiceHelper.MemberInfo basicInfo = fullMemberInfo.MemberInfo;
         EtownMemberInfoServiceHelper.PartnerInfo partnerInfo = fullMemberInfo.PartnerInfo;
        EtownMemberInfoServiceHelper.CorporateInfo corporateInfo = fullMemberInfo.CorporateInfo;
        if(basicInfo != null)
        {
            contact.EtownMemberId__c = basicInfo.MemberId;
            
            if(basicInfo.Email != null && basicInfo.Email != '')
            {
                contact.Email = basicInfo.Email;
            }
            /*
            if(basicInfo.Phone != null && basicInfo.Phone != '')
            {
                contact.Phone = basicInfo.Phone;
            }
            if(basicInfo.Mobile != null && basicInfo.Mobile != '')
            {
                contact.MobilePhone = basicInfo.Mobile;
            }
            */
            contact.CountryCode__c = basicInfo.CountryCode;
            contact.IsSocial__c = basicInfo.IsSocialMember;
            contact.PreferredLanguage__c = basicInfo.LanguageCode;
            contact.PartnerCode__c = basicInfo.PartnerCode;
            contact.DivisionCode__c = basicInfo.DivisionCode;
            contact.IsInitiallySynced__c = true;
            
            if(basicInfo.Gender == 'M')
            {
                contact.Salutation =  'Mr.';
            }
            else if(basicInfo.Gender == 'F')
            {
                contact.Salutation = 'Ms.';
            }
            else if(contact.Salutation == null)
            {
                contact.Salutation = '';
            }
            if(corporateInfo != null && corporateInfo.CorporateCode != null)
            {
                contact.CorporateCode__c = corporateInfo.CorporateCode;
            }
            if(partnerInfo != null && partnerInfo.BusinessUnit != null)
            {
                contact.BU__c = partnerInfo.BusinessUnit;
            }
        }
        return contact;
    }
    
    private static void updateCorpoAndPartner(EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo)
    {
        EtownMemberInfoServiceHelper.PartnerInfo partnerInfo = fullMemberInfo.PartnerInfo;
        EtownMemberInfoServiceHelper.CorporateInfo corporateInfo = fullMemberInfo.CorporateInfo;
        
        if(corporateInfo != null && corporateInfo.CorporateCode != null)
        {
            CorporateSvc.upsertCorporate(corporateInfo);
        }
        if(corporateInfo != null && corporateInfo.DivisionCode != null)
        {
            DivisionSvc.upsertDivision(corporateInfo);
        }
        if(partnerInfo != null && partnerInfo.PartnerCode != null)
        {
            PartnerSvc.upsertPartner(partnerInfo);
        }
    }
    
    private static Account createStudentAccount(EtownMemberInfoServiceHelper.MemberInfo memberInfo)
    {
        Account account = new Account();
        account.Name = memberInfo.FirstName + ' ' + memberInfo.LastName;
        account.First_Name__c = (memberInfo.FirstName.length() > 25) ? memberInfo.FirstName.substring(0, 25) : memberInfo.FirstName;
        account.Last_Name__c = (memberInfo.LastName.length() > 25) ? memberInfo.LastName.substring(0, 25) : memberInfo.LastName;
        account.Email__c =memberInfo.Email;
        account.Phone = memberInfo.Phone;
        account.Mobile__c = memberInfo.Mobile;
        account.RecordTypeId = getRecordTypeId('ETown_Student_Account_record_type', 'Account');
        Id ownerId = getEtownSystemUserId();
        if(ownerId != null)
        {
            account.OwnerId = ownerId;
        }
        try
        {
            insert account;
        }
        catch(DMLException ex)
        {
            throw(new EtownException(ex.getMessage(), 0));
        }
        return account;
    }
    
    private static Id getEtownSystemUserId()
    {
        Id userId;
        List<User> users = [select Id from User where Name = 'ETown System' and IsActive = true limit 1];
        if(users.size() > 0)
        {
            userId = users[0].Id;
        }
        return userId;
    }
    
    private static Id getRecordTypeId(String name, String objName)
    {
        List<RecordType> recordType = [Select Id from RecordType where DeveloperName = :name and IsActive = true and SObjectType = :objname];
        if(recordType.size() > 0)
        {
            return recordType[0].Id;
        } 
        return null;
    }
    
    @isTest
    static void testContactSvc()
    {
        List<Contact> contacts = new List<Contact>{
                                                    new Contact(LastName = 'acme1', Email = 'acme@acme.com', EtownMemberId__c = 1241241244),
                                                    new Contact(LastName = 'acme2', FirstName = 'acme', Phone = '12312345678'),
                                                    new Contact(LastName = 'acme3', Email = 'acme@acme.com')
                                                };
        insert contacts;
        ContactSvc.getContactByEmail('acme@acme.com');
        ContactSvc.getContactByMemberId(1241241244);
        EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByEmaiFromEtown('acme@acme.com');
        ContactSvc.mapContactWithFullMemberInfo(fullMemberInfo);
        ContactSvc.mapFullMemberInfoWithContact(fullMemberInfo, contacts);
        ContactSvc.updateContactByMemberInfo(fullMemberInfo, contacts[0].Id);
        Contact contact = [select Id from Contact where EtownMemberId__c = :fullMemberInfo.memberInfo.MemberId];
        delete contact;
        ContactSvc.createContactByMemberInfo(fullMemberInfo);
        ContactSvc.createContactByEmail('acme.acme@acme.com');      
    }
    
    @isTest
    static void testCheckEmailAddress()
    {
        System.assert(checkEmailAddress('a@a.com'));
        System.assert(checkEmailAddress('a-a@a.com'));
        System.assert(checkEmailAddress('a@a-a.com'));
        System.assert(checkEmailAddress('a@a.com.cn'));
        System.assert(checkEmailAddress('a1@a1.com'));
        System.assert(checkEmailAddress('a-1.a1@a1.com'));
        System.assert(checkEmailAddress('!#$%^.&*(.)-=_+/|?`~@a-.a-.1-a'));
        System.assert(!checkEmailAddress('asd-bcd.dfdf@kdrd.abb..com'));
    }
}