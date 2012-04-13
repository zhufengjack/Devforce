/*
 * Test the triggers
 */
public  class TriggerTestFixtures
{
     @isTest
    static void testSetStudentActualWhenCreatePayMentByPos()
    {
        Account company = new Account(Name = 'Virtual company');
        insert company;
        Contact student = new Contact(LastName = 'acme name', AccountId = company.Id);
        insert student;
        Actual__c actual = new Actual__c(account__c = company.Id);
        insert actual;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, Student__c = student.Id);
        insert studentActual; 
        String cardHolderAndStudentActualId = 'DavidTest:' + studentActual.Id;
        PaymentData__c payment = new PaymentData__c(Actual__c = actual.Id, Card_Holder__c = cardHolderAndStudentActualId, Pay_Type__c = 'China Smart Deposit', Amount__c = 100); 
        insert payment; 
        payment = [select Id, Actual__c, Card_Holder__c, Pay_Type__c, StudentActual__c from PaymentData__c where Id=:payment.Id limit 1];     
    }
    
    @isTest
    static void testSetOpportunityFTMName()
    {
        Account acc = new Account(name='acme');
        insert acc;
        Opportunity opp = new Opportunity(AccountId=acc.Id, Name = 'acme', Location__c = 'BJ DFG', StageName = 'Set Appt', CloseDate = Date.today(), RecordTypeId='0124000000099sY');
        insert opp;
        User ftmUser = getUserByProfile('00e40000001BNBh');
        acc.OwnerId = ftmUser.Id; System.debug('###:ftmUser' + ftmUser.Id);
        update acc;
        opp = [select Id, FTM_Name__c from Opportunity where Id=:opp.Id limit 1];
    }
    @isTest
    static void testSetStudentRoleName()
    {
        Account acc = new Account(name='acme');
        insert acc; 
        acc = [select Id, Student_Owner_Role__c from Account where Id=:acc.Id limit 1];
        UserRole currentRole = [select Id, Name from UserRole where Id=:UserInfo.getUserRoleId() limit 1];
    }
    
    @isTest
    static void testLeadTriggerForSetValues()
    {
        System.runAs(getUserByProfile('00e40000001BNBS'))
        {
            Lead newLead = new Lead(LastName='acme', Company='acme', status = 'Set Appt');
            insert newLead;
            newLead = [select LeadSource, Initial_Appt_Date__c from Lead where Id=:newLead.Id limit 1];
            //System.assertEquals('Direct to center', newLead.LeadSource);
            //System.assert(newLead.Initial_Appt_Date__c != null);
        }
    }
    
    @isTest
    static void testBrazilTransferAccount()
    {
        Account acc = new Account(name='acme');
        insert acc;
        System.runAs(getUserByRole('00E40000000siWr'))
        {
            //running in the role of 'Brazil Sales Group Lead (A)'
            try
            {
                acc.OwnerId = getUserByRole('00E30000000rCiw').Id; //sets the ownerId to a user of role 'Brazil Sales Group (A)'
                update acc;
            
                acc.OwnerId = getUserByRole('00E30000000rCil').Id; //sets the ownerId to a user of another role
                update acc;
                //System.assert(false);
            }
            catch(Exception ex)
            {
                //an exception is expected to happen
            }
        }
    }
    @isTest
    static void testBrazilTransferOpportunity()
    {
        Opportunity opp = new Opportunity(Name='acme', StageName = 'Set Appt', CloseDate = Date.today());
        insert opp;
        System.runAs(getUserByRole('00E40000000siWr'))
        {
            //running in the role of 'Brazil Sales Group Lead (A)'
            try
            {
                opp.OwnerId = getUserByRole('00E30000000rCiw').Id; //sets the ownerId to a user of role 'Brazil Sales Group (A)'
                update opp;
            
                opp.OwnerId = getUserByRole('00E30000000rCil').Id; //sets the ownerId to a user of another role
                update opp;
                //System.assert(false);
            }
            catch(Exception ex)
            {
                //an exception is expected to happen
            }
        }
    }
    
    @isTest
    static void testPreventOPTUpdated()
    {
        Account company = new Account(Name = 'test company');
        insert company;
        Contact student = new Contact(LastName = 'acme lastname', AccountId = company.ID, OPT_Level__c = 'test', OPTTeacher__c = 'test');
        insert student;
        try
        {
            student.OPT_Level__c = 'test1';
            student.OPTTeacher__c = 'test2';
            update student;
        }
        catch(DMLException ex)
        {
            System.assertEquals('FIELD_CUSTOM_VALIDATION_EXCEPTION', ex.getDmlStatusCode(0));
        }
    }
    
    @isTest
    static void testCalculateFinalPrice()
    {
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c studentActual1 = new StudentActual__c(Name = 'Student1', Actual__c = testActual.Id);
        StudentActual__c studentActual2 = new StudentActual__c(Name = 'Student2', Actual__c = testActual.Id);
        StudentActual__c studentActual3 = new StudentActual__c(Name = 'Student3', Actual__c = testActual.Id);
        insert new StudentActual__c[]{studentActual1, studentActual2, studentActual3};
        StudentProduct__c studentProduct1 = new StudentProduct__c(Price__c = 200, Quantity__c = 3, StudentActual__c = studentActual1.Id);
        StudentProduct__c studentProduct2 = new StudentProduct__c(Price__c = 100, Quantity__c = 2, StudentActual__c = studentActual1.Id);
        StudentProduct__c studentProduct3 = new StudentProduct__c(Price__c = 100, Quantity__c = 3, StudentActual__c = studentActual2.Id);
        insert new StudentProduct__c[]{studentProduct1, studentProduct2, studentProduct3};
        testActual = [select Id, Final_Price__c from Actual__c where Id = :testActual.Id];
        System.assertEquals(1100, testActual.Final_Price__c);
        StudentActual__c studentActualTemp = [select Id, FinalPrice__c from StudentActual__c where Id = :studentActual1.Id];
        System.assertEquals(800, studentActualTemp.FinalPrice__c);
        Delete studentProduct2;
        testActual = [select Id, Final_Price__c from Actual__c where Id = :testActual.Id];
        System.assertEquals(900, testActual.Final_Price__c);
        studentActualTemp = [select Id, FinalPrice__c from StudentActual__c where Id = :studentActual1.Id];
        System.assertEquals(600, studentActualTemp.FinalPrice__c);
    }
    
    @isTest
    static void testCalculateSumPaymentData()
    {
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c studentActual1 = new StudentActual__c(Name = 'Student1', Actual__c = testActual.Id);
        StudentActual__c studentActual2 = new StudentActual__c(Name = 'Student2', Actual__c = testActual.Id);
        StudentActual__c studentActual3 = new StudentActual__c(Name = 'Student3', Actual__c = testActual.Id);
        insert new StudentActual__c[]{studentActual1, studentActual2, studentActual3};
        PaymentData__c payment1 = new PaymentData__c(Actual__c = testActual.Id, StudentActual__c = studentActual1.Id, Pay_Type__c = 'China Smart Deposit', Amount__c = 100);
        PaymentData__c payment2 = new PaymentData__c(Actual__c = testActual.Id, StudentActual__c = studentActual1.Id, Pay_Type__c = 'China Smart Deposit', Amount__c = 200);
        PaymentData__c payment3 = new PaymentData__c(Actual__c = testActual.Id, StudentActual__c = studentActual1.Id, Pay_Type__c = 'China Smart Payment', Amount__c = 0);
        PaymentData__c Payment4 = new PaymentData__c(Actual__c = testActual.Id, StudentActual__c = studentActual1.Id, pay_Type__c = 'China Smart Payment', Amount__c = 500);
        insert new PaymentData__c[]{payment1, payment2, payment3, payment4};
        testActual = [select Id, CN_Payment_Total__c, CN_Deposit_Total__c,  CN_Refund_Total__c from Actual__c where Id = :testActual.Id];
        System.assertEquals(500, testActual.CN_Payment_Total__c);
        System.assertEquals(300, testActual.CN_Deposit_Total__c);
    }

    @isTest
    static void testDeleteStudentProduct()
    {
        Actual__c testActual = new Actual__c();
        insert testActual;
        StudentActual__c student1 = new StudentActual__c(Actual__c = testActual.Id, RefundType__c = 'Full Refund');
        StudentActual__c student2 = new StudentActual__c(Actual__c = testActual.Id, RefundType__c = 'Full Refund');
        StudentActual__c student3 = new StudentActual__c(Actual__c = testActual.Id, RefundType__c = 'Full Refund');
        insert new StudentActual__c[]{student1, student2, student3};
        StudentProduct__c product1 = new StudentProduct__c(StudentActual__c = student1.Id, Name = 'test1',  Price__c = 23, Quantity__c = 2);
        StudentProduct__c product2 = new StudentProduct__c(StudentActual__c = student2.Id, Name = 'test2', Price__c = 23, Refund_Amount__c = 12, Refund_Quantity__c = 2, Refund_date_China__c = Date.today());
        StudentProduct__c Product3 = new StudentProduct__c(StudentActual__c = student3.Id, Name = 'test3', Price__c = 23, Refund_Amount__c = 12, Refund_Quantity__c = 1, Refund_date_China__c = Date.today());
        StudentProduct__c product4 = new StudentProduct__c(StudentActual__c = student3.Id, Name = 'test4', Price__c = 23, Refund_Amount__c = 12, Refund_Quantity__c = 1, Refund_date_China__c = Date.today());
        insert new StudentProduct__c[]{product1, product2, product3, product4}; 
        testActual = [select Id, Name, Final_Price__c, CN_Refund_Amount__c from Actual__c where Id = :testActual.Id];
        System.assertEquals(115, testActual.Final_Price__c);
        System.assertEquals(36, testActual.CN_Refund_Amount__c);
        delete new StudentActual__c[]{student1, student2, student3};
        testActual = [select Id, Name, Final_Price__c, CN_Refund_Amount__c from Actual__c where Id = :testActual.Id];
        System.assertEquals(0, testActual.Final_Price__c);
        System.assertEquals(0, testActual.CN_Refund_Amount__c);
    }

    @isTest
    static void testForTranslationRule()
    {
        String ccProfileId = '00e40000000j20V'; // EF China Sales User New.
        String ccRoleId = '00E40000000rUqH'; // China BJ_DWL Sales Consultant.
        String b2bSalesManagerProfileId = [select Id from Profile where Name = 'EF China Smart B2B Sales Manager' limit 1].Id;//'00eO0000000Lqze'; //   EF China B2B Sales Manager
        String b2bSalesRoleId = '00E40000000sLt0'; // China BJ Finance Manager
        User currentUser = new User(alias = 'cUser', IsActive = true, email='currentUser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', localesidkey='en_US', profileid = ccProfileId, userRoleId = ccRoleId, timezonesidkey='America/Los_Angeles', username='currentUser@testorg.com', Locale__c = 'China', Functions__c = 'China Smart Schools');
        User b2bManagerUser = new User(alias = 'mUser', IsActive = true, email='managerUser@testorg.com', emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US', localesidkey='en_US', profileid = b2bSalesManagerProfileId, userRoleId = b2bSalesRoleId, timezonesidkey='America/Los_Angeles', username='managerUser@testorg.com', Locale__c = 'China', Functions__c = 'China Smart Schools');
        insert new User[]{currentUser, b2bManagerUser};
        
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1];
        
        System.runAs(currentUser)
        {  
            Account student = new Account(Name = 'test');
            Account student2 = new Account(Name = 'test2');
            insert new Account[]{student, student2};
            Opportunity testOpp = new Opportunity(Name = 'test', AccountId = student.Id, Location__c = 'BJ GM1',  LeadSource = 'Inbound Call', CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
            Opportunity testOpp2 = new Opportunity(Name = 'test2', AccountId = student.Id, Location__c = 'BJ GM1',  LeadSource = 'Inbound Call', CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
            insert new Opportunity[]{testOpp, testOpp2};
            testOpp.OwnerId = b2bManagerUser.Id;
            testOpp2.OwnerId = b2bManagerUser.Id;
            update new Opportunity[]{testOpp, testOpp2}; 
            student2.OwnerId = b2bManagerUser.Id;
            update new Account[]{student2};
            //System.assertEquals(currentUser.Id, [select Id, B2C_Sales_Name__c from Opportunity where Id = :testOpp.Id].B2C_Sales_Name__c);
        }
        
        //Test for trigger "UpdateRelatedOpportunityFields".
        System.runAs(currentUser)
        {
            Account student = new Account(Name = 'test');
            insert student;
            Opportunity testOpp = new Opportunity(Name = 'test', AccountId = student.Id, Location__c = 'BJ GM1',  LeadSource = 'Inbound Call', CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
            Opportunity testOpp2 = new Opportunity(Name = 'test2', AccountId = student.Id, Location__c = 'BJ GM1',  LeadSource = 'Inbound Call', CloseDate = Date.today().addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
            insert new Opportunity[]{testOpp, testOpp2};
            student.OwnerId = b2bManagerUser.Id;
            update student;
        }
    }
    
    // Test for tigger CanNotAddOrDeleteAfterActivation. 
    @isTest
    static void testCanNotAddOrDeleteAfterActivation()
    {
        Actual__c actual = new Actual__c();
        insert actual;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id);
        insert studentActual;
        StudentProduct__c studentProduct1 = new StudentProduct__c(StudentActual__c = studentActual.Id);
        insert StudentProduct1;
        StudentProduct__c studentProduct2 = new StudentProduct__c(StudentActual__c = studentActual.Id);
        insert StudentProduct2;
        studentActual.Status__c = 'Activated';
        update studentActual;
        StudentProduct__c studentProduct3 = new StudentProduct__c(StudentActual__c = studentActual.Id);
        try
        {
            insert studentProduct3;
        }
        catch(Exception ex){}
        try
        {
            delete  studentProduct1;
        }
        catch(Exception ex){}   
    }
    
    // Test for CanNotCreateNewContactForAccount.
    //@isTest
    static void testCanNotCreateNewContactForAccount()
    {
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Smart B2B record type' or Name = 'Brazil Student Record Type'];
        String b2bRecordTypeId = '012O00000004IYJ'; // China Smart B2B record type.
        String brazilRecordTypeId = '0124000000098oB'; // Brazil Student Record Type.
 
        Account b2bAccount = new Account(Name = 'testAccount', RecordTypeId = b2bRecordTypeId);
        Account notB2bAccount = new Account(Name = 'testNotB2bAccount', RecordTypeId = brazilRecordTypeId);
        insert new Account[]{b2bAccount, notB2bAccount};
        // For b2b type.
        Contact contact1 = new Contact(LastName = 'test1', AccountId = b2bAccount.Id);
        insert contact1;
        Contact contact2 = new Contact(LastName = 'test2', AccountId = b2bAccount.Id);
        insert contact2;
        // For other type.
        Contact contact3 = new Contact(LastName = 'test3', AccountId = notB2bAccount.Id);
        insert contact3;
        Contact contact4 = new Contact(LastName = 'test4', AccountId = notB2bAccount.Id);
        Contact contact5 = new Contact(LastName = 'test5', AccountId = notB2bAccount.Id);
        try
        {
            insert new Contact[]{contact4, contact5};
        }
        catch(Exception ex){}
        contact1.AccountId = notB2bAccount.Id;
        contact2.AccountId = notB2bAccount.Id;
        try
        {
            upsert new Contact[]{contact1, contact2, new Contact(LastName = 'test5', AccountId = notB2bAccount.Id), new Contact(LastName = 'test6', AccountId = notB2bAccount.Id)};
        }
        catch(Exception ex){}
        // test for duplicate values.
        notB2bAccount = new Account(Name = 'testNotB2bAccount', RecordTypeId = brazilRecordTypeId);
        insert notB2bAccount;
        try
        {
            insert new Contact[]{new Contact(LastName = 'test7', AccountId = notB2bAccount.Id), new Contact(LastName = 'test8', AccountId = notB2bAccount.Id)};
        }
        catch(Exception ex){} 
    }
    
    //gets an active user with the specified profile Id
    private static User getUserByProfile(String profileId)
    {
        List<User> users = [select Id from User where ProfileId=:profileId and IsActive=true];
        if(users.size() > 0)
        {
            return users[0];
        }
        else
        {
            return new User(Id=UserInfo.getUserId());
        }
    }
    
    //gets an active user with the specified role Id
    private static User getUserByRole(String roleId)
    {
        List<User> users = [select Id from User where UserRoleId=:roleId and IsActive=true];
        if(users.size() > 0)
        {
            return users[0];
        }
        else
        {
            return new User(Id=UserInfo.getUserId());
        }
    }
    
    @isTest
    static void testCopyRefundDateToActual()
    {
        Actual__c actual1 = new Actual__c();
        Actual__c actual2 = new Actual__c();
        Actual__c actual3 = new Actual__c();
        Actual__c actual4 = new Actual__c();
        insert new Actual__c[]{actual1, actual2, actual3, actual4};
        StudentActual__c student1 = new StudentActual__c(Name = 'Student Actual 1', Actual__c = actual1.Id);
        StudentActual__c student2 = new StudentActual__c(Name = 'Student Actual 2', Actual__c = actual2.Id);
        StudentActual__c student3 = new StudentActual__c(Name = 'Student Actual 3', Actual__c = actual3.Id);
        StudentActual__c student4 = new StudentActual__c(Name = 'Student Actual 4', Actual__c = actual4.Id);
        StudentActual__c student5 = new StudentActual__c(Name = 'Student Actual 5', Actual__c = actual4.Id);
        insert new StudentActual__c[]{student1, student2, student3, student4, student5};
        Id productRecordTypeId = '0124000000098XF'; // China Product Record Type.
        Product2 testProduct1 = new Product2(Name = 'Test Product', EtownId__c = 'test12345', RecordTypeId = productRecordTypeId);
        Product2 testProduct2 = new Product2(Name = 'Test Product2', RecordTypeId = ProductRecordTypeId);
        insert new Product2[]{testProduct1, testProduct2};
        Date baseDate = Date.today();
        StudentProduct__c product1 = new StudentProduct__c(StudentActual__c = student1.Id, Refund_date_China__c = baseDate, Product__c = testProduct1.Id);
        StudentProduct__c product2 = new StudentProduct__c(StudentActual__c = student2.Id, Refund_date_China__c = baseDate.addDays(6), product__c = testProduct1.Id);
        StudentProduct__c product3 = new StudentProduct__c(StudentActual__c = student3.Id, Refund_date_China__c = baseDate.addDays(3), product__c = testProduct2.Id);
        StudentProduct__c product4 = new StudentProduct__c(StudentActual__c = student4.Id, Refund_date_China__c = baseDate.addDays(2), product__c = testProduct2.Id);
        StudentProduct__c product5 = new StudentProduct__c(StudentActual__c = student5.Id, Refund_date_China__c = baseDate.addDays(8), product__c = testProduct2.Id);
        insert new StudentProduct__c[]{product1, product2, product3, product4, product5};
        System.assertEquals(baseDate, [select Id, Refund_date_China__c from Actual__c where Id = :actual1.Id].Refund_date_China__c);
        System.assertEquals(null, [select Id, Refund_date_China__c from Actual__c where Id = :actual4.Id].Refund_date_China__c);
    }
    
    @isTest
    static void testCoachEventAndpaymentStatus()
    {
        Opportunity currentOpp = new Opportunity(Email__c = 'david.lee@meginfo.com', StageName = 'Closed Won', CloseDate = Date.today(), Name='acme');
        insert currentOpp;
        String BrazilActualRecordTypeId = '0124000000098gR';
        Actual__c actual = new Actual__c(RecordTypeId = BrazilActualRecordTypeId, Status__c = 'In Progress', Final_Price__c = 1000, Opportunity__c = currentOpp.Id);
        insert actual;
        student_after_sales__c studentAfterSales = new student_after_sales__c(Actual__c = actual.Id, Refund_amount_local_finance__c = 0, Discount_amount__c = 100, Info_for_Payments_Status__c = 'Cancelled-90 Days');
        insert studentAfterSales;
        Payment_Record__c record = new Payment_Record__c(Actual__c = actual.Id, Status__c = 'Collected', Amount_Due__c = 900, Amount_Collected__c = 900, Due_Date__c = date.today(), Collected_Date__c = date.today());
        insert record;
        Payment_Record__c record2 = new Payment_Record__c(Actual__c = actual.Id, Status__c = 'Failed', Amount_Due__c = 900, Due_Date__c = date.today());
        insert record2;
        //actual.Status__c = 'Waiting for T&C';
        actual.Product_Changed__c = true;
        update actual;
        studentAfterSales.Cancellation_reasons__c = 'Cancelled';
        studentAfterSales.Info_for_Payments_Status__c = 'Would like to upgrade/downgrade to another product';
        update studentAfterSales;
    }
    
    @isTest
    static void testSetContact()
    {
        Account b2cAccount = new Account(Name = 'b2c account');
        Account b2cAccount2 = new Account(Name = 'b2c account2');
        insert new Account[]{b2cAccount, b2cAccount2};
        Contact contact1 = new Contact(LastName = 'test contact 1', AccountId = b2cAccount.Id);
        Contact contact2 = new Contact(LastName = 'test contact 2', AccountId = b2cAccount2.Id);
        insert new Contact[]{contact1, contact2};
        Opportunity opp = new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name='acme', AccountId = b2cAccount.Id);
        insert opp;
        System.assertEquals(contact1.Id, [select Id, Contact__c from Opportunity where Id = :opp.Id].Contact__c);
        opp.AccountId = b2cAccount2.Id;
        update opp;
        System.assertEquals(contact2.Id, [select Id, Contact__c from Opportunity where Id = :opp.Id].Contact__c);
    }
    
    @isTest
    static void testSetContactToConvertOpportunity()
    {
        Lead testLead = new Lead(lastname = 'test', Company = 'test company');
        insert testLead;
        Database.Leadconvert lc = new Database.Leadconvert();
        lc.setLeadId(testLead.Id);
        LeadStatus convertStatus = [select Id, MasterLabel from LeadStatus where IsConverted = true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.Leadconvertresult result = Database.convertLead(lc);
        System.assertEquals(result.getContactId(), [select Id, Contact__c from Opportunity where Id = :result.getOpportunityId()].Contact__c);
    }
    
    @isTest
    static  void testAutomaticSendSMS()
    {
            String oppIds = '123455ty76ut';
            Opportunity opp = new Opportunity();
            opp.Name ='Test';
            opp.CloseDate = Date.today() ;
            opp.StageName ='show';
            opp.Automatic_Action__c ='Send SMS';
            insert opp;
            update opp; 
    }
    
     @isTest
    static void testCopyReferralInformation()
    {
        Account act2 = new Account(Name = 'test Account Referee');
        insert act2;
        Account act1 = new Account(Name = 'test Account Referral', ParentId = act2.Id);
        insert act1;
        Referral__c refrral = new Referral__c(Name = 'test Refrral', Referee__c = act2.Id, ReferralName__c = act1.Id);
        insert refrral;
        Contact contact1 = new Contact(LastName = 'test1', AccountId = act1.Id);
        insert contact1;
        Opportunity opp = new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name='opp refree', AccountId = act1.Id);
        insert opp;
        Actual__c actual = new Actual__c(Account__c = act1.Id, China_Sales_Type__c = 'New', Opportunity__c = opp.Id);
        insert actual;
        StudentActual__c stuActual = new StudentActual__c(Student__c = contact1.Id, Actual__c = actual.Id);
        insert stuActual;
        Id productRecordTypeId = '0124000000098XF'; // China Product Record Type.
        Product2 testProduct1 = new Product2(Name = 'Test Product', RecordTypeId = productRecordTypeId);
        insert testProduct1;
        StudentProduct__c stuProd = new StudentProduct__c(Name = 'test stuProduct', StudentActual__c = stuActual.Id, Product__c = testProduct1.Id);
        insert stuProd;
        StudentProduct__c newStuProd = new StudentProduct__c(Id = stuProd.Id);
        newStuProd.Status__c = 'Activated';
        update newStuProd;
    }
}