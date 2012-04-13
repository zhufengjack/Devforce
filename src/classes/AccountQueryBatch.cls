/*
* This batch apex for Account Query.It will find duplicate account use email address. 
*/
global class AccountQueryBatch implements Database.Batchable<sObject>, Database.stateful
{
	public String accountQuery = 'select Id, Name, RecordTypeId, RecordType.Name, CreatedDate, Email__c, Phone, Mobile__c from Account';
	private Integer accountAmount = 0;
	private Integer duplicateEmailAmount = 0;
	private Integer duplicateAccountAmountReal = 0;
	private String previousBatchEmail = '';
	private List<Account> previousDuplicateAccountList = new List<Account>();
	private Map<String, List<Account>> accountMap = new Map<String, List<Account>>(); 
	private Integer documentSerialNo = 0;
	private Boolean isFinished = false;
	
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
	   	   Integer accountListSize = accounts.size();
       	   String previousEmail = previousBatchEmail;
       	   List<Account> tempAccounts = previousDuplicateAccountList;
           for(Integer i = 0; i < accountListSize; i++)
           {
               String currentEmail = accounts[i].Email__c.toLowerCase();
               if(currentEmail == previousEmail)
               {
                   tempAccounts.add(accounts[i]);
                   if(i == accountListSize - 1)
                   { // For last account in this batch.
                       accountMap.put(previousEmail, tempAccounts);
                       previousBatchEmail = currentEmail;
                       previousDuplicateAccountList = tempAccounts;
                   }
               }
               else
               {
               	   if(i == accountListSize - 1)
               	   { // For last account in this batch.
               	       tempAccounts.add(accounts[i]);
               	       previousBatchEmail = currentEmail;
               	       previousDuplicateAccountList = tempAccounts;
               	   }
               	   else
               	   {
               	       if(tempAccounts.size() > 1)
                       {
                           accountMap.put(previousEmail, tempAccounts);
                       }
                       // Create a new list for store accounts. reset the previous email.
                       previousEmail = currentEmail;
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
		    Document doc = new Document(Name = 'Account Query Result ' + documentSerialNo, FolderId = publicFolder.Id);
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
	        	if(email == previousBatchEmail && isFinished == false)
	        	{
	        	    continue;
	        	}
	        	else
	        	{
	        		duplicateEmailAmount++;
		        	List<Account> accountList = tempMap.get(email);
	                if(accountList != null && accountList.size() > 0)
	                {   
	                    tableSize += accountList.size();
	                    for(Account account : accountList)
	                    {
	                        String recordTypeName = (account.RecordTypeId != null)? account.RecordType.Name: 'null';
	                        result = result + account.Id + '  ' + recordTypeName + '  ' + account.CreatedDate + '  ' + account.Email__c + ' \r\n';
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
        mail.setSubject('Account Query Finished');
        Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = '';
        htmlText = htmlText + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
        htmlText = htmlText + ' 存在重复Email的 Account 数量：' + duplicateAccountAmountReal + ' \r\n';
        htmlText = htmlText + ' 重复Email数量 ：' + duplicateEmailAmount; //duplicateEmailSet
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
    static void testAccountQueryBatch()
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
        Test.startTest();
        AccountQueryBatch batch = new AccountQueryBatch();
        batch.accountQuery += ' where Name like \'test account%\' and Email__c != null order by Email__c';
        Database.executeBatch(batch);
        Test.stopTest();
        batch.filterEmailIsNull();
    }
}