global class AccountQueryPhoneBatch implements Database.Batchable<sObject>, Database.stateful
{
    public String accountQuery = 'select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c from Account';
    private Integer accountAmount = 0;
    private Integer duplicateEmailAmount = 0;
    private Integer duplicateAccountAmountReal = 0;
    //private String previousBatchEmail = '';
    private String previousBatchMobile = '';
    private List<Account> previousDuplicateAccountList = new List<Account>();
    private Map<String, List<Account>> accountMap = new Map<String, List<Account>>(); 
    private Integer documentSerialNo = 0;
    private Boolean isFinished = false;
    
    public void filterEmailIsNull()
    {
       accountQuery += ' where Email__c = null and phone != null order by phone';
    }
    
    global database.Querylocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(accountQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> accounts)
    {
       if(accounts.size() > 0)
       {
           Integer accountListSize = accounts.size();
           String previousMobile = previousBatchMobile;
           List<Account> tempAccounts = previousDuplicateAccountList;
           for(Integer i = 0; i < accountListSize; i++)
           {
               String currentMobile = accounts[i].phone.toLowerCase();
               if(currentMobile == previousMobile)
               {
                   tempAccounts.add(accounts[i]);
                   if(i == accountListSize - 1)
                   { // For last account in this batch.
                       accountMap.put(previousMobile, tempAccounts);
                       previousBatchMobile = currentMobile;
                       previousDuplicateAccountList = tempAccounts;
                   }
               }
               else
               {
                   if(i == accountListSize - 1)
                   { // For last account in this batch.
                       tempAccounts.add(accounts[i]);
                       previousBatchMobile = currentMobile;
                       previousDuplicateAccountList = tempAccounts;
                   }
                   else
                   {
                       if(tempAccounts.size() > 1)
                       {
                           accountMap.put(previousMobile, tempAccounts);
                       }
                       // Create a new list for store accounts. reset the previous email.
                       previousMobile = currentMobile;
                       tempAccounts = new List<Account>();
                       tempAccounts.add(accounts[i]);
                   }
               }
           } // End for.
           
           if(accountMap.size() > 2000)
           {
               generateDocument(accountMap);
               accountMap.Clear();
               documentSerialNo++;
           }
       } // End if.
    }
    
    private void generateDocument(Map<String, List<Account>> tempMap)
    {
        if(tempMap != null && tempMap.size() > 0)
        {
            Folder publicFolder = [select Id, Name from Folder where Name = 'Public'];
            Document doc = new Document(Name = 'Account Query Result[Duplicate Phone] ' + documentSerialNo, FolderId = publicFolder.Id);
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
            for(String mobile : tempMap.keySet())
            { 
                if(mobile == previousBatchMobile && isFinished == false)
                {
                    continue;
                }
                else
                {
                    duplicateEmailAmount++;
                    List<Account> accountList = tempMap.get(mobile);
                    if(accountList != null && accountList.size() > 0)
                    {   
                        tableSize += accountList.size();
                        for(Account account : accountList)
                        {
                            String recordTypeName = (account.RecordTypeId != null)? account.RecordType.Name: 'null';
                            result = result + account.Id + '  ' + recordTypeName + '  ' + account.CreatedDate + '  [Phone]' + account.phone + '  [Mobile]' + account.Mobile__c + ' \r\n';
                        }
                    }
                }
                
            }
            duplicateAccountAmountReal = duplicateAccountAmountReal + tableSize;
            result = result.replace('{!TableSizeParameter}', tableSize + ' ');
        }
        return result;
    }
    
    private void sendFinishedEmail()
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Account Query Finished(Duplicate Mobiles)');
        Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = '';
        htmlText = htmlText + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
        htmlText = htmlText + ' 存在重复Phone的 Account 数量：' + duplicateAccountAmountReal + ' \r\n';
        htmlText = htmlText + ' 重复Phone数量 ：' + duplicateEmailAmount; //duplicateEmailSet
        mail.setPlainTextBody(htmlText);
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    global void finish(Database.BatchableContext BC)
    {
        isFinished = true;
        generateDocument(accountMap);
        sendFinishedEmail();
    }
    
    @isTest
    static void testAccountQueryPhoneBatch()
    {
        String accountRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and SobjectType = 'Account'].Id;
        List<Account> testAccountList = new List<Account>();
        Integer size = 50;
        Integer sameEmailSize = 0;
        Integer emailRandomNo = 1000;
        for(Integer i = 0; i < size; i++)
        {
            Account acc = new Account(Name = 'test account ' + i, phone = '1000000' + emailRandomNo);
            sameEmailSize++;
            if(sameEmailSize == 3)
            {
                emailRandomNo++;
                sameEmailSize = 0;
            }
            testAccountList.add(acc);
        }
        insert testAccountList;
        Test.startTest();
        AccountQueryPhoneBatch batch = new AccountQueryPhoneBatch();
        batch.accountQuery += ' where Name like \'test account%\' and Email__c = null and phone != null order by phone';
        Database.executeBatch(batch);
        Test.stopTest();
        batch.filterEmailIsNull();
    }
}