public class ChinaTSPaymentProcessBusiness 
{
    public Boolean processInitialpaymentSuccess(Opportunity opp, Date collectedDate, Double amountCollected, String memberId)
    {
        // Create finance data.
        Boolean initialResult = false;
        ChinaTSFinanceDataUtility utility = new ChinaTSFinanceDataUtility();
        String newActualId;
        try
        {
            newActualId = utility.generateFinanceData(opp, collectedDate, amountCollected); // Date collectedDate, Double amountCollected, String memberId
            updateMemberId(opp, memberId);
            initialResult = true;
        }
        catch(Exception ex)
        {
        	if(newActualId != null)
        	{
        	    delete new Actual__c(Id = newActualId);
        	}
	        throw new PaymentProcessException(ex.getMessage());
        }
        return initialResult;
    }
    
    //update contact memberId
    public void updateMemberId(Opportunity opp,String memberId)
    {
        if(opp != null && memberId != null)
        {
            Contact contactInfo;
            List<Contact> contactList = [select Id from Contact Where AccountId = :opp.AccountId and AccountId != null limit 1];
            if(contactList.size() > 0)
            {
                contactInfo = contactList[0];
                contactInfo.EtownMemberId__c = double.valueOf(memberId);
                update contactInfo;
            }
            else
            {
                throw new PaymentProcessException('No associated contact for this opportunity.');
            }
        }
    }
    
    public Boolean processPaymentSucess(String memberId, String phaseNumber, Date collectedDate, Double collectedAmount)
    {
       Boolean updateResult = false;
       if(memberId != null && phaseNumber != null)
       {
           PaymentData__c payment = searchPaymentRecord(memberId, phaseNumber);
           if(payment != null)
           {
               payment.Status__c = 'Paid';
               payment.TransDatetime__c = collectedDate;
               payment.Amount__c = collectedAmount;
               update payment;
               List<Actual__c> relatedActuals = [select Id, Status__c, Final_Price__c, Number_of_Installments__c from Actual__c where Id = :payment.Actual__c];
               if(relatedActuals.size() > 0)
               {
                    Actual__c relatedActual = relatedActuals[0];
                    Integer currentPhaseNumber = (phaseNumber == null) ? 0 : Integer.valueOf(phaseNumber); 
                    if(relatedActual.Status__c != 'Dead')
                    {
	                    if(currentPhaseNumber == relatedActuals[0].Number_of_Installments__c)
	                    {
	                        relatedActual.Status__c = 'Paid in Full';
	                    }
	                    else
	                    {
	                        relatedActual.Status__c = 'In Progress';
	                    }
	                    update relatedActual;
                    }
                    updateResult = true;
               }
           }
       } 
       return updateResult;
    }
    
    private PaymentData__c searchPaymentRecord(String memberId, String phaseNumber)
    {
        if(memberId != null && phaseNumber != null)
        {  
            List<Contact> studentList = [select Id, AccountId from Contact where EtownMemberId__c = :Decimal.valueOf(memberId)];
            if(studentList.size() > 0)
            {   
                Set<String> actualStatusSet = new Set<String>{'In Progress', 'First Charge Failed', 'Second Charge Failed', 'Third Charge Failed', 'Dead'}; 
                List<PaymentData__c> payments = [select Id, Actual__c, Actual__r.opportunity__r.ownerId, Actual__r.Status__c from PaymentData__c where Actual__r.Opportunity__r.AccountId = :studentList[0].AccountId and Actual__r.Opportunity__r.AccountId != null and no_of_installments__c = :phaseNumber and Actual__r.Status__c in :actualStatusSet order by Actual__r.Opportunity__r.CreatedDate desc limit 1];
                if(payments.size() > 0)
                {
                    return payments[0];
                }
            }
            else
            {
                throw new UpgradeAndRetryException('This memberId is not in salesforce.');
            } 
        }
        return null;
    }
    
    public Boolean processPaymentFailed(String memberId, String phaseNumber, String failureReasonCode, Date collectedDate)
    {
       Boolean updateResult = false;
       if(memberId != null && phaseNumber != null)
       {
           PaymentData__c payment = searchPaymentRecord(memberId, phaseNumber);
           if(payment != null)
           {   
               String failureReason = searchFailureReason(failureReasonCode);
               payment.Status__c = 'Failed';
               payment.TransDatetime__c = collectedDate;
               update payment;
                 
               Actual__c relatedActual = checkPreviousPayment(payment.Actual__c, payment.Actual__r.Status__c, failureReason);
               if(relatedActual != null)
               {
                    update relatedActual; 
                    updateResult = true; 
               } 
               //sendEmailToSales(payment.Actual__r.opportunity__r.ownerId);   
           }
       }
       return updateResult;
    }
    
    // get failure reason from custom setting.   
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
    
    private Actual__c checkPreviousPayment(Id actualId, String actualStatus, string failureReason)
    {
       if(actualId != null && actualStatus != null)
       {
           Actual__c tempActual = new Actual__c(Id = actualId, PaymentFailureReason__c = failureReason);
           if(actualStatus == 'Dead')
           {
               tempActual.Status__c = 'Dead';
           }
           else if(actualStatus == 'First Charge Failed')
           {
               tempActual.Status__c = 'Second Charge Failed';
           }
           else if(actualStatus == 'Second Charge Failed')
           {
               tempActual.Status__c = 'Third Charge Failed';
           }
           else if(actualStatus != 'Second Charge Failed' && actualStatus != 'Third Charge Failed')
           {
               tempActual.Status__c = 'First Charge Failed';
           }
           return tempActual;
       }
       return null;    
    }
    
    public class UpgradeAndRetryException extends Exception {}
    
    public class PaymentProcessException extends Exception {}
    
    public class SendEmailException extends Exception {}
    
    @isTest
    static void testChinaTSPaymentProcessBusiness()
    {
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContact = new Contact(AccountId = testAccount.Id, Lastname = 'last name', EtownMemberId__c = 999999);
        insert testContact;
        String chinaTsRecordTypeId = [select Id from RecordType where Name = 'China Telesales Record Type' and sobjectType = 'Opportunity' limit 1].Id;
        Opportunity testOpportunity = new Opportunity(Name = 'test opp', China_Sales_Type__c = 'Upgrade', AccountId = testAccount.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = chinaTsRecordTypeId);
        insert testOpportunity;
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
        //Create controller.
        ChinaTSPaymentProcessBusiness controller = new ChinaTSPaymentProcessBusiness();
        // Test for installmentNumber is  1.
        Opportunity currentTestOpp = [select Id, Name, AccountId, RecordType.Name, StageName, Product__c, China_Sales_Type__c, Company_Type__c, OwnerId, Owner.Username, Location__c, Opportunity_Number__c, CloseDate, Amount, Payment_Type__c, Payment_Schedule__c, Number_of_Installments__c, (Select Id, Quantity, PricebookEntry.Product2.IsLevel__c, PricebookEntry.Product2.Months__c, PricebookEntry.Product2.Name, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.FreeLength__c, PricebookEntry.Product2.MarketingLength__c, PricebookEntry.Product2.CourseLength__c, PricebookEntry.Product2.NumberOfInstallments__c, UnitPrice from OpportunityLineItems), (select Id from Actuals__r limit 1) from Opportunity where Id = :testOpportunity.Id];
        controller.processInitialpaymentSuccess(currentTestOpp, Date.today(), 1111, '232323');
        controller.processPaymentSucess('232323', '2', Date.today(), 233);
        controller.processPaymentFailed('232323', '3', 'reason', Date.today());
    }
}