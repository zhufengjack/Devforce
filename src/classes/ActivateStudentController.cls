/*
 * A controller for page "Activate Student" and page "ActivateStudentConfirmation".
 */ 
public class ActivateStudentController 
{ 
    private Contact student;
    
    public ActivateStudentController()
    {
        String studentId = ApexPages.currentPage().getParameters().get('id');
        userNameExist = false;
        try
        {
           	student = [select Id, Name, Email, Phone, MobilePhone, EtownUserName__c,  Status__c,  CurrentLevel__c, StudyCenter__c, EtownMemberId__c, IsRescheduleSynced__c from Contact where Id = :studentId];
            StudentUsername = student.EtownUserName__c;
            if(StudentUsername != null && StudentUsername != '')
            {
                throw new UserNameExistException('Can\'t map Student again.');
            }
        }
        catch(UserNameExistException ex)
        {   // If user name exist on current contact, can't map student again.
            userNameExist = true;
            ApexPages.addMessages(ex);
        }
        catch(Exception ex)
        {
            ex.setMessage('No student found');
            ApexPages.addMessages(ex);
        }
    }
  	
  	public String StudentUsername { get; set; }
    public MatchInfo SalesforceStudentInfo { get; set; } // Stores information for salesforce student.
    public MatchInfo EnglishtownStudentInfo { get; set; } // Stores information from Etown.
    public Boolean userNameExist { get; set; }
    
    public PageReference next()
    {
        try
        {
            checkUserName(StudentUsername); // Check user name in SF and Etown.
            // Redirect to confirm page.
            PageReference confirmPage = Page.ActivateStudentConfirmation;
            return confirmPage;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return null;
        } 
    }
    
    private void checkUserName(String name)
    {
    	// Checks duplicated Etown user name.
        List<Contact> studentList = [select Id, Name from Contact where EtownUserName__c = :name and Id != :student.Id limit 1];
        if(studentList.size() > 0)
        {
            throw new UserNameExistException('The user name entered already exists in Salesforce, linking to<a href="/' + studentList[0].Id + '" target="_blank"><span style="font-size:13px;">' + studentList[0].Name + '</span></a>, pls check whether the input is correct.');        
        }
        
        EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
        params.Username = name;
        params.RequireSyncReschedule = false;
        EtownCourseService.EtownLoadStudentResult result;
        try
        { 
            result = EtownCourseService.loadStudentInEtown(params);
        }
        catch(Exception ex)
        {
        	ex.setMessage('Failed to call Etown Sync Service.');
        	throw(ex);
        }
        
        if(result != null && result.MemberInfo != null)
        {
            EtownCourseService.EtownMemberInfo memberInfo = result.MemberInfo;
            
            Integer memberId = memberInfo.MemberId;
            String currentStatus = memberInfo.Status;
            String email = memberInfo.Email; 
            String phone = memberInfo.MobilePhone;
            if(result.IsSuccess)
            {
            	SalesforceStudentInfo = new MatchInfo(student.Name, student.Email, student.Phone, student.MobilePhone);
            	EnglishtownStudentInfo = new MatchInfo('', email, phone, memberId, currentStatus); 
            }
            else
            {
            	String message = 'Failed to call Etown Service, ' + ((result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode);
            	throw new UserNameExistException(message);
            }
        }
        else
        {
        	throw new UserNameExistException('Failed to call Etown Sync Service.');
        }
    }
    
    public void save()
    {
    	student.EtownUserName__c = StudentUsername;
        student.Status__c = EnglishtownStudentInfo.Status;
        student.CurrentLevel__c = EnglishtownStudentInfo.CurrentLevel;
        student.StudyCenter__c = EnglishtownStudentInfo.StudyCenter;
        student.EtownMemberId__c = EnglishtownStudentInfo.MemberId;
        try
        {
            update student;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<script type="text/javascript">closeWindow();</script>'));
        }
        catch(DmlException ex)
        {
            String statusCode = ex.getDmlStatusCode(0);
            if(statusCode == 'DUPLICATE_VALUE')
            {  
                String recordId = ex.getDmlMessage(0).split('id:').get(1); 
                recordId = recordId.trim();
                Contact record = [select Id, Name from Contact where Id = :recordId];
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The member id already exists in salesforce , linking to<a href="/' + recordId + '"><span style="font-size:13px;">' + record.Name + '</span></a>, pls double check.'));
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }
    
    public PageReference back()
    {
        return Page.ActivateStudent;
    }
    
    // Wraps information for page "Confirm Information".
    public class MatchInfo
    {
        public String StudentName { get; set; }
        public String Email { get; set; }
        public String Telephone { get; set; }
        public String Mobile { get; set; }
        public String Status { get; set; }
        public String CurrentLevel { get; set; }
        public String StudyCenter { get; set; }
        public Integer MemberId { get; set; }
        
        // Constructor for salesforce student.
        public MatchInfo(String name, String emailAddress, String phone, String mobilePhone)
        {
            StudentName = name;
            Email = emailAddress;
            Telephone = phone;
            Mobile = mobilePhone;
        }
        
        // Constructor for Etown student.
        public MatchInfo(String name, String emailAddress, String phone, Integer etwonMemberId, String etownStatus)
        {
            this(name, emailAddress, phone, '');
            MemberId = etwonMemberId;
            Status = etownStatus;
        }
    }

    public class UserNameExistException extends Exception{}
    
    @isTest
    static void testActivateStudentController()
    {
        Account company = new Account(Name = 'Virtual Company');
        insert company;
        Contact student = new Contact(AccountId = company.Id, LastName = 'student name');
        insert student;
        Actual__c actual = new Actual__c(Account__c = company.Id);
        insert actual;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, Student__c = student.Id, EliteCard__c = 'test-Elite-12345', StartingLevel__c = 'Elementary-Level 3', EntryCenter__c = 'BJ DZM');
        insert studentActual;
        Product2 product = new Product2(Name = 'Premium 10', Months__c = 5);
        insert product;
        StudentProduct__c studentProduct = new StudentProduct__c(Product__c = product.Id, StudentActual__c = studentActual.Id, LevelsPurchased__c = '10');
        insert studentProduct;
        ActivateStudentController testController = new ActivateStudentController();
        PageReference currentPage = new PageReference('/apex/ActivateStudent?id=' + student.Id);
        Test.setCurrentPage(currentPage);
        ActivateStudentController controller = new ActivateStudentController();
        controller.StudentUsername = 'testUserName01';
        MatchInfo match = new MatchInfo('testName', 'test@acme.com', '123456', 2345, 'Activate');
        controller.EnglishtownStudentInfo = match;
        controller.next();
        controller.save();
        System.assertNotEquals(null, controller.back());
        ActivateStudentController newController = new ActivateStudentController();
    }  
}