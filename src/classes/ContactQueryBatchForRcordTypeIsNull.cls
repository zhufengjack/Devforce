global class ContactQueryBatchForRcordTypeIsNull implements Database.Batchable<sObject>, Database.stateful
{
    public String AccountQueryString = 'select Id, Name, First_Name__c, Last_Name__c, Phone, Mobile__c, Email__c, OwnerId, (select Id, Name from Contacts) from Account where RecordTypeId = null';
    private Integer numberOfAccountWithoutContact = 0; 
    private Integer numberOfAccountWithMultiContact = 0; 
    private Map<String, String> accountWithMultiContactMap = new Map<String, String>(); 
    private Integer batchNumber = 0;
    private Integer emailAmount = 0;
    
    global database.Querylocator start(Database.BatchableContext BC)
    {   
        return Database.getQueryLocator(AccountQueryString);
    } 
    
    global void execute(Database.BatchableContext BC, List<Account> accounts)
    {
        if(accounts.size() > 0)
        {   
            batchNumber++; // Update batch number.
            List<Account> accountWithoutContactList = new List<Account>();
            for(Account account : accounts)
            {
                if(account.contacts.size() > 1)
                {   // If account have more than one contact.
                    numberOfAccountWithMultiContact++;
                    accountWithMultiContactMap.put(account.Id, account.Name);
                }
                else if(account.contacts.size() == 0)
                {   // If no contact under this contact.
                    numberOfAccountWithoutContact++;
                    accountWithoutContactList.add(account);
                }
            }  
            // Create contact for account that is no contact.
            createContactAndConectToStudentActual(accountWithoutContactList);
            // Send report to admin.
            sendAccountWithMultiContactInformationToAdmin(accountWithMultiContactMap);
        }
    }
    
    private void createContactAndConectToStudentActual(List<Account> accounts)
    {
        if(accounts != null && accounts.size() > 0)
        {
            Map<String, Contact> accountId2Contact = new Map<String, Contact>();
            for(Account account : accounts)
            {
                // Create new contact.
                Contact newContact = new Contact(FirstName = account.First_Name__c, phone = account.Phone, MobilePhone = account.Mobile__c, AccountId = account.Id);
                // LastName = account.Last_Name__c, 
                if(account.Last_Name__c == null || account.Last_Name__c == ' ')
                {
                	String accountName = account.Name;
                    newContact.LastName = (accountName.length() > 80) ? accountName.substring(0, 80) : accountName;
                }
                else
                {
                    newContact.LastName = account.Last_Name__c;
                }
                // Add this new contact to map.
                accountId2Contact.put(account.Id, newContact);
            }
            
            insert accountId2Contact.values();
            
            // Conect student actual to contact.
            // First: Select all student actuals.
            List<StudentActual__c> studentActualUpdatedList = new List<StudentActual__c>();
            List<StudentActual__c> studentActuals = [select Id, Student__c, Actual__r.Opportunity__r.AccountId from StudentActual__c where Actual__r.Opportunity__r.AccountId in :accountId2Contact.keySet() and Actual__r.Opportunity__r.AccountId != null];
            if(studentActuals.size() > 0)
            {
                for(StudentActual__c studentActual : studentActuals)
                {
                    if(accountId2Contact.containsKey(studentActual.Actual__r.Opportunity__r.AccountId))
                    {
                        studentActual.Student__c = accountId2Contact.get(studentActual.Actual__r.Opportunity__r.AccountId).Id;
                        studentActualUpdatedList.add(studentActual);
                    }
                }
                // Update student actuals.
                if(studentActualUpdatedList.size() > 0)
                {
                    update studentActualUpdatedList;
                }
            }
            
        }
    }
    
    private void sendAccountWithMultiContactInformationToAdmin(Map<String, String> accountMap)
    {
        if(accountMap != null && accountMap.size() > 0)
        {
            if(accountMap.size() >= 1000)
            {
                // Send Email to Admin
                if(emailAmount < 10)
                {
	                sendReportEmailPlainText('');
	                //Clear accountMap.
	                accountMap.clear();
	                emailAmount++;
                }
                else
                {
                	emailAmount++;
                    accountMap.clear();
                }
                //sendReportEmailPlainText('');
                //Clear accountMap.
                //accountMap.clear(); 
            }
        }
    }

    // For plaintext boday.
    public String generateAccountWithMultiContactTableText()
    {
        //accountWithMultiContactMap
        String htmlResult = 'Account with Multi Contact Table: (' + accountWithMultiContactMap.size() + ' records)\r\n';
        if(accountWithMultiContactMap != null && accountWithMultiContactMap.size() > 0)
        {
            Integer serialNumber = 1;
            for(String accountId : accountWithMultiContactMap.KeySet())
            {
                htmlResult += accountId + '  ' + accountWithMultiContactMap.get(accountId) + '\r\n';
                serialNumber++;
            }
        }
        return htmlResult;
        return null;
    }
    
    public void sendReportEmailPlainText(String flag)
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Contact Query Batch Report plainText');
        Datetime nowTime = Datetime.now();
        String finished = '';
        if(flag == 'finished')
        {
            finished = 'Finished Email';
        }
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = 'batch serial number: ' + batchNumber + '\r\n';
        htmlText = htmlText + finished + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\nAccount do not have contact:' + numberOfAccountWithoutContact + '\r\n';
        htmlText = htmlText + 'Account have more than one contact:' + numberOfAccountWithMultiContact + '\r\n';
        // Generate account table.
        htmlText += generateAccountWithMultiContactTableText();
        // Added this table string to email.
        mail.setPlainTextBody(htmlText);
        // Send email.
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // SendEmail To administrator.
        sendReportEmailPlainText('Finished');
    }
    
    @isTest
    static void testContactQueryBatch()
    {
        // Create accounts for testing. Record type is 'China Smart Record Type'.
        //String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and SobjectType = 'Account'].Id;
        //String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Account'].Id;
        List<Account> testAccountList = new List<Account>(); // Store account;
        Integer accountSize = 50; // The volume of account list.
        for(Integer i = 0; i < 50; i++)
        {
            Account tempAccount = new Account(Name = 'Test Account ' + i, First_Name__c = 'FName' + i, Last_Name__c = 'LName' + i, Phone = '76543' + i, Mobile__c = '8888' + i, Email__c = 'test' + i + '@g.com');
            testAccountList.add(tempAccount);
        }
        insert testAccountList;
        Datetime currentTime = Datetime.now();
        Date CloseDate = Date.today().addDays(10);
        List<Opportunity> oppList = new List<Opportunity>();
        Opportunity opp1 = new Opportunity(Name = 'Test_Opportunity_1', AccountId = testAccountList[0].Id, Initial_Appt_Date__c = currentTime, CloseDate = closeDate, StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp2 = new Opportunity(Name = 'Test_Opportunity_2', AccountId = testAccountList[1].Id, Initial_Appt_Date__c = currentTime, CloseDate = closeDate, StageName = 'Set Appt', China_Sales_Type__c = 'New');
        oppList.addAll(new List<Opportunity>{opp1, opp2});
        insert oppList;
        List<Actual__c> actualList = new List<Actual__c>();
        Actual__c actual1 = new Actual__c(Account__c = testAccountList[0].Id, Opportunity__c = opp1.Id);
        Actual__c actual2 = new Actual__c(Account__c = testAccountList[1].Id, Opportunity__c = opp2.Id);
        actualList.addAll(new List<Actual__c>{actual1, actual2});
        insert actualList;
        List<StudentActual__c> studentActualList = new List<StudentActual__c>();
        StudentActual__c studentActual1 = new StudentActual__c(Name = 'Test Student Actual_1', actual__c = actual1.Id);
        StudentActual__c studentActual2 = new StudentActual__c(Name = 'Test Student Actual_2', actual__c = actual2.Id);
        studentActualList.addAll(new List<StudentActual__c>{studentActual1, studentActual2});
        insert studentActualList;
        Test.startTest();
        ContactQueryBatchForRcordTypeIsNull batch = new ContactQueryBatchForRcordTypeIsNull();
        batch.AccountQueryString = 'select Id, Name, First_Name__c, Last_Name__c, Phone, Mobile__c, Email__c, OwnerId, (select Id, Name from Contacts) from Account where Name like \'Test Account %\'';
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest(); 
        Contact tempContact = [select Id, Firstname, Lastname, Phone, MobilePhone, Email from Contact where AccountId in (select Id from Account where Name = 'Test Account 1')];
        System.assertEquals('FName1', tempContact.FirstName);
        System.assertEquals('LName1', tempContact.LastName);
        System.assertEquals('765431', tempContact.Phone);
        System.assertEquals('88881', tempContact.MobilePhone);
        //System.assertEquals('test1@g.com', tempContact.Email);
        System.assertEquals([select Id, Student__c from StudentActual__c where Id = :studentActual1.Id].Student__c, [select Id from Contact where AccountId = :testAccountList[0].Id].Id);
    }
}