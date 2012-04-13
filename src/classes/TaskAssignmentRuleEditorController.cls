/*
 * this controller for the page "TaskAssignmentRuleEditor"
 */
public class TaskAssignmentRuleEditorController
{
    private static Map<Id, User> allAdvisorUsers; //key: user id, value: User
    private static Map<String, List<User>> allAdvisorMembers; //key: group code, value: group members
    private static Boolean isTest = Test.isRunningTest();
    
    static
    {
        //static constructor initializes the static variables 
        allAdvisorUsers = new Map<Id, User>();
        allAdvisorMembers = new Map<String, List<User>>();
        for(User usr : [select Id, Name, Email, Department from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and IsActive=true order by Name limit :(isTest? 20 : 50000)])
        {
            allAdvisorUsers.put(usr.Id, usr);
        }
        for(ContentParamInheritance__c param : [select Id, Name, Child__c, Parent__c from ContentParamInheritance__c where RecordType.Name='User' and Child__c!=null and Parent__c!=null limit :(isTest? 20 : 50000)])
        {
            if(allAdvisorUsers.containsKey(param.Child__c))
            {
                User advisor = allAdvisorUsers.get(param.Child__c);
                if(!allAdvisorMembers.containsKey(param.Parent__c))
                {
                    allAdvisorMembers.put(param.Parent__c, new List<User> { advisor });
                }
                else
                {
                    allAdvisorMembers.get(param.Parent__c).add(advisor);
                }
            }
        }
    }
    
    public TaskAssignmentRuleEditorController()
    {
        EditingRule = new RuleInfo(new EtownConfiguration__c());
        CurrentPageIndex = 1;
        List<EtownConfiguration__c> configurations = [select Id, Assignee__c from EtownConfiguration__c where RecordType.Name='Task' and IsDefault__c=true order by CreatedDate desc limit 1];
        if(configurations.size() > 0)
        {
            DefaultRuleId = configurations[0].Id;
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'There must be a default "Assign to".'));
        }
        IsDefaultShow = true;
    }
    
    private List<RuleInfo> ruleList;
    
    public String AdvisorFilter { get; set; }
    public String DefaultRuleId { get;private set; }
    public Boolean IsDefaultShow { get; set; }
    public List<RuleInfo> RuleInfos  // bind these data into Table.
    {
        get
        {
            if(ruleList == null)
            {
                ruleList = new List<RuleInfo>();
                for(EtownConfiguration__c eg : [select Id, Priority__c, Partner__c, Language__c, Country__c, Assignee__c from EtownConfiguration__c where RecordType.Name='Task' and IsDefault__c=false order by Priority__c asc limit :(isTest? 20 : 50000)])
                {
                    ruleList.add(new RuleInfo(eg));
                }
            }
            return ruleList; 
        }
    }
    
    public RuleInfo EditingRule { get; set; } // used to edit in the Div.
    public Integer EditingRuleIndex {get; set; }  // gets the index of the rule being editing
    
    public List<SelectOption> PartnerItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));
            for(EtownPartner__c partner : [select Id, Name, Code__c from EtownPartner__c where Code__c != null order by Name limit :(isTest? 20 : 1000)]) 
            {
                options.add(new SelectOption(partner.Code__c, partner.Code__c));
            }
            return options;
        }
    }
    public List<SelectOption> LanguageItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));
            for(EtownLanguage__c language : [select Id, Name, Code__c from EtownLanguage__c order by Name limit :(isTest? 20 : 1000)])
            {
                options.add(new SelectOption(language.Code__c, language.Name));
            }
            return options;
        } 
    }
    
    public List<SelectOption> CountryItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));
            for(ContentParamInheritance__c cpi : [select Parent__c from ContentParamInheritance__c where RecordType.Name = 'Country' and Parent__c != null order by Name limit :(isTest? 20 : 1000)]) // group items
            {
                options.add(new SelectOption(cpi.Parent__c, cpi.Parent__c + '*'));
            }
            for(EtownCountry__c country : [select Id, Name, Code__c from EtownCountry__c where Code__c != null order by Name limit :(isTest? 20 : 1000)])
            {
                if(country.Code__c.length() == 2)
                {
                    options.add(new SelectOption(country.Code__c, country.Name));
                }
            }
            return options;
        }
    }
    
    private List<AdvisorInfo> advisorList;
    
    public List<AdvisorInfo> AllAdvisors
    {
        get
        {
            if(advisorList == null)
            {
                advisorList = new List<AdvisorInfo>();
                for(User usr : allAdvisorUsers.values())
                {
                    AdvisorInfo advisor = new AdvisorInfo(usr);
                    advisor.IsSelected = EditingRule.HasAdvisor(usr.Id);
                    advisorList.add(advisor);
                }
            }
            return advisorList;
        }
    }
    
    public List<AdvisorInfo> FilteredAdvisors
    {
        get
        {
            List<AdvisorInfo> result = new List<AdvisorInfo>();
            if(AdvisorFilter == null || AdvisorFilter == '')
            {
                result.addAll(AllAdvisors);
            }
            else
            {
                for(AdvisorInfo advisor : AllAdvisors)
                {
                    if(advisor.Username.toLowerCase().contains(AdvisorFilter.trim().toLowerCase()))
                    {
                        result.add(advisor);
                    }
                }
            }
            if(result.size() < 1)
            {
                return result;
            }
            else
            {       
                return sortAdvisorInfoByName(result);
            }  
        }
    }
    
    private List<AdvisorInfo> sortAdvisorInfoByName (List<AdvisorInfo> advisorInfos)
    {
        AdvisorInfo tempAdvisorInfo = new AdvisorInfo();
        for(Integer i = 0; i < advisorInfos.size(); i++)
        {
            for(Integer j = advisorInfos.size()-1; j > i; j--)
            {
                if(advisorInfos[j].Username < advisorInfos[j-1].Username)
                {
                    tempAdvisorInfo = advisorInfos[j-1];
                    advisorInfos[j-1] = advisorInfos[j];
                    advisorInfos[j] = tempAdvisorInfo;
                }
            }
        }
        return advisorInfos;
    }
    
    // pagination in SA User table.
    public Integer CurrentPageIndex { get; set; }
    
    public PageReference previous()
    {
        if(CurrentPageIndex > 1)
        {
            CurrentPageIndex --;
        }
        return null;
    }
        
    public PageReference next()
    {
        if(CurrentPageIndex < getTotalPageSize())
        {
            CurrentPageIndex ++;
        }
        return null;
    }
        
    public Integer getTotalPageSize()
    {
        Integer totalPageSize = 0;
        Integer totalRecordSize = (FilteredAdvisors == null)? 0: FilteredAdvisors.size();
        if(Math.mod(totalRecordSize, 20) != 0)
        {
            totalPageSize = totalRecordSize / 20 + 1;
        }
        else
        {
            totalPageSize = totalRecordSize / 20;
        }
        return totalPageSize;
    }
    
    public RuleInfo DefaultRule
    {
        get
        {
            List<EtownConfiguration__c> ruleList = [select Id, Priority__c, Partner__c, Language__c, Country__c, Assignee__c from EtownConfiguration__c where RecordType.Name='Task' and IsDefault__c=true limit :(isTest? 20 : 50000)];
            if(ruleList.size() < 1)
            {
                try
                {
                    String recTypeId = [Select Id from RecordType where Name = 'Task' and SObjectType='EtownConfiguration__c' limit 1].Id;              
                    EtownConfiguration__c rule = new EtownConfiguration__c(Priority__c=1, Partner__c='', Language__c='', Country__c='', RecordTypeId=recTypeId, IsDefault__c=true);
                    rule.Assignee__c=(allAdvisorUsers.values() == null)? '': (allAdvisorUsers.values())[0].Id;
                    insert rule;
                    return new RuleInfo(rule);
                }
                catch(Exception ex)
                {
                    ApexPages.addMessages(ex);
                }               
            }
            return new RuleInfo(ruleList[0]);
        }
    }
    
    public PageReference editRule()
    {
        IsDefaultShow = true;
        if(EditingRuleIndex != null)
        {
            EditingRule = RuleInfos[EditingRuleIndex];
            EditingRule.Language = (EditingRule.Language != null && EditingRule.Language != '')?(EditingRule.Language.replace('!', '')):EditingRule.Language;           
            EditingRule.Country = (EditingRule.Country != null && EditingRule.Country != '')?(EditingRule.Country.replace('!', '')):EditingRule.Country;          
            EditingRule.Partner = (EditingRule.Partner != null && EditingRule.Partner != '')?(EditingRule.Partner.replace('!', '')):EditingRule.Partner;
            advisorList = null;
        }
        return null;
    }
    
    public PageReference insertRule()
    {
        IsDefaultShow = true;
        EditingRuleIndex = -1;
        advisorList = null;
        EditingRule = new RuleInfo(new EtownConfiguration__c());
        return null;
    }
    
    public PageReference refreshUserList()
    {
        advisorList = null;
        return null;
    }
    
    public PageReference save()
    {
        // update the record.  delete first , then create new . 
        if(EditingRule != null)
        {
            try
            {
                EtownConfiguration__c newRule = new EtownConfiguration__c(Id=EditingRule.RuleId, Priority__c=EditingRule.Priority);
                newRule.Language__c = (EditingRule.LanguageStatus == true)?('!' + EditingRule.Language):EditingRule.Language; 
                newRule.Partner__c = (EditingRule.PartnerStatus == true)?('!' + EditingRule.Partner):EditingRule.Partner; 
                newRule.Country__c = (EditingRule.CountryStatus == true)?('!' + EditingRule.Country):EditingRule.Country; 
                newRule.Assignee__c = getUserGroup(EditingRule);              
                newRule.RecordTypeId = [Select Id from RecordType where Name = 'Task' and SObjectType='EtownConfiguration__c' limit 1].Id;            
                upsert newRule;
                PageReference page = new PageReference('/apex/TaskAssignmentRuleEditor');
                page.setRedirect(true);
                return page;
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }
        }
        
        return null;
    }
    
    // gets the index of record list , then delete this record.
    public PageReference deleteRule()
    { 
        try
        {
            EditingRule = RuleInfos[EditingRuleIndex];
            delete [select Id from ContentParamInheritance__c where Parent__c=:EditingRule.Assignee and RecordType.Name='User' limit :(isTest? 20 : 50000)];
            delete new EtownConfiguration__c(Id=EditingRule.RuleId);
            ruleList = null;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    public PageReference popDefaultRule()
    {
        IsDefaultShow = false;
        EditingRule = DefaultRule;
        advisorList = null;      
        return null;
    }
    
    private String getUserGroup(RuleInfo rule)
    {
        List<String> selectedAdvisors = new List<String>();
        for(AdvisorInfo advisor : AllAdvisors)
        {
            if(advisor.IsSelected)
            {
                selectedAdvisors.add(advisor.UserId);
            }
        }
        if(selectedAdvisors.size() == 0)
        {
            throw new EtownException('At least 1 user required', 0);
        }        
        if(rule.RuleId != null)
        {
            delete [select Id from ContentParamInheritance__c where Parent__c=:rule.Assignee and RecordType.Name='User' limit :(isTest? 20 : 50000)];
        }        
        if(selectedAdvisors.size() > 1)
        {
            List<ContentParamInheritance__c> groupItems = new List<ContentParamInheritance__c>();
            String userGroupRecordTypeId = [select Id from RecordType where SObjectType='ContentParamInheritance__c' and Name='User' limit 1].Id;
            for(String userId : selectedAdvisors)
            {
                groupItems.add(new ContentParamInheritance__c(Child__c=userId, RecordTypeId=userGroupRecordTypeId));    
            }
            insert groupItems;
            groupItems = [select Id, Name, Child__c from ContentParamInheritance__c where Id in :groupItems limit :(isTest? 20 : 50000)];
            for(ContentParamInheritance__c item : groupItems)
            {
                item.Parent__c = groupItems[0].Name;
            }
            upsert groupItems;
            return groupItems[0].Name + '*';
        }
        else if(selectedAdvisors.size() == 1)
        {
            return selectedAdvisors[0];
        }
        else
        {
            return null;
        }
    }

    public class RuleInfo
    {
        private EtownConfiguration__c rule;
        
        public RuleInfo(EtownConfiguration__c etRule)
        {   
            rule = etRule;
            this.RuleId = rule.Id;
            this.Priority = Integer.valueOf(rule.Priority__c);
            this.Language = rule.Language__c;
            this.Country = rule.Country__c;
            this.Partner = rule.Partner__c;
            if(rule.Assignee__c != null)
            {
                this.Assignee = (rule.Assignee__c.contains('*'))?(rule.Assignee__c.replace('*', '')):rule.Assignee__c;
            }
            this.LanguageStatus = (Language != null && Language != '')?(Language.contains('!')):false;
            this.PartnerStatus = (Partner != null && Partner != '')?(Partner.contains('!')):false;
            this.CountryStatus = (Country != null && Country != '')?(Country.contains('!')):false;
        }
        
        public Id RuleId { get; set; }
        public Integer Priority { get; set; }
        public String Language { get; set; }
        public String Country { get; set; }
        public String Partner { get; set; }
        public String Assignee { get; set; }
        public Boolean LanguageStatus { get; set; }
        public Boolean CountryStatus { get; set; }
        public Boolean PartnerStatus { get; set; }
        
        //gets a value represents the saList in the format 'A/B/C/D'
        public String SAList
        {
            get
            {
                String result = '';
                for(AdvisorInfo user : Advisors)
                {
                    result += user.Username + '/';
                }
                if(result.length() > 0)
                {
                    result = result.substring(0, result.length() - 1);
                }
                return result;
            }
        }
        
        private List<AdvisorInfo> advisorList;
        
        public List<AdvisorInfo> Advisors
        {
            get
            {
                if(advisorList == null)
                {
                    advisorList = new List<AdvisorInfo>();
                    if(assignee != null && assignee != '')
                    {
                        if(allAdvisorMembers.containsKey(Assignee))
                        {
                            //assignee is a group
                            for(User usr : allAdvisorMembers.get(Assignee))
                            {
                                advisorList.add(new AdvisorInfo(usr));
                            }
                        }
                        else if(Assignee instanceof Id && allAdvisorUsers.containsKey(Assignee))
                        {
                            //assignee is an user id
                            advisorList.add(new AdvisorInfo(allAdvisorUsers.get(Assignee)));
                        }
                        else
                        {
                            //assignee not found
                        }
                    }   
                }
                return advisorList;
            }
        }
        
        public Boolean HasAdvisor(Id userId)
        {
            for(AdvisorInfo advisor : Advisors)
            {
                if(advisor.UserId == userId)
                {
                    return true;
                }
            }
            return false;
        }
    }
    
    public class AdvisorInfo
    {
        private User usr;
        
        public AdvisorInfo()
        {
        }
        
        public AdvisorInfo(User user)
        {
            this.usr = user;
            this.Username = usr.Name;
            this.UserId = usr.Id;
            this.Department = usr.Department;
            this.Email = usr.Email;
        }
        
        public Boolean IsSelected { get; set; }
        public Id UserId { get; set; }
        public String Username { get; set; }
        public String Email {get; set; }
        public String Department { get; set; }
    }
    
    @isTest
    static void testTaskAssignmentRuleEditorController()
    {
        EtownPartner__c partner = new EtownPartner__c(Code__c='Acme1', Name='Acme1');
        insert partner;
        EtownLanguage__c language = new EtownLanguage__c(Code__c='en_us', Name='English');
        insert language;
        EtownCountry__c country = new EtownCountry__c(Code__c='ame', Name='America');
        insert country;
        ContentParamInheritance__c cpi = new ContentParamInheritance__c();
        insert cpi;
        RecordType recType = [select Id from RecordType where Name='Task' and SObjectType='EtownConfiguration__c' limit 1];
        List<User> SAUsers = [select Id, Name from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and IsActive=true order by Name];
        EtownConfiguration__c config = new EtownConfiguration__c(Assignee__c=SAUsers[0].Id, Country__c=country.Code__c, Language__c=language.Code__c, Partner__c=partner.Code__c, Priority__c=1, RecordTypeId=recType.Id);
        insert config;
        
        TaskAssignmentRuleEditorController controller = new TaskAssignmentRuleEditorController();
        System.assert(controller.RuleInfos.size() > 0);
        System.assert(controller.PartnerItems != null);
        System.assert(controller.LanguageItems != null);
        System.assert(controller.CountryItems != null);
        controller.AdvisorFilter = ' ';    
        controller.EditingRuleIndex = 0;
        System.assert(controller.EditingRule != null);
        System.assert(controller.RuleInfos[controller.EditingRuleIndex] != null);
        controller.CurrentPageIndex = 2;
        System.assert(controller.FilteredAdvisors != null);
        System.assert(controller.AllAdvisors.size() > 0);
        controller.editRule();
        controller.insertRule();
        controller.deleteRule();
        controller.refreshUserList();
        controller.popDefaultRule();
        controller.previous();
        controller.next();
        controller.save();
        System.assert(controller.getTotalPageSize() >= 0);
        System.assert(controller.RuleInfos[0].SAList != null);
    }
}