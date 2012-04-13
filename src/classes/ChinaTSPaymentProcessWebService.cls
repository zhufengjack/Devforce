/*
    This class controls creating actual and china payment data for china ts. It will be invoked when we click button. 
    For different opportunity type, the processing procedure will be difference.
*/
global class ChinaTSPaymentProcessWebService 
{ 
    WebService static String activateCourse(String opportunityId, String actualId)
    {
        String resultMessage = '';
        try
        {
            if(opportunityId != null && opportunityId != '')
            {
                List<Opportunity> opportunities = [select Id, AccountId, China_Sales_Type__c, Payment_Schedule__c, (select Id, PricebookEntry.Product2.OfferId__c, PricebookEntry.Product2.IsLevel__c, PricebookEntry.Product2.RedemptionCode__c from OpportunityLineItems), (select Id, RecordType.Name, Close_Date__c from Actuals__r where Id = :actualId) from Opportunity where Id = :opportunityId];
                if(opportunities.size() > 0)
                {
                    Id accountId = opportunities[0].AccountId;
                    String offerId;
                    String memberId;
                    String redemptionCode;
                    //check the close date, should be prior to today.
                    if(opportunities[0].Actuals__r[0].Close_Date__c != null &&  opportunities[0].Actuals__r[0].Close_Date__c > Date.today())
                    {
                        throw new PaymentVerificationException('You cannot activate product before the invoice date.');
                    }
                    // Check opportunity record type.
                    if(opportunities[0].Actuals__r[0].RecordType.Name != 'China TS Actual Record Type')
                    {
                        throw new PaymentVerificationException('Actual record type is ' + opportunities[0].Actuals__r[0].RecordType.Name + '. You can\'t use this button.');
                    }
                    // Gets offer id from opportunity product.
                    if(opportunities[0].OpportunityLineItems.size() > 0)
                    {
                        offerId = opportunities[0].OpportunityLineItems[0].PricebookEntry.Product2.OfferId__c;
                        redemptionCode = opportunities[0].OpportunityLineItems[0].PricebookEntry.Product2.RedemptionCode__c;
                        if(offerId == null)
                        {
                            throw new PaymentVerificationException('Error : Offer id is null.');
                        }
                    }
                    else
                    {
                        throw new PaymentVerificationException('No product was added. You can\'t activate course.');
                    }
                    if(offerId == null)
                    {
                        throw new PaymentVerificationException('Error : Offer id is null.');
                    }
                    // Checks payment records.
                    if(opportunities[0].Actuals__r.size() == 0)
                    {
                        throw new PaymentVerificationException('No payment records. Please create payment records.');
                    }
                    // Gets member id from contact.
                    List<Contact> contacts = [select Id, EtownMemberId__c from Contact where AccountId = :accountId and AccountId != null limit 1];
                    if(contacts.size() > 0 && contacts[0].EtownMemberId__c != null)
                    {
                        memberId = String.valueOf(contacts[0].EtownMemberId__c);
                    }
                    if(memberId == null)
                    {
                        throw new PaymentVerificationException('No member id. You can\'t activate course.');
                    }
                    
                    ChinaTSActivateCourseService activateCourseService = new ChinaTSActivateCourseService();
                   
                    Boolean isTimeProduct = false;
                    if(opportunities[0].OpportunityLineItems.size() > 0)
                    {
                        isTimeProduct = opportunities[0].OpportunityLineItems[0].PricebookEntry.Product2.IsLevel__c;
                    }
                    if(isTimeProduct)
                    {
                        activateCourseService.upgradeProduct(memberId, offerId, opportunities[0].Actuals__r[0].Id, redemptionCode);
                        resultMessage = 'Successfully';
                    }
                    else
                    {
                        activateCourseService.upgradeProduct(memberId, offerId, opportunities[0].Actuals__r[0].Id, redemptionCode);
                        resultMessage = 'Successfully';
                    }
                }
            }
            else
            {
                resultMessage = 'Error : Opportunity id is null.';
            } 
        }
        catch(Exception ex)
        {
            resultMessage = ex.getMessage();
        }
        return resultMessage;
    }
    
    // When change payment failed, Sales will use "Retry" button invoke this function to send message to etown.
    WebService static String retryPurchase(String opportunityId)
    {
       String resultMessage = '';
       try
       {
           List<Actual__c> actuals = [select Id, Status__c,opportunity__c, opportunity__r.AccountId, RecordType.Name, Opportunity__r.China_Sales_Type__c, Opportunity__r.Payment_Schedule__c from Actual__c where Opportunity__c = :opportunityId limit 1];
           if(actuals.size() > 0)
           {
               // Checks actual record type.
               if(actuals[0].RecordType.Name != 'China TS Actual Record Type')
               {
                   throw new PaymentVerificationException('Actual record type is ' + actuals[0].RecordType.Name + '. You can\'t use this button.');
               }
               //Set<String> actualStatus = new Set<String>{'In Progress', 'First Charge Failed', 'Second Charge Failed', 'Third Charge Failed'};
               String actualStatus = (actuals[0].Status__c == null) ? '' : actuals[0].Status__c.toLowerCase();
               if(actualStatus.contains('failed'))
               {
                   Integer memberId;
                   String offerId;         
                   List<Opportunity> opps = [select Id,(select Id, PricebookEntry.Product2.OfferId__c, PricebookEntry.Product2.IsLevel__c from OpportunityLineItems) from Opportunity where Id = :actuals[0].opportunity__c];
                   if(opps.size() > 0)
                   {
                       offerId = (opps[0].OpportunityLineItems.size() > 0) ? opps[0].OpportunityLineItems[0].PricebookEntry.Product2.OfferId__c : '';
                   }
                   List<Contact> students = [select Id, EtownMemberId__c from Contact where AccountId = :actuals[0].opportunity__r.AccountId and AccountId != null limit 1];
                   if(students.size() > 0)
                   {
                       memberId = students[0].EtownMemberId__c.intValue();
                   }
                   ChinaTSActivateCourseService activateCourseService = new ChinaTSActivateCourseService();
                   activateCourseService.retryPurchase(memberId, offerId, actuals[0].Id);
                   return 'Successful';
               }
               else
               {
                   throw new PaymentVerificationException('Actual status is "'+ actuals[0].State__c +'".');
               }
           }
           else
           {
               throw new PaymentVerificationException('No payment records.');
           }
       }
       catch(Exception ex)
       {
           resultMessage = ex.getMessage();
       }
       return resultMessage;
    }
    
    WebService static String dieOrder(String actualId)
    {
        String resultMessage = '';
        if(actualId != null)
        {
            List<Actual__c> actuals = [select Id, Status__c from Actual__c where Id = :actualId];
            if(actuals.size() > 0)
            {
            	update new Actual__c(Id = actuals[0].Id, Status__c = 'Dead');
            	setPaymentDataStatusToDead(actuals[0].Id);
            	resultMessage = 'Process successfully';
            }
            else
            {
                resultMessage = 'Error: No actual is selected.';
            }
        }
        else
        {
            resultMessage = 'Error: No actual id.';
        }
        return resultMessage;
    }
    
    private static void setPaymentDataStatusToDead(String actualId)
    {
        if(actualId != null)
        {
            List<PaymentData__c> paymentDatas = [select Id, Status__c from PaymentData__c where Actual__c = :actualId];
            List<PaymentData__c> updatedList = new List<PaymentData__c>();
            for(PaymentData__c paymentData : paymentDatas)
            {
                if(PaymentData.Status__c == 'Due' || PaymentData.Status__c == 'Failed' || PaymentData.Status__c == null || PaymentData.Status__c == '')
                {
                    PaymentData.status__c = 'Dead';
                    updatedList.add(paymentData);
                }
            }
            if(updatedList.size() > 0)
            {
                update updatedList;
            }
        }
    }
    
    public class CreatePaymentRecordException extends Exception {}

    public class PaymentVerificationException extends Exception {}
    
    @isTest
    static void testChinaTSPaymentProcessWebService()
    {
        // Test activateCourse method.
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContact = new Contact(AccountId = testAccount.Id, Lastname = 'last name', EtownMemberId__c = 999999);
        insert testContact;
        String chinaTsRecordTypeId = [select Id from RecordType where Name = 'China Telesales Record Type' and sobjectType = 'Opportunity' limit 1].Id;
        Opportunity testOpportunity = new Opportunity(Name = 'test opp', China_Sales_Type__c = 'Upgrade', Payment_Schedule__c = 'Single', AccountId = testAccount.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = chinaTsRecordTypeId);
        insert testOpportunity;
        String chinaTsActualRecordTypeId = [select Id from RecordType where Name = 'China TS Actual Record Type' and sobjectType = 'Actual__c' limit 1].Id;
        
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
        ChinaTSPaymentProcessWebService.activateCourse(testOpportunity.Id, testActual.Id);
        // Test retryPurchase method.
        update new Opportunity(Id = testOpportunity.Id, Payment_Schedule__c = 'Installments', StageName = 'Closed Won');
        update new Actual__c(Id = testActual.Id, Status__c = 'First Charge Failed');
        ChinaTSPaymentProcessWebService.retryPurchase(testOpportunity.Id);
        // Test createChinaTsPaymentInfo method.
        delete testActual; 
        // Test for dying order.
        Actual__c dyOrderActual = new Actual__c(RecordTypeId = chinaTsActualRecordTypeId, Account__c = testAccount.Id, Opportunity__c = testOpportunity.Id, status__c = 'In Progress');
        insert dyOrderActual;
        PaymentData__c dyPaymentData = new PaymentData__c(Actual__c = dyOrderActual.Id, Status__c = 'Paid');
        PaymentData__c dyPaymentData2 = new PaymentData__c(Actual__c = dyOrderActual.Id, Status__c = 'Due');
        PaymentData__c dyPaymentData3 = new PaymentData__c(Actual__c = dyOrderActual.Id, Status__c = 'Failed');
        PaymentData__c dyPaymentData4 = new PaymentData__c(Actual__c = dyOrderActual.Id);
        insert new List<PaymentData__c>{dyPaymentData, dyPaymentData2, dyPaymentData3, dyPaymentData4};
        ChinaTSPaymentProcessWebService.dieOrder(dyOrderActual.Id);
        system.assertEquals('Dead', [select Status__c from Actual__c where Id = :dyOrderActual.Id].Status__c);
        system.assertEquals('Paid', [select Status__c from PaymentData__c where Id = :dyPaymentData.Id].Status__c);
        system.assertEquals('Dead', [select Status__c from PaymentData__c where Id = :dyPaymentData2.Id].Status__c);
    }
}