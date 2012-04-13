/**
 * sends next week’s # of initial appts to managers
*/
global class SmartSendWeeklyApptReportsSchedule implements Schedulable 
{
    private final Id EFChinaTeleManagerProfileId = '00e30000000hjwK';
    private final Id EFChinaRegionalDirectorProfileId = '00eO0000000LrQV';
    private final Id EFChinaSalesManagerNewId = '00e40000000j2k8';
    private final String EFChinaTelemarketingManagerRoleName  = 'China Telemarketing Manager';
    private final String EFChinaCenterSalesManagerRoleName  = 'China SH Sales Manager';
    private boolean isTesting = false;
    
    global void execute(SchedulableContext ctx)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();//mails which be sent
        List<User> defaultManagerUsers = new List<User>();//default user ,for example:users of role named center sales manager
        List<Id> SHManagerUserProfieIds = new List<Id>{EFChinaTeleManagerProfileId, EFChinaRegionalDirectorProfileId, EFChinaSalesManagerNewId};//static profile ids of the managers for lead to show schools
        
        map<String, List<String>> roleMap = new map<String, List<String>>();// key:role name ,value:List schools      
        map<String, List<String>> roleMap2 = new map<String, List<String>>();// key:role name ,value:List schools
        
         List<String> allLeadToShowSchools = RemainingApptshelper.getValidOriginalSchools();//get all lead to show schools
        set<String> allLeadToShowSchoolRoleNames = new set<String>{EFChinaTelemarketingManagerRoleName};//all role name of lead to show schools
        List<SchoolAndManager__c> allSchoolManagers = [select Name, ManagerRole__c, ManagerRole2__c from SchoolAndManager__c where Name in :allLeadToShowSchools]; 
              
        for(SchoolAndManager__c schoolManager : allSchoolManagers)
        {
            allLeadToShowSchoolRoleNames.add(schoolManager.ManagerRole__c);
            allLeadToShowSchoolRoleNames.add(schoolManager.ManagerRole2__c);
            if(roleMap.containsKey(schoolManager.ManagerRole__c))
            {
                List<String> schools = roleMap.get(schoolManager.ManagerRole__c);
                schools.add(schoolManager.Name);
            }
            else
            {
                roleMap.put(schoolManager.ManagerRole__c, new List<String>{schoolManager.Name});
            }
            if(roleMap2.containsKey(schoolManager.ManagerRole2__c))
            {
                List<String> schools = roleMap2.get(schoolManager.ManagerRole2__c);
                schools.add(schoolManager.Name);
            }
            else
            {
                roleMap2.put(schoolManager.ManagerRole2__c, new List<String>{schoolManager.Name});
            }
            
        }
        List<RemainingApptsHelper.ApptDetailInfo2> details = new List<RemainingApptsHelper.ApptDetailInfo2>();
        if(isTesting)
        {        
        	details = RemainingApptsHelper.getApptDetailsBySchoolsForTest(allLeadToShowSchools, 7);//get the appt detail of 7 days later
        }
        else
        {
        	details = RemainingApptsHelper.getApptDetailsBySchools(allLeadToShowSchools, 7);//get the appt detail of 7 days later
        }
        map<String, List<RemainingApptsHelper.ApptDetailInfo2>> schoolApptMap = RemainingApptsHelper.getSchoolApptDetailsMap(details);//gets schoolMap,key:school, value:List<ApptDetail>
        //makes all schools have records of appt
        for(String leadToShowSchool : allLeadToShowSchools)
        {
            if(!schoolApptMap.containsKey(leadToShowSchool))
            {
                List<RemainingApptsHelper.ApptDetailInfo2> currentList = RemainingApptsHelper.CompleteList(new List<RemainingApptsHelper.ApptDetailInfo2>{new RemainingApptsHelper.ApptDetailInfo2(leadToShowSchool, Date.today(), 0, 0)}, 7);
                schoolApptMap.put(leadToShowSchool, currentList);
            }
            else
            {
                List<RemainingApptsHelper.ApptDetailInfo2> currentList = schoolApptMap.get(leadToShowSchool);
                currentList = RemainingApptsHelper.CompleteList(currentList, 7);
            }
        }
         //gets users for using lead to show schools
        List<User> allSHManagerUser = [select Email, ProfileId, UserRole.Name from User where IsActive = true and (ProfileId in :SHManagerUserProfieIds or UserRole.Name in :allLeadToShowSchoolRoleNames)];
        for(User sHManagerUser : allSHManagerUser)
        {
            if((sHManagerUser.ProfileId == EFChinaTeleManagerProfileId && sHManagerUser.UserRole.Name == EFChinaTelemarketingManagerRoleName) || ((sHManagerUser.ProfileId == EFChinaRegionalDirectorProfileId && sHManagerUser.UserRole.Name == EFChinaCenterSalesManagerRoleName)))
            {
                defaultManagerUsers.add(sHManagerUser);
            }
            else if(roleMap2.containsKey(sHManagerUser.UserRole.Name) && sHManagerUser.ProfileId == EFChinaSalesManagerNewId)
            {
                List<String> schools = roleMap2.get(sHManagerUser.UserRole.Name);
                if(schools != null)
                {
	                for(String school : schools)
	                {
	                	List<RemainingApptsHelper.ApptDetailInfo2> item = schoolApptMap.get(school);
	                	if(item != null)
	                	{
	                		List<List<RemainingApptsHelper.ApptDetailInfo2>> items = new List<List<RemainingApptsHelper.ApptDetailInfo2>>{item};
	                    	mails.addAll(getMails(new List<User>{sHManagerUser}, items));

	                	}
	                }
            	} 
            }
            else if(roleMap.containsKey(sHManagerUser.UserRole.Name) && sHManagerUser.ProfileId == EFChinaRegionalDirectorProfileId)
            {
                List<String> schools = roleMap.get(sHManagerUser.UserRole.Name);
                if(schools != null)
                {
	                for(String school : schools)
	                {
	                	List<RemainingApptsHelper.ApptDetailInfo2> item = schoolApptMap.get(school);
	                	if(item != null)
	                	{
	                		List<List<RemainingApptsHelper.ApptDetailInfo2>> items = new List<List<RemainingApptsHelper.ApptDetailInfo2>>{item};
	                    	mails.addAll(getMails(new List<User>{sHManagerUser}, items));

	                	}
	                }
            	}
            }          
        }
        if(!defaultManagerUsers.isEmpty())
        {
            mails.addAll(getMails(defaultManagerUsers, schoolApptMap.values()));    
        }
        if(!mails.isEmpty())
        {
             Messaging.sendEmail(mails);
        }
    }
    
    //gets mails which sent to specified managers
    private List<Messaging.SingleEmailMessage> getMails(List<User> users, List<List<RemainingApptsHelper.ApptDetailInfo2>> itemsList)
    {
        List<Messaging.SingleEmailMessage> results = new List<Messaging.SingleEmailMessage>();
        String htmlBody = getApptReport(itemsList);
        for(User user : users)
        {
            Messaging.SingleEmailMessage result = new Messaging.SingleEmailMessage();
            result.setToAddresses(new String[]{user.Email});
            result.setCcAddresses(new String[] {'david.lee@meginfo.com','Cherry.Jing@ef.com'});
            result.setHtmlBody(htmlBody);
            result.setSubject('# of initial appt this week.');
            result.setSenderDisplayName('Englishtown Salesforce Team');
            result.setReplyTo('no-reply@Englishtown.com');
            results.add(result);
        }
        return results;
    }
    
    //gets the report of the emailBody with specified appt records.
    private String getApptReport(List<List<RemainingApptsHelper.ApptDetailInfo2>> itemsList)
    {
        String report = 'Dear manager,<br/><br/><p>Below is your school’s initial appt number this week.</p>' + 
                        '<table border="1" width="640px" cellspacing="0" cellpadding="2">' + 
                            '<thead>' + 
                                '<tr>' + 
                                    '<th>School</th>' + 
                                    '<th>Mon(date)</th>' + 
                                    '<th>Tue</th>' + 
                                    '<th>Wed</th>' + 
                                    '<th>Thu</th>' +
                                    '<th>Fri</th>' +
                                    '<th>Sat</th>' +
                                    '<th>Sun</th>' +
                                '</tr>' +
                            '</thead>';
        for(List<RemainingApptsHelper.ApptDetailInfo2>  items : itemsList)
        {
            report += '<tr><td>' + items[0].SchoolName + '</td>';
            for(Integer i = 1; i <= 7; i++)
            {
                report += '<td align="right">' + items[i].UsedApptCount + '</td>';
            }
            report += '</tr>';
        }
        report += '</table><p/>Thanks,<br/>Salesforce Team';
        return report;
    }
    
    @isTest
    static void testSchedule()
    {
    	Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
    	List<Opportunity> testOpportunites = new List<Opportunity>();
    	Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
    	testOpportunites.add(testOpportunity1);
    	Opportunity testOpportunity2 = new Opportunity(name = 'acme', location__c = 'SH LJZ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
    	testOpportunites.add(testOpportunity2);
    	Opportunity testOpportunity3 = new Opportunity(name = 'acme', location__c = 'SH BBB', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, Check_confirmation__c = true, CloseDate = date.today());
    	testOpportunites.add(testOpportunity3);
    	insert testOpportunites;
    	List<Appt_Max_target__c> testTargets = new List<Appt_Max_target__c>();
    	Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
    	testTargets.add(testTarget1);
    	Appt_Max_target__c testTarget2 = new Appt_Max_target__c(Max_target__c = 1, School__c = 'SH LJZ', Date__c = date.today());
    	testTargets.add(testTarget2);
    	Appt_Max_target__c testTarget3 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH BBB', Date__c = date.today());
    	testTargets.add(testTarget3);
    	insert testTargets;
    	SmartSendWeeklyApptReportsSchedule schedulable = new SmartSendWeeklyApptReportsSchedule();
    	schedulable.isTesting = true;
        SchedulableContext contenx;
        schedulable.execute(contenx);
    }
}