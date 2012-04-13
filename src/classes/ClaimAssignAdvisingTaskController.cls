/*
*  This class for Claim and Assign page.
*/
global class ClaimAssignAdvisingTaskController 
{
    public FilterCondition Condition {get; set;}
    public List<TaskEntity> TaskEntities {get; set;}
    public Task StartDateTask {get; set;}
    public Task EndDateTask {get; set;}
    public Boolean IsSAManageer {get; set;}
    public Boolean IsSystemAdmin {get; set;}
    public Boolean IsSAuser {get; set;}
    public Boolean DisplayButton {get; set;}
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
            return 100;
        }
    }
    public Integer startIndex {get; set;}
    public Boolean PreviousButtonDisplay {get; set;}
    public Boolean NextButtonDisplay {get; set;}
    public Integer pageNumber {get; set;}
    public Integer pageSize {get; set;}
    private String studyAdviseTaskRecordTypeId;
    
    public ClaimAssignAdvisingTaskController()
    {
        Condition = new FilterCondition();
        TaskEntities = new List<TaskEntity>();
        StartDateTask = new Task();
        EndDateTask = new Task();
        User currentUser = [select Id, Profile.Name from User where Id = :UserInfo.getUserId()];
        studyAdviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        String profileName = currentUser.Profile.Name;
        String profileNameLower = (profileName == null)? '': profileName.toLowerCase();
        if(profileName == 'Englishtown study advisor manager' || profileName == 'Englishtown Study advisor admin')
        {
            IsSAManageer = true;
        }
        else if(profileName == 'Englishtown Study Advisor')
        {
            IsSAuser = true;
        }
        else if(profileNameLower.contains('system administrator'))
        {
            IsSystemAdmin = true;
        }
    }
    
    public void previous()
    {
        startIndex = startIndex - tableSize;
        pageNumber = pageNumber - 1;
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
    }
    
    public void next()
    {
        startIndex = startIndex + tableSize;
        pageNumber = pageNumber + 1;
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
    }
    
    public void toFirstPage()
	{
	    startIndex = 0;
	    pageNumber = 1;
	    PreviousButtonDisplay = false;
	    if(startIndex + tableSize < TaskEntities.size())
        {
            NextButtonDisplay = true;
        }
	}
	
	public void toLastPage()
	{
	    if(TaskEntities.size() > tableSize)
	    {
	        Integer modNumber = Integer.valueOf(Math.mod(TaskEntities.size(), tableSize));
	        if(modNumber == 0)
	        {
	            startIndex = TaskEntities.size() - tableSize;
	        }
	        else
	        {
	           startIndex = TaskEntities.size() - modNumber;
	        }
	        pageNumber = pageSize;
	        NextButtonDisplay = false;
	        PreviousButtonDisplay = true;
	    }
	}
    
    public void searchRecordWithFliterCondition()
    {
        TaskEntities.clear();
        DisplayButton = false;
        startIndex = 0;
        pageNumber = 1;
        pageSize = 1;
        PreviousButtonDisplay = false;
        NextButtonDisplay = true;
        Set<String> contactIdSet = new Set<String>();
        String taskQuery = generateTaskQuery(); 
        List<Sobject> taskList = Database.query(taskQuery);
        for(Sobject task : taskList)
        {
            Task tempTask = (Task)task;
            contactIdSet.add(tempTask.WhoId);
        }
        List<Contact> contactList = [select Id, Name, Email, CorporateCode__c, Phone, CountryCode__c, TimeZone__c, PreferredLanguage__c from Contact where Id in :contactIdSet];
        Map<String, Contact> contactMap = new Map<String, Contact>();
        for(Contact student : contactList)
        {
            contactMap.put(student.Id, student);
        }
        for(Sobject task : taskList)
        {
            Task tempTask = (Task)task;
            TaskEntity entity = new TaskEntity();
            entity.IsSelected = false;
            entity.CalledBy = tempTask.LastCallBy__c;
            entity.DueDate = (tempTask.ActivityDate == null)? null: tempTask.ActivityDate.format();
            entity.Status = tempTask.status;
            entity.TaskId = tempTask.Id;
            entity.ContactId = tempTask.WhoId;
            entity.OwnerName = tempTask.Owner.Name;
            String lowerCaseCountryCode = (tempTask.Country__c != null)? tempTask.Country__c.toLowerCase(): '';
            if(lowerCaseCountryCode != null && lowerCaseCountryCode.length() > 2)
            {
                lowerCaseCountryCode = lowerCaseCountryCode.subString(0, 2);
            }
            entity.Country = condition.countryMap.get(lowerCaseCountryCode);
            String lowerCaseCorporate = (tempTask.Corporate__c != null)? tempTask.Corporate__c.toLowerCase(): '';
            entity.Corporate = condition.corporateMap.get(lowerCaseCorporate);
            String lowerCasePreferredLanguage = (tempTask.Language__c != null)? tempTask.Language__c.toLowerCase(): '';
            entity.Language = condition.languageMap.get(lowerCasePreferredLanguage);

            Contact tempContact = contactMap.get(tempTask.WhoId);
            if(tempContact != null)
            {
                entity.ContactName = tempContact.Name;
                entity.ContactEmail = tempContact.Email;
                entity.Telephone = tempContact.Phone;
                entity.LocalTime = tempContact.TimeZone__c;
            } 
            TaskEntities.add(entity);
        }
        if(TaskEntities.size() > 0)
        {
        	DisplayButton = true;
            if(TaskEntities.size() > tableSize)
            {
                pageSize = Integer.valueOf(Math.ceil(Double.valueOf(TaskEntities.size())/Double.valueOf(tableSize)));
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No result found.'));
        }
    }
    
    public String generateTaskQuery()
    {
        String taskQuery = 'select Id, WhoId, LastCallBy__c, ActivityDate, Status, OwnerId, Owner.Name, Country__c, Corporate__c, Language__c from Task where WhoId != null and IsClosed = false ';
        String startDate = formatQueryStringDate(StartDateTask.ActivityDate);
        String endDate = formatQueryStringDate(EndDateTask.ActivityDate);
        if(StartDateTask.ActivityDate != null)
        {
            taskQuery += 'and ActivityDate >= ' + startDate + ' ';
        }
        if(EndDateTask.ActivityDate != null)
        {
            taskQuery += 'and ActivityDate <= ' + endDate + ' ';
        }
        if(Condition.CallType != null && Condition.CallType != '')
        {
            taskQuery += 'and CallType = \'' + Condition.CallType + '\' ';
        }
        if(Condition.Subject != null && Condition.Subject != '')
        {
            taskQuery += 'and Subject like \'%'+ Condition.Subject +'%\' ';
        }
        if(Condition.Status != null && Condition.Status != '')
        {
            taskQuery += 'and Status = \'' + Condition.Status + '\' ';
        }
        if(Condition.AssignTo != null && Condition.AssignTo != '')
        {
            taskQuery += 'and OwnerId = \'' + Condition.AssignTo + '\' ';
        }
        if(Condition.AttemptNumber != null && Condition.AttemptNumber != 'All')
        {
            taskQuery += 'and Attempt__c = ' + Condition.AttemptNumber + ' ';
        }
        if(Condition.Corporate != null && Condition.Corporate != '')
        {
            taskQuery += 'and Corporate__c = \'' + Condition.Corporate + '\' ';
        }
        if(Condition.Country != null && Condition.Country != '')
        {
            taskQuery += 'and Country__c like \'' + Condition.Country + '%\' ';
        }
        if(Condition.Division != null && Condition.Division != '')
        {
            taskQuery += 'and Division__c = \'' + Condition.Division + '\' ';
        }
        if(Condition.Language != null && Condition.Language != '')
        {
            taskQuery += 'and Language__c = \'' + Condition.Language + '\' ';
        }
        if(Condition.TimeZone != null && Condition.TimeZone != '')
        {
            taskQuery += 'and TimeZone__c = \'' + Condition.TimeZone + '\' ';
        }
        taskQuery += 'and RecordTypeId = \'' + studyAdviseTaskRecordTypeId + '\' order by ActivityDate limit 1000';
        return taskQuery;
    }
    
    private String formatQueryStringDate(Date dateValue)
    {
        String result = '';
        if(dateValue != null)
        {
            String year = String.valueOf(dateValue.year());
            String month = String.valueOf(dateValue.month());
            String day = String.valueOf(dateValue.day());
            month = (month.length() == 1)? '0' + month: month;
            day = (day.length() == 1)? '0' + day : day;
            result = year + '-' + month + '-' + day;
        }
        return result;
    }
    
    public PageReference closeTask()
    {
        try
        {
            
            changeTaskStatus('Closed by Manager', 'Tasks are successfully closed.');
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
     
    public PageReference assginTask()
    {
        try
        {
            if(condition.Assignee == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No "Assign to" is selected.'));
                return null;
            }
            changeTaskOwner(condition.Assignee, 'Tasks are successfully assigned.');
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    private void changeTaskOwner(String userId, String message)
    {
        if(TaskEntities.size() != null && TaskEntities != null)
        {
            List<Task> taskUpdatedList = new List<Task>();
            for(TaskEntity entity : TaskEntities)
            {
                if(entity.IsSelected)
                {
                    taskUpdatedList.add(new Task(Id = entity.taskId, OwnerId = userId));
                }
            }
            if(taskUpdatedList.size() > 0)
            {
                update taskUpdatedList;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select a record.'));
            }
        }
    }
    
    private void changeTaskStatus(String taskStatus, String message)
    {
        if(TaskEntities.size() != null && TaskEntities != null)
        {
            List<Task> taskUpdatedList = new List<Task>();
            List<TaskEntity> remainTasks = new List<TaskEntity>();
            for(TaskEntity entity : TaskEntities)
            {
                if(entity.IsSelected)
                {
                    taskUpdatedList.add(new Task(Id = entity.taskId, Status = taskStatus));
                }
                else
                {
                    remainTasks.add(entity);
                }
            }
            if(taskUpdatedList.size() > 0)
            {
                update taskUpdatedList;
                startIndex = 0;
                PreviousButtonDisplay = false;
                NextButtonDisplay = true;
                TaskEntities = remainTasks;
                pageNumber = 1;
                if(TaskEntities.size() > tableSize)
	            {
	                pageSize = Integer.valueOf(Math.ceil(Double.valueOf(TaskEntities.size())/Double.valueOf(tableSize)));
	            }
	            else
	            {
	                pageSize = 1;
	            }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Please select a record.'));
            }
        }
    }
     
    public class FilterCondition
    {
        public String Corporate {get; set;}
        public String Division {get; set;}
        public String Status {get; set;}
        public String CallType {get; set;}
        public String Subject {get; set;}
        public String Country {get; set;}
        public String TimeZone {get; set;}
        public String Language {get; set;}
        public String Assignee {get; set;}
        public String CalledBy {get; set;}
        public String AssignTo {get; set;}
        public String AttemptNumber {get; set;}
        private Map<String, String> corporateMap = new Map<String, String>();
        private Map<String, String> languageMap = new Map<String, String>();
        private Map<String, String> countryMap = new Map<String, String>();
        private List<SelectOption> divisionOptions = new List<SelectOption>();
        
        public FilterCondition(){}
        
        public List<SelectOption> getAssignToUsers()
        {
            List<User> advisors = [select Id, Name from User where IsActive = true and (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown study advisor manager') order by Name];
            List<SelectOption> options = new List<SelectOption>{new SelectOption('', '--Assign To--')};
            if(advisors.size() > 0)
            {
                for(User user : advisors)
                {
                   options.add(new SelectOption(user.Id, user.Name));
                }
            }
            return options;
        }
        
        //Pony Ma 2012-01-12 fix issue - list too long(>1000)
        public List<List<SelectOption>> getCorprateLists(){
        	List<SelectOption> lstOption=getCorprateList();
        	system.debug(lstOption.size());
        	
        	List<List<SelectOption>> lstOptionList=new List<List<SelectOption>>();
        	List<SelectOption> temp=new List<SelectOption>();
        	for(SelectOption op:lstOption){
        		if(temp.size()==500){
        			lstOptionList.add(temp);
        			temp=new List<SelectOption>();	
        		}
        		temp.add(op);		
        	}
        	if(temp.size()>0) lstOptionList.add(temp);
        	return lstOptionList;  	
        }
        
        public List<SelectOption> getCorprateList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Corporate--'));
            List<EtownCorporate__c> corporates = [select Id, Name, Code__c from EtownCorporate__c order by Name];
            for(EtownCorporate__c corporate : corporates)
            {
                if(corporate.Code__c != null && corporate.Code__c != '')
                {   
                    options.add(new SelectOption(corporate.Code__c, corporate.Name));
                    corporateMap.put(corporate.Code__c.toLowerCase(), corporate.Name);
                }
            }
            return options;
        }
        
        public PageReference buildDivisionList()
        {
            divisionOptions = new List<SelectOption>();
            divisionOptions.add(new SelectOption('', '--Division--'));
            List<EtownDivision__c> divisions = [select Id, Name, Code__c from EtownDivision__c where CorporateCode__c = :Corporate and CorporateCode__c != null order by Name];
            for(EtownDivision__c division : divisions)
            {
                if(division.Code__c != null && division.Code__c != '')
                {
                    divisionOptions.add(new SelectOption(division.Code__c, division.Name));
                }
            }
            return null;
        }
        
        public List<SelectOption> getDivisionList()
        {
            if(divisionOptions == null || divisionOptions.size() == 0)
            {
                divisionOptions.add(new SelectOption('', '--Division--'));
            }
            return divisionOptions;
        }
        
        public List<SelectOption> getAttemptList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Attempt--'));
            options.add(new SelectOption('All', 'All'));
            options.add(new SelectOption('1', '1'));
            options.add(new SelectOption('2', '2'));
            options.add(new SelectOption('3', '3'));
            return options;
        }
        
        public List<SelectOption> getStatusList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Status--'));
            options.add(new SelectOption('Open', 'Open'));
            options.add(new SelectOption('On-Hold', 'On-Hold'));
            return options;
        }
          
        public List<SelectOption> getCallTypeList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Call Type--'));
            Schema.Describefieldresult fieldResult = Task.CallResult__c.getDescribe();
            List<Schema.Picklistentry> picklistEntries = fieldResult.getPicklistValues();
            for(Schema.Picklistentry entry : picklistEntries)
            {
                options.add(new SelectOption(entry.getValue(), entry.getValue()));
            }
            return options;
        }
        
        public List<SelectOption> getTimezoneList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Timezone--'));
            Schema.Describefieldresult fieldResult = Contact.TimeZone__c.getDescribe();
            List<Schema.Picklistentry> picklistEntries = fieldResult.getPicklistValues();
            for(Schema.Picklistentry entry : picklistEntries)
            {
                options.add(new SelectOption(entry.getValue(), entry.getValue()));
            }
            return options;
        }
        
        public List<SelectOption> getCountryList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Country--'));
            List<EtownCountry__c> countries = [select Id, Name, Code__c from EtownCountry__c order by Name];
            for(EtownCountry__c country : countries)
            {
                if(country.Code__c != null && country.Code__c != '' && country.Code__c.length() == 2)
                {
                    options.add(new SelectOption(country.Code__c, country.Name));
                    countryMap.put(country.Code__c.toLowerCase(), country.Name);
                }
            }
            return options;
        }
        
        public List<selectOption> getLanguageList()
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', '--Language--'));
            List<EtownLanguage__c> languages = [select Id, Name, Code__c from EtownLanguage__c order by Name];
            for(EtownLanguage__c language : languages)
            {
                if(language.Code__c != null && language.Code__c != '')
                {
                    options.add(new SelectOption(language.Code__c, language.Name));
                    languageMap.put(language.Code__c.toLowerCase(), language.Name);
                }
            }
            return options;
        }
    }
    
    public class TaskEntity
    {
        public Boolean IsSelected {get; set;}
        public String taskId {get; set;}
        public String ContactName {get; set;}
        public String ContactEmail {get; set;}
        public String ContactId {get; set;}
        public String CalledBy {get; set;}
        public String DueDate {get; set;}
        public String Telephone {get; set;}
        public String Country {get; set;}
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
        public String OwnerName {get; set;}
        private String timeZone;
        
        public String generateLocalTime(String timezone)
        {
            String result = '';
            if(timezone != null && timezone.length() >= 10)
            {
                String subTimeZone = timezone.substring(4, 10); // result like this -04:30
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
            String year = String.valueOf(localDatetime.yearGmt());
            String month = String.valueOf(localDatetime.monthGmt());
            String day = String.valueOf(localDatetime.dayGmt());
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
    
    webservice static List<String> calculateCalledBeforeNumber(String taskIds)
    {
        List<String> results = new List<String>();
        Map<String, Integer> taskId2Count = new Map<String, Integer>();
        if(taskIds != null)
        {
            List<String> taskIdList = taskIds.split(':');
            List<Task> tasks = [select Id, WhoId, Status, CallId__c, ActivityDate from Task where Id in :taskIdList and WhoId != null]; 
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
        }
        return results;
    } 
    
    public class ClaimOrAssginAdvisingTaskException extends Exception {}
    
    @isTest
    static void testClaimAssignAdvisingTaskController()
    {
        Account testAccount = new Account(Name = 'Test Account Name');
        insert testAccount;
        Contact testContact = new Contact(Lastname = 'last name', AccountId = testAccount.Id, Timezone__c = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)');
        insert testContact;
        Id studyAdviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        Task testTask = new Task(RecordTypeId = studyAdviseTaskRecordTypeId);
        testTask.ActivityDate = Date.today();
        testTask.WhoId = testContact.Id;
        testTask.Subject = 'This is test Task';
        testTask.Status = 'Open';
        testTask.Attempt__c = 1;
        insert testTask;
        ClaimAssignAdvisingTaskController controller = new ClaimAssignAdvisingTaskController();
        controller.Condition.Subject = 'This is test Task';
        User saUser1 = [select Id from User where Profile.Name = 'Englishtown Study Advisor' and IsActive = true limit 1];
        controller.Condition.Assignee = saUser1.Id;
        controller.Condition.Status = 'Open';
        controller.Condition.AttemptNumber = '1';
        controller.Condition.getTimezoneList();
        controller.Condition.getCallTypeList();
        controller.Condition.getCountryList();
        controller.Condition.getTimezoneList();
        controller.Condition.getStatusList();
        controller.searchRecordWithFliterCondition();
        controller.Condition.buildDivisionList();
        controller.Condition.getDivisionList();
        controller.Condition.getAttemptList();
        controller.closeTask();
        controller.assginTask();
        controller.next();
        controller.previous();
        controller.toFirstPage();
        controller.toLastPage();
        ClaimAssignAdvisingTaskController.FilterCondition condition = new ClaimAssignAdvisingTaskController.FilterCondition();
        controller.Condition = condition;
        controller.StartDateTask.ActivityDate = Date.today().addDays(-3);
        controller.EndDateTask.ActivityDate = Date.today().addDays(6);
        condition.CallType = 'Call Type';
        condition.Subject = 'Subject';
        condition.Status = 'Open';
        condition.AssignTo = 'AssignTo';
        condition.AttemptNumber = 'All';
        String taskQuery = controller.generateTaskQuery();
        condition.Corporate = 'Corporate';
        condition.Country = 'Country';
        condition.Division = 'Division';
        condition.Language = 'English';
        condition.TimeZone = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)';
        condition.getLanguageList();
        condition.getAssignToUsers();
        ClaimAssignAdvisingTaskController.TaskEntity testTaskEntity = new ClaimAssignAdvisingTaskController.TaskEntity();
        testTaskEntity.CalledBy = 'test user 2';
        testTaskEntity.ContactName = 'test name';
        testTaskEntity.ContactEmail = 'test email';
        testTaskEntity.Corporate = 'ibm';
        testTaskEntity.Country = 'cn';
        testTaskEntity.IsSelected = true;
        testTaskEntity.Language = 'cn';
        testTaskEntity.Status = 'Open';
        testTaskEntity.taskId = testTask.Id;
        testTaskEntity.Telephone = '5051221';
        testTaskEntity.TimeZone = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)';
        String testLocalTime = testTaskEntity.LocalTime;
        ClaimAssignAdvisingTaskController.calculateCalledBeforeNumber(testTask.Id + ':dfdfdfdfd');
    }
}