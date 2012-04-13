/**
 * A Schedule class used to send daily opportunity appt reports to managers
 * The managers are configed in custom settings (SchoolAndmanager__c)
 * David updated 2011-06-14
*/
global class SmartSendDailyConfirmedApptSchedule implements Schedulable  
{
    private Id chinaSmartOppRecordTypeId; // = '0124000000099sY';
    
    public SmartSendDailyConfirmedApptSchedule()
    {
        chinaSmartOppRecordTypeId = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1].Id;
    }
    
    global void execute(SchedulableContext ctx)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();//mails which be sent
        map<String, List<Opportunity>> schoolOpportuitesMap = new map<String, List<Opportunity>>();//key:school,value: current school opportunity array
        map<String, List<String>> schoolEmialsMap = new map<String, List<String>>();//key:school value:current school email which should be sent
        map<String, set<String>> schoolProfileRolesMap = new map<String, set<String>>();//key:school,value:profile + role
        map<String, List<String>> emailSchoolsMap = new map<String, List<String>>();//key:emal address,value:schools[]
        List<String> allLeadToShowSchools = RemainingApptshelper.getValidOriginalSchools();//get all lead to show schools 
        List<SchoolAndManager__c> allSchoolManagers = [select Name, ManagerProfile__c, ManagerRole__c, ManagerRole2__c, ManagerProfile2__c, ChinaTMManagerProfile__c, ChinaTMManagerRole__c, RegionalSalesManagerProfile__c, RegionalSalesManagerRole__c, RegionalTMManagerProfile__c, RegionalTMManagerRole__c, ChinaLeaderProfile__c, ChinaLeaderRole__c, GroupMail__c from SchoolAndManager__c where Name in :allLeadToShowSchools];              
        Set<String> allProfiles = new set<String>();//using for searching users
        set<String> allRoles = new set<String>();//using for searching users
        for(SchoolAndManager__c schoolManager : allSchoolManagers)
        {
            List<set<String>> currentSchoolProfileRoles = getProfileRoles(schoolManager);//[0]set<profiles>,[1]set<Roles>,[2]set<profileRoles>
            allProfiles.addAll(currentSchoolProfileRoles[0]);
            allRoles.addAll(currentSchoolProfileRoles[1]);
            schoolProfileRolesMap.put(schoolManager.Name, currentSchoolProfileRoles[2]);
            List<String> currentSchoolEmails = new List<String>();
            if(schoolManager.GroupMail__c != null)
            {
                currentSchoolEmails.add(schoolManager.GroupMail__c);
            }
            schoolEmialsMap.put(schoolManager.Name, currentSchoolEmails);     
        }               
        List<Opportunity> allOpps = [select Name, Reschedule_appt_Date_Time__c, Location__c, Mobile__c, Special_Offer__c, Check_confirmation__c from Opportunity where Location__c in :allLeadToShowSchools and Reschedule_appt_Date__c = :date.today().addDays(1) and RecordTypeId = :chinaSmartOppRecordTypeId]; 
        for(Opportunity opp : allOpps)
        {
            if(schoolOpportuitesMap.containsKey(opp.Location__c))
            {
               List<Opportunity> items = schoolOpportuitesMap.get(opp.Location__c);
               items.add(opp);
            }
            else
            {
               schoolOpportuitesMap.put(opp.Location__c, new List<Opportunity>{opp});
            }
        }
        //gets users for using lead to show schools
        List<User> managerUsers = [select Email, ProfileId, UserRole.Name, Profile.Name from User where IsActive = true and Profile.Name in :allProfiles and UserRole.Name in :allRoles];
        for(User managerUser : managerUsers)
        {
             String currentUserProfileRole = managerUser.Profile.Name + managerUser.UserRole.Name;        
             for(String schoolName : schoolProfileRolesMap.keyset())
             {
                 set<String> currentSchoolProfileRoles = schoolProfileRolesMap.get(schoolName);
                 if(currentSchoolProfileRoles.contains(currentUserProfileRole))
                 {
                    List<String> currentSchoolEmails = schoolEmialsMap.get(schoolName);
                    if(currentSchoolEmails != null)
                    {
                            currentSchoolEmails.add(managerUser.Email);
                    }
                 }                
             }   
        }
        for(String school : schoolEmialsMap.keyset())
        {
                list<String> currentEmails = schoolEmialsMap.get(school);
                for(String email : currentEmails)
                {
                    if(emailSchoolsMap.containsKey(email))
                    {
                        emailSchoolsMap.get(email).add(school);
                    }
                    else
                    {
                        emailSchoolsMap.put(email, new List<String>{school});
                    }
                }
        }
        SendAppReportBatch currentBatchJob = new SendAppReportBatch(emailSchoolsMap, schoolOpportuitesMap);
        Database.executeBatch(currentBatchJob, 1);
    }
    
    /**
     *  gets profiles with a specified schoolAndManager
     *  returns: [1]:profiles,[2]roles,[3]profileRoles
    */
    private List<set<String>> getProfileRoles(SchoolAndManager__c schoolManager)
    {
        List<set<String>> results = new List<set<String>>();
        set<String> profiles = new set<String>();
        set<String> roles = new set<String>();
        set<String> profileRoles = new set<String>();
        if(schoolManager.ManagerProfile2__c == null)
        {
            schoolManager.ManagerProfile2__c = '';
        }
        if(schoolManager.ChinaLeaderProfile__c == null)
        {
            schoolManager.ChinaLeaderProfile__c = '';
        }
        if(schoolManager.ChinaTMManagerProfile__c == null)
        {
             schoolManager.ChinaTMManagerProfile__c = '';
        }
        if(schoolManager.RegionalSalesManagerProfile__c == null)
        {
            schoolManager.RegionalSalesManagerProfile__c = '';
        }
        if(schoolManager.RegionalTMManagerProfile__c == null)
        {
             schoolManager.RegionalTMManagerProfile__c = '';
        }
        if(schoolManager.ManagerProfile__c == null)
        {
             schoolManager.ManagerProfile__c = '';
        }
        if(schoolManager.ManagerRole2__c == null)
        {
             schoolManager.ManagerRole2__c = '';
        }
        if(schoolManager.ChinaLeaderRole__c == null)
        {
             schoolManager.ChinaLeaderRole__c = '';
        }
        if(schoolManager.ChinaTMManagerRole__c == null)
        {
             schoolManager.ChinaTMManagerRole__c = '';
        }
        if(schoolManager.ManagerRole__c == null)
        {
             schoolManager.ManagerRole__c = '';
        }
        if(schoolManager.RegionalSalesManagerRole__c == null)
        {
             schoolManager.RegionalSalesManagerRole__c = '';
        }
        if(schoolManager.RegionalTMManagerRole__c == null)
        {
             schoolManager.RegionalTMManagerRole__c = '';
        }
        profiles.addAll(new set<String>{schoolManager.ManagerProfile2__c, schoolManager.ChinaLeaderProfile__c, schoolManager.ChinaTMManagerProfile__c, schoolManager.ManagerProfile__c, schoolManager.RegionalSalesManagerProfile__c, schoolManager.RegionalTMManagerProfile__c});
        roles.addAll(new set<String>{schoolManager.ManagerRole2__c, schoolManager.ChinaLeaderRole__c, schoolManager.ChinaTMManagerRole__c, schoolManager.ManagerRole__c, schoolManager.RegionalSalesManagerRole__c, schoolManager.RegionalTMManagerRole__c});
        profileRoles.addAll(new set<String>{schoolManager.ManagerProfile2__c + schoolManager.ManagerRole2__c, schoolManager.ChinaLeaderProfile__c + schoolManager.ChinaLeaderRole__c, schoolManager.ChinaTMManagerProfile__c + schoolManager.ChinaTMManagerRole__c, schoolManager.ManagerProfile__c + schoolManager.ManagerRole__c, schoolManager.RegionalSalesManagerProfile__c + schoolManager.RegionalSalesManagerRole__c, schoolManager.RegionalTMManagerProfile__c + schoolManager.RegionalTMManagerRole__c});
        results.add(profiles);
        results.add(roles);
        results.add(profileRoles);
        return results;
    }
    
    @isTest
    static void testSchedule()
    {
        Id chinaSmartOpportunityRecordTypeId = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1].Id; //'0124000000099sY';
        List<Opportunity> testOpportunites = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today(), Check_confirmation__c = true);
        testOpportunites.add(testOpportunity1);
        Opportunity testOpportunity2 = new Opportunity(name = 'acme', location__c = 'SH LJZ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today(), Check_confirmation__c = true);
        testOpportunites.add(testOpportunity2);
        Opportunity testOpportunity3 = new Opportunity(name = 'acme', location__c = 'SH BBB', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, Check_confirmation__c = true, CloseDate = date.today());
        testOpportunites.add(testOpportunity3);
        insert testOpportunites;
        SmartSendDailyConfirmedApptSchedule schedulable = new SmartSendDailyConfirmedApptSchedule();
        SchedulableContext contenx;
        schedulable.execute(contenx);
    }
}