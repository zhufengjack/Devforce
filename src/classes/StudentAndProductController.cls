/*
*    This controller for StudentAndProduct page.
*/
public class StudentAndProductController 
{
	public Boolean AllSelected { get { return false; } set; }
	
	private String actualId;
	private List<StudentInfo> allStudents;
	private StudentInfo highLightedStudent;
	
	public StudentAndProductController()
	{
	    actualId = ApexPages.currentPage().getParameters().get('id');
	    List<Actual__c> actuals = [select Id, China_Sales_Type__c from Actual__c where Id = :actualId limit 1];
	    if(actuals.size() == 0)
	    {
	        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No actual selected'));
	    }
	}
	
	public List<StudentInfo> getAllStudents()
	{
        if(allStudents == null)
        {
            allStudents = new List<StudentInfo>();
            List<StudentActual__c> actuals = [Select Id, Name, Student__c, Student__r.Name, EliteCard__c, StartingLevel__c, EntryCenter__c, (Select Id, Product__c, Product__r.Name, Product__r.Family, LevelsPurchased__c, Freelevels__c, ProductLength__c, FreeLength__c, MarketingLength__c, Price__c, Quantity__c, BookingCenters__c From StudentProducts__r order by Product__r.Family) From StudentActual__c where Actual__c=:actualId];
            for(StudentActual__c actual : actuals)
            {
                StudentInfo student = new StudentInfo(actual.Id, actual.Student__r.Name);
                student.EliteCard = actual.EliteCard__c;
                student.StartingLevel = actual.StartingLevel__c;
                student.EntryCenter = actual.EntryCenter__c;
                for(StudentProduct__c prod : actual.StudentProducts__r)
                {
                    Integer qty = (prod.Quantity__c != null)?prod.Quantity__c.intValue():0;
                    ProductInfo newProductInfo = new ProductInfo(prod.Product__c, prod.Id, prod.Product__r.Name, prod.Product__r.Family, prod.Price__c, qty);
                    newProductInfo.LevelsPurchased = (prod.LevelsPurchased__c == null) ? null : Integer.valueOf(prod.LevelsPurchased__c);
                    newProductInfo.FreeLength = (prod.FreeLength__c == null) ? null : Integer.valueOf(prod.FreeLength__c);
                    newProductInfo.ProductLength = (prod.ProductLength__c == null) ? null : prod.ProductLength__c.intValue();
                    newProductInfo.MarketingLength = (prod.MarketingLength__c == null) ? null : Integer.valueOf(prod.MarketingLength__c);
                    newProductInfo.FreeLevel = (prod.Freelevels__c == null) ? '' : prod.Freelevels__c;
                    newProductInfo.BookingCenter = (prod.BookingCenters__c == null) ? '' : prod.BookingCenters__c;
                    student.addProduct(newProductInfo);
                }
                allStudents.add(student);
            }
            if(allStudents.size() == 1)
            {
                allStudents[0].Selected = true;
            }
        }
        return allStudents;
	}
	
    public StudentInfo getHighLightedStudent()
    {
        if(highLightedStudent == null && getAllStudents().size() > 0)
        {
            highLightedStudent = getAllStudents()[0];
        }
        return highLightedStudent;
    }
    
    public PageReference highlightStudent()
    {
        String studentId = ApexPages.currentPage().getParameters().get('sid');
        for(StudentInfo student : getAllstudents())
        {
            if(student.Id == studentId)
            {
                highLightedStudent = student;
                break;
            }
        }
        return null;
    }
    
    //redirects back to the actual page
    public PageReference cancel()
    {
        if(actualId == null)
        {
            return new PageReference('/a00/o');
        }
        return new PageReference('/' + actualId);
    }
	
	public class StudentInfo
	{
		public StudentInfo(String id, String name)
        {
            this.Id = id;
            this.Name = name;
            products = new List<ProductInfo>();
        }
		
	    public Boolean Selected { get; set; }
        public String Id { get; set; }
        public String Name { get; set; }
        public String EliteCard { get; set; }
        public String StartingLevel { get; set; }
        public String EntryCenter { get; set; }
        public Integer ProductsCount {get { return products.size(); }}
        public List<ProductInfo> products { get; set; }
        public Decimal TotalAmount
        {
            get
            {
                Decimal result = 0;
                for(ProductInfo prod : products)
                {
                    result += prod.Amount;
                }
                return result;
            }
        }
        
        public void addProduct(ProductInfo product)
        {
            products.add(product);
            product.Student = this;
        }
	}

    public class ProductInfo
    {
        public ProductInfo()
        {
            this.Id = '0';
        }
        
        public ProductInfo(String id, String name, String family, Decimal price, Boolean isLevel)
        {
            this.Id = id;
            this.Name = name;
            this.Price = price;
            this.Family = family;
            this.Quantity = 0;
            this.IsLevel = isLevel;
        }
        
        public ProductInfo(String id, String spid, String name, String family, Decimal price, Integer qty)
        {
            this.Id = id;
            this.Name = name;
            this.StudentProductId = spid;
            this.Price = price;
            this.Family = family;
            this.Quantity = qty;
        }
        
        public String Id { get; set; }
        public String Name { get; set; }
        public Boolean IsLevel { get; set; }
        public Decimal Price { get; set; }
        public Integer LevelsPurchased { get; set; }
        public Integer StandardLength { get; set; }
        public Integer ProductLength {get; set;}
        public Integer FreeLength { get; set; }
        public Integer MarketingLength { get; set; }
        public String Family { get; set; }
        public Integer Quantity { get; set; }
        public String Notes { get; set; }
        public Decimal Amount 
        { 
            get 
            { 
				if(Name == 'Cross Center Booking')
				{
				    if(Price == null)
				    {
				        return 0;
				    }
				    else
				    {
				        return Price;
				    }
				}
				if(Price == null || Quantity == null)
				{
				    return 0;
				}
				return Price * Quantity; 
            } 
        }
        public String StudentProductId { get; set; }
        public StudentInfo Student { get; set; }
        public String FreeLevel { get; set;}
        public String BookingCenter { get; set; }
       
        public PageReference remove()
        {
            if(StudentProductId != null && StudentProductId != '')
            {
                StudentProduct__c prod = new StudentProduct__c(Id=StudentProductId );
                try
                {
                    delete prod;
                    for(Integer i = 0; i < Student.Products.size(); i++)
                    {
                        if(Student.Products.get(i) == this)
                        {
                            Student.Products.remove(i);
                        }
                    }
                }
                catch(Exception ex)
                {
                    ApexPages.addMessages(ex);
                }
            }
            return null;
        }
    }
    
    @isTest
    static void testStudentAndProductController()
    {
        Id b2bCompanyRecordTypeId = [select Id from RecordType where Name  = 'China Smart B2B record type' and SobjectType = 'Account'].Id;
        Account company = new Account(Name = 'Virtual Company', RecordTypeId = b2bCompanyRecordTypeId);
        insert company;
        Contact student = new Contact(LastName = 'student1', AccountId = company.Id);
        Contact student2= new Contact(LastName = 'student2', AccountId = company.Id);
        insert new Contact[]{student, student2};
        Actual__c actual = new Actual__c(Account__c = company.Id);
        insert actual;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, Student__c = student.Id, EliteCard__c = 'test1234');
        StudentActual__c studentActual2 = new StudentActual__c(Actual__c = actual.Id, Student__c = student2.Id, EliteCard__c = 'test1235');
        insert new StudentActual__c[]{studentActual, studentActual2};
        StudentProduct__c sProduct = new StudentProduct__c(Name = 'test product', StudentActual__c = studentActual2.Id); 
        insert sProduct;     

        PageReference page = new PageReference('/apex/StudentAndProduct?id=' + actual.Id);
        Test.setCurrentPage(page);
        StudentAndProductController controller = new StudentAndProductController();
        List<StudentInfo> students = controller.getAllStudents();
        System.assert(students.size() > 0);
        Decimal amount = students[0].TotalAmount;
        controller.getHighLightedStudent();
        controller.highlightStudent();
        controller.cancel();
        StudentAndProductController.ProductInfo pInfo = new StudentAndProductController.ProductInfo();
        StudentAndProductController.ProductInfo pInfo2 = new StudentAndProductController.ProductInfo('000P000xsdheMa', 'ProductName', 'Product Family', 3333, true);
        StudentAndProductController.ProductInfo pInfo3 = new StudentAndProductController.ProductInfo('000P000987cide', sProduct.Id, 'ProductName', 'Product Family', 3333, 1);
        pInfo3.remove();
    }
}