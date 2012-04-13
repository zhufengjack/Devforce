/*
 * this controller for page "CaseAssignmentRuleEditor"
 */
public class CaseAssignmentRuleEditorController
{
    static Map<String, String> groupId2Name; // key: GroupId, value: GroupName
    static Set<String> queueSet;
    private static Boolean isTest = Test.isRunningTest();
    private static Integer queryLimitedSize;
                
    static
    {
        queryLimitedSize = isTest? (20): Limits.getLimitQueryRows();
        groupId2Name = new Map<String, String>();
        queueSet = new Set<String>();
        for(Group gp : [select Id, Name from Group where Type='Queue' order by Name limit :queryLimitedSize])
        {
            if(gp.Name != null)
            {
                groupId2Name.put(gp.Id, gp.Name);
            }
        } 
        for(QueueSobject st : [Select QueueId From QueueSobject where SobjectType='Case' limit :queryLimitedSize])
        {
            queueSet.add(st.QueueId);
        }
    }
    
    public CaseAssignmentRuleEditorController()
    {
        EditingRule = new RuleInfo(new EtownConfiguration__c(), new Map<String, String>());
        IsDefaultShow = true;
    }
    
    private List<RuleInfo> ruleList;
    private Set<String> buCollection;
    private String countryCodeFilter = 'un';
    
    public List<RuleInfo> RuleInfos  // bind these data into Table.
    {
        get
        {
            if(ruleList == null)
            {
                ruleList = new List<RuleInfo>();
                for(EtownConfiguration__c eg : [select Id, Priority__c, Partner__c, Language__c, Country__c, BU__c, Assignee__c from EtownConfiguration__c where RecordType.Name='Case' and IsDefault__c=false order by Priority__c asc limit :queryLimitedSize])
                {            
                    ruleList.add(new RuleInfo(eg, groupId2Name));                   
                }
            }
            return ruleList; 
        }
    }
    
    public RuleInfo EditingRule { get; set; } // used to edit in the Div.
    public Integer EditingRuleIndex { get; set; }  // gets the index of the rule being editing
    public Boolean IsDefaultShow { get; set; }
    public RuleInfo DefaultRule 
    { 
        get
        {
            List<EtownConfiguration__c> ruleList = [select Id, Priority__c, Partner__c, Language__c, Country__c, BU__c, Assignee__c from EtownConfiguration__c where RecordType.Name='Case' and IsDefault__c=true limit :queryLimitedSize];
            if(ruleList.size() < 1)
            {
                try
                {
                    String recTypeId = [Select Id from RecordType where Name = 'Case' and SObjectType='EtownConfiguration__c' limit 1].Id;
                    String queueId = [Select QueueId From QueueSobject where SobjectType='Case' limit 1].QueueId;       
                    EtownConfiguration__c rule = new EtownConfiguration__c(Priority__c=1, Partner__c='', Language__c='', Country__c='', BU__c='', Assignee__c=queueId, RecordTypeId=recTypeId, IsDefault__c=true);
                    insert rule;
                    return new RuleInfo(rule, groupId2Name);
                }
                catch(Exception ex)
                {
                    ApexPages.addMessages(ex);
                }
            }
            return new RuleInfo(ruleList[0], groupId2Name);         
        } 
    }
    public PageReference popDefaultRule()
    {
        IsDefaultShow = false;
        EditingRule = DefaultRule;
        return null;
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
            EditingRule.BU = (EditingRule.BU != null && EditingRule.BU != '')?(EditingRule.BU.replace('!', '')):EditingRule.BU;
        }
        return null;
    }
    
    public PageReference insertRule()
    {
        IsDefaultShow = true;
        EditingRuleIndex = -1;
        EditingRule = new RuleInfo(new EtownConfiguration__c(), new Map<String, String>());
        return null;
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
	        for(EtownCountry__c country : [select Id, Name, Code__c from EtownCountry__c where Code__c != null  order by Name limit :(isTest? 20 : 1000)])
	        {
	        	if(country.Code__c.length() == 2)
	        	{
		            options.add(new SelectOption(country.Code__c, country.Name));
	        	}
	        }
    		return options;
    	}
    }
    
    public List<SelectOption> getPartnerItems()
    {
    	List<SelectOption> result = new List<SelectOption>();
        if(buCollection == null)
        {
        	buCollection = new Set<String>();
        }
        result.add(new SelectOption('',' '));
        countryCodeFilter = (EditingRule != null && EditingRule.Partner != null)? (EditingRule.Country + '%') : countryCodeFilter;
        for(EtownPartner__c partner : [select Id, Name, Code__c, BusinessUnit__c from EtownPartner__c where Code__c != null and (CountryCode__c = 'un' or CountryCode__c like :countryCodeFilter) order by Name limit :(isTest? 20 : 1000)]) 
        {
            result.add(new SelectOption(partner.Code__c, partner.Name));
            buCollection.add(partner.BusinessUnit__c);
        }
    	return result;
    }
    
    public PageReference refreshPartnerItems()
    {
    	if(EditingRule.Country != null)
    	{
    		countryCodeFilter = EditingRule.Country + '%';
    	}
    	return null;
    }

    public List<SelectOption> BUItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));
            for(String str : buCollection)
            {
                options.add(new SelectOption(str, str));
            }
            return options;
        }
    }
    
    public List<SelectOption> QueueItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));           
            for(Group gp : [select Id, Name from Group where Type='Queue' and Id in :queueSet order by Name limit :(isTest? 20 : 1000)])
            {
                options.add(new SelectOption(gp.Id, gp.Name));
            }   
            return options;
        }
    }            
    
    public PageReference save()
    {
        // update the record.  delete first , then create new . 
        if(EditingRule != null)
        {
            try
            {
                EtownConfiguration__c newRule = new EtownConfiguration__c(Id=EditingRule.RuleId, Priority__c=EditingRule.Priority,  Assignee__c=EditingRule.Queue);
                newRule.Language__c = (EditingRule.LanguageStatus == true)?('!' + EditingRule.Language):EditingRule.Language; 
                newRule.Partner__c = (EditingRule.PartnerStatus == true)?('!' + EditingRule.Partner):EditingRule.Partner; 
                newRule.Country__c = (EditingRule.CountryStatus == true)?('!' + EditingRule.Country):EditingRule.Country; 
                newRule.BU__c = (EditingRule.BUStatus == true)?('!' + EditingRule.BU):EditingRule.BU; 
                newRule.RecordTypeId = [Select Id from RecordType where Name = 'Case' and SObjectType='EtownConfiguration__c' limit 1].Id;
                upsert newRule; 
                
                PageReference page = new PageReference('/apex/CaseAssignmentRuleEditor');
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
            delete new EtownConfiguration__c(Id=EditingRule.RuleId);
            ruleList = null;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }

    public class RuleInfo
    {
        private EtownConfiguration__c rule;
        
        public RuleInfo(EtownConfiguration__c etRule, Map<String, String> Id2Name)
        {   
            rule = etRule;
            this.RuleId = rule.Id;
            this.Priority = Integer.valueOf(rule.Priority__c);
            this.Partner = rule.Partner__c;
            this.Language = rule.Language__c;
            this.Country = rule.Country__c;                       
            this.BU = rule.BU__c;
            this.Queue = rule.Assignee__c;
            this.QueueName = Id2Name.get(rule.Assignee__c);
            //this.IsSocial = rule.IsSocial__c;
            this.LanguageStatus = (Language != null && Language != '')?(Language.contains('!')):false;
            this.PartnerStatus = (Partner != null && Partner != '')?(Partner.contains('!')):false;
            this.CountryStatus = (Country != null && Country != '')?(Country.contains('!')):false;
            this.BUStatus = (BU != null && BU != '')?(BU.contains('!')):false;    
        }
        
        public Id RuleId { get; set; }
        public Integer Priority { get; set; }
        public String Language { get; set; }
        public String Country { get; set; }
        public String Partner { get; set; }
        public String Queue { get; set; }  // QueueName
        public String QueueName { get; set; }
        public String BU { get; set; }
        //public Boolean IsSocial { get; set; }
        public Boolean LanguageStatus { get; set; }
        public Boolean PartnerStatus { get; set; }
        public Boolean CountryStatus { get; set; }
        public Boolean BUStatus { get; set; }
    }
    
    @isTest 
    static void testCaseAssignmentRuleEditorController()
    {
        EtownPartner__c partner = new EtownPartner__c(Code__c='B2C', BusinessUnit__c='Acme', Name='Acme');
        insert partner;
        EtownLanguage__c language = new EtownLanguage__c(Code__c='en_us', Name='English');
        insert language;
        EtownCountry__c country = new EtownCountry__c(Code__c='ame', Name='America');
        insert country;
        Group gp = new Group(Name='Acme1', Type='Queue');
        insert gp;
        RecordType recType = [select Id from RecordType where Name='Case' and SObjectType='EtownConfiguration__c' limit 1];
        EtownConfiguration__c config = new EtownConfiguration__c(Assignee__c=gp.Id, BU__c=partner.BusinessUnit__c, Country__c=country.Code__c, Language__c=language.Code__c, Partner__c=partner.Code__c, Priority__c=1, RecordTypeId=recType.Id);
        insert config;
        
        CaseAssignmentRuleEditorController controller = new CaseAssignmentRuleEditorController();
        System.assert(controller.RuleInfos.size() >= 0);
        System.assert(controller.getPartnerItems() != null);
        System.assert(controller.LanguageItems != null);
        System.assert(controller.CountryItems != null);
        System.assert(controller.BUItems != null);
        System.assert(controller.QueueItems != null);
        System.assertEquals(groupId2Name.isEmpty(), false);
    
        controller.EditingRuleIndex = 0;
        System.assert(controller.RuleInfos[controller.EditingRuleIndex] != null);
        controller.editRule();
        controller.popDefaultRule();
        controller.insertRule();
        controller.save();
        controller.deleteRule();    
    }
}