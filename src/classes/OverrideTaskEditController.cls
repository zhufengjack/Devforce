/*
*  This controller for Override Task Edit page.
*/
public class OverrideTaskEditController 
{
    public Task CurrentTask { get; set; }
    public Task TempTask { get; set; }
    public String TaskStatus 
    {
        get
        {
            return CurrentTask.Status;
        }
        set
        {
            CurrentTask.Status = value;
        }
    }
    public String TaskCallResult { get; set; }
    public String EmailMessageBoday { get; set; }
    public Boolean ShowCloseButton { get; set; }
    public Contact Student { get; set; }
    public Boolean IsAdminOrManager { get; set; }
    public Boolean IsClosedTask { get; set; }
    public Boolean SendEmail { get; set; }
    private Set<String> accomplishedStatusSet = new Set<String>{'Successfully discussed study', 'Chatted but not about study'};
    private Set<String> unaccomplishedStatusSet = new Set<String>{'Requested call back', 'Hang up', 'Disconnected', 'Out of office', 'No answer'};
    private Set<String> onHoldStatusSet = new Set<String>{'Left company', 'Invalid number'};
    private static String advisorTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
    private EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService service = new EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService();

    public OverrideTaskEditController(ApexPages.StandardController controller)
    {
        try
        {
            initializeService();
            SendEmail = true;
            User currentUser = [select Id, Profile.Name from User where Id = :UserInfo.getUserId()];
            String profileName = currentUser.Profile.Name;
            profileName = (profileName == null)? '': profileName.toLowerCase();
            if(profileName == 'englishtown study advisor admin' || profileName == 'englishtown study advisor manager' || profileName.contains('system administrator'))
            {
                IsAdminOrManager = true;
            }
            else
            {
                IsAdminOrManager = false;
            }
            String taskId = controller.getId();
            ShowCloseButton = false;
            tempTask = new Task(RecordTypeId = advisorTaskRecordTypeId);
            List<Task> tasks = [select Id, Subject, WhoId, Attempt__c, IsClosed, ActivityDate, CallResult__c, CallId__c, Status, Description, RecordType.Name, OwnerId from Task where Id = :taskId];
            if(tasks.size() > 0) 
            {
                currentTask = tasks[0]; 
                if(tasks[0].IsClosed)
                {
                    IsClosedTask = true;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'This task has been closed. You can\'t edit it now.'));
                }
                tempTask.ActivityDate = Date.today().addDays(30);
                List<Contact> contacts = [select Id, FirstName, LastName, Name, EtownMemberId__c, Email, Phone, CountryCode__c, PartnerCode__c, PreferredLanguage__c, CorporateCode__c, AccountId, DivisionCode__c, TimeZone__c from Contact where Id = :tasks[0].WhoId];
                if(contacts.size() > 0)
                {
                    student = contacts[0];
                }
                else
                {
                    throw new ProcessAdvisorTaskException('No student related to this task.');
                }
            }
            else
            {
                throw new ProcessAdvisorTaskException('Invalid task id.'); 
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    private void initializeService()
    {
        service.timeout_x = 60 * 1000 * 2;
        service.Security = new EtownStudyAdvisorIdentityValidation.Security_element();
        service.Security.UsernameToken = new EtownStudyAdvisorIdentityValidation.UsernameToken_element();
        service.Security.UsernameToken.Username = 'SalesForceUser';
        service.Security.UsernameToken.Password = 'WsFerS12';
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
    
    public List<SelectOption> getTaskCallResultList()
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult fieldResult = Task.CallResult__c.getDescribe();
        List<Schema.Picklistentry> picklistEntries = fieldResult.getPicklistValues();
        options.add(new SelectOption('', ''));
        for(Schema.Picklistentry entry : picklistEntries)
        {
            options.add(new SelectOption(entry.getValue(), entry.getValue()));
        }
        return options;
    }
    
    public PageReference checkTaskRecordType()
    {
        String taskId = ApexPages.currentPage().getParameters().get('id');
        List<Task> tasks = [select Id, RecordType.Name from Task where Id = :taskId];
        if(tasks.size() > 0)
        {
            if(tasks[0].RecordType.Name == 'Study Advise')
            {
                return null;
            }
        }
        PageReference taskEditPage = new pageReference('/' + taskId + '/e?nooverride=1');
        return taskEditPage;
    }
    
    // Concatenates the MemberId, current year and current month to get an unique id.
    private String generateCallId(String uniqueId)
    {
        String year = String.valueOf(Datetime.now().yearGmt());
        String month = String.valueOf(Datetime.now().monthGmt());
        String day = String.valueOf(Datetime.now().dayGmt());
        String hour = String.valueOf(Datetime.now().hourGmt());
        String minute = String.valueOf(Datetime.now().minuteGmt());
        String second = String.valueOf(Datetime.now().secondGmt());
        month = (month.length() == 1)? '0' + month: month;
        day = (day.length() == 1)? '0' + day : day;
        hour = (hour.length() == 1)? '0' + hour : hour;
        minute = (minute.length() == 1)? '0' + minute : minute;
        second = (second.length() == 1)? '0' + second : second;
        return 'SA' + uniqueId + year + month + day + hour + minute + second;
    }
    
    public PageReference closeTaskWithoutFollowup()
    {
        try
        {
            if(IsAdminOrManager)
            {
                checkTaskInputInfo();
            }
            String callResult = TaskCallResult;
            if(callResult == null)
            {
                throw new ProcessAdvisorTaskException('Please input "Call Result".');
            }
            if(onHoldStatusSet.contains(callResult))
            {
                currentTask.Status = 'On-Hold';
            }
            else if(accomplishedStatusSet.contains(callResult))
            {
                currentTask.Status = 'Accomplished';
                currentTask.ActivityDate = Date.today();
            }
            else if(unaccomplishedStatusSet.contains(callResult))
            {
               currentTask.Status = 'Unaccomplished';
               currentTask.ActivityDate = Date.today();
            }
            sendEmailToStudent();
            currentTask.CallResult__c = TaskCallResult;
            update currentTask;
            return new PageReference('/home/home.jsp');
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    public PageReference save()
    {
        try
        {   
            checkTaskInputInfo();
            Task updatedTask = new Task(Id = currentTask.Id);
            updatedTask.Status = currentTask.Status;
            updatedTask.Subject = currentTask.Subject;
            updatedTask.OwnerId = currentTask.OwnerId;
            update updatedTask;
            return new PageReference('/home/home.jsp');
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
    
    private void checkTaskInputInfo()
    {   
        if(currentTask.OwnerId == null)
        {
            throw new ProcessAdvisorTaskException('Assign To is null.');
        }
        if(currentTask.Subject == null)
        {
            throw new ProcessAdvisorTaskException('Subject is null.');
        }
        if(currentTask.ActivityDate == null)
        {
            throw new ProcessAdvisorTaskException('Due date is null.');
        }
    }
    
    public PageReference closeTaskWithFollowup()
    {
        try
        {   
            if(IsAdminOrManager)
            {
                checkTaskInputInfo();
            }
            String callResult = TaskCallResult;
            currentTask.CallResult__c = TaskCallResult;
            if(callResult == null)
            {
                throw new ProcessAdvisorTaskException('Please input "Call Result".');
            }
            if(onHoldStatusSet.contains(callResult))
            {
                sendEmailToStudent();
                currentTask.Status = 'On-Hold';
                update currentTask;
            }
            else
            {
                closeCurrentTaskAndCreateNextTask(callResult);
            }
            PageReference resultPage = new PageReference('/home/home.jsp');
            return resultPage; 
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
            return null;
        }
    }
     
    private void checkSubscriptionDateOrFeatureDate(Date DueDateofNextTask)
    {   
        Datetime subscriptionDate;
        Datetime featureDate;
        
        // Invoke etown service.
        EtownStudyAdvisorDataContract.CheckDueDateResult result;
        Integer etownMemberId = (student.EtownMemberId__c == null)? 0: Integer.valueOf(student.EtownMemberId__c); 
        try
        {
            result = service.CheckDueDate(etownMemberId);
            if(result.Succeeded)
            {
                subscriptionDate = result.SubscriptionExpiredDate;
                featureDate = result.FeatureAccessExpiredDate;
            }
            else
            {
                throw new ProcessAdvisorTaskException('Failed to invoke Etown service.');
            }
        }
        catch(exception ex)
        {
            throw new ProcessAdvisorTaskException('Failed to invoke Etown service.');
        }  
        compareAdvisorServiceDate(subscriptionDate, featureDate, DueDateofNextTask);  
    }
    
    private void compareAdvisorServiceDate(Datetime subscriptionDate, Datetime featureDate, Date DueDateofNextTask)
    {   
        Datetime limitedDate = Datetime.newInstance(1990,1,1); 
        if(subscriptionDate == null || featureDate == null)
        {
            ShowCloseButton = true;
            throw new ProcessAdvisorTaskException('This student\'s advising service has expired. Please click \'terminate service\'.');
        }
        if(subscriptionDate < limitedDate && featureDate < limitedDate)
        {
            ShowCloseButton = true;
            throw new ProcessAdvisorTaskException('This student\'s advising service has expired. Please click \'terminate service\'.');
        }
        else if(subscriptionDate < Date.today() || featureDate < Date.today())
        {
            ShowCloseButton = true;
            throw new ProcessAdvisorTaskException('This student\'s advising service has expired. Please click \'terminate service\'.');
        }
        else if(DueDateofNextTask > subscriptionDate || DueDateofNextTask > featureDate)
        {
            ShowCloseButton = true;
            Datetime endDatetime = (subscriptionDate < featureDate && subscriptionDate != null)? subscriptionDate: featureDate;
            String endDateString;
            if(endDatetime != null)
            {
                endDateString = endDatetime.day() + '/' + endDatetime.month() + '/' + endDatetime.year();
            }
            throw new ProcessAdvisorTaskException('You can not set the due date later than the service end date ' + endDateString + '. Please input the due date again, or terminate the service. ');
        } 
        else
        {
            ShowCloseButton = false;
        }
    }
    
    private String closeCurrentTaskAndCreateNextTask(String callResult)
    {
        String lastCalledBy = [select Id, Name from User where Id = :UserInfo.getUserId()].Name;
        String assignToUserId = currentTask.OwnerId;
        String nextTaskId;
        if(accomplishedStatusSet.contains(callResult))
        {
            nextTaskId = createFirstTaskInTaskGroup('Accomplished', lastCalledBy, assignToUserId);
        }
        else if(unaccomplishedStatusSet.contains(callResult))
        {
            if(currentTask.Attempt__c == 3)
            {
                String tempStauts = (callResult == 'Requested call back') ? 'Accomplished' : 'Unaccomplished';
                nextTaskId = createFirstTaskInTaskGroup(tempStauts, lastCalledBy, assignToUserId);
            }
            else
            {
                nextTaskId = createOtherTaskInTaskGroup('Unaccomplished', lastCalledBy, assignToUserId);
            }
        }
        return nextTaskId;
    }
    
    private String createFirstTaskInTaskGroup(String taskStatus, String lastCalledBy, String assignTo)
    {
        Task newTask = new Task(RecordTypeId = advisorTaskRecordTypeId);
        newTask.Subject = 'Recurring';
        newTask.Attempt__c = 1;
        if(tempTask.ActivityDate == null)
        {
            throw new ProcessAdvisorTaskException('Please input "Due Date of next task".');
        }
        if(tempTask.ActivityDate < Date.today())
        {
            throw new ProcessAdvisorTaskException('Due date of next task is less than today. Please check.');
        }
        newTask.ActivityDate = tempTask.ActivityDate;
        newTask.LastCallBy__c = lastCalledBy;
        newTask.WhoId = student.Id;
        newTask.WhatId = student.AccountId;
        newTask.Language__c = student.PreferredLanguage__c;
        newTask.Country__c = student.CountryCode__c;
        newTask.Corporate__c = student.CorporateCode__c;
        newTask.Division__c = student.DivisionCode__c;
        newTask.TimeZone__c = student.TimeZone__c;
        newTask.OwnerId = assignTo;
        newTask.Status = 'Open';
        checkSubscriptionDateOrFeatureDate(newTask.ActivityDate);
        sendEmailToStudent();
        insert newTask;
        update new Task(Id = newTask.Id, CallId__c = generateCallId(newTask.Id));
        currentTask.Status = taskStatus;
        currentTask.ActivityDate = Date.today();
        update currentTask; 
        return newTask.Id;
    }
    
    private String createOtherTaskInTaskGroup(String taskStatus, String lastCalledBy, String assignTo)
    {
        if(currentTask.ActivityDate == null)
        {
            throw new ProcessAdvisorTaskException('Due date of current task is null. Please fill in this field.');
        }
        Task newTask = new Task(RecordTypeId = advisorTaskRecordTypeId);
        newTask.Subject = 'Recurring'; 
        if(currentTask.Attempt__c == null || currentTask.Attempt__c == 0)
        {
            currentTask.Attempt__c = 1;
        }
        Integer newAttemptNumber = Integer.valueOf(currentTask.Attempt__c + 1);
        Integer day = 1;
        day = (newAttemptNumber == 3)? 2: day;
        newTask.Attempt__c = newAttemptNumber; 
        newTask.ActivityDate = Date.today().addDays(day);
        newTask.CallId__c = currentTask.CallId__c; 
        newTask.LastCallBy__c = lastCalledBy;
        newTask.WhoId = student.Id;
        newTask.WhatId = student.AccountId;
        newTask.Language__c = student.PreferredLanguage__c;
        newTask.Country__c = student.CountryCode__c;
        newTask.Corporate__c = student.CorporateCode__c;
        newTask.Division__c = student.DivisionCode__c;
        newTask.TimeZone__c = student.TimeZone__c;
        newTask.OwnerId = assignTo;
        newTask.Status = 'Open';
        checkSubscriptionDateOrFeatureDate(newTask.ActivityDate);
        sendEmailToStudent();
        insert newTask;  
        currentTask.Status = taskStatus; //'Unaccomplished';
        currentTask.ActivityDate = Date.today();
        update currentTask;
        return newTask.Id;
    }
    
    public void sendEmailToStudent()
    {
        if(SendEmail)
        {
            if(EmailMessageBoday == null || EmailMessageBoday == '')
            {
                throw new ProcessAdvisorTaskException('The email cannot be blank.');
                return;
            }
            if(student.Email == null)
            {
                throw new ProcessAdvisorTaskException('Please input "Email Address".');
                return;
            }
            try
            {
                List<EmailTemplate> advisorEmailTemplates = [select Id, Body from EmailTemplate where Name = 'Study Advisor Task Edit Email Template' limit 1];
                String emailTemplateId;
                if(advisorEmailTemplates.size() > 0)
                {
                    emailTemplateId = advisorEmailTemplates[0].Id;
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'No email template. Please check.'));
                    return;
                }
                String templateHtmlBody = advisorEmailTemplates[0].Body;
                templateHtmlBody = templateHtmlBody.replace('{!name}', student.Name).replace('{!body}', EmailMessageBoday);
                Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
                String toAddress = student.Email;
                String emailSubject = 'A message from your EF Study Advisor';
                String replyTo = 'advisors@ef.com';
                ThorSendEmailServiceHelper emailServiceHelper = new ThorSendEmailServiceHelper();
                ThorSendEmailServiceHelper.EmailServiceResult result = emailServiceHelper.sendEmail(toAddress, replyTo, emailSubject, templateHtmlBody, true);
                if(result.isSuccess)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Send email successfully.'));
                    SendEmail = false;
                }
                else
                {
                    throw new ProcessAdvisorTaskException('Unexpected error occurred! The email is not sent successfully. Please send it again.');
                }
            }
            catch(Exception ex)
            {
                throw new ProcessAdvisorTaskException(ex.getMessage());
            }
        }
    }
    
    public class ProcessAdvisorTaskException extends Exception {}
    
    @isTest
    static void testOverrideTaskEditController()
    {
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContact = new Contact(Lastname = 'test contact', AccountId = testAccount.Id, Email = 'test.acme.advise@pm.com', EtownMemberId__c = 9899999);
        insert testContact;
        String adviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        Task testTask = new Task(RecordTypeId = adviseTaskRecordTypeId);
        testTask.Subject = 'Test Task';
        testTask.ActivityDate = Date.today().addDays(3);
        testTask.OwnerId = UserInfo.getUserId();
        testTask.WhoId = testContact.Id;
        testTask.Attempt__c = 1;
        insert testTask;
        Pagereference testPage = new PageReference('/apex/OverrideTaskEdit?id=' + testTask.Id);
        ApexPages.Standardcontroller standardController = new ApexPages.Standardcontroller(testTask);
        OverrideTaskEditController controller = new OverrideTaskEditController(standardController);
        controller.SendEmail = false;
        controller.checkTaskRecordType();
        controller.EmailMessageBoday = 'test';
        try
        {
            controller.sendEmailToStudent();
        }
        catch(Exception ex){}
        controller.TaskCallResult = 'Hang up';
        controller.closeTaskWithFollowup();
        controller.getTaskStatusList();
        controller.getTaskCallResultList();
        String callId = controller.generateCallId(testTask.Id);
        update new Task(Id = testTask.Id, CallId__c = callId);
        // Test for save method.
        controller.CurrentTask.OwnerId = UserInfo.getUserId();
        controller.CurrentTask.Subject = 'Test Advise Task';
        controller.CurrentTask.Status = 'On-Hold';
        controller.save();
        System.assertEquals('Test Advise Task', [select Id, Subject from Task where Id = :testTask.Id].Subject);
        // Test closeTaskWithoutFollowup.
        controller.TaskCallResult = 'Left company';
        controller.closeTaskWithoutFollowup();
        controller.TaskCallResult = 'Requested call back';
        controller.closeTaskWithoutFollowup();
        controller.TaskCallResult = 'Chatted but not about study';
        controller.closeTaskWithoutFollowup();
        controller.SendEmail = true;
        try
        {
            controller.sendEmailToStudent();
        }
        catch(Exception ex){}
        // Test compareAdvisorServiceDate.
        Datetime subscriptionDate = null;
        Datetime featureDate = null;
        Date dueDateOfNextTask = Date.today().addDays(3);
        try
        {
            controller.compareAdvisorServiceDate(subscriptionDate, featureDate, dueDateofNextTask);
        }
        catch(Exception ex){}
        subscriptionDate = Datetime.newInstance(0001, 1, 1);
        featureDate = Datetime.newInstance(0001, 1, 1);
        try
        {
            controller.compareAdvisorServiceDate(subscriptionDate, featureDate, dueDateofNextTask);
        }
        catch(Exception ex){}
        subscriptionDate = Datetime.now().addDays(-2);
        featureDate = Datetime.now().addDays(-3);
        try
        {
            controller.compareAdvisorServiceDate(subscriptionDate, featureDate, dueDateofNextTask);
        }
        catch(Exception ex){}
        subscriptionDate = Datetime.now().addDays(1);
        featureDate = Datetime.now().addDays(1);
        try
        {
            controller.compareAdvisorServiceDate(subscriptionDate, featureDate, dueDateofNextTask);
        }
        catch(Exception ex){}
        String status = controller.TaskStatus;
        try
        {
            controller.closeCurrentTaskAndCreateNextTask('Successfully discussed study');
            String callIdPrefix = 'SA' + testTask.Id + '%';
            Task nextMonthTask = [select Id, Attempt__c, CallId__c from Task where WhoId = :testContact.Id and Id != :testTask.Id order by createdDate limit 1];
            System.assertEquals(1, nextMonthTask.Attempt__c); 
            // Test for next month task(1).
            standardController = new ApexPages.Standardcontroller(nextMonthTask);
            controller = new OverrideTaskEditController(standardController);
            controller.closeCurrentTaskAndCreateNextTask('Requested call back');
            Task task2 =  [select Id, Attempt__c, CallId__c from Task where CallId__c = :nextMonthTask.CallId__c and Id != :nextMonthTask.Id ];
            Task tempTask = [select Id, CallId__c  from Task where Id = :testTask.Id];
            System.assertEquals(2, task2.Attempt__c);
            controller.closeTaskWithoutFollowup();
        }catch(Exception ex){}
    }
}