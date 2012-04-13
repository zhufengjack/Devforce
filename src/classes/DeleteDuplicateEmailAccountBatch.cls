global class DeleteDuplicateEmailAccountBatch implements Database.Batchable<sObject>, Database.stateful
{
	public String accountQuery = 'select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c, (select Id, StageName, LastModifiedDate from Opportunities), (select Id from Contacts) from Account';
    private Integer accountAmount = 0;
    private Integer duplicateEmailAmount = 0;
    private Integer duplicateAccountAmountReal = 0;
    private Integer duplicateClosedWonAccountAmount = 0;
    private String previousBatchEmail = '';
    //private List<Account> previousDuplicateAccountList = new List<Account>();
    private Map<String, List<Account>> accountMap = new Map<String, List<Account>>(); 
    private Integer documentSerialNo = 0;
    private Boolean isFinished = false;
    
    // for delete account.
    private Integer amountOfDeleteAccount = 0;
    private Integer amountOfDeleteContact = 0;
    private Integer amountOfDeleteOpportunity = 0;
    private Map<String, List<Account>> accountDuplicateClosedWonMap = new Map<String, List<Account>>();
    
    private Set<Id> deletedAccountIds = new Set<Id>();
    
    public void filterEmailIsNull()
    {
       accountQuery += ' where Email__c != null order by Email__c';
    }
    
    global database.Querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(accountQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts)
    {
       if(accounts.size() > 0)
       {   
           for(Account acc : accounts)
           {
               String currentEmail = acc.Email__c.toLowerCase();
               if(accountMap.keySet().size() > 2000 && previousBatchEmail != currentEmail)
               {
                   deleteDuplicateData();
                   generateDocument(accountMap, 'Delete Account Report(test) ');
                   deletedAccountIds.clear();
                   accountMap.Clear();
                   documentSerialNo++;
                   if(accountDuplicateClosedWonMap.keySet().size() > 2000)
                   {
                       generateDocumentClosedWon(accountDuplicateClosedWonMap, 'Duplicate Closed Won Account Report(test)');
                       accountDuplicateClosedWonMap.clear();
                   }
               }
               if(accountMap.containsKey(currentEmail))
               {
                   accountMap.get(currentEmail).add(acc);
               }
               else
               {
                   accountMap.put(currentEmail, new List<Account> { acc });
                   // 如果前一个email的重复数组的Size为1.也就是没有重复.那么从Map里面移除.
                   if(accountMap.containsKey(previousBatchEmail))//accountMap.containsKey(previousBatchEmail))
                   {   
                       Integer previousEmailListSize = accountMap.get(previousBatchEmail).size();                     
                       if(previousEmailListSize < 2)
                       {
                           accountMap.remove(previousBatchEmail);
                       }
                   }
               }
               previousBatchEmail = currentEmail;
           }
       }
    }
    
    private void deleteDuplicateData()
    {
        if(accountMap != null && accountMap.size() > 0)
        {
            List<Contact> contactDeletedList = new List<Contact>();
            List<Opportunity> opportunityDeletedList = new List<Opportunity>();
            List<Account> accountDeletedList = new List<Account>();
            
            for(String accountEmail : accountMap.keySet())
            {
                List<Account> accountList = accountMap.get(accountEmail); 
                //用来存储 lastModifiedDate 为最新的 opportunity 和相关联的 Account。
                Opportunity lastCreatedOpportunity = null; // For no closed won account.
                Account lastCreatedOpportunityAssociatedAccount = null; // For no closed won account.
                //将要被删除的Account会被存储在这个Map里面。
                Map<Id, Account> sameEmailAccountMap = new Map<Id, Account>();
                // 用来标示 当前email下是否存在closed won opportunity。
                Boolean hasClosedWonAccount = false;
                // 用来标示当前Email下含有closed won account的数量。
                Integer closedWonAccountNumber = 0;
                
                for(Account account : accountList)
                {
                    List<Opportunity> opps = account.Opportunities;
                    List<Contact> contacts = account.Contacts;
                    Boolean isClosedWonAccount = false;
                    
                    if(opps.size() > 0)
                    {
                        if(lastCreatedOpportunity == null)
                        {
                            lastCreatedOpportunity = opps[0];
                            lastCreatedOpportunityAssociatedAccount = account;
                        }
                        for(Opportunity opp : opps)
                        {
                            if(opp.StageName == 'Closed Won' || opp.StageName == 'Payment Pending')
                            {
                                isClosedWonAccount = true;
                                hasClosedWonAccount = true;
                                addToAccountDuplicateClosedWonMap(accountEmail, account);
                                closedWonAccountNumber++;
                                break;
                            }
                            if(opp.LastModifiedDate > lastCreatedOpportunity.LastModifiedDate)
                            {
                                lastCreatedOpportunity = opp;
                                lastCreatedOpportunityAssociatedAccount = account;
                            }
                        }
                        if(!isClosedWonAccount)
                        {
                            // 把Account对象加入到map中，这个map中的内容将要被删除.
                            sameEmailAccountMap.put(account.Id, account);
                        }
                    }
                }
                
                if(closedWonAccountNumber == 1)
                {
                    accountDuplicateClosedWonMap.remove(accountEmail);
                }
                // Add to delete list.
                if(hasClosedWonAccount)
                { // If have closed won account under this. 
                    if(sameEmailAccountMap.size() > 0)
                    {
                        for(String accountId : sameEmailAccountMap.keySet())
                        {
                            Account tempAccount = sameEmailAccountMap.get(accountId);
                            accountDeletedList.add(tempAccount); // Add to deleted list.
                            if(tempAccount.contacts.size() > 0) // Add related contact to deleted list.
                            {
                               contactDeletedList.addAll(tempAccount.contacts);
                            }
                            if(tempAccount.Opportunities.size() > 0) // Add relate opportunity to deleted list.
                            {
                                opportunityDeletedList.addAll(tempAccount.Opportunities);
                            }
                        }
                    }
                }
                else
                {
                    if(sameEmailAccountMap.size() > 0)
                    {   
                        sameEmailAccountMap.remove(lastCreatedOpportunityAssociatedAccount.Id);// Remove last account.
                        for(String accountId : sameEmailAccountMap.keySet())
                        {
                            Account tempAccount = sameEmailAccountMap.get(accountId);
                            accountDeletedList.add(tempAccount); // Add to deleted list.
                            if(tempAccount.contacts.size() > 0)
                            {
                               contactDeletedList.addAll(tempAccount.contacts);
                            }
                            if(tempAccount.Opportunities.size() > 0)
                            {
                                opportunityDeletedList.addAll(tempAccount.Opportunities);
                            }
                        }
                    }
                }
                //temp .....
                deletedAccountIds.addAll(sameEmailAccountMap.keySet());
                //temp end ....
            }
            /*
            accountMap.clear();
            // Delete data.
            
            delete contactDeletedList;
            delete opportunityDeletedList;
            delete accountDeletedList;
            //*/
            amountOfDeleteAccount = amountOfDeleteAccount + accountDeletedList.size();
            amountOfDeleteContact = amountOfDeleteContact + contactDeletedList.size();
            amountOfDeleteOpportunity = amountOfDeleteOpportunity + opportunityDeletedList.size();
        }
    }
    
    private void addToAccountDuplicateClosedWonMap(String email, Account account)
    {
        if(account != null && email != null)
        {
            if(accountDuplicateClosedWonMap.keySet().contains(email))
            {
                accountDuplicateClosedWonMap.get(email).add(account);
            }
            else
            {
                accountDuplicateClosedWonMap.put(email, new List<Account>{account});
            }
        }
    }
    
    private void generateDocument(Map<String, List<Account>> tempMap, String documentSubject)
    {
        if(tempMap != null && tempMap.size() > 0)
        {
            Folder publicFolder = [select Id, Name from Folder where Name = 'Public'];
            Document doc = new Document(Name = documentSubject + documentSerialNo, FolderId = publicFolder.Id);
            String result = '';
            Datetime nowTime = Datetime.now();
            String dateString = nowTime.format();
            String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
            result = result + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
            result = result + formatDocumentBody(tempMap);
            doc.Body = Blob.valueOf(result);
            insert doc;
        }
    }
    
    private String formatDocumentBody(Map<String, List<Account>> tempMap)
    {
        String result = '';
        if(tempMap != null && tempMap.size() > 0)
        {
            result = result + 'Account amount in this doc: {!TableSizeParameter} \r\n\r\n';
            Integer tableSize = 0;
            for(String email : tempMap.keySet())
            { 
                duplicateEmailAmount++;
                List<Account> accountList = tempMap.get(email);
                result = result + email +' '+ accountList.size() + '\r\n';
                if(accountList != null && accountList.size() > 0)
                {   
                    tableSize += accountList.size();
                    for(Account account : accountList)
                    {
                        String recordTypeName = (account.RecordTypeId != null)? account.RecordType.Name: 'null';
                        String deleteResult = (deletedAccountIds.contains(account.Id)) ? 'true ': 'false';
                        result = result + deleteResult + '  ' + account.Id + '  ' + recordTypeName + '  ' + account.CreatedDate + '  ' + account.Email__c + ' \r\n';
                    }
                }
            }
            duplicateAccountAmountReal = duplicateAccountAmountReal + tableSize;
            result = result.replace('{!TableSizeParameter}', tableSize + ' ');
        }
        return result;
    }
    
    private void generateDocumentClosedWon(Map<String, List<Account>> tempMap, String documentSubject)
    {
        if(tempMap != null && tempMap.size() > 0)
        {
            Folder publicFolder = [select Id, Name from Folder where Name = 'Public'];
            Document doc = new Document(Name = documentSubject + documentSerialNo, FolderId = publicFolder.Id);
            String result = '';
            Datetime nowTime = Datetime.now();
            String dateString = nowTime.format();
            String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
            result = result + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
            result = result + formatDocumentBodyClosedWon(tempMap);
            doc.Body = Blob.valueOf(result);
            insert doc;
        }
    }  
    
    private String formatDocumentBodyClosedWon(Map<String, List<Account>> tempMap)
    {
        String result = '';
        if(tempMap != null && tempMap.size() > 0)
        {
            result = result + 'Account amount in this doc: {!TableSizeParameter} \r\n\r\n';
            Integer tableSize = 0;
            for(String email : tempMap.keySet())
            { 
                //duplicateEmailAmount++;
                List<Account> accountList = tempMap.get(email);
                result = result + email +' '+ accountList.size() + '\r\n';
                if(accountList != null && accountList.size() > 0)
                {   
                    tableSize += accountList.size();
                    for(Account account : accountList)
                    {
                        String recordTypeName = (account.RecordTypeId != null)? account.RecordType.Name: 'null';
                        String deleteResult = (deletedAccountIds.contains(account.Id)) ? 'true ': 'false';
                        result = result + deleteResult + '  ' + account.Id + '  ' + recordTypeName + '  ' + account.CreatedDate + '  ' + account.Email__c + ' \r\n';
                    }
                }
            }
            duplicateClosedWonAccountAmount = duplicateClosedWonAccountAmount + tableSize;
            result = result.replace('{!TableSizeParameter}', tableSize + ' ');
        }
        return result;
    }
    
    private void sendFinishedEmail()
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Account Query Finished');
        Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = '';
        htmlText = htmlText + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
        htmlText = htmlText + ' 存在重复Email的 Account 数量：' + duplicateAccountAmountReal + ' \r\n';
        htmlText = htmlText + ' 重复Email数量 ：' + duplicateEmailAmount + ' \r\n'; //duplicateEmailSet
        htmlText = htmlText + ' 重复的closed won account 的数量：' + duplicateClosedWonAccountAmount + ' \r\n' + ' \r\n';
        htmlText = htmlText + ' Delete重复的Account 的数量：' + amountOfDeleteAccount + ' \r\n';
        htmlText = htmlText + ' Delete重复的Opportunity 的数量：' + amountOfDeleteOpportunity + ' \r\n';
        htmlText = htmlText + ' Delete重复的Contact 的数量：' + amountOfDeleteContact;
        mail.setPlainTextBody(htmlText);
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // 判断最后一个email是不是存在重复值，如果不存在重复值，那么从map里面删除。
        List<Account> lastAccounts = accountMap.get(previousBatchEmail);
        if(lastAccounts != null)
        {
            if(lastAccounts.size() < 2)
            {
                accountMap.remove(previousBatchEmail);
            }
        }
        
        isFinished = true;
        deleteDuplicateData();
        generateDocument(accountMap, 'Delete Account Result(test) ');
        // 对Email重复，且Stage = Closed Won/Payment Pending.  生成报告。
        generateDocumentClosedWon(accountDuplicateClosedWonMap, 'Duplicate Closed Won Account Report(test)');
        sendFinishedEmail();
    }
    
    @isTest
    static void testDeleteDuplicateEmailAccountBatch()
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
        DeleteDuplicateEmailAccountBatch batch = new DeleteDuplicateEmailAccountBatch();
        batch.accountQuery += ' where Name like \'test account%\' and Email__c != null order by Email__c';
        Database.executeBatch(batch);
        Test.stopTest();
        batch.filterEmailIsNull();
    }
}