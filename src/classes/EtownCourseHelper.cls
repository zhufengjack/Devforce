/*
 * A helper class for reschedule student course
 */
public class EtownCourseHelper 
{
    public enum ActionType { SUSPEND, RESUME } 
    
    //updates status and date of contact, students actual and student product when Etown calls SF EtownCourseSerivce webservice
    public static void updateStatusAndDate(StudentActionParams actionParams)
    {
        if(actionParams != null)
        { 
            String status = '';
            String newStatus = '';
            Boolean isNeedUpdateDate = false;
            Integer memberId = actionParams.MemberId;
            Integer operateId = actionParams.OperateId;
            ActionType actionTypeName = actionParams.ActionTypeName;
            if(actionTypeName == ActionType.SUSPEND)
            {
                status = 'Activated';
                newStatus = 'Suspended';
                isNeedUpdateDate = true;
            }
            else if(actionTypeName == ActionType.RESUME)
            {
                status = 'Suspended';
                newStatus = 'Activated';
            }
            
            List<Contact> contacts = [select Id, (select Id, Status__c, OrderStartDate__c, OrderEndDate__c from Student_Actuals__r where OrderStartDate__c != null and OrderEndDate__c != null order by OrderStartDate__c) from Contact where EtownMemberId__c != null and EtownMemberId__c = :memberId];
            if(contacts.size() > 0)
            {
                List<CourseReschedule__c> crs = [select Id, Duration__c, ScheduleDate__c, ActionStatus__c from CourseReschedule__c where Contact__c = : contacts[0].Id and ScheduleJobId__c != null and ScheduleJobId__c = :operateId limit 1];
                if(crs.size() > 0)
                {
                    CourseReschedule__c reschedule = crs[0];
                    Savepoint sp = Database.setSavepoint();
                    try
                    {
                        updateStatus(contacts, status, newStatus);
                        if(isNeedUpdateDate)
                        {
                            updateDate(contacts, Integer.valueOf(reschedule.Duration__c), reschedule.ScheduleDate__c);
                        }
                        else if(reschedule.ActionStatus__c == 'Manually')
                        {
                            Integer duration = reschedule.ScheduleDate__c.daysBetween(Date.today());
                            updateDate(contacts, duration, reschedule.ScheduleDate__c);
                        }
                        updateCourseRescheduleStatus(reschedule);
                    }
                    catch(Exception ex)
                    {
                        Database.rollback(sp);
                        throw(ex);
                    }
                }
            }
        }
    }
    
    //updates status of contact, student actual and student product 
    public static void updateStatus(List<Contact> contacts, String status, String newStatus)
    {
        if(contacts.size() > 0)
        {
            Contact contact = contacts[0];
            contact.Status__c = (newStatus == 'Activated') ? 'Active' : newStatus;
            
            List<StudentActual__c> updatedStuActuals = new List<StudentActual__c>();
            Set<Id> studentActualIds = new Set<Id>();
            for(StudentActual__c sa : contact.Student_Actuals__r)
            {
                if(sa.Status__c == status)
                {
                    sa.Status__c = newStatus;
                    updatedStuActuals.add(sa);
                    studentActualIds.add(sa.Id);
                }
            }
            
            List<StudentProduct__c> updatedStuProds = new List<StudentProduct__c>();
            List<StudentProduct__c> stuProducts = [select Id from StudentProduct__c where StudentActual__c in :studentActualIds and Status__c = :status];
            for(StudentProduct__c sp : stuProducts)
            {
                sp.Status__c = newStatus;
                updatedStuProds.add(sp);
            }
            
            try
            {
                update contact;
                update updatedStuActuals;
                update updatedStuProds;
            }
            catch(Exception ex)
            {
                String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                throw new EtownCourseHelperException('An error occurred while trying to call UpdateStatus method: \r\n' + error);
            }
        }
    }
    
    //updates date of student actuals
    public static void updateDate(List<Contact> contacts, Integer duration, Date suspendDate)
    {
        if(contacts.size() > 0)
        {
            if(duration != null && suspendDate != null)
            {
                Contact contact = contacts[0];
                List<StudentActual__c> updatedStudentActuals = new List<StudentActual__c>();
                for(StudentActual__c sa : contact.Student_Actuals__r)
                {
                    if(sa.OrderStartDate__c <= suspendDate && sa.OrderEndDate__c >= suspendDate)
                    {
                        sa.OrderEndDate__c = sa.OrderEndDate__c.addDays(duration);
                        updatedStudentActuals.add(sa);
                    }
                    else if(sa.OrderStartDate__c > suspendDate && sa.OrderEndDate__c > suspendDate)
                    {
                        sa.OrderStartDate__c = sa.OrderStartDate__c.addDays(duration);
                        sa.OrderEndDate__c = sa.OrderEndDate__c.addDays(duration);
                        updatedStudentActuals.add(sa);
                    }
                }
                try
                {
                    update updatedStudentActuals;
                }   
                catch(Exception ex)
                {
                    String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                    throw new EtownCourseHelperException('An error occurred while trying to call updateStuActualDate method: \r\n' + error);
                }
            }
            else
            {
                throw new EtownCourseHelperException('Duration or ScheduleDate of CourseReschedule is invalid.');
            }
        }
    }
    
    public static void updateCourseRescheduleStatus(CourseReschedule__c reschedule)
    {
        if(reschedule != null && reschedule.Id != null)
        {
            reschedule.Status__c = 'Completed';
            reschedule.ActionDate__c = DateTime.now();
            try
            {
                update reschedule;
            }
            catch(Exception ex)
            {
                String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
                throw new EtownCourseHelperException('An error occurred while trying to call updateCourseRescheduleStatus method: \r\n' + error);
            }
        }
    }
    
    // gets CourseReschedule from the same group
    public static CourseReschedule__c getCorrectSchedule(Id contactId, String courseRescheduleType, Date courseRescheduleDate)
    {
        CourseReschedule__c result;
        if(courseRescheduleType != null && courseRescheduleDate != null && contactId != null)
        {
            if(courseRescheduleType == 'Resume')
            {
                List<CourseReschedule__c> courseReschedules = [select Id, Name, CreatedDate, CreatedById, LastModifiedDate, Type__c, Duration__c, SuspendReason__c, ScheduleDate__c, ScheduleJobId__c, Contact__c, Subject__c, StudentActual__c, ActionStatus__c, Status__c from CourseReschedule__c where (Status__c = 'Completed' or Status__c = 'Not start yet') and Type__c = 'Suspend' and Contact__c = :contactId and ScheduleDate__c <= :courseRescheduleDate order by ScheduleDate__c desc limit 1];
                if(courseReschedules.size() > 0)
                {
                    result = courseReschedules[0];
                }  
            }
            if(courseRescheduleType == 'Suspend')
            {
                List<CourseReschedule__c> courseReschedules = [select Id, Name, CreatedDate, CreatedById, LastModifiedDate, Type__c, Duration__c, SuspendReason__c, ScheduleJobId__c, ScheduleDate__c, Contact__c, Subject__c, StudentActual__c, ActionStatus__c, Status__c from CourseReschedule__c where (Status__c = 'Completed' or Status__c = 'Not start yet') and Type__c = 'Resume' and Contact__c = :contactId and ScheduleDate__c >= :courseRescheduleDate order by ScheduleDate__c asc limit 1];
                if(courseReschedules.size() > 0)
                {
                    result = courseReschedules[0];
                } 
            }
        }
        return result;
    }
    
    // gets Gmt date time, time always is Chinese Time
    public static DateTime getGMTDateTime(Date myDate)
    {
        String[] parts = myDate.format().split('/');
        String day = parts[0];
        String month = parts[1];      //00:00 - 24:00
        String year = parts[2];
        DateTime myDateTime = Datetime.newInstanceGmt(Integer.valueOf(year), Integer.valueOf(month), Integer.valueOf(day), 0, 0, 0);
        return myDateTime.addHours(-8);
    }
     
    public static void sendErrorInfoEmail(String subject, String content)
    {
        SendEmailHelper.sendExceptionEmail('sf@ef.com', subject, content);
    }
        
    //gets the current student actual and last active sutdent actual    
    public static CourseDataInfo parseStudentActual(String studentActualId)
    {
        CourseDataInfo result = new CourseDataInfo();
        List<StudentActual__c> currentStudentActuals = [select Id, Student__c, StartingLevel__c, Student__r.StartingLevel__c, Student__r.Status__c,
                                                        (Select Product__r.Name, Product__r.EtownId__c, Product__r.IsLevel__c from StudentProducts__r where Product__r.Family != 'Smart Non-Standard Product List' limit 1) from StudentActual__c 
                                                        where Id = :studentActualId];
        if(currentStudentActuals.size() > 0)
        {
            result.CurrentStudentActual = currentStudentActuals[0];
            result.CurrentStudentProduct = (currentStudentActuals[0].StudentProducts__r.size() > 0) ? currentStudentActuals[0].StudentProducts__r[0] : null;
            String studentId = currentStudentActuals[0].Student__c;
            //gets last active sutdent actual   
            StudentActual__c olderStudentActual = getLastActiveStudentActual(studentId);
            if(olderStudentActual != null)
            {
                result.OlderStudentActual = olderStudentActual;
                result.OlderStudentProduct = olderStudentActual.StudentProducts__r[0];
            }
        }
        return processStudentActual(result);
    }
    
    public static StudentActual__c getLastActiveStudentActual(String studentId)
    {
        StudentActual__c studentActual;
        List<StudentActual__c> studentActuals = [select Id, EliteCard__c, StartingLevel__c, Student__r.StartingLevel__c, Student__r.Status__c,
                                                   (Select Id, Product__r.Name, Product__r.EtownId__c, Product__r.IsLevel__c from StudentProducts__r where Product__r.Family != 'Smart Non-Standard Product List' limit 1) from StudentActual__c 
                                                    where Student__c = :studentId and CourseActivationDate__c != null  
                                                    order by CourseActivationDate__c desc nulls last, OrderStartDate__c desc nulls last, LastModifiedDate desc nulls last limit 1];
        if(studentActuals.size() > 0 && studentActuals[0].StudentProducts__r.size() > 0) 
        {
            studentActual = studentActuals[0];
        }
        return studentActual;
    }

    private static CourseDataInfo processStudentActual(CourseDataInfo dataInfo)
    {
        CourseDataInfo result = dataInfo;
        if(result.CurrentStudentActual.StartingLevel__c == null)
        {
            if(result.OlderStudentActual == null)
            {
                result.IsFirstSP = true;
                result.IsLength2Level = false;
            }
            else
            {
                result.IsFirstSP = false;
                result.IsLength2Level = isLength2Level(result);
            }
            result.IsAlumniClub = isAlumniClub(result);
        }
        else
        {
            result.HasLevelValue = true;
        }
        return result;
    }
    
    private static Boolean isLength2Level(CourseDataInfo dataInfo)
    {
        Boolean result = false;
        if(dataInfo.CurrentStudentActual != null && dataInfo.OlderStudentActual != null)
        {
            StudentProduct__c currentStudentProduct = dataInfo.CurrentStudentProduct;
            StudentProduct__c olderStudentProduct = dataInfo.OlderStudentProduct;
            Boolean currentProductIsLevel = (currentStudentProduct != null) ? currentStudentProduct.Product__r.IsLevel__c : false;
            Boolean olderProductIsLevel = (olderStudentProduct != null) ? olderStudentProduct.Product__r.IsLevel__c : false;
            if(!olderProductIsLevel && currentProductIsLevel)
            {
                result = true;
            }
        }
        return result;
    }
    
    private static Boolean isAlumniClub(CourseDataInfo dataInfo)
    {
        Boolean result = false;
        if(dataInfo.CurrentStudentActual != null && dataInfo.CurrentStudentActual.StudentProducts__r.size() > 0 && dataInfo.CurrentStudentActual.StudentProducts__r[0].Product__r.Name == 'Alumni Club')
        {
            result = true;
        }
        if(dataInfo.OlderStudentActual != null && dataInfo.OlderStudentActual.StudentProducts__r.size() > 0 && dataInfo.OlderStudentActual.StudentProducts__r[0].Product__r.Name == 'Alumni Club')
        {
            result = true;
        }
        return result;
    }
    
    public class CourseDataInfo
    {
        public CourseDataInfo()
        {
            this.HasLevelValue = false;
            this.IsFirstSP = false;
            this.IsAlumniClub = false;
            this.IsLength2Level = false;
        }
        
        public Boolean HasLevelValue { get; set; }
        public Boolean IsFirstSP { get; set; }
        public Boolean IsAlumniClub { get; set; }
        public Boolean IsLength2Level { get; set; }
        public StudentProduct__c CurrentStudentProduct { get; set; }
        public StudentProduct__c OlderStudentProduct { get; set; }
        public StudentActual__c CurrentStudentActual { get; set; }
        public StudentActual__c OlderStudentActual { get; set; }
    }
    
    public class StudentActionParams
    {
        public Integer MemberId { get; set; }
        public Integer OperateId { get; set; }
        public ActionType ActionTypeName { get; set; }
    }
   
    public class EtownCourseHelperException extends Exception { }
    
    @isTest
    static void testEtownCourseHelper()
    {
        List<Account> accounts = new List<Account>{
                            new Account(Name = 'acme1'),
                            new Account(Name = 'acme2'),
                            new Account(Name = 'acme2') };
        
        insert accounts;
        Contact contact = new Contact(LastName = 'acme', AccountId = accounts[0].Id, EtownMemberId__c = 9801);
        insert contact;
        List<Contact> contacts = new List<Contact>{
            new Contact(LastName = 'acme', AccountId = accounts[1].Id, EtownMemberId__c = 00102034),
            new Contact(LastName = 'acme test', AccountId = accounts[2].Id, EtownMemberId__c = 000010243)
        };
        insert contacts;
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c testSA = new StudentActual__c(Actual__c = testActual.Id, Status__c = 'Activated', OrderStartDate__c = Date.today(), OrderEndDate__c = Date.today().addDays(30), Student__c = contact.Id);
        insert testSA;
        StudentProduct__c testSP = new StudentProduct__c(Name = 'acme test', Status__c = 'Activated', StudentActual__c = testSA.Id);
        insert testSP;
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>{
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Suspend', ActionStatus__c = 'Manually', ScheduleJobId__c = 4356, Duration__c = 7, ScheduleDate__c = Date.today()),
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not start yet', Type__c = 'Resume', ScheduleJobId__c = 5436, Duration__c = 7, ScheduleDate__c = Date.today().addDays(7))
        };
        insert courseReschedules;
        
        EtownCourseHelper helper = new EtownCourseHelper();
        EtownCourseHelper.StudentActionParams params = new EtownCourseHelper.StudentActionParams();
        params.ActionTypeName = EtownCourseHelper.ActionType.RESUME;
        params.ActionTypeName = EtownCourseHelper.ActionType.SUSPEND;
        params.MemberId = 9801;
        params.OperateId = 4356;
        EtownCourseHelper.updateStatusAndDate(params);
        EtownCourseHelper.getCorrectSchedule(contact.Id, 'Suspend', Date.today());
        EtownCourseHelper.getCorrectSchedule(contact.Id, 'Resume', Date.today().addDays(7));
        EtownCourseHelper.sendErrorInfoEmail('test', 'error');
        EtownCourseHelper.updateCourseRescheduleStatus(courseReschedules[0]);
        EtownCourseHelper.updateDate(contacts, 7, Date.today().addDays(-1));
        EtownCourseHelper.getGMTDateTime(Date.today());
    }
    
    @isTest
    static void testParseStudentActual()
    {
        Account company  = new Account(Name='test company');
        insert company;
        Contact student1 = new Contact(LastName='studentName1', AccountId=company.Id);
        insert student1;
        Actual__c actual1 = new Actual__c(Account__c=company.Id);
        Actual__c actual2 = new Actual__c(Account__c=company.Id);
        Actual__c actual3 = new Actual__c(Account__c=company.Id);
        insert new List<Actual__c> { actual1, actual2, actual3};
        StudentActual__c studentActual1 = new StudentActual__c(Actual__c=actual1.Id, Student__c=student1.Id);
        StudentActual__c studentActual2 = new StudentActual__c(Actual__c=actual2.Id, Student__c=student1.Id, CourseActivationDate__c=Date.today());
        StudentActual__c studentActual3 = new StudentActual__c(Actual__c=actual3.Id, Student__c=student1.Id);
        insert new List<StudentActual__c> { studentActual1, studentActual2, studentActual3};
        Product2 testProduct1 = new Product2(Name='test Product', EtownId__c='test124', IsLevel__c=false, IsActivable__c=true, Family='Smart Prodcut List'); 
        Product2 testProduct2 = new Product2(Name='Premium 10', EtownId__c='test123', IsLevel__c=true, IsActivable__c=true, Family='Smart Product List'); 
        Product2 testProduct3 = new Product2(Name='Alumni Club', EtownId__c='test125', IsLevel__c=true, IsActivable__c=true, Family='Smart Porduct List');
        insert new List<Product2>{ testProduct1, testProduct2, testProduct3};
        StudentProduct__c studentProduct1 = new StudentProduct__c(Product__c=testProduct1.Id, StudentActual__c=studentActual1.Id);
        StudentProduct__c studentProduct2 = new StudentProduct__c(Product__c=testProduct2.Id, StudentActual__c=studentActual2.Id);
        StudentProduct__c studentProduct3 = new StudentProduct__c(Product__c=testProduct3.Id, StudentActual__c=studentActual3.Id);
        insert new List<StudentProduct__c>{ studentProduct1, studentProduct2, studentProduct3 };
        
        EtownCourseHelper.CourseDataInfo info = new EtownCourseHelper.CourseDataInfo();
        info = EtownCourseHelper.parseStudentActual(studentActual1.Id);
        System.assertEquals(studentActual2.Id, info.OlderStudentActual.Id);
        
        studentActual2.OrderStartDate__c = Date.today();
        update studentActual2;
        info = EtownCourseHelper.parseStudentActual(studentActual1.Id);
        System.assertEquals(studentActual2.Id, info.OlderStudentActual.Id);
        
        studentActual3.CourseActivationDate__c = Date.today();
        studentActual3.OrderStartDate__c = Date.today().addDays(10);
        update studentActual3;
        info = EtownCourseHelper.parseStudentActual(studentActual1.Id);
        System.assertEquals(studentActual3.Id, info.OlderStudentActual.Id);
    }
}