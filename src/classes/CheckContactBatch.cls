global class CheckContactBatch implements Database.Batchable<sObject>, Database.stateful
{
	public String contactQueryString = 'select Id, Lastname, AccountId from Contact ';
	public Id createdUserId = null;
    public String startTime = '2011-04-08T00:00:00Z';
    public String finishedTime = '2011-04-08T23:59:59Z';
	
	private Integer allContactAmount = 0;
	private Integer accountWithMultiContactAmount = 0;
	private Map<Id, String> accountId2Name = new Map<Id, String>();
	private List<Integer> batchSizeList = new List<Integer>();

	private Integer emialSerialNum = 0;
	private Integer batchNumber = 0;
	
	public void CreateQueryString()
	{
	   contactQueryString += 'where CreatedById = \'' + createdUserId + '\' and CreatedDate > ' + startTime + ' and CreatedDate < ' + finishedTime;
	}
	
    global database.Querylocator start(Database.BatchableContext BC)
    {  
        return Database.getQueryLocator(contactQueryString);
    }
    
    global void execute(Database.BatchableContext BC, List<Contact> contacts)
    {
        if(contacts.size() > 0)
        { 
        	batchNumber++;
        	// record current batch size.
            batchSizeList.add(contacts.size());
            // Store account id.
            Set<Id> accountIdSet = new Set<Id>();
            for(Contact contact : contacts)
            {
                if(contact.AccountId != null)
                {
                    accountIdSet.add(contact.AccountId);
                    allContactAmount++;
                }
            }
            
            List<Account> accounts = [select Id, Name, (select Id from Contacts) from Account where Id in : accountIdSet];
            for(Account account : accounts)
            {
                if(account.contacts.size() > 1)
                {
                	if(!accountId2Name.containsKey(account.Id))
                	{
                	    accountId2Name.put(account.Id, account.Name);
                        accountWithMultiContactAmount = accountWithMultiContactAmount + 1;
                	}
                }
            }
            
            // Send report to admin user.
            if(accountId2Name.size() > 220)
            {
            	emialSerialNum++;
                sendReportEmailToUser(false);
                accountId2Name.clear();
                
            }
        }
    }
    
    private void sendReportEmailToUser(Boolean isFinished)
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com', 'Jenny.Chen@ef.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Check incorrect contacts: ' + emialSerialNum);
        String emailPlainTextBody = generatePlainTextBody(isFinished);
        mail.setPlainTextBody(emailPlainTextBody);
        // Send email.
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail}); 
    }
    
    private String generatePlainTextBody(Boolean isFinished)
    {
    	String result = '';
    	Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        if(isFinished)
        {
            result += '***** This is final email *****\r\n';
        }
    	result += 'batch serial number: ' + batchNumber + '\r\n';
    	result += '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
    	if(accountId2Name != null && accountId2Name.size() > 0)
    	{
    	   result += 'Account table size:' + accountId2Name.size() + '\r\n';
    	   for(Id accountId : accountId2Name.keySet())
    	   {
    	       result += accountId + '   ' + accountId2Name.get(accountId) + '\r\n';
    	   }
    	}
    	
    	if(isFinished)
    	{
    	   result += '\r\n\r\n\r\n';
    	   result += '||++++++++++++++++++++ Batch Report ++++++++++++++++++++||\r\n';
    	   result += '创建重复contact的Account数量：' + accountWithMultiContactAmount + '\r\n';
    	   result += 'All contact amount:' + allContactAmount + '\r\n';  
    	}
    	
        return result;
    }
    
    global void finish(Database.BatchableContext BC)
    {
        // SendEmail To administrator.
        emialSerialNum++;
        sendReportEmailToUser(true);
    }
    
    @isTest
    static void testCheckContactBatch()
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
        List<Contact> contacts = new List<Contact>();
        Integer index = 1;
        for(Account account : testAccountList)
        {
            contacts.add(new Contact(AccountId = account.Id, LastName = 'test acme test' + index));
            index++;
        }
        insert contacts;
        Test.startTest();
        CheckContactBatch batch = new CheckContactBatch();
        batch.contactQueryString += ' where LastName like \'test acme test%\' ';
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest(); 
        batch.CreateQueryString();
    }
}