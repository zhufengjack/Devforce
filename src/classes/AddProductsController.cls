/*
 * Controller for page AddProducts
 */
public with sharing class AddProductsController 
{
    private String actualId;
    private List<StudentInfo> allStudents;
    private StudentInfo highLightedStudent;
    private List<ProductInfo> studentProducts;
    private ProductInfo standardProd;
    private ProductInfo newProd;
    private List<ProductInfo> allProducts;
    
    public AddProductsController()
    {
        actualId = ApexPages.currentPage().getParameters().get('id');
        StandardProduct = new ProductInfo();
        StandardProduct.Quantity = 1;
        StandardProduct.Family = 'Smart Product List';
        NewProduct = new ProductInfo();
        NewProduct.Quantity = 1;
        NewProduct.Family = 'Smart new product list';
        CCBookingProduct = new ProductInfo();
        studentProductInfo = new StudentProduct__c();
        
        List<Actual__c> actuals = [select Id, China_Sales_Type__c from Actual__c where Id = :actualId limit 1];
        if(actuals.size() > 0)
        {
            String salesType = (actuals[0].China_Sales_Type__c != null) ? actuals[0].China_Sales_Type__c : '';
            if(salesType.startsWith('Upgrade') || salesType == 'Downgrade' || salesType == 'Renewal')
            {
                IsUpgrade = true;
            }
            else
            {
                IsUpgrade = false;
            }
            if(salesType == 'Additional' || salesType == 'Promotion' || salesType == 'Referral' || salesType == 'Service Recovery')
            {
                IsAdditional = true;
            }
            //IsAdditional = (salesType == 'Additional');
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No actual selected'));
        }
    }
    
    public Boolean IsUpgrade { get; set; }
    public Boolean AllSelected { get { return false; } set; }
    public Boolean IsAdditional { get; set; }
    public ProductInfo StandardProduct { get { return standardProd; } set {standardProd = value; } }
    public ProductInfo NewProduct { get { return newProd; } set {newProd = value; } }
    public ProductInfo CCBookingProduct { get; set; }
    public StudentProduct__c studentProductInfo { get; set; }

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

    //gets the students which have the checkbox checked
    public List<StudentInfo> getSelectedStudents()
    {
        List<StudentInfo> result = new List<StudentInfo>();
        for(StudentInfo student : allStudents)
        {
            if(student.Selected == true)
            {
                result.add(student);
            }
        }
        return result;
    }
    
    //gets the student which is currently clicked and will be showed up in the right side
    public StudentInfo getHighlightedStudent()
    {
        if(highLightedStudent == null && getAllStudents().size() > 0)
        {
            highLightedStudent = getAllStudents()[0];
        }
        return highLightedStudent;
    }
    
    //after user click a student in the left side, it will be showed up in the right
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

    //gets the default product list in the popup form. returns a list of 5 products
    public List<ProductInfo> getStudentProducts()
    {
        if(studentProducts == null)
        {
            studentProducts = new List<ProductInfo>();
            for(Integer i = 0; i < 5; i++)
            {
                ProductInfo info = new ProductInfo();
                info.Quantity = 1;
                studentProducts.add(info);
            }
        }
        return studentProducts;
    }
    
    public List<SelectOption> getAllProductItems()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0', ' '));
        for(ProductInfo prd : getAllProducts())
        {
            result.add(new SelectOption(prd.Id, prd.Name));
        }
        return result;        
    }
    
    public List<SelectOption> getNewProductItems()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0', ' '));
        for(Product2 prd : [Select Id, Name From Product2 where IsActive=true and Family='Smart new product list' order by Name])
        {
            result.add(new SelectOption(prd.Id, prd.Name));
        }
        return result; 
    }
    
    public List<SelectOption> getStandardProductItems()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0', ' '));
        for(Product2 prd : [Select Id, Name From Product2 where IsActive=true and Family='Smart Product List' order by Name])
        {
            result.add(new SelectOption(prd.Id, prd.Name));
        }
        return result; 
    }
    
    public List<SelectOption> getNonStandardProductItems()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0', ' '));
        for(Product2 prd : [Select Id, Name From Product2 where IsActive=true and Family='Smart Non-Standard Product List' order by Name])
        {
            if(prd.Name != 'Cross Center Booking')
            {
                result.add(new SelectOption(prd.Id, prd.Name));
            }
            else if(prd.Name == 'Cross Center Booking')
            {
                CCBookingProduct.Id = prd.Id;
            }
        }
        return result;  
    }
    
    //gets all the products in the database, whose family is 'Smart Product List', 'Smart Non-Standard Product List' or 'Smart new product list'
    public List<ProductInfo> getAllProducts()
    {
        if(allProducts == null)
        {
            allProducts = new List<ProductInfo>();
            List<Product2> products = [Select Id, Name, Family, EtownId__c, IsLevel__c, (Select UnitPrice, IsActive From PricebookEntries where Pricebook2.Name='CN Smart Price Book' limit 1) From Product2 where IsActive=true and Family in ('Smart Product List', 'Smart Non-Standard Product List', 'Smart new product list') order by Name];
            for(Product2 prd : products)
            {
                Decimal price = 0;
                for(PricebookEntry entry : prd.PricebookEntries)
                {
                    if(entry.IsActive == true && entry.UnitPrice != null)
                    {
                        price = entry.UnitPrice;
                    }
                }
                allProducts.add(new ProductInfo(prd.Id, prd.Name, prd.Family, price, prd.IsLevel__c));
            }
        }
        return allProducts;
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
    
    //saves the products selected in the popup form.
    public PageReference save()
    {
        Set<Id> needToUpdateEliteCardStudentActualIds = new Set<Id>();
        List<StudentInfo> sStudents = getSelectedStudents();
        List<StudentProduct__c> result = new List<StudentProduct__c>();
        List<ProductInfo> productsToBeAdded = new List<ProductInfo>();
        
        //checks bookingcenters filed, if it has a vaule, the Cross Center booking product will be added in studentProducts list
        if(studentProductInfo.BookingCenters__c != null && studentProductInfo.BookingCenters__c != '') 
        {  
            //prevent more than one new products added to a student
            if(hasUniqueProductsFound(sStudents, CCBookingProduct.Id))
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to add products. Each student can just have one Corss Center Booking product, please check your selection.'));
                 return null;
            } 
            else
            {
                CCBookingProduct.BookingCenter = mergeSchoolName(studentProductInfo.BookingCenters__c);
                studentProducts.add(CCBookingProduct);
            }
        }
        
        for(ProductInfo prod : studentProducts)
        {
            if(prod.Id != '0')
            {
                productsToBeAdded.add(prod);
            }
        }
       
        //prevent more than one new products added to a student
        if(NewProduct.Id != '0' && hasNewProductsFound(sStudents))
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to add products. Each student can just have one new product, please check your selection.'));
            return null;
        }
        for(StudentInfo student : sStudents)
        {
            if(StandardProduct.Id != '0')
            {
                result.add(new StudentProduct__c(Name=getProductName(StandardProduct.Id), StudentActual__c=student.Id, Product__c=StandardProduct.Id, Price__c=StandardProduct.Price));
            }
            if(NewProduct.Id != '0')
            {
                needToUpdateEliteCardStudentActualIds.add(student.Id);
                String prodName = getProductName(NewProduct.Id);
                if(isLevelProduct(NewProduct.Id))
                {
                    result.add(new StudentProduct__c(Name=prodName, StudentActual__c=student.Id, Product__c=NewProduct.Id, Price__c=NewProduct.Price, FreeLength__c=String.valueOf(NewProduct.FreeLength), MarketingLength__c=String.valueOf(NewProduct.MarketingLength), LevelsPurchased__c=String.valueOf(NewProduct.LevelsPurchased), FinanceNotes__c=NewProduct.Notes,  Freelevels__c = NewProduct.FreeLevel));
                }
                else
                {
                    // For product "NewProduct.StandardLength".
                    // If sales type of actual is "Additional" "Promotion" "Referral"(IsAdditional is true), standard length of product will be NULL.
                    if(prodName == 'Englishtown Lite' && IsAdditional != true)
                    {
                        NewProduct.StandardLength = 6;
                    }
                    result.add(new StudentProduct__c(Name=prodName, StudentActual__c=student.Id, Product__c=NewProduct.Id, Price__c=NewProduct.Price, FreeLength__c=String.valueOf(NewProduct.FreeLength), StandardLength__c=String.valueOf(NewProduct.StandardLength), MarketingLength__c=String.valueOf(NewProduct.MarketingLength), FinanceNotes__c=NewProduct.Notes));
                }
            }
            //non-standard products
            for(ProductInfo prod : productsToBeAdded)
            {
                result.add(new StudentProduct__c(Name=getProductName(prod.Id), StudentActual__c=student.Id, Product__c=prod.Id, Price__c=prod.Price, Quantity__c=prod.Quantity, FinanceNotes__c=prod.Notes, BookingCenters__c=prod.BookingCenter));
            } 
        }
        try
        {
            EliteCardHelper.generateEliteCardNumber(needToUpdateEliteCardStudentActualIds);
            if(sStudents.size() == 1 && SelectOneStudentActual == true && StudentProductSelectId != null)
            {
                update new StudentActual__c(Id = sStudents[0].Id, SourceProductName__c = StudentProductSelectId);
            }
            insert result;
            allStudents = null;    //force page refresh
            studentProducts = null;
            StandardProduct = new ProductInfo();
            StandardProduct.Quantity = 1;
            StandardProduct.Family = 'Smart Product List';
            NewProduct = new ProductInfo();
            NewProduct.Quantity = 1;
            NewProduct.Family = 'Smart new product list';
            CCBookingProduct = new ProductInfo();
            studentProductInfo = new StudentProduct__c();
            //highlight the student which has just added product
            for(StudentInfo student : getAllstudents())
            {
                if(student.Id == student.Id)
                {
                    highLightedStudent = student;
                    break;
                }
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Products Added'));
        }
        catch(Exception ex)
        {
            studentProducts = null;
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    //checks if the specified student actual already have new products added, returns true if found, otherwise false.
    //this is to ensure only one new product can be added to each student actual
    private Boolean hasNewProductsFound(List<StudentInfo> students)
    {
        Set<Id> studentActualIds = new Set<Id>();
        for(StudentInfo student : students)
        {
            studentActualIds.add(student.Id);
        }
        for(StudentActual__c studentActual : [select Id, Name, (select Id from StudentProducts__r where Product__r.EtownId__c != null limit 1) from StudentActual__c where Id in :studentActualIds])
        {
            if(studentActual.StudentProducts__r.size() > 0)
            {
                return true;
            }
        }
        return false;
    }
    
    //checks if the specified student actual already have unique product added, returns true , otherwise false.
    private Boolean hasUniqueProductsFound(List<StudentInfo> students, String productId)
    {
        Set<Id> studentActualIds = new Set<Id>();
        for(StudentInfo student : students)
        {
            studentActualIds.add(student.Id);
        }
        for(StudentActual__c studentActual : [select Id, Name, (select Id from StudentProducts__r where Product__r.Id = :productId and Product__r.IsUnique__c = true) from StudentActual__c where Id in :studentActualIds])
        {
            if(studentActual.StudentProducts__r.size() > 0)
            {
                return true;
            }
        }
        return false;
    }
    
    private String getProductName(String productId)
    {
        for(ProductInfo prod : getAllProducts())
        {
            if(prod.Id == productId)
            {
                return prod.Name;
            }
        }
        return '';
    }
    
    private Boolean isLevelProduct(String productId)
    {
        for(ProductInfo prod : getAllProducts())
        {
            if(prod.Id == productId)
            {
                return prod.IsLevel;
            }
        }
        return false;
    }
    
    //merges school name, if selected school have a 'All' word, that will retain the region name and delete all schools in this region
    public String mergeSchoolName(String selectedSchool)
    {
        String result = '';
        Set<String> schoolNames = new Set<String>();
        List<String> removedSchools = new List<String>();    
        schoolNames.addAll(selectedSchool.split(';'));
        
        for(String name : schoolNames)
        {
          Integer index = name.indexOf('All');
          if(index == 0) //selected the nation
          {
            return result = 'All';
            break;
          }
          else if(index > 0) //selected all schools in the region
          {
            String region = name.subString(0,index).trim();
            
            for(String sName : schoolNames)
            {
              if(sName.indexOf(region) == 0 && sName.indexOf('All') < 0)
              {
                removedSchools.add(sName); 
              }
            }        
          }
        }
        schoolNames.removeAll(removedSchools);
        
        for(String finalName : schoolNames)
        {
          result += finalName + ';';
        }
        return result;
    }
  
    public class StudentInfo
    {
        public StudentInfo()
        {
            products = new List<ProductInfo>();
        }
        
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
        public Integer ProductsCount
        {
            get { return products.size(); }
        }
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
    
    // For original product
    private Map<String, PreviousProductInfo> originalProductMap = new Map<String, PreviousProductInfo>();
    
    public String StudentProductSelectId {get; set;}
    public List<SelectOption> OriginalProductOptions {get; set;}
    public Boolean SelectOneStudentActual {get; set;}
    
    public List<PreviousProductInfo> getOldProductInfoList()
    {
        if(StudentProductSelectId == null)
        {
            if(OriginalProductOptions != null && OriginalProductOptions.size() > 0)
            {
                return new List<PreviousProductInfo>{ originalProductMap.get(OriginalProductOptions[0].getValue()) };
            }
            return null;
        }
        else
        {
            return new List<PreviousProductInfo>{ originalProductMap.get(StudentProductSelectId)};
        }
    }
    
    public void selectOldProducts()
    {   
        OriginalProductOptions = new List<SelectOption>();
        originalProductMap.clear();
        StudentProductSelectId = null;
        if(allStudents != null)
        {
            String currentStudentActualId = null;
            SelectOneStudentActual = true;
            for(StudentInfo info : allStudents)
            { 
                if(info.Selected != null && info.Selected)
                {
                    if(currentStudentActualId != null && currentStudentActualId != info.Id)
                    {
                        SelectOneStudentActual = false;
                        break;
                    }
                    currentStudentActualId = info.Id;
                }
            }
            if(currentStudentActualId != null && SelectOneStudentActual != false)
            {
                StudentActual__c studentActual = [select Id, Student__c, Actual__r.China_Sales_Type__c from StudentActual__c where Id = :currentStudentActualId limit 1];
                if(studentActual.Actual__r.China_Sales_Type__c != null && (studentActual.Actual__r.China_Sales_Type__c.contains('Upgrade') || studentActual.Actual__r.China_Sales_Type__c == 'Downgrade' || studentActual.Actual__r.China_Sales_Type__c == 'Renewal'))
                {   
                    List<StudentProduct__c> studentProducts = [select Id, Product__r.Name, LevelsPurchased__c, StandardLength__c, FreeLength__c, MarketingLength__c, Quantity__c from StudentProduct__c where StudentActual__r.Student__c = :studentActual.Student__c and StudentActual__r.Student__c != null];
                    for(StudentProduct__c studentProduct : studentProducts)
                    {
                        originalProductMap.put(studentProduct.Id, new PreviousProductInfo(studentActual.Id, studentProduct.Product__r.Name, studentProduct.Id, studentProduct.LevelsPurchased__c, studentProduct.StandardLength__c, studentProduct.FreeLength__c, studentProduct.Quantity__c));
                        OriginalProductOptions.add(new SelectOption(studentProduct.Id, studentProduct.Product__r.Name));
                    }
                }
            }
        }
    } //original product end.
    
    public class PreviousProductInfo
    {
        private String StudentActualId;
        public String ProductName {get; set;}
        public String ProductId {get; set;}
        public String LevelPurchased {get; set;}
        public String StandLength {get; set;}
        public String FreeLength {get; set;}
        public Integer Quantity {get; set;}
        
        public PreviousProductInfo(String studentActualIdValue, String name, String pId, String level, String sLength, String fLength, Double qut)
        {
            StudentActualId = studentActualIdValue;
            ProductName = name;
            ProductId = pId;
            LevelPurchased = level;
            StandLength = sLength;
            FreeLength = fLength;
            Quantity = (qut == null) ? 0 : qut.intValue();
        }
    }
    
    public class StudentAmountInfo
    {
        public String StudentActualId {get; set;}
        public Decimal FinalPrice {get; set;}
        public Decimal CNPaymentTotal {get; set;}
        
        public StudentAmountInfo(String idValue, Decimal price, Decimal paymentTotal)
        {
            StudentActualId = idValue;
            FinalPrice = price;
            CNPaymentTotal = paymentTotal;
        }
    }
    
    public List<StudentActual__c> getStudentAmountInfos()
    {
        //List<StudentAmountInfo> resultList = new List<StudentAmountInfo>();
        return [select Id, Name, FinalPrice__c, CNPaymentTotal__c from StudentActual__c where Actual__c = :actualId and Actual__c != null];
    } 
     
    @isTest
    static void testAddProductsController()
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

        PageReference page = new PageReference('/apex/AddProducts?id=' + actual.Id);
        Test.setCurrentPage(page);
        AddProductsController controller = new AddProductsController();
        List<StudentInfo> students = controller.getAllStudents();
        System.assert(students.size() > 0);
        Decimal amount = students[0].TotalAmount;
        
        students[0].Selected = true;
        List<StudentInfo> selectedStudents = controller.getSelectedStudents();
        System.assert(selectedStudents.size() > 0);
        
        PageReference submitedPage = new PageReference('/apex/AddProducts?id=' + actual.Id + '&sid=' + studentActual.Id);
        Test.setCurrentPage(submitedPage);
        controller.highlightStudent();
        StudentInfo currentStudent = controller.getHighlightedStudent();
        System.assert(currentStudent != null);
        
        System.assert(controller.getNewProductItems() != null);
        System.assert(controller.getStandardProductItems() != null);
        System.assert(controller.getNonStandardProductItems() != null);
        System.assert(controller.getAllProductItems() != null);
        
        List<ProductInfo> products = controller.getStudentProducts();
        //products[0].StudentProductId = 'test';
        products[0].remove();
        //controller.NewProduct.Id = 'test';
        controller.studentProductInfo.BookingCenters__c = 'BJ All;BJ DWL';
        controller.cancel();
        controller.save();
        controller.getOldProductInfoList();
        controller.selectOldProducts();
        
        AddProductsController.PreviousProductInfo previousProduct = new AddProductsController.PreviousProductInfo('11227363674', 'test name', 'pid', 'level', 'slength', 'flength', 2.0);
        AddProductsController.StudentAmountInfo  sAmountInfo = new AddProductsController.StudentAmountInfo('id', 7.8, 7.8);
    }
}