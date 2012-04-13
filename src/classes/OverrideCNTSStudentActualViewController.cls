/*
*    Controller for "Override CNTS Student Actual View" page.
*/
public class OverrideCNTSStudentActualViewController 
{
    public String studentActualId;
    public List<PaymentInfo> TSPayments {get; set;}
    public StudentActual__c StudentActual {get;set;}
    
    public OverrideCNTSStudentActualViewController(ApexPages.StandardController controller)
    {
        studentActualId = controller.getId();
        StudentActual = [select Id, Name, Actual__c, Actual__r.RecordType.Name from StudentActual__c where Id = :studentActualId limit 1]; 
        TSPayments = InitialPaymentList();
    }
    
    private List<PaymentInfo> InitialPaymentList()
    {
        List<PaymentInfo> results = new List<PaymentInfo>();
        if(studentActualId != null)
        {
            List<PaymentData__c> items = [select Id, Name, Actual__c, DueDate__c, Amount__c, AmountDue__c, Status__c, CollectedDate__c, BankName__c, CardNo__c, Card_Holder__c, Exp_Date__c, OperateType__c, OriginTrace__c, SysTraceNo__c, Payment_method__c, TransDatetime__c, TransType__c, StudentActual__c, StudentActual__r.Name, Pay_Type__c, Deposit_Type__c, Withdraw_Deposit__c, Total_Refund_Amount__c from PaymentData__c where StudentActual__c= :studentActualId order by CreatedDate];
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
                    record.AmountDue = item.AmountDue__c;
                    record.Status = item.Status__c;
                    record.PayMethod = item.Payment_method__c;
                    record.BankName = (item.BankName__c != null)?(item.BankName__c):'N/A';
                    record.CardHolder = (item.Card_Holder__c != null)?(item.Card_Holder__c):'N/A';
                    record.CardNO = (item.CardNo__c != null)?(item.CardNo__c):'N/A';
                    record.DueDate = (item.DueDate__c != null)?(item.DueDate__c.format()):null;
                    record.CollectedDate = (item.TransDatetime__c != null)?(item.TransDatetime__c.date().format()):null;
                    record.PayType = (item.Pay_Type__c != null)?(item.Pay_Type__c):'N/A';
                    record.RefundAmount = item.Total_Refund_Amount__c; //(item.Total_Refund_Amount__c != 0)?(item.Total_Refund_Amount__c):null;
                    if(item.Pay_Type__c == 'China TS Deposit')
                    {
                        record.IsRenderPayWithDepositButton = true; 
                        if(item.Withdraw_Deposit__c == true)
                        {
                            record.IsCanRefund = true;
                            record.IsDisabledPayDesButton = true;
                        }
                    }  
                    if(record.Amount - record.RefundAmount <= 0)
                    {
                        record.IsDisabledPayDesButton = true;
                        record.IsCanRefund = true;
                    }
                    if(item.StudentActual__r != null)
                    {                       
                        record.StudentActualId = item.StudentActual__c;
                        record.StudentActualname = item.StudentActual__r.Name;                  
                    }
                    results.add(record);
                    index++;
                }
            }
        }
        return results;
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
        // Used in china TS.
        public String Status {get; set;}
        public Double AmountDue {get; set;}
        public String CollectedDate {get; set;}
        
        public void tsPayWithDeposit()
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
            newPaymentRecordDep.Pay_Type__c =  'China TS Deposit';
            newPaymentRecordDep.Deposit_Type__c = 'Withdraw';
            newPaymentRecordDep.Status__c = 'Paid';
            newPaymentRecordDep.Payment_method__c = this.PayMethod;
            newPaymentRecordDep.TransDatetime__c = datetime.now();
            records.add(newPaymentRecordDep);
            
            newPaymentRecordPay.Amount__c = this.Amount - this.RefundAmount;
            newPaymentRecordPay.StudentActual__c = currentStduentActualId;
            newPaymentRecordPay.Pay_Type__c =  'China TS Payment';
            newPaymentRecordPay.Status__c = 'Paid';
            newPaymentRecordPay.Payment_method__c = this.PayMethod;
            newPaymentRecordPay.TransDatetime__c = datetime.now();
            newPaymentRecordPay.BankName__c = this.BankName;
            newPaymentRecordPay.CardNo__c = this.CardNo;
            newPaymentRecordPay.Card_Holder__c = this.CardHolder;
            records.add(newPaymentRecordPay);
            try
            {
                insert records;
                PaymentData__c currentPayment = new PaymentData__c(Id = this.PaymentId);
                currentPayment.Withdraw_Deposit__c = true;
                update currentPayment;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully paid with desposit.<script>setTimeout("window.location.reload();", 3000)</script>'));
                
            }
            catch(Exception ex)
            {
            	if(records.size() > 0)
                {
                    delete records;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to pay with desposit.\r\n' + ex.getMessage()));
            }
            //return null;
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
    static void testOverrideCNTSStudentActualViewController()
    {
        String chinaTSActualRecordTypeId = [select Id, Name from RecordType where Name = 'China TS Actual Record Type' and SobjectType = 'Actual__c'].Id;
        Actual__c testActual = new Actual__c(RecordTypeId = chinaTSActualRecordTypeId);
        insert testActual;
        StudentActual__c testStudentActual = new StudentActual__c(Actual__c = testActual.Id, Name = 'Test cnts student actual');
        insert testStudentActual;
        PaymentData__c payment1 = new PaymentData__c(Actual__c = testActual.Id, StudentActual__c = testStudentActual.Id, Pay_Type__c = 'China TS Deposit', TransDatetime__c = datetime.now(), Status__c = 'Paid', Deposit_Type__c = 'Withdraw');
        insert payment1;
        ApexPages.StandardController studentActualStandardController = new ApexPages.StandardController(testStudentActual);
        OverrideCNTSStudentActualViewController controller = new OverrideCNTSStudentActualViewController(studentActualStandardController);
        controller.TSPayments[0].tsPayWithDeposit();
        controller.TSPayments[0].Refund();
        controller.TSPayments[0].Cancel();
        controller.getStudentProducts();
    }
}