/*
* Controller for page "Student Product Refund Dialog".
*/
public class StudentProductRefundDialogController 
{
    private StudentProduct__c currentStudentProduct;
    private RefundInfo tempRefundInfo = new RefundInfo();
    private static EtownServiceStub.BasicHttpBinding_ISalesForceService service;
    private static final String oboeUsername = 'SalesforceSmartUser';
    private static final String oboePassword = 'SalesforceSmartPwd';
    private String studentProductId;
    
    public StudentProductRefundDialogController()
    {
        MiddleObject = new StudentProduct__c();
        MiddleStudentActual = new StudentActual__c();
        studentProductId = ApexPages.currentPage().getParameters().get('id');
        List<StudentProduct__c> studentProducts = [select Id, Name, Amount__c, Status__c, Quantity__c, BookingCenters__c, Refund_Amount__c, Product__r.Family, Product__r.Name, Product__r.RedemptionCode__c, Refund_date_China__c, Refund_Quantity__c, StudentActual__c, StudentActual__r.RefundType__c, StudentActual__r.RefundAmount__c, StudentActual__r.EntryCenter__c, StudentActual__r.CNRefundTotal__c, StudentActual__r.Student__c, StudentActual__r.OrderStartDate__c, StudentActual__r.OrderEndDate__c, StudentActual__r.Status__c, StudentActual__r.Student__r.EtownUserName__c, StudentActual__r.Student__r.EtownMemberId__c, StudentActual__r.Student__r.Status__c, StudentActual__r.CourseActivationDate__c from StudentProduct__c where Id = :studentProductId and StudentActual__c != null and StudentActual__r.Student__c != null limit 1];
        if(studentProducts.size() > 0)
        {
            currentStudentProduct = studentProducts[0];
            StudentProductName = currentStudentProduct.Name;
            ProductName = currentStudentProduct.Product__r.Name;
            MiddleObject.Refund_Amount__c = currentStudentProduct.Refund_Amount__c;
            MiddleObject.Refund_Quantity__c = currentStudentProduct.Refund_Quantity__c;
            MiddleStudentActual.RefundType__c = currentStudentProduct.StudentActual__r.RefundType__c;
        }
    }
    
    public StudentProduct__c MiddleObject {get; set;} // Student Product Refund Dialog.
    public StudentActual__c MiddleStudentActual {get; set;} // Student Product Refund Dialog.
    public String StudentProductName {get; set;}
    public String ProductName {get; set;}
    public Boolean VisualConfirm 
    {
        get
        { 
            if (visualConfirm == null ) 
                return false; 
            else 
                return visualConfirm;
        }  
        set;
    }
    
    public void refund()
    {
        String resultMessage;
        if(MiddleObject != null && MiddleStudentActual != null && currentStudentProduct != null)
        {       
            if(!checkInput())
            {
                return;
            }
            if(MiddleObject.Refund_Amount__c > currentStudentProduct.Amount__c)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Refund Amount cannot exceed product amount, please double check!'));
                return;
            }
            createRefundInfo();
            if(compareRefundAmount()) 
            {
                save();
            }
            else
            {
                VisualConfirm = true;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Refund Amount does not equal CN Refund Total, please double check!'));
                return;
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund failure.'));
        }
    }
    
    // When refund amount not equals to cn payment total, you should confirm.
    public void confirm()
    {
        String resultMessage;
        if(MiddleObject != null && MiddleStudentActual != null && currentStudentProduct != null)
        {
            save();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund failure.'));
        }
    }
    
    // All input field must be filled with.
    private Boolean checkInput()
    {
        Boolean pass = true;
        if(MiddleObject.Refund_Amount__c == null )
        { 
            MiddleObject.Refund_Amount__c.addError('Required.');
            pass = false;
        }
        if(MiddleObject.Refund_Quantity__c == null)
        {
            MiddleObject.Refund_Quantity__c.addError('Required.');
            pass = false;
        }
        if(MiddleObject.Refund_date_China__c == null)
        {
            MiddleObject.Refund_date_China__c.addError('Required');
            pass = false;
        }
        if(MiddleStudentActual.RefundType__c == null || MiddleStudentActual.RefundType__c == '')
        {
            MiddleStudentActual.RefundType__c.addError('Required');
            pass = false;
        }
        return pass;
    }
    
    // Create RefundInfo object for storing refund information.
    private void createRefundInfo()
    { 
        Decimal currentRefundAmount = (currentStudentProduct.Refund_Amount__c == null) ? 0 : currentStudentProduct.Refund_Amount__c;
        tempRefundInfo = (tempRefundInfo == null) ? (new RefundInfo()) : tempRefundInfo;
        tempRefundInfo.refundAmount = currentRefundAmount + MiddleObject.Refund_Amount__c;
        tempRefundInfo.quantity = MiddleObject.Refund_Quantity__c;
        tempRefundInfo.refundDate = MiddleObject.Refund_date_China__c;
        tempRefundInfo.refundType = MiddleStudentActual.RefundType__c;
    }

    // check whether CNRefundTotal__c equals to RefundAmount__c. 
    private Boolean compareRefundAmount()
    {
        Decimal cnRefundTotal = (currentStudentProduct.StudentActual__r.CNRefundTotal__c == null) ? 0 : currentStudentProduct.StudentActual__r.CNRefundTotal__c;
        Decimal oldRefundAmount = (currentStudentProduct.StudentActual__r.RefundAmount__c == null) ? 0 : currentStudentProduct.StudentActual__r.RefundAmount__c;
        Decimal currentRefundAmount = oldRefundAmount + MiddleObject.Refund_Amount__c;
        if(cnRefundTotal != currentRefundAmount)
        {
            return false;
        }
        else
        {
            return true;
        }
    }
     
    private void save()
    { 
        currentStudentProduct.Refund_Amount__c = tempRefundInfo.refundAmount;
        currentStudentProduct.Refund_date_China__c = tempRefundInfo.refundDate;
        currentStudentProduct.Refund_Quantity__c = tempRefundInfo.quantity;
        Savepoint sp;
        try
        { 
            if(currentStudentProduct.Product__r.Family != 'Smart Non-Standard Product List')
            {
                if(isNeedCallEtownService())
                {
                    EtownCourseService.EtownInactivateResult refundResult = requestEtownService();
                    if(refundResult != null && refundResult.IsSuccess)
                    {
                        sp = Database.setSavepoint();
                        updateStatusNeedCallEtown(); // update student actuals & products, course reschedules status.
                    }
                    else
                    { 
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ((refundResult == null)? 'Server Error' : refundResult.ErrorMessage)));
                        return;
                    }
                }  
                else     
                {
                    sp = Database.setSavepoint();
                    updateStatusNotNeedCallEtown(); // update current student product & actual.
                }
            }
            else
            {
                if(currentStudentProduct.Product__r.Name == 'Cross Center Booking')
                {
                    if(currentStudentProduct.Status__c == 'Activated')
                    {
                        terminateCCBProduct(currentStudentProduct);
                    }
                    currentStudentProduct.Status__c = 'Closed';
                }
                sp = Database.setSavepoint();
                update currentStudentProduct;
                update new StudentActual__c(Id = currentStudentProduct.StudentActual__c, RefundType__c = tempRefundInfo.refundType);
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            if(ex.getTypeName() == 'DMLException')
            {
                Database.rollback(sp);
            }
            return;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Refund successful.<script type="text/javascript">opener.location.reload();closeWindow();</script>'));
    }
    
    // updates status of student actual and student product if it not needs to call etown
    private void updateStatusNotNeedCallEtown()
    {
        currentStudentProduct.Status__c = 'Closed';   
        update currentStudentProduct;
        update new StudentActual__c(Id = currentStudentProduct.StudentActual__c, Status__c = 'Closed', RefundType__c = tempRefundInfo.refundType);
    }

    // updates status of student actual and student product if it needs to call etown
    private void updateStatusNeedCallEtown()
    {
        List<StudentActual__c> updatingStudentActuals = new List<StudentActual__c>();
        List<StudentProduct__c> updatingStudentProducts = new List<StudentProduct__c>();
        StudentActual__c currentStudentActual = new StudentActual__c(Id = currentStudentProduct.StudentActual__c, Status__c = 'Closed', RefundType__c = tempRefundInfo.refundType, OrderEndDate__c = tempRefundInfo.refundDate);
        updatingStudentActuals.add(currentStudentActual);
        currentStudentProduct.Status__c = 'Closed';
        updatingStudentProducts.add(currentStudentProduct);
        List<StudentActual__c> studentActuals = [select Id, Status__c, CourseActivationDate__c, OrderEndDate__c, (select Id, Status__c from StudentProducts__r where (Status__c = 'Activated' or Status__c = 'Suspended') and Product__c != null and (Product__r.family != 'Smart Non-Standard Product List')) from StudentActual__c where (Status__c = 'Activated' or Status__c = 'Suspended') and Student__c = :currentStudentProduct.StudentActual__r.Student__c and Id != :currentStudentProduct.StudentActual__c];
        for(StudentActual__c studentActual : studentActuals)
        {
            studentActual.OrderEndDate__c = tempRefundInfo.refundDate;
            studentActual.Status__c = 'Closed';
            updatingStudentActuals.add(studentActual);
            List<StudentProduct__c> studentProducts = studentActual.StudentProducts__r;
            for(StudentProduct__c studentProduct : studentProducts)
            {
                studentProduct.Status__c = 'Closed';
                updatingStudentProducts.add(studentProduct);
            }
        }
        update updatingStudentActuals;
        update updatingStudentProducts;
        updateCourseResheduleStatus();
    }

    private void updateCourseResheduleStatus()
    {
        List<CourseReschedule__c> updatingCourseReschedules  = new List<CourseReschedule__c>();
        List<CourseReschedule__c> courseReschedules = [select Id, Status__c, ScheduleDate__c, Type__c from CourseReschedule__c where Contact__c = :currentStudentProduct.StudentActual__r.Student__c order by CreatedDate];
        if(courseReschedules.size() > 0)
        {
            for(Integer i = 0; i < courseReschedules.size(); i++)
            {
                if(Math.Mod(i, 2) == 0 && (i + 1 < courseReschedules.size()))
                {
                    if((courseReschedules[i].Status__c == 'Completed' && courseReschedules[i].Type__c == 'Suspend' && courseReschedules[i+1].Status__c == 'Not start yet' && courseReschedules[i+1].Type__c == 'Resume') || (courseReschedules[i].Status__c == 'Not start yet' && courseReschedules[i].Type__c == 'Suspend' && courseReschedules[i+1].Status__c == 'Not start yet' && courseReschedules[i+1].Type__c == 'Resume'))
                    {
                        courseReschedules[i].Status__c = 'Closed';
                        courseReschedules[i+1].Status__c = 'Closed';
                        updatingCourseReschedules.add(courseReschedules[i]);
                        updatingCourseReschedules.add(courseReschedules[i+1]);
                    }
                }
            } 
        }
        update updatingCourseReschedules;   
    }
    
    private static String getCurrentContactStatusFromEtown(String etownUserName)
    {
        String currentStatus;
        if(etownUserName != null && etownUserName != '')
        {
            EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
            params.Username = etownUserName;
            params.RequireSyncReschedule = true;
            EtownCourseService.EtownLoadStudentResult result;
            try
            { 
                result = EtownCourseService.loadStudentInEtown(params);
            }
            catch(Exception ex)
            {
                throw(ex);
            }
            if(result != null && result.MemberInfo != null && result.IsSuccess)
            {
                EtownCourseService.EtownMemberInfo memberInfo = result.MemberInfo;
                currentStatus = memberInfo.Status;
            }
            else
            {
                throw new RefundProductException('Failed to refund, invalid Etown status.' + result.ErrorMessage);
            }
        }
        return currentStatus;
    }

    private Boolean isNeedCallEtownService()
    {
        Boolean result = false;
        String latestContactStatus = getCurrentContactStatusFromEtown(currentStudentProduct.StudentActual__r.Student__r.EtownUserName__c);
        String currentStudentActualStatus = currentStudentProduct.StudentActual__r.Status__c;
        if(currentStudentActualStatus == 'Suspended' || (currentStudentActualStatus == 'Activated' && (latestContactStatus == 'Suspended' || latestContactStatus == 'Active')))
        {
            if(currentStudentProduct.StudentActual__r.Student__r.EtownUserName__c != null && currentStudentProduct.StudentActual__r.Student__r.EtownUserName__c != '')
            {
                result = true;
            }
            else
            {
                throw new RefundProductException('Failed to refund, the user name is null!');
            }
        }
        else if(currentStudentActualStatus == 'Error')
        {
            throw new RefundProductException('Failed to refund, status of student actual is error.');
        }
        else
        {
            result = false;
        }
        return result;
    }
    
    // A web service method used to request Etown
    private EtownCourseService.EtownInactivateResult requestEtownService()
    {
        EtownCourseService.EtownInactivateParams params = new EtownCourseService.EtownInactivateParams();
        if(currentStudentProduct.StudentActual__r.Student__r.EtownMemberId__c != null)
        {
            params.MemberId = Integer.valueOf(currentStudentProduct.StudentActual__r.Student__r.EtownMemberId__c);
        }
        EtownCourseService.EtownInactivateResult result = null;
        try
        {
            result = EtownCourseService.inactivateInEtown(params);
        }
        catch(Exception ex)
        {
            throw new RefundProductException('Failed to refund the student product from Etown, the error message is: ' + ex.getMessage());
        }
        return result;
    }
    
    // This method for terminating Cross Center Booking product.
    private void terminateCCBProduct(StudentProduct__c studentProduct)
    {
        if(studentProduct != null)
        {  
            loginOboeEtownService();
            EtownServiceDataContract.TerminateProductParam param = new EtownServiceDataContract.TerminateProductParam();
            param.CommerceProduct = studentProduct.Product__r.RedemptionCode__c;
            try
            {
                param.MemberID = StudentProduct.StudentActual__r.Student__r.EtownMemberId__c.intValue();
            }
            catch(Exception ex)
            {
                ex.setMessage('Invalid value. Please check the value of Etown Member Id');
                throw ex;
            }
            if(studentProduct.StudentActual__c != null)
            {
                String studentActualId = studentProduct.StudentActual__c;
                param.Salesforce_id = (studentActualId.length() > 15) ? studentActualId.subString(0, 15) : studentActualId;
                param.SchoolName = ETownServiceHelper.translateDivisionCode(studentProduct.StudentActual__r.EntryCenter__c);
            }
           
            List<EtownServiceDataContract.CrossCenterBookingInfo> CrossCenterBookingInfoList = new List<EtownServiceDataContract.CrossCenterBookingInfo>();
            List<Map<String, Integer>> schoolCodeAndCityIdMapList = EtownServiceHelper.getSchoolCodeAndCityId(StudentProduct.BookingCenters__c);
            if(schoolCodeAndCityIdMapList != null)
            {   
                for(Map<String, Integer> schoolCodeAndCityIdMap : schoolCodeAndCityIdMapList)
                {
                    EtownServiceDataContract.CrossCenterBookingInfo tempBookingInfo;
                    if(schoolCodeAndCityIdMap.get('CityId') != null)
                    {
                        tempBookingInfo = new EtownServiceDataContract.CrossCenterBookingInfo();
                        tempBookingInfo.City_id = schoolCodeAndCityIdMap.get('CityId');
                        tempBookingInfo.Duration = (studentProduct.Quantity__c != null) ? studentProduct.Quantity__c.intValue() : 0;
                    }
                    else if(schoolCodeAndCityIdMap.get('SchoolCode') != null)
                    {
                        tempBookingInfo = new EtownServiceDataContract.CrossCenterBookingInfo();
                        tempBookingInfo.City_id = -1;
                        tempBookingInfo.Duration = (studentProduct.Quantity__c != null) ? studentProduct.Quantity__c.intValue() : 0;
                        tempBookingInfo.SchoolCode = String.valueOf(schoolCodeAndCityIdMap.get('SchoolCode'));
                    }
                    if(tempBookingInfo != null)
                    {
                        CrossCenterBookingInfoList.add(tempBookingInfo);
                    }
                }
            }
            param.CrossCenterBookingParam = new EtownServiceDataContract.CrossCenterBookingParams();
            param.CrossCenterBookingParam.Info = new EtownServiceDataContract.ArrayOfCrossCenterBookingInfo();
            param.CrossCenterBookingParam.info.CrossCenterBookingInfo = CrossCenterBookingInfoList;
            EtownServiceDataContract.ExternalAppInfo appInfo = new EtownServiceDataContract.ExternalAppInfo();
            appInfo.ExternalUserId = UserInfo.getUserId();
            appInfo.ExternalAppCode = 'Salesforce';
            EtownServiceDataContract.TerminateProductResult result = new EtownServiceDataContract.TerminateProductResult();
            String utcTokenDate = DateTime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            String securityToken = EtownServiceHelper.getSecurityToken(String.valueOf(param.MemberID), utcTokenDate);
           
            try
            {
                if(!Test.isRunningTest())
                {
                    result = service.TerminateProduct(appInfo, param, securityToken, utcTokenDate);  
                }  
            }
            catch(Exception ex)
            {
                throw new TerminateCCBProductException(ex.getMessage()); 
            }
           
            if(result.Success != true)
            {
                throw new TerminateCCBProductException('Terminate CCB product failed. \r\nError Message:' + result.ErrorMessage);
            }
       }
    }
    
    private static void loginOboeEtownService()
    {
        service = new EtownServiceStub.BasicHttpBinding_ISalesForceService();
        service.endpoint_x = EtownServer__c.getInstance('Oboe server').Url__c;
        service.timeout_x = 120 * 1000;   //2 minutes
        EtownServiceToken.UsernameToken_element token = new EtownServiceToken.UsernameToken_element();
        token.Username = oboeUsername;
        token.Password = oboePassword;
        EtownServiceToken.Security_element security = new EtownServiceToken.Security_element();
        security.UsernameToken = token;
        service.Security = security;
    }
    
    public class RefundInfo
    {
        Decimal refundAmount;
        Date refundDate;
        String refundType;
        Decimal quantity;
        
        public RefundInfo(){}
    }
    
    public class TerminateCCBProductException extends Exception{}
    public class RefundProductException extends Exception{}
    
    @isTest
    static void testRefund()
    {
        Actual__c actual = new Actual__c();
        insert actual;
        Contact contact = new Contact(EtownMemberId__c = 124608, Lastname = 'test name', EtownUserName__c = 'Etown');
        insert contact;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, CNRefundTotal__c = 23, Student__c = contact.Id);
        insert studentActual;
        StudentProduct__c studentProduct = new StudentProduct__c(Name = 'test', StudentActual__c = studentActual.Id, Price__c = 9999, Quantity__c = 1);
        insert studentProduct;
        PageReference testPage = new PageReference('/apex/StudentProductRefundDialog?id=' + studentProduct.Id);
        Test.setCurrentPage(testPage);
        StudentProductRefundDialogController controller = new StudentProductRefundDialogController();
        controller.refund();
        controller.MiddleObject.Refund_Amount__c = 3216;
        controller.MiddleObject.Refund_Quantity__c = 7;
        controller.MiddleObject.Refund_date_China__c = Date.today();
        controller.MiddleStudentActual.RefundType__c = 'Full Refund';
        controller.refund();
        controller.confirm();
        System.assertEquals('Full Refund', [select Id, RefundType__c from StudentActual__c where Id = :studentActual.Id].RefundType__c);
        StudentProduct__c studentProduct3 = [select Id, Refund_Amount__c, Refund_Quantity__c, Refund_date_China__c from StudentProduct__c where Id = :studentProduct.Id];
        System.assertEquals(3216, studentProduct3.Refund_Amount__c);
        System.assertEquals(7, studentProduct3.Refund_Quantity__c);
        System.assertEquals(Date.today(), studentProduct3.Refund_date_China__c);
    }
    
    @isTest
    static void testRefundCcbProduct()
    {
        Actual__c actual = new Actual__c();
        insert actual;
        Contact contact = new Contact(EtownMemberId__c = 1208, Lastname = 'test EF name', EtownUserName__c = 'EtownName');
        insert contact;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, CNRefundTotal__c = 23, Student__c = contact.Id);
        insert studentActual;
        Product2 ccbProd = new Product2(Name = 'Cross Center Booking', Family = 'Smart Non-Standard Product List');
        insert ccbProd;
        StudentProduct__c studentProduct = new StudentProduct__c(Name = 'Cross Center Booking', Price__c = 9999, Status__c = 'Activated', Quantity__c = 1, Product__c = ccbProd.Id, StudentActual__c = studentActual.Id, BookingCenters__c = 'SH All;BJ DWL;BJ DZM;SZ All');
        insert studentProduct;
        PageReference testPage = new PageReference('/apex/StudentProductRefundDialog?id=' + studentProduct.Id);
        Test.setCurrentPage(testPage);
        StudentProductRefundDialogController controller = new StudentProductRefundDialogController();
        controller.refund();
        controller.MiddleObject.Refund_Amount__c = 3216;
        controller.MiddleObject.Refund_Quantity__c = 7;
        controller.MiddleObject.Refund_date_China__c = Date.today();
        controller.MiddleStudentActual.RefundType__c = 'Full Refund';
        controller.refund();   
        controller.save();
    }
    
    @isTest 
    static void testRefundMainProduct()
    {
        Actual__c actual = new Actual__c();
        insert actual;
        Contact contact = new Contact(EtownMemberId__c = 453612, Lastname = 'testname', Status__c = 'Suspended', EtownUserName__c = 'testEF');
        insert contact;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, Student__c = contact.Id, Status__c = 'Activated');
        insert studentActual;
        Product2 mainProd = new Product2(Name='Home');
        insert mainProd;
        StudentProduct__c stuProduct = new StudentProduct__c(Name = 'main product', Price__c = 8888, Status__c = 'Activated', Quantity__c = 1, Product__c = mainProd.Id, StudentActual__c = studentActual.Id);
        insert stuProduct;
        List<CourseReschedule__c> courseReschedules = new List<CourseReschedule__c>{
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Completed', Type__c = 'Suspend', ScheduleDate__c = Date.today()),
            new CourseReschedule__c(Contact__c = contact.Id, Status__c = 'Not Start yet', Type__c = 'Resume', ScheduleDate__c = Date.today().addDays(7))
        };
        insert courseReschedules;
        PageReference testMainProducrPage = new PageReference('/apex/StudentProductRefundDialog?id=' + stuProduct.Id);
        Test.setCurrentPage(testMainProducrPage);
        StudentProductRefundDialogController controller = new StudentProductRefundDialogController();
        List<StudentProduct__c> studentProducts = [select Id, Name, Amount__c, Status__c, Quantity__c, BookingCenters__c, Refund_Amount__c, Product__r.Family, Product__r.Name, Product__r.RedemptionCode__c, Refund_date_China__c, Refund_Quantity__c, StudentActual__c, StudentActual__r.RefundType__c, StudentActual__r.RefundAmount__c, StudentActual__r.CNRefundTotal__c, StudentActual__r.Student__c, StudentActual__r.OrderStartDate__c, StudentActual__r.OrderEndDate__c, StudentActual__r.Status__c, StudentActual__r.Student__r.EtownUserName__c, StudentActual__r.Student__r.EtownMemberId__c from StudentProduct__c where Id = :stuProduct.Id limit 1];
        controller.refund();
        controller.save();
        controller.updateStatusNeedCallEtown();
    }
}