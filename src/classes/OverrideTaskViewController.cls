/*
*  This controller for Page OverrideTaskView.
*/
public class OverrideTaskViewController 
{
    public TaskDetailSection TaskDetail {get; set;} 
    public PersonalInfoSection PersonalInfoSection {get; set;}
    public EnrollmentSection EnrollmentSection {get; set;}
    public PerformanceSection PerformanceSection {get; set;}
    public HistorySection HistorySection {get; set;}
    public OldHistorySection OldHistorySection {get; set;}
    private EtownPersonalInfoStub.BasicHttpBinding_ISalesForceStudyAdvisorService service = new EtownPersonalInfoStub.BasicHttpBinding_ISalesForceStudyAdvisorService();
    private EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService advisorService = new EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService();
     
    public OverrideTaskViewController(ApexPages.StandardController controller)
    {
        try
        {
            initializeService();
            TaskDetail = new TaskDetailSection(controller);
            personalInfoSection = new PersonalInfoSection(TaskDetail.Student, service);
            EnrollmentSection = new EnrollmentSection(TaskDetail.Student, advisorService);
            PerformanceSection = new PerformanceSection(TaskDetail.Student);
            HistorySection = new HistorySection(TaskDetail.Student, TaskDetail.currentTask.Id);
            OldHistorySection = new OldHistorySection(TaskDetail.Student, advisorService);
        }
        catch(Exception ex)
        {
            apexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    }
    
    private void initializeService()
    {
        service.Security = new EtownPersonalInfoIdentityValidation.Security_element();
        service.timeout_x = 60 * 1000 * 2;
        service.Security.UsernameToken = new EtownPersonalInfoIdentityValidation.UsernameToken_element();
        service.Security.UsernameToken.Username = 'SalesForceUser';
        service.Security.UsernameToken.Password = 'WsFerS12';
        advisorService.timeout_x = 60 * 1000 * 2;
        advisorService.Security = new EtownStudyAdvisorIdentityValidation.Security_element();
        advisorService.Security.UsernameToken = new EtownStudyAdvisorIdentityValidation.UsernameToken_element();
        advisorService.Security.UsernameToken.Username = 'SalesForceUser';
        advisorService.Security.UsernameToken.Password = 'WsFerS12';
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
        PageReference taskEditPage = new pageReference('/' + taskId + '?nooverride=1');
        return taskEditPage;
    }
    
    public class TaskDetailSection
    {
        public Task currentTask {get; set;}
        public String Phone {get; set;}
        public String MobilePhone {get; set;}
        public String StudentName {get; set;}
        public String Email {get; set;}
        public Boolean ShowEditButton {get; set;}
        public Boolean ShowAdditionalSection {get; set;}
        public Contact Student;
        private ApexPages.StandardController currentController;
        
        public TaskDetailSection(ApexPages.StandardController controller)
        {
            currentController = controller;
            String taskId = controller.getId();
            List<Task> tasks = [select Id, WhoId, IsClosed, Attempt__c, CallId__c, OwnerId, Subject, ActivityDate, RecordType.Name, CreatedById, CreatedDate, LastModifiedDate, Status, LastModifiedById, CallResult__c, Description, LastCallBy__c from Task where Id = :taskId];
            if(tasks.size() > 0) 
            {
                currentTask = tasks[0];
                List<Contact> contacts = [select Id, Name, Email, Salutation, MobilePhone, Phone, EtownMemberId__c, Timezone__c  from Contact where Id = :tasks[0].WhoId];
                if(contacts.size() > 0)
                {
                    student = contacts[0];
                    Phone = student.Phone;
                    MobilePhone = student.MobilePhone;
                    Email = student.Email;
                    StudentName = student.Name;
                }
                else
                {
                    throw new TaskControllerException('No student related to this task.');
                }
                // Check User profile.
                User currentUser = [select Id, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
                String userProfile = currentUser.Profile.Name;
                userProfile = (userProfile == null)? '':userProfile.toLowerCase();
                if(currentTask.IsClosed == true)
                {
                    ShowEditButton = false;
                    ShowAdditionalSection = false;
                }
                else
                {
                    ShowEditButton = true;
                    ShowAdditionalSection = true;
                }
            }
            else
            {
                throw new TaskControllerException('Invalid id.');
            }
        }
        
        public PageReference edit()
        {
            return currentController.edit();
        }
    }
    
    public class PersonalInfoSection
    {
        public Boolean RefreshPersonalInfoSection {get; set;}
        public Boolean PersonalInfoErrorMessageDisplay {get; set;}
        public String PersonalInfoErrorMessage {get; set;}
        public PersonalInfo personalInfo {get; set;} 
        public String LocalTime {get; set;}
        public String Gender 
        {
            get
            {
                String result = '';
                if(student != null)
                {
                    if(student.Salutation == 'Mr.')
                    {
                        result = 'male';
                    }
                    else if(student.Salutation == 'Ms.')
                    {
                        result = 'female';
                    }
                }
                return result;
            } 
            set;
        }
        public Boolean DisplayLocalTimeMessage {get; set;}
        private Contact student; 
        private EtownPersonalInfoStub.BasicHttpBinding_ISalesForceStudyAdvisorService service;
        private Date limitedDate = Date.newInstance(1980,1,1);
        
        public PersonalInfoSection(Contact contact, EtownPersonalInfoStub.BasicHttpBinding_ISalesForceStudyAdvisorService etownService)
        {
            personalInfo = new PersonalInfo();
            student = contact;
            service = etownService;
            LocalTime = generateLocalTime(contact.Timezone__c);
        }
        
        public void getPersonalInfoFromEtown()
        {
            try
            {
                RefreshPersonalInfoSection = true;
                if(Student.EtownMemberId__c == null)
                {
                   throw new TaskControllerException('Etown memeberid is null.');
                }
                Integer etownMemberId = Integer.valueOf(Student.EtownMemberId__c);
                invokeEtownPersonalInfoService(etownMemberId);
            }
            catch(Exception ex)
            {
                PersonalInfoErrorMessageDisplay = true;
                PersonalInfoErrorMessage = ex.getMessage();
            }
        }
        
        private String generateLocalTime(String timezone)
        {
            String result = '';
            if(timezone != null && timezone.length() >= 10)
            {
                String subTimeZone = timezone.substring(4, 10); // result like this -04:30
                Integer hours = getHours(subTimeZone);
                Integer minutes = getMinutes(subTimeZone);
                //Datetime gmtDatetime = Datetime.newInstanceGmt(Datetime.now().dateGMT(), Datetime.now().timeGmt());
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
            else
            {
                DisplayLocalTimeMessage = true;
            }
            return result; //Datetime.now().format('MM/dd/yyyy HH:mm:ss');
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
        
        private void invokeEtownPersonalInfoService(Integer studentMemberId)
        {   
            try
            {
                EtownPersonalInfoDataContract.GetPersonalInfoResult result;
                result = service.GetPersonalInfo(studentMemberId);
                if(result.Succeeded)
                {   
                    buildPersonalInfoData(result.EFPersonalInfo);
                }
                else
                {
                    throw new TaskControllerException('Failed to load personal information');
                }
            } 
            catch(Exception ex)
            {
                throw new TaskControllerException('Failed to load personal information');
            }
        }
        
        private void buildPersonalInfoData(EtownPersonalInfoDataContract.EFPersonalInfo efPersonalInfo)
        {
            if(efPersonalInfo != null)
            {   
                PersonalInfo.UserName = efPersonalInfo.UserName;
                PersonalInfo.MemberID = efPersonalInfo.MemberID;
                PersonalInfo.Password = efPersonalInfo.Password;
                PersonalInfo.Corporate = efPersonalInfo.Corporate;
                PersonalInfo.CurrentLevel = efPersonalInfo.CurrentLevel;
                PersonalInfo.Division = efPersonalInfo.Division;
                PersonalInfo.Partner = efPersonalInfo.Partner;
                PersonalInfo.Preferredlanguage = efPersonalInfo.Preferredlanguage;
                PersonalInfo.SubStartDate = (efPersonalInfo.SubStartDate == null || efPersonalInfo.SubStartDate <= limitedDate)? '': formatDate(efPersonalInfo.SubStartDate);
                PersonalInfo.SubEndDate = (efPersonalInfo.SubEndDate == null || efPersonalInfo.SubEndDate <= limitedDate)? '': formatDate(efPersonalInfo.SubEndDate);
                PersonalInfo.LastVisitDate = (efPersonalInfo.LastVisitDate == null || efPersonalInfo.LastVisitDate <= limitedDate)? '': formatDate(efPersonalInfo.LastVisitDate);
                PersonalInfo.StudyHours = efPersonalInfo.StudyHours;
                PersonalInfo.StudyGoal = efPersonalInfo.StudyGoal;
                PersonalInfo.AchievedLevel = efPersonalInfo.AchievedLevel;
                PersonalInfo.StartingLevel = efPersonalInfo.StartingLevel;
                PersonalInfo.UnitCompleted = efPersonalInfo.UnitCompleted;
                PersonalInfo.Writing = efPersonalInfo.Writing;
                PersonalInfo.ConversationClass = efPersonalInfo.ConversationClass;
                PersonalInfo.PrivateLesson = efPersonalInfo.PrivateLesson;
                PersonalInfo.StudyPace = efPersonalInfo.StudyPace;
                personalInfo.StudyFocus = efPersonalInfo.StudyFocus;
                personalInfo.HighLightSubEndDate = (efPersonalInfo.SubEndDate == null)? false: efPersonalInfo.SubEndDate <= Date.today();
            }
        }
        
        private String formatDate(Datetime dateValue)
	    {
	        if(dateValue != null)
	        {
	            String year = String.valueOf(dateValue.yearGmt());
	            String month = String.valueOf(dateValue.monthGmt());
	            String day = String.valueOf(dateValue.dayGmt());
	            month = (month.length() == 1)? '0' + month: month;
	            day = (day.length() == 1)? '0' + day : day;
	            return day + '/' + month + '/' + year;
	        }
	        return '';
	    }
    }
    
    public class PersonalInfo
    {
        public String UserName {get; set;}
        public Integer MemberID {get; set;}
        public String Password {get; set;}
        public String Corporate {get; set;}
        public String Division {get; set;}
        public String Partner {get; set;}
        public String Preferredlanguage {get; set;}
        public String StudyPace {get; set;}
        public String StudyFocus {get; set;}
        public String StudyGoal {get; set;}
        public String SubStartDate {get; set;}
        public String SubEndDate {get; set;}
        public String LastVisitDate {get; set;}
        public Boolean HighLightSubEndDate {get; set;}
        public String CurrentLevel {get; set;}
        public String StartingLevel {get; set;}
        public String AchievedLevel {get; set;}
        public Integer UnitCompleted {get; set;}
        public Integer Writing {get; set;}
        public Integer ConversationClass {get; set;}
        public Integer PrivateLesson {get; set;}
        public Double StudyHours {get; set;}
    }
    
    public class EnrollmentSection
    {
        public Boolean RefreshEnrollmentsSection {get; set;}
        public Integer firstRowIndex {get; set;}
        public Boolean EnrollmentsErrorMessageDisplay {get; set;}
        public String EnrollmentsErrorMessage {get; set;}
        public List<EnrollmentInfo> Enrollments {get; set;}
        public Boolean PreviousButtonDisplay {get; set;}
        public Boolean NextButtonDisplay {get; set;}
        public Integer tableSize 
        {
            get
            {
                return 50;
            } 
            set;
        }
        private Contact student;
        private EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService service;
        
        public EnrollmentSection(Contact contact, EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService etownService)
        {
            student = contact;
            service = etownService;
            Enrollments = new List<EnrollmentInfo>(); 
            firstRowIndex = 0;
        }
        
        public void getEnrollmentsFromEtown()
        {
            try
            {
                RefreshEnrollmentsSection = true;
                if(Student.EtownMemberId__c == null)
                {
                   throw new TaskControllerException('Etown memeberid is null.');
                }
                Integer etownMemberId = Integer.valueOf(student.EtownMemberId__c);
                invokeEtownEnrollmentService(etownMemberId);
                if(Enrollments.size() > tableSize)
                {
                    NextButtonDisplay = true;
                }
            }
            catch(Exception ex)
            {
                EnrollmentsErrorMessageDisplay = true;
                EnrollmentsErrorMessage = ex.getMessage();
            }
        }
        
        public void previousTable()
        {
            firstRowIndex = firstRowIndex - tableSize;
            firstRowIndex = (firstRowIndex < 0)? 0: firstRowIndex;
            if(firstRowIndex > 0)
            {
                PreviousButtonDisplay = true;
            }
            else
            {
                PreviousButtonDisplay = false;
            }
        }
        
        public void nextTable()
        {
            firstRowIndex = firstRowIndex + tableSize;
            if(firstRowIndex + tableSize < Enrollments.size())
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
        
        private void invokeEtownEnrollmentService(Integer studentMemberId)
        {
            try
            {
                EtownStudyAdvisorDataContract.GetStudyProgressInfoResult result;
                result = service.GetStudyProgressInfo(studentMemberId);
                if(result.Succeeded)
                {
                    buildEnrollmentData(result.EFStudyProgressInfoList);
                }
                else
                {
                    throw new TaskControllerException('Failed to load enrollment information.');
                }
            }
            catch(Exception ex)
            {
                throw new TaskControllerException('Failed to load enrollment information.');
            }
            
        }
        
        private void buildEnrollmentData(EtownStudyAdvisorDataContract.ArrayOfStudyProgressInfo enrollmentInfos)
        {
            if(enrollmentInfos != null && enrollmentInfos.StudyProgressInfo != null && enrollmentInfos.StudyProgressInfo.size() > 0)
            {   
                Datetime limitDatetime = Datetime.newInstance(1990,1,1); 
                for(EtownStudyAdvisorDataContract.StudyProgressInfo enrollment : enrollmentInfos.StudyProgressInfo)
                {
                    if(enrollment.StartDate != null && Datetime.valueOf(enrollment.StartDate) > limitDatetime)
                    {
                        EnrollmentInfo tempInfo = new EnrollmentInfo();
                        tempInfo.CourseName = enrollment.CourseName;
                        tempInfo.CourseId = enrollment.CourseId;
                        tempInfo.CompletedDate = enrollment.CompletedDate;
                        tempInfo.Courseware = enrollment.Courseware;
                        tempInfo.StartDate = enrollment.StartDate;
                        tempInfo.Grade = enrollment.Grade;
                        Enrollments.add(tempInfo);
                    }
                }
            }
        }
    }
    
    public class EnrollmentInfo
    {
        public String CourseName {get; set;}
        public Integer CourseId {get; set;}
        public String Courseware {get; set;}
        public String StartDate {get; set;}
        public String CompletedDate {get; set;}
        public Integer Grade {get; set;}
    }
    
    public class PerformanceSection
    {
        public String DigestMessage {get; set;}
        public String MemberId {get; set;}
        public String utcDateString {get; set;}
        public String EtownDomain {get; set;}
        public Boolean DisplayLink {get; set;}
        private final String digitKey = 'Et0wnLL5';
        private Contact student;
        
        public PerformanceSection(Contact contact)
        {
            student = contact;
            getPerformanceLink();
        }
        
        public void getPerformanceLink()
        {
            DisplayLink = true;
            EtownDomain = EtownServer__c.getInstance('Study Advisor Performance').Url__c;
            memberId = (student.EtownMemberId__c == null)? '':String.valueOf(student.EtownMemberId__c);
            String inputString = memberId + digitKey;
            if(inputString != null)
            {
                digestMessage = generateDigest(inputString);
            }
            utcDateString = getUTCDateString(); 
        }
        
        private String generateDigest(String inputValue)
        {
            Blob encryptedText = Crypto.generateDigest('MD5', Blob.valueOf(inputValue));
            return EncodingUtil.convertToHex(encryptedText);
        }
        
        private String getUTCDateString()
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
            return year + '-' + month + '-' + day + ' ' + hour + ':' + minute + ':' + second;
        }
    }
    
    public class HistorySection
    {
        public Boolean RefreshHistorySection {get; set;}
        public Boolean HistoryErrorMessageDisplay {get; set;}
        public String HistoryErrorMessage {get; set;}
        public List<HistoryTask> HistoryTasks {get; set;}
        public List<HistoryCase> HistoryCases {get; set;}
        public String currentTaskId;
        private Contact student;
        
        public HistorySection(Contact contact, String taskId)
        {
            HistoryTasks = new List<HistoryTask>();
            HistoryCases = new List<HistoryCase>();
            student = contact;
            currentTaskId = taskId;
        }
        
        public void getHistory()
        {
            RefreshHistorySection = true;
            try
            {
                List<Task> tasks = [select Id, Subject, ActivityDate, Status, CallResult__c, IsClosed, Description, OwnerId, Owner.Name from Task where RecordType.Name = 'Study Advise' and WhoId = :student.Id and Id != :currentTaskId order by IsClosed, ActivityDate limit 1000];
                for(Task task : tasks)
                {
                    HistoryTask newHistoryTask = new HistoryTask();
                    newHistoryTask.TaskId = task.Id;
                    newHistoryTask.Subject = task.Subject;
                    newHistoryTask.IsClosed = task.IsClosed;
                    newHistoryTask.DueDate = (task.ActivityDate == null)? '': task.ActivityDate.format();
                    newHistoryTask.Status = task.Status;
					newHistoryTask.Description = task.Description;
                    newHistoryTask.CallResult = task.CallResult__c;
                    newHistoryTask.AssginTo = task.Owner.Name;
                    HistoryTasks.add(newHistoryTask);
                }
                
                List<Case> cases = [select Id, CaseNumber, CreatedDate, Owner.Name, Status, Subject, IsClosed, Priority, OwnerId from Case where ContactId = :student.Id order by IsClosed, CreatedDate limit 1000];
                for(Case caseEntry : cases)
                {
                    HistoryCase newHistoryCase = new HistoryCase();
                    newHistoryCase.CaseId = caseEntry.Id;
                    newHistoryCase.CaseNum = caseEntry.CaseNumber;
                    newHistoryCase.Subject = caseEntry.Subject;
                    newHistoryCase.IsClosed = caseEntry.IsClosed;
                    newHistoryCase.Owner = caseEntry.Owner.Name;
                    newHistoryCase.Priority = caseEntry.Priority;
                    newHistoryCase.CreatedDate = caseEntry.CreatedDate.format('dd/MM/yyyy');
                    newHistoryCase.Status = caseEntry.Status;
                    HistoryCases.add(newHistoryCase);
                }
            }
            catch(Exception ex)
            {
                HistoryErrorMessageDisplay = true;
                HistoryErrorMessage = ex.getMessage();
            }
        }
    }
    
    public class HistoryTask
    {
        public Boolean IsClosed {get; set;}
        public String TaskId {get; set;}
        public String Subject {get; set;}
        public String DueDate {get; set;}
		public String Description {get; set;}
        public String Status {get; set;}
        public String CallResult {get; set;}
        public String AssginTo {get; set;}
    }
    
    public class HistoryCase
    {
        public Boolean IsClosed {get; set;}
        public String CaseId {get; set;}
        public String CaseNum {get; set;}
        public String Subject {get; set;}
        public String Owner {get; set;}
        public String Priority {get; set;}
        public String CreatedDate {get; set;}
        public String Status {get; set;}
    }
    
    public class OldHistorySection
    {
        public Boolean RefreshOldHistorySection {get; set;}
        public Boolean OldHistoryErrorMessageDisplay {get; set;}
        public String OldHistoryErrorMessage {get; set;}
        public Integer firstRowIndex {get; set;}
        public Boolean PreviousButtonDisplay {get; set;}
        public Boolean NextButtonDisplay {get; set;}
        public List<OldHistory> oldHistories {get; set;}
        public Integer tableSize 
        {
            get
            {
                return 50;
            } 
            set;
        }
        private Contact student;
        private EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService service;
        
        public OldHistorySection(Contact contact, EtownStudyAdvisorServiceStub.BasicHttpBinding_ISalesForceStudyAdvisorService etownService)
        {
            student = contact;
            service = etownService;
            oldHistories = new List<OldHistory>();
            if(oldHistories.size() > tableSize)
            {
                NextButtonDisplay = true;
            }
            firstRowIndex = 0;
        }
        
        public void getOldHistoryFromEtown()
        {
            try
            {
                RefreshOldHistorySection = true;
                if(Student.EtownMemberId__c == null)
                {
                   throw new TaskControllerException('Etown memeberid is null.');
                }
                Integer etownMemberId = Integer.valueOf(Student.EtownMemberId__c);
                invokeEtownOldHistoryService(etownMemberId);
            }
            catch(Exception ex)
            {
                OldHistoryErrorMessageDisplay = true;
                OldHistoryErrorMessage = ex.getMessage();
            }
        }
        
        private void invokeEtownOldHistoryService(Integer studentMemberId)
        {
            try
            {
                EtownStudyAdvisorDataContract.GetOldHistoryResult result;
                result = service.GetPhoneCoachingHistory(studentMemberId);
                if(result.Succeeded)
                {
                    buildOldHistoryData(result.EFStudyProgressInfoList);
                }
                else
                {
                    throw new TaskControllerException('Failed to load history information');
                }
            }
            catch(Exception ex)
            {
                throw new TaskControllerException('Failed to load history information');
            }
        }
        
        private void buildOldHistoryData(EtownStudyAdvisorDataContract.ArrayOfPhoneCoachingHistoryInfo oldHistoryArrayInfo)
        {   
            if(oldHistoryArrayInfo != null && oldHistoryArrayInfo.PhoneCoachingHistoryInfo != null && oldHistoryArrayInfo.PhoneCoachingHistoryInfo.size() > 0)
            {   
                for(EtownStudyAdvisorDataContract.PhoneCoachingHistoryInfo oldHistoryInfo : oldHistoryArrayInfo.PhoneCoachingHistoryInfo)
                {
                    OldHistory tempHistory = new OldHistory();
                    tempHistory.AdvisorName = oldHistoryInfo.AdvisorName;
                    tempHistory.Comment = oldHistoryInfo.Comment;
                    tempHistory.LogDate = (oldHistoryInfo.LogDate == null)? '' : formatDatetime(oldHistoryInfo.LogDate); //.format('dd/MM/yyyy HH:mm:ss');
                    tempHistory.LogReason = oldHistoryInfo.LogReason;
                    oldHistories.add(tempHistory);
                }
            }
        }
        
        private String formatDatetime(Datetime localDatetime)
		{
		    String year = String.valueOf(localDatetime.yearGmt());
		    String month = String.valueOf(localDatetime.monthGmt());
		    String day = String.valueOf(localDatetime.dayGmt());
		    String hour = String.valueOf(localDatetime.hourGmt());
		    String minute = String.valueOf(localDatetime.minuteGmt());
		    String second = String.valueOf(localDatetime.secondGmt());
		    month = (month.length() == 1)? '0' + month: month;
		    day = (day.length() == 1)? '0' + day : day;
		    hour = (hour.length() == 1)? '0' + hour : hour;
		    minute = (minute.length() == 1)? '0' + minute : minute;
		    second = (second.length() == 1)? '0' + second : second;
		    return day + '/' + month + '/' + year + ' ' + hour + ':' + minute + ':' + second;
		}
        
        public void nextTable()
        {
            firstRowIndex = firstRowIndex + tableSize;
            if(firstRowIndex + tableSize < oldHistories.size())
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
        
        public void previousTable()
        {
            firstRowIndex = firstRowIndex - tableSize;
            firstRowIndex = (firstRowIndex < 0)? 0: firstRowIndex;
            if(firstRowIndex > 0)
            {
                PreviousButtonDisplay = true;
            }
            else
            {
                PreviousButtonDisplay = false;
            }
        }
    }
    
    public class OldHistory
    {
        public String LogReason {get; set;}
        public String AdvisorName {get; set;}
        public String Comment {get; set;}
        public String LogDate {get; set;}
    }
    
    public class TaskControllerException extends Exception {}
    
    @isTest
    static void testOverrideTaskViewController()
    {
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContact = new Contact(Lastname = 'test contact', Salutation = 'Mr.', AccountId = testAccount.Id, Email = 'test.acme.advise@pm.com', EtownMemberId__c = 9899999, Timezone__c = '(GMT+14:00) Line Islands Time (Pacific/Kiritimati)');
        insert testContact;
        String adviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
        Task testTask = new Task(RecordTypeId = adviseTaskRecordTypeId);
        testTask.Subject = 'Test Task';
        testTask.ActivityDate = Date.today().addDays(3);
        testTask.OwnerId = UserInfo.getUserId();
        testTask.WhoId = testContact.Id;
        Task testTask2 = new Task(RecordTypeId = adviseTaskRecordTypeId);
        testTask2.Subject = 'Test Task';
        testTask2.ActivityDate = Date.today().addDays(2);
        testTask2.OwnerId = UserInfo.getUserId();
        testTask2.WhoId = testContact.Id;
        insert new Task[]{testTask, testTask2};
        Case testCase = new Case(contactId = testContact.Id, Description = 'test description', OwnerId = UserInfo.getUserId(), Subject = 'Test Case');
        insert testCase;
        PageReference testPage = new PageReference('/apex/OverrideTaskView?id=' + testTask.Id);
        Test.setCurrentPage(testPage);
        ApexPages.Standardcontroller standController = new ApexPages.Standardcontroller(testTask);
        OverrideTaskViewController controller = new OverrideTaskViewController(standController);
        controller.checkTaskRecordType();
        System.assertEquals('test.acme.advise@pm.com', controller.TaskDetail.Email);
        System.assertEquals(true, controller.TaskDetail.ShowEditButton);
        // For task detail section.
        controller.TaskDetail.edit();
        // Test for personalInfoSection.
        controller.PersonalInfoSection.getPersonalInfoFromEtown();
        EtownPersonalInfoDataContract.EFPersonalInfo efPersonalInfo = new EtownPersonalInfoDataContract.EFPersonalInfo();
        controller.PersonalInfoSection.buildPersonalInfoData(efPersonalInfo);
        String gender = controller.PersonalInfoSection.Gender;
        // Test for EnrollmentSection.
        controller.EnrollmentSection.getEnrollmentsFromEtown();
        EtownStudyAdvisorDataContract.ArrayOfStudyProgressInfo progressInfo = new EtownStudyAdvisorDataContract.ArrayOfStudyProgressInfo();
        progressInfo.StudyProgressInfo = new List<EtownStudyAdvisorDataContract.StudyProgressInfo>{new EtownStudyAdvisorDataContract.StudyProgressInfo()};
        controller.EnrollmentSection.buildEnrollmentData(progressInfo);
        controller.EnrollmentSection.previousTable();
        controller.EnrollmentSection.nextTable();
        // Test for Performance.
        controller.PerformanceSection.getPerformanceLink();
        // Test for HistorySection.
        controller.HistorySection.getHistory();
        //System.assertEquals(1, controller.HistorySection.HistoryTasks.size());
        //System.assertEquals(1, controller.HistorySection.HistoryCases.size());
        // Test for OldHistorySection.
        controller.OldHistorySection.getOldHistoryFromEtown();
        EtownStudyAdvisorDataContract.ArrayOfPhoneCoachingHistoryInfo oldHistoryArrayInfo = new EtownStudyAdvisorDataContract.ArrayOfPhoneCoachingHistoryInfo();
        oldHistoryArrayInfo.PhoneCoachingHistoryInfo = new List<EtownStudyAdvisorDataContract.PhoneCoachingHistoryInfo>{new EtownStudyAdvisorDataContract.PhoneCoachingHistoryInfo()};
        controller.OldHistorySection.buildOldHistoryData(oldHistoryArrayInfo);
        controller.OldHistorySection.previousTable();
        controller.OldHistorySection.nextTable();
		controller.OldHistorySection.formatDatetime(DateTime.now());
		controller.PerformanceSection.getUTCDateString();
		controller.PersonalInfoSection.formatDate(DateTime.now());
    }
}