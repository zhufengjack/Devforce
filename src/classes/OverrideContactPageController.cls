/*
 *Controller for Override Contact Page 
 */
public class OverrideContactPageController 
{
    private Contact contactRecord;
    private Set<String> chinaSmartRecordTypes = new Set<String>{'China Smart contact record type', 'China SmartB2B contact record type'};
    private Set<String> teacherRecordTypes=new Set<String>{'Etown EAST contact record type'};
    
    public OverrideContactPageController(ApexPages.StandardController controller)
    {
        String studentId = controller.getId();
        List<Contact> contacts = [select Id, Name, EliteCard__c, Product__c, IsNewEliteCard__c, RecordType.Name, IsRescheduleSynced__c, LastRefreshDate__c, EtownUserName__c, CurrentLevel__c from Contact where Id =:studentId];
        if(contacts.size() > 0)
        {
            contactRecord = contacts[0];
        }         
    }                
    
    public RescheduleInfo Record { get; set; }     
    
    public Boolean getHasSuspendAndResume(){
        return (contactRecord != null && chinaSmartRecordTypes.Contains(contactRecord.RecordType.Name));        
    }
    
    public List<RescheduleInfo> Reschedules
    {
        get
        {
            List<RescheduleInfo> records = new List<RescheduleInfo>();
            if(contactRecord.Id != null)
            {
                List<CourseReschedule__c> courseReschedules = [select Id, Name, CreatedDate, CreatedById, LastModifiedDate, ScheduleDate__c, Status__c, SuspendReason__c, ScheduleJobId__c, ActionStatus__c, ActionDate__c, Duration__c, Type__c, Subject__c, StudentActual__c, Contact__c from CourseReschedule__c where Contact__c = :contactRecord.Id order by CreatedDate, ScheduleDate__c limit 2000];
                if(courseReschedules.size() > 0)
                {
                    for(Integer i = 0; i < courseReschedules.size(); i++)
                    {
                        Record = new RescheduleInfo();
                        if(Math.Mod(i, 2) == 0 && (i + 1 < courseReschedules.size()))
                        {
                            //suspend
                            Record.SuspendId = courseReschedules[i].Id;
                            Record.CourseRescheduleName = courseReschedules[i].Name;
                            Record.Subject = 'Suspension ' + (i/2 + 1);
                            Record.SuspendDate = courseReschedules[i].ScheduleDate__c;
                            Record.SuspendStatus = courseReschedules[i].Status__c;
                            Record.SuspendActionStatus = courseReschedules[i].ActionStatus__c;
                            Record.ContactName = courseReschedules[i].Contact__c;
                            Record.StudentActualName = courseReschedules[i].StudentActual__c;
                            Record.Duration = (courseReschedules[i].ScheduleDate__c == null || courseReschedules[i+1].ScheduleDate__c == null) ? 0 : Integer.valueOf(courseReschedules[i].ScheduleDate__c.daysBetween(courseReschedules[i+1].ScheduleDate__c));
                            Record.SuspendReason = courseReschedules[i].SuspendReason__c;
                            Record.SuspendScheduleJobId = Integer.valueOf(courseReschedules[i].ScheduleJobId__c);
                            Record.SuspendType = courseReschedules[i].Type__c;
                            Record.SuspendActionDate = courseReschedules[i].ActionDate__c;
                            // resume 
                            Record.ResumeId = courseReschedules[i+1].Id; 
                            Record.ResumeDate = courseReschedules[i+1].ScheduleDate__c;
                            Record.ResumeStatus = courseReschedules[i+1].Status__c;
                            Record.ResumeActionStatus = courseReschedules[i+1].ActionStatus__c;
                            Record.ResumeScheduleJobId = Integer.valueOf(courseReschedules[i+1].ScheduleJobId__c);
                            Record.ResumeType = courseReschedules[i+1].Type__c;
                            Record.ResumeActionDate = courseReschedules[i+1].ActionDate__c;
                            if(courseReschedules[i].Status__c == 'Completed' && courseReschedules[i+1].Status__c == 'Not start yet')
                            {
                                Record.Status = 'In progress';
                            }
                            else
                            {
                                Record.Status = courseReschedules[i].Status__c;
                            }
                            records.add(Record);
                        }
                    }
                }
            }
            return records;
        }
    }

    //redirect user to standard new contact page, update student from etown. 
    //Pony Ma 2012-01-05 Added Tako Case History Section in VF Page for all record types(except Teacher EAST)
    //Pony Ma 2012-01-18 Redirect to standard page layout for Teacher EAST record type
    public PageReference redirectAndUpdateContact()      
    {
        if(contactRecord != null && contactRecord.Id == null)
        {
            return new PageReference('/003/o');
        }
        else if(contactRecord != null && teacherRecordTypes.Contains(contactRecord.RecordType.Name))
        {
            return new PageReference('/' + contactRecord.Id + '?nooverride=1'); 
        }
        else if(contactRecord != null && chinaSmartRecordTypes.Contains(contactRecord.RecordType.Name))
        {
            checkAndUpdateStudentInfo(contactRecord);                
        }        
        return null;
    }

    private void checkAndUpdateStudentInfo(Contact student)
    { 
        if(student != null && student.EtownUserName__c != null && student.EtownUserName__c != '')
        {   
            Contact con = setStudentEliteCard(student);
            con = setEtownStudentInfo(student);
            try
            { 
                update con;
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }
        }
    }
    
    private Contact setEtownStudentInfo(Contact student)
    {
        if(student != null)
        {
            EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
            params.Username = student.EtownUserName__c;
            params.RequireSyncReschedule = (!student.IsRescheduleSynced__c);
            EtownCourseService.EtownLoadStudentResult result;
            try
            { 
                result = EtownCourseService.loadStudentInEtown(params);
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'An error occurred while calling Etown WebService. Error Message: ' + ex.getMessage()));
            }
            if(result != null && result.MemberInfo != null)
            {         
                EtownCourseService.EtownMemberInfo memberInfo = result.MemberInfo;
                EtownCourseService.EtownCourseRescheduleList reshceudles = memberInfo.RescheduleList;
                String currentLevel = memberInfo.CurrentLevel;
                String currentSchool = memberInfo.CurrentSchool;
                String currentStatus = memberInfo.Status;
                if(result.IsSuccess)
                {
                    student.Status__c = currentStatus; 
                    student.StudyCenter__c = currentSchool;
                    student.CurrentLevel__c = currentLevel;
                    student.LastRefreshDate__c = System.now();
                    if(!student.IsRescheduleSynced__c)
                    {
                        createRescheduleRecords(student.Id, memberInfo.RescheduleList);
                        student.IsRescheduleSynced__c = true;
                    }
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result.ErrorMessage));
                }
            }
        }
        return student;
    }
    
    private Contact setStudentEliteCard(Contact contact)
    {
        if(contact != null)
        {
            StudentActual__c studentActual = EtownCourseHelper.getLastActiveStudentActual(contact.Id);
            if(studentActual != null)
            {     
                if(contact.EliteCard__c != studentActual.EliteCard__c)
                {
                    contact.EliteCard__c = studentActual.EliteCard__c;
                }   
                if(contact.Product__c != studentActual.StudentProducts__r[0].Id)
                {
                    contact.Product__c = studentActual.StudentProducts__r[0].Id;
                }            
            }
        }     
        return contact;
    }

    //sync course reschedule info from Etown, if the records is odd, we will create a matching course reschedule record.
    private static void createRescheduleRecords(Id contactId, EtownCourseService.EtownCourseRescheduleList reschedules)
    {
        if(reschedules != null)
        {
            if(reschedules.ReshceduleInfoList != null && reschedules.ReshceduleInfoList.size() != 0)
            {
                Boolean isSuccess = true;
                List<CourseReschedule__c> createdReschedules = new List<CourseReschedule__c>();
                for(EtownCourseService.EtownCourseRescheduleInfo info : reschedules.ReshceduleInfoList)
                {
                    CourseReschedule__c reschedule = new CourseReschedule__c();
                    reschedule.Contact__c = contactId;
                    reschedule.ScheduleJobId__c = info.OperateId;
                    reschedule.ScheduleDate__c = (info.OperateDate != null) ? info.OperateDate.dateGmt() : null;
                    reschedule.Type__c = info.OperateType;
                    reschedule.Status__c = 'Not start yet';
                    createdReschedules.add(reschedule);
                }
                if(Math.mod(reschedules.ReshceduleInfoList.size(), 2) != 0)
                {
                    List<EtownCourseService.EtownCourseRescheduleInfo> rescheduleInfos = sortRescheduleRecordsByAsc(reschedules.ReshceduleInfoList);
                    if(rescheduleInfos[0].OperateType == 'Resume')
                    {
                        CourseReschedule__c reschedule = new CourseReschedule__c();
                        reschedule.Contact__c = contactId;
                        reschedule.ScheduleDate__c = Date.newInstance(1900, 01, 01);
                        reschedule.Type__c = 'Suspend';
                        reschedule.Status__c = 'Completed';
                        createdReschedules.add(reschedule);
                    }
                    else
                    {
                        isSuccess = false;
                    }
                }
                if(isSuccess)
                {
                    try
                    {
                        insert createdReschedules;
                    }
                    catch(Exception ex)
                    {
                        isSuccess = false;
                    }
                }
                else
                {
                    EtownCourseHelper.sendErrorInfoEmail('Failed to sync reschedule infomation', 'Please check the Etwon Reschedule record. Contact Id:' + contactId);
                }
            }
        }
    }
    
    private static List<EtownCourseService.EtownCourseRescheduleInfo> sortRescheduleRecordsByAsc(List<EtownCourseService.EtownCourseRescheduleInfo> rescheduleInfos)
    {
        if(rescheduleInfos != null)
        {
            Boolean isExchanged = false;
            EtownCourseService.EtownCourseRescheduleInfo temp;
            Integer len = rescheduleInfos.size();
            for(Integer i = 0; i < len - 1; i++)
            {
                for(Integer j = len - 1; j > i; j--)
                {
                    EtownCourseService.EtownCourseRescheduleInfo nInfo = rescheduleInfos[j];
                    EtownCourseService.EtownCourseRescheduleInfo pInfo = rescheduleInfos[j-1];
                    if(nInfo.OperateDate < pInfo.OperateDate)
                    {
                        temp = nInfo;
                        rescheduleInfos[j] = pInfo;
                        rescheduleInfos[j-1] = temp;
                        isExchanged = true;
                    }
                }
                if(!isExchanged)
                {
                    break;
                }
            }
        }
        return rescheduleInfos;
    }

    public class RescheduleInfo
    { 
        public Id SuspendId { get; set; }
        public Id ResumeId { get; set; }
        public String CourseRescheduleName { get; set; }
        public String Subject { get; set; }
        public Date SuspendDate { get; set; }
        public Date ResumeDate { get; set; }
        public String Status { get; set; }
        public String SuspendStatus { get; set; }
        public String ResumeStatus { get; set; }
        public String SuspendActionStatus { get; set; }
        public String ResumeActionStatus { get; set; }
        public String ContactName { get; set; }
        public String StudentActualName { get; set; }
        public Integer Duration { get; set; }
        public String SuspendReason { get; set; }
        public Integer SuspendScheduleJobId { get; set; }
        public Integer ResumeScheduleJobId { get; set; }
        public String SuspendType { get; set; }
        public String ResumeType { get; set; }
        public DateTime SuspendActionDate { get; set; }
        public DateTime ResumeActionDate { get; set; }
    }
    
    @isTest
    static void testOverrideContactPageController()
    {
        Contact contact = new Contact(LastName='Acme', OwnerId=UserInfo.getUserId(), EtownUserName__c = 'test1212', EliteCard__c = '1234');
        insert contact;
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c testSA = new StudentActual__c(Actual__c = testActual.Id, Student__c = contact.Id, EliteCard__c = '12367', CourseActivationDate__c=Date.today());
        insert testSA;
        Product2 testProduct = new Product2(Name='Premium 10', EtownId__c='test123', IsLevel__c=true, IsActivable__c=true, Family='Smart Product List');
        insert testProduct;
        StudentProduct__c testSP = new StudentProduct__c(Name = 'acme test', Status__c = 'Activated', Product__c = testProduct.Id, StudentActual__c = testSA.Id);
        insert testSP;
        
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>
        {
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Completed', Type__c = 'Suspend', ScheduleJobId__c = 4356, Duration__c = 7, ScheduleDate__c = Date.today()),
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Resume', ScheduleJobId__c = 5436, Duration__c = 7, ScheduleDate__c = Date.today().addDays(7))
        };
        insert courseReschedules;
        
        ApexPages.StandardController controller = new ApexPages.StandardController(contact);
        OverrideContactPageController con = new OverrideContactPageController(controller);
        con.redirectAndUpdateContact();
        system.assert(con.Reschedules.size() > 0);
    }
}