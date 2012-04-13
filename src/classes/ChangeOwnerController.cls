/*
 * controller of page ChangeOwner
 */
public class ChangeOwnerController
{
    //private Id chinaSHTMUserProfileId = '00eO0000000LrQu';
    private Id chinaSHTMUserProfileId = '00e90000000UVtx';
    //private Id chinaSHTMManagerProfileId = '00eO0000000Lrff';
    private Id chinaSHTMManagerProfileId = '00e90000000UeEp';
    private Id chinaSmartBookingOfficerProfileId = '00e40000001BNBS';
    private Id EFChinaOperatorProfileid = '00e30000000hjwF';
    private Id EFChinaOperatorLeadProfileid = '00e30000000hq1u';

    public changeOwnerController()
    {
        String accId=ApexPages.currentPage().getParameters().get('id');
        List<Account> accounts = [select Id, Name,OwnerId,Booking_Officer_Name__c from Account where Id=:accId limit 1];
        if(accounts.size() > 0)
        {
            TargetAccount = accounts[0];
            if(TargetAccount.Booking_Officer_Name__c==null&&UserInfo.getProfileId()==chinaSmartBookingOfficerProfileId)
            {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please back and fill in Booking Officer name')); 
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose an account')); 
            IsDenied = true;
        }
    }
    
    public Account TargetAccount {get; set; }
    public String SelectedUserId { get; set; }
    public String PostAction{get;set;}
    public Boolean IsDenied{get;set;}
    public List<SelectOption> UserList { get; set; }
    
    private String OldSchoolName
    {
        get
        {
            return [select SchoolName__c from User where Id =:TargetAccount.OwnerId].SchoolName__c; 
        } 
    }
    private String CurrentSchoolName
    {
        get
        {
            return [select SchoolName__c from User where Id =:UserInfo.getUserId()].SchoolName__c;
        }
    }
    
    private String CurrentUserRoleName
    {
        get
        {
            return [Select Name From UserRole Where Id = : UserInfo.getUserRoleId() Limit 1].Name;
        }
    }
    private String OldUserRoleName
    {
        get
        {
            return [select UserRole.Name from User where Id =:TargetAccount.OwnerId].UserRole.Name;
        }
    }
    
    private String CurrentProfileName
    {
         get
         {
            return [select  Name from Profile where Id =:UserInfo.getProfileId()].Name; 
         }
    }
    private String OldProfileName
    {
        get
        {
            return [select Profile.Name from User where Id =:TargetAccount.OwnerId].Profile.Name;
        }
    }
    
    public PageReference init()
    {
        UserList = buildUserList();
        return null;
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + TargetAccount.Id);
    }
    
    public PageReference save()
    {
        if(SelectedUserId != null && SelectedUserId != '')
        {      
            TargetAccount.OwnerId = SelectedUserId;
            try
            {
                update TargetAccount;
                List<Opportunity> opps = [select Id, OwnerId , Owner.ProfileId from Opportunity where AccountId=:TargetAccount.Id and StageName!='Closed Won' AND StageName !='Expired'];
                for(Opportunity opp : opps)
                {                    
                    if(UserInfo.getProfileId() == chinaSmartBookingOfficerProfileId && (opp.Owner.ProfileId == EFChinaOperatorProfileid || opp.Owner.ProfileId == EFChinaOperatorLeadProfileid || opp.Owner.ProfileId == chinaSHTMUserProfileId || opp.Owner.ProfileId == chinaSHTMManagerProfileId))
                    {
                        opp.FTM_Name__c = opp.OwnerId;
                    }
                    opp.OwnerId = SelectedUserId;
                }
                update opps;
                List<Contact> contacts = [select Id , OwnerId from Contact where AccountId = :TargetAccount.Id];
                for(Contact con : contacts)
                {
                	con.OwnerId = SelectedUserId;
                }
                update contacts;
                List<Actual__c> acts=[select Id,Opportunity_Owner__c from Actual__c where Opportunity__c in :opps]; 
                for(Actual__c act:acts)
                {
                    act.Opportunity_Owner__c = SelectedUserId;
                }
                update acts;
                if(PostAction != null && PostAction.contains('UpdateOppStage'))
                {
                    UpdateOppStage();
                }
                if(PostAction != null && PostAction.contains('UpdateEventOwnerId'))
                {
                    UpdateEventOwnerId();
                }
                return new PageReference('/' + TargetAccount.Id);
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }          
         }       
         else
           {
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose a user to continue.'));
           }
               
        return null;
    }
    
    private List<SelectOption> buildUserList()
    {
        if(TargetAccount == null)
        {
            return new List<SelectOption>();
        }
        
        Map<String, String> userMap = new Map<String, String>();
        List<SelectOption> options = new List<SelectOption>();
        List<ChangeOwnerRule__c> configs= [select CurrentRole__c, ToRole__c,ToProfile__c,FromRole__c,FromProfile__c,Denied__c,DenialMessage__c,FromSameSchool__c,ToSameSchool__c,ToUser__c,PostAction__c  from ChangeOwnerRule__c 
                                            where (CurrentRole__c =:CurrentUserRoleName and CurrentProfile__c =:CurrentProfileName) or (CurrentRole__c =''and CurrentProfile__c=:CurrentProfileName) or (CurrentProfile__c='' and CurrentRole__c =:CurrentUserRoleName)];
        if(configs.size() > 0)
        {
            for(ChangeOwnerRule__c config : configs)
            {
                if((isNullOrEmpty(config.FromRole__c) && config.FromProfile__c == OldProfileName) || (isNullOrEmpty(config.FromProfile__c) && config.FromRole__c == OldUserRoleName)||(config.FromRole__c == OldUserRoleName && config.FromProfile__c == OldProfileName)||(isNullOrEmpty(config.FromProfile__c) && isNullOrEmpty(config.FromRole__c)))
                {
                    if(config.Denied__c)
                    {
                        //display the denial message directly here
                        IsDenied = true;
                        config.DenialMessage__c = (config.DenialMessage__c == null) ? 'Your are not allowed to change the owner.' : config.DenialMessage__c;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, config.DenialMessage__c)); 
                    }
                    else
                    {
                        PostAction=config.PostAction__c;
                        ////not denied
                        if(!config.FromSameSchool__c)
                        {
                            //not from same school
                            if(config.ToSameSchool__c)
                            {
                                //to same school  
                                userMap.putAll(GetToUsers(config.ToRole__c, config.ToProfile__c, config.ToUser__c, CurrentSchoolName));
                            }
                            else
                            {
                                //not to same school
                                userMap.putAll(GetToUsers(config.ToRole__c, config.ToProfile__c, config.ToUser__c, ''));
                            }   
                        }
                        else
                        {
                            //from same school
                            if(CurrentSchoolName == OldSchoolName)
                            {
                                if(config.ToSameSchool__c)
                               {
                                   //to same school
                                    userMap.putAll(GetToUsers(config.ToRole__c, config.ToProfile__c, config.ToUser__c, CurrentSchoolName));
                               }
                               else
                               {
                                   //not to same school
                                   userMap.putAll(GetToUsers(config.ToRole__c, config.ToProfile__c, config.ToUser__c, ''));
                               }      
                            }
                            else
                            {
                                IsDenied = true;
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You cannot change owner from other school.')); 
                            }
                        }
                    }  
                }   
            }
        }
        for(String usrId : userMap.keySet())
        {
            options.add(new SelectOption(usrId, userMap.get(usrId)));
        }
        if(options.size()>0)
        {
            options.add(0, new SelectOption('', '--Choose a user--'));
        }
        else
        {
            options.add(new SelectOption('','--None--'));
        }
        return options;
    }
    
    private Map<String, String> GetToUsers(String role, String profile, String userId, String schoolName)
    {
        String sql = 'select Id, Name,SchoolName__c from User where IsActive=true';
        Map<String, String> userMap = new Map<String, String>();
        if(!isNullOrEmpty(role))
        {
            sql += ' and UserRole.Name=:role';
        }
        if(!isNullOrEmpty(profile))
        {
            sql += ' and Profile.Name=:profile';
        }
        if(!isNullOrEmpty(userId))
        {
            sql += ' and Id =:userId';
        }
        if(!isNullOrEmpty(schoolName))
        {
            sql += ' and SchoolName__c=:schoolName';
        }
        for(User usr : Database.query(sql))
        {
            userMap.put(usr.Id, usr.Name);
        }
        return userMap;
    }
    
    private Boolean isNullOrEmpty(String value)
    {
        return (value == null) || (value == '');
    }
    private void UpdateOppStage()
    {
         List<Opportunity> opps = [select Id, OwnerId , Owner.ProfileId from Opportunity where AccountId=:TargetAccount.Id and StageName!='Closed Won' AND StageName !='Expired'];
        List<Event> salesDemoEvents = [select Id from Event where Subject Like 'sales demo%' and WhatId in :opps];
        for(Opportunity opp : opps)
        {
            opp.StageName = 'Showed Up - Followup';
            opp.First_Visit__c = date.today();
            String showUpTime = null;
            String currentHour = String.valueof(Datetime.now().hour());
            String currentMinute = (datetime.now().minute() >= 30)?'30':'00';
            showUpTime = currentHour + ':' + currentMinute;
            opp.ShowUpTime__c = showUpTime;
        }
        update opps;
        if(!salesDemoEvents.isEmpty())
        {
        		delete salesDemoEvents;
        }
    }
    private void UpdateEventOwnerId()
    {
        List<Event> events = [SELECT Id, OwnerId, Subject, Appt_Status__c FROM Event WHERE AccountId = :TargetAccount.Id];
        List<Event> sEvents = new List<Event>();
        for (Event event : events)
        {
            if (event.Subject.contains('Sales Demo') && event.Appt_Status__c == 'Scheduled')
            {
                event.OwnerId = SelectedUserId;
                sEvents.add(event);
            }
        }
        Database.update(sEvents, false);
    }
    
    @isTest
    static void testChangeOwnerController()
    {
        ChangeOwnerRule__c config = new ChangeOwnerRule__c();
        config.Name = 'test1';
        config.CurrentRole__c = 'English Town';
        config.ToUser__c = '00540000000rnP7';
        config.ToSameSchool__c = True;
        insert config;
        Account testAccount = [select Id, Name, OwnerId from Account limit 1];
        PageReference testPage = new PageReference('/changeOwner?id=' + testAccount.Id);
        test.setCurrentPage(testPage);
        ChangeOwnerController  changeOwner = new ChangeOwnerController();
        changeOwner.TargetAccount = testAccount;
        changeOwner.SelectedUserId = '00540000000rnP7';
        changeOwner.init();
        changeOwner.save();
        changeOwner.UpdateEventOwnerId();
        changeOwner.cancel();  
    }
   
}