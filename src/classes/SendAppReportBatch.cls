//  batch job for sending appt reports to managers
global class SendAppReportBatch implements Database.Batchable<sObject>, Database.Stateful
{
    global Map<String, List<String>> emailSchoolsMap = null;
    global Map<String, List<Opportunity>> schoolOpportuitesMap = null;  
    global Set<String> userEmails = new set<String>();
    private String QueryString = 'select Email from User where IsActive = true and Email in :tempEmailSet and Email != null';
    
    global SendAppReportBatch(Map<String, List<String>> emailSchoolsMapPara, Map<String, List<Opportunity>> schoolOppsMapPara)
    {
        this.emailSchoolsMap = emailSchoolsMapPara;
        this.schoolOpportuitesMap = schoolOppsMapPara;
    }
    
    global Database.QueryLocator start(Database.BatchableContext context)
    {
        Set<String> tempEmailSet = emailSchoolsMap.keyset();
        return Database.getQueryLocator(QueryString);
    }
    
    global void execute (Database.BatchableContext context, List<sObject> users)
    {
         List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();//mails which be sent
         for(sObject user : users)
         {
            User currentUser = (User)user;
            if(!userEmails.contains(currentUser.Email))
            {
	            userEmails.add(currentUser.Email);
	            Messaging.SingleEmailMessage tempEmail = getemailWithSpecifiedEmail(currentUser.Email);
	            if(tempEmail != null)
	            {
	                mails.add(tempEmail);
	            }
            }
         }
         if(!mails.isEmpty())
         {
             Messaging.sendEmail(mails); 
         }
    }
    
    global void finish(Database.BatchableContext context)
    {
        sendGroupMails();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();              
        mail.setToAddresses(new String[] {'hobart.cui@meginfo.com'});
        mail.setSubject('Send appts report Notification.');
        mail.setSenderDisplayName('Englishtown Salesforce Team');
        mail.setReplyTo('no-reply@Englishtown.com');
        mail.setPlainTextBody('Send appts report completed.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail}); 
    }
    
    private void sendGroupMails()
	{
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();//mails which be sent
        for(String currentEmail : emailSchoolsMap.keyset())
        {
            if(!userEmails.contains(currentEmail))
            {
            	Messaging.SingleEmailMessage tempMail = getemailWithSpecifiedEmail(currentEmail);
                if(tempMail != null)
                {
                    mails.add(tempMail);
                }
            }
        }
        if(!mails.isEmpty())
	    {
	        Messaging.sendEmail(mails); 
	    }
    }
    
    /**
     * gets email with a specified email address
     */
    private Messaging.SingleEmailMessage getemailWithSpecifiedEmail(String specifiedEmail)
    {
        Messaging.SingleEmailMessage result; //= new Messaging.SingleEmailMessage();
        List<String> schools = emailSchoolsMap.get(specifiedEmail);
        if(schools != null)
        {
            List<String> needSentSchools = new List<String>();
	        for(String school : schools)
	        {
	            if(schoolOpportuitesMap.containsKey(school))
	            {
	                needSentSchools.add(school);
	            }
	        }
	        if(!needSentSchools.isEmpty())
	        {
	            result = getMail(specifiedEmail, needSentSchools, schoolOpportuitesMap);
	        }
        } 
        return result;
    }
    
    //gets mails which sent to specified managers
    private Messaging.SingleEmailMessage getMail(String emailAddress, List<String> schools, Map<String, List<Opportunity>> schoolOppsMap)
    {
        Messaging.SingleEmailMessage result = new Messaging.SingleEmailMessage();        
        String htmlBody = getApptReport(schools, schoolOppsMap);       
        result.setToAddresses(new String[]{emailAddress});
        result.setCcAddresses(new String[] {'hobart.cui@meginfo.com'});
        result.setHtmlBody(htmlBody);
        result.setSubject('Appt detail today.');
        result.setSenderDisplayName('Englishtown Salesforce Team');
        result.setReplyTo('no-reply@Englishtown.com');
        return result;
    }
    
    /**
     * gets emailBody of appt report with specified school and opportunity records.
    */
    private String getApptReport(List<String> schools, Map<String, List<Opportunity>> schoolOppsMap)
    {   
        String report = 'Dear manager,<br/><br/><p>Below is your school’s appt detail today.</p><table border="1" width="420px" cellspacing="0" cellpadding="10px"><thead><tr><th>School</th><th>Opportunity Name</th><th>Reschedule Appt Date</th><th>Show Confirmed</th><th>Demo Class</th><th>Cell Phone</th></tr></thead>';
        Integer total = 0;
        for(String schoolName : schools)
        {
            List<Opportunity> opportunites = schoolOppsMap.get(schoolName);
            report += '<tr>';         
            if(opportunites != null && opportunites.size() > 0)
            {
                String firstMobile = '';
                if(opportunites[0].Mobile__c != null && opportunites[0].Mobile__c.length() == 11)
                {
                    firstMobile = opportunites[0].Mobile__c.subString(0, 5) + '***' + opportunites[0].Mobile__c.subString(8, 11);
                }
                report += '<th rowspan="' + opportunites.size() + '">' + schoolName + '</th><td>' + opportunites[0].Name + '</td><td>' + opportunites[0].Reschedule_appt_Date_Time__c.format() + '</td><td>' + ((opportunites[0].Check_confirmation__c == true)?'√':'X') +'</td><td>' + ((opportunites[0].Special_Offer__c == 'Sales demo appt')?'√':'X') +'</td><td>' + firstMobile +'</td></tr>';
                total += 1;
                for(Integer j = 1; j < opportunites.size(); j++)
                {
                    total++;
                    String currentMobile = '';
                    if(opportunites[j].Mobile__c != null && opportunites[j].Mobile__c.length() == 11)
                    { 
                        currentMobile = opportunites[j].Mobile__c.subString(0, 5) + '***' + opportunites[j].Mobile__c.subString(8, 11);
                    }
                    report += '<tr><td>' + opportunites[j].Name + '</td><td>' + opportunites[j].Reschedule_appt_Date_Time__c.format() + '</td><td>' + ((opportunites[j].Check_confirmation__c == true)?'√':'X') +'</td><td>' + ((opportunites[j].Special_Offer__c == 'Sales demo appt')?'√':'X') +'</td><td>' + currentMobile +'</td></tr>';
                }   
            } 
            else
            {
                report += '<th>' + schoolName + '</th><td colspan="5" align="center">0</td></tr>';
            }
        }    
        report += '<tr><th>Total</th><td colspan="5" align="center">' + String.valueof(total) +'</td></tr></table><p/>Thanks,<br/>Salesforce Team';
        return report;
    }
     
    @isTest
    static void testBatchJob()
    {
        Id chinaSmartOpportunityRecordTypeId = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1].Id;
        List<Opportunity> testOpportunites = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
        testOpportunites.add(testOpportunity1);        
        insert testOpportunites;
        User user = [select Email from User where IsActive = true limit 1];
        Map<String, List<String>> emailSchoolsMap = new Map<String, List<String>>();
        emailSchoolsMap.put(user.Email, new List<String>{'SH PSQ'});
        Map<String, List<Opportunity>> schoolOpportuitesMap = new Map<String, List<Opportunity>>();
        schoolOpportuitesMap.put('SH PSQ', testOpportunites);
        Test.startTest();
        SendAppReportBatch batchJob = new SendAppReportBatch(emailSchoolsMap, schoolOpportuitesMap);
        batchJob.queryString = batchJob.queryString + ' limit 1';
        Database.executeBatch(batchJob, 1);
        Test.stopTest();
    }
}