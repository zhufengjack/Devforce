/*
 *The class of create Actual, China Payment Data,Student Product,Student Actual.
 *
 */
public class ChinaTSFinanceDataUtility
{
    private ActualEntity actualEntity = new ActualEntity();
    private StudentActualEntity studentActualEntity = new StudentActualEntity();
    private PaymentDataEntity paymentDataEntity = new PaymentDataEntity();
    private StudentProductEntity studentProductEntity = new StudentProductEntity();

	// Unionpay use this method.
    public String generateFinanceData(Opportunity opp, Date collectedDate, Double amountCollected)
    {
        String resultId;
        CreateDataConfig tsConfigInfo = new CreateDataConfig();
        try
        {
            buildData(opp, collectedDate, amountCollected);
            resultId = createData(opp.Id, tsConfigInfo);
        } 
        catch(Exception ex)
        {
            throw new CreateChinaTsFinanceDataException('Generate data failed. Error message: ' + ex.getMessage()); // ex.getStackTraceString();
        }
        return resultId;
    }

    public String generateFinanceData(TsCreateActualController.ChinaTSFinanceInfo financeInfo)
    {
        String resultId;
        CreateDataConfig tsConfigInfo = new CreateDataConfig();
        tsConfigInfo.isRequiredToCreateStudentProduct = false;
        tsConfigInfo.isRequiredToCreatePaymentData = false;
        try
        {
            buildData(financeInfo);
            resultId = createData(financeInfo.Record.Id, tsConfigInfo);
        }
        catch(Exception ex)
        {
            throw new CreateChinaTsFinanceDataException('Generate data failed. Error message: ' + ex.getMessage());
        }
        return resultId;
    }

	// For Unionpay.
    private void buildData(Opportunity opp, Date collectedDate, Double amountCollected)
    {
        if(opp != null)
        {
            actualEntity.ownerId = UserInfo.getUserId();
            actualEntity.closeDate = Date.today();
            // We get the company code from custom setting.
			List<FinanceCompanyCode__c> companyCodes = [select CompanyCode__c from FinanceCompanyCode__c where Location__c = :opp.Location__c];
			if(companyCodes.size() == 1)
			{
				actualEntity.companyCode = companyCodes[0].CompanyCode__c;
			}
            // actualEntity.companyCode = opp.Company_Type__c;
            actualEntity.salesType = opp.China_Sales_Type__c;
            actualEntity.opportunityId = opp.Id;
            actualEntity.opportunityOwnerId = opp.OwnerId;
            actualEntity.salesApptLocation = opp.Location__c;
            actualEntity.opportunityNumber = opp.Opportunity_Number__c;
            actualEntity.ownerId = opp.OwnerId;
            actualEntity.accountId = opp.AccountId;
            actualEntity.paymentMethod = 'UnionPay';
            paymentDataEntity.paymentMethod = 'UnionPay'; //opp.Payment_Type__c;
            paymentDataEntity.closeDate = opp.CloseDate;
            PaymentDataEntity.payType = 'China TS Payment';
            if(opp.OpportunityLineItems.size() > 0)
            {
                Decimal numberOfInstallment = opp.OpportunityLineItems[0].PricebookEntry.Product2.NumberOfInstallments__c;
                actualEntity.numberOfInstallments = (numberOfInstallment == null)? 0: numberOfInstallment.intValue();
                actualEntity.firstInstallmentAmount = opp.OpportunityLineItems[0].PricebookEntry.Product2.FirstInstallmentAmount__c;
                actualEntity.monthlyFeeAmount = opp.OpportunityLineItems[0].PricebookEntry.Product2.MonthlyFee__c;
                paymentDataEntity.firstInstallmentAmount = opp.OpportunityLineItems[0].PricebookEntry.Product2.FirstInstallmentAmount__c;
                paymentDataEntity.monthlyFeeAmount = opp.OpportunityLineItems[0].PricebookEntry.Product2.MonthlyFee__c;
                paymentDataEntity.collectedData = collectedDate;
                paymentDataEntity.amount = amountCollected;
                paymentDataEntity.ownerId = opp.OwnerId;
                paymentDataEntity.numberOfInstallments = (numberOfInstallment == null)? 0: numberOfInstallment.intValue();

                studentProductEntity.standardLength = String.valueOf(opp.OpportunityLineItems[0].PricebookEntry.Product2.CourseLength__c);
                studentProductEntity.marketingLength = String.valueOf(opp.OpportunityLineItems[0].PricebookEntry.Product2.MarketingLength__c);
                studentProductEntity.freeLength = String.valueOf(opp.OpportunityLineItems[0].PricebookEntry.Product2.FreeLength__c);
                studentProductEntity.productName = opp.OpportunityLineItems[0].PriceBookEntry.Product2.Name;
                studentProductEntity.productId = opp.OpportunityLineItems[0].PricebookEntry.Product2.Id;
                studentProductEntity.quantities = opp.OpportunityLineItems[0].Quantity;
                studentProductEntity.unitPrices = opp.OpportunityLineItems[0].UnitPrice;
            }
        }
    }

    private void buildData(TsCreateActualController.ChinaTSFinanceInfo financeInfo)
    {
        if(financeInfo.Record != null)
        {
            //Actual
            actualEntity.companyCode = financeInfo.CompanyCode;
            actualEntity.salesType = financeInfo.SalesType;
            actualEntity.numberOfInstallments = financeInfo.NoOfInstallments;
            actualEntity.opportunityId = financeInfo.Record.Id;
            actualEntity.closeDate = financeInfo.Record.CloseDate;
            actualEntity.accountId = financeInfo.Record.AccountId;
            actualEntity.opportunityOwnerId = financeInfo.Record.OwnerId;
            actualEntity.ownerId = financeInfo.Record.OwnerId;
        }
    }

    private String createData(String oppId, CreateDataConfig tsConfigInfo)
    {
        actualEntity.createActual(oppId);
        studentActualEntity.createStudentActual(actualEntity.actualId,actualEntity.accountId);
        if(tsConfigInfo.isRequiredToCreatePaymentData)
        {
        	paymentDataEntity.createPaymentData(actualEntity.actualId, studentActualEntity.studentActualId, actualEntity.salesType);
        }
        //paymentDataEntity.createPaymentData(actualEntity.actualId, studentActualEntity.studentActualId, actualEntity.salesType);
        /*if(actualEntity.salesType != 'Deposit'&&actualEntity.salesType != 'Promotion'&&actualEntity.salesType != 'Additional'&&actualEntity.salesType != 'Referral')
        {
            studentProductEntity.createStudentProduct(studentActualEntity.studentActualId);
        }*/
        if(tsConfigInfo.isRequiredToCreateStudentProduct)
        {
        	if(actualEntity.salesType != 'Deposit'&&actualEntity.salesType != 'Promotion'&&actualEntity.salesType != 'Additional'&&actualEntity.salesType != 'Referral')
        	{
        		studentProductEntity.createStudentProduct(studentActualEntity.studentActualId);
        	}  
        }
        return actualEntity.actualId;
    }

    // Inner classes for storing information.
    public class ActualEntity
    {
        private Map<String, String> salesTypedependenceMap = new Map<String, String>
        {
            'New' => 'Regular new student',
                'Deposit' => 'Only paid deposit money',
                'Course extension' =>'Course extension',
                'Service Upgrade' =>'Purchase online pl',
                'Downgrade' => 'Time length reduction within same product & School to Home'
        };

        // Some fields for actual.
        public String actualId;
        public String opportunityId;
        public String opportunityOwnerId; //
        public String ownerId;
        public String accountId;//from opportunity
        public String salesTypeDefinition;
        public String companyCode;
        public Date closeDate; //from opportunity
        public String paymentStatus;
        public Double finalPrice;
        public Double firstInstallmentAmount;
        public Double monthlyFeeAmount;
        public Integer numberOfInstallments; //default as 1
        public String salesType;
        public String salesApptLocation;
        public String opportunityNumber;
        public String paymentMethod;

        //create actual 
        public void createActual(String oppId)
        {       
            String chinaTSActualRecordTypeId =null;
            Schema.DescribeSObjectResult R = Actual__c.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
            for(Schema.Recordtypeinfo rtinfo:RT)
            {
                if(rtinfo.isDefaultRecordTypeMapping()==true)
                {
                    chinaTSActualRecordTypeId=rtinfo.getRecordTypeId();
                }
            }
            Actual__c actual = new Actual__c(Opportunity__c = oppId, Account__c = accountId, RecordTypeId = chinaTSActualRecordTypeId);
            actual.Final_Price__c = finalPrice;
            actual.MonthlyFee__c = monthlyFeeAmount;
            actual.FirstInstallmentAmount__c = firstInstallmentAmount;
            actual.Status__c = (numberOfInstallments == 1) ? 'Paid':'In Progress'; //default as In Progress if hasn’t paid full
            actual.Opportunity_owner__c = opportunityOwnerId;
            actual.China_Sales_Type__c = salesType;
            actual.Sales_Type_Definition__c = salesTypedependenceMap.get(actual.China_Sales_Type__c);
            actual.Company_code__c = companyCode;
            actual.Close_Date__c = closeDate;
            actual.Number_of_Installments__c = numberOfInstallments;
            actual.Sales_Appt_Locations_c__c = salesApptLocation;
            actual.Opportunity_number__c = opportunityNumber;
            actual.OwnerId = ownerId;
            actual.Payment_Type__c = paymentMethod;
            try
            {
                insert actual;
                actualId = actual.Id;
            }
            catch(Exception ex)
            {
                throw new CreateChinaTsFinanceDataException('Create actual failed. Error message:' + ex.getMessage());
            }
        }
    }

    //create student actual class
    public class StudentActualEntity
    {
        public String studentActualId;
        public Double finalPrice;
        // String accountId;//from opportunity
        public void createStudentActual(String actualId, String accountId)
        {
            List<Contact> students = [select Id, Name from Contact where AccountId =:accountId];
            if(students.size() > 0)
            {
                StudentActual__c newStudent = new StudentActual__c(Actual__c = actualId, Student__c = students[0].Id, Name = students[0].Name);
                try
                {
                    insert newStudent;
                    studentActualId = newStudent.Id;
                }
                catch(Exception ex)
                {
                    throw new CreateChinaTsFinanceDataException('Created Student Actual failed.');
                    delete new Actual__c(Id = actualId); // if a exception occur, we will delete the associated actual.
                }
            }
            else
            {
                throw new CreateChinaTsFinanceDataException('No associated contact for this opportunity.');
            }
        }
    }
    // create china payment data class
    public class PaymentDataEntity
    {
        // Some fields for payment data.
        public String bankName;
        public String accountHolder;
        public String paymentMethod; 	
        public String payType;
        public Date closeDate;//from opportunity
        public Double amount;
        public Double dueAmount;
        public Date collectedData;
        public String ownerId;
        public Date dueData;
        public Integer numberOfInstallments;
        public Double firstInstallmentAmount;
        public Double monthlyFeeAmount;

        public void createPaymentData(String actualId, String studentActualId, String salesType)
        {
            List<PaymentData__c> paymentDatas = new List<PaymentData__c>();
            if(numberOfInstallments == 1)
            {
                PaymentData__c paymentData = new PaymentData__c(Actual__c = actualId, StudentActual__c = studentActualId);
                // how to evaluate pay type. 
                paymentData.Payment_Method__c = paymentMethod;
                paymentData.BankName__c =bankName;
                paymentData.Card_Holder__c = accountHolder;
                paymentData.Amount__c = amount;
                paymentData.TransDatetime__c = collectedData;
                paymentData.Status__c = 'Paid';
                paymentData.Pay_Type__c = (salesType == 'Deposit') ? 'China TS Deposit': 'China TS Payment';
                paymentData.no_of_installments__c = String.valueOf(numberOfInstallments);
                paymentData.OwnerId = ownerId;
                paymentDatas.add(paymentData);
            }
            else if(numberOfInstallments > 1)
            {
                for(Integer i = 1; i <= numberOfInstallments; i++)
                {
                    PaymentData__c paymentData = new PaymentData__c(Actual__c = actualId, StudentActual__c = studentActualId);
                    if(i == 1)
                    {
                        paymentData.Amount__c = firstInstallmentAmount;
                        paymentData.TransDatetime__c = collectedData;
                        paymentData.AmountDue__c = firstInstallmentAmount;
                        paymentData.DueDate__c = collectedData;
                        paymentData.Payment_method__c = paymentMethod;
                        paymentData.Status__c = 'Paid';
                        paymentData.Pay_Type__c = payType; // Pay type is 'China TS Payment'.
                        paymentData.no_of_installments__c = String.valueOf(i);
                        paymentData.OwnerId = ownerId;
                    }
                    else
                    {
                        paymentData.AmountDue__c = monthlyFeeAmount;
                        paymentData.DueDate__c = Date.today().addMonths(i-1);
                        paymentData.Status__c = 'Due';
                        paymentData.Pay_Type__c = payType; // Pay type is 'China TS Payment'.
                        paymentData.Payment_method__c = paymentMethod;
                        paymentData.no_of_installments__c = String.valueOf(i);
                        paymentData.OwnerId = ownerId;
                    }
                    paymentDatas.add(paymentData);
                }
            }
            insert paymentDatas;
        }
    }

    public class StudentProductEntity
    {
        // Some fields for student product.
        public Double quantities;
        public Double unitPrices;
        public String productId;
        public String productName;
        public String standardLength;
        public String freeLength;
        public String marketingLength;

        public void createStudentProduct(String studentActualId)
        {
            if(productId == null)
            {
                throw new CreateChinaTsFinanceDataException('No product under this opportunity.');
            }
            StudentProduct__c newStudentProduct = new StudentProduct__c(StudentActual__c = studentActualId);
            newStudentProduct.Name = productName;
            newStudentProduct.Product__c = productId;
            newStudentProduct.StandardLength__c = standardLength; 
            newStudentProduct.MarketingLength__c = marketingLength;
            newStudentProduct.FreeLength__c = freeLength;
            newStudentProduct.Quantity__c = quantities;
            newStudentProduct.Price__c = unitPrices;
            insert newStudentProduct;
        }
    }
    
    public class CreateDataConfig
    {
    	public Boolean isRequiredToCreateActual;
    	public Boolean isRequiredToCreateStudentActual;
    	public Boolean isRequiredToCreateStudentProduct;
    	public Boolean isRequiredToCreatePaymentData;
    	
    	public CreateDataConfig()
    	{
    	    isRequiredToCreateActual = true;
    	    isRequiredToCreateStudentActual = true;
    	    isRequiredToCreateStudentProduct = true;
    	    isRequiredToCreatePaymentData = true;
    	}
    }

    public class CreateChinaTsFinanceDataException extends Exception {}

    @isTest
    static void testChinaTSFinanceDataUtility()
    {
    	Account acc = new Account(Name='acme');
    	insert acc;
    	Contact contact = new Contact(LastName = 'acme', AccountId = acc.Id);
    	insert contact;
        ChinaTSFinanceDataUtility chinaTsFinanceData = new ChinaTSFinanceDataUtility();
        Opportunity opp = new Opportunity(Name = 'acme', StageName = 'set App', CloseDate = System.today(), AccountId = acc.Id);
        insert opp;
        TsCreateActualController.ChinaTSFinanceInfo financeInfo = new TsCreateActualController.ChinaTSFinanceInfo(opp);
        Product2 testProduct = new Product2(Name = 'test product acme', IsActive = true, NumberOfInstallments__c = 6, FirstInstallmentAmount__c = 432, MonthlyFee__c = 223);
        insert testProduct;
        String standardPriceBookId = [select Id from Pricebook2 where IsStandard = true limit 1].Id;
        PricebookEntry standardPricebookEntry = new PricebookEntry(IsActive = true, Pricebook2Id = standardPriceBookId, Product2Id = testProduct.Id, UnitPrice = 8888);
        insert standardPricebookEntry;
        Pricebook2 testPricebook = new Pricebook2(IsActive = true, Name = 'test price book acme');
        insert testPricebook;
        PricebookEntry testPricebookEntry = new PricebookEntry(IsActive = true, Pricebook2Id = testPricebook.Id, Product2Id = testProduct.Id, UnitPrice = 8888);
        insert testPricebookEntry; 
        OpportunityLineItem testOpportunityLineItem = new OpportunityLineItem(OpportunityId = opp.Id, PriceBookEntryId = testPricebookEntry.Id, Quantity = 1, TotalPrice = 8888);
        insert testOpportunityLineItem;
        update opp;
        opp = [select Id, Name, AccountId, RecordType.Name, Location__c, Email__c, Company_Type__c, StageName, Product__c, China_Sales_Type__c, OwnerId, Owner.Username, Opportunity_Number__c, Mobile__c, Phone2__c, CloseDate, Amount, Payment_Type__c, Number_of_Installments__c, (Select Id, OpportunityId, PriceBookEntryId, Quantity, TotalPrice, UnitPrice, PricebookEntry.Product2.Name, PricebookEntry.Product2.FirstInstallmentAmount__c, PricebookEntry.Product2.Months__c, PricebookEntry.Product2.MonthlyFee__c, PricebookEntry.Product2.MarketingLength__c, PricebookEntry.Product2.CourseLength__c, PricebookEntry.Product2.FreeLength__c, PricebookEntry.Product2.NumberOfInstallments__c from OpportunityLineItems) from Opportunity where Id = :opp.Id];
        chinaTsFinanceData.generateFinanceData(opp, Date.today(), 8888);
        financeInfo.AccountHolder = 'acme';
        financeInfo.Record = opp;
        //financeInfo.Record.Id = opp.Id;
        financeInfo.Amount = 5678;
        financeInfo.BankName = '中国人民银行PBC(People\'s Bank of China)';
        financeInfo.CloseWon = 'No';
        financeInfo.CompanyCode ='CN220';
        financeInfo.NoOfInstallments = 1;
        financeInfo.PaymentMethod = '99Bill';
        financeInfo.SalesType = 'Deposit';
        chinaTsFinanceData.generateFinanceData(financeInfo); 
    }
}