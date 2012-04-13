public class TsStudentProductRefundDialogController 
{
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
    public Boolean IsTSActual {get; set;}
    private StudentProduct__c currentStudentProduct;
    private RefundInfo tempRefundInfo = new RefundInfo();
    
    public TsStudentProductRefundDialogController()
    {
        MiddleObject = new StudentProduct__c();
        MiddleStudentActual = new StudentActual__c();
        
        String studentProductId = ApexPages.currentPage().getParameters().get('id');
        List<StudentProduct__c> studentProducts = [select Id, Name, Amount__c, Quantity__c, BookingCenters__c, Refund_Amount__c, Product__r.Name, Product__r.RedemptionCode__c, Refund_date_China__c, Refund_Quantity__c, StudentActual__c, StudentActual__r.RefundType__c, StudentActual__r.RefundAmount__c, StudentActual__r.CNRefundTotal__c, StudentActual__r.Student__r.EtownMemberId__c, StudentActual__r.Actual__r.RecordType.Name from StudentProduct__c where Id = :studentProductId limit 1];
        if(studentProducts.size() > 0)
        {
            currentStudentProduct = studentProducts[0];
            if(currentStudentProduct.StudentActual__r.Actual__r.RecordType.Name == 'China TS Actual Record Type')
            {
                IsTSActual = true;
            }
            StudentProductName = currentStudentProduct.Name;
            ProductName = currentStudentProduct.Product__r.Name;
            MiddleObject.Refund_Amount__c = currentStudentProduct.Refund_Amount__c;
            MiddleObject.Refund_Quantity__c = currentStudentProduct.Refund_Quantity__c;
            MiddleStudentActual.RefundType__c = currentStudentProduct.StudentActual__r.RefundType__c;
        }
    }

    public void refundTSPayment()
    {
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
            save();
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
    private Boolean compareTSRefundAmount()
    {
        Decimal cnRefundTotal = (currentStudentProduct.StudentActual__r.CNRefundTotal__c == null) ? 0 : currentStudentProduct.StudentActual__r.CNRefundTotal__c;
        Decimal oldRefundAmount = (currentStudentProduct.StudentActual__r.RefundAmount__c == null) ? 0 : currentStudentProduct.StudentActual__r.RefundAmount__c;
        Decimal currentRefundAmount = oldRefundAmount + MiddleObject.Refund_Amount__c;
        if(cnRefundTotal < currentRefundAmount)
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
        try
        { 
            currentStudentProduct.Refund_Amount__c = tempRefundInfo.refundAmount;
            currentStudentProduct.Refund_date_China__c = tempRefundInfo.refundDate;
            currentStudentProduct.Refund_Quantity__c = tempRefundInfo.quantity;
            StudentActual__c tempStudentActual = new StudentActual__c(Id = currentStudentProduct.StudentActual__c, RefundType__c = tempRefundInfo.refundType);
            update tempStudentActual;
            update currentStudentProduct;   
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
            return;
        }
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Refund successful.<script type="text/javascript">opener.location.reload();closeWindow();</script>'));
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
    
    @isTest
    static void testRefund()
    {
        Actual__c actual = new Actual__c();
        insert actual;
        StudentActual__c studentActual = new StudentActual__c(Actual__c = actual.Id, CNRefundTotal__c = 23);
        insert studentActual;
        StudentProduct__c studentProduct = new StudentProduct__c(Name = 'test', StudentActual__c = studentActual.Id, Price__c = 9999, Quantity__c = 1);
        insert studentProduct;
        Product2 ccbProd = new Product2(Name='Cross Center Booking');
        insert ccbProd;
        PageReference testPage = new PageReference('/apex/StudentProductRefundDialog?id=' + studentProduct.Id);
        Test.setCurrentPage(testPage);
        TsStudentProductRefundDialogController controller = new TsStudentProductRefundDialogController();
        controller.refundTSPayment();
        controller.MiddleObject.Refund_Amount__c = 3216;
        controller.MiddleObject.Refund_Quantity__c = 7;
        controller.MiddleObject.Refund_date_China__c = Date.today();
        controller.MiddleStudentActual.RefundType__c = 'Full Refund';
        controller.refundTSPayment();
        controller.compareTSRefundAmount();
        controller.confirm();
        System.assertEquals('Full Refund', [select Id, RefundType__c from StudentActual__c where Id = :studentActual.Id].RefundType__c);
        StudentProduct__c studentProduct3 = [select Id, Refund_Amount__c, Refund_Quantity__c, Refund_date_China__c from StudentProduct__c where Id = :studentProduct.Id];
        System.assertEquals(3216, studentProduct3.Refund_Amount__c);
        System.assertEquals(7, studentProduct3.Refund_Quantity__c);
        System.assertEquals(Date.today(), studentProduct3.Refund_date_China__c);
    }
}