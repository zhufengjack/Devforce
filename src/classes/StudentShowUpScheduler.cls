/*
 * A scheduled job, checks in a daily basis:
 * 1. if appt_date of opportunity passed 24 hrs, sends the owner an email
 * 2. if appt_date of opportunity passed 48 hrs, updates stage 
 */
global class StudentShowUpScheduler implements Schedulable
{
    global void execute(SchedulableContext sc)
    {
        doShowUp();
    }
    
    public void doShowUp()
    {
        DateTime oneDayAgo = DateTime.now().addHours(-24);
        DateTime twoDaysAgo = DateTime.now().addHours(-48);
        DateTime launchDate = DateTime.newInstance(2010,4,16,0,0,0);
        List<Opportunity> needSendingEmail = [select Id, Initial_Appt_Date__c, OwnerId from Opportunity where StageName='Set Appt' and RecordType.Name='China Smart Record Type' and Initial_Appt_Date__c<:oneDayAgo and Initial_Appt_Date__c>:twoDaysAgo];
        List<Opportunity> needUpdatingStage = [select Id, Initial_Appt_Date__c, OwnerId from Opportunity where StageName='Set Appt' and RecordType.Name='China Smart Record Type' and Initial_Appt_Date__c<:twoDaysAgo and Initial_Appt_Date__c>:launchDate];
        if(needSendingEmail.size() > 0)
        {
            sendEmails(needSendingEmail);
        }
        if(needUpdatingStage.size() > 0)
        {
            updateStages(needUpdatingStage);
        }
    }
    
    private static void sendEmails(List<Opportunity> opps)
    {
        Set<Id> userIds = new Set<Id>();
        for(Opportunity opp : opps)
        {
            userIds.add(opp.OwnerId);
        }
        //converts users to contacts to be the recipients, as users cannot be used along with WhatId when sending emails
        Map<Id, Id> user2Contact = createTempContacts(userIds);  //key=>userId, value=>contactId
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        for(Opportunity opp : opps)
        {
            if(user2Contact.containsKey(opp.OwnerId))
            {
                Id targetContact = user2Contact.get(opp.OwnerId);
                Messaging.SingleEmailMessage mail = getEmail(targetContact, opp.Id);
                mails.add(mail);
                if(mails.size() > 99)
                {
                    //sends every 100 opportunities
                    try
                    {
                        Messaging.sendEmail(mails);
                    }
                    catch(Exception ex){}
                    mails.clear();
                }
            }
        }
        if(mails.size() > 0)
        {
            //send the remaining.
            try
            {
                Messaging.sendEmail(mails);
            }
            catch(Exception ex){}
        }
        removeTempContacts(user2Contact.values());
    }

    private static void updateStages(List<Opportunity> opps)
    {
        for(Opportunity opp : opps)
        {
            opp.StageName = 'Appt No Show - Call Later';
        }
        update opps;
    }
    
    //initializes a new Email with the specified target and whatId
    private static Messaging.SingleEmailMessage getEmail(Id targetObjectId, Id whatId)
    {
        String templateId = '00X90000000cbH6'; //sandbox template: 00XT0000000n7jT, production template: 00X90000000cbH6
        String subject = 'Appt past 24 hrs - ' + Date.today().format();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(templateId);
        mail.setSaveAsActivity(false);
        mail.setTargetObjectId(targetObjectId);
        mail.setWhatId(whatId);
        mail.setSenderDisplayName('Salesforce Administrator');
        mail.setReplyTo('noreply@ef.com');
        return mail;
    }
    
    //creates some temporary contacts with the specified user email and name
    private static Map<Id, Id> createTempContacts(Set<Id> userIds)
    {
        List<Contact> contacts = new List<Contact>();
        List<User> users = [select Id, Username, Email from User where Id in :userIds];
        for(User theUser : users)
        {
            contacts.add(new Contact(LastName=theUser.Username, Email=theUser.Email));
        }
        insert contacts;
        Map<Id, Id> result = new Map<Id, Id>(); //key=>UserId, value: ContactId
        for(User theUser : users)
        {
            Contact relatedContact = null;
            for(Contact theContact : contacts)
            {
                if(theContact.LastName == theUser.Username)
                {
                    relatedContact = theContact;
                    break;
                }
            }
            if(relatedContact != null)
            {
                result.put(theUser.Id, relatedContact.Id);
            }
        }
        return result;
    }
    
    //delete the contacts with the specified id.
    private static void removeTempContacts(List<Id> contactIds)
    {
        List<Contact> contacts = new List<Contact>();
        for(Id contactId : contactIds)
        {
            contacts.add(new Contact(Id=contactId));
        }
        delete contacts;
    }
    
    @isTest
    static void testStudentShowUpScheduler()
    {
        Opportunity testEmailOpp = new Opportunity(Name='acme', StageName='Set Appt', CloseDate=Date.today(), Initial_Appt_Date__c=DateTime.now().addHours(-25));
        insert testEmailOpp;
        Opportunity testFieldOpp = new Opportunity(Name='acme', StageName='Set Appt', CloseDate=Date.today(), Initial_Appt_Date__c=DateTime.now().addHours(-49));
        insert testFieldOpp;
        
        StudentShowUpScheduler scheduler = new StudentShowUpScheduler();
        scheduler.doShowUp();
    }
}