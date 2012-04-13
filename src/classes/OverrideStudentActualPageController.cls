public class OverrideStudentActualPageController 
{
    public String studentActualId;
    
    public OverrideStudentActualPageController(ApexPages.StandardController controller)
    {
        studentActualId = ApexPages.currentPage().getParameters().get('id');
        StudentActual = [select Id, Name from StudentActual__c where Id = :studentActualId limit 1]; 
    }
    
    public PageReference checkStudentActualRecordType()
    {
        String initialStudentActualId = ApexPages.currentPage().getParameters().get('id');
        List<StudentActual__c> studentActuals = [select Id, Name, Actual__c, Actual__r.RecordType.Name from StudentActual__c where Id = :initialStudentActualId limit 1];
        if(studentActuals.size() > 0)
        {
            if(studentActuals[0].Actual__r.RecordType.Name == 'China TS Actual Record Type' || studentActuals[0].Actual__r.RecordType.Name == 'China mini actual record type')
            {
                PageReference chinaTSStudentActualViewPage = new pageReference('/apex/OverrideChinaTSStudentActualView?id=' + initialStudentActualId); // + '/e?nooverride=1
                    return chinaTSStudentActualViewPage;
            }
        }
        return null;
    }
    
    public StudentActual__c StudentActual {get;set;}
    public List<PaymentInfo> Payments
    {
        get
        {
            List<paymentInfo> records = new List<PaymentInfo>();
            if(studentActualId != null)
            {
                List<PaymentData__c> items = [select Id, Name, Actual__c, Amount__c, BankName__c, CardNo__c, Card_Holder__c, Exp_Date__c, OperateType__c, OriginTrace__c, SysTraceNo__c, Payment_method__c, TransDatetime__c, TransType__c, StudentActual__c, StudentActual__r.Name, Pay_Type__c, Deposit_Type__c, Withdraw_Deposit__c, Total_Refund_Amount__c from PaymentData__c where StudentActual__c= :studentActualId order by CreatedDate];
                if(!items.isEmpty())
                {
                    integer index = 1;
                    for(PayMentData__c item : items)
                    {
                        PaymentInfo record = new paymentInfo();
                        record.Index = (index < 10)?('0' + String.valueof(index)):(String.valueof(index));
                        record.ActualId = item.Actual__c;
                        record.paymentId = item.Id;
                        record.Amount = item.Amount__c;
                        record.PayMethod = item.Payment_method__c;
                        record.TraceNo = (item.SysTraceNo__c != null)?(item.SysTraceNo__c):'N/A';
                        record.CardHolder = (item.Card_Holder__c != null)?(item.Card_Holder__c):'N/A';
                        record.CardNO = (item.CardNo__c != null)?(item.CardNo__c):'N/A';
                        record.BankName = (item.BankName__c != null)?(item.BankName__c):'N/A';
                        record.DueDate = (item.TransDatetime__c != null)?(item.TransDatetime__c.format()):null;
                        record.CardExpDate = (item.Exp_Date__c != null)?(item.Exp_Date__c):'N/A';
                        record.PayType = (item.Pay_Type__c != null)?(item.Pay_Type__c):'N/A';
                        record.RefundAmount = item.Total_Refund_Amount__c;
                        record.OperateType = item.OperateType__c;
                        record.OriginTrace = item.OriginTrace__c;
                        record.TransType = item.TransType__c;
                        record.RefundAmount =  (item.Total_Refund_Amount__c != null)?(item.Total_Refund_Amount__c):0;
                        if(item.Pay_Type__c == 'China Smart Deposit')
                        {
                            record.IsRenderPayWithDepositButton = true; 
                            if(item.Amount__c < = 0)
                            {
                                record.IsDisabledPayDesButton = true;
                                record.IsCanRefund = true;
                            }
                            if(record.RefundAmount > 0)
                            {
                                record.IsCanRefund = true;
                            }
                        }
                        if(item.Payment_method__c != null && (item.Payment_method__c.toLowerCase() == 'pos' || item.Payment_method__c.toLowerCase() == 'ONLINE PAYMENT-99BILL'))
                        {
                            if(item.TransDatetime__c != null && (item.TransDatetime__c.date() == date.today()))
                            {
                                record.isCanCancel = false;
                            }
                        }
                        else
                        {
                            if(item.Pay_Type__c == 'China Smart Payment')
                            {
                                record.isCanCancel = true;
                            }
                            else
                            {
                                record.IsRenderCancelButton = false;
                            }
                        }
                        record.DespositType = (item.Deposit_Type__c != null)?(item.Deposit_Type__c):'N/A';
                        record.WithDrawDeposit = (item.Withdraw_Deposit__c != null)?(item.Withdraw_Deposit__c):false;
                        if(item.Withdraw_Deposit__c == true)
                        {
                            record.IsDisabledPayDesButton = true;
                            record.IsCanRefund = true;
                        }
                        record.StudentActualId = item.StudentActual__c;
                        record.StudentActualname = item.StudentActual__r.Name;                  
                        records.add(record);
                        index++;
                    }
                }
                
            }
            return records;
        }
    }
    
    public class PaymentInfo
    {
        public PaymentInfo()
        {
            StudentActualId = 'N/A';
            StudentActualName = 'N/A';
            IsRenderPayWithDepositButton = false;
            IsCanCancel = true;
            IsCanRefund = false;
            IsDisabledPayDesButton = false;
            IsRenderCancelButton = true;
        }
        public String ActualId {get;set;}
        public String StudentActualId {get;set;}
        public String PaymentId {get;set;}
        public String StudentActualName {get;set;}
        public String Index {get;set;}
        public double Amount {get;set;}
        public double RefundAmount {get;set;}
        public String PayMethod {get;set;}
        public String TraceNo{get;set;}
        public String CardHolder {get;set;}
        public String CardNO {get;set;}
        public String BankName {get;set;}
        public String DueDate {get;set;}
        public String CardExpDate {get;set;}
        public String PayType {get;set;}
        public String DespositType {get;set;}
        public String OperateType {get;set;}
        public String OriginTrace {get;set;}
        public String TransType {get;set;}
        public Boolean WithDrawDeposit {get;set;}
        public Boolean IsCanRefund {get;set;}
        public Boolean IsRenderPayWithDepositButton {get;set;}
        public Boolean IsCanCancel {get;set;}
        public Boolean IsDisabledPayDesButton {get;set;}
        public Boolean IsRenderCancelButton {get;set;}
        
        public PageReference PayWithDeposit()
        {
            List<PaymentData__c> records = new List<PaymentData__c>();
            PaymentData__c newPaymentRecordDep = new PaymentData__c(Actual__c = this.ActualId);
            PaymentData__c newPaymentRecordPay = new PaymentData__c(Actual__c = this.ActualId);
            newPaymentRecordDep.Amount__c = this.RefundAmount - this.Amount;
            String currentStduentActualId;
            if(this.StudentActualId != 'N/A')
            {
                currentStduentActualId = this.StudentActualId;
            }
            newPaymentRecordDep.StudentActual__c = currentStduentActualId;
            newPaymentRecordDep.Pay_Type__c =  'China Smart Deposit';
            newPaymentRecordDep.Deposit_Type__c = 'Withdraw';
            newPaymentRecordDep.TransDatetime__c = datetime.now();
            records.add(newPaymentRecordDep);
            
            newPaymentRecordPay.Amount__c = this.Amount - this.RefundAmount;
            newPaymentRecordPay.StudentActual__c = currentStduentActualId;
            newPaymentRecordPay.Pay_Type__c =  'China Smart Payment';
            newPaymentRecordPay.TransDatetime__c = datetime.now();
            newPaymentRecordPay.BankName__c = this.BankName;
            newPaymentRecordPay.CardNo__c = this.CardNo;
            newPaymentRecordPay.Card_Holder__c = this.CardHolder;
            newPaymentRecordPay.Exp_Date__c = this.CardExpDate;
            newPaymentRecordPay.OperateType__c = this.OperateType;
            newPaymentRecordPay.OriginTrace__c = this.OriginTrace;
            newPaymentRecordPay.SysTraceNo__c = this.TraceNo;
            newPaymentRecordPay.TransType__c = this.TransType;
            records.add(newPaymentRecordPay);
            try
            {
                insert records;
                PaymentData__c currentPayment = new PaymentData__c(Id = this.PaymentId);
                currentPayment.Withdraw_Deposit__c = true;
                try
                {
                    update currentPayment;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'you have successed to pay with desposit.<script>setTimeout("window.location.reload();", 3000)</script>'));
                }
                Catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'failed to pay with desposit.' + ex.getMessage()));
                }
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'failed to pay with desposit.' + ex.getMessage()));
            }
            return null;
        }
        public PageReference Refund()
        {
            return null;
        }
        public PageReference Cancel()
        {
            return null;
        }
    }
    
    // Gets all related student products under current student Actual.
    public List<StudentProduct__c> getStudentProducts()
    {
        if(studentActualId != null)
        {
            List<StudentProduct__c> relatedStudentProducts = [select Id, Name, Status__c, Product__c, Product__r.Name, LevelsPurchased__c, StandardLength__c, FreeLength__c, MarketingLength__c, Quantity__c, Refund_Amount__c from StudentProduct__c where StudentActual__c = :studentActualId];
            return relatedStudentProducts;
        }
        return null;
    }
    
    @isTest
    static void testController()
    {
        List<PaymentData__c> payments = [select Id, Actual__c, StudentActual__c from PaymentData__c where StudentActual__c != null limit 1];
        Actual__c actual = [select Id ,(Select Id From Student_Actuals__r) from Actual__c where Id = :payments[0].Actual__c limit 1];
        StudentActual__c studentActual = [select Id from StudentActual__c where Id = :payments[0].StudentActual__c limit 1];
        ApexPages.StandardController sc = new ApexPages.StandardController(studentActual);
        pageReference currentPage = new PageReference('/apex/OverrideStudentActualView?id=' + studentActual.Id); 
        test.setCurrentPage(currentPage);
        OverrideStudentActualPageController controller = new OverrideStudentActualPageController(sc);
        List<PaymentInfo> results = controller.Payments;
        system.assert(results != null);
        results[0].PayWithDeposit();
        results[0].Cancel();
        results[0].Refund();
        controller.getStudentProducts();
    }   
}