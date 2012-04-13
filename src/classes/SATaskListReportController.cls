/*
 * this controller is used to render task list in page "SATaskListReport"
 */
public class SATaskListReportController
{    
    private transient List<Task> allTasks;
    private Map<String, String> contactId2Name; // key:contact Id, value: contact name.
    private static Map<Boolean, Integer> isTestMethod2SelectLimit = new Map<Boolean, Integer>{ true => 20, false => 50000};  // keyWord: Test.isRunningTest()
    private String queryString; // store danymic soql
    private Integer PageSize = 50;
    
    public SATaskListReportController()
    {
        CurrentPageIndex = 1;
        PageCount = 1;
        allTasks = new List<Task>();
        contactId2Name = new Map<String, String>();
    }
    
    public List<TaskInfo> Tasks { get; set; }
    public Integer PageCount { get; set; }
    public String StatusItem { get; set; }
    public String SAItem { get; set; }
    public String CountryItem { get; set; }
    public String LanguageItem { get; set; }
    public String CorporateItem { get; set; }    
            
    public List<SelectOption> CountryItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('',' '));            
            for(EtownCountry__c country : [select Id, Name, Code__c from EtownCountry__c where Code__c != null order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {
                if(country.Code__c.length() == 2)
                {
                    options.add(new SelectOption(country.Code__c, country.Name));
                }
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
            for(EtownLanguage__c language : [select Id, Name, Code__c from EtownLanguage__c where Code__c != null order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {
                options.add(new SelectOption(language.Code__c, language.Name));
            }
            return options;
        }
    }
    
    public List<SelectOption> CorporateItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', ' '));
            for(EtownCorporate__c corporate : [select Id, Name, Code__c from EtownCorporate__c where Code__c != null order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {
                options.add(new SelectOption(corporate.Code__c, corporate.Name));
            }          
            return options;
        }
    }
    
    //Vason 2012-01-13 fix issue - list too long(>1000)
    public List<List<SelectOption>> CorprateLists
    {
    	get
    	{
	    	List<SelectOption> lstOption = CorporateItems;
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
    }
    
    public List<SelectOption> SAItems
    {
        get
        {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('', ' '));
            for(User usr : [select Id, Name from User where (Profile.Name='Englishtown Study Advisor' or Profile.Name='Englishtown Study Advisor Manager') and IsActive=true order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {               
                options.add(new SelectOption(usr.Id, usr.Name));
            }        
            return options;
        }
    } 
    
    private String formulateQueryString()
    {
        Integer maxLimit = (Test.isRunningTest() == true)? 20 : 3000; // used to reduce the SOQL numbers.
        String result = 'select Id, WhoId, ActivityDate, LastModifiedDate, Status, Corporate__c, Country__c, Language__c from Task where RecordType.Name=\'Study Advise\' ';
        result += (StatusItem == null || StatusItem == '')? '': ' and Status=\'' + StatusItem + '\' ';
        result += (SAItem == null || SAItem == '')? '': ' and OwnerId=\'' + SAItem + '\' ';
        result += (CountryItem == null || CountryItem == '')? '': ' and Country__c=\'' + CountryItem + '\' ';
        result += (LanguageItem == null || LanguageItem == '')? '': ' and Language__c=\'' + LanguageItem + '\' ';
        result += (CorporateItem == null || CorporateItem == '')? '': ' and Corporate__c=\'' + CorporateItem + '\' ';
        result += ' order by LastModifiedDate limit ' + maxLimit;
        return result;
    }
    
    // pagination in table.
    public Integer CurrentPageIndex { get; set; }
    public String PageIndexShow 
    { 
        get
        {
            return (PageCount == 0)? '': '(' + CurrentPageIndex + ' / ' + PageCount + ')';
        }
    }
    
    public PageReference previous()
    {
        if(CurrentPageIndex > 1)
        {
            CurrentPageIndex--;           
        }
        fillTasks();
        return null;
    }
        
    public PageReference next()
    {
        if(CurrentPageIndex < PageCount)
        {
            CurrentPageIndex++;
        }
        fillTasks();
        return null;
    }

    public PageReference search()
    {           
        CurrentPageIndex = 1;
        fillTasks();
        return null;
    }
    
    private void fillTasks()
    {
        queryString = formulateQueryString();
        List<sObject> taskList = Database.query(queryString); 
        PageCount = Math.ceil(taskList.size() * 1.0 / PageSize).intValue();
        Tasks = new List<TaskInfo>();
        for(Integer i = (CurrentPageIndex - 1) * PageSize; i < CurrentPageIndex * PageSize && i < taskList.size(); i++)
        {
            Tasks.add(new TaskInfo((Task)taskList[i]));
        }
        refreshContactName();
    }
    
    private void refreshContactName()
    {
        Set<Id> contactIds = new Set<Id>();
        for(TaskInfo task : Tasks)
        {
            contactIds.add(task.ContactId);
        }
        Map<Id, String> contactId2Name = new Map<Id, String>();
        for(Contact contact :[select Id, Name from Contact where Id in :contactIds])
        {
            contactId2Name.put(contact.Id, contact.Name);
        }
        for(TaskInfo task : Tasks)
        {
            if(contactId2Name.containsKey(task.ContactId))
            {
                task.ContactName = contactId2Name.get(task.ContactId);
            }
        }
    }
    public class TaskInfo
    {
        private Task tsk;
        
        public TaskInfo(Task task)
        {
            tsk = task;
            this.TaskId = tsk.Id;
            this.ContactId = tsk.WhoId;
            this.ActivityDate = tsk.ActivityDate;
            this.CompleteDate = tsk.LastModifiedDate.date();
            this.Status = (tsk.Status == null)? '': tsk.Status;
            this.Corporate = (tsk.Corporate__c == null)? '': tsk.Corporate__c;
            this.Country = (tsk.Country__c == null)? '': tsk.Country__c;
            this.Language = (tsk.Language__c == null)? '': tsk.Language__c;            
        }
        
        public String TaskId { get; set; }
        public String ContactId { get; set; }
        public String ContactName { get; set; }
        public Date ActivityDate { get; set; }
        public Date CompleteDate { get; set; }
        public String Status { get; set; }
        public String Corporate { get; set; }
        public String Country { get; set; }
        public String Language { get; set; } 
    }
    
    @isTest
    static void testSATaskListReportController()
    {
        //create data.
        List<String> callResult = new List<String>{'Accomplished', 'Closed by System', 'Closed by Manager', 'On-Hold', 'Open', 'Unaccomplished'};
        EtownLanguage__c language = new EtownLanguage__c(Code__c='en_us', Name='English');
        insert language;
        EtownCountry__c country = new EtownCountry__c(Code__c='ame', Name='America');
        insert country;
        List<User> testAllSA = [select Id, Name from User where (Profile.Name='EnglishTown Study Advisor' or Profile.Name='EnglishTown Study Advisor Manager') and IsActive=true order by Name];
        List<Account> testAccounts  = new List<Account>{
                                                    new Account(Name='acme1'),
                                                    new Account(Name='acme2'),
                                                    new Account(Name='acme3')};
        insert testAccounts;
        List<Contact> testContacts = new List<Contact>{
                                                    new Contact(Lastname = 'test contact1', AccountId = testAccounts[0].Id),
                                                    new Contact(Lastname = 'test contact3', AccountId = testAccounts[1].Id),
                                                    new Contact(Lastname = 'test contact2', AccountId = testAccounts[2].Id)};
        insert testContacts;
        String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType='Task' limit 1].Id;
        List<Task> testTasks = new List<Task>();
        for(Integer i = 0; i < testAllSA.size(); i++)
        {
            testTasks.add(new Task(OwnerId=testAllSA[i].Id, WhoId=testContacts[Math.mod(i, 3)].Id, Status=callResult[Math.mod(i, 6)], RecordTypeId=recTypeId, ActivityDate=Date.today().addDays(-1)));
        }
        testTasks.add(new Task(OwnerId=testAllSA[0].Id, WhoId=testContacts[0].Id, Status=callResult[0], RecordTypeId=recTypeId, ActivityDate=Date.today(), Language__c=language.Code__c, Country__c=country.Code__c));
        insert testTasks;
        //test logic.
        SATaskListReportController controller = new SATaskListReportController();
        System.assert(controller.SAItems != null);
        System.assert(controller.CountryItems != null);
        System.assert(controller.LanguageItems != null);
        System.assert(controller.CorporateItems != null);
        System.assert(controller.PageIndexShow != null);
        controller.search();
        controller.previous();
        controller.next();
    }
}