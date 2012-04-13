/*
 * Controller of page CreatePaymentPlan, for Brazil opportunities to create actual
 * Pony Ma 2011-01-20 Added street for mailing address for US
 * Pony Ma 2011-01-29 Added support for ROLA, logic is exactly same as Mexico
 */
public class CreatePaymentPlanController 
{
    private static final String BrazilOpportunityRecordTypeId = '0123000000097DO';
    private static final String MexicoOpportunityRecordTypeId = '0124000000099Hw';
    private static final String USOpportunityRecordTypeId = '012400000009A32';
    private static final String BrazilRecordTypeId = '0124000000099WD';
    private static final String MexicoRecordTypeId = '0124000000099IG';
    private static final String USRecordTypeId = '012400000009A87';
    private static final String BrazilActualRecordTypeId = '0124000000098gR';
    private static final String MexicoActualRecordTypeId = '0124000000099IB';
    private static final String USActualRecordTypeId = '012400000009A3C';
    
    //Added support for ROLA
    private static final String ROLAOpportunityRecordTypeId='01290000000NWfq';
    private static final String ROLARecordTypeId='01290000000NWkq';
    private static final String ROLAActualRecordTypeId='01290000000NWkv';
    
    //record type id in QA
    //private static final String ROLAOpportunityRecordTypeId='012N00000000AhJ';
    //private static final String ROLARecordTypeId='012N00000000AhT';
    //private static final String ROLAActualRecordTypeId='012N00000000AhO';
    
    public CreatePaymentPlanController()
    {
    }
    
    public PageReference CreateActualAndPaymentRecords()
    {
        String oppId = ApexPages.currentPage().getParameters().get('oppId');
        Boolean isValid = true;
        if(oppId != null && oppId != '')
        {//if a  actual is existed, throw a error message
            List<Actual__c> actuals = [select Id from Actual__c where Opportunity__c = :oppId limit 1];
            if(!actuals.isEmpty())
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'an actual has existed. You can not create a new actual.'));
            }
            else
            {
                List<Opportunity> opptunities = 
                [select Id, 
                    Complement__c, 
                    First_installment_after_discount__c, 
                    First_installment_Discount__c, 
                    Each_installment_amount__c, 
                    Bank_Name__c, 
                    No_of_installment_month__c, 
                    Referral_opportunity_number__c, 
                    Social_Security_or_RFC__c, Promo_Gift__c, 
                    Accoun_holder_name_1__c, 
                    Welcome_kit_receiver__c, 
                    City__c, 
                    RG__c, 
                    StageName, 
                    Neighborhood__c, 
                    CloseDate, 
                    AccountId, 
                    RecordTypeId, 
                    product__c, 
                    Amount, 
                    Payment_Type__c, 
                    Number_of_Installments__c, 
                    Check_confirmation__c, 
                    Account_Number__c, 
                    Payment_Schedule__c, 
                    CCV__c, 
                    Charging_System__c, 
                    Credit_Card_Type__c, 
                    Legal_Name__c, 
                    Bank_code__c, 
                    Zip_Code__c, 
                    State__c, Street__c, Country__c, ID_Number__c, Credit_card__c, 
                    X1st_Authorization__c, CC_Exp_Date__c, OwnerId, 
                    Account.Email__c, Account.Mobile__c, Account.Phone
                    from Opportunity where Id= :oppId 
                    and (RecordTypeId=:BrazilOpportunityRecordTypeId or RecordTypeId = :MexicoOpportunityRecordTypeId or RecordTypeId = :USOpportunityRecordTypeId or RecordTypeId=:ROLAOpportunityRecordTypeId)];                
                if(!opptunities.isEmpty())
                {
                    Opportunity currentOpportunity = opptunities[0];
                    String currentOppRecordTypeId = currentOpportunity.RecordTypeId;
                    //valid the opportunity fields value ,if is invalid throw error message
                    if(currentOpportunity.StageName != 'Closed Won')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'stage has to be close won.'));
                        isValid = false;
                    }
                    if(currentOpportunity.product__c == null || currentOpportunity.product__c == '')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Select a product.'));
                        isValid = false;
                    }
                    if(currentOpportunity.Amount == null)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount can not be empty.'));
                        isValid = false;
                    }
                    if(currentOpportunity.Payment_Type__c == null || currentOpportunity.Payment_Type__c == '')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fill in payment method.'));
                        isValid = false;
                    }
                    if(currentOpportunity.Payment_Type__c == 'Cheque' && currentOpportunity.Check_confirmation__c != true)
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'If payment method is “Cheque”, pls check with your finance. “Check confirmation” should be filled in.'));
                        isValid = false;
                    }
                    if(currentOpportunity.Number_of_Installments__c == null || currentOpportunity.Number_of_Installments__c == '')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fill in "number of installments".'));
                        isValid = false;
                    }
                    if(currentOpportunity.Payment_Schedule__c == null || currentOpportunity.Payment_Schedule__c == '')
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fill in "payment schedule".'));
                        isValid = false;
                    }
                    if(currentOppRecordTypeId.subString(0, 15) == BrazilOpportunityRecordTypeId && (currentOpportunity.ID_Number__c == null || currentOpportunity.ID_Number__c == ''))
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fill in "ID Number".'));
                        isValid = false;
                    }
                    if((currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15)==ROLAOpportunityRecordTypeId) && (currentOpportunity.First_installment_Discount__c == null || currentOpportunity.First_installment_Discount__c == ''))
                    {
                      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Fill in  first installment Discount %'));
                        isValid = false;
                    }
                    if(isValid)
                    {//if the fields is valid of the opportunity,create a actual ,and copy some fileds value from opportunity to actual
                      Date currentDay = Date.today();
                      Integer currentMonth = currentDay.month();
                      Integer currentYear = currentDay.year();
                      Date closeMonth = Date.newInstance(currentYear, currentMonth, 1);
                      
                      
                        String mailingAddress = 
                        ((currentOpportunity.Street__c != null)?currentOpportunity.Street__c:'') + ',' + 
                        ((currentOpportunity.City__c != null)?currentOpportunity.City__c:'') + ',' + 
                        ((currentOpportunity.Country__c != null)?currentOpportunity.Country__c:'');
                        
                        //Modified JH Start
                      String mailingAddressMX = 
                      ((currentOpportunity.Legal_Name__c != null)?currentOpportunity.Legal_Name__c:'') + '\n' +
                      ((currentOpportunity.Street__c != null)?currentOpportunity.Street__c:'') + '\n' +
                      '\n' +
                      ((currentOpportunity.Neighborhood__c != null)?currentOpportunity.Neighborhood__c:'') + '\n' +
                      ((currentOpportunity.City__c != null)?currentOpportunity.City__c:'') + '\n' +
                      ((currentOpportunity.Zip_Code__c != null)?currentOpportunity.Zip_Code__c:'') + '\n' +
                      ((currentOpportunity.Account.Phone != null)?currentOpportunity.Account.Phone:'') + '/' +
                      ((currentOpportunity.Account.Mobile__c != null)?currentOpportunity.Account.Mobile__c:'') + '\n' +
                      ((currentOpportunity.Welcome_kit_receiver__c != null)?currentOpportunity.Welcome_kit_receiver__c:'') + '\n' +
                      ((currentOpportunity.Account.Email__c != null)?currentOpportunity.Account.Email__c:'') + '\n';
                      
                        //Pony Ma Added mailing street for US
                        String mailingAddressUS =
                        ((currentOpportunity.Legal_Name__c != null)?currentOpportunity.Legal_Name__c:'') + '\n' +
                        ((currentOpportunity.Street__c != null)?currentOpportunity.Street__c:'') + '\n' +
                        ((currentOpportunity.City__c != null)?currentOpportunity.City__c:'') + '\n' +
                        ((currentOpportunity.Country__c != null)?currentOpportunity.Country__c:'') + '\n' +
                        ((currentOpportunity.Zip_Code__c != null)?currentOpportunity.Zip_Code__c:'') + '\n' +
                        ((currentOpportunity.Account.Phone != null)?currentOpportunity.Account.Phone:'') +
                        ((currentOpportunity.Account.Phone!=null && currentOpportunity.Account.Mobile__c!=null)?'/':'') +
                        ((currentOpportunity.Account.Mobile__c != null)?currentOpportunity.Account.Mobile__c:'') + '\n' +
                        ((currentOpportunity.Account.Email__c != null)?currentOpportunity.Account.Email__c:'');
                        
                        //Modified JH End
                        
                        Actual__c newActual = new  Actual__c(Opportunity__c = currentOpportunity.Id, 
                        Complement__c = currentOpportunity.Complement__c,
                        Account_Holder_Name__c = currentOpportunity.Accoun_holder_name_1__c, 
                        Account__c = currentOpportunity.AccountId, Bank_Name__c = currentOpportunity.Bank_Name__c, 
                        Mailing_Address__c = mailingAddress, 
                        Neighborhood__c = currentOpportunity.Neighborhood__c,  
                        Final_Price__c = currentOpportunity.Amount, City__c =currentOpportunity.City__c,  
                        Product__c = currentOpportunity.product__c, Close_Month__c = closeMonth, 
                        Payment_Type__c = currentOpportunity.Payment_Type__c, 
                        Payment_Schedule__c = currentOpportunity.Payment_Schedule__c, 
                        Number_of_Installments__c = Double.valueOf(currentOpportunity.Number_of_Installments__c), Credit_card_new__c = currentOpportunity.Credit_card__c, CCV__c = currentOpportunity.CCV__c, Charging_System__c = currentOpportunity.Charging_System__c, Credit_Card_Type__c = currentOpportunity.Credit_Card_Type__c, Official_Name__c = currentOpportunity.Legal_Name__c, Account_Number__c = currentOpportunity.Account_Number__c, Bank_Code__c = currentOpportunity.Bank_code__c,  State__c = currentOpportunity.State__c, Country__c = currentOpportunity.Country__c, Street__c = currentOpportunity.Street__c, Zip_Code__c = currentOpportunity.Zip_Code__c, PERID__c = currentOpportunity.ID_Number__c, CC_Exp_Date__c = currentOpportunity.CC_Exp_Date__c, Ist_Authorization__c = currentOpportunity.X1st_Authorization__c,  Opportunity_owner__c = currentOpportunity.OwnerId, RG__c = currentOpportunity.RG__c, RecordTypeId=BrazilActualRecordTypeId);
                        
                        if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15) == USOpportunityRecordTypeId)
                        {
                          newActual.No_of_installment_month__c = currentOpportunity.No_of_installment_month__c;
                          newActual.Referral_opportunity_number__c = currentOpportunity.Referral_opportunity_number__c;
                          newActual.Social_Security_or_RFC__c = currentOpportunity.Social_Security_or_RFC__c;
                          newActual.Promo_Gift__c = currentOpportunity.Promo_Gift__c;
                          newActual.Welcome_kit_receiver__c = currentOpportunity.Welcome_kit_receiver__c;
                          if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId)
                          {
                            newActual.RecordTypeId = MexicoActualRecordTypeId;
                            newActual.Mailing_Address__c = mailingAddressMX;
                          }else if(currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId)
                          {
                          	newActual.RecordTypeId = ROLAActualRecordTypeId;
                            newActual.Mailing_Address__c = mailingAddressUS;	
                          }else if(currentOppRecordTypeId.subString(0, 15) == USOpportunityRecordTypeId)
                          {                          
                            newActual.RecordTypeId = USActualRecordTypeId;
                            newActual.Mailing_Address__c = mailingAddressUS;
                          }
                        }
                        try
                        {
                            insert newActual;
                        }
                        catch(Exception ex)
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create actual, the error message is: ' + ex.getMessage()));
                            return null;
                        }
                        //if sucess to create the actual ,continue the payment records for the actual
                        List<Payment_Record__c> payments = new List<Payment_Record__c>();
                        Integer numberOfInstallments = integer.valueof(currentOpportunity.Number_of_Installments__c);
                        //for Mexico
                        if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15) == USOpportunityRecordTypeId)
                        {
                        Payment_Record__c firstPayment = new Payment_Record__c(Actual__c = newActual.Id);
                        if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId)
                          {
                            firstPayment.RecordTypeId = MexicoRecordTypeId;
                          }
                          else if(currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId)
                          {
                          	firstPayment.RecordTypeId = ROLARecordTypeId;	
                          }
                          else if(currentOppRecordTypeId.subString(0, 15) == USOpportunityRecordTypeId)
                          {
                            firstPayment.RecordTypeId = USRecordTypeId;
                          }
                        firstPayment.Amount_Collected__c = currentOpportunity.First_installment_after_discount__c;
                            firstPayment.Amount_Due__c = currentOpportunity.First_installment_after_discount__c;
                            firstPayment.Due_Date__c = currentDay;
                            firstPayment.Collected_Date__c = currentOpportunity.CloseDate;
                            firstPayment.Status__c = 'Collected';
                            firstPayment.Installment__c = '1';
                            payments.add(firstPayment);
                            for(Integer i = 0; i < numberOfInstallments - 1; i++)
                            {                       
                                Payment_Record__c remainPayment = new Payment_Record__c(Actual__c = newActual.Id);
                                if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId)//ADD
	                            {
	                              remainPayment.RecordTypeId = MexicoRecordTypeId;
	                            }
	                            else if(currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId)
	                            {
	                            	remainPayment.RecordTypeId = ROLARecordTypeId;		
	                            }
	                            else if(currentOppRecordTypeId.subString(0, 15) == USOpportunityRecordTypeId)
	                            {
	                              remainPayment.RecordTypeId = USRecordTypeId;
	                            }
                                remainPayment.Amount_Due__c = currentOpportunity.Each_installment_amount__c;                        
                                remainPayment.Status__c = 'Due';
                                remainPayment.Installment__c = string.valueof((i + 2));                             
                               if(currentOpportunity.No_of_installment_month__c == '2')
                               {
                                   remainPayment.Due_Date__c = currentDay.addDays(15*(i + 1));
                               }
                               else
                               {
                                    remainPayment.Due_Date__c = currentDay.addMonths((i + 1));
                               }
                               payments.add(remainPayment);
                            }
                          system.debug('###' + payments[0]);  
                        }
                        else//for brazial
                        {
                          //pay by manual ,will create more payment records
                          if(currentOpportunity.Payment_Schedule__c == 'Installments-Manual-Deposit')
                          {                      
                               double remainPaymentAmount = 0.8*currentOpportunity.Amount/(numberOfInstallments - 1);                         
                               Payment_Record__c firstPayment = new Payment_Record__c(Actual__c = newActual.Id, RecordTypeId = BrazilRecordTypeId);
                               firstPayment.Amount_Collected__c = 0.2*currentOpportunity.Amount;
                               firstPayment.Amount_Due__c = 0.2*currentOpportunity.Amount;
                               firstPayment.Due_Date__c = currentDay;
                               firstPayment.Collected_Date__c = currentOpportunity.CloseDate;
                               firstPayment.Status__c = 'Collected';
                               firstPayment.Installment__c = '1';
                               payments.add(firstPayment);
                               for(Integer i = 0; i < numberOfInstallments - 1; i++)
                               {
                                  Payment_Record__c remainPayment = new Payment_Record__c(Actual__c = newActual.Id, RecordTypeId = BrazilRecordTypeId);
                                  remainPayment.Amount_Due__c = remainPaymentAmount;
                                  remainPayment.Due_Date__c = currentDay.addMonths((i + 1));
                                  remainPayment.Status__c = 'Due';
                                  remainPayment.Installment__c = string.valueof((i + 2));
                                  payments.add(remainPayment);
                               }
                          }
                          else
                          {//create  payment records whene payment schedule is NOT “installments –manual-deposit”
                             double singlePaymentAmount = currentOpportunity.Amount/numberOfInstallments;    
                               Payment_Record__c firstPayment = new Payment_Record__c(Actual__c = newActual.Id, RecordTypeId = BrazilRecordTypeId);
                               firstPayment.Amount_Collected__c = singlePaymentAmount;
                               firstPayment.Amount_Due__c = singlePaymentAmount;
                               firstPayment.Due_Date__c = currentDay;
                               firstPayment.Collected_Date__c = currentOpportunity.CloseDate;
                               firstPayment.Status__c = 'Collected';
                               firstPayment.Installment__c = '1';
                               payments.add(firstPayment);
                               for(Integer i = 0; i < numberOfInstallments - 1; i++)
                               {
                                  Payment_Record__c remainPayment = new Payment_Record__c(Actual__c = newActual.Id, RecordTypeId = BrazilRecordTypeId);
                                  remainPayment.Amount_Due__c = singlePaymentAmount;
                                  remainPayment.Due_Date__c = currentDay.addMonths((i + 1));
                                  remainPayment.Status__c = 'Due';
                                  remainPayment.Installment__c = string.valueof((i + 2));
                                  payments.add(remainPayment);
                               }
                          }
                        }
                        try
                        {
                          insert payments; 
                          newActual.Payment_Plan_Description__c = getPaymentsDescription(payments); 
                          update newActual;                                                  
                        }
                        catch(Exception ex)
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Actual is created successfully, but failed to create payment records, the error message is: ' + ex.getMessage()));
                            return null;
                        }
                        //if sucess to create the actual and payment records ,continue to clear some fields for the opportunity
                        Opportunity newOpportunity = new Opportunity(Id = currentOpportunity.Id);
                        newOpportunity.Payment_Type__c = null;
                        newOpportunity.Payment_Schedule__c = null;
                        newOpportunity.Number_of_Installments__c = null;
                        newOpportunity.CCV__c = '';
                        newOpportunity.Charging_System__c = null; 
                        newOpportunity.Credit_Card_Type__c = null;
                        newOpportunity.Credit_Card__c = null;
                        newOpportunity.CC_Exp_Date__c = null;
                        newOpportunity.Legal_Name__c = null;
                        newOpportunity.Account_Number__c = null;
                        newOpportunity.Bank_code__c = null;
                        newOpportunity.City__c = null;
                        newOpportunity.State__c = null;
                        newOpportunity.Country__c = null;
                        newOpportunity.Zip_Code__c = null;
                        newOpportunity.Street__c = null;
                        if(currentOppRecordTypeId.subString(0, 15) == MexicoOpportunityRecordTypeId || currentOppRecordTypeId.subString(0, 15) == ROLAOpportunityRecordTypeId)
                        {
                          newOpportunity.No_of_installment_month__c = null;
                          newOpportunity.Referral_opportunity_number__c = null;
                          newOpportunity.Social_Security_or_RFC__c = null;
                          newOpportunity.Promo_Gift__c = null;
                          newOpportunity.Accoun_holder_name_1__c = null;
                          newOpportunity.Welcome_kit_receiver__c = null;
                        }
                        try
                        {
                            update newOpportunity;
                            return new PageReference('/' + newActual.Id);    
                        }
                        catch(Exception ex)
                        {
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                        }                   
                    }
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity specified. Please take care this button only works for Brazil Opportunities or Mexico/US Opportunities.'));
                }  
            }
        }
        return null;
    }
    // gets payments description 
     private String getPaymentsDescription(List<Payment_Record__c> payments)
     {
       String paymentPlanDescription = 'Payment 1 Amount ' + String.valueOf(payments[0].Amount_Due__c)  + ' Received ' + payments[0].Collected_Date__c.format() + '\r\n';
       for(Integer i = 1; i < payments.size(); i++)
       {
         paymentPlanDescription += 'Payment ' + string.valueof((i + 1)) + ' Amount ' + String.valueOf(payments[i].Amount_Due__c) + ' Due ' + (payments[i].Due_Date__c.format()) +'\r\n';
       }
       return paymentPlanDescription;
     }
     
    @isTest 
    static void testController()
    {
      String BrazilOppRecordTypeId = '0123000000097DO';
        Account acc = new Account(name='acme');
        insert acc;
        Product2 product = new Product2(Name = 'Premium 10', Months__c = 7, EtownId__c = 'test1234');
        insert product;
        Opportunity currentOpp = new Opportunity(AccountId=acc.Id, Name = 'acme', Product__c = product.Id, Amount = 5000, Payment_Schedule__c = 'Installments-Manual-Deposit', Number_of_Installments__c = '5', Payment_Type__c = 'Cash Full Payment', Location__c = 'BJ DFG', StageName = 'Closed Won', CloseDate = Date.today(), RecordTypeId=BrazilOppRecordTypeId, China_Sales_Type__c = 'New');
        insert currentOpp;
        PageReference testPage = new PageReference('/apex/CreateActualForOpportunity?oppId=' + currentOpp.Id);
        test.setCurrentPage(testPage);
        CreatePaymentPlanController controller = new CreatePaymentPlanController();
        controller.CreateActualAndPaymentRecords();
        
        String MexicoOppRecordTypeId = '0124000000099Hw';
        Account acc2 = new Account(name='acme');
        insert acc2;
        Product2 product2 = new Product2(Name = 'Premium 11', Months__c = 7, EtownId__c = 'acme');
        insert product2;
        Opportunity MexicoOpp = new Opportunity(AccountId=acc2.Id, Name = 'acme', Product__c = product2.Id, Amount = 5000, No_of_installment_month__c = '1', First_installment_Discount__c = '50%', Referral_opportunity_number__c = 'acme', Social_Security_or_RFC__c = 'acme', First_installment_after_discount__c = 100, Each_installment_amount__c = 200, Welcome_kit_receiver__c = 'acme', Payment_Schedule__c = 'Installments-Manual-Deposit', Number_of_Installments__c = '5', Payment_Type__c = 'Cash Full Payment', Location__c = 'BJ DFG', StageName = 'Closed Won', CloseDate = Date.today(), RecordTypeId = MexicoOppRecordTypeId, China_Sales_Type__c = 'New');
        insert MexicoOpp;
        PageReference mexTestpage = new PageReference('/apex/CreateActualForOpportunity?oppId=' + MexicoOpp.Id);
        test.setCurrentPage(mexTestpage);
        CreatePaymentPlanController mexicoController = new CreatePaymentPlanController();
        mexicoController.CreateActualAndPaymentRecords();
        
        
        Opportunity currentOpp2 = new Opportunity(AccountId=acc.Id, Name = 'acme', Product__c = product.Id, Amount = 5000, Payment_Schedule__c = 'Singel', Number_of_Installments__c = '5', Payment_Type__c = 'Cash Full Payment', Location__c = 'BJ DFG', StageName = 'Closed Won', CloseDate = Date.today(), RecordTypeId=BrazilOppRecordTypeId, China_Sales_Type__c = 'New');
        insert currentOpp2;
        PageReference testPage2 = new PageReference('/apex/CreateActualForOpportunity?oppId=' + currentOpp2.Id);
        test.setCurrentPage(testPage2);
        CreatePaymentPlanController controller2 = new CreatePaymentPlanController();
        controller2.CreateActualAndPaymentRecords();
    }
}