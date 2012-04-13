/*
 * A controller for page "Add Student Actuals"
 */
public class AddStudentActualsController 
{
    private List<SelectOption> entryCenters;
    private String actualId;
    
    public AddStudentActualsController()
    {
    	try
    	{
			actualId = ApexPages.currentPage().getParameters().get('id');
	        List<Actual__c> currentActuals = [select Id, Account__c, Opportunity__r.AccountId from Actual__c where Id = :actualId];
	
	        if(currentActuals.size() > 0)
	        {
	        	String opportunityAccountId;
	        	if(currentActuals[0].Opportunity__r != null)
	        	{
	        		opportunityAccountId = currentActuals[0].Opportunity__r.AccountId;
	        	} 
		        String accountId = (currentActuals[0].Account__c != null) ? currentActuals[0].Account__c : opportunityAccountId;
		        
		       	// selects all student under the account which id is accountId.
		        List<Contact> studentList = [select Id, Name, EtownMemberId__c, EntryCenter__c, IDNumber__c, (select Id, RefundAmount__c, Actual__c  from Student_Actuals__r order by CreatedDate ) from Contact where AccountId = :accountId and AccountId != null];  
		        Map<String, String> student2StudentActual = new Map<String, String>(); // If a student has student actual. This map stores contact id and student actual id.
		        Map<String, Contact> studentMap = new Map<String, Contact>(); 
		        Map<String, StudentActual__c> previousStudentActualMap = new Map<String, StudentActual__c>(); // last 2nd student actual map.
		        
		        String currentActualId = currentActuals[0].Id;
		        for(Contact student : studentList)
		        {
		            if(student.Student_Actuals__r.size() > 0)
		            {
		                student2StudentActual.put(student.Id, student.Student_Actuals__r.get(0).Id);
		                StudentActual__c previousStudentActual = null;
			            for(StudentActual__c studentActual : Student.Student_Actuals__r)
			            {
			            	if(studentActual.Actual__c == currentActualId)
			            	{
			            		break;
			            	}
			            	else
			            	{
			            		previousStudentActual = studentActual;
			            	}
			            }
			            // If find previous student actual, stores it in map.
			            if(previousStudentActual != null)
			            {
			            	previousStudentActualMap.put(student.Id, previousStudentActual);
			            }
		            }
		            studentMap.put(student.Id, student);
		        }
		        
		        // For student actuals have been existed in system.
		        StudentActuals = new List<StudentActualInfo>();
		        List<StudentActual__c> oldStudentActuals = [select Id, Name, Student__c, Student__r.Name, Student__r.EtownMemberId__c, Company_Portion__c, Invoice__c, EntryCenter__c, Actual__c from StudentActual__c where Actual__c = :currentActuals[0].Id];
		        Boolean isFirst;
		        for(StudentActual__c oldStudentActual : oldStudentActuals)
		        {
		            isFirst = (oldStudentActual.Id == student2StudentActual.get(oldStudentActual.Student__c)) ? true : false; 
		            Double originalRefundAmount = 0;
		           	if(!isFirst) 
		            {
		            	if(oldStudentActual.Student__c == null)
		            	{
		            		throw new AddStudentActualException('Student field can\'t be null, Please check student actual <a href=\'/'+ oldStudentActual.Id +'\'>' + oldStudentActual.Name + '</a>');
		            	}
		            	originalRefundAmount = (previousStudentActualMap.get(oldStudentActual.Student__c) != null) ? previousStudentActualMap.get(oldStudentActual.Student__c).RefundAmount__c : 0; 
		            }
		            studentMap.remove(oldStudentActual.Student__c);
		            StudentActuals.add(new StudentActualInfo(oldStudentActual.Name, oldStudentActual.Student__c, oldStudentActual.Invoice__c, oldStudentActual.Id, oldStudentActual.EntryCenter__c, true, false, isFirst, originalRefundAmount, null, oldStudentActual.Company_Portion__c));
		        }
		         
		        // For new student actuals. 
		        String currentCenter = getCurrentEntryCenter();
		        for(Contact newStudent : studentMap.values())  //studentMap contains only contact which does't have a student actual
		        {
		            isFirst = (student2StudentActual.get(newStudent.Id) == null) ? true : false;
		            Double originalRefundAmount = 0;
		            if(!isFirst)
		            {
		            	originalRefundAmount = (previousStudentActualMap.get(newStudent.Id) != null) ? previousStudentActualMap.get(newStudent.Id).RefundAmount__c : 0;
		            }
		            StudentActuals.add(new StudentActualInfo(newStudent.Name, newStudent.Id, currentCenter, false, true, isFirst, originalRefundAmount, newStudent.IDNumber__c));
		        }
	        }
    	}
    	catch(Exception ex)
    	{
    		ApexPages.addMessages(ex);    
    	}
    }   
	
	public List<StudentActualInfo> StudentActuals { get; set; }
	 
    public PageReference save()
    {
    	PageReference page;
        List<StudentActual__c> studentActualList = new List<StudentActual__c>();
        List<StudentActual__c> studentActualDeletedList = new List<StudentActual__c>();
        
        for(StudentActualInfo studentActual : StudentActuals)
        {
            if(studentActual.NotDeleted == true)
            {
                if(studentActual.StudentActualId == null || studentActual.StudentActualId == '')
                {
                    studentActualList.add(new StudentActual__c(Student__c = studentActual.StudentId , Invoice__c = studentActual.InvoiceNumber, Actual__c = actualId, Name = studentActual.StudentName, EntryCenter__c = studentActual.EntryCenter, OriginalRefundAmount__c = studentActual.OriginalRefundAmount, IDNumber__c = studentActual.idNumber, Company_Portion__c = studentActual.tempCompanyPortion));
                }
                else
                {
                	//update old student actuals
                    studentActualList.add(new StudentActual__c(Id = studentActual.StudentActualId, Invoice__c = studentActual.InvoiceNumber, EntryCenter__c = studentActual.EntryCenter, OriginalRefundAmount__c = studentActual.OriginalRefundAmount, Company_Portion__c = studentActual.tempCompanyPortion));
                }
            }
            else
            {
                if(studentActual.StudentActualId != null && studentActual.StudentActualId != '')
                {
                    studentActualDeletedList.add(new StudentActual__c(Id = studentActual.StudentActualId));
                }
            }
        }
        try
        {
            upsert studentActualList;
            delete studentActualDeletedList;
            
            page = new PageReference('/'+actualId);
            page.setRedirect(true);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return page;
    }

    public PageReference cancel()
    {
        PageReference page;
        if(actualId != null && actualId != '')
        {
        	page = new PageReference('/'+actualId);
        }
        else
        {
        	page = new PageReference('/a00/o');
        } 
        page.setRedirect(true);
        return page;
    }
 
	// Gets dynamic values for entry center picklist. 
    public List<SelectOption> getEntryCenterPicklistValues()
    {
        if(entryCenters == null)
        {
            entryCenters = new List<SelectOption>();
            Schema.Describefieldresult fieldResult = StudentActual__c.EntryCenter__c.getDescribe();
            List<Schema.Picklistentry> picklistEntries = fieldResult.getPicklistValues();
            for(Schema.Picklistentry entry : picklistEntries)
            {
                entryCenters.add(new SelectOption(entry.getValue(), entry.getValue()));
            }
        }
        return entryCenters;
    }
    
    // This method will get default entry center based on user role name.
    private String getCurrentEntryCenter()
    {
        User currentUser = [select Id, UserRole.Name, Profile.Name from User where Id = :UserInfo.getUserId()];
        String roleName = currentUser.UserRole.Name;
        String profileName = currentUser.Profile.Name;
        Integer splitIndex = roleName.indexOf('Finance User');
        if(splitIndex != -1)
        {
            String tempString = roleName.substring(0, splitIndex);
            tempString = tempString.replace('China', '');
            tempString = tempString.replace('_', ' ');
            return tempString.trim();
        }
        
        if(profileName == 'EF China Smart B2B CR User')
        {
        	Integer b2bIndex = roleName.indexOf('China Smart B2B ');
        	if(b2bIndex != -1)
        	{
        		String tempString = roleName.replace('China Smart B2B ', '');
        		tempString = tempString.substring(0, 2);
        		return 'B2B ' + tempString;
        	}
        }
        
        return 'Central';
    }

    public class StudentActualInfo
    {
    	private Decimal tempCompanyPortion;
    	
        public StudentActualInfo(String name, String contactId, String center, Boolean isNotDeleted, Boolean newRecord, Boolean firstActual, Double refundAmount, String idNumberValue)
        {
			StudentName = name;
            StudentId = contactId;
            EntryCenter = center;
            NotDeleted = isNotDeleted;
            IsNew = newRecord;
            IsFirstActual = firstActual;
            OriginalRefundAmount = refundAmount;
            idNumber = idNumberValue;
        }
        
        public StudentActualInfo(String name, String contactId, String invoice, String oldStudentActualId, String center, Boolean isNotDeleted, Boolean newRecord, Boolean firstActual, Double refundAmount, String idNumberValue, Decimal companyPortionValue)
        {
            StudentName = name;
            StudentId = contactId;
            InvoiceNumber = invoice;
            StudentActualId = oldStudentActualId;
            EntryCenter = center;
            NotDeleted = isNotDeleted;
            IsNew = newRecord;
            IsFirstActual = firstActual;
            OriginalRefundAmount = refundAmount;
            idNumber = idNumberValue;
            tempCompanyPortion = companyPortionValue;
        }
        
        public String StudentName { get; set; }
        public String StudentId { get; set; }
        public String InvoiceNumber { get; set; }
        public String StudentActualId { get; set; }
        public String EntryCenter { get; set; }
        public Boolean NotDeleted { get; set; }
        public Boolean IsNew { get; set; } // If the student actual have been not create, the value of "IsNew" is true.
        public Boolean IsFirstActual { get; set; } // If the student actual is student's first actual, the value of "IsFirstActual" is true. 
        public Double OriginalRefundAmount; // Stores refund amount on previous student actual.
        public String idNumber;
        public String CompanyPortion 
        {
        	get
        	{
        		String temp = '';
        		if(tempCompanyPortion != null)
        		{
        			temp = String.valueOf(tempCompanyPortion);
        		}
        		return temp;
        	}
        	 set
        	 {
        	 	try
        	 	{
	        	 	if(value != null)
	        	 	{
	        	 		tempCompanyPortion = Decimal.valueOf(value);
	        	 	}
	        	 	else
	        	 	{
	        	 		tempCompanyPortion = 0;
	        	 	}
	        	 }
	        	 catch(Exception ex)
	        	 {
	        	 	tempCompanyPortion = 0;
	        	 }
        	 } 
       	}
    }
    
    public class AddStudentActualException extends Exception {}
    
    @isTest
    static void test()
    {
    	Id b2bActualRecordTypeId = [select Id from RecordType where Name = 'China Smart B2B record type' and SobjectType = 'Account'].Id;
        Account company = new Account(Name = 'Virtual Company', RecordTypeId = b2bActualRecordTypeId);
        insert company;
        Contact student1 = new Contact(LastName = 'student1', AccountId = company.Id);
        Contact student2 = new Contact(LastName = 'student2', AccountId = company.Id);
        Contact student3 = new Contact(LastName = 'student3', AccountId = company.Id);
        insert new Contact[]{student1, student2, student3};
        Actual__c actual = new Actual__c(Account__c = company.Id);
        Actual__c actual2 = new Actual__c(Account__c = company.Id);
        Actual__c actual3 = new Actual__c(Account__c = company.Id, Elite_Card__c = 'test1234');
        insert new actual__c[]{actual, actual2, actual3};
        StudentActual__c firstStudentActual = new StudentActual__c(Actual__c = actual2.Id, Student__c = student1.Id, EliteCard__c = 'test1234');
        StudentActual__c duplicateStudentActual = new StudentActual__c(Actual__c = actual2.Id, Student__c = student2.Id, EliteCard__c = 'test1235');
        insert new StudentActual__c[]{duplicateStudentActual, firstStudentActual};
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, Student__c = student1.Id, EliteCard__c = 'test1234');
        StudentActual__c studentActual2 = new StudentActual__c(Actual__c = actual.Id, Student__c = student2.Id, EliteCard__c = 'test1235');
        insert new StudentActual__c[]{studentActual, studentActual2};
        PageReference addStudentPage = new PageReference('/apex/AddStudentActuals?id=' + actual.Id);
        Test.setCurrentPage(addStudentPage);
        AddStudentActualsController controller = new AddStudentActualsController();
        for(StudentActualInfo tempStudentActual : controller.StudentActuals)
        {
            if(tempStudentActual.StudentId == student3.Id)
            {
            	String temp;
                tempStudentActual.IsNew = true;
                tempStudentActual.CompanyPortion = temp;
                tempStudentActual.CompanyPortion = 'a';
                temp = tempStudentActual.CompanyPortion;
            }
        }
        controller.save();
        controller.cancel();
        controller.getCurrentEntryCenter();
        controller.getEntryCenterPicklistValues();
        delete actual3;
        delete duplicateStudentActual;
        insert new StudentActual__c(Actual__c = actual.Id, Student__c = student2.Id, EliteCard__c = 'test1234');
    }
}