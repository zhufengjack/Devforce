global class DeleteDuplicateContactBatch implements Database.Batchable<sObject>, Database.stateful
{
	String contactQueryString = 'select Id, Lastname, AccountId from Contact ';
	public Id createdUserId = '00540000000rpj3'; // User id jenny.
    public String startTime = '2011-04-07T00:00:00Z';
    public String finishedTime = '2011-04-07T23:59:59Z';
    
    private Integer deleteContactAmount = 0;
    private Integer allContactAmount = 0;
    private Map<Id, String> reportAccountMap = new Map<Id, String>();
    private Integer emialSerialNum = 0;
    private Integer batchNumber = 0;
    
    public void setCreatedUserId(String userId)
    {
        createdUserId = userId;
    }
    
    public void setStartTime(String startTimeString)
    {
        startTime = startTimeString; // format like '2011-04-07T00:00:00Z'.
    }
	
	public void setFinishedTime(String finishedTimeString)
	{
	    finishedTime = finishedTimeString;
	}
	
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
        if(contacts != null && contacts.size() > 0)
        {   
        	batchNumber++;
        	allContactAmount = allContactAmount + contacts.size();
        	
            Map<Id, Id> accId2Contact = new Map<Id, Id>();
            for(Contact contact : contacts)
            {
            	if(contact.AccountId != null)
            	{
            	    accId2Contact.put(contact.AccountId, contact.Id);
            	}
            }
            
            if(accId2Contact.size() > 0)
            {
                List<Account> accounts = [select Id, Name, (select Id from Contacts) from Account where Id in :accId2Contact.keySet() and RecordType.Name != 'China Smart B2B record type'];
                if(accounts.size() > 0)
                {
                	List<Contact> deletedCotacts = new List<Contact>();
	                for(Account acc : accounts)
	                {
	                    if(acc.contacts.size() == 2)
	                    {
	                        Id contactId = accId2Contact.get(acc.Id);
	                        deletedCotacts.add(new Contact(Id = contactId));
	                        reportAccountMap.put(acc.Id, acc.Name);
	                    }
	                }
	                if(deletedCotacts.size() > 0)
	                {
	                	deleteContactAmount = deleteContactAmount + deletedCotacts.size();
	                    delete deletedCotacts; 
	                }
	                if(reportAccountMap.size() > 1000)
	                {
	                	emialSerialNum++;
	                    sendReportEmailToAdmin(false);
	                    reportAccountMap.clear();
	                }
                }
            }
        }
    }
    
    private void sendReportEmailToAdmin(Boolean isFinished)
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'hobart.cui@meginfo.com', 'Jenny.Chen@ef.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Delete duplicate contacts report: ' + emialSerialNum);
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
        if(reportAccountMap != null && reportAccountMap.size() > 0)
        {
           result += 'Account table size:' + reportAccountMap.size() + '\r\n';
           for(Id accountId : reportAccountMap.keySet())
           {
               result += accountId + '   ' + reportAccountMap.get(accountId) + '\r\n';
           }
        }
        if(isFinished)
        {
           result += '\r\n\r\n\r\n';
           result += '||++++++++++++++++++++ Batch Report ++++++++++++++++++++||\r\n';
           result += '被删除的contact的数量;' + deleteContactAmount + '\r\n';
           result += '全部的Contact数量:' + allContactAmount;
        }
        
        return result;
    }
    
    global void finish(Database.BatchableContext BC)
    {
        emialSerialNum++;
        sendReportEmailToAdmin(true);
    }
    
    @isTest
    static void testDeleteDuplicateContactBatch()
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
        DeleteDuplicateContactBatch batch = new DeleteDuplicateContactBatch();
        batch.contactQueryString += ' where LastName like \'test acme test%\' ';
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
        batch.setCreatedUserId('00540000000rpj3');
        batch.setFinishedTime('acme');
        batch.setStartTime('acme');
        batch.CreateQueryString();
    }
    
}