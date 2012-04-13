/*
 * A button "Activate Course" on StudentActual will invoke the service in this class
 * This service passes course information to ETown server.
 */ 
global class ActivateCourseService 
{
    //for old activation course interface  
    private static EtownServiceStub.BasicHttpBinding_ISalesForceService service;
    private static final String oboeUsername = 'SalesforceSmartUser';
    private static final String oboePassword = 'SalesforceSmartPwd';
                    
    webService static String activateCourse(String studentActualId) 
    {
        String resultMessage = '';
       
        List<StudentActual__c> studentActuals = [select Id, Student__c, CreatedDate, orderId__c, EliteCard__c, EntryCenter__c, Status__c, StartingLevel__c, LevelInherited__c, 
                                                    (select Id, Name, BookingCenters__c, Quantity__c, Status__c, Product__r.RedemptionCode__c, Product__r.AdditionalRedemptionCode__c, 
                                                    Product__r.Name, Product__r.Family, Product__r.IsLevel__c, Product__r.EtownId__c, LevelsPurchased__c, FreeLength__c, 
                                                    Freelevels__c, MarketingLength__c, StandardLength__c, ProductLength__c from StudentProducts__r 
                                                    where Product__r.IsActivable__c = true and Status__c not in ('Activated','Suspended', 'Expired')), 
                                                Actual__r.Sales_Appt_Locations_2__c, Actual__r.China_Sales_Type__c, Actual__r.CreatedDate, Actual__r.Close_Date__c, 
                                                Student__r.EtownUserName__c, Student__r.EtownMemberId__c, Student__r.Status__c from StudentActual__c 
                                                where Id = :studentActualId limit 1];

        if(studentActuals.size() > 0)
        {
            StudentActual__c currentStudentActual = studentActuals[0];
            List<StudentProduct__c> mainStudentProducts = new List<StudentProduct__c>();
            List<StudentProduct__c> viceStudentProducts = new List<StudentProduct__c>();
            for(StudentProduct__c studentProduct : currentStudentActual.StudentProducts__r)
            {
                if(studentProduct.Product__r.Family != null && studentProduct.Product__r.Family != 'Smart Non-Standard Product List')
                {
                    mainStudentProducts.add(studentProduct);
                }
                else if(studentProduct.Product__r.Family == 'Smart Non-Standard Product List') //Is Activateable = true, only are OnlinePL and CCB(Cross Center Booking)
                {
                    viceStudentProducts.add(studentProduct);
                }
            }
            if(mainStudentProducts.size() > 0 || viceStudentProducts.size() > 0)
            {
                try
                {
                    validateStudentActualInfo(currentStudentActual);
                    resultMessage = activateProduct(mainStudentProducts, viceStudentProducts, currentStudentActual);
                }
                catch(Exception ex)
                {
                    resultMessage = ex.getMessage();
                }
            }
            else
            {
                resultMessage = 'No inactive product was selected. Cannot activate the course.';
            }
        }
        return resultMessage;
    }
    
    private static String activateProduct(List<StudentProduct__c> mainStudentProducts, List<StudentProduct__c> viceStudentProducts, StudentActual__c currentStudentActual)
    {
        String resultMessage = '';
        Boolean hasErrorOccured = false;
        //Stores products that has been activated.
        List<StudentProduct__c> activePorducts = new List<StudentProduct__c>(); 
        
        //add by gerald 2011-1-1 to update Elite card on current Contact
        Contact currentContact = new Contact(Id = currentStudentActual.Student__c);
         
        //handel result of active main products
        if(mainStudentProducts.size() > 0)  
        {
            try
            {
                validateMainProductInfo(mainStudentProducts, currentStudentActual);
                ActivationResult mainProductResult = activateMainProduct(mainStudentProducts, currentStudentActual);
                
                if(mainProductResult.IsSuccess)
                {
                    currentStudentActual.Status__c = 'Activated';
                    currentStudentActual.OrderId__c = mainProductResult.OrderId;
                    currentStudentActual.CourseActivationDate__c = Date.today();
                    currentStudentActual.OrderStartDate__c = mainProductResult.OrderStartDate;
                    currentStudentActual.OrderEndDate__c = mainProductResult.OrderEndDate;
                    if(currentStudentActual.StartingLevel__c == null)
                    {
                        currentStudentActual.LevelInherited__c = true; //not need to set starting level
                    }
                    activePorducts.addAll(mainProductResult.ActiveStudentProducts);
                    
                    //add by gerald 2011-1-1 to update Elite card on current Contact
                    currentContact.EliteCard__c = currentStudentActual.EliteCard__c;
                }
                else //error occured while call Etown service
                {
                    hasErrorOccured = true;
                    currentStudentActual.Status__c = 'Error';
                    update currentStudentActual; //set current student actual's status to error
                    resultMessage = 'Activating failed, please contact system administrator.\n' + mainProductResult.ErrorMessage + 
                                    '. The error product name: ' + mainProductResult.ErrorProduct.Name;
                    handleEtownErrorMsg(mainProductResult);
                }
            }
            catch(Exception ex)//SF validate rule error 
            {
                hasErrorOccured = true;
                resultMessage = ex.getMessage();
            }
        }
        
        //handel result of activate vice products
        if((mainStudentProducts.size() == 0 || !hasErrorOccured) && viceStudentProducts.size() > 0)
        {
            ActivationResult plProductResult;
            try
            {
                plProductResult = activateViceProduct(viceStudentProducts, currentStudentActual);
                if(plProductResult.IsSuccess)
                {
                    currentStudentActual.Status__c = 'Activated';
                    activePorducts.addAll(plProductResult.ActiveStudentProducts);
                }
            }
            catch(Exception ex)
            {
                hasErrorOccured = true;
                currentStudentActual.Status__c = 'Error';
                resultMessage = ex.getMessage();
            }
        }
        
        if(activePorducts.size() > 0)
        {
            update activePorducts;
            update currentStudentActual;
            update currentContact;
        }
        if(!hasErrorOccured)
        {
            resultMessage = 'Activated successfully.';
        }
        return resultMessage;
    }
    
    private static ActivationResult activateMainProduct(List<StudentProduct__c> mainProducts, StudentActual__c currentStudentActual)
    {
        ActivationResult result = new ActivationResult();
        if(mainProducts.size() == 1)
        {   
            StudentProduct__c mainStudentProduct = mainProducts[0];
            //call the Etown webservice to activate course  
            result = transferInfomatinToEtown(currentStudentActual, mainStudentProduct);
            if(result != null && result.IsSuccess)
            {
                mainStudentProduct.Status__c = 'Activated';
                mainStudentProduct.CourseActivationDate__c = Date.today();
                result.ActiveStudentProducts.add(mainStudentProduct);
            }
            else
            {
                result.ErrorProduct = mainStudentProduct;
            }
        }
        return result; 
    }
    
    private static ActivationResult activateViceProduct(List<StudentProduct__c> viceProductList, StudentActual__c tempStudentActual)
    {
        ActivationResult result = new ActivationResult();
        for(StudentProduct__c studentProduct : viceProductList)
        {
            if(studentProduct.Status__c == 'Activated')
            {
                continue;
            }
            if(studentProduct.Status__c == 'Error')
            {
                throw new ActivationException('Activating failed, Student product name: ' + StudentProduct.Name + ', please contact system administrator.');
            }
            Boolean isSuccess;
            try
            {
                loginOboeEtownService(); //for old WebService infterface
                
                if(studentProduct.Product__r.Name == 'Cross Center Booking')
                {
                     isSuccess = createCCBAccountToEtown(tempStudentActual, studentProduct); 
                }
                else
                {
                     isSuccess = createPlAccountToEtown(tempStudentActual, studentProduct);
                }
                 
                if(isSuccess)
                {
                    studentProduct.Status__c = 'Activated';
                    studentProduct.CourseActivationDate__c = Date.today();
                    result.IsSuccess = true;
                    result.ActiveStudentProducts.add(studentProduct);
                }
            }
            catch(Exception ex)
            {
                result.IsSuccess = false;
                result.ErrorProduct = studentProduct;
                throw ex;
            }
        }
        return result;
    }
    
    private static ActivationResult transferInfomatinToEtown(StudentActual__c studentActual, StudentProduct__c studentProduct)
    {
        ActivationResult result;
        if(studentActual != null && studentActual.Student__r != null && studentProduct != null && studentProduct.Product__c != null)
        {
            Boolean isLevelProduct = studentProduct.Product__r.IsLevel__c;
            TransferInfo info;
            if(isLevelProduct == true)
            {
                info = getTransferInfo(studentActual, studentProduct, ProductType.LEVEL);
            }
            else
            { 
                info = getTransferInfo(studentActual, studentProduct, ProductType.LENGTH);
            }
            //call Etown method to activate course
            result = createMainAccountToEtown(info);
        }
        return result;
    }
    
    //posts acitve information to Etown 
    private static ActivationResult createMainAccountToEtown(TransferInfo info)
    {
        ActivationResult activeResult = new ActivationResult();
        if(info != null)
        {
            EtownCourseService.EtownActivateParams params = setActiveInfo2Etwon(info);
            try
            {
                EtownCourseService.EtownActivateResult result = EtownCourseService.activateInEtown(params);
                if(result != null)
                {
                    if(result.IsSuccess)
                    {
                        activeResult.IsSuccess = result.IsSuccess;
                        activeResult.OrderStartDate = result.OrderStartDate;
                        activeResult.OrderEndDate = result.OrderEndDate;
                        activeResult.OrderId = result.OrderId;
                    }
                    else
                    {
                        activeResult.TransferInfoDetail = info.getDetail();
                        String errorMsg = 'Etown Error - ';
                        errorMsg += (result.ErrorCode != null) ? ('Error Code: ' + result.ErrorCode) : '';
                        errorMsg += (result.ErrorMessage != null) ? ('Error Message: ' + result.ErrorMessage) : '';
                        activeResult.ErrorMessage = errorMsg;
                    }
                }
            }
            catch(Exception ex)
            {
                activeResult.TransferInfoDetail = info.getDetail();
                activeResult.ErrorMessage = ex.getMessage().toLowerCase();
            }
        }
        return activeResult;
    }
    
    private static Boolean createPlAccountToEtown(StudentActual__c studentActual, StudentProduct__c studentProduct)
    {
        if(studentActual != null && studentProduct != null)
        { 
            EtownServiceDataContract.SellProductToStudentParam sellProductParam = new EtownServiceDataContract.SellProductToStudentParam();
            sellProductParam.CommerceProduct = studentProduct.Product__r.RedemptionCode__c; 
            try
            {
                sellProductParam.MemberID = studentActual.Student__r.EtownMemberId__c.intValue();
            }
            catch(Exception ex)
            {
                ex.setMessage('Invalid value. Please check the value of Etown Member Id.');
                throw ex;
            }
            sellProductParam.Qty = studentProduct.Quantity__c.intValue();
            sellProductParam.SchoolName = ETownServiceHelper.translateDivisionCode(studentActual.EntryCenter__c);
            
            String utcTokenDate = DateTime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            String securityToken = EtownServiceHelper.getSecurityToken(String.valueOf(sellProductParam.MemberID), utcTokenDate);
            EtownServiceDataContract.ExternalAppInfo appInfo = new EtownServiceDataContract.ExternalAppInfo();
            appInfo.ExternalUserId = UserInfo.getUserId();
            appInfo.ExternalAppCode = 'Salesforce';
            EtownServiceDataContract.SellProductToStudentResult result;
            try
            {
                result = service.SellProductToStudent(appInfo, sellProductParam, securityToken, utcTokenDate);
            }
            catch(Exception ex)
            {
                String exMessage = ex.getMessage().toLowerCase();
                if(exMessage.contains('time out') || exMessage.contains('timeout') || exMessage.contains('timed out'))
                {
                    setErrorStatus(studentProduct.Id);
                    String detail = 'Student Actual Id = ' + studentActual.Id + '\r\nStudent Product Id = ' + studentProduct.Id + '\r\n';
                    sendErrorEmail(detail, exMessage);
                    throw new ActivationException(exMessage);
                }
                throw ex;
            }
            
            if(result.Success == true)
            {
                return true;
            }
            else
            {
                setErrorStatus(studentProduct.Id);
                String detail = 'Student Actual Id = ' + studentActual.Id + '\r\nStudent Product Id = ' + studentProduct.Id + '\r\n';
                String errorMessage = '\r\nError Code = ' + result.ErrorCode + '\r\nError Message = ' + ((result.ErrorMessage == null) ? '' : result.ErrorMessage);
                sendErrorEmail(detail, errorMessage);
                throw new ActivationException('Activating failed, please contact system administrator.\n' + errorMessage + '. \r\nProduct Name: ' + StudentProduct.Name);
            }
        }
        return null;
    }
    
    private static Boolean createCCBAccountToEtown(StudentActual__c studentActual, StudentProduct__c studentProduct)
    {
        if(studentActual != null && studentProduct != null)
        {
            EtownServiceDataContract.SellProductToStudentParam sellProductParam = new EtownServiceDataContract.SellProductToStudentParam();
            sellProductParam.CommerceProduct = studentProduct.Product__r.RedemptionCode__c; // This value should be 'CCB' => 2.
            try
            {
                sellProductParam.MemberID = studentActual.Student__r.EtownMemberId__c.intValue();
            }
            catch(Exception ex)
            {
                ex.setMessage('Invalid value. Please check the value of Etown Member Id.');
                throw ex;
            }
            
            String studentActualId = studentActual.Id;
            sellProductParam.Salesforce_id = (studentActualId.length() > 15) ? studentActualId.subString(0, 15) : studentActualId;
            sellProductParam.SchoolName = ETownServiceHelper.translateDivisionCode(studentActual.EntryCenter__c);

            sellProductParam.CrossCenterBookingParam = new EtownServiceDataContract.CrossCenterBookingParams(); 
            sellProductParam.CrossCenterBookingParam.info = new EtownServiceDataContract.ArrayOfCrossCenterBookingInfo();
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
            sellProductParam.CrossCenterBookingParam.info.CrossCenterBookingInfo = CrossCenterBookingInfoList;
            EtownServiceDataContract.ExternalAppInfo appInfo = new EtownServiceDataContract.ExternalAppInfo();
            appInfo.ExternalUserId = UserInfo.getUserId();
            appInfo.ExternalAppCode = 'Salesforce';
            String utcTokenDate = DateTime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
            String securityToken = EtownServiceHelper.getSecurityToken(String.valueOf(sellProductParam.MemberID), utcTokenDate);
            EtownServiceDataContract.SellProductToStudentResult result;
            
            try
            {
                result = service.SellProductToStudent(appInfo, sellProductParam, securityToken, utcTokenDate);
            }
            catch(Exception ex)
            {
                String exMessage = ex.getMessage().toLowerCase();
                if(exMessage.contains('time out') || exMessage.contains('timeout') || exMessage.contains('timed out'))
                {
                    setErrorStatus(studentProduct.Id);
                    String detail = 'Student Actual Id = ' + studentActual.Id + '\r\nStudent Product Id = ' + studentProduct.Id + '\r\n';
                    sendErrorEmail(detail, exMessage);
                    throw new ActivationException(exMessage);
                }
                throw ex;
            }
            if(result.Success == true)
            {
                return true;
            }
            else
            {
                setErrorStatus(studentProduct.Id);
                String detail = 'Student Actual Id = ' + studentActual.Id + '\r\nStudent Product Id = ' + studentProduct.Id + '\r\n';
                String errorMessage = '\r\nError Code = ' + result.ErrorCode + '\r\nError Message = ' + ((result.ErrorMessage == null) ? '' : result.ErrorMessage);
                sendErrorEmail(detail, errorMessage);
                throw new ActivationException('Activating failed, please contact system administrator.\n' + errorMessage + '. \r\nProduct Name: ' + StudentProduct.Name);
            }
        }      
        return false; 
    }
    
    private static EtownCourseService.EtownActivateParams setActiveInfo2Etwon(TransferInfo info)
    {
        EtownCourseService.EtownActivateParams params = new EtownCourseService.EtownActivateParams();
        params.DivisionCode = info.DivisionCode;
        params.EliteCode = info.EliteCode;
        params.FreeRedemptionCode = info.FreeRedemptionCode;
        params.FreeRedemptionQty = info.FreeRedemptionQty;
        params.LevelQty = info.LevelQty;
        params.MainRedemptionCode = info.MainRedemptionCode;
        params.MainRedemptionQty = info.MainRedemptionQty;
        params.MemberId = info.MemberId;
        params.ProductId = info.ProductId;
        params.StartLevel = info.StartLevel;
        return params;
    }
    
    private static void handleEtownErrorMsg(ActivationResult errorResult)
    {
        if(errorResult != null)
        {
            StudentProduct__c errorProduct = errorResult.ErrorProduct;
            String errorMessage = errorResult.ErrorMessage;
            String transferDetailInfo = errorResult.TransferInfoDetail;
            setErrorStatus(errorProduct.Id); 
            sendErrorEmail('StudentProduct Name:' + errorProduct.Name + '\r\nStudentProduct Id:' + errorProduct.Id + '\r\n' + transferDetailInfo, errorMessage);
        }
    }
    
    private static void setErrorStatus(String StudentProductId)
    {
        StudentProduct__c sProduct = new StudentProduct__c(Id=StudentProductId, Status__c='Error');
        update sProduct;
    }
    
    private static void sendErrorEmail(String message, String errorMessage)
    {
        String subject = 'Failed to activate a course';
        String content = message + '\r\nThe error is:\r\n' + errorMessage;
        SendEmailHelper.sendExceptionEmail('SmartSF@ef.com', subject, content);
    }
    
    private static TransferInfo getTransferInfo(StudentActual__c studentActual, StudentProduct__c studentProduct, ProductType prodType)
    {
        TransferInfo info = new TransferInfo();
        Integer freeLength = (studentProduct.FreeLength__c != null) ? Integer.valueOf(studentProduct.FreeLength__c) : 0;
        Integer mktLength = (studentProduct.MarketingLength__c != null) ? Integer.valueOf(studentProduct.MarketingLength__c) : 0;
        Integer levelPruchased = (studentProduct.LevelsPurchased__c != null) ? Integer.valueOf(studentProduct.LevelsPurchased__c) : 0;
        Integer standardLength = (studentProduct.StandardLength__c != null) ? Integer.valueOf(studentProduct.StandardLength__c) : 0;
        Integer freeLevel = (studentProduct.Freelevels__c != null) ? Integer.valueOf(studentProduct.Freelevels__c) : 0;
        
        info.MemberId = studentActual.Student__r.EtownMemberId__c.intValue();
        info.EliteCode = studentActual.EliteCard__c;
        info.DivisionCode = ETownServiceHelper.translateDivisionCode(studentActual.EntryCenter__c);
        info.ProductId = (studentProduct.Product__r.EtownId__c != null) ? Integer.valueOf(studentProduct.Product__r.EtownId__c) : null;
        info.StartLevel = EtownServiceHelper.getLevelCode(studentActual.StartingLevel__c); 
        info.MainRedemptionCode = studentProduct.Product__r.RedemptionCode__c;
        info.FreeRedemptionCode = studentProduct.Product__r.AdditionalRedemptionCode__c;
        if(prodType == ProductType.LENGTH)
        {
            info.MainRedemptionQty = standardLength;
            info.FreeRedemptionQty = freeLength + mktLength;
            info.LevelQty = 1;
        }
        else if(prodType == ProductType.LEVEL)
        {
            info.MainRedemptionQty = levelPruchased + freeLevel;
            info.FreeRedemptionQty = freeLength + mktLength;
            info.LevelQty = info.MainRedemptionQty;
        }
        return info;
    }

    private static void validateStudentActualInfo(StudentActual__c studentActual)
    {
        if(studentActual.Actual__r.Close_Date__c != null && studentActual.Actual__r.Close_Date__c > Date.today()) //Actual__c is required field
        {
            throw new ActivationException('You cannot activate the product before invoice date.');
        }
        //if 'Sales Type' = 'Double pay'.
        if(studentActual.Actual__r.China_Sales_Type__c == 'Double Pay')
        {
            throw new ActivationException('Activating failed, the sales type value is Double Pay.');
        }
        if(studentActual.Student__r == null || studentActual.Student__r.EtownMemberId__c == null)
        {
            throw new ActivationException('Please check the value of student\'s Etown Member Id.');
        }
        
        //the following validate rules also in the "activate course" button
        if(studentActual.Status__c == 'Activated')
        {
            throw new ActivationException('The course has already been Activated. You can\'t do that again.');
        }
        if(studentActual.Status__c == 'Error')
        {
            throw new ActivationException('There was an error in the previous activating operation, please contact system administrator.');
        }
    }
    
    private static void validateMainProductInfo(List<StudentProduct__c> mainProducts, StudentActual__c studentActual)
    {
        if(mainProducts.size() > 1)
        {
            throw new ActivationException('There are more than one main product found. Cannot activate the course.');
        }
        else if(mainProducts.size() == 1)
        {   
            StudentProduct__c mainProduct = mainProducts[0];
            if(studentActual.EliteCard__c == null)
            {
                throw new ActivationException('Elite card # can\'t be null.');
            }
            if(mainProduct.Status__c == 'Error')
            {
                throw new ActivationException('Activating failed, please contact system administrator. The error product name: ' + mainProduct.Name);
            }
            if(mainProduct.Product__r != null && mainProduct.Product__r.EtownId__c != null)
            {
                if(!isNumberType(mainProduct.Product__r.EtownId__c))
                {
                     throw new ActivationException('Offline Package Id of the prodcut is invalid. Product Name: ' + mainProduct.Product__r.Name);
                }
            }
            
            EtownCourseHelper.CourseDataInfo dataInfo = EtownCourseHelper.parseStudentActual(studentActual.Id);
            if(dataInfo != null)
            {
                //validates weather need to set starting level
                if(isNeedToSetStartingLevel(dataInfo))
                {
                    throw new ActivationException('Please set starting level first.');
                }
                //When following actual is not with the same product type as the previous one, only when 1st actual has been expired or deactivated, then 2nd actual can be activated.
                if(dataInfo.CurrentStudentProduct != null && dataInfo.CurrentStudentProduct.Product__r != null && dataInfo.OlderStudentProduct != null && dataInfo.OlderStudentProduct.Product__r != null)
                {
                    if(!dataInfo.IsFirstSP && !isPreviousStudentExpired(dataInfo) && dataInfo.CurrentStudentProduct.Product__r.EtownId__c != dataInfo.OlderStudentProduct.Product__r.EtownId__c)
                    {   
                        throw new ActivationException('Student\'s current product must be expired in order to activate a new product.');
                    } 
                }
            }
        }
    }
    
    private static Boolean isNeedToSetStartingLevel(EtownCourseHelper.CourseDataInfo dataInfo)
    {
        Boolean result = false;
        if(dataInfo != null && (dataInfo.IsFirstSP || dataInfo.IsLength2Level || dataInfo.IsAlumniClub))
        {
            result = true;
        }
        return result;
    }
    
    private static Boolean isPreviousStudentExpired(EtownCourseHelper.CourseDataInfo dataInfo)
    {
        Boolean previousExpired = false;
        if(dataInfo.OlderStudentActual != null)
        {
            StudentActual__c olderStudentActual = dataInfo.OlderStudentActual;
            if(olderStudentActual.Student__r.Status__c != 'Active' && olderStudentActual.Student__r.Status__c != 'Suspended' && olderStudentActual.Student__r.Status__c != 'Suspend')
            {
                previousExpired = true;
            }
        }
        return previousExpired;
    }
    
    private static Boolean isNumberType(String parma)
    {
        Boolean result = true;
        if(parma != null)
        {
            try
            {
                Integer.valueOf(parma);
            }
            catch(Exception ex)
            {
                result = false;
            }
        }
        return result;
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
    
    public enum ProductType { LEVEL, LENGTH }
    
    public class ActivationException extends Exception { }
    
    public class ActivationResult
    {
        public ActivationResult()
        {
            IsSuccess = false;
            ActiveStudentProducts = new List<StudentProduct__c>();
        }
        
        public Boolean IsSuccess { get; set; }
        public Date OrderEndDate { get; set; }
        public Date OrderStartDate { get; set; }
        public Long OrderId { get; set; }
        public String ErrorMessage { get; set; }
        public String TransferInfoDetail { get; set; }  //this for email
        public StudentProduct__c ErrorProduct { get; set; }
        public List<StudentProduct__c> ActiveStudentProducts { get; set; }
    }
    
    public class TransferInfo
    {
        public Integer MemberId { get; set; }
        public String EliteCode { get; set; }
        public String DivisionCode { get; set; }
        public String FreeRedemptionCode { get; set; }
        public Integer FreeRedemptionQty { get; set; }
        public String MainRedemptionCode { get; set; }
        public Integer MainRedemptionQty { get; set; }
        public String StartLevel { get; set; }
        public Integer ProductId { get; set; }
        public Integer LevelQty { get; set; }
        
        public String getDetail()
        {
            String result = '';
            result += 'Member Id = ' + MemberId + '\r\n';
            result += 'Elite Code = ' + EliteCode + '\r\n';
            result += 'Division Code = ' + DivisionCode + '\r\n';
            result += 'Start Level = ' + StartLevel + '\r\n';
            result += 'Etown Product Id = ' + ProductId + '\r\n';
            result += 'Main Redemption Code = ' + MainRedemptionCode + '\r\n';
            result += 'Main Redemption Qty = ' + MainRedemptionQty + '\r\n';
            result += 'Free Redemption Code = ' + FreeRedemptionCode + '\r\n';
            result += 'Free Redemption Qty = ' + FreeRedemptionQty + '\r\n';
            result += 'Level Qty = ' + LevelQty + '\r\n';
            return result;
        } 
    }
    
    @isTest
    static void testAcivateCourse()
    {
        Account testCompany = new Account(Name = 'company acem');
        insert testCompany;
        Contact student = new Contact(LastName = 'acme1 name', AccountId = testCompany.Id, Email = 'acme@g.com', phone = '123456', EtownMemberId__c = 1122333, Status__c = 'Inactive');
        insert student;
        Actual__c testActual = new Actual__c(Account__c = testCompany.Id, China_Sales_Type__c = 'New');
        insert testActual;
        StudentActual__c studentActual = new StudentActual__c(Student__c = student.Id, Actual__c = testActual.Id, EliteCard__c = '1111', StartingLevel__c = 'Beginner-Level0A');
        insert studentActual;
        Product2 product = new Product2(Name = 'Alumni Club', EtownId__c = '9999999991', IsLevel__c = true, Family = 'Smart Product List', IsActivable__c = true);
        Product2 product2 = new Product2(Name = 'Onlie PL', EtownId__c = '9999999992', IsActivable__c = true, Family = 'Smart Non-Standard Product List');
        Product2 product3 = new Product2(Name = 'Cross Center Booking', EtownId__c = '9999999993', IsActivable__c = true, Family = 'Smart Non-Standard Product List');
        insert new Product2[]{ product, product2, product3 };
        StudentProduct__c studentProduct = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product.Id, LevelsPurchased__c = '3', FreeLength__c = '4', Quantity__c = 1);
        StudentProduct__c studentProduct2 = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product2.Id, Quantity__c = 1);
        insert new StudentProduct__c[]{ studentProduct, studentProduct2 };
        //main prodct and online PL product
        ActivateCourseService.activateCourse(studentActual.Id);
        
        StudentActual__c studentActual2 = new StudentActual__c(Student__c = student.Id, Actual__c = testActual.Id, EliteCard__c = '1111', StartingLevel__c = 'Beginner-Level0A');
        insert studentActual2;
        Product2 product4 = new Product2(Name = 'Home', EtownId__c = '999999994', IsLevel__c = false, Family = 'Smart Product List', IsActivable__c = true);
        insert product4;
        StudentProduct__c studentProduct4 = new StudentProduct__c(StudentActual__c = studentActual2.Id, product__c = product4.Id);
        StudentProduct__c studentProduct3 = new StudentProduct__c(StudentActual__c = studentActual2.Id, product__c = product3.Id, BookingCenters__c='BJ DFG;SH All');
        insert new StudentProduct__c[] { studentProduct3, studentProduct4 };
        ActivateCourseService.activateCourse(studentActual2.Id);
    }
    
    @isTest
    static void testValidateMethod()
    {
    	List<RecordType> recordType = [select Name from RecordType where IsActive = true and Name = 'US Actual Record Type' limit 1];
        Account testCompany = new Account(Name = 'company acem');
        insert testCompany;
        Contact student = new Contact(LastName = 'acme1 name', AccountId = testCompany.Id, Email = 'acme@g.com', phone = '123456', Status__c = 'Active');
        insert student;
        Actual__c testActual = new Actual__c(Account__c = testCompany.Id, RecordTypeId = recordType[0].Id, China_Sales_Type__c = 'Double Pay', Close_Date__c = Date.today().addDays(10));
        insert testActual;
        StudentActual__c studentActual = new StudentActual__c(Student__c = student.Id, Actual__c = testActual.Id);
        insert studentActual;
        Test.startTest();
        ActivateCourseService.activateCourse(studentActual.Id);//no acitve products
        Product2 product = new Product2(Name = 'Alumni Club', EtownId__c = 'X123456789', IsLevel__c = true, Family = 'Smart Product List', IsActivable__c = true);
        Product2 product2 = new Product2(Name = 'Onlie PL', EtownId__c = '999999991', IsActivable__c = true, Family = 'Smart Non-Standard Product List');
        Product2 product3 = new Product2(Name = 'Cross Center Booking', EtownId__c = '999999992', IsActivable__c = true, Family = 'Smart Non-Standard Product List');
        insert new Product2[]{ product, product2, product3 };
        StudentProduct__c studentProduct = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product.Id, LevelsPurchased__c = '3', FreeLength__c = '4', Quantity__c = 1);
        StudentProduct__c studentProduct2 = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product2.Id, Quantity__c = 1);
        StudentProduct__c studentProduct3 = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product3.Id);
        insert new StudentProduct__c[]{ studentProduct, studentProduct2, studentProduct3 };
        ActivateCourseService.activateCourse(studentActual.Id); // actual colse date needs to less than or equal today
         
        testActual.Close_date__c = Date.today();
        update testActual;
        ActivateCourseService.activateCourse(studentActual.Id); // actual sales type can't be "Double Pay"
         
        testActual.China_Sales_Type__c = 'New';
        update testActual;
        ActivateCourseService.activateCourse(studentActual.Id); // EtownMemberId can't be null 
       
        student.EtownMemberId__c = 111;
        update student;
        StudentProduct__c studentProduct4 = studentProduct.clone(false, true);
        insert studentProduct4;
        ActivateCourseService.activateCourse(studentActual.Id); // student actual has tow main products
        
        delete studentProduct4;
        ActivateCourseService.activateCourse(studentActual.Id); //elite card can't be null
        
        studentActual.EliteCard__c = '111';
        update studentActual;
        studentProduct.Status__c = 'Error';
        update studentProduct;
        ActivateCourseService.activateCourse(studentActual.Id); // error status
        
        studentProduct.Status__c = 'Inactive';
        update studentProduct;
        ActivateCourseService.activateCourse(studentActual.Id); // EtownId is need to Number
         
        product.EtownId__c = '999999993';
        update product;
        ActivateCourseService.activateCourse(studentActual.Id); // need to set starting level
        
        //create a old acitve student acutal 
        Actual__c oldActual = new Actual__c(Account__c = testCompany.Id, China_Sales_Type__c = 'New', Close_Date__c = Date.today());
        insert oldActual;
        StudentActual__c oldStudentActual = new StudentActual__c(Student__c = student.Id, Actual__c = oldActual.Id, CourseActivationDate__c = Date.today());
        insert oldStudentActual;
        Product2 oldProduct = new Product2(Name = 'Premium 10', EtownId__c = 'X123456789', IsLevel__c = true, Family = 'Smart Product List', IsActivable__c = true);
        insert oldProduct; 
        StudentProduct__c oldStudentProduct = new StudentProduct__c(StudentActual__c = oldStudentActual.Id, product__c = oldProduct.Id, LevelsPurchased__c = '3', FreeLength__c = '4', Quantity__c = 1);
        insert oldStudentProduct;
        studentActual.StartingLevel__c = 'Beginner-Level0A';
        update studentActual;
        ActivateCourseService.activateCourse(studentActual.Id);
        Test.stopTest();
    }
    
    @isTest
    static void testHandleEtownErrorMsg()
    {
    	List<RecordType> recordType = [select Name from RecordType where IsActive = true and Name = 'US Actual Record Type' limit 1];
        Account testCompany = new Account(Name = 'company acem');
        insert testCompany;
        Contact student = new Contact(LastName = 'acme1 name', AccountId = testCompany.Id, Email = 'acme@g.com', phone = '123456', Status__c = 'Active');
        insert student;
        Actual__c testActual = new Actual__c(Account__c = testCompany.Id, RecordTypeId = recordType[0].Id, China_Sales_Type__c = 'Double Pay', Close_Date__c = Date.today().addDays(10));
        insert testActual;
        StudentActual__c studentActual = new StudentActual__c(Student__c = student.Id, Actual__c = testActual.Id);
        insert studentActual;
        Product2 product = new Product2(Name = 'Alumni Club', EtownId__c = '999999999', IsLevel__c = true, Family = 'Smart Product List', IsActivable__c = true);
        insert product;
        StudentProduct__c studentProduct = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product.Id, LevelsPurchased__c = '3', FreeLength__c = '4', Quantity__c = 1);
        insert studentProduct;
        ActivateCourseService.ActivationResult result = new ActivateCourseService.ActivationResult();
        result.ErrorMessage = 'error';
        result.ErrorProduct = studentProduct;
        ActivateCourseService.handleEtownErrorMsg(result);
    }
}