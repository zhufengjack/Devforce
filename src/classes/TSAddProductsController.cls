/*
 *Controller of page Ts Add Products.
 */ 
public class TSAddProductsController
{  
    public Decimal Price {get; set;}
    public String StandardLength {get; set;}
    public String MarketingLength{get;set;}
    public String FreeLength{get;set;}
    public String productId {get; set;}
    public String note {get; set;}
    public Integer Quantity {get{return (productQuantity == null)? 0: productQuantity.intValue();}}
    //private String actualId;
    private Decimal productQuantity;
    private List<String> studentIdList = new List<String>();
    private Map<String, String> productId2Name = new Map<String, String>();

    public TsAddProductsController()  
    { 
        //actualId = Apexpages.currentPage().getParameters().get('Id');
        String studentIds = ApexPages.currentPage().getParameters().get('studentActualIds');//get this Id from parent window
        productQuantity = 1;
        generateStudentIdList(studentIds);
    } 

    public List<ProductInfo> getAllProducts()
    {
        String Pricebookname = null;
        String Productfamily = null;
        Schema.DescribeSObjectResult R = Actual__c.SObjectType.getDescribe();
        List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
        for(Schema.Recordtypeinfo rtinfo:RT)
        {
            if(rtinfo.isDefaultRecordTypeMapping()==true)
            {
                if(rtinfo.getName().contains('tele'))
                {
                    Pricebookname='China Telesales Pricebook';
                    Productfamily='tele-sales';
                }
                else if(rtinfo.getName().contains('Mini'))
                {
                    Pricebookname='China Mini Pricebook';
                    Productfamily='tele-sales';
                }else{
                    Pricebookname='China Telesales Pricebook';
                    Productfamily='tele-sales';
                }
            }
        }

        List<ProductInfo> productInfos = new List<ProductInfo>();
        List<Product2> products = [Select Id, Name, Months__c, CourseLength__c, MarketingLength__c, FreeLength__c, Family, IsLevel__c, (Select UnitPrice, IsActive From PricebookEntries where Pricebook2.Name=:Pricebookname limit 1) From Product2 where IsActive=true and Family =:Productfamily order by Name];
        for(Product2 product : products)
        {
            Decimal price = 0;
            for(PricebookEntry entry : product.PricebookEntries)
            {
                if(entry.IsActive == true && entry.UnitPrice != null)
                {
                    price = entry.UnitPrice;
                }
            }
            productInfos.add(new ProductInfo(product.Id, product.Name, price, product.CourseLength__c, product.MarketingLength__c, product.FreeLength__c));
            productId2Name.put(product.Id, product.Name);
        }
        return productInfos;
    }

    // store student Ids into a list.  
    private void generateStudentIdList(String studentIds)
    {
        if(studentIds != null)
        {
            for(String  studentActualId: studentIds.split(':'))
            {   
                if(studentActualId != null && studentActualId != '')
                {
                    studentIdList.add(studentActualId);
                }
            }
        }
    }

    public List<SelectOption> getNewProductItems()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0', ' '));
        for(Product2 product : [Select Id, Name From Product2 where IsActive=true and Family='Tele-sales' order by Name])
        {
            result.add(new SelectOption(product.Id, product.Name));
        }
        return result; 
    }  

    public void save()     
    {
        try
        {
            if(studentIdList.size() > 0)
            { 
                List<StudentActual__c> studentActuals = [select Id, Name, (select Id from StudentProducts__r  limit 1) from StudentActual__c where Id in :studentIdList];
                for(StudentActual__c studentActual : studentActuals)
                {
                    if(studentActual.StudentProducts__r.size() > 0)
                    {
                        throw new AddNewProductException('Only one product can be added for each student!');
                    }
                }
                if(productId == null || productId == '' || productId == '0')
                {
                    throw new AddNewProductException('No products selected.');
                }
                List<StudentProduct__c> studentProducts = new List<StudentProduct__c>();
                for(StudentActual__c studentActual : studentActuals)
                {
                    StudentProduct__c studentProduct = new StudentProduct__c();
                    studentProduct.StudentActual__c = studentActual.Id;
                    studentProduct.Name = productId2Name.get(productId);
                    studentProduct.Product__c = productId;
                    studentProduct.StandardLength__c = StandardLength;
                    studentProduct.MarketingLength__c=MarketingLength;
                    studentProduct.FreeLength__c=FreeLength;
                    studentProduct.Price__c = price;
                    studentProduct.Quantity__c = productQuantity;
                    studentProduct.FinanceNotes__c = note;
                    studentProducts.add(studentProduct);
                }
                insert studentProducts;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Add successful!<script type="text/javascript">refreshOpenerWindow();</script>')); 
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
    } 

    public class ProductInfo
    {
        public String Id { get; set; }
        public String Name { get; set; }
        public Decimal Price { get; set; }
        public String StandardLength { get; set; }
        public String MarketingLength { get; set; }
        public String FreeLength { get; set; }

        public ProductInfo(String productId, String productName, Decimal productPrice, Decimal standardLength, Decimal marketingLength, Decimal freeLength)
        {
            this.Id = productId;
            this.Name = productName;
            this.price = productPrice;
            this.StandardLength = (standardLength == null)? '0': String.valueOf(standardLength.intValue());
            this.MarketingLength = (marketingLength == null)? '0': String.valueOf(marketingLength.intValue());
            this.FreeLength = (freeLength == null)? '0': String.valueOf(freeLength.intValue());
        }
    }

    public class AddNewProductException extends Exception{}

    @isTest
    static void testTsAddProductsController()
    {
        Account testAccount = new Account(Name = 'test account', First_Name__c = 'First Name', Last_Name__c = 'Last Name', phone = '3214567890', Mobile__c = '1234567890');
        insert testAccount;
        Contact testContact = new Contact(AccountId = testAccount.Id, Lastname = 'last name', EtownMemberId__c = 999999);
        insert testContact;
        String chinaTsRecordTypeId = [select Id from RecordType where Name = 'China Telesales Record Type' and sobjectType = 'Opportunity' limit 1].Id;
        Opportunity testOpportunity = new Opportunity(Name = 'test opp', Phone2__c = '3214567890', China_Sales_Type__c = 'New', Email__c = 'test@ef.email.com', Payment_Schedule__c = 'Installments',Payment_Type__c = 'Unipay', AccountId = testAccount.Id, Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = chinaTsRecordTypeId);
        insert testOpportunity;
        String chinaTsActualRecordTypeId = [select Id from RecordType where Name = 'China TS Actual Record Type' and sobjectType = 'Actual__c' limit 1].Id;
        Product2 testProduct = new Product2(Name = 'test product acme', IsActive = true, Family = 'Smart new product list', OfferId__c = 'ERYEUW6635', RedemptionCode__c = 'EERER384783', IsLevel__c = true, NumberOfInstallments__c = 6);
        insert testProduct;
        Actual__c testActual = new Actual__c(RecordTypeId = chinaTsActualRecordTypeId, Account__c = testAccount.Id, Opportunity__c = testOpportunity.Id);
        insert testActual;
        StudentActual__c testStudentActual = new StudentActual__c(Actual__c = testActual.Id, Student__c = testContact.Id);
        insert testStudentActual;
        PageReference testPage = new PageReference('/apex/TSAddProducts?studentActualIds=' + testStudentActual.Id);
        test.setCurrentPage(testPage);
        TSAddProductsController controller = new TSAddProductsController();
        controller.getAllProducts();
        controller.getNewProductItems();
        controller.productId = testProduct.Id;
        controller.save();
    }
}