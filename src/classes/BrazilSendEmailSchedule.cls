/**
 * sets up schedule to send emails at due date 
*/
global class BrazilSendEmailSchedule implements Schedulable
{
    final Id emailRecordTypeId = '0123000000096Sw';
    final Id firstEmailTemplateId = '00X90000000dph1';
    final Id secondEmailTemplateId = '00X90000000dph6';
    final Id thirdEmailTemplateId = '00X90000000dphB';
    final Id fourthEmailTemplateId = '00X90000000dphG';
    final Id fifthEmailTemplateId = '00X90000000dphL';
    map<Id, List<Task>> collectionProcessMap = new map<Id, List<Task>>();
    String collectionProcessObjPrefix = 'a0V';
    global void execute(SchedulableContext contentx)
    {       
        List<Task> allActiveEmailTasks = [select Id, Subject, OwnerId, Owner.Email, Status, WhatId, ActivityDate from Task where RecordTypeId = :emailRecordTypeId and ActivityDate = :Date.today() and Status != 'completed'];
        if(!allActiveEmailTasks.isEmpty())
        {
            for(Task currentTask : allActiveEmailTasks)
            {
                String currentWateId = currentTask.WhatId;
                if(currentWateId != null && currentWateId.startsWith(collectionProcessObjPrefix))
                {
                    if(collectionProcessMap.containsKey(currentTask.WhatId))
                    {
                        List<Task> items = collectionProcessMap.get(currentTask.WhatId);
                        items.add(currentTask);
                    }
                    else
                    {
                        collectionProcessMap.put(currentTask.WhatId, new List<Task>{currentTask});
                    }                   
                }
            }
            if(!collectionProcessMap.keyset().isEmpty())
            {
                    List<EmailTemplate> brazilTemplates = [select Id, Subject, Body from EmailTemplate where Id in :new String[]{firstEmailTemplateId, secondEmailTemplateId, thirdEmailTemplateId, fourthEmailTemplateId, fifthEmailTemplateId}];
                    Map<Id, EmailTemplate> templateMap = new Map<Id, EmailTemplate>();
                    for(EmailTemplate template : brazilTemplates)
                    {
                        templateMap.put(template.Id, template);
                    }
                List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
                List<Collection_Process__c> collectionHostories = [select Id, PaymentRecord__r.Installment__c, PaymentRecord__r.Due_Date__c, PaymentRecord__r.Actual__r.Official_Name__c from Collection_Process__c where Id in :collectionProcessMap.keyset()];
                List<Task> updatedTasks = new List<Task>();
                for(Collection_Process__c collectionHostory : collectionHostories)
                {
                        List<Task> currentTasks = collectionProcessMap.get(collectionHostory.Id);
                        for(Task currentTask : currentTasks)
                        {
                            EmailTemplate currentTemplate;
                            String currrentSubject = '';
                        String currentBody = '';
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        if(currentTask.Subject != null && currentTask.Subject.contains('(1)'))
                        {
                            currentTemplate = templateMap.get(firstEmailTemplateId);                            
                        }
                        else if(currentTask.Subject != null && currentTask.Subject.contains('(2)'))
                        {
                            currentTemplate = templateMap.get(secondEmailTemplateId);   
                        }
                        else if(currentTask.Subject != null && currentTask.Subject.contains('(3)'))
                        {
                            currentTemplate = templateMap.get(thirdEmailTemplateId);    
                        }
                        else if(currentTask.Subject != null && currentTask.Subject.contains('(4)'))
                        {
                            currentTemplate = templateMap.get(fourthEmailTemplateId);   
                        }
                        else if(currentTask.Subject != null && currentTask.Subject.contains('(5)'))
                        {
                            currentTemplate = templateMap.get(fifthEmailTemplateId);    
                        }
                        String officialName = (collectionHostory.PaymentRecord__r.Actual__r.Official_Name__c != null)?(collectionHostory.PaymentRecord__r.Actual__r.Official_Name__c):' ';
                        String dueDate = (collectionHostory.PaymentRecord__r.Due_Date__c != null)?(collectionHostory.PaymentRecord__r.Due_Date__c.format()):' ';
                        String installment = (collectionHostory.PaymentRecord__r.Installment__c != null)?(collectionHostory.PaymentRecord__r.Installment__c):' ';
                        if(currentTemplate != null)
                        {
                            currentBody = currentTemplate.Body.replace('{!Actual__c.Official_Name__c}', officialName).replace('{!Payment_Record__c.Due_Date__c}', dueDate).replace('{!Payment_Record__c.Installment__c}', installment);
                            currrentSubject = currentTemplate.Subject;
                        }
                        mail.setPlainTextBody(currentBody);
                        mail.setSubject(currrentSubject);
                        mail.setToAddresses(new String[]{'david.lee@meginfo.com', currentTask.Owner.Email});
                        mail.setSenderDisplayName('Englishtown Salesforce Team');
                        mail.setReplyTo('no-reply@Englishtown.com');
                        mails.add(mail);
                        currentTask.Status = 'completed';
                        updatedTasks.add(currentTask);
                        }
                }
                try
                {
                    Messaging.sendEmail(mails);
                    update updatedTasks;
                }
                catch(exception ex)
                {}
            }       
        }
    }
    @istest
    static void testSchedule()
    {
            String BrazilTypeId = '0124000000099WD';
            Id brazilActualTypeId = '0124000000098gR';
            Id emailTaskRecordTypeId = '0123000000096Sw';
            Date currentDay = Date.today().addDays(-5);
            Opportunity opp = [select Id from Opportunity limit 1];
            Account company = new Account(Name = 'Virtual company');
        insert company;
        Actual__c actual = new Actual__c(account__c = company.Id, Payment_Schedule__c ='Installments-Automatic', RecordTypeId = brazilActualTypeId);
        insert actual;
        Payment_Record__c payment = new Payment_Record__c(Actual__c = actual.Id, Amount_Due__c = 1000, Collection_staff__c = UserInfo.getUserId(), Due_Date__c = currentDay, Status__c = 'Due', RecordTypeId = BrazilTypeId);
        insert payment;
            payment.Failed_date__c = currentDay;
            update payment;
            Collection_Process__c collectionProcess = new Collection_Process__c(Collection_status__c = 'In collection', PaymentRecord__c = payment.Id);
            insert collectionProcess;
        Task currentTask = new Task(Subject = '(1) Email', RecordTypeId = emailTaskRecordTypeId, WhatId = collectionprocess.Id, ActivityDate = Date.today());
        Task currentTask2 = new Task(Subject = '(1) Email', RecordTypeId = emailTaskRecordTypeId, WhatId = actual.Id, ActivityDate = Date.today());
        Task currentTask3 = new Task(Subject = '(1) Email', RecordTypeId = emailTaskRecordTypeId, WhatId = opp.Id, ActivityDate = Date.today());
        insert new List<Task>{currentTask, currentTask2, currentTask3};
        Event event1 = new Event(Subject = '(1) Email', WhatId = collectionprocess.Id, ActivityDate = Date.today(),DurationInMinutes = 1, ActivityDateTime = datetime.now());
        Event event2 = new Event(Subject = '(1) Email', WhatId = actual.Id, ActivityDate = Date.today(), DurationInMinutes = 1, ActivityDateTime = datetime.now());
        Event event3 = new Event(Subject = '(1) Email', WhatId = opp.Id, ActivityDate = Date.today(), DurationInMinutes = 1, ActivityDateTime = datetime.now());
        insert new List<Event>{event1, event2, event3};
            BrazilSendEmailSchedule schedulable = new BrazilSendEmailSchedule();
        try
        {
            SchedulableContext ctx;
            schedulable.execute(ctx);
        }
        catch(Exception ex)
        {
        }
    }
}