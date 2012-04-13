/*
 * A schedule job send not updated opportunity report to CSM 
 */
global class SmartSendOppReportToCsmSchedule implements Database.Batchable<SObject>, Schedulable
{
    private static final String EmailTemplateName = 'SendReportToCSM';
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
        //traverse each school and select the CMS       
        Map<String, Set<Id>> schoolName2Ids = new Map<String, Set<Id>>();  //key: school name, value: user id list
        for(User user : [select Id, Name, SchoolName__c, Email from User where SchoolName__c in :schoolNames and Profile.Name = 'EF China Sales Manager New' and IsActive=true])
        {
            if(!schoolName2Ids.containsKey(user.SchoolName__c))
            {
                schoolName2Ids.put(user.SchoolName__c, new Set<Id>{user.Id});
            }
            else
            {
                Set<Id> usersId = schoolName2Ids.get(user.SchoolName__c);
                usersId.add(user.Id);
            }
        }
        List<EmailTemplate> templates =[select Id from EmailTemplate where Name = :EmailTemplateName];
        if(templates.size() > 0)
        {
            EmailTemplateId = templates[0].Id;
        }
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for(SchoolAddress__c school : schoolInfos)
        {
            SmartOppsWithoutActivitiesController controller = new SmartOppsWithoutActivitiesController();
            controller.SchoolName = school.Name;
            if(controller.OpportunitiesWithoutActivities.size() > 0 || controller.FirstShowUpOpps.size() > 0 || controller.Events.size() > 0 || controller.Tasks.size() > 0)
            {
                //send to report to each cmsUsers
                for(Id userId : schoolName2Ids.get(school.Name))
                {   
                	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();   
                    mail.setSaveAsActivity(false);
                    mail.setSenderDisplayName('Salesforce Team');
                    mail.setTargetObjectId(userId);  
                    mail.setTemplateId(EmailTemplateId);
                    emails.add(mail);
                } 
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
            	SendEmailHelper.sendSimpleEmail(new String[] { 'peak.lee@meginfo.com', 'jair.zheng@meginfo.com' }, 'Error occureed on SmartSendOppReportToCsmSchedule class', error);
            }
        }   
    }   
    
    global void finish(Database.BatchableContext BC)
    {
    }
    
    global void execute(SchedulableContext SC)
    {
        SmartSendOppReportToCsmSchedule batch = new SmartSendOppReportToCsmSchedule();
        Database.executeBatch(batch, 1);
    }
    
    @isTest
    static void testSmartSendOppReportToCSM()
    {
        Test.startTest();
        SmartSendOppReportToCsmSchedule batch = new SmartSendOppReportToCsmSchedule();
        Database.executeBatch(batch);
        Test.stopTest();    
    }
}