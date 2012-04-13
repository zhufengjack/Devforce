/*
 * assigns task/case according to the assignment rule
 */
 
global class AutoAssignmentLogic
{
	private static Boolean isTest = Test.isRunningTest();
    private static Integer queryLimitedSize;
    
    static
    {
        queryLimitedSize = isTest? (20): Limits.getLimitQueryRows();
    }
	
    webservice static String assignTask(String taskId)
    {   
        String result = '';
        if(taskId == null || taskId == '')
        {
            throw new EtownException('TaskId cannot be null', 0);
        }

        List<Task> tasks = [select Id, WhoId from Task where Id=:taskId limit 1];
        if(tasks.size() == 0)
        {
            throw new EtownException('Task not found', 0);
        }
        List<Contact> contacts = [select PartnerCode__c, PreferredLanguage__c, CountryCode__c from Contact where Id=:tasks[0].WhoId limit 1];
        if(contacts.size() == 0)
        {
            throw new EtownException('Task is not related to a contact', 0);
        }
        String partner = contacts[0].PartnerCode__c;
        String country = contacts[0].CountryCode__c;
        String language = contacts[0].PreferredLanguage__c;
        
        return assignTask(partner, country, language);
    }
    
    public static String assignTask(String partner, String country, String language)
    {
    	String revisedCountry = (country != null && country.length() > 2)? country.substring(0, 2): country;
        EtownConfiguration__c matchedRule = getAssignmentRule(partner, revisedCountry, language); 
        if(matchedRule == null || matchedRule.Assignee__c == null)
        {
        	List<EtownConfiguration__c> defaultMatchedRules = [select Id, Assignee__c from EtownConfiguration__c where RecordType.Name='Task' and IsDefault__c=true order by CreatedDate desc limit 1];
        	if(defaultMatchedRules.size() > 0)
        	{
        	    matchedRule = defaultMatchedRules[0];
        	}
        	else
        	{
        	    throw new EtownException('No assignment rule matched', 0);
        	}
        }
        String assignee = matchedRule.Assignee__c;
        List<User> assignees = getAssignees(assignee);
        if(assignees == null || assignees.size() == 0)
        {
            throw new EtownException('No SA user[' + assignee + '] found', 0);
        }
        else if(assignees.size() == 1)
        {            
            return assignees[0].Id;
        }
        else
        {
            //more than 1 users
            Id saWithFewestTask = getUserWithFewestTask(assignees);
            if(saWithFewestTask == null)
            {
                throw new EtownException('No SA user[' + assignee + '] found', 0);
            }            
            return saWithFewestTask;
        }
    }
    
    webservice static String assignCase(String caseId)
    {
        String result = assignCase2(caseId);
        assignCaseToUser(caseId, result);
        return result;
    }
    
    webservice static String assignCase2(String caseId)
    {
        String result = '';
        if(caseId == null || caseId == '')
        {
            throw new EtownException('caseId cannot be null', 0);
        }

        List<Case> cases = [select Id, ContactId, LanguageCode__c, Contact.PartnerCode__c, Contact.PreferredLanguage__c, Contact.CountryCode__c, Contact.DivisionCode__c, Contact.IsSocial__c, Contact.BU__c from Case where Id=:caseId limit 1];
        if(cases.size() == 0)
        {
            throw new EtownException('Case not found', 0);
        }
        if(cases[0].ContactId == null)
        {
            throw new EtownException('Case is not related to a contact', 0);
        }
        String partner = cases[0].Contact.PartnerCode__c;
        String country = cases[0].Contact.CountryCode__c;
        String language = cases[0].LanguageCode__c;
        if ((language == '')||(language == null))
        {
        	language = cases[0].Contact.PreferredLanguage__c;
        }
        Boolean isSocial = cases[0].Contact.IsSocial__c;
        String bu = cases[0].Contact.BU__c;
        String revisedCountry = (country != null && country.length() > 2)? country.substring(0, 2): country;
        
        system.debug('partner ' + partner);
        system.debug('revisedCountry ' + revisedCountry);
        system.debug('language '+ language);
        system.debug('isSocial' + isSocial);
        system.debug('bu' + bu);
        
        EtownConfiguration__c matchedRule = getAssignmentRule(partner, revisedCountry, language, isSocial, bu);
		
		system.debug('matchedRule  '  + matchedRule);
		
        if(matchedRule == null || matchedRule.Assignee__c == null || matchedRule.Assignee__c == '')
        {
        	matchedRule = [select Id, Assignee__c from EtownConfiguration__c where RecordType.Name='Case' and IsDefault__c=true limit 1];            
        }
        return matchedRule.Assignee__c;
    }
    
    public static void assignCaseToUser(String caseId, String userOrQueueId)
    {
        try
        {
            update new Case(Id=caseId, OwnerId=userOrQueueId);   
        }
        catch(DmlException ex)
        {
            throw new EtownException('Failed to update case owner: ' + ex.getMessage(), 0);
        }
    }
    
    private static EtownConfiguration__c getAssignmentRule(String partner, String country, String language)
    {
        //parse the param
        Set<String> possiblePartnerValues = getPossibleValues(partner, 'Partner');
        Set<String> possibleCountryValues = getPossibleValues(country, 'Country');
        Set<String> possibleLanguageValues = getPossibleValues(language, 'Language');  
        List<EtownConfiguration__c> rules = [select Id, Assignee__c from EtownConfiguration__c where (Partner__c in :possiblePartnerValues) and (Language__c in :possibleLanguageValues) and (Country__c in :possibleCountryValues) and RecordType.Name='Task' and IsDefault__c = false order by Priority__c asc limit 1];
        if(rules.size() > 0)
        {
            return rules[0];
        }
        else
        {
            return null;
        }
    }
    
    private static EtownConfiguration__c getAssignmentRule(String partner, String country, String language, Boolean isSocial, String bu)
    {
        //parse the param
        Set<String> possiblePartnerValues = getPossibleValues(partner, 'Partner');
        Set<String> possibleCountryValues = getPossibleValues(country, 'Country');
        Set<String> possibleLanguageValues = getPossibleValues(language, 'Language');
        Set<String> possibleBuValues = new Set<String>{ null, bu };
        List<EtownConfiguration__c> rules = [select Id, Assignee__c from EtownConfiguration__c where (Partner__c in :possiblePartnerValues) and (Language__c in :possibleLanguageValues) and (Country__c in :possibleCountryValues) and BU__c in :possibleBuValues and RecordType.Name='Case' and IsDefault__c=false order by Priority__c asc limit :queryLimitedSize];    
        if(rules.size() > 0)
        {
            return rules[0];
        }
        else
        {
            return null;
        }
    }
    
    private static Set<String> getPossibleValues(String value, String recordType)
    {
        Set<String> includedGroup = getIncludedGroups(value, recordType);
        Set<String> excludedGroup = getExcludedGroups(value, recordType);
        Set<String> notEqual = getAllValues(recordType);
        notEqual.remove(value);
        includedGroup = appendSuffix(includedGroup, '*');
        excludedGroup = appendPrefix(appendSuffix(excludedGroup, '*'), '!');
        notEqual = appendPrefix(notEqual, '!');
        Set<String> expected = new Set<String> { value, null };
        expected.addAll(includedGroup);
        expected.addAll(excludedGroup);
        expected.addAll(notEqual);
        return expected;
    }
    
    private static Set<String> getAllGroups(String recordType)
    {
        Set<String> results = new Set<String>();
        for(ContentParamInheritance__c cpi : [select Parent__c from ContentParamInheritance__c where RecordType.Name=:recordType limit :queryLimitedSize])
        {
            results.add(cpi.Parent__c);
        }
        return results;
    }
    
    private static Set<String> getIncludedGroups(String member, String recordType)
    {
        Set<String> results = new Set<String>();
        for(ContentParamInheritance__c cpi : [select Parent__c from ContentParamInheritance__c where Child__c = :member and RecordType.Name=:recordType limit :queryLimitedSize])
        {
            results.add(cpi.Parent__c);
        }
        return results;
    }
    
    private static Set<String> getExcludedGroups(String member, String recordType)
    {
        Set<String> allGroups = getAllGroups(recordType);
        Set<String> includedGroups = getIncludedGroups(member, recordType);
        allGroups.removeAll(includedGroups);
        return allGroups;
    }
    
    private static Set<String> getGroupMembers(String groupName, String recordType)
    {
        Set<String> result = new Set<String>();
        for(ContentParamInheritance__c cpi : [select Child__c from ContentParamInheritance__c where Parent__c=:groupName and RecordType.Name=:recordType limit :queryLimitedSize])
        {
            result.add(cpi.Child__c);
        }
        return result;
    }
    
    private static Set<String> getAllValues(String recordType)
    {
        Set<String> result = new Set<String>();
        if(recordType == 'Partner')
        {
            for(EtownPartner__c partner : [select Code__c from EtownPartner__c limit :queryLimitedSize])
            {
                result.add(partner.Code__c);
            }
        }
        else if(recordType == 'Country')
        {
            for(EtownCountry__c country : [select Code__c from EtownCountry__c limit :queryLimitedSize])
            {
                result.add(country.Code__c);
            }
        }
        else if(recordType == 'Language')
        {
            for(EtownLanguage__c language : [select Code__c from EtownLanguage__c limit :queryLimitedSize])
            {
                result.add(language.Code__c);
            }
        }
        return result;
    }
    
    private static Set<String> appendSuffix(Set<String> values, String suffix)
    {
        Set<String> result = new Set<String>();
        for(String value : values)
        {
            result.add(value + suffix);
        }
        return result;
    }
    private static Set<String> appendPrefix(Set<String> values, String prefix)
    {
        Set<String> result = new Set<String>();
        for(String value : values)
        {
            result.add(prefix + value);
        }
        return result;
    }
    
    private static List<User> getAssignees(String assignee)
    {
        if(assignee.contains('*'))
        {
            //assignee is a group name
            Set<String> userIds = getGroupMembers(assignee.replace('*', ''), 'User');
            return [select Id from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and Id in :userIds and IsActive=true limit :queryLimitedSize];
        }
        else
        {
            //assignee is a user id
            List<User> users = [select Id from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and Id=:assignee and IsActive=true limit 1];
            if(users.size() > 0)
            {
                return new List<User> { users[0] };
            }
            else
            {
                return new List<User>();
            }
        }
    }
    
    private static Id getUserWithFewestTask(List<User> users)
    {
        Map<String, Integer> user2TaskCount = new Map<String, Integer>();
        String result;
        if(users != null && users.size() > 0)
        {
            for(User saUser : users)
            {
                user2TaskCount.put(saUser.Id, 0);
            }
        }
        AggregateResult[] groupedResults = [select OwnerId, count(Id) c from Task where OwnerId in :users and IsClosed=false and RecordType.Name = 'Study Advise' group by OwnerId limit :queryLimitedSize];  
        if(groupedResults.size() > 0)
        {
            for(AggregateResult ar : groupedResults)
            {
                user2TaskCount.put((Id)ar.get('OwnerId'), (Integer)ar.get('c'));
            }
        }
        Integer min = 0;
        if(user2TaskCount.values().size() > 0)
        {
            min = user2TaskCount.values().get(0);
        }
        for(String userId : user2TaskCount.keySet())
        {
            Integer saTaskCount = user2TaskCount.get(userId);
            if(saTaskCount <= min)
            {
                min = saTaskCount;
                result = userId;
            }
        }
        return result;
    }

    @isTest
    static void testAutoAssignmentLogic()
    {
        // create necessary data.               
        EtownPartner__c partner = new EtownPartner__c(Code__c='Acme1', Name='Acme1');
		insert partner;
		EtownLanguage__c language = new EtownLanguage__c(Code__c='en_us', Name='English');
		insert language;
		EtownCountry__c country = new EtownCountry__c(Code__c='ame', Name='America');
		insert country;
		EtownDivision__c division = new EtownDivision__c(Code__c='Smart', Name='Shanghai');
    	insert division;
    	String adviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
    	List<Account> accounts  = new List<Account>{
										    		new Account(Name='acme1'),
										    		new Account(Name='acme2'),
										    		new Account(Name='acme3')};
        insert accounts;
		Contact taskCont = new Contact(Lastname = 'test contact1', AccountId = accounts[0].Id, Email = 'test.acme.advise@pm.com', EtownMemberId__c = 9899999, PartnerCode__c='uss', PreferredLanguage__c='aaa', CountryCode__c='span');
        Contact taskCont2 = new Contact(Lastname = 'test contact3', AccountId = accounts[1].Id, Email = 'test.acme.advise@pm.com', EtownMemberId__c = 9899997, PartnerCode__c='', PreferredLanguage__c='', CountryCode__c='');
        Contact caseCont = new Contact(Lastname = 'test contact2', AccountId = accounts[2].Id, Email = 'test.acme.advise@pm.com', EtownMemberId__c = 9888888, PartnerCode__c=partner.Code__c, PreferredLanguage__c=language.Code__c, CountryCode__c=country.Code__c, DivisionCode__c=division.Code__c, IsSocial__c=false);
        insert new List<Contact>{taskCont, taskCont2, caseCont}; 
        Task task1 = new Task(RecordTypeId=adviseTaskRecordTypeId, Subject='test Task', ActivityDate=Date.today().addDays(3), OwnerId=UserInfo.getUserId(), WhoId=taskCont.Id, Status='In Progress');
        Task task2 = new Task(RecordTypeId=adviseTaskRecordTypeId, Subject='test Task2', ActivityDate=Date.today().addDays(3), OwnerId=UserInfo.getUserId(), WhoId=caseCont.Id, Status='In Progress');
        Task task3 = new Task(RecordTypeId=adviseTaskRecordTypeId, Subject='test Task3', ActivityDate=Date.today().addDays(3), OwnerId=UserInfo.getUserId(), WhoId=taskCont2.Id,  Status='In Progress');
        insert new List<Task>{task1, task2, task3};
        Id recordTypeId = [select Id from RecordType where Name != 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
        Case case1 = new Case(Subject='acme', Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email', ContactId=caseCont.Id, AccountId = accounts[2].Id, RecordTypeId = recordTypeId);
        insert case1;
        //task part:
	    ContentParamInheritance__c cpi = new ContentParamInheritance__c();
	    insert cpi;
	    RecordType recTypeTask = [select Id from RecordType where Name='Task' and SObjectType='EtownConfiguration__c' limit 1];
	    List<User> SAUsers = [select Id, Name from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and IsActive=true order by Name limit 20];
		EtownConfiguration__c config1 = new EtownConfiguration__c(Assignee__c=SAUsers[0].Id, Country__c=country.Code__c, Language__c=language.Code__c, Partner__c=partner.Code__c, Priority__c=1, IsDefault__c=false, RecordTypeId=recTypeTask.Id);
    	EtownConfiguration__c config2 = new EtownConfiguration__c(Assignee__c=SAUsers[0].Id, Country__c='', Language__c='', Partner__c='', Priority__c=1, RecordTypeId=recTypeTask.Id, IsDefault__c=true);
		EtownConfiguration__c config5 = new EtownConfiguration__c(Assignee__c=SAUsers[0].Id, Country__c='us', Language__c='en', Partner__c='Corp', Priority__c=2, RecordTypeId=recTypeTask.Id);
		EtownConfiguration__c config6 = new EtownConfiguration__c(Assignee__c=SAUsers[0].Id, Country__c='', Language__c='!fr', Partner__c='', Priority__c=1, RecordTypeId=recTypeTask.Id);
		insert new List<EtownConfiguration__c>{config1, config2, config5, config6};
		//case part:
    	String queue = [Select Id, QueueId From QueueSobject where SobjectType='Case' limit 1].QueueId;
    	RecordType recTypeCase = [select Id from RecordType where Name='Case' and SObjectType='EtownConfiguration__c' limit 1];
    	EtownConfiguration__c config3 = new EtownConfiguration__c(Assignee__c=queue, BU__c=partner.BusinessUnit__c, Country__c=country.Code__c, Division__c=division.Code__c, Language__c=language.Code__c, Partner__c=partner.Code__c, Priority__c=1, IsDefault__c=false, RecordTypeId=recTypeCase.Id);
		EtownConfiguration__c config4 = new EtownConfiguration__c(Assignee__c=queue, BU__c='', Country__c='', Division__c='', Language__c='', Partner__c='', Priority__c=1, RecordTypeId=recTypeCase.Id, IsDefault__c=true);
    	insert new List<EtownConfiguration__c>{config3, config4};   	    	
    	String result1 = AutoAssignmentLogic.assignTask(task1.Id);
    	System.assert(result1 != null);
    	String result2 = AutoAssignmentLogic.assignTask(task2.Id);
    	System.assert(result2 != null);
    	String result3 = AutoAssignmentLogic.assignTask(task3.Id);
    	System.assert(result3 != null);
    	String result4 = AutoAssignmentLogic.assignCase(case1.Id);
    	System.assert(result4 != null);
    	AutoAssignmentLogic.getUserWithFewestTask(SAUsers);
    	AutoAssignmentLogic.getGroupMembers('', '');
    }
}