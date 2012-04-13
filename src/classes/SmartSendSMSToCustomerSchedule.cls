/*
 * A schedule job to send reminder SMS to customer
 */
global class SmartSendSMSToCustomerSchedule implements Database.Batchable<SObject>, Schedulable, Database.AllowsCallouts
{
    private String smsMessageTemplate;
    private Map<Id, DateTime> Id2DateTime = new Map<Id, DateTime>(); // key : eventId, value : eventDateTime
    private Set<Id> profileIds = new Set<Id>();
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
    	for(Profile profile : [select Id from Profile where Name in ('EF China Sales User New LTC', 'EF China Sales User New')])
    	{
	    	profileIds.add(profile.Id);	
    	}
        return Database.getQueryLocator([select Id, WhatId, StartDateTime from Event where Subject like '%sales demo%' and Appt_Status__c = 'Scheduled' and Owner.ProfileId in :profileIds and Owner.IsActive = true and ActivityDate = :Date.today().addDays(1)]);
    }
    
    global void execute(Database.BatchableContext BC, List<Event> events)
    {
        for(Event event : events)
        {   
            Id2DateTime.put(event.WhatId, event.StartDateTime);
        }
        
        List<Opportunity> opps = [select Id, Mobile__c, Owner.Id, Owner.Name, Owner.MobilePhone, AccountId, Account.Name, Opportunity_Number__c, Contact__c, Contact__r.LastName, Contact__r.FirstName, Location__c from Opportunity where Id in :Id2DateTime.keySet() and Owner.IsActive = true];
        List<Task> tasks = new List<Task>();
        for(Opportunity opp : opps)
        {   
        	String message = getMessage(opp);
            SendSMSHelper.SmsParams params = new SendSMSHelper.SmsParams();
        	params.BusinessUnit = SchoolInfoHelper.getBU(opp.Location__c); //bu is global variable
        	params.Content = message;
        	params.MobileNumber = opp.Mobile__c;
        	params.OppNumber = opp.Opportunity_Number__c;
            SendSMSHelper.SMSInfo smsInfo = SendSMSHelper.sendSMS(params);
            if(smsInfo.isSucceeded)
            {
                Task task = new Task();
                task.WhatId = opp.Id;
                task.Subject = 'Send SMS';
                task.ActivityDate = Date.Today();
                task.Status = 'In sending';
                task.OwnerId = opp.OwnerId;
                task.Priority = 'Normal';
                task.WhoId = opp.Contact__c;
                task.Description = message;
                task.MessageID__c = smsInfo.MsgId;
                task.RecordTypeId = getRecordTypeId('Send SMS', 'Task');
                tasks.add(task);    
            }
        }
        try
        {
            insert tasks;
        }
        catch(DmlException ex)
        {
            String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
            SendEmailHelper.sendSimpleEmail(new String[] { 'exception@meginfo.com' }, 'EF: Error occureed on SmartSendSmsToCustomer class', error);
        }   
    }
    
    global void finish(Database.BatchableContext BC)    {}
    
    global void execute(SchedulableContext SC)
    {
        SmartSendSMSToCustomerSchedule batch = new SmartSendSMSToCustomerSchedule();
        Database.executeBatch(batch, 1);
    }
    
    private String getMessage(Opportunity opp)
    {
        if(smsMessageTemplate == null)
        {
            List<SmsTemplate__c> templates = [select Name, Message__c from SmsTemplate__c where Name = 'Remind SMS to Customer' limit 1];
            if(templates.size() > 0)
            {
                smsMessageTemplate = templates[0].Message__c;
            }
            else
            {
                smsMessageTemplate = '';
            }
        }
        String name = (opp.AccountId == null) ? '' : opp.Account.Name ;
        if(opp.Contact__c != null)
        {
            name = ((opp.Contact__r.LastName == null) ? '' : opp.Contact__r.LastName) + ((opp.Contact__r.FirstName == null) ? '' : opp.Contact__r.FirstName);
        }
        String message = smsMessageTemplate.replace('{Name}', name);
        message = message.replace('{OpportunityOwner}', opp.Owner.Name);
        message = message.replace('{OwnerMobilePhone}', (opp.Owner.MobilePhone == null) ? '' : opp.Owner.MobilePhone);
        message = message.replace('{day}', String.ValueOf(Id2DateTime.get(opp.Id).day()));
        message = message.replace('{hour}', String.ValueOf(Id2DateTime.get(opp.Id).hour()));
        return message;
    }

    private static Id getRecordTypeId(String name, String objName)
    {
        List<RecordType> recordType = [Select Id from RecordType where Name =:name and IsActive=true and SObjectType =:objName];
        if(recordType.size() > 0)
        {
            return recordType[0].Id;
        } 
        return null;
    }
    
    @isTest
    static void testSmartSendSMSToCustomer()
    {
        Account acc = new Account(Name='TestAccout');
        insert acc;
        Contact contact = new Contact(LastName='TestAccount', AccountId=acc.Id);
        insert contact;
        Opportunity opp = new Opportunity(Name = 'Acme', OwnerId = UserInfo.getUserId(), AccountId = acc.Id, Contact__c = contact.Id, Mobile__c = '11111111111', CloseDate = Date.today(), StageName = 'Closed Won', Location__c = 'BJ XZM', ForecastCategoryName = 'Pipeline');
        insert opp;
        Event event = new Event(WhatId = opp.Id, Subject = 'test1 sales demo test2', Appt_Status__c = 'Scheduled', ActivityDate = Date.today().addDays(1), StartDateTime = Datetime.Now().addDays(1), DurationInMinutes = 90);
        insert event;
        
        Test.startTest();
        SmartSendSMSToCustomerSchedule batch = new SmartSendSMSToCustomerSchedule();
        Id batchProcessId = Database.executeBatch(batch);
        Test.stopTest();
    }
}