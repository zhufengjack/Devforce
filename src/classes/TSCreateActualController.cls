/*
 * Controller of page Ts Create Actual
 * depend on ChinaTSFinanceDataUtility class
 * only works for china Ts payment and China Ts deposit
 */
public class TSCreateActualController
{
    public ChinaTSFinanceInfo FinanceInfo {get; set;}
    private String currentUserRoleName;
    
    public TsCreateActualController(ApexPages.StandardController controller) 
    {
        try
        {   
        	currentUserRoleName = [select Id, Name from UserRole where Id = :UserInfo.getUserRoleId()].Name; 
            List<Opportunity> opps = [select Id, Name, Mobile__c, Phone2__c, Email__c, AccountId, Amount, OwnerId, (select Quantity, UnitPrice, PriceBookEntry.Product2Id, PriceBookEntry.Product2.Name, PriceBookEntry.Product2.Months__c from OpportunityLineItems), (select Id from Actuals__r limit 1), CloseDate, RecordTypeId from Opportunity where Id=:controller.getId() limit 1];
            if(opps.size() > 0)
            {
                FinanceInfo = new ChinaTSFinanceInfo(opps[0]);
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
        }
    }
    
    public PageReference save()
    {
        String newActualId;
        try
        {
            Opportunity updateOpportunity = new Opportunity(Id = FinanceInfo.Record.Id, CloseDate = FinanceInfo.record.CloseDate);
            if(FinanceInfo.CloseWon == 'No')
            {
                FinanceInfo.SalesType = 'Deposit';
            }
            else
            {
                updateOpportunity.StageName = 'Closed Won';
            } 
            checkPaymentStatus(FinanceInfo.Record.Actuals__r, FinanceInfo.SalesType);
            ChinaTSUtility.checkAndCreateNewContact(FinanceInfo.record, '');
            Savepoint sp=Database.setSavepoint();
            ChinaTSFinanceDataUtility financeDataUtility = new ChinaTSFinanceDataUtility();
            newActualId = financeDataUtility.generateFinanceData(FinanceInfo); 
            update updateOpportunity;
            return new PageReference('/' + newActualId);
        }
        catch(Exception ex)
        {   
            if(newActualId != null)
            {
                delete new Actual__c(Id = newActualId);
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, ex.getMessage()));
            return null;
        }
    }
    
    private void checkPaymentStatus(List<Actual__c> actualList, String SalesType)
    {
        if(actualList != null && actualList.size() > 0 &&(SalesType!='Additional'&&SalesType!='Promotion'&&SalesType!='Referral'))
        {
            throw new CreateActualException('Note that: You have create actual for this opportunity. You can\'t do this again.');
        }
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + FinanceInfo.Record.Id);
    }
    
    public List<SelectOption> getCompanyCodeList()
    {
        List<FinanceCompanyCode__c> companyCodeList = [select Id, Name, CompanyCode__c, UserRole__c from FinanceCompanyCode__c where UserRole__c = :currentUserRoleName order by CompanyCode__c];
        List<SelectOption> options = new List<SelectOption>();
        for(FinanceCompanyCode__c financeCompanyCode : companyCodeList)
        {
            options.add(new SelectOption(financeCompanyCode.CompanyCode__c, financeCompanyCode.CompanyCode__c));
        }
        return options;
    }
    
    public List<SelectOption> getSalesTypes()
    {
        List<Actual__c> actuals = [select Id from Actual__c where Opportunity__c=:FinanceInfo.record.Id limit 1];
        List<SelectOption> options = new List<SelectOption>();
        if(actuals.size() >0)
        {
            
            options.add(new SelectOption('Additional', 'Additional'));
            options.add(new SelectOption('Promotion', 'Promotion'));
            options.add(new SelectOption('Referral', 'Referral'));
        }
        else
        {
            options.add(new SelectOption('New', 'New'));
            options.add(new SelectOption('Renew', 'Renew'));
            options.add(new SelectOption('Deposit', 'Deposit'));
            options.add(new SelectOption('Course Extention', 'Course Extention'));
            options.add(new SelectOption('Service Upgrade', 'Service Upgrade'));
            options.add(new SelectOption('Downgrade', 'Downgrade'));
            options.add(new SelectOption('Double Pay', 'Double Pay'));
        }
        return options;
    }
    
    public class ChinaTSFinanceInfo
    {
        public Integer NoOfInstallments = 1;
        public String CloseWon { get; set; }
        public String SalesType { get; set; }
        public String CompanyCode { get; set; }
        public String PaymentMethod { get; set; }
        public String BankName { get; set; }
        public Double Amount { get; set; }
        public String AccountHolder { get; set; }
        public Opportunity record { get; set; }
        
        public ChinaTSFinanceInfo(Opportunity opp)
        {
            record = opp;
            Amount = opp.Amount;
            CloseWon = 'Yes';
        }
    }
    
    public class CreateActualException extends Exception {}
    
    @isTest
    static void testTsCreateActualController()
    {
        ChinaTSFinanceDataUtility chinaTsFinanceData = new ChinaTSFinanceDataUtility();
        Opportunity opp = new Opportunity(Name = 'acme', StageName = 'set App', CloseDate = System.today(), China_Sales_Type__c = 'New');
        insert opp;
        Product2 testProduct = new Product2(Name = 'test product acme', IsActive = true);
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
        TsCreateActualController.ChinaTSFinanceInfo financeInfo = new TsCreateActualController.ChinaTSFinanceInfo(opp);
        financeInfo.AccountHolder = 'acme';
        financeInfo.Amount = 5678;
        financeInfo.BankName = '中国人民银行PBC(People\'s Bank of China)';
        financeInfo.CloseWon = 'No';
        financeInfo.CompanyCode ='CN220';
        financeInfo.NoOfInstallments = 1;
        financeInfo.PaymentMethod = '99Bill';
        financeInfo.SalesType = 'Deposit';
        ApexPages.StandardController standardController =  new ApexPages.StandardController(opp);
        TsCreateActualController controller = new TsCreateActualController(standardController);
        controller.save();
        controller.cancel();
        controller.getSalesTypes();
        Opportunity opp2 = new Opportunity(Name = 'acme', StageName = 'set App', CloseDate = System.today(), China_Sales_Type__c = 'New');
        insert opp2;
        ApexPages.StandardController standardController2 =  new ApexPages.StandardController(opp2);
        TsCreateActualController controller2 = new TsCreateActualController(standardController2);
        controller2.getSalesTypes();
        controller2.getCompanyCodeList();
        try
        {
            controller.checkPaymentStatus(New List<Actual__c>{new Actual__c()}, 'Deposit');
        }
        catch(Exception ex){}
    }
}