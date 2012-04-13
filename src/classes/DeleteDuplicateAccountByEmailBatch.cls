/*
*  If one opportunity stage = close won or payment pending, keep the account which opportunity stage = close won and delete the other accounts/contact/opportunity.
*  If opportunity stage is not close won or payment pending, keep the most recent one (use last modified date) and delete the other duplicated account and associated contact and opportunity.
*/
global class DeleteDuplicateAccountByEmailBatch implements Database.Batchable<sObject>
{
    public String accountQuery = 'select Id from Account where Email__c != null and Email__c != \'jenny.chen@ef.com\' ';
    
    global database.Querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(accountQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts)
    {
        if(accounts.size() > 0)
        {
            List<Account> currentBatchAccounts = selectAccountFromDatabase(accounts);
            if(currentBatchAccounts.size() > 0)
            {
                Set<String> emailSet = new Set<String>();
                for(Account acc : currentBatchAccounts)
                {
                    emailSet.add(acc.Email__c);
                }
                List<Account> duplicateEmailAccounts = [select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c, (select Id, StageName, Initial_Appt_Date__c, LastModifiedDate from Opportunities), (select Id from Contacts) from Account where Email__c in :emailSet and Email__c != null];
                Map<String, List<Account>> email2Accounts = new Map<String, List<Account>>();
                for(Account acc : duplicateEmailAccounts)
                {
                    if(acc.Opportunities.size() > 0)
                    {
                        String emailAddress = acc.Email__c;
                        emailAddress = emailAddress.toLowerCase();
                        if(email2Accounts.containsKey(emailAddress))
                        {
                            email2Accounts.get(emailAddress).add(acc);
                        }
                        else
                        {
                            email2Accounts.put(emailAddress, new List<Account>{acc});
                        }
                    }  
                }
                deleteDuplicateAccountProcess(email2Accounts);
            }
        }
    }
    
    private List<Account> selectAccountFromDatabase(List<Account> accounts)
    {
        List<Account> results = new List<Account>();
        Set<String> accountIds = new Set<String>();
        for(Account acc : accounts)
        {
            accountIds.add(acc.Id);
        }
        if(accountIds.size() > 0)
        {
            results = [select Id, Email__c from Account where Id in :accountIds];
        }
        return results;
    }
    
    private void deleteDuplicateAccountProcess(Map<String, List<Account>> email2Accounts)
    {
        if(email2Accounts.size() > 0)
        {
            List<Account> accountWillBeDeletedList = new List<Account>();
            
            for(String email : email2Accounts.keySet())
            {
                List<Account> sameEmailAccounts = email2Accounts.get(email);
                List<Account> analysisResults = analyseAccountData(sameEmailAccounts);
                if(analysisResults != null && analysisResults.size() > 0)
                {
                    accountWillBeDeletedList.addAll(analysisResults);
                }
            }
            deleteDuplicateData(accountWillBeDeletedList);
        }
    }
    
    private void deleteDuplicateData(List<Account> duplicateAccounts)
    {
        if(duplicateAccounts != null && duplicateAccounts.size() > 0)
        {
            List<Account> accountWillBeDeletedList = new List<Account>();
            List<Opportunity> oppWillBeDeletedList = new List<Opportunity>();
            LIst<Contact> contactWillBeDeletedList = new List<Contact>();
            for(Account acc : duplicateAccounts)
            {
                accountWillBeDeletedList.add(acc);
                if(acc.Opportunities.size() > 0)
                {
                    oppWillBeDeletedList.addAll(acc.Opportunities);
                }
                if(acc.contacts.size() > 0)
                {
                    contactWillBeDeletedList.addAll(acc.contacts);
                }
            }
            try
            {
                TempAccount__c accountQueryDetail;
                if(accountWillBeDeletedList.size() > 0)
                {
                    accountQueryDetail = new TempAccount__c(Type__c = 'Email', AccountAmount__c = accountWillBeDeletedList.size(), ContactAmount__c = contactWillBeDeletedList.size(), OpportunityAmount__c = oppWillBeDeletedList.size());
                }
                Database.delete(oppWillBeDeletedList, false);
                Database.delete(contactWillBeDeletedList, false);
                Database.delete(accountWillBeDeletedList, false);
                if(accountQueryDetail != null)
                {
                    insert accountQueryDetail;
                }
            }
            catch(Exception ex){}
        }
    }
    
    private List<Account> analyseAccountData(List<Account> sameEmailAccounts)
    {
        List<Account> results = new List<Account>();
        if(sameEmailAccounts.size() > 1)
        {
            results = filterClosedWonAccount(sameEmailAccounts);
        }
        return results; 
    }
    
    private List<Account> filterClosedWonAccount(List<Account> sameEmailAccounts)
    {
        if(sameEmailAccounts != null && sameEmailAccounts.size() > 0)
        {
            List<Account> results = new List<Account>();
            Boolean hasClosedWonOpp = false;
            for(Account acc : sameEmailAccounts)
            {
                List<Opportunity> relatedOpps = acc.Opportunities;
                if(relatedOpps.size() > 0)
                {   
                    Boolean isclosedWonAccount = false;
                    for(Opportunity opp : relatedOpps)
                    {
                        if(opp.StageName == 'Closed Won' || opp.StageName == 'Payment Pending')
                        {
                            hasClosedWonOpp = true;
                            isclosedWonAccount = true;
                        }
                    }
                    if(isclosedWonAccount == false)
                    {
                        results.add(acc);
                    }
                }
            }
            if(hasClosedWonOpp)
            {
                return results;
            }
            else
            {
                //return null;
                results = filterOtherAccount(sameEmailAccounts);
                return results;
            }
        }
        return null;
    }
    
    private List<Account> filterOtherAccount(List<Account> sameEmailAccounts)
    {
        if(sameEmailAccounts != null && sameEmailAccounts.size() > 0)
        {   
            List<Account> results = new List<Account>();
            Opportunity lastModifiedOpportunity;
            Account lastModifiedAssociatedAccount;
            Opportunity lastInitalApptDateOpportunity;
            Account lastInitalApptDateAssociatedAccount;
            for(Account acc : sameEmailAccounts)
            {
                List<Opportunity> relatedOpps = acc.Opportunities;
                if(relatedOpps.size() > 0)
                {
                    if(lastModifiedOpportunity == null)
                    {
                        lastModifiedOpportunity = relatedOpps[0];
                        lastModifiedAssociatedAccount = acc;
                    }
                    if(lastInitalApptDateOpportunity == null)
                    {
                        lastInitalApptDateOpportunity = relatedOpps[0];
                        lastInitalApptDateAssociatedAccount = acc;
                    }
                    for(Opportunity opp : relatedOpps)
                    {
                        if(opp.LastModifiedDate > lastModifiedOpportunity.LastModifiedDate)
                        {
                            lastModifiedOpportunity = opp;
                            lastModifiedAssociatedAccount = acc;
                        }
                        if(opp.Initial_Appt_Date__c != null && lastInitalApptDateOpportunity.Initial_Appt_Date__c != null)
                        {
                            if(opp.Initial_Appt_Date__c > lastInitalApptDateOpportunity.Initial_Appt_Date__c)
                            {
	                            lastInitalApptDateOpportunity = opp;
	                            lastInitalApptDateAssociatedAccount = acc;
                            }
                        }
                        else if(opp.Initial_Appt_Date__c != null)
                        {
                            lastInitalApptDateOpportunity = opp;
                            lastInitalApptDateAssociatedAccount = acc;
                        } 
                    }
                }
            }
            if(lastInitalApptDateAssociatedAccount != null && lastInitalApptDateOpportunity.Initial_Appt_Date__c != null)
            {
                for(Account acc : sameEmailAccounts)
                {
                    if(acc.Id != lastInitalApptDateAssociatedAccount.Id)
                    {
                        results.add(Acc);
                    }
                }
            }
            else if(lastModifiedAssociatedAccount != null)
            {
                for(Account acc : sameEmailAccounts)
                {
                    if(acc.Id != lastModifiedAssociatedAccount.Id)
                    {
                        results.add(Acc);
                    }
                }
            }
            if(results.size() > 0)
            {
                return results;
            }
        }
        return null;
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // To do ...
        sendFinishedEmail();
    }
    
    private void sendFinishedEmail()
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'hobart.cui@meginfo.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Account Query Finished');
        Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = 'Finished time: ' + GMTDateString;
        mail.setPlainTextBody(htmlText);
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    @isTest
    static void testDeleteDuplicateAccountByEmailBatch()
    {
        String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and SobjectType = 'Account'].Id;
        List<Account> testAccountList = new List<Account>();
        Integer size = 50;
        Integer sameEmailSize = 0;
        Integer emailRandomNo = 1000;
        for(Integer i = 0; i < size; i++)
        {
            Account acc = new Account(Name = 'test account ' + i, Email__c = 'test.' + emailRandomNo + '@test.com');
            sameEmailSize++;
            if(sameEmailSize == 3)
            {
                emailRandomNo++;
                sameEmailSize = 0;
            }
            testAccountList.add(acc);
        }
        insert testAccountList;
        List<Opportunity> relatedOpps = new List<Opportunity>();
        List<Contact> relatedContacts = new List<Contact>();
        for(Integer i = 0; i < testAccountList.size(); i++)
        {
            if(i < 10)
            {
                Opportunity opp1 = new Opportunity(Name = 'Test_Opp_e1_11' + i, AccountId = testAccountList[i].Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
                Opportunity opp2 = new Opportunity(Name = 'Test_Opp_e1_12' + i, AccountId = testAccountList[i].Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
                relatedOpps.add(opp1);
                relatedOpps.add(opp2);
                Contact tempContact = new Contact(Lastname = 'Test_Contact_'+i, AccountId = testAccountList[i].Id);
                relatedContacts.add(tempContact);
            }
            else
            {
                Opportunity opp1 = new Opportunity(Name = 'Test_Opp_e1_11' + i, AccountId = testAccountList[i].Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
                Opportunity opp2 = new Opportunity(Name = 'Test_Opp_e1_12' + i, AccountId = testAccountList[i].Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
                relatedOpps.add(opp1);
                relatedOpps.add(opp2);
                Contact tempContact = new Contact(Lastname = 'Test_Contact_'+i, AccountId = testAccountList[i].Id);
                relatedContacts.add(tempContact);
            }
        }
        insert relatedOpps;
        insert relatedContacts;
        
        Test.startTest();
        DeleteDuplicateAccountByEmailBatch batch = new DeleteDuplicateAccountByEmailBatch();
        batch.accountQuery += ' and Name like \'test account%\' ';
        Database.executeBatch(batch);
        Test.stopTest();
    }
    
    @isTest
    static void testBatchMethods()
    {
        String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and SobjectType = 'Account'].Id;
        // Creates accounts for group 1.
        Account acc11 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G1_001', Email__c = 'group1@email.com');
        Account acc12 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G1_002', Email__c = 'group1@email.com');
        Account acc13 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G1_003', Email__c = 'Group1@email.com');
        // Creates accounts for group 2.
        Account acc21 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G2_001', Email__c = 'group2@email.com');
        Account acc22 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G2_002', Email__c = 'group2@email.com');
        Account acc23 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G2_003', Email__c = 'group2@email.com');
        // Creates accounts for group 3.
        Account acc31 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G3_001', Email__c = 'group3@email.com');
        Account acc32 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G3_002', Email__c = 'group3@email.com');
        Account acc33 = new Account(recordTypeId = accountRecordTypeId, Name = 'Account_G3_003', Email__c = 'group3@email.com');
        insert new List<Account>{acc11, acc12, acc13, acc21, acc22, acc23, acc31, acc32, acc33};
        
        // Creates contacts for group 1.
        Contact con11 = new Contact(AccountId = acc11.Id, LastName = 'Contact_G1_001');
        Contact con12 = new Contact(AccountId = acc12.Id, LastName = 'Contact_G1_002');
        Contact con13 = new Contact(AccountId = acc13.Id, LastName = 'Contact_G1_003');
        // Creates contacts for group 2.
        Contact con21 = new Contact(AccountId = acc21.Id, LastName = 'Contact_G2_001');
        Contact con22 = new Contact(AccountId = acc22.Id, LastName = 'Contact_G2_002');
        Contact con23 = new Contact(AccountId = acc23.Id, LastName = 'Contact_G2_003');
        // Creates contacts for group 3.
        Contact con31 = new Contact(AccountId = acc31.Id, LastName = 'Contact_G3_001');
        Contact con32 = new Contact(AccountId = acc32.Id, LastName = 'Contact_G3_002');
        Contact con33 = new Contact(AccountId = acc33.Id, LastName = 'Contact_G3_003');
        insert new List<Contact>{con11, con12, con13, con21, con22, con23, con31, con32, con33};
        
        // Creates opps for group 1.
        Opportunity opp11 = new Opportunity(Name = 'Opp_G1_001', AccountId = acc11.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
        Opportunity opp12 = new Opportunity(Name = 'Opp_G1_002', AccountId = acc12.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
        Opportunity opp13 = new Opportunity(Name = 'Opp_G1_003', AccountId = acc13.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        // Creates opps for group 2.
        Opportunity opp21 = new Opportunity(Name = 'Opp_G2_001', AccountId = acc21.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp22 = new Opportunity(Name = 'Opp_G2_002', AccountId = acc22.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Payment Pending', China_Sales_Type__c = 'New');
        Opportunity opp23 = new Opportunity(Name = 'Opp_G2_003', AccountId = acc23.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        // Creates opps for group 3.
        Opportunity opp31 = new Opportunity(Name = 'Opp_G3_001', AccountId = acc31.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp32 = new Opportunity(Name = 'Opp_G3_002', AccountId = acc32.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp33 = new Opportunity(Name = 'Opp_G3_003', AccountId = acc33.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        insert new List<Opportunity>{opp11, opp12, opp13, opp21, opp22, opp23, opp31, opp32, opp33};
        update new Opportunity(Id = opp32.Id, Initial_Appt_Date__c = Datetime.now().addDays(3));
        List<Account> group1Accounts = [select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c, (select Id, StageName, LastModifiedDate, Initial_Appt_Date__c from Opportunities), (select Id from Contacts) from Account where Name like 'Account_G1_%'];
        List<Account> group2Accounts = [select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c, (select Id, StageName, LastModifiedDate, Initial_Appt_Date__c from Opportunities), (select Id from Contacts) from Account where Name like 'Account_G2_%'];
        List<Account> group3Accounts = [select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c, (select Id, StageName, LastModifiedDate, Initial_Appt_Date__c from Opportunities), (select Id from Contacts) from Account where Name like 'Account_G3_%'];
        
        DeleteDuplicateAccountByEmailBatch batch = new DeleteDuplicateAccountByEmailBatch();
        List<Account> analysisResult1 = batch.analyseAccountData(group1Accounts);
        System.assertEquals(acc13.Id, analysisResult1[0].Id);
        List<Account> analysisResult2 = batch.analyseAccountData(group2Accounts);
        System.assertEquals(2, analysisResult2.size());
        List<Account> analysisResult3 = batch.analyseAccountData(group3Accounts);
        System.assertEquals(2, analysisResult3.size());
        
        Map<String, List<Account>> email2Accounts = new Map<String, List<Account>>();
        email2Accounts.put('group1@email.com', group1Accounts);
        email2Accounts.put('group2@email.com', group2Accounts);
        email2Accounts.put('group3@email.com', group3Accounts);
        batch.deleteDuplicateAccountProcess(email2Accounts);
        Set<Id> deleteAccountIdSet = new Set<Id>{acc13.Id, acc21.Id, acc23.Id};
        Set<Id> unDeleteAccountIdSet = new Set<Id>{acc11.Id, acc12.Id, acc22.Id};
        System.assertEquals(0, [select Id from Account where Id in :deleteAccountIdSet].size());
        System.assertEquals(3, [select Id from Account where Id in :unDeleteAccountIdSet].size());
    }
    
    
}