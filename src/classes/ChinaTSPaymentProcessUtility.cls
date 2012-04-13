/*
*   This class implements core logic for china TS finance project. 
*/
public class ChinaTSPaymentProcessUtility 
{
    private ChinaTsServiceStub.BasicHttpBinding_ISalesforceService service = new ChinaTsServiceStub.BasicHttpBinding_ISalesforceService();
    private static final String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';
    private final String eCommerceUsername = 'CommerceSalesforce';
    private final String eCommercePassword = 'so2#6)=|~nzH^';
    
    public ChinaTSPaymentProcessUtility()
    {
       service.timeout_x = 60 * 1000 * 2; //timeout is 2 minute.
       service.Security = new ChinaTSIdentityValidation.Security_element();
       service.Security.UsernameToken = new ChinaTSIdentityValidation.UsernameToken_element();
       service.Security.UsernameToken.Username = eCommerceUsername;
       service.Security.UsernameToken.Password = eCommercePassword;
    }
    
    //manually create actual and payment data
    public Boolean createPaymentInfo(Opportunity oppt, Date collectedDate, Double amountCollected)
    {
        //need a validation method
        Boolean processResult = false;
        if(oppt != null && collectedDate != null && amountCollected != null)
        {
            Actual__c actual = createActual(oppt);
            processResult = createPaymentData(actual, oppt, collectedDate, amountCollected);
        }
        return processResult;
    } 
    
    //automatically create actual and payment data
    public Boolean createPaymentInfo(Opportunity oppt, Date collectedDate, Double amountCollected, String memberId)
    {
        Boolean processResult = false;
        if(oppt != null && collectedDate != null && amountCollected != null && memberId != null)
        {
            updateMemberId(oppt, memberId); 
            Actual__c actual = createActual(oppt);
            processResult = createPaymentData(actual, oppt, collectedDate, amountCollected);
        }
        return processResult;
    }
    
    public Actual__c createActual(Opportunity opptInfo)
    {   
        if(opptInfo != null)
        {
            // Checks actual under current opportunity
            if(opptInfo.actuals__r.size() > 0)
            {
                 throw new PaymentVerificationException('Payment records have been created. You can\'t do that again.');
            }
            
            Actual__c actual = new Actual__c();
            RecordType ChinaTSRecordType = [Select Id from RecordType Where SobjectType = 'Actual__c'  and Name = 'China TS Actual Record Type' limit 1];
            actual.Opportunity__c = opptInfo.Id;
            actual.Opportunity_owner__c = opptInfo.OwnerId; 
            actual.Opportunity_Name__c = opptInfo.Name;
            actual.Close_date__c = opptInfo.CloseDate;
            actual.Final_Price__c = opptInfo.Amount;
            actual.Payment_Schedule__c = opptInfo.Payment_Schedule__c; 
            actual.Payment_Type__c = opptInfo.Payment_Type__c; //field label is Payment Method
            actual.Number_of_Installments__c = opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c; 
            actual.RecordTypeId = ChinaTSRecordType.Id; 
            actual.OwnerId = opptInfo.OwnerId;
            actual.FirstInstallmentAmount__c = opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.FirstInstallmentAmount__c;
            actual.MonthlyFee__c = opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.MonthlyFee__c;
            if(opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c == 1)
            {
                actual.Status__c = 'Paid';
            }
            else if(opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c > 1)
            {
                actual.Status__c = 'In Progress';
            }
            actual.Sales_Appt_Locations_c__c = opptInfo.Location__c; 
            actual.Opportunity_number__c = opptInfo.Opportunity_Number__c;
            actual.Mobile__c = opptInfo.Mobile__c;
            actual.Phone__c = opptInfo.Phone2__c;
            actual.Email__c = opptInfo.Email__c;         
            if(opptInfo.OpportunityLineItems.size() > 0)
            {
                actual.China_Product_List__c = opptInfo.OpportunityLineItems[0].PricebookEntry.Product2.Name;
            }
            
            insert actual;
            return actual;
        }
        return null;
    }
    
    public Boolean createPaymentData(Actual__c actualInfo, Opportunity opptInfo, Date collectedDate, Double amountCollected)
    {
        if(actualInfo != null && opptInfo != null)
        {
            List<PaymentData__c> paymentDataList = new List<PaymentData__c>();
            Actual__c currentActual = [select Id, Payment_Type__c, FirstInstallmentAmount__c, MonthlyFee__c from Actual__c where Id = :actualInfo.Id limit 1];  
            Integer installmentLength = (actualInfo.Number_of_Installments__c == null) ? 0 : actualInfo.Number_of_Installments__c.intValue();
            if(installmentLength == 1)
            {  
                //Payment by Single
                PaymentData__c paymentData = new PaymentData__c();
                paymentData.Actual__c = actualInfo.Id;
                paymentData.Pay_Type__c = 'China TS Payment';
                paymentData.Status__c = 'Collected';
                paymentData.Payment_method__c = actualInfo.Payment_Type__c;
                paymentData.DueDate__c = Date.today();
                paymentData.AmountDue__c = opptInfo.Amount;
                paymentData.AmountCollected__c = amountCollected;
                paymentData.CollectedDate__c = collectedDate;
                paymentData.OwnerId = opptInfo.OwnerId;
                paymentDataList.add(paymentData); 
            }
            else if(installmentLength >= 1)
            {   
                //Payment by Installment
                for(Integer i = 1; i <= installmentLength; i++ )
                { 
                    PaymentData__c paymentData = new PaymentData__c();
                    if(i == 1)
                    {
                        paymentData.Actual__c = actualInfo.Id;
                        paymentData.Pay_Type__c = 'China TS Payment';
                        paymentData.Status__c = 'Paid';
                        paymentData.Payment_method__c = actualInfo.Payment_Type__c;
                        paymentData.DueDate__c = Date.today();
                        paymentData.AmountDue__c = currentActual.FirstInstallmentAmount__c;//First installment amount;
                        paymentData.AmountCollected__c = amountCollected;
                        paymentData.CollectedDate__c = collectedDate;
                        paymentData.no_of_installments__c = String.valueOf(i);
                        paymentData.OwnerId = opptInfo.OwnerId;
                        paymentDataList.add(paymentData); 
                    }
                    else
                    {
                        paymentData.Actual__c = actualInfo.Id;
                        paymentData.Pay_Type__c = 'China TS Payment';
                        paymentData.Status__c = 'Due';
                        paymentData.Payment_method__c = actualInfo.Payment_Type__c;
                        paymentData.DueDate__c = Date.today().addMonths(i-1);
                        paymentData.AmountDue__c = currentActual.MonthlyFee__c; //mothy fee;
                        paymentData.no_of_installments__c = String.valueOf(i);
                        paymentData.OwnerId = opptInfo.OwnerId;
                        paymentDataList.add(paymentData);
                    }
                }
            }
            else
            {
                delete new Actual__c(Id = actualInfo.Id);
                throw new PaymentVerificationException('Creating failure, Please check number of installment.');
            } 
            if(paymentDataList.size() > 0)
            {
               insert paymentDataList; 
               return true;
            }
        }
        return false;
    }
    
    //update contact memberId
    public void updateMemberId(Opportunity opptInfo,String memberId)
    {
        if(opptInfo != null && memberId != null)
        {
            Contact contactInfo;
            List<Contact> contactList = [select Id from Contact Where AccountId = :opptInfo.AccountId and AccountId != null limit 1];
            
            if(contactList.size() > 0)
            {
                contactInfo = contactList[0];
                contactInfo.EtownMemberId__c = double.valueOf(memberId);
                update contactInfo;
            }
            else
            {
                throw new PaymentVerificationException('No associated contact for this opportunity.');
            }
        }
    }
    
    public Boolean updateSuccessPaymentRecord(String memberId, String phaseNumber, Date collectedDate, Double collectedAmount)
    {
       Boolean updateResult = false;
       if(memberId != null && phaseNumber != null)
       {
           PaymentData__c payment = searchPaymentRecord(memberId, phaseNumber);
           if(payment != null)
           {
               payment.Status__c = 'Paid';
               payment.CollectedDate__c = collectedDate;
               payment.AmountCollected__c = collectedAmount;
               update payment;
               List<Actual__c> relatedActuals = [select Id, A_R_total__c, Number_of_Installments__c from Actual__c where Id = :payment.Actual__c];
               if(relatedActuals.size() > 0)
               {
                    Actual__c relatedActual = relatedActuals[0];
                    Integer currentPhaseNumber = (phaseNumber == null) ? 0 : Integer.valueOf(phaseNumber);
                    if(relatedActual.A_R_total__c == 0)
                    {
                        relatedActual.Status__c = 'Paid';
                    }
                    else if(currentPhaseNumber == relatedActuals[0].Number_of_Installments__c)
                    {
                        relatedActual.Status__c = 'Paid';
                    }
                    else
                    {
                        relatedActual.Status__c = 'In Progress';
                    }
                    update relatedActual;
                    updateResult = true;
               }
           }
       } 
       return updateResult;
    }
    
    public Boolean updateFailurePaymentRecord(String memberId, String phaseNumber, String failureReasonCode, Date collectedDate)
    {
       Boolean updateResult = false;
       if(memberId != null && phaseNumber != null)
       {
           PaymentData__c payment = searchPaymentRecord(memberId, phaseNumber);
           if(payment != null)
           {   
               String failureReason = searchFailureReason(failureReasonCode);
               payment.Status__c = 'Failed';
               payment.CollectedDate__c = collectedDate;
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
    
    private void sendEmailToSales(String salesId)
    {
         if(salesId != null)
         {
             String templateName = ''; // TO Confirm.
             List<User> sales = [select Id,Name, Email from User where Id = :salesId limit 1];
             if(sales.size() > 0)
             {
                  Account tempAccount = new Account(Name = 'temp acc');
                  insert tempAccount;
                  Contact tempContact = new Contact(LastName = 'temp con', AccountId = tempAccount.Id, Email = sales[0].Email);
                  insert tempContact;
                  List<EmailTemplate> templates = [select Id from EmailTemplate where Name = :templateName limit 1];
                  if(templates.size() > 0)
                  {
                      Messaging.Singleemailmessage email = new Messaging.Singleemailmessage();
                      // Sets other information.
                      email.setTargetObjectId(tempcontact.Id);
                      //email.setWhatId(oppId);
                      email.setTemplateId(templates[0].Id);
                      Messaging.sendEmail(new Messaging.Singleemailmessage[]{email}); 
                      //result = true;
                      delete tempContact;
                      delete tempAccount;
                  } 
                  else
                  {
                      throw new SendEmailException('Email template name error.');
                  }
             }
         }
         
    }   
    private PaymentData__c searchPaymentRecord(String memberId, String phaseNumber)
    {
        if(memberId != null && phaseNumber != null)
        {  
            List<Contact> studentList = [select Id, AccountId from Contact where EtownMemberId__c = :Decimal.valueOf(memberId)];
            if(studentList.size() > 0)
            {
                Set<String> actualStatusSet = new Set<String>{'In Progress', 'First Charge Failed', 'Second Charge Failed', 'Third Charge Failed'}; 
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
    
    private Actual__c checkPreviousPayment(Id actualId, String actualStatus, string failureReason)
    {
       if(actualId != null && actualStatus != null)
       {
           Actual__c tempActual = new Actual__c(Id = actualId, PaymentFailureReason__c = failureReason);
           if(actualStatus == 'First Charge Failed')
           {
               tempActual.Status__c = 'Second Charge Failed';
           }
           else if(actualStatus == 'Second Charge Failed')
           {
               tempActual.Status__c = 'Third Charge Failed';
           }
           else if(actualStatus != 'Third Charge Failed')
           {
               tempActual.Status__c = 'First Charge Failed';
           }
           return tempActual;
       }
       return null;    
    }
    
    // Activate course.   
    public Boolean upgradeProduct(String memberId, String offerId, String actualId, String redemptionCode)
    {   
        Boolean result = false;
        if(memberId != null && offerId != null)
        { 
            Integer memberIdValue;
            try
            {
                memberIdValue = Integer.valueOf(memberId);
            }
            catch(Exception ex)
            {
                memberIdValue = 0;
            }
            
            String utcTokenDate = generateUtcTokenDate(); 
            String securityToken = getChinaTsSecurityToken(new List<String>{memberId, utcTokenDate, chinaTsSecurityKey}); // should be change.
            ChinaTsServiceAccountInfo.CreateAccountResult webServiceResult;
            ChinaTsServiceAccountInfo.CreateAccountParams accountParams = new ChinaTsServiceAccountInfo.CreateAccountParams();
            ChinaTsServiceMemberInfo.MemberInfo memberInfo = new ChinaTsServiceMemberInfo.MemberInfo();
            memberInfo.Member_id = memberIdValue;
            memberInfo.PartnerCode = 'None';
            accountParams.Member = memberInfo;
            accountParams.RedemptionCode = redemptionCode;
            try
            {
                 webServiceResult = service.CreateAccountForMember(accountParams, utcTokenDate, securityToken);
            }
            catch(Exception ex)
            {
                 throw new UpgradeAndRetryException(ex.getMessage());
            }
           
            if(webServiceResult.IsSucceed == true)
            {
                update new actual__c(Id = actualId, ActivationStatus__c = 'Activated');
                return true;
            }
            else
            {
                throw new UpgradeAndRetryException('Activating failed.Error Code: '+ webServiceResult.ErrorCode);
            }
            
        }
        return result;
    }
    
    public Boolean retryPurchase(Integer memberId, String offerId, String actualId)
    {
        Boolean result = false;
        if(memberId != null && offerId != null)
        {   
            String utcTokenDate = generateUtcTokenDate(); 
            String securityToken = getChinaTsSecurityToken(new List<String>{String.valueOf(memberId), utcTokenDate, chinaTsSecurityKey}); // should be change.
            ChinaTsServiceReactivateResult.ReactivateAccountResult webServiceResult;
            try
            {
                 webServiceResult = service.ReactivateAccount(memberId, utcTokenDate, securityToken);
            }
            catch(Exception ex)
            {
                throw new UpgradeAndRetryException('Retrying failed.'+ ex.getMessage());
            }
            
            if(webServiceResult.IsSucceed == true)
            {
                 try
                 {
                     update new actual__c(Id = actualId, Status__c = 'In Progress');
                 }
                 catch(Exception ex)
                 {
                     throw new UpgradeAndRetryException('Update actual failed.');
                 }
                 return true;
            }
            else
            {
                throw new UpgradeAndRetryException('Retrying failed. Error Code: '+ webServiceResult.ErrorCode);
            }
        }
        return result;
    }
   
    public Boolean validateSecuriteKey(List<String> parameters, String verificationCode)
    {   
        if(parameters != null && parameters.size() > 0 && verificationCode != null)
        {
            parameters.add(chinaTsSecurityKey);
            String digestString = getChinaTsSecurityToken(parameters);
            if(verificationCode.equals(digestString))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        return false;
    }
    
    public String getChinaTsSecurityToken(List<String> params)
    {
        if(params != null)
        {
            String plainText = '';
            params.sort();
            for(String param : params)
            {
                plainText += param + ':';
            }
            plainText += '3t0wn_H@sh';
            Blob encryptedText = Crypto.generateDigest('MD5', Blob.valueOf(plainText));
            return EncodingUtil.convertToHex(encryptedText);
        }
        return null;
    } 
    
    // This method for generate utc token.
    private String generateUtcTokenDate()
    {
        // M/dd/yyyy H:mm:ss tt
        Datetime currentTime = Datetime.now();
        Integer year = currentTime.yearGmt();
        Integer month = currentTime.monthGmt();
        Integer day = currentTime.dayGmt();
        Integer hour = currentTime.hourGmt();
        Integer minute = currentTime.minuteGmt();
        Integer second = currentTime.secondGmt();
        String tt = (hour >= 12) ? 'pm' : 'am';
        return month + '/' + day + '/' + year + ' ' + hour + ':' + formatDateString(minute) + ':' + formatDateString(second) + ' ' + tt;
    }
    
    // Format date string.
    private String formatDateString(Integer value)
    {
        String result = '';
        if(value != null)
        {
            result = String.valueOf(value);
            if(result.length() < 2)
            {
                result = '0' + result;
            }
        }
        return result;
    }
    
    public class PaymentVerificationException extends Exception {}
    
    public class UpgradeAndRetryException extends Exception {}
    
    public class SendEmailException extends Exception {}
    
    @isTest
    static void testChinaTSPaymentProcessUtility()
    {
        Account testAccount = new Account(Name = 'test account');
        insert testAccount;
        Contact testContact = new Contact(AccountId = testAccount.Id, Lastname = 'last name', EtownMemberId__c = 232323);
        insert testContact;
        String chinaTsRecordTypeId = [select Id from RecordType where Name = 'China Telesales Record Type' and sobjectType = 'Opportunity' limit 1].Id;
        Opportunity testOpportunity = new Opportunity(Name = 'test opp', AccountId = testAccount.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = chinaTsRecordTypeId);
        insert testOpportunity;
        Product2 testProduct = new Product2(Name = 'test product acme', IsActive = true, Family = 'Smart new product list', OfferId__c = 'ERYEUW6635', RedemptionCode__c = 'EERER384783', IsLevel__c = true, NumberOfInstallments__c = 1);
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
        ChinaTSPaymentProcessUtility utility = new ChinaTSPaymentProcessUtility();
        // Test for installmentNumber is  1.
        Opportunity currentTestOpp = [select Id, Name, RecordType.Name, StageName, Product__c, China_Sales_Type__c, OwnerId, Owner.Username, Location__c, Opportunity_Number__c, Mobile__c, Phone2__c, Email__c, CloseDate, Amount, Payment_Type__c, Payment_Schedule__c, Number_of_Installments__c, (Select Id, PricebookEntry.Product2.IsLevel__c, PricebookEntry.Product2.Name, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.NumberOfInstallments__c from OpportunityLineItems), (select Id from Actuals__r limit 1) from Opportunity where Id = :testOpportunity.Id];
        utility.createPaymentInfo(currentTestOpp, Date.today(), 1111);
        // Delete test actual.
        List<Actual__c> actuals = [select Id from Actual__c where Opportunity__c = :testOpportunity.Id];
        delete actuals; 
        // Update installment number.
        update new Product2(Id = testProduct.Id, NumberOfInstallments__c = 6);
        update new Opportunity(Id = currentTestOpp.Id, Payment_Schedule__c = 'Installments');
        currentTestOpp = [select Id, Name, AccountId, RecordType.Name, StageName, Product__c, China_Sales_Type__c, OwnerId, Owner.Username, Location__c, Opportunity_Number__c, Mobile__c, Phone2__c, Email__c, CloseDate, Amount, Payment_Type__c, Payment_Schedule__c, Number_of_Installments__c, (Select Id, PricebookEntry.Product2.IsLevel__c, PricebookEntry.Product2.Name, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.NumberOfInstallments__c from OpportunityLineItems), (select Id from Actuals__r limit 1) from Opportunity where Id = :testOpportunity.Id];
        utility.createPaymentInfo(currentTestOpp, Date.today(), 1111, '232323');
        utility.updateSuccessPaymentRecord('232323', '2', Date.today(), 233);
        utility.updateFailurePaymentRecord('232323', '3', 'reason', Date.today());
        actuals = [select Id from Actual__c where Opportunity__c = :testOpportunity.Id];
        // Test for sendEmailToSales method.
        try
        {
            utility.sendEmailToSales([select Id from User where IsActive = true limit 1].Id);
        }
        catch(Exception ex){}
        // Test for upgrade product.
        try
        {
            utility.upgradeProduct('232323', 'TEST99999', actuals[0].Id, 'TEST99999');
        }
        catch(Exception ex){}
        // Test for retryPurchase
        try
        {
            utility.retryPurchase(232323, 'TEST99999', actuals[0].Id);
        }
        catch(Exception ex){}
        utility.validateSecuriteKey(new String[]{'test1', 'test2', 'test3'}, 'DFDRETWRSFAEW#QWR');
        utility.searchFailureReason('0003');
    } 
}