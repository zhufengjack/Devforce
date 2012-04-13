/*
 * controller of page CreateActual
 * creates actual of the opportunity, and a default student actual
 * only works for china smart
 */
public class CreateActualController 
{
    public static final String B2BOpportunityRecordTypeId =  [select Id from RecordType where Name = 'China Smart B2B Record Type' and SobjectType = 'Opportunity'].Id; //'012O00000004IYO';
    public static final String ChinaSmartActualRecordTypeId = [select Id from RecordType where Name = 'China Smart Actual Record Type' and SobjectType = 'Actual__c'].Id;//'0124000000098F6';
    
    public CreateActualController(ApexPages.StandardController controller) 
    {
        CloseWon = 'Y';
        List<Opportunity> opps = [select Id, Name, AccountId, OwnerId, Location__c, CloseDate, RecordTypeId from Opportunity where Id=:controller.getId() limit 1];
        if(opps.size() > 0)
        {
            Record = opps[0];
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No opportunity selected'));
        }
    }
      
    private Map<String, String> salesTypeDependenceMap 
    {
        get
        {
            Map<String, String> tempMap = new Map<String, String>	
            {
    	    	'New' => 'Regular new student',
                'Double Pay' => 'Company pay to EF after student paid',
                'Upgrade 1' => 'Course extension: 0 < Course Taken < 14 Days',
                'Upgrade 2' => 'Course extension: 14 Days < Course Taken < 60 Days',
                'Upgrade 3' => 'Course extension: 60 Days < Course Taken < Complete',
                'Upgrade 4' => 'Service Upgrade: Home Upgrade To School',
                'Renewal' => 'Student buy a new product after course completed',
                'Downgrade' => 'Time length reduction within same product & School to Home'
            }; 
            return tempMap;
        }
    }
    
	public Opportunity Record { get; set; }
    public String CloseWon { get; set; }
    public String SalesType { get; set; }
    public String CompanyCode { get; set; }
    
    public PageReference save()
    {
        Actual__c newActual = new Actual__c(Account__c=Record.AccountId, RecordTypeId=ChinaSmartActualRecordTypeId, Opportunity__c=Record.Id, Opportunity_Owner__c=Record.OwnerId, Company_Code__c=CompanyCode, China_Sales_Type__c=SalesType, Close_date__c=Record.CloseDate);
        setSalesType(newActual);
        Savepoint sp = Database.setSavepoint();
        try
        {
            insert newActual;
            createStudentActual(newActual.Id);
            updateOpportunity();
 			updateReferralCloseDate(newActual);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            Database.rollback(sp);
            return null;
        }
        return new PageReference('/' + newActual.Id);
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + Record.Id);
    }
    
    // gets company code, the company code is auto selected according to this user’s role
    public List<SelectOption> getCompanyCodes()
    {
        List<SelectOption> options = new List<SelectOption>();
        User user = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()]; //gets the current user
    	if(user != null)
    	{
			List<FinanceCompanyCode__c> companyCodes = [select CompanyCode__c from FinanceCompanyCode__c where UserRole__c = :User.UserRole.Name];
			if(companyCodes.size() == 1)
			{
				options.add(new SelectOption(companyCodes[0].CompanyCode__c, companyCodes[0].CompanyCode__c));
			}
			else
			{
				//companyCodes.size > 1 or = 0
				options.add(new SelectOption('', '--None--'));
	        	for(FinanceCompanyCode__c financeCompanyCode : companyCodes)
	        	{
	        		options.add(new SelectOption(financeCompanyCode.CompanyCode__c, financeCompanyCode.CompanyCode__c));
	        	}
			}
		}
    	return options;
    }
    
    public List<SelectOption> getSalesTypes()
    {
        List<Actual__c> actuals = [select Id from Actual__c where Opportunity__c = :Record.Id limit 1];
        if(actuals.size() > 0)
        {
            return getPicklistValuesForAdditionalActual();
        }
        else
        {
        	return getPicklistValues('ChinaSalesType');
        }
    }
    
    //sets Sales Type Definition
    private void setSalesType(Actual__c actual)
    {
    	if(actual != null)
    	{
	    	if(CloseWon != 'Y')
	        {
	            actual.China_Sales_Type__c = 'Deposit';
	        }
	        String salesTypeDefinition = salesTypeDependenceMap.get(actual.China_Sales_Type__c);// Set Sales Type Definition
	        if(salesTypeDefinition != null)
	        {
	            actual.Sales_Type_Definition__c = salesTypeDefinition;
	        }
    	}
    }

    // A method used to create student actual
    private void createStudentActual(Id actualId)
 	{
 		List<Contact> students = [select Id, Name, IDNumber__c, (select Id, EliteCard__c, RefundAmount__c from Student_Actuals__r order by CreatedDate desc limit 1) from Contact where AccountId=:Record.AccountId];
        if(students.size() > 0 && actualId != null)
        {
            StudentActual__c newStudentActual = new StudentActual__c(Actual__c=actualId, Student__c=students[0].Id, Name = students[0].Name, EntryCenter__c=Record.Location__c, IDNumber__c = students[0].IDNumber__c);
            if(students[0].Student_Actuals__r.size() > 0)
            {
                if(students[0].Student_Actuals__r[0].RefundAmount__c != null && students[0].Student_Actuals__r[0].RefundAmount__c > 0)
                {
                    newStudentActual.OriginalRefundAmount__c = students[0].Student_Actuals__r[0].RefundAmount__c;
                }
            }
            insert newStudentActual;
        }
 	}
 	
    //updates opportunity
    private void updateOpportunity()
    {
    	if(CloseWon == 'Y')
        {
            Record.StageName = 'Closed Won';
        }
        else
        {
            if(Record.RecordTypeId != B2BOpportunityRecordTypeId)
            { 
                Record.StageName = 'Payment Pending';
            }
        }
        update Record;
    }
    
	//private update close date of the referee
    private void updateReferralCloseDate(Actual__c actual)
    {
      	if(actual != null && actual.China_Sales_Type__c == 'New')
	    {
          	List<Referral__c> referals = [select Id, Actual__c from Referral__c where ReferralName__c = :Record.AccountId limit 1];
          	if(referals.size() == 1)
          	{
              	update new Referral__c(Actual__c = actual.Id, Id = referals[0].Id);   
          	}          
      	} 
    }

    private List<SelectOption> getPicklistValuesForAdditionalActual()
    {
    	List<SelectOption> options = new List<SelectOption>();
	  	options.add(new SelectOption('Additional', 'Additional'));
	   	options.add(new SelectOption('Promotion', 'Promotion'));
	   	options.add(new SelectOption('Referral', 'Referral'));
        options.add(new SelectOption('Service Recovery', 'Service Recovery'));
	   	return options;
    }
    
    // gets sales type and company code value
    private List<SelectOption> getPicklistValues(String fieldName)
    {
        List<SelectOption> options = new List<SelectOption>();
        Schema.Describefieldresult fieldResult;
        if(fieldName == 'ChinaSalesType')
        {
            fieldResult = Actual__c.China_Sales_Type__c.getDescribe();
        }
        if(fieldResult != null)
        {
            List<Schema.Picklistentry> entries = fieldResult.getPicklistValues();
            for(Schema.Picklistentry entry : entries)
            {
                options.add(new SelectOption(entry.getValue(), entry.getLabel()));
            }
        }
        return options;
    }
    
    @isTest
    static void testCreateActualController()
    {
        Id b2bAccountRecordTypeId = [Select Id from RecordType where Name = 'China Smart B2B record type' and SobjectType = 'Account'].Id; 
        Account b2bAccount = new Account(Name = 'test account', RecordTypeId = b2bAccountRecordTypeId);
        insert b2bAccount;
        Contact student1 = new Contact(LastName = 'student1', AccountId = b2bAccount.Id);
        Contact student2 = new Contact(LastName = 'student2', AccountId = b2bAccount.Id);
        insert new Contact[]{ student1, student2 };
        Id b2bOppTypeId = [select Id from RecordType where Name = 'China Smart B2B Record Type' and SobjectType = 'Opportunity'].Id;
        Opportunity b2bOpp = new Opportunity(Name = 'b2bOpp', RecordTypeId = b2bOppTypeId, AccountId = b2bAccount.Id, StageName = 'Set Appt', Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today(), GZ_Marketing__c = 'Other', Contract_end_date__c = Date.today());
        insert b2bOpp;
        ApexPages.StandardController standardController =  new ApexPages.StandardController(b2bOpp);
        CreateActualController controller = new CreateActualController(standardController);
        controller.save();
        
        System.assertEquals(1, [select Id, StudentActualCount__c from Actual__c where Opportunity__c = :b2bOpp.Id].StudentActualCount__c);
        controller.cancel();
        controller.getCompanyCodes();
        controller.getSalesTypes();
        controller.getPicklistValues('ChinaSalesType');
        controller.getPicklistValuesForAdditionalActual();
        controller.save();
    }
}