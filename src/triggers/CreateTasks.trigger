/**
 *create tasks when a collection history record insert.
*/
trigger CreateTasks on Collection_Process__c (after insert) 
{
    final Id BrazilCountryManagerProfileId = '00e30000000hnba';
    final Id MexicoCountryManagerProfileId = '00e40000000i262';
    final Id EuropeAndAmericasManagerProfileId = '00e40000000i20J';
    
    List<Id> allAffectedTypeIds = new List<Id>();
    final Id brazilActualTypeId = '0124000000098gR';
    final Id mexicoActualTypeId = '0124000000099IB';
    final Id usActualTypeId = '012400000009A3C';
    final Id italyActualTypeId = '012400000009BQb';
    final Id franceActualTypeId = '0124000000099Xa';
    final Id germanyActualTypeId = '012400000009Axj';
    allAffectedTypeIds.add(brazilActualTypeId);
    allAffectedTypeIds.add(mexicoActualTypeId);
    allAffectedTypeIds.add(usActualTypeId);
    allAffectedTypeIds.add(italyActualTypeId);
    allAffectedTypeIds.add(franceActualTypeId);
    allAffectedTypeIds.add(germanyActualTypeId);
    
    final String phoneCallRecordTypeId = '0123000000095jN';
    final String smsRecordTypeId = '0123000000096TV';
    final String emailRecordTypeId = '0123000000096Sw';
    Id currentUserProfileId = UserInfo.getProfileId();
    Id brazilCollectionUserId = '00590000000ZdGh'; 
    List<Task> tasks = new List<Task>();
    List<Collection_Process__c> allHistories = [select Id, CreatedById, CreatedDate, PaymentRecord__r.Collection_staff__c, PaymentRecord__r.Actual__r.RecordTypeId from Collection_Process__c where Id in :trigger.new and PaymentRecord__r.Actual__r.RecordTypeId in :allAffectedTypeIds];
    List<Collection_Process__c> mexicoHistories = new List<Collection_Process__c>();
    List<Collection_Process__c> americaAndEuropeHistories = new List<Collection_Process__c>();
    for(Collection_Process__c history : allHistories)
    {
        if(history.PaymentRecord__r.Actual__r.RecordTypeId == mexicoActualTypeId)//brazilActualTypeId
        {
            mexicoHistories.add(history);
        }
        else
        {
            americaAndEuropeHistories.add(history);
        }
    }
    if(!mexicoHistories.isEmpty())
    {
        tasks.addAll(getTasksForSpecifiedRegion(mexicoHistories, MexicoCountryManagerProfileId));
    }
    if(!americaAndEuropeHistories.isEmpty())
    {
        tasks.addAll(getTasksForSpecifiedRegion(americaAndEuropeHistories, EuropeAndAmericasManagerProfileId));
    }
    insert tasks;
    
    private List<Task> getTasksForSpecifiedRegion(List<Collection_Process__c> histories, Id profileId)
    {
        List<Task> results = new List<Task>();
        String soql = 'select Id, First_Date_Of_Email_Task__c, First_Date_Of_Phone_Task__c, First_Date_Of_SMS_Task__c, Second_Date_Of_Email_Task__c, Second_Date_Of_Phone_Task__c, Second_Date_Of_SMS_Task__c, Third_Date_Of_Email_Task__c, Third_Date_Of_Phone_Task__c, Third_Date_Of_SMS_Task__c, Fourth_Date_Of_Email_Task__c, Fourth_Date_Of_Phone_Task__c, Fourth_Date_Of_SMS_Task__c, Fifth_Date_Of_Email_Task__c, Fifth_Date_Of_Phone_Task__c, Fifth_Date_Of_SMS_Task__c, Region__c from CollectionScheduleConfig__c';
        if(profileId == MexicoCountryManagerProfileId)
        {
            soql += ' where Region__c = \'MexicoCountry\' limit 1';
        }
        else if(profileId == BrazilCountryManagerProfileId || profileId == EuropeAndAmericasManagerProfileId)
        {
            soql += ' where Region__c = \'BrazilOrEuropeOrAmerica\' limit 1';
        }
        //for Test
        else
        {
            soql += ' where Region__c = \'AdminForTest\' limit 1';
        }
        List<CollectionScheduleConfig__c> configs = database.query(soql);
        if(!configs.isEmpty())
        {
            for(Collection_Process__c history : histories)
            {
                if(configs[0].First_Date_Of_Phone_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call (1)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].First_Date_Of_Phone_Task__c.intValue())));
                }
                if(configs[0].Second_Date_Of_Phone_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call (2)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Second_Date_Of_Phone_Task__c.intValue())));
                }
                if(configs[0].Third_Date_Of_Phone_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call (3)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Third_Date_Of_Phone_Task__c.intValue())));
                }
                if(configs[0].Fourth_Date_Of_Phone_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call (4)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fourth_Date_Of_Phone_Task__c.intValue())));
                }
                if(configs[0].Fifth_Date_Of_Phone_Task__c != null)
                {
                  results.add(new Task(RecordTypeId = phoneCallRecordTypeId, Subject = 'Phone call (5)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fifth_Date_Of_Phone_Task__c.intValue())));
                }
                if(configs[0].First_Date_Of_SMS_Task__c != null)
                {
                  results.add(new Task(RecordTypeId = smsRecordTypeId, Subject = 'Send SMS (1)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].First_Date_Of_SMS_Task__c.intValue())));
                }
                if(configs[0].Second_Date_Of_SMS_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = smsRecordTypeId, Subject = 'Send SMS (2)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Second_Date_Of_SMS_Task__c.intValue())));
                }
                if(configs[0].Third_Date_Of_SMS_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = smsRecordTypeId, Subject = 'Send SMS (3)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Third_Date_Of_SMS_Task__c.intValue())));
                }
                if(configs[0].Fourth_Date_Of_SMS_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = smsRecordTypeId, Subject = 'Send SMS (4)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fourth_Date_Of_SMS_Task__c.intValue())));
                }
                if(configs[0].Fifth_Date_Of_SMS_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = smsRecordTypeId, Subject = 'Send SMS (5)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fifth_Date_Of_SMS_Task__c.intValue())));
                }
                if(configs[0].First_Date_Of_Email_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = emailRecordTypeId, Subject = 'Send Email (1)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].First_Date_Of_Email_Task__c.intValue())));                
                }
                if(configs[0].Second_Date_Of_Email_Task__c != null)
                {
                  results.add(new Task(RecordTypeId = emailRecordTypeId, Subject = 'Send Email (2)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Second_Date_Of_Email_Task__c.intValue())));
                }
                if(configs[0].Third_Date_Of_Email_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = emailRecordTypeId, Subject = 'Send Email (3)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Third_Date_Of_Email_Task__c.intValue())));
                }
                if(configs[0].Fourth_Date_Of_Email_Task__c != null)
                {
                  results.add(new Task(RecordTypeId = emailRecordTypeId, Subject = 'Send Email (4)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fourth_Date_Of_Email_Task__c.intValue())));
                }
                if(configs[0].Fifth_Date_Of_Email_Task__c != null)
                {
                    results.add(new Task(RecordTypeId = emailRecordTypeId, Subject = 'Send Email (5)', OwnerId = brazilCollectionUserId, Status = 'Not Started', Priority = 'Normal', WhatId = history.Id, ActivityDate = history.CreatedDate.date().addDays(configs[0].Fifth_Date_Of_Email_Task__c.intValue())));
                }
            }
        }
        return results;
    }
}