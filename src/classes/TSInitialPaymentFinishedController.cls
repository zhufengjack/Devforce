/*
*   This controller for page TS Initial Payment Completed.
*/
public class TSInitialPaymentFinishedController 
{
    public String ProcessResult {get; set;}
    
    public void processInitialSuccessPayment()
    {
        try
        {
            String oppNum= ApexPages.currentPage().getParameters().get('opp');
            String amount = ApexPages.currentPage().getParameters().get('amount');
            String memberId = ApexPages.currentPage().getParameters().get('memberId');
            String colDate = ApexPages.currentPage().getParameters().get('date');
            String reasonCode = ApexPages.currentPage().getParameters().get('reason');
            String vcodeValue = ApexPages.currentPage().getParameters().get('vcode'); 
            List<String> parameters = new List<String>{oppNum, amount, memberId, colDate}; // Note that: we didn't add reason parameter to this list.
            Boolean verificationPassed = ChinaTSUtility.validateSecuriteKey(parameters, vcodeValue);
            if(verificationPassed) 
            {
                checkUrlParam(oppNum, amount, memberId, colDate, vcodeValue);
                List<Opportunity> opportunitys =  [select Id, Name, Comments__c, Mobile__c, Phone2__c, Email__c, AccountId, Company_Type__c, product__c, China_Sales_Type__c, OwnerId, Owner.Username, Location__c, Opportunity_Number__c, CloseDate, Amount, Payment_Type__c, Payment_Schedule__c, Number_of_Installments__c, (Select Id, PricebookEntry.Product2.Name, Quantity, UnitPrice, PricebookEntry.Product2.OfferId__c, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.NumberOfInstallments__c, PricebookEntry.Product2.Months__c, PricebookEntry.Product2.MarketingLength__c, PricebookEntry.Product2.FreeLength__c, PricebookEntry.Product2.CourseLength__c from OpportunityLineItems), (select Id from Actuals__r limit 1) from Opportunity where Opportunity_Number__c = :oppNum limit 1];
                if(opportunitys.size() > 0)
                {
                    Date collectedDate;
                    Double currentAmount;
                    currentAmount = double.valueOf(amount);
                    collectedDate = processDateString(colDate);
                    // Check fields.
                    checkFields(opportunitys[0]);
                    if(currentAmount <= 0)
                    {   // If amount equals 0 or less than 0, it means that the first payment failure. 
                        // update opportunity stage.
                        updateOpportunityStage(opportunitys[0], 'Payment Pending Failed', reasonCode, opportunitys[0].comments__c);
                        ProcessResult = 'Update opportunity payment status successfully.';
                    }
                    else
                    {
                        ChinaTSUtility.checkAndCreateNewContact(opportunitys[0], memberId);
                        Boolean result = (new ChinaTSPaymentProcessBusiness()).processInitialpaymentSuccess(opportunitys[0], collectedDate, double.valueOf(amount), memberId);
                        if(result == true)
                        {
                            ProcessResult = 'Create Successfully';
                            updateOpportunityStage(opportunitys[0], 'Closed Won');
                        }
                        else
                        {
                            ProcessResult = 'No payment record was created.';
                        }
                    }
                 }
                 else
                 {
                     ProcessResult = 'Invalid opportunity number.';
                 }
            }
            else
            {
                ProcessResult = 'Authentication Failed';
            }
        }
        catch(Exception ex)
        {
            ProcessResult = ex.getMessage();
        }
    }
    
    private Date processDateString(String dateParameter)
    {
        if(dateParameter != null)
        {
           List<String> splitList = dateParameter.split('-');
           Date resultDate = Date.newInstance(Integer.valueOf(splitList[0]), Integer.valueOf(splitList[1]), Integer.valueOf(splitList[2]));
           return resultDate;
        }
        else
        {
            return null;
        }
    }
    
    private void updateOpportunityStage(Opportunity opp, String value)
    {
        if(opp != null)
        {
            Opportunity newOpp = new Opportunity(Id = opp.Id, StageName = value, CloseDate = Date.today());
            update newOpp;
        }
    }
    
    private void updateOpportunityStage(Opportunity opp, String value, String errorCode, String comments)
    {
        if(opp != null)
        {
            Opportunity newOpp = new Opportunity(Id = opp.Id, StageName = value);
            if(errorCode != null)
            {
                String errorReason = searchFailureReason(errorCode);
                if(errorReason != null)
                {
                    comments = (comments != null) ? comments : '';
                    newOpp.Comments__c = comments + ' \n\r失败原因：' + errorReason;
                }
            }
            update newOpp;
        }
    }
    
    private String searchFailureReason(String failureReasonCode)
    {
        if(failureReasonCode != null)
        {
            UnipayErrorCode__c errorCodeInstance = UnipayErrorCode__c.getInstance(failureReasonCode);
            if(errorCodeInstance != null)
            {
                return errorCodeInstance.ErrorReason__c;
            }
        }
        return null;
    }
    
    // Check fields.
    private void checkFields(Opportunity opp)
    {
        if(opp != null)
        {
            if(opp.Actuals__r.size() > 0)
            {
                throw new CheckOpportunityException('You have create actual for this opportunity. You can\'t do this again.');
            }
            if(opp.OpportunityLineItems.size() == 0)
            {
                throw new CheckOpportunityException('No products under opportunity.');
            }
            if(opp.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c == null || opp.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c == 0)
            {
                throw new CheckOpportunityException('Error: number of installment is null.');
            }
        }
    }
    
    // Check url parameters.
    private void checkUrlParam(String oppNum, String amount, String memberId, String colDate, String vcodeValue)
    {
        if(oppNum == null || oppNum == '')
        {
            throw new ParameterException('Error: opp is null.');
        }
        try
        {
            Double currentAmount = double.valueOf(amount);
        }
        catch(Exception ex)
        {
            throw new  ParameterException('Invalid amount format.');
        }
        try
        {
            Date collectedDate = processDateString(colDate);
        }
        catch(Exception ex)
        {
            throw new  ParameterException('Invalid date format.');
        }
        if(memberId == null)
        {
            throw new ParameterException('Error: Member id is null.');
        }
    }
    
    public class ParameterException extends Exception {}
    
    public class CheckOpportunityException extends Exception {}
    
    @isTest
    static void testTSInitialPaymentFinishedController()
    {
        //String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';
        //String testVcode = (new ChinaTsPaymentProcessUtility()).getChinaTsSecurityToken(new String[]{'op-12322', '9999', '2011-4-16', '45434', chinaTsSecurityKey});
        Account testAccount = new Account(Name = 'test account', First_Name__c = 'First Name', Last_Name__c = 'Last Name', phone = '3214567890', Mobile__c = '1234567890');
        insert testAccount;
        /*Contact testContact = new Contact(AccountId = testAccount.Id, Lastname = 'last name', EtownMemberId__c = 999999);
        insert testContact;*/
        String chinaTsRecordTypeId = [select Id from RecordType where Name = 'China Telesales Record Type' and sobjectType = 'Opportunity' limit 1].Id;
        Opportunity testOpportunity = new Opportunity(Name = 'test opp', Phone2__c = '3214567890', China_Sales_Type__c = 'New', Payment_Schedule__c = 'Installments',Payment_Type__c = 'Unipay', AccountId = testAccount.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = chinaTsRecordTypeId);
        insert testOpportunity;
        String chinaTsActualRecordTypeId = [select Id from RecordType where Name = 'China TS Actual Record Type' and sobjectType = 'Actual__c' limit 1].Id;
        /*Actual__c testActual = new Actual__c(RecordTypeId = chinaTsActualRecordTypeId, Account__c = testAccount.Id, Opportunity__c = testOpportunity.Id);
        insert testActual; */
        Product2 testProduct = new Product2(Name = 'test product acme', IsActive = true, Family = 'Smart new product list', OfferId__c = 'ERYEUW6635', RedemptionCode__c = 'EERER384783', IsLevel__c = true, NumberOfInstallments__c = 6);
        insert testProduct;
        Pricebook2 testPricebook = new Pricebook2(IsActive = true, Name = 'test price book acme');
        insert testPricebook;
        String standardPriceBookId = [select Id from Pricebook2 where IsStandard = true limit 1].Id;
        PricebookEntry standardPricebookEntry = new PricebookEntry(IsActive = true, Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, UnitPrice = 994889);
        PricebookEntry testPricebookEntry = new PricebookEntry(IsActive = true, Pricebook2Id = testPricebook.Id, Product2Id = testProduct.Id, UnitPrice = 9999999);
        insert standardPricebookEntry;
        insert testPricebookEntry;
        OpportunityLineItem testOpportunityLineItem = new OpportunityLineItem(OpportunityId = testOpportunity.Id, PriceBookEntryId = testPricebookEntry.Id, Quantity = 1, TotalPrice = 88);
        insert testOpportunityLineItem;
        Actual__c testActual = new Actual__c(RecordTypeId = chinaTsActualRecordTypeId, Account__c = testAccount.Id, Opportunity__c = testOpportunity.Id);
        insert testActual;
        testOpportunity = [select Id, Name, AccountId, Email__c, product__c, China_Sales_Type__c, OwnerId, Owner.Username, Location__c, Opportunity_Number__c, Mobile__c, Phone2__c, CloseDate, Amount, Payment_Type__c, Payment_Schedule__c, Number_of_Installments__c, (Select Id, PricebookEntry.Product2.Name, PricebookEntry.Product2.OfferId__c, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.NumberOfInstallments__c from OpportunityLineItems), (select Id from Actuals__r limit 1) from Opportunity where Id = :testOpportunity.Id limit 1];
        List<Actual__c> tempActuals = [select Id from Actual__c where Opportunity__c = :testOpportunity.Id];
        delete tempActuals;
        String testVcode = ChinaTSUtility.getChinaTsSecurityToken(new String[]{testOpportunity.Opportunity_Number__c, '9999', '2011-4-16', '45434'});
        PageReference testpage = new PageReference('/apex/TSInitialPaymentFinished?opp=' + testOpportunity.Opportunity_Number__c + '&amount=9999&memberId=45434&date=2011-4-16&vcode=' + testVcode);
        Test.setCurrentPage(testpage);
        TSInitialPaymentFinishedController controller = new TSInitialPaymentFinishedController();
        controller.processInitialSuccessPayment();
        controller.updateOpportunityStage(testOpportunity, 'Close Won');
        controller.updateOpportunityStage(testOpportunity, 'Payment Pending Failed', '0033', 'test comments');
        // Test for creating new contact.
        Contact newContact = [select Id, FirstName, LastName, Phone, MobilePhone from Contact where AccountId = :testAccount.Id];
        System.assertEquals('test account', newContact.LastName);
        System.assertEquals('3214567890', newContact.Phone);
    }
}