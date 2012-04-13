/*
*   Webservice for Etown to create a advise task.
*/
global class ETStudyAdvisingService 
{
    private static String advisorTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
    
    // Create a tast/contact from etown.
    webservice static CreateAdvisingTaskResult CreateAdvisingTask(CreateAdvisingTaskParam param)
    {
        CreateAdvisingTaskResult result = new CreateAdvisingTaskResult();
        try
        { 
            validateParameter(param);
            //return result;
            Integer memberId = param.Member.MemberId;
            String contactId; 
            List<Contact> contacts = [select Id, AccountId, CountryCode__c, EtownMemberId__c, IsInitiallySynced__c, PreferredLanguage__c, PartnerCode__c, CorporateCode__c, DivisionCode__c, TimeZone__c, (select Id, Status from Tasks where IsClosed = false and RecordTypeId = :advisorTaskRecordTypeId) from Contact where EtownMemberId__c = :memberId];
            if(contacts.size() > 0)
            {   // Check wether have active task under this contact.
                
                //Added by Jerry 20110714(S)
                EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo;
                
                if(contacts[0].IsInitiallySynced__c == false)
                {
                    fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(Integer.valueof(contacts[0].EtownMemberId__c));    
                    ContactSvc.updateContactByMemberInfo(fullMemberInfo,contacts[0].Id); 
                    contacts = [select Id, AccountId, CountryCode__c, EtownMemberId__c, IsInitiallySynced__c, PreferredLanguage__c, PartnerCode__c, CorporateCode__c, DivisionCode__c, TimeZone__c, (select Id, Status from Tasks where IsClosed = false and RecordTypeId = :advisorTaskRecordTypeId) from Contact where EtownMemberId__c = :memberId];
                }
                //Added by Jerry 20110714(E)
                
                result = closeOldTaskAndCreateNewTask(contacts[0], param);
            }
            else
            {
                // Invoke Etown interface to get student informatin.
                contactId = checkStudentByEtownFullMemberInfo(memberId);
                if(contactId != null)
                {
                    result = closeOldTaskAndCreateNewTask(contactId, param);
                }
            }
        }
        catch(Exception ex)
        {
            result.Succeeded = false;
            result.ErrorMessage = ex.getMessage();
        }
        return result;
    }
    
    // Close all open advising tasks of a student.
    webservice static CloseAdvisingTaskResult CloseAdvisingTask(CloseAdvisingTaskParam param)
    {
        CloseAdvisingTaskResult result = new CloseAdvisingTaskResult();
        
        try
        { 
            if(param == null)
            {
                throw new CloseAdvisingTaskException('CloseAdvisingTaskParam is null.');
            }
            
            if(param.Member == null)
            {
                throw new CloseAdvisingTaskException('MemberInfo is null.');
            }
            
            if(param.Member.MemberId == null)
            {
                throw new CloseAdvisingTaskException('MemberId is null.=');
            }
        
            Integer memberId = param.Member.MemberId;
            String contactId; 
            List<Contact> contacts = [select Id, (select Id, Status from Tasks where IsClosed = false and RecordTypeId = :advisorTaskRecordTypeId) from Contact where EtownMemberId__c = :memberId];
            
            if(contacts.size() > 0)
            {   
                Contact contact = contacts[0];
                if(contact.tasks.size() > 0)
                { 
                    for(Task task : contact.tasks)
                    {
                        task.Status = 'Closed by System';
                    }
                    
                    update contact.tasks;
                }  
                
                result.Succeeded = true;
                
                return result;              
            }
        }
        catch(Exception ex)
        {
            result.Succeeded = false;
            result.ErrorMessage = ex.getMessage();
        }
        
        return result;
    }    
    
    private static Boolean validateParameter(CreateAdvisingTaskParam param)
    {
        if(param == null)
        {
            throw new CreateAdvisingTaskException('CreateAdvisingTaskParam is null.');
        }
        if(param.Member == null)
        {
            throw new CreateAdvisingTaskException('MemberInfo is null.');
        }
        if(param.Member.MemberId == null)
        {
            throw new CreateAdvisingTaskException('MemberId is null.');
        }
        return true;
    }
    
    // In this class we will invoke an etown webservice, we will use the return information to map a student. 
    // If no contact was found or found more than one contact, we will create a new contact. 
    // If we found one contact, we will update this cotact use the information from etown. 
    // This method also create other information for partner object, country object, preferred Language object(if we can't find those information in salesforce). 
    private static String checkStudentByEtownFullMemberInfo(Integer memberId)
    { 
        String contactId;
        Decimal memberIdParam = (memberId == null)? 0: Decimal.valueOf(memberId);
        EtownMemberInfoServiceHelper.FullMemberInfo fullMemberInfo = EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(memberIdParam);
        String contactIdbySearched = ContactSvc.mapContactWithFullMemberInfo(fullMemberInfo);
        if(contactIdbySearched == null)
        {   // Didn't find contact.
            contactId = ContactSvc.createContactByMemberInfo(fullMemberInfo); 
        }
        else
        {   
            Boolean updateResult = ContactSvc.updateContactByMemberInfo(fullMemberInfo, contactIdbySearched);
            contactId = contactIdbySearched;
        }
        return contactId;
    }
    
    private static CreateAdvisingTaskResult closeOldTaskAndCreateNewTask(Contact contact, CreateAdvisingTaskParam param)
    {
        CreateAdvisingTaskResult result = new CreateAdvisingTaskResult();
        String partnerCode = contact.PartnerCode__c;
        String countryCode = contact.CountryCode__c;
        String preferredLanguage = contact.PreferredLanguage__c;
        String contactId = contact.Id;
        String accountId = contact.AccountId;
        String taskOwnerId = assignTask(partnerCode, countryCode, preferredLanguage);
        if(contact.tasks.size() > 0)
        { 
            if(param.Task.IsSpecialUpload == true)
            {   // Closes all old study advisor tasks.
                for(Task oldTask : contact.tasks)
                {
                    oldTask.Status = 'Closed by System';
                }
                update contact.tasks;
            }
            else
            {
                result.Succeeded = true;
                return result; // Nothing to do. 
            }
        }  
        //Task newTask = createNewTask(param.Task, contactId, accountId, taskOwnerId);
        Task newTask = createNewTask(param.Task,contact, taskOwnerId);
        result.Succeeded = true;
        result.ContactId = contactId;
        result.TaskId = newTask.Id;
        return result;
    }
    
    private static CreateAdvisingTaskResult closeOldTaskAndCreateNewTask(String contactId, CreateAdvisingTaskParam param)
    {
        List<Contact> newContacts = [select Id, AccountId, CountryCode__c, PreferredLanguage__c, PartnerCode__c, CorporateCode__c, DivisionCode__c, TimeZone__c, (select Id, Status from Tasks where IsClosed = false and RecordTypeId = :advisorTaskRecordTypeId) from Contact where Id = :contactId];
        return closeOldTaskAndCreateNewTask(newContacts[0], param);
    }
    
    private static Task createNewTask(TaskInfo taskParam, Contact student, String taskOwnerId)
    {
        Task newTask;
        if(taskParam != null)
        {   
            newTask = new Task(WhoId = student.Id, WhatId = student.AccountId, OwnerId = taskOwnerId, Subject = taskParam.Subject, Status = 'Open', ActivityDate = taskParam.DueDate, RecordTypeId = advisorTaskRecordTypeId);
            newTask.Language__c = student.PreferredLanguage__c;
            newTask.Country__c = student.CountryCode__c;
            newTask.Corporate__c = student.CorporateCode__c;
            newTask.Division__c = student.DivisionCode__c;
            newTask.TimeZone__c = student.TimeZone__c;
            insert newTask;
            String callId = generateCallId(newTask.Id);
            update new Task(Id = newTask.Id, CallId__c = callId);
        }
        else
        {
            throw new CreateAdvisingTaskException('TaskInfo is null.');
        }
        return newTask;
    }
    
    private static String assignTask(String partner, String country, String language)
    {
        String assignToUserId = AutoAssignmentLogic.assignTask(partner, country, language);
        return assignToUserId;
    }
    
    private static String generateCallId(String uniqueId)
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
    
    global class CreateAdvisingTaskParam
    {
       webservice MemberInfo Member;
       webservice TaskInfo Task;
    }

    global class CloseAdvisingTaskParam
    {
       webservice MemberInfo Member;
    }    
    
    global class MemberInfo
    {
       webservice Integer MemberId;
       webservice String FirstName;
       webservice String LastName;
       webservice String Email;
       webservice String Password;
       webservice String CountryCode;
       webservice String PartnerCode;
       webservice String DivisionId;
       webservice String CorporateId;
       webservice String TimeZone;
       webservice String PreferredLanguage;
    } 
    
    global class TaskInfo
    {
       webservice String Subject;
       webservice Date DueDate;
       webservice Boolean IsSpecialUpload;
    }
    
    global class CreateAdvisingTaskResult
    {
       webservice Boolean Succeeded;
       webservice Integer ErrorCode;    //applicable when Succeeded=false
       webservice String ErrorMessage;  //applicable when Succeeded=false
       webservice String ContactId;     //applicable when Succeeded=true
       webservice String TaskId;        //applicable when Succeeded=true
    }
    
    global class CloseAdvisingTaskResult
    {
       webservice Boolean Succeeded;
       webservice Integer ErrorCode;    //applicable when Succeeded=false
       webservice String ErrorMessage;  //applicable when Succeeded=false
    }    
    
    global class CreateAdvisingTaskException extends Exception {}
    global class CloseAdvisingTaskException extends Exception {}
    
    @isTest
    static void testETStudyAdvisingService()
    {
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContactNew = new Contact(Lastname = 'test contact', AccountId = testAccount.Id, EtownMemberId__c = 999999);
        insert testContactNew;
        String advisorTaskRecordTypeId2 = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        Task testTask1 = new Task(WhoId = testContactNew.Id, Subject = 'Test Subject', ActivityDate = Date.today().addDays(1), OwnerId = UserInfo.getUserId(), RecordTypeId = advisorTaskRecordTypeId2);
        insert testTask1;
        // Create webservice object.
        ETStudyAdvisingService.CreateAdvisingTaskParam param = new ETStudyAdvisingService.CreateAdvisingTaskParam();
        ETStudyAdvisingService.MemberInfo memberInfo = new ETStudyAdvisingService.MemberInfo();
        memberInfo.MemberId = 999999;
        ETStudyAdvisingService.TaskInfo taskInfo = new ETStudyAdvisingService.TaskInfo();
        taskInfo.Subject = 'Test Task';
        taskInfo.IsSpecialUpload = true;
        taskInfo.DueDate = Date.today().addDays(5);
        param.Member = memberInfo;
        param.Task = taskInfo;
        ETStudyAdvisingService.CreateAdvisingTaskResult result = ETStudyAdvisingService.CreateAdvisingTask(param);
        // Test for fullMemberInfo.
        memberInfo.MemberId = 99999933;
        result = ETStudyAdvisingService.CreateAdvisingTask(param);
        //ETStudyAdvisingService.closeOldTaskAndCreateNewTask(testContactNew.Id, param);
    }
}