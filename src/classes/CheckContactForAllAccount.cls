global class CheckContactForAllAccount implements Database.Batchable<sObject>, Database.stateful
{
    public String AccountQueryString = 'select Id, Name, (select Id, Name from Contacts) from Account where (RecordType.Name != \'China Smart B2B record type\' and RecordType.Name != \'Etown Teacher account record type\') or RecordTypeId = null';
    private Integer numberOfAccountWithoutContact = 0; // Count account that without contact.
    private Integer numberOfAccountWithMultiContact = 0; // Count account that have more than one contact.
    private Map<String, String> accountWithMultiContactMap = new Map<String, String>(); // <AccountId, AccountName>.
    private Map<String, String> accountWithoutContactMap = new Map<String, String>(); // <AccountId, AccountName>. 
    private Integer batchNumber = 0;
    
    private Integer noContactEmailAmount = 0;
    private Integer multiContactEmailAmount = 0;
    
    global database.Querylocator start(Database.BatchableContext BC)
    {   
        return Database.getQueryLocator(AccountQueryString);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts)
    {
        if(accounts.size() > 0)
        {   
            batchNumber++; // Update batch number.
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
                    accountWithoutContactMap.put(account.Id, account.Name);
                }
            }  
            // Create contact for account that is no contact.
            // Send report to admin.
            sendAccountWithMultiContactInformationToAdmin(accountWithMultiContactMap);
            sendAccountWithoutContactInformationToAdmin(accountWithoutContactMap);
        }
    }
    
    private void sendAccountWithMultiContactInformationToAdmin(Map<String, String> accountMap)
    {
        if(accountMap != null && accountMap.size() > 0)
        {
            if(accountMap.size() >= 1000)
            {
                // Send Email to Admin
                if(multiContactEmailAmount < 10)
                {
                    sendReportEmailPlainText('', accountMap);
                    multiContactEmailAmount++;
	                //Clear accountMap.
	                accountMap.clear(); 
                }
                else
                {
                	multiContactEmailAmount++;
                    accountMap.clear();
                }
            }
        }
    }
    
    private void sendAccountWithoutContactInformationToAdmin(Map<String, String> accountMap)
    {
        if(accountMap != null && accountMap.size() > 0)
        {
            if(accountMap.size() >= 1000)
            {
            	if(noContactEmailAmount < 10)
            	{
                    sendReportEmailPlainTextForNoContactAccount('', accountMap);
                    noContactEmailAmount++;
                    accountMap.clear();
            	}
            	else
            	{
            	    noContactEmailAmount++;
                    accountMap.clear();
            	} 
            }
        }
    }

    // For plaintext boday.
    public String generateAccountWithMultiContactTableText(Map<String, String> accountMap)
    {
        //accountWithMultiContactMap
        String htmlResult = 'Contact Table: (' + accountMap.size() + ' records)\r\n';
        if(accountMap != null && accountMap.size() > 0)
        {
            Integer serialNumber = 1;
            for(String accountId : accountMap.KeySet())
            {
                htmlResult += accountId + '  ' + accountMap.get(accountId) + '\r\n';
                serialNumber++;
            }
        }
        return htmlResult;
    }
    
    public void sendReportEmailPlainText(String flag, Map<String, String> accountMap)
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Contact Query Batch Report plainText Multi:' + multiContactEmailAmount);
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
        htmlText += generateAccountWithMultiContactTableText(accountMap);
        // Added this table string to email.
        mail.setPlainTextBody(htmlText);
        // Send email.
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    public void sendReportEmailPlainTextForNoContactAccount(String flag, Map<String, String> accountMap)
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Contact Query Batch Report plainText For No Contact Account:' + noContactEmailAmount);
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
        htmlText += generateAccountWithMultiContactTableText(accountMap);
        // Added this table string to email.
        mail.setPlainTextBody(htmlText);
        // Send email.
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // SendEmail To administrator.
        sendReportEmailPlainText('Finished', accountWithMultiContactMap);
        sendReportEmailPlainTextForNoContactAccount('Finished', accountWithoutContactMap);
    }
    
    @isTest
    static void testCheckContactForAllAccount()
    {
        // Create accounts for testing. Record type is 'China Smart Record Type'.
        String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and SobjectType = 'Account'].Id;
        //String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Account'].Id;
        List<Account> testAccountList = new List<Account>(); // Store account;
        Integer accountSize = 50; // The volume of account list.
        for(Integer i = 0; i < 50; i++)
        {
            Account tempAccount = new Account(Name = 'Test Account ' + i, RecordTypeId = accountRecordTypeId, First_Name__c = 'FName' + i, Last_Name__c = 'LName' + i, Phone = '76543' + i, Mobile__c = '8888' + i, Email__c = 'test' + i + '@g.com');
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
        CheckContactForAllAccount batch = new CheckContactForAllAccount();
        //batch.AccountQueryString += ' and Name like \'Test Account %\' ';
        batch.AccountQueryString = 'select Id, Name, (select Id, Name from Contacts) from Account where Name like \'Test Account %\' ';
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();         
    }
}