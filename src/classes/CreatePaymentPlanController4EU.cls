/*
 * Controller of page CreatePaymentPlan, for Europe opportunities to create actual
 * Author: Jerry Hong
 * Pony Ma 2012-02-23 Added support for Korean/Japan
 * Pony Ma 2012-02-23 Refactored class, Removed hard-coded record type ids.
 */
public class CreatePaymentPlanController4EU 
{       
    private Opportunity currentOpportunity  = null;
    private String oppId = ApexPages.currentPage().getParameters().get('oppId');
    private Id currentOppRecordTypeId = null; 
    public Actual__c NewActual {get; set;}
    public List<Payment_Record__c> FirstPaymentRecords {get; set;}
    public List<Payment_Record__c> RemainPaymentRecords {get; set;}
         
    public CreatePaymentPlanController4EU()
    {
        init();       
    }
                            
    private void init()
    {
        FirstPaymentRecords = new List<Payment_Record__c>();
        RemainPaymentRecords = new List<Payment_Record__c>();
        
        String actualRecordTypeId='';
        String paymentRecordTypeId='';
        
        Boolean isValid = true;
        if(oppId != null && oppId != '')
        {
        	//Get Oppo Info(S)
            List<Opportunity> opptunities = 
            [select Id, First_installment_after_discount__c, First_installment_Discount__c, Each_installment_amount__c, Bank_Name__c, 
            No_of_installment_month__c, Referral_opportunity_number__c, Social_Security_or_RFC__c, Promo_Gift__c, Accoun_holder_name_1__c, 
            Welcome_kit_receiver__c, City__c, RG__c, StageName, Neighborhood__c, CloseDate, AccountId, RecordTypeId, product__c, RecordType.Name,Amount, 
            Payment_Type__c, Number_of_Installments__c, Check_confirmation__c, Account_Number__c, Payment_Schedule__c, 
            CCV__c, Charging_System__c, Credit_Card_Type__c, Legal_Name__c, Bank_code__c, Zip_Code__c, State__c, Street__c, Country__c, 
            ID_Number__c, Credit_card__c, X1st_Authorization__c, CC_Exp_Date__c, OwnerId 
            from Opportunity 
            where Id= :oppId ];
            //Get Oppo Info(E)
                              
            if(!opptunities.isEmpty())
            {
                currentOpportunity = opptunities[0];
                currentOppRecordTypeId = currentOpportunity.RecordTypeId;
                
                system.debug('Current RT Id'+ currentOppRecordTypeId);                
                
                //init actual and paymentrecord record type based on country name in opp record type
                String oppRecordName=currentOpportunity.RecordType.Name;
                //by default, the first word in record type name should be country name
                String countryName=currentOpportunity.RecordType.Name.split(' ')[0];
                String countryNameFilter=countryName + '%';
                List<RecordType> lstActualRT=[select Id,Sobjecttype,Name from RecordType where Name like :countryNameFilter and Sobjecttype='Actual__c'];
                if(lstActualRT.size()>0){
                	actualRecordTypeId=lstActualRT[0].Id;	
                }
                system.debug('Current Actual RT Id:' + actualRecordTypeId);
                List<RecordType> lstPaymentRecordRT=[select Id,Sobjecttype,Name from RecordType where Name like :countryNameFilter and Sobjecttype='Payment_Record__c'];
                if(lstPaymentRecordRT.size()>0){
                	paymentRecordTypeId=lstPaymentRecordRT[0].Id;	
                }
                system.debug('Current Payment Record RT Id:' + paymentRecordTypeId);
                
                if(actualRecordTypeId=='' || paymentRecordTypeId==''){
                	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Not able to get actual record type or paymnet record type(by country) from opportunity record type ' + oppRecordName));
                	return;	
                }
                                
                //Create a actual ,and copy some fileds value from opportunity to actual
                Date currentDay = Date.today();
                //String paymentPlanDescription = '';
                Integer currentMonth = currentDay.month();
                Integer currentYear = currentDay.year();
                Date closeMonth = Date.newInstance(currentYear, currentMonth, 1);
                String mailingAddress = ((currentOpportunity.Street__c != null)?currentOpportunity.Street__c:'') + ',' + ((currentOpportunity.City__c != null)?currentOpportunity.City__c:'') + ',' + ((currentOpportunity.Country__c != null)?currentOpportunity.Country__c:'');
                
                Integer Number_of_Installments;
                
                if ( currentOpportunity.Number_of_Installments__c != null && currentOpportunity.Number_of_Installments__c != '')
                {
                	Number_of_Installments = Integer.valueof(currentOpportunity.Number_of_Installments__c);
                }
                else
                {
                	Number_of_Installments = 0;	
                }
                
                NewActual = new  Actual__c
                (
                Opportunity__c = currentOpportunity.Id, 
                Account_Holder_Name__c = currentOpportunity.Accoun_holder_name_1__c, 
                Account__c = currentOpportunity.AccountId, 
                Bank_Name__c = currentOpportunity.Bank_Name__c, 
                Mailing_Address__c = mailingAddress, 
                Neighborhood__c = currentOpportunity.Neighborhood__c,  
                Final_Price__c = currentOpportunity.Amount, 
                City__c =currentOpportunity.City__c,  
                Product__c = currentOpportunity.product__c, 
                Close_Month__c = closeMonth, 
                Payment_Type__c = currentOpportunity.Payment_Type__c, 
                Payment_Schedule__c = currentOpportunity.Payment_Schedule__c, 
                //Number_of_Installments__c = Double.valueOf(currentOpportunity.Number_of_Installments__c), 
                Number_of_Installments__c = Double.valueOf(Number_of_Installments), 
                Credit_card_new__c = currentOpportunity.Credit_card__c,
                CCV__c = currentOpportunity.CCV__c, 
                Charging_System__c = currentOpportunity.Charging_System__c, 
                Credit_Card_Type__c = currentOpportunity.Credit_Card_Type__c, 
                Official_Name__c = currentOpportunity.Legal_Name__c, 
                Account_Number__c = currentOpportunity.Account_Number__c, 
                Bank_Code__c = currentOpportunity.Bank_code__c,  
                State__c = currentOpportunity.State__c, 
                Country__c = currentOpportunity.Country__c, 
                Street__c = currentOpportunity.Street__c, 
                Zip_Code__c = currentOpportunity.Zip_Code__c, 
                PERID__c = currentOpportunity.ID_Number__c, 
                CC_Exp_Date__c = currentOpportunity.CC_Exp_Date__c, 
                //Ist_Authorization__c = currentOpportunity.X1st_Authorization__c,  
                Opportunity_owner__c = currentOpportunity.OwnerId, 
                RG__c = currentOpportunity.RG__c,
                Referral_opportunity_number__c = currentOpportunity.Referral_opportunity_number__c,
                Social_Security_or_RFC__c = currentOpportunity.Social_Security_or_RFC__c,
                Promo_Gift__c = currentOpportunity.Promo_Gift__c,
                Welcome_kit_receiver__c = currentOpportunity.Welcome_kit_receiver__c
                );
           		
           		//for Japan & Korean, auto approve actual
           		if(oppRecordName.contains('Korea') || oppRecordName.contains('Japan')){
           			newActual.Approved__c=true;
           			if(Number_of_Installments==1){
           				newActual.Status__c='Paid in Full';	
           			}else{
           				newActual.Status__c = 'In Progress';
           			}	           			           			
           		} 
           		
                newActual.RecordTypeId=actualRecordTypeId;
                
                //Set First Payment Payment_Record__c Record Type(Start)
                Payment_Record__c firstPayment = new Payment_Record__c();
                firstPayment.RecordTypeId=paymentRecordTypeId;
                                                    
                //Set First Payment(Start)
                firstPayment.Amount_Collected__c = currentOpportunity.First_installment_after_discount__c;
                firstPayment.Amount_Due__c = currentOpportunity.First_installment_after_discount__c;
                firstPayment.Due_Date__c = currentDay;
                firstPayment.Collected_Date__c = currentOpportunity.CloseDate;
                firstPayment.Status__c = 'Collected';
                firstPayment.Installment__c = '1';
                FirstPaymentRecords.add(firstPayment);        
                //Set First Payment(End)
                                        
                //Set Remain Payment(Start)
                Integer numberOfInstallments = integer.valueof(currentOpportunity.Number_of_Installments__c);
            	if (numberOfInstallments > 1)
            	{
                    for(Integer i = 0; i < numberOfInstallments - 1; i++)
                    {                       
                        Payment_Record__c remainPayment = new Payment_Record__c();
                        remainPayment.RecordTypeId=paymentRecordTypeId;                                                
                        remainPayment.Amount_Due__c = currentOpportunity.Each_installment_amount__c;                        
                        remainPayment.Status__c = 'Due';
                        remainPayment.Installment__c = string.valueof((i + 2));                             
                        if(currentOpportunity.No_of_installment_month__c == '2') {remainPayment.Due_Date__c = currentDay.addDays(15*(i + 1)); }
                        else {remainPayment.Due_Date__c = currentDay.addMonths((i + 1));}
                        RemainPaymentRecords.add(remainPayment);
                    }
        		}                                  
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity specified. Please take care this button only works for Brazil, Mexico/US or Europe Opportunities.'));
            }   
        }
    }//End of init()
    
    //creates actual and payments
    public PageReference Save()
    {              
        try
        {                   
            Boolean isValid1 = true;
            Boolean isValid2 = true;
            Integer numberOfInstallments = integer.valueof(currentOpportunity.Number_of_Installments__c);
            if (numberOfInstallments > 1)
            {
	            //Validation 1(Start)                
	            decimal InstallTotal = 0;
	            for(Payment_Record__c PaymentRecord : FirstPaymentRecords)
	            {
	                InstallTotal+=PaymentRecord.Amount_Due__c;
	            }
	            
	            for(Payment_Record__c PaymentRecord : RemainPaymentRecords)
	            {
	                InstallTotal+=PaymentRecord.Amount_Due__c;
	            }
	            system.debug('Install Total: '+InstallTotal);          
	            if(InstallTotal!=currentOpportunity.Amount){isValid1 = False;}
	            //Validation 1(End)
	            
	            //Validation 2(Start)
	            Integer i=RemainPaymentRecords.size();
	            Integer k;
	            Boolean Flag = true;
	            if(i>1)
	            {
	                for(k=0;k<i-1;k++)
	                {   
	                    if(RemainPaymentRecords[k].Due_Date__c>RemainPaymentRecords[k+1].Due_Date__c)
	                    {
	                        isValid2 = false;
	                    }
	                }
	            }
	            
	            Integer l=FirstPaymentRecords.size();
	            if (l > 0)
	            {
	                if(FirstPaymentRecords[l-1].Due_Date__c>RemainPaymentRecords[0].Due_Date__c)
	                {
	                    isValid2 = false;
	                }
	            }    
	            system.debug('FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF: '+Flag);
	            //Validation 2(End)
            }
            
            //Create Payment Plan(Start)
            if(!isValid1)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sum of Amount Due should be equal to Final Price!'));
                return null;
            }
            else if(!isValid2)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Installment Due Date out of order!'));
                return null;
            }
            else
            {
                insert NewActual;
                if (numberOfInstallments > 1)
            	{
	                for(Payment_Record__c newPaymentRecord : RemainPaymentRecords)
	                {
	                    newPaymentRecord.Actual__c = NewActual.Id;
	                }
            	}
                for(Payment_Record__c newPaymentRecord : FirstPaymentRecords)
                {
                    newPaymentRecord.Actual__c = NewActual.Id;
                }
                try
                {
                    insert FirstPaymentRecords;
                    if (numberOfInstallments > 1)
            		{
                    	insert RemainPaymentRecords; 
            		}
            	                     
                    NewActual.Payment_Plan_Description__c = getPaymentsDescription(FirstPaymentRecords,RemainPaymentRecords);
                    update NewActual; 
                    clearOpportunity(oppId);
                    return new PageReference('/' + NewActual.Id);
                }
                catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Actual is created successfully, but failed to create payment records, the error message is: ' + ex.getMessage()));
                    return null;
                }
            }
            //Create Payment Plan(End)

        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create actual, the error message is: ' + ex.getMessage()));
            return null;
        }        
        //if sucess to create the actual and payment records ,continue to clear some fields for the opportunity
        
        return null;
    }
    
    //cancels the action
    public PageReference Cancel()
    {
        return new PageReference('/' + oppId);
    }
    
    // gets payments description 
     private String getPaymentsDescription(List<Payment_Record__c> Fp, List<Payment_Record__c> Rp)
     {
        String paymentPlanDescription = 'Payment 1 Amount ' + String.valueOf(Fp[0].Amount_Due__c)  + ' Received ' + Fp[0].Collected_Date__c.format() + '\r\n';
        for(Integer i = 0; i < Rp.size(); i++)
        {
            paymentPlanDescription += 'Payment ' + string.valueof((i + 2)) + ' Amount ' + String.valueOf(Rp[i].Amount_Due__c) + ' Due ' + (Rp[i].Due_Date__c.format()) +'\r\n';
        }
        return paymentPlanDescription;
     }
    
     //clears some fields when successes.
     private void clearOpportunity(Id opportunityId)
     {
        Opportunity newOpportunity = new Opportunity(Id = opportunityId);
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
        
        try
        {
            update newOpportunity;  
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }                   
     }
     
    @isTest 
    static void testController()
    {
        String FranceOppoRecordTypeId = '0124000000099XL';
        
        Account acc = new Account(name='acme');
        insert acc;
        Product2 product = new Product2(Name = 'Premium 10', Months__c = 7, EtownId__c = 'test1234');
        insert product;
        
        Opportunity FraOpp = new Opportunity(AccountId=acc.Id, Name = 'acme', Product__c = product.Id, Amount = 5000, 
        Payment_Schedule__c = 'Installments-Manual-Deposit', Number_of_Installments__c = '5', Payment_Type__c = 'Cash Full Payment', 
        Location__c = 'BJ DFG', StageName = 'Closed Won', CloseDate = Date.today(), RecordTypeId=FranceOppoRecordTypeId, 
        China_Sales_Type__c = 'New');
        insert FraOpp;
        
        PageReference testPage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + FraOpp.Id);
        test.setCurrentPage(testPage);
        
        CreatePaymentPlanController4EU FraController = new CreatePaymentPlanController4EU();
        FraController.init();
        FraController.save();
        FraController.cancel();
        
        String GermanyOppoRecordTypeId = '012400000009AxZ';
        Account acc2 = new Account(name='acme');
        insert acc2;
        Product2 product2 = new Product2(Name = 'Premium 11', Months__c = 7, EtownId__c = 'acme');
        insert product2;
        Opportunity GerOpp = new Opportunity
        (
        	AccountId=acc2.Id, 
        	Name = 'acme', 
        	Product__c = product2.Id, Amount = 5000, 
        	No_of_installment_month__c = '1', 
	        First_installment_Discount__c = '50%', 
	        Referral_opportunity_number__c = 'acme', 
	        Social_Security_or_RFC__c = 'acme', 
	        First_installment_after_discount__c = 100, 
	        Each_installment_amount__c = 200, 
	        Welcome_kit_receiver__c = 'acme', 
	        Payment_Schedule__c = 'Installments-Manual-Deposit', 
	        Number_of_Installments__c = '5', 
	        Payment_Type__c = 'Cash Full Payment',  
	        StageName = 'Closed Won', 
	        CloseDate = Date.today(), 
	        RecordTypeId = GermanyOppoRecordTypeId, 
	        China_Sales_Type__c = 'New'
        );
        insert GerOpp;
        PageReference GerTestpage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + GerOpp.Id);
        test.setCurrentPage(GerTestpage);
        CreatePaymentPlanController4EU GerController = new CreatePaymentPlanController4EU();
        GerController.init();
        GerController.save();
        GerController.cancel();
        
        String ItalyOppoRecordTypeId = '012400000009BQR';
        Opportunity ItaOpp = new Opportunity(AccountId=acc.Id, Name = 'acme', Product__c = product.Id, Amount = 5000, 
        Payment_Schedule__c = 'Singel', Number_of_Installments__c = '5', Payment_Type__c = 'Cash Full Payment', Location__c = 'BJ DFG', 
        StageName = 'Closed Won', CloseDate = Date.today(), RecordTypeId=ItalyOppoRecordTypeId, China_Sales_Type__c = 'New');
        insert ItaOpp;
        PageReference ItatestPage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + ItaOpp.Id);
        test.setCurrentPage(ItatestPage);
        CreatePaymentPlanController4EU ItaController = new CreatePaymentPlanController4EU();
        ItaController.init();
        ItaController.save();
        
        //Opportunity__c = currentOpportunity.Id, 
        list <Opportunity> ItaOppList = [Select Id from Opportunity where AccountId=:acc.Id];
        Opportunity ItaOpp2 = ItaOppList[0];
        Id ItaOppId = ItaOpp2.Id;
        //list<Actual__c> ItaAcutalList = [Select Id from Actual__c where Opportunity__c =: ItaOppId];
        list<Actual__c> ItaAcutalList = [Select a.Id, a.RecordTypeId from Actual__c a where a.RecordTypeId='012400000009BQbAAM' limit 1];
                                         
        Actual__c ItaAcutal = ItaAcutalList[0];
        ItaAcutal.Status__c = 'Paid in Full';
        update ItaAcutal;
        Id TestId = ItaAcutal.Id;
        
        /*
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
  		req1.setComments('Submitting request for approval.');
   		req1.setObjectId(TestId);
   		
   		list<User> ItaUserList = [Select u.Id, u.UserRoleId from User u where u.UserRoleId='00E40000000rTgJEAU' limit 1];
   		User ItaUser = ItaUserList[0];
   		Id ItaUserId = ItaUser.Id;
   	
   		Profile p = [select id from profile where name='System Administrator'];
        User u = new User
        	(	alias = 'standt', 
        		email='standarduser@testorg.com',
            	emailencodingkey='UTF-8', 
            	lastname='Testing', 
            	languagelocalekey='en_US',
            	localesidkey='en_US', 
            	profileid = p.Id,
            	timezonesidkey='America/Los_Angeles', 
            	username='yipinghong1111@gmail.com',
            	UserRoleId = ItaUser.UserRoleId,
            	Locale__c = 'US',
            	Functions__c = 'Etown global'
            );
   		insert u;
   		
   		System.runAs(u) 
   		{
   			list<Actual__c> ItaAcutalList2 = [Select a.Id, a.RecordTypeId from Actual__c a where a.RecordTypeId='012400000009BQbAAM' limit 1];        
        	Actual__c ItaAcutal2 = ItaAcutalList2[0];
        	ItaAcutal2.Status__c = 'Paid in Full';
        	update ItaAcutal2;
        	Id TestId2 = ItaAcutal2.Id;
   			Approval.ProcessSubmitRequest req2 = new Approval.ProcessSubmitRequest();
  			req1.setComments('Submitting request for approval.');
   			req1.setObjectId(TestId2);
   			Approval.ProcessResult result2 = Approval.process(req1);
   			System.assert(result2.isSuccess()); 
   		}
   		 
   		//System.assert(result.isSuccess()); 
   		//req1.setAction('Approve');  
        */
        
        ItaController.cancel();
        
        String SpainOppoRecordTypeId = '012400000009AxU';
        Opportunity SpaOpp = new Opportunity
        (
         AccountId=acc.Id, 
         Name = 'acme3', 
         Product__c = product.Id, 
         //Amount = 5000, 
         Payment_Schedule__c = 'Installments', 
         Number_of_Installments__c = '6', 
         Payment_Type__c = 'Credit Card-Installments', 
         Each_installment_amount__c = 200,
         First_installment_Discount_amount__c = 100,
         //Payment_Method_c = '',
         
         Location__c = 'BJ DFG', 
         StageName = 'Closed Won', 
         CloseDate = Date.today(), 
         RecordTypeId=SpainOppoRecordTypeId, 
         China_Sales_Type__c = 'New'
        );
        
        insert SpaOpp;
        
        PageReference SpatestPage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + ItaOpp.Id);
        test.setCurrentPage(SpatestPage);
        CreatePaymentPlanController4EU SpaController = new CreatePaymentPlanController4EU();
        SpaController.init();
        SpaController.save();
        
        /*
    	String MeastOppoRecordTypeId = '012O00000004JHE';
    	Opportunity MeastOpp = new Opportunity 
    	(
         AccountId=acc.Id, 
         Name = 'acme3', 
         Product__c = product.Id, 
         //Amount = 5000, 
         Payment_Schedule__c = 'Installments', 
         Number_of_Installments__c = '6', 
         Payment_Type__c = 'Credit Card-Installments', 
         Each_installment_amount__c = 200,
         First_installment_Discount_amount__c = 100,
         //Payment_Method_c = '',
         
         Location__c = 'BJ DFG', 
         StageName = 'Closed Won', 
         CloseDate = Date.today(), 
         RecordTypeId=MeastOppoRecordTypeId, 
         China_Sales_Type__c = 'New'
        );
    	insert MeastOpp;
        PageReference MeasttestPage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + ItaOpp.Id);
        test.setCurrentPage(MeasttestPage);
        CreatePaymentPlanController4EU MeastController = new CreatePaymentPlanController4EU();
        MeastController.init();
    	    	
    	/*
    	String UkOppoRecordTypeId = '012O00000004JtN';
    	Opportunity ukOpp = new Opportunity
    	(
         AccountId=acc.Id, 
         Name = 'acme3', 
         Product__c = product.Id, 
         //Amount = 5000, 
         Payment_Schedule__c = 'Installments', 
         Number_of_Installments__c = '6', 
         Payment_Type__c = 'Credit Card-Installments', 
         Each_installment_amount__c = 200,
         First_installment_Discount_amount__c = 100,
         //Payment_Method_c = '',
         
         Location__c = 'BJ DFG', 
         StageName = 'Closed Won', 
         CloseDate = Date.today(), 
         RecordTypeId=UkOppoRecordTypeId, 
         China_Sales_Type__c = 'New'
        );
        insert UkOpp;
        PageReference UktestPage = new PageReference('/apex/CreatePaymentPlan4EU?oppId=' + ItaOpp.Id);
        test.setCurrentPage(UktestPage);
        CreatePaymentPlanController4EU UkController = new CreatePaymentPlanController4EU();
        UkController.init();
    	*/
    }
}