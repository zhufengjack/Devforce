/*
*    This controller for page "Override Task New". In the codes below, we will copy some fields from contact to new task.
*/
public class OverrideTaskNewController 
{
	public Task CurrentTask {get; set;}
	public AdditionalInfo AdditionalInfo {get; set;}
	
    public OverrideTaskNewController(ApexPages.StandardController controller)
    {
         CurrentTask = (Task)controller.getRecord();
         initialTask();
    }
    
    private void initialTask()
    {
    	 AdditionalInfo  = new AdditionalInfo();
         CurrentTask.Attempt__c = 1;
         CurrentTask.Status = 'Open';
         CurrentTask.ActivityDate = Date.today();
         List<Contact> contacts = [select Id, Name, AccountId, Account.Name, PreferredLanguage__c, CountryCode__c, CorporateCode__c, DivisionCode__c, TimeZone__c from Contact where Id = :CurrentTask.WhoId];
         if(contacts.size() > 0)
         {
         	 AdditionalInfo.ContactId = contacts[0].Id;
         	 AdditionalInfo.ContactName = contacts[0].Name;
         	 AdditionalInfo.AccountId = contacts[0].AccountId;
         	 AdditionalInfo.AccountName = contacts[0].Account.Name;
             CurrentTask.WhatId = contacts[0].AccountId;
             CurrentTask.Language__c = contacts[0].PreferredLanguage__c;
             CurrentTask.Country__c = contacts[0].CountryCode__c;
             CurrentTask.Corporate__c = contacts[0].CorporateCode__c;
             CurrentTask.Division__c = contacts[0].DivisionCode__c;
             CurrentTask.TimeZone__c = contacts[0].TimeZone__c;
         }
    }
    
    private String generateCallId(String uniqueId)
    {
        String year = String.valueOf(Datetime.now().yearGmt());
        String month = String.valueOf(Datetime.now().monthGmt());
        String day = String.valueOf(Datetime.now().dayGmt());
        String hour = String.valueOf(Datetime.now().hourGmt());
        String minute = String.valueOf(Datetime.now().minuteGmt());
        String second = String.valueOf(Datetime.now().secondGmt());
        month = (month.length() == 1)? '0' + month: month;
        day = (day.length() == 1)? '0' + day : day;
        hour = (hour.length() == 1)? '0' + hour : hour;
        minute = (minute.length() == 1)? '0' + minute : minute;
        second = (second.length() == 1)? '0' + second : second;
        return 'SA' + uniqueId + year + month + day + hour + minute + second;
    }
    
    private void checkInputValues()
    {
        if(CurrentTask.OwnerId == null)
        {
            throw new NewTaskException('Please input "Assign To".');
        }
        if(CurrentTask.Subject == null)
        {
            throw new NewTaskException('Please input "Subject".');
        }
        if(CurrentTask.ActivityDate == null)
        {
            throw new NewTaskException('Please input "Due Date".');
        }
    }
    
    private void closeOldAdviseTasks(String contactId, String currentTaskId)
    {
        if(contactId != null && currentTaskId != null)
        {
            List<Task> oldTasks = [select Id from Task where RecordType.Name = 'Study Advise' and whoId = :contactId and Id != :currentTaskId and Isclosed = false];
            for(Task task : oldTasks)
            {
                task.Status = 'Closed by System';
            }
            if(oldTasks.size() > 0)
            {
            	update oldTasks;
            }
        }
    }
    
    public PageReference checkTaskRecordType()
    {
    	Boolean isAdviseTask = false;
    	String recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
    	if(recordTypeId != null)
    	{
    	    List<RecordType> studyAdviseTaskRecordTypes = [select Id from RecordType where SobjectType = 'Task' and Name = 'Study Advise' and Id = :recordTypeId limit 1];
    	    if(studyAdviseTaskRecordTypes.size() != 0 )
    	    {
    	        isAdviseTask = true;
    	    }
    	}
    	else
    	{
    	    List<User> users = [select Id from User where Id = :UserInfo.getUserId() and Profile.Name like 'Englishtown study advisor%'];
    	    if(users.size() != 0)
    	    {
    	        isAdviseTask = true;
    	    }
    	}
    	if(!isAdviseTask)
    	{
    	    String currentPageUrl = ApexPages.currentPage().getUrl();
            String parameterUrl = '';
            if(currentPageUrl != null && currentPageUrl.indexOf('?') >= 0)
            {
                parameterUrl = currentPageUrl.subString(currentPageUrl.indexOf('?')).replace('?', '').replace('save_new=1', 'skip_select_RecordType_c=1');
            }
            return new PageReference('/00T/e?nooverride=1&' + parameterUrl);
    	}
        return null;
    }
    
    public pageReference save()
    {
    	try
    	{
    		checkInputValues();
	    	insert CurrentTask;
	        CurrentTask.CallId__c = generateCallId(CurrentTask.Id);
	        update CurrentTask;
	        closeOldAdviseTasks(CurrentTask.whoId, CurrentTask.Id);
	        return new PageReference('/' + AdditionalInfo.ContactId);
    	}
    	catch(Exception ex)
    	{
    	    ApexPages.addMessage(New ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
    	    return null;
    	}
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + AdditionalInfo.ContactId);
    }
    
    public class AdditionalInfo
    {
        public String ContactName {get; set;}
        public String ContactId {get; set;}
        public String AccountName {get; set;}
        public String AccountId {get; set;}
    }
    
    public class NewTaskException extends Exception{}
    
    @isTest
    static void testOverrideTaskNewController()
    {
    	Account testAccount = new Account(Name = 'Test Account');
    	insert testAccount;
    	Contact testContact = new Contact(LastName = 'Test Contact', AccountId = testAccount.Id, Email = 'test@ef.email.com', Phone = '765456', PreferredLanguage__c = 'en', CountryCode__c = 'cn', CorporateCode__c = 'cool');
    	insert testContact;
    	String adviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
    	Task oldAdviseTask = new Task(Subject = 'Test Sub', OwnerId = UserInfo.getUserId(), RecordTypeId = adviseTaskRecordTypeId, ActivityDate = Date.today(), WhoId = testContact.Id, WhatId = testAccount.Id, Status = 'Open');
        insert oldAdviseTask;
        Task newTask = new Task(RecordTypeId = adviseTaskRecordTypeId, WhoId = testContact.Id);
        ApexPages.StandardController standardController = new ApexPages.StandardController(newTask);
        OverrideTaskNewController controller = new OverrideTaskNewController(standardController);
        System.assertNotEquals(null, controller.checkTaskRecordType());
        controller.CurrentTask.Subject = 'for test';
        controller.CurrentTask.OwnerId = UserInfo.getUserId();
        controller.save();
        System.assertEquals(2, [select Id, (Select Id from Tasks ) from Contact where Id = :testContact.Id][0].tasks.size());
        System.assertEquals(true, [select Id, IsClosed from Task where Id = :oldAdviseTask.Id].IsClosed);
        System.assertEquals(testAccount.Id, [select Id, WhatId from Task where whoId = :testContact.Id and IsClosed = false].WhatId);
    }
}