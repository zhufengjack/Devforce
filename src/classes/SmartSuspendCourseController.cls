/*
 *A controller of page Suspend Cource 
 */
public class SmartSuspendCourseController 
{
    private String studentId;
    private Contact student;  
    
    public SmartSuspendCourseController()
    {
        studentId = ApexPages.currentPage().getParameters().get('id');
        List<Contact> contacts = [select Id, Status__c, EtownMemberId__c from Contact where Id = :studentId limit 1];
        if(contacts.size() > 0)
        {
            student = contacts[0];
            if(student.Status__c == 'Expired')
            {
            	IsValidContactStatus = false;
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Can\'t suspend, the student is expired already.'));
            }
            else if(student.Status__c == 'Inactive')
            {
            	IsValidContactStatus = false;
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Can\'t suspend, the student is not activated yet.'));
            }
            else if(student.Status__c == null || student.Status__c == '')
            {
            	IsValidContactStatus = false;
            	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Student status must be activated or suspended!'));
            }
            else
            {
            	IsValidContactStatus = true;
            }
            CurrentContactUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/' + contacts[0].Id;
        }
        ShowPage = 1;
        Reschedule = new RescheduleInfo();
    }
    
    public Boolean IsValidContactStatus { get; set; }
    public String EtownErrorMessage { get; set; }
    public String CurrentContactUrl { get; set; }
    public RescheduleInfo Reschedule { get; set; }
    public Boolean ShowConfirmPage { get; set; }  //ShowPage=1 contains two pages
    public Integer ShowPage { get; set; } /*a property used to show different pages
                                          *ShowPage=1, show submit page * ShowPage=2, show confirm page * ShowPage=3, show try again page * ShowPage=4, show close page  */
    public String DateToday
    {
        get
        {
            return DateTime.now().format('dd/MM/yyyy');
        }
    }
      
    // if the date is a valid suspend date
    private Boolean isValidSuspensionDate()
    {
        Boolean valid = true;
        if(Reschedule.SuspensionDate >= Reschedule.ResumeDate)
        {
            valid = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Resume date can not be smaller than start date.'));
        }
        else if(Reschedule.SuspensionDate <= Date.today())
        {
            valid = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'You can only set suspension start date later than current date.'));
        }
        else if(isOverlapSuspensionDate())
        {
           valid = false;
           ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The date is not valid, please choose again.'));
        }
        else 
        {
    		valid = isCorrectCourseDuration();
        }
        return valid;
    }
    
    public PageReference submit()
    {
        ShowConfirmPage = isValidSuspensionDate();
        return null;
    }
    
    public PageReference confirmSubmit()
    {
        if(Reschedule.SuspensionDate != null && Reschedule.ResumeDate != null)
        {
        	if(!isValidSuspensionDate())
        	{
        		return null;
        	}
            EtownCourseService.EtownSuspendResult suspendResult = requestEtownService();
            Integer duration = Reschedule.SuspensionDate.daysBetween(Reschedule.ResumeDate);
            List<StudentActual__c> matchedStudentActuals = [select Id from StudentActual__c where Student__c = :studentId and (Status__c = 'Activated' or Status__c = 'Suspended') and OrderStartDate__c <= :Reschedule.SuspensionDate and OrderEndDate__c > :Reschedule.SuspensionDate limit 1];
            StudentActual__c matchedStudentActual = (matchedStudentActuals.size() > 0) ? matchedStudentActuals[0] : null;
            if(suspendResult != null && suspendResult.IsSuccess) 
            {
                Id studentActualId = (matchedStudentActual != null) ? matchedStudentActual.Id : null;
                createCourseReschedule(studentActualId, Reschedule.SuspensionDate, 'Suspend', suspendResult.SuspendOperateId, Reschedule.SuspendReason, duration);
                createCourseReschedule(studentActualId, Reschedule.ResumeDate, 'Resume', suspendResult.ResumeOperateId, Reschedule.SuspendReason, duration);
                ShowPage = 2;  //if the result is successful
            }
            else
            {
                if(ShowPage == 1)
                {
                    ShowPage = 3;
                }
                else
                {
                    ShowPage = 4;
                    EtownErrorMessage = (suspendResult == null)? 'Error occurred while calling Etown server.' : suspendResult.ErrorMessage;
                }
            }
        }
        return null;
    }
    
    // if submit failed, show confirm page to try again
    public PageReference tryAgain()
    {
        confirmSubmit();
        return null;
    }
    
    //the suspension date can not overlap
    private Boolean isOverlapSuspensionDate()
    {
    	Boolean result = false;
    	List<CourseReschedule__c> courseReschedules = [select Id, Status__c, Type__c, Contact__c, ScheduleJobId__c, ScheduleDate__c from CourseReschedule__c where Contact__c = :student.Id and (Status__c = 'Not start yet' or Status__c = 'Completed') order by CreatedDate limit 2000];
        if(courseReschedules.size() > 0)
        {
        	for(Integer i = 0; i < courseReschedules.size(); i++)
        	{
    			if(Math.mod(i, 2) == 0 && i+1 < courseReschedules.size())
    			{
    				Date previousSuspendDate = courseReschedules[i].ScheduleDate__c;
    				Date previousResumeDate = courseReschedules[i+1].ScheduleDate__c;
	    			if((Reschedule.SuspensionDate >= previousSuspendDate && Reschedule.SuspensionDate <= previousResumeDate) || (Reschedule.ResumeDate >= previousSuspendDate && Reschedule.ResumeDate <= previousResumeDate))
		        	{
		        		result = true;
		        	}
		        	else if(Reschedule.SuspensionDate <= previousSuspendDate && Reschedule.ResumeDate >= previousSuspendDate)
					{
						result = true;
					}
					else
					{
						result = false;
					}
    			}
        	}
        }
        return result;
    }
    
    // gets the student actuals which contain the main student product
    private Set<Id> getMainStudentActuals()
    {
        Set<Id> mainStudentActualIds = new Set<Id>();
        List<StudentActual__c> allStudentAcutuals = [select Id, (select Id from StudentProducts__r where Product__c != null and Product__r.Family != 'Smart Non-Standard Product List') from StudentActual__c where (Status__c = 'Activated' or Status__c = 'Suspended') and Student__c = :student.Id];
        for(StudentActual__c studentActual : allStudentAcutuals)
        {
            List<StudentProduct__c> studentProducts = studentActual.StudentProducts__r;
            if(studentProducts.size() > 0)
            {
                mainStudentActualIds.add(studentActual.Id);
            }   
        }
        return mainStudentActualIds;
    }
    
    //whether the suspension date is in the correct course duration
    private Boolean isCorrectCourseDuration()
    {
    	Boolean result = true;
    	Set<Id> mainStudentActualIds = getMainStudentActuals();
        if(mainStudentActualIds.size() > 0)
        {
            Integer actualsWithoutDate = [select count() from StudentActual__c where Id in :mainStudentActualIds and (Status__c = 'Activated' or Status__c = 'Suspended') and Student__c = :studentId and (OrderStartDate__c = null or OrderEndDate__c = null)];
            if(actualsWithoutDate == 0)
            {
                AggregateResult[] results = [select max(OrderEndDate__c) max, min(OrderStartDate__c) min from StudentActual__c where Id in :mainStudentActualIds and (Status__c = 'Activated' or Status__c = 'Suspended') and Student__c = :studentId and OrderStartDate__c != null and OrderEndDate__c != null];
                Date minDate = (Date)results[0].get('min');
                Date maxDate = (Date)results[0].get('max');
                if(minDate != null && maxDate != null)
                {
                    if(Reschedule.SuspensionDate >= maxDate)
                    {
                        result = false;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The suspend date is not in the student course duration, please choose again.'));
                    }
                    else if(Reschedule.SuspensionDate < minDate)
                    {
                        result = false;
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'The suspend date is not in the student course duration, please choose again.'));
                    }
                }
                else
                {
                    result = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'There are no rightful student actuals.'));
                }
            }
        }
        else
        {
        	result = false;
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'There are no active or suspended main products, please check the student actual of this contact.'));
        }
        return result;
    }
    
    // requests etown system
    private EtownCourseService.EtownSuspendResult requestEtownService()
    {
        // call etown web services 
        EtownCourseService.EtownSuspendParams params = new EtownCourseService.EtownSuspendParams();
        if(student != null && student.EtownMemberId__c != null)
        {
            params.MemberId = Integer.valueOf(student.EtownMemberId__c); //?
        }
        params.SuspendDate = EtownCourseHelper.getGMTDateTime(Reschedule.SuspensionDate);
        params.ResumeDate = EtownCourseHelper.getGMTDateTime(Reschedule.ResumeDate);
        if(Reschedule.SuspendReason !=  null && Reschedule.SuspendReason != '')
        {
            params.ReasonCode = Reschedule.SuspendReason;
        }
        EtownCourseService.EtownSuspendResult result = null;
        try
        {
            result = EtownCourseService.suspendInEtown(params);
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Failed to suspend the student from Etown, the error message is: ' + ex.getMessage()));
        }
        return result;
    }
    
    private void createCourseReschedule(Id studentActualId, Date operateDate, String operateType, Integer operateId, String reason, Integer duration)
    {
        CourseReschedule__c CourseReschedule = new CourseReschedule__c();
        if(student != null && student.Id != null && operateId != null && operateType != null && operateDate != null && reason != null)
        {
            CourseReschedule.Contact__c = student.Id;
            CourseReschedule.StudentActual__c = studentActualId; 
            CourseReschedule.ScheduleJobId__c = operateId; 
            CourseReschedule.Type__c = operateType;
            CourseReschedule.Status__c = 'Not start yet';
            CourseReschedule.ActionStatus__c = 'Auto';
            CourseReschedule.ScheduleDate__c = operateDate;
            CourseReschedule.SuspendReason__c = reason;
            CourseReschedule.Duration__c = duration;
            Integer subjectCount = [select count() from CourseReschedule__c where Contact__c = :student.Id];
            subjectCount++;
            CourseReschedule.Subject__c = 'Suspension '+ subjectCount; 
            try
            {
                insert CourseReschedule;
            }
            catch(Exception ex) 
            {
                ApexPages.addMessages(ex);     
            }
        }
    }
        
    public class RescheduleInfo
    {
        public Date SuspensionDate;
        public Date ResumeDate;
        
        public String SuspensionDateInputValue 
        {
            get
            {
                String result = '';
                if(SuspensionDate != null)
                {
                    result = SuspensionDate.format();
                }
                return result;
            } 
            set
            {
                if(value != null)
                {
                    SuspensionDate = Date.parse(value);
                }
            }
        }  
        public String ResumeDateInputValue 
        {
            get 
            {
                String result = '';
                if(ResumeDate != null)
                {
                    result = ResumeDate.format();
                }
                return result;
            } 
            set
            {
                if(value != null)
                { 
                    ResumeDate = Date.parse(value);
                }
            }
        }
        public String SuspendReason { get; set; }
        public List<SelectOption> SuspendReasons
        {
            get
            {
                List<SelectOption> options = new List<SelectOption>();
                Schema.Describefieldresult fieldResult = CourseReschedule__c.SuspendReason__c.getDescribe();   
                List<Schema.PickListEntry> pickListEntries = fieldResult.getPickListValues();       
                for(Schema.PickListEntry entry : pickListEntries)
                {
                    options.add(new SelectOption(entry.getValue(), entry.getValue()));
                }
                return options;
            }
        } 
    }

    @isTest
    static void testSmartSuspendCourseController()
    {
        Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName = 'acme', AccountId = account.Id, EtownMemberId__c = 98014356);
        insert contact;
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c testSA = new StudentActual__c(Actual__c = testActual.Id, Status__c = 'Activated', OrderStartDate__c = Date.today(), OrderEndDate__c = Date.today().addDays(30), Student__c = contact.Id);
        insert testSA;
        StudentProduct__c testSP = new StudentProduct__c(Name = 'acme test', Status__c = 'Activated', StudentActual__c = testSA.Id);
        insert testSP;
        CourseReschedule__c course = new CourseReschedule__c(Contact__c = contact.Id);
        insert course;
        
        PageReference pageRef = new PageReference('/apex/SmartSuspendCourse?id='+contact.Id);
        Test.setCurrentPage(pageRef);
        SmartSuspendCourseController controller = new SmartSuspendCourseController();
        controller.student = contact;
        system.assert(controller.DateToday != null);
        SmartSuspendCourseController.RescheduleInfo info = controller.Reschedule;
        info.ResumeDate = Date.today().addDays(3);
        info.SuspensionDate = Date.today().addDays(1);
        info.SuspendReason = 'test reason';
        EtownCourseService.EtownSuspendResult suspendResult = new EtownCourseService.EtownSuspendResult(new EtownCourseRescheduleServiceDataContract.SuspendResult());
        suspendResult.ResumeOperateId = 111;
        suspendResult.SuspendOperateId = 112;
        suspendResult.IsSuccess = true;
        controller.createCourseReschedule(testSA.Id, info.SuspensionDate, 'Suspend', Integer.valueOf(suspendResult.SuspendOperateId), info.SuspendReason, 2);
        controller.submit();
        controller.confirmSubmit();
        controller.tryAgain();
    }
    
    @isTest
    static void testRescheduleInfo()
    {
        SmartSuspendCourseController controller = new SmartSuspendCourseController();
        SmartSuspendCourseController.RescheduleInfo info = controller.Reschedule;
        info.ResumeDate = Date.today().addDays(3);
        info.SuspensionDate = Date.today().addDays(4);
        info.SuspensionDateInputValue = '01/12/2011';
        info.ResumeDateInputValue = '01/12/2011';
        system.assert(info.SuspensionDateInputValue != null);
        system.assert(info.ResumeDateInputValue != null);
        system.assert(info.SuspendReasons.size() >= 0);
        controller.submit();
    }
    
    @isTest  
    static void testIsValidDate() 
    {
        Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName = 'acme', AccountId = account.Id, EtownMemberId__c = 98014356, Status__c = 'Expired');
        insert contact;
        Actual__c testActual = new Actual__c();
        insert testActual;
        List<StudentActual__c> testSAs = new List<StudentActual__c> 
        {
            new StudentActual__c(Actual__c = testActual.Id, Status__c = 'Activated', OrderStartDate__c = Date.today(), OrderEndDate__c = Date.today().addDays(5), Student__c = contact.Id),
            new StudentActual__c(Actual__c = testActual.Id, Status__c = 'Activated', OrderStartDate__c = Date.today().addDays(1), OrderEndDate__c = Date.today().addDays(10), Student__c = contact.Id)
        };
        insert testSAs;
        Product2 mainProd = new Product2(Name='12 Month Etown');
        insert mainProd;
        StudentProduct__c studentProduct = new StudentProduct__c(Name = '12 Month Etown', Price__c = 9999, Status__c = 'Activated', Quantity__c = 1, Product__c = mainProd.Id, StudentActual__c = testSAs[0].Id);
        insert studentProduct;
        PageReference pageRef = new PageReference('/apex/SmartSuspendCourse?id='+contact.Id);
        Test.setCurrentPage(pageRef);
        
        SmartSuspendCourseController controller = new SmartSuspendCourseController();
        SmartSuspendCourseController.RescheduleInfo info = controller.Reschedule;
        info.SuspensionDate = Date.today().addDays(20);
        info.ResumeDate = Date.today().addDays(22);
        controller.submit();
        system.assertEquals(controller.isValidSuspensionDate(), false);
        
        info.SuspensionDate = Date.today().addDays(-2);   
        info.ResumeDate = Date.today().addDays(-1);
        controller.submit();  
        system.assertEquals(controller.isValidSuspensionDate(), false);
    }
}