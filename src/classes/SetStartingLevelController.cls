/*
 * This controller for page 'Set Starting Level'. The page in a popup window when we click the button 'Set Starting Level' on student actual detail page.
 */
public class SetStartingLevelController 
{
    private Contact student;
    private EtownCourseHelper.CourseDataInfo actualInfo;
    private static final List<String> firstActualOptions = new List<String> {    'Beginner-Level0A',
                                                                         'Beginner-Level 1',
                                                                         'Elementary-Level 2',
                                                                         'Intermediate-Level 5',
                                                                         'Upper Intermediate-Level 8',
                                                                         'Advanced-Level 11',
                                                                         'Upper Advanced-Level 14' };
    private static final List<String> secondActualOptions = new List<String> {  'Beginner-Level0A',
                                                                          'Beginner-Level0B',
                                                                          'Beginner-Level 1',
                                                                          'Elementary-Level 2',
                                                                          'Elementary-Level 3',
                                                                          'Elementary-Level 4',
                                                                          'Intermediate-Level 5',
                                                                          'Intermediate-Level 6',
                                                                          'Intermediate-Level 7',
                                                                          'Upper Intermediate-Level 8',
                                                                          'Upper Intermediate-Level 9',
                                                                          'Upper Intermediate-Level 10',
                                                                          'Advanced-Level 11',
                                                                          'Advanced-Level 12',
                                                                          'Advanced-Level 13',
                                                                          'Upper Advanced-Level 14' };
    
    public SetStartingLevelController()
    {
        String studentActualId = ApexPages.currentPage().getParameters().get('id');
        try
        {
            actualInfo = EtownCourseHelper.parseStudentActual(studentActualId);
            StartingLevelValue = actualInfo.CurrentStudentActual.Student__r.StartingLevel__c;
            populateLevelItems(actualInfo);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }
    
    public Boolean IsPanelShow { get; set; }
    public String StartingLevelValue { get; set; }
    public List<SelectOption> LevelItems { get; set; }
    
    public PageReference save()
    {
        try
        {
            actualInfo.currentStudentActual.StartingLevel__c = StartingLevelValue;
            if(student != null)
            {
                student.StartingLevel__c = StartingLevelValue;
                update student;
            }
            update actualInfo.CurrentStudentActual;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    private void populateLevelItems(EtownCourseHelper.CourseDataInfo dataInfo)
    {
        if(dataInfo.HasLevelValue)
        {
            IsPanelShow = false;
            LevelItems = new List<SelectOption>();
        }
        else
        {
            if(dataInfo.IsFirstSP)
            {
                IsPanelShow = true;
                LevelItems = (dataInfo.IsAlumniClub)? createActualItems(secondActualOptions) : createActualItems(firstActualOptions);
                student = new Contact(Id=dataInfo.CurrentStudentActual.Student__c); // if student actual is the first for student, copy the value to that field of contact.
            }
            else if(dataInfo.IsLength2Level || dataInfo.IsAlumniClub)
            {
                IsPanelShow = true;
                LevelItems = createActualItems(secondActualOptions);
            }
            else
            {
                IsPanelShow = false;
                LevelItems = new List<SelectOption>();
            }
        }
    }
    
    private List<SelectOption> createActualItems(List<String> options)
    {
        List<SelectOption> result = new List<SelectOption>();
        for(String option : options)
        {
            result.add(new SelectOption(option, option));
        }
        return result;
    }

    @isTest
    static void testSetStartingLevelController()
    {
        List<RecordType> b2bTypes = [select Id from RecordType where SObjectType='Account' and Name like '%B2B%' limit 1];
        Id b2bId = (b2bTypes.size() > 0) ? b2bTypes[0].Id : null;
        Account company  = new Account(Name='test company', RecordTypeId=b2bId);
        insert company;
        Contact student1 = new Contact(LastName='studentName1', AccountId=company.Id);
        Contact student2 = new Contact(LastName='studentName2', AccountId=company.Id);
        insert new List<Contact>{ student1, student2 };
        Actual__c actual1 = new Actual__c(Account__c=company.Id);
        Actual__c actual2 = new Actual__c(Account__c=company.Id);
        Actual__c actual3 = new Actual__c(Account__c=company.Id);
        insert new List<Actual__c> { actual1, actual2, actual3};
        StudentActual__c studentActual1 = new StudentActual__c(Actual__c=actual1.Id, Student__c=student1.Id);
        StudentActual__c studentActual2 = new StudentActual__c(Actual__c=actual2.Id, Student__c=student1.Id);
        StudentActual__c studentActual3 = new StudentActual__c(Actual__c=actual3.Id, Student__c=student1.Id);
        insert new List<StudentActual__c> { studentActual1, studentActual2, studentActual3};
        Product2 testProduct1 = new Product2(Name='test Product', EtownId__c='test124', IsLevel__c=false, IsActivable__c=true, Family='Smart Prodcut List'); //length product
        Product2 testProduct2 = new Product2(Name='Premium 10', EtownId__c='test123', IsLevel__c=true, IsActivable__c=true, Family='Smart Product List'); //level product
        Product2 testProduct3 = new Product2(Name='Alumni Club', EtownId__c='test125', IsLevel__c=true, IsActivable__c=true, Family='Smart Porduct List');
        insert new List<Product2>{ testProduct1, testProduct2, testProduct3};
        StudentProduct__c studentProduct1 = new StudentProduct__c(Product__c=testProduct1.Id, StudentActual__c=studentActual1.Id);
        StudentProduct__c studentProduct2 = new StudentProduct__c(Product__c=testProduct2.Id, StudentActual__c=studentActual2.Id);
        StudentProduct__c studentProduct3 = new StudentProduct__c(Product__c=testProduct3.Id, StudentActual__c=studentActual3.Id);
        insert new List<StudentProduct__c>{ studentProduct1, studentProduct2, studentProduct3};
        
        Test.startTest();
        PageReference page1 = new PageReference('/apex/SetStartingLevel?id=' + studentActual1.Id + '&studentId=' + student1.Id);
        Test.setCurrentPage(page1);
        SetStartingLevelController controller1 = new SetStartingLevelController();
        System.assertEquals(controller1.IsPanelShow, true);
        System.assertEquals(controller1.LevelItems.size(), 7);
        controller1.StartingLevelValue = 'Beginner-Level 1';
        controller1.save();
     
        //length product to level product, last acitve prodcut is length, current product is level
        PageReference page2 = new PageReference('/apex/SetStartingLevel?id=' + studentActual2.Id + '&studentId=' + student1.Id);
        Test.setCurrentPage(page2);
        studentActual1.CourseActivationDate__c = Date.today();
        update studentActual1;
        SetStartingLevelController controller2 = new SetStartingLevelController();
        System.assertEquals(controller2.IsPanelShow, true);
        System.assertEquals(controller2.LevelItems.size(), 16);
        controller2.StartingLevelValue = 'Elementary-Level 2';
        controller2.save();
            
        //not need to set starting level
        studentActual2.CourseActivationDate__c = Date.today();
        studentActual2.OrderStartDate__c = Date.today();
        studentActual2.OrderEndDate__c = Date.today().addDays(30);
        studentActual1.StartingLevel__c = null;
        update new List<StudentActual__c> { studentActual1, studentActual2 };
        PageReference page5 = new PageReference('/apex/SetStartingLevel?id=' + studentActual1.Id + '&studentId=' + student1.Id);
        Test.setCurrentPage(page5);
        SetStartingLevelController controller5 = new SetStartingLevelController();
        System.assertEquals(controller5.IsPanelShow, false);
        controller5.save();
        
        //current product is alumni club 
        PageReference page3 = new PageReference('/apex/SetStartingLevel?id=' + studentActual3.Id + '&studentId=' + student2.Id);
        Test.setCurrentPage(page3);
        SetStartingLevelController controller3 = new SetStartingLevelController();
        System.assertEquals(controller3.IsPanelShow, true);
        controller3.StartingLevelValue = 'Elementary-Level 2';
        controller3.save();
        studentActual3.CourseActivationDate__c = Date.today();
        studentActual3.OrderStartDate__c = Date.today().addDays(30);
        studentActual3.OrderEndDate__c = Date.today().addDays(40);
        update studentActual3;
        
        //last active product is alumni club 
        studentActual1.StartingLevel__c = null;
        update studentActual1;
        PageReference page4 = new PageReference('/apex/SetStartingLevel?id=' + studentActual1.Id + '&studentId=' + student1.Id);
        Test.setCurrentPage(page4);
        SetStartingLevelController controller4 = new SetStartingLevelController();
        controller4.StartingLevelValue = 'Elementary-Level 4';
        System.assertEquals(controller4.IsPanelShow, true);
        controller4.save();
            
        //starting level has a value already
        PageReference page6 = new PageReference('/apex/SetStartingLevel?id=' + studentActual1.Id + '&studentId=' + student1.Id);
        Test.setCurrentPage(page6);
        SetStartingLevelController controller6 = new SetStartingLevelController();
        System.assertEquals(controller6.IsPanelShow, false);
        controller6.save();
        Test.stopTest();
    }
}