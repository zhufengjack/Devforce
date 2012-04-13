/*
*   Controller for study advisor task list page.
*/
global class StudyAdviseTaskListController 
{
	public List<TaskEntity> TaskEntities {get; set;}
	public Boolean DisplayPreviousAndNextPanel 
    {
        get
        {
            if(TaskEntities.size() > tableSize)
            {
                return true;
            }
            else
            {
                return false;
            }
        } 
        private set;
    }
    public Integer tableSize 
    {
        get
        {
            return 20;
        }
    }
	public Integer startIndex {get; set;}
    public Boolean PreviousButtonDisplay {get; set;}
    public Boolean NextButtonDisplay {get;set;}
    public String FilterTaskStatus {get; set;}
    private Map<String, String> corporateMap = new Map<String, String>();
    private Map<String, String> languageMap = new Map<String, String>();
    private Map<String, String> countryMap = new Map<String, String>();
	private Map<String, Contact> contactMap = new Map<String, Contact>();
	private Map<String, String> memberId2Level = new Map<String, String>();
	private Integer etownServiceMemberIdStartIndex;
	private List<TaskEntity> tempEntities = new List<TaskEntity>();
	private EtownPersonalInfoWebService etownService;
	
    public StudyAdviseTaskListController()
    {
    	TaskEntities = new List<TaskEntity>();
    	FilterTaskStatus = 'Open';
    	etownService = new EtownPersonalInfoWebService();
        filterTaskByStatus();
    }
    
    public void filterTaskByStatus()
    {
    	TaskEntities.clear();
    	memberId2Level.clear();
    	etownServiceMemberIdStartIndex = 0;
        Map<String, String> task2Student = new Map<String, String>();
        List<Task> Tasks = [select Id, Subject, WhoId, LastCallBy__c, ActivityDate, Status from Task where Status = :FilterTaskStatus and OwnerId = :UserInfo.getUserId() and RecordType.Name = 'Study Advise' order by Subject asc, ActivityDate desc nulls last, Who.Name asc limit 1000];
        for(Task task : Tasks)
        {   
            task2Student.put(task.Id, task.WhoId);
        }
        generateContactInformation(task2Student);
        for(Task task : tasks)
        {
            String contactId = task2Student.get(task.Id);
            Contact tempContact = contactMap.get(contactId);
            TaskEntity entity = new TaskEntity();
            entity.taskId = task.Id;
            if(tempContact != null)
            {
                entity.ContactName = tempContact.Name;
                entity.EtownMemberId = (tempContact.EtownMemberId__c == null)? '':String.valueOf(tempContact.EtownMemberId__c);
                entity.Telephone = tempContact.Phone;
                entity.MobilePhone = (tempContact.MobilePhone == null) ? '': tempContact.MobilePhone;
                String lowerCaseCountryCode = (tempContact.CountryCode__c != null)? tempContact.CountryCode__c.toLowerCase(): '';
                if(lowerCaseCountryCode != null && lowerCaseCountryCode.length() > 2)
				{
				    lowerCaseCountryCode = lowerCaseCountryCode.subString(0, 2);
				}
                entity.Country = countryMap.get(lowerCaseCountryCode);
                String lowerCasePreferredLanguage = (tempContact.PreferredLanguage__c != null)? tempContact.PreferredLanguage__c.toLowerCase(): '';
                entity.Language = languageMap.get(lowerCasePreferredLanguage);
                String lowerCaseCorporate = (tempContact.CorporateCode__c != null)? tempContact.CorporateCode__c.toLowerCase(): '';
                entity.Corporate = corporateMap.get(lowerCaseCorporate);
                entity.LocalTime = tempContact.TimeZone__c;
                entity.ContactId = tempContact.Id;
            }
            entity.Subject = task.Subject;
            entity.CalledBy = task.LastCallBy__c;
            entity.DueDate = (task.ActivityDate == null)? null: task.ActivityDate.format();
            TaskEntities.add(entity);
        }
        initialPreviousAndNextPanelParameter();
        getStudentLevelInfoForEtown();
    }
    
    public List<SelectOption> getTaskStatusList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Open', 'Open'));
        options.add(new SelectOption('On-Hold', 'On-Hold'));
        options.add(new SelectOption('Accomplished', 'Accomplished'));
        options.add(new SelectOption('Unaccomplished', 'Unaccomplished'));
        options.add(new SelectOption('Closed by System', 'Closed by System'));
        options.add(new SelectOption('Closed by Manager', 'Closed by Manager'));
        return options;
    }
    
    public void previous()
    {
        startIndex = startIndex - tableSize;
        startIndex = (startIndex < 0)? 0: startIndex;
        if(startIndex > 0)
        {
            PreviousButtonDisplay = true;
        }
        else
        {
            PreviousButtonDisplay = false;
        }
        if(startIndex + tableSize < TaskEntities.size())
        {
            NextButtonDisplay = true;
        }
        getStudentLevelInfoForEtown();
    }
    
    public void next()
    {
        startIndex = startIndex + tableSize;
        if(startIndex + tableSize < TaskEntities.size())
        {
            PreviousButtonDisplay = true;
            NextButtonDisplay = true;
        }
        else
        {
            PreviousButtonDisplay = true;
            NextButtonDisplay = false;
        }
        getStudentLevelInfoForEtown();
    }
    
    private void getStudentLevelInfoForEtown()
    {
        List<String> currentTableMemberIds = getMemberIds();
        if(currentTableMemberIds != null && currentTableMemberIds.size() > 0)
        {
            Map<String, String> levelResultMap = etownService.invokeEtownPersonalInfoWebService(currentTableMemberIds);
            memberId2Level.putAll(levelResultMap); 
            for(TaskEntity entity : tempEntities)
            {   
                if(entity.EtownMemberId != null)
                {
                    entity.Level = (memberId2Level.get(entity.EtownMemberId) == null)? '0': memberId2Level.get(entity.EtownMemberId);
                }
            }
        }
    }
    
    private List<String> getMemberIds()
    {
    	List<String> results = new List<String>();
    	tempEntities = new List<TaskEntity>();
        Integer startEntityIndex = startIndex;
        Integer endIndex;
        if(startEntityIndex + tableSize < TaskEntities.size())
        {
            endIndex = startEntityIndex + tableSize;
        }
        else
        {
            endIndex = TaskEntities.size();
        }
        for(; startEntityIndex < endIndex; startEntityIndex++)
        {
            if(TaskEntities[startEntityIndex].EtownMemberId != null && !memberId2Level.keySet().contains(TaskEntities[startEntityIndex].EtownMemberId))
            {
                results.add(TaskEntities[startEntityIndex].EtownMemberId);
            }
            tempEntities.add(TaskEntities[startEntityIndex]);
        }
        return results;
    }
    
    private void initialPreviousAndNextPanelParameter()
    {
		PreviousButtonDisplay = false;
		if(TaskEntities.size() > tableSize)
		{
		    NextButtonDisplay = true;  
		}
		else
		{
		    NextButtonDisplay = false;
		}
		startIndex = 0;
    }
    
    private void generateContactInformation(Map<String, String> task2Student)
    {
    	if(task2Student != null)
    	{
	        List<Contact> contacts = [select Id, Name, EtownMemberId__c, CorporateCode__c, Phone, CountryCode__c, TimeZone__c, PreferredLanguage__c, MobilePhone from Contact where Id in :task2Student.values()];
	        Set<String> corporateCodeSet = new Set<String>();
	        Set<String> languageCodeSet = new Set<String>();
	        Set<String> countryCodeSet = new Set<String>();
	        for(Contact contact : contacts)
	        {
	            contactMap.put(contact.Id, Contact);
	            corporateCodeSet.add(contact.CorporateCode__c);
	            languageCodeSet.add(contact.PreferredLanguage__c);
	            countryCodeSet.add(contact.CountryCode__c);
	        }
	        createCorporateMap(corporateCodeSet);
	        createLanguageMap(languageCodeSet);
	        createCountryMap(countryCodeSet);
    	}
    }
    
    private void createCorporateMap(Set<String> corporateCodeSet)
    {
    	if(corporateCodeSet != null)
    	{
    	    List<EtownCorporate__c> corporates = [select Id, Name, Code__c from EtownCorporate__c where Code__c in :corporateCodeSet and Code__c != null];
    	    for(EtownCorporate__c corporate : corporates)
    	    {
    	    	if(corporate.Code__c != null && corporate.Code__c != '')
    	    	{
    	    	    corporateMap.put(corporate.Code__c.toLowerCase(), corporate.Name);
    	    	}
    	    }
    	}
    }
    
    private void createLanguageMap(Set<String> languageCodeSet)
    {
        if(languageCodeSet != null)
        {
            List<EtownLanguage__c> languages = [select Id, Name, Code__c from EtownLanguage__c where Code__c in :languageCodeSet and Code__c != null];
            for(EtownLanguage__c language : languages)
            {
            	if(language.Code__c != null && language.Code__c != '')
            	{
            	    languageMap.put(language.Code__c.toLowerCase(), language.Name);
            	}
            }
        }
    }
    
    private void createCountryMap(Set<String> countryCodeSet)
    {
        if(countryCodeSet != null)
        {
            List<EtownCountry__c> countries = [select Id, Name, Code__c from EtownCountry__c where Code__c in :countryCodeSet and Code__c != null];
            for(EtownCountry__c country : countries)
            {
            	if(country.Code__c != null && country.Code__c != '' && country.Code__c.length() == 2)
            	{
            	    countryMap.put(country.Code__c.toLowerCase(), country.Name);
            	}
            }
        }
    }
    
    webservice static List<String> calculateCalledBeforeNumber(String taskIds)
    {
        List<String> results = new List<String>();
        Map<String, Integer> taskId2Count = new Map<String, Integer>();
        if(taskIds != null)
        {
            List<String> taskIdList = taskIds.split(':');
            List<Task> tasks = [select Id, Status, CallId__c, WhoId, ActivityDate from Task where Id in :taskIdList and WhoId != null]; 
            for(Task task : tasks)
            {
                List<AggregateResult> taskResults = [select CallId__c from Task where RecordType.Name = 'Study Advise' and WhoId = :task.WhoId and ActivityDate < :task.ActivityDate and CallId__c != null and CallId__c != :task.CallId__c and Status != 'Closed by System' and Status != 'Closed by Manager' GROUP BY CallId__c];
                Integer calledBeforeCount = taskResults.size();
                taskId2Count.put(task.Id, calledBeforeCount);
            }
            for(String taskId : taskId2Count.keySet())
            {
                results.add(taskId + ':' + taskId2Count.get(taskId));
            }
            for(Task task : [select Id from Task where Id in :taskIdList and WhoId = null])
            {
                results.add(task.Id + ':0');
            }
        }
        return results;
    }
    
    public class ClaimOrAssginAdvisingTaskException extends Exception {}
    
    public class EtownPersonalInfoWebService
    {
        public EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService service = new EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService();        
        
        public EtownPersonalInfoWebService()
        {
			//EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService service = new EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService();
            service.timeout_x = 60 * 1000 * 2;
	        service.Security = new EtownStudyAdvisorIdentityValidation.Security_element();
	        service.Security.UsernameToken = new EtownStudyAdvisorIdentityValidation.UsernameToken_element();
	        service.Security.UsernameToken.Username = 'SalesForceUser';
	        service.Security.UsernameToken.Password = 'WsFerS12';
        }
        
        public Map<String, String> invokeEtownPersonalInfoWebService(List<String> etowmMemberIds)
        {
        	Map<String, String> resultMap = new Map<String, String>();
        	String memberIdString = generateMemberIdString(etowmMemberIds);
            // Invoker service.
            if(memberIdString != null || memberIdString != '')
            {
                EtownStudyAdvisorDataContract.GetCurrentLevelResult result;
                try
                {
                    result = service.GetCurrentLevel(memberIdString);
                    if(result.Succeeded)
                    {
                        for(EtownStudyAdvisorDataContract.CurrentLevelInfo levelInfo : result.CurrentLevelInfoList.CurrentLevelInfo)
						{
						    if(levelInfo.MemberId != null && levelInfo.CurrentLevel != null)
						    {
						        resultMap.put(String.valueOf(levelInfo.MemberId), levelInfo.CurrentLevel);
						    }
						}
                    }
                }
                catch(Exception ex){}
            }
            return resultMap;
        }
        
        private String generateMemberIdString(List<String> memberIds)
        {
        	String result = '';
            if(memberIds != null && memberIds.size() > 0)
            {
            	Integer memberIdsSize = memberIds.size();
            	for(Integer i = 0; i < memberIdsSize; i++)
            	{
            	    if(i == (memberIdsSize - 1))
            	    {
            	        result = result + memberIds[i];
            	    }
            	    else
            	    {
            	        result = result + memberIds[i] + ',';
            	    }
            	}
            }
            return result;
        }
    }
    
    public class TaskEntity
    {
        public String Subject {get; set;}
        public String taskId {get; set;}
        public String ContactName {get; set;}
        public String ContactId {get; set;}
        public String EtownMemberId {get; set;}
        public String CalledBy {get; set;}
        public String DueDate {get; set;}
        public String Telephone {get; set;}
        public String MobilePhone {get; set;}
        public String Country {get; set;}
        public String Level {get; set;}
        public String LocalTime 
        {
            get
            {
                return generateLocalTime(timeZone);
            } 
            set
            {
                timeZone = value;
            }
        }
        public String Corporate {get; set;}
        public String Language {get; set;}
        public String Status {get; set;}
        private String timeZone;
        
        public String generateLocalTime(String timezone)
        {
            String result = '';
            if(timezone != null && timezone.length() >= 10)
            {   
                String subTimeZone = timezone.substring(4, 10); 
                Integer hours = getHours(subTimeZone);
                Integer minutes = getMinutes(subTimeZone);
                Datetime gmtDatetime = Datetime.now();
                if(subTimeZone.startsWith('-'))
                {
                    Datetime tempLocaltime = gmtDatetime.addMinutes(0 - (60 * hours + minutes));
                    result = formatDatetime(tempLocaltime);
                }
                else if(subTimeZone.startsWith('+'))
                {
                    Datetime tempLocaltime = gmtDatetime.addMinutes(60 * hours + minutes);
                    result = formatDatetime(tempLocaltime);
                }
            }
            return result; 
        }
        
        private String formatDatetime(Datetime localDatetime)
        {
            String year = String.valueOf(localDatetime.year());
            String month = String.valueOf(localDatetime.month());
            String day = String.valueOf(localDatetime.day());
            String hour = String.valueOf(localDatetime.hourGmt());
            String minute = String.valueOf(localDatetime.minuteGmt());
            month = (month.length() == 1)? '0' + month: month;
            day = (day.length() == 1)? '0' + day : day;
            hour = (hour.length() == 1)? '0' + hour : hour;
            minute = (minute.length() == 1)? '0' + minute : minute;
            return day + '/' + month + '/' + year + ' ' + hour + ':' + minute;
        }
        
        private Integer getHours(String timeZoneValue)
        {
            Integer result;
            String hours = timeZoneValue.substring(1, 3);
            if(hours.startsWith('0'))
            {
                hours = hours.substring(1);
            }
            result = Integer.valueOf(hours);
            return result;
        }
        
        private Integer getMinutes(String timeZoneValue)
        {
            Integer result;
            String minutes = timeZoneValue.substring(4);
            if(minutes.startsWith('0'))
            {
                minutes = minutes.substring(1);
            }
            result = Integer.valueOf(minutes);
            return result;
        }
    }
    
    @isTest
    static void testStudyAdviseTaskListController()
    {
        Account testAccount1 = new Account(Name = 'test account');
        Account testAccount2 = new Account(Name = 'test account2');
        insert new List<Account>{testAccount1, testAccount2};
        Contact testContact1 = new Contact(Lastname = 'test last name', EtownMemberId__c = 987877699, AccountId = testAccount1.Id, PreferredLanguage__c = 'en', CountryCode__c = 'it', Timezone__c = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)');
        Contact testContact2 = new Contact(Lastname = 'test last name2', EtownMemberId__c = 987877693, AccountId = testAccount2.Id);
        insert new List<Contact>{testContact1, testContact2};
        String advisorTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        Task task1 = new Task(RecordTypeId = advisorTaskRecordTypeId, Subject = 'Test task1', ActivityDate = Date.today().addDays(-3), WhatId = testAccount1.Id, Status = 'Open', WhoId = testContact1.Id, OwnerId = UserInfo.getUserId());
        Task task2 = new Task(RecordTypeId = advisorTaskRecordTypeId, Subject = 'Test task2', ActivityDate = Date.today().addDays(-2), WhatId = testAccount2.Id, Status = 'Open', WhoId = testContact2.Id, OwnerId = UserInfo.getUserId());
        insert new List<Task>{task1, task2};
        Task task3 = new Task(RecordTypeId = advisorTaskRecordTypeId, Subject = 'Test task3', ActivityDate = Date.today().addDays(1), WhatId = testAccount1.Id, Status = 'Open', WhoId = testContact1.Id, OwnerId = UserInfo.getUserId());
        Task task4 = new Task(RecordTypeId = advisorTaskRecordTypeId, Subject = 'Test task4', ActivityDate = Date.today().addDays(2), WhatId = testAccount2.Id, Status = 'Open', WhoId = testContact2.Id, OwnerId = UserInfo.getUserId());
        insert new List<Task>{task3, task4};
        StudyAdviseTaskListController controller = new StudyAdviseTaskListController();
        TaskEntity entity = controller.TaskEntities[0];
        entity.LocalTime = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)';
        String localTime = entity.LocalTime;
        System.assertNotEquals(null, localTime);
        controller.getTaskStatusList();
        StudyAdviseTaskListController.calculateCalledBeforeNumber(task4.Id);
        controller.previous();
        controller.next();
    }
}