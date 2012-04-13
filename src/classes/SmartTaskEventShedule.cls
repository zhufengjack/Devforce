global class SmartTaskEventShedule implements Database.Batchable<SObject>, Schedulable{
    private static final String EmailTemplateName = 'SendEmaitoCCToday';
    private static String EmailTemplateId;
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        List<EmailTemplate> templates =[select Id from EmailTemplate where Name = :EmailTemplateName];
        if(templates.size() > 0)
        {
            return Database.getQueryLocator([select Name from SchoolAddress__c where IsIgnite__c = true]);
        }
        else
        {
            return null;
        }
    }
    
    global void execute(Database.BatchableContext BC, List<SchoolAddress__c> schoolInfos)
    {
        Set<String> schoolNames = new Set<String>();
        for(SchoolAddress__c school : schoolInfos)
        {
            schoolNames.add(school.Name);
        }
        List<User> allsales=[select Id, Name, SchoolName__c, Email from User where SchoolName__c in :schoolNames and Profile.Name in ( 'EF China Sales User New','EF China Sales User New LTC') and IsActive=true];
        //traverse each school and select the CMS       
       
        
        List<EmailTemplate> templates =[select Id from EmailTemplate where Name = :EmailTemplateName];
        if(templates.size() > 0)
        {
            EmailTemplateId = templates[0].Id;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(User salesperson : allsales)
        {
            AllMyActivitiesToday controller = new AllMyActivitiesToday();
            controller.userid = salesperson.Id;
            if(controller.allmytasktoday.size() > 0 || controller.allmyeventtoday.size()>0)
            {
                //send to report to each sales user
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
                    String[] ccAdresses = new String[] {'jackzhufeng@yahoo.com','angeline.bai@meginfo.com'};
                    mail.setCcAddresses(ccAdresses);                
                    mail.setSaveAsActivity(false);
                    mail.setSenderDisplayName('Salesforce Team');
                    mail.setTargetObjectId(salesperson.Id);  
                    mail.setTemplateId(EmailTemplateId);
                    emails.add(mail);
                
            }
        }
        if(emails.size() > 0)
        {
            try
            {
                Messaging.sendEmail(emails);    
            }
            catch(Exception ex)
            {
                String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                SendEmailHelper.sendSimpleEmail(new String[] { 'jack.zhu@ef.com' }, 'Error occureed on SmartTaskEventShedule class', error);
            }
        }   
    }   
    
    global void finish(Database.BatchableContext BC)
    {
    }
    
    global void execute(SchedulableContext SC)
    {
        SmartTaskEventShedule batch = new SmartTaskEventShedule();
        Database.executeBatch(batch, 1);
    }
    
    @isTest
    static void testSmartTaskEventShedule()
    {
        Test.startTest();
        SmartTaskEventShedule batch = new SmartTaskEventShedule();
        Database.executeBatch(batch);
        Test.stopTest();    
    }
}