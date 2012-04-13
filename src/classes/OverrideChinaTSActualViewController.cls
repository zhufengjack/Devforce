/*
*    Controller for "Override China TS Actual View" page.
*/
public class OverrideChinaTSActualViewController 
{
    public List<PaymentInfo> Payments {get; set;}
    public List<StudentInfo> StudentActuals {get; set;}
    public List<SelectOption> StudentActualOptions {get; set;}
    public List<String> SelectedStudent = new List<String>();
    public PaymentData__c TSNewPayment{get;set;}
    public String PaymentMethod {get; set;} // Used in china ts.
    public String ChinaTSPaymentType {get; set;} // Used in china ts.
    public String BankName {get;set;}
    private String currentActualId;
    
    public OverrideChinaTSActualViewController(ApexPages.StandardController controller)
    {
        currentActualId = controller.getId();
        if(currentActualId != null)
        {
            List<Actual__c> actuals = [select Id, Name, RecordType.Name, (Select Id, Name, EntryCenter__c, EliteCard__c, Student__c, Individual_Portion__c, FinalPrice__c, Status__c, CNPaymentTotal__c From Student_Actuals__r)  from Actual__c where Id = :currentActualId limit 1];
            if(actuals.size() > 0)
            {
                TSNewPayment = new PaymentData__c(Actual__c = currentActualId);
                studentActuals = initialStudentActuals(actuals[0].Student_Actuals__r);
                StudentActualOptions = initialStudentActualOptions(actuals[0].Student_Actuals__r);
                Payments = initialPayments(currentActualId);
            }
        }
    }
    
      public List<SelectOption> getItems()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','---Select a bank---'));
        options.add(new SelectOption('中国银行 BOC','中国银行 BOC'));
        options.add(new SelectOption('工商银行 ICBC','工商银行 ICBC'));
        options.add(new SelectOption('建设银行 CCB','建设银行 CCB'));
        options.add(new SelectOption('交通银行 BankComm','交通银行 BankComm'));
        options.add(new SelectOption('招商银行 CMB','招商银行 CMB'));
        options.add(new SelectOption('中国农业银行 ABChina','中国农业银行 ABChina'));
        options.add(new SelectOption('广东发展银行 GDB','广东发展银行 GDB'));
        options.add(new SelectOption('深圳发展银行 SDB','深圳发展银行 SDB'));
        options.add(new SelectOption('中国光大银行 CEB','中国光大银行 CEB'));
        options.add(new SelectOption('中信银行 China CITIC Bank','中信银行 China CITIC Bank'));
        options.add(new SelectOption('中国民生银行 CMBC','中国民生银行 CMBC'));
        options.add(new SelectOption('中国人民银行 PBC','中国人民银行 PBC'));
        options.add(new SelectOption('上海浦东发展银行 SPD Bank','上海浦东发展银行 SPD Bank'));
        options.add(new SelectOption('华夏银行 HXB','华夏银行 HXB'));
        options.add(new SelectOption('兴业银行','兴业银行'));
        options.add(new SelectOption('邮政储蓄','邮政储蓄'));
        options.add(new SelectOption('上海银行','上海银行'));
        options.add(new SelectOption('北京农村商业银行','北京农村商业银行'));
        options.add(new SelectOption('北京银行','北京银行'));
        options.add(new SelectOption('深圳平安银行','深圳平安银行'));
        options.add(new SelectOption('广州市商业银行','广州市商业银行'));
        options.add(new SelectOption('广州市农村信用合作社','广州市农村信用合作社'));
        options.add(new SelectOption('其他中国银行 Other China Banks','其他中国银行 Other China Banks'));
        options.add(new SelectOption('其他外国银行 Other Foreign Banks','其他外国银行 Other Foreign Banks'));
        return options;
    }
    
    public List<String> getSelectedStudent()
    {
        return selectedStudent;
    }
    
    public void setSelectedStudent(List<String> students)
    {
        this.selectedStudent = students;    
    }
    
    //Creates payment data for china ts.
    public Pagereference CreateTSPaymentData()
    {
        Boolean isValid = true;
        if(SelectedStudent.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a student.'));
            isValid = false;
        }
        if(TSNewPayment.Amount__c == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount is null.'));
            isValid = false;
        }
        if(ChinaTSPaymentType == null || ChinaTSPaymentType == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pay type is null.'));
            isValid = false;
        }
        if(TSNewPayment.Card_Holder__c == null || TSNewPayment.Card_Holder__c == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Card Holder is null.'));
            isValid = false;
        }
        if(TSNewPayment.no_of_installments__c == null || TSNewPayment.no_of_installments__c == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a number for installments.'));
            isValid = false;
        }
        if(isValid)
        {
            List<PaymentData__c> records = new List<PaymentData__c>();
            //double subAmount = TSNewPayment.Amount__c/SelectedStudent.size();
            if(SelectedStudent.size() > 1)
            {
                //double subAmount = TSNewPayment.Amount__c/SelectedStudent.size();
                PaymentData__c totalPayment1 = new PaymentData__c();
                PaymentData__c totalPayment2 = new PaymentData__c();                
                totalPayment1.Amount__c = TSNewPayment.Amount__c;
                totalPayment1.Actual__c = currentActualId;
                totalPayment1.Exp_Date__c = TSNewPayment.Exp_Date__c;
                totalPayment1.TransDatetime__c = datetime.now();
                totalPayment1.Payment_method__c = PaymentMethod;
                totalPayment1.Pay_Type__c = ChinaTSPaymentType;
                totalPayment1.Card_Holder__c = TSNewPayment.Card_Holder__c;
                totalPayment1.CardNo__c = TSNewPayment.CardNo__c;
                totalPayment1.BankName__c = BankName;
               
                totalPayment2.Amount__c = 0 - TSNewPayment.Amount__c;
                totalPayment2.Actual__c = currentActualId;
                totalPayment2.Pay_Type__c = ChinaTSPaymentType; 
                totalPayment2.TransDatetime__c = datetime.now();
                records.add(totalPayment1);
                records.add(totalPayment2);
                double subAmount = TSNewPayment.Amount__c/SelectedStudent.size(); 
                for(String studentId : SelectedStudent)
                {
                    PaymentData__c record = new PaymentData__c();
                    record.Amount__c = subAmount;
                    record.Actual__c = currentActualId;
                    record.StudentActual__c = studentId;
                    record.Exp_Date__c = TSNewPayment.Exp_Date__c;
                    record.TransDatetime__c = datetime.now();
                    record.Payment_method__c = PaymentMethod;
                    record.Pay_Type__c = ChinaTSPaymentType;
                    record.Card_Holder__c = TSNewPayment.Card_Holder__c;
                    record.CardNo__c = TSNewPayment.CardNo__c;
                    record.BankName__c = BankName;
                    record.Status__c = 'Paid';
                    record.no_of_installments__c = TSNewPayment.no_of_installments__c;
                    records.add(record);
                }
            }
            else
            {
                PaymentData__c record = new PaymentData__c();
                record.Amount__c = TSNewPayment.Amount__c;
                record.Actual__c = currentActualId;
                record.StudentActual__c = SelectedStudent[0];
                record.Exp_Date__c = TSNewPayment.Exp_Date__c;
                record.TransDatetime__c = datetime.now();
                record.Payment_method__c = PaymentMethod;
                record.Pay_Type__c = ChinaTSPaymentType;
                record.Card_Holder__c = TSNewPayment.Card_Holder__c;
                record.CardNo__c = TSNewPayment.CardNo__c;
                record.BankName__c = BankName;
                record.Status__c = 'Paid';
                record.no_of_installments__c = TSNewPayment.no_of_installments__c;
                records.add(record);
            }
            try
            {
                insert records;
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully created the payment records.<script>setTimeout("window.location=window.location;", 3000)</script>'));
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to create payment records.' + ex.getMessage()));
            }
        }
        return null;  
    }
    
    private List<StudentInfo> initialStudentActuals(List<StudentActual__c> studentActualList)
    {
        List<StudentInfo> results = new List<StudentInfo>();
        if(studentActualList != null && studentActualList.size() > 0)
        {
            for(StudentActual__c student : studentActualList)
            {
                StudentInfo currentStudent = new StudentInfo(student.Id,student.Name, student.EntryCenter__c);
                currentStudent.finalPrice = (student.FinalPrice__c != null)?('$' + String.valueof(student.FinalPrice__c)):'N/A';
                currentStudent.paymentTotal = (student.CNPaymentTotal__c != null)?(String.valueof(student.CNPaymentTotal__c)):'0';
                currentSTudent.Status = student.Status__c;
                currentStudent.IndividualPortain = (student.Individual_Portion__c != null)?('$' + (String.valueof(student.Individual_Portion__c))):'';
                currentStudent.EliteCard = student.EliteCard__c;
                currentStudent.studentId = student.Student__c;
                results.add(currentStudent);
            }
        }
        return results;
    }
    
    private List<SelectOption> initialStudentActualOptions(List<StudentActual__c> studentActualList)
    {
        //StudentActualOptions
        List<SelectOption> options = new List<SelectOption>();
        if(studentActualList != null && studentActualList.size() > 0)
        {
            for(StudentActual__c student : studentActualList)
            {
                options.add(new SelectOption(student.Id,student.Name));            
            }
        }
        return options;
    }
    
    private List<PaymentInfo> initialPayments(String actualId)
    {
        List<PaymentInfo> results = new List<PaymentInfo>();
        if(actualId != null)
        {
            List<PaymentData__c> items = [select Id, Name, Actual__c, DueDate__c, Amount__c, AmountDue__c, Status__c, CollectedDate__c, BankName__c, CardNo__c, Card_Holder__c, Exp_Date__c, OperateType__c, OriginTrace__c, SysTraceNo__c, Payment_method__c, TransDatetime__c, TransType__c, StudentActual__c, StudentActual__r.Name, Pay_Type__c, Deposit_Type__c, Withdraw_Deposit__c, Total_Refund_Amount__c from PaymentData__c where Actual__c= :actualId order by CreatedDate];
            if(!items.isEmpty())
            {
                integer index = 1;
                for(PayMentData__c item : items)
                {
                    PaymentInfo record = new paymentInfo();
                    record.Index = (index < 10)?('0' + String.valueof(index)):(String.valueof(index));
                    record.ActualId = actualId; 
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
    
    //inner class for student actual
    public class StudentInfo
    {
        public StudentInfo(String id, String studentName, String school)
        {
            this.Id = id;
            this.StudentName = studentName;
            this.schoolName = school;
        }
        public String Id {get;set;}
        public String StudentName {get;set;}
        public String studentId {get;set;}
        public String schoolName {get;set;}
        public String finalPrice {get;set;}
        public String paymentTotal{get;set;}
        public String Status {get;set;}
        public String IndividualPortain {get;set;}
        public String EliteCard {get;set;}
    }
    
    //inner class for payment record
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
    
    @isTest
    static void testOverrideChinaTSActualViewController()
    { 
        String chinaTSActualRecordTypeId = [select Id, Name from RecordType where Name = 'China TS Actual Record Type' and SobjectType = 'Actual__c'].Id;
        Actual__c testActual = new Actual__c(RecordTypeId = chinaTSActualRecordTypeId);
        insert testActual;
        StudentActual__c testStudentActual = new StudentActual__c(Actual__c = testActual.Id, Name = 'Test cnts student actual');
        insert testStudentActual;
        ApexPages.StandardController actualStandardController = new ApexPages.StandardController(testActual);
        OverrideChinaTSActualViewController controller = new OverrideChinaTSActualViewController(actualStandardController);
        controller.PaymentMethod = 'CASH';
        controller.BankName = 'Test bank name';
        controller.ChinaTSPaymentType = 'China TS Deposit';
        controller.TSNewPayment.Amount__c = 3122;
        controller.SelectedStudent = new List<String>{testStudentActual.Id};
        controller.TSNewPayment.CardNo__c = '223334444332';
        controller.TSNewPayment.Exp_Date__c = '12/12';
        controller.TSNewPayment.Card_Holder__c = 'ht';
        controller.TSNewPayment.no_of_installments__c = '1';
        controller.CreateTSPaymentData();
        OverrideChinaTSActualViewController testController = new OverrideChinaTSActualViewController(actualStandardController);
        testController.Payments[0].tsPayWithDeposit();
        testController.Payments[0].Refund();
        testController.Payments[0].Cancel();
        StudentActual__c testStudentActual2 = new StudentActual__c(Actual__c = testActual.Id, Name = 'Test cnts student actual2');
        insert testStudentActual2;
        OverrideChinaTSActualViewController controller2 = new OverrideChinaTSActualViewController(actualStandardController);
        controller2.PaymentMethod = 'CASH';
        controller2.BankName = 'Test bank name';
        controller2.ChinaTSPaymentType = 'China TS Payment';
        controller2.TSNewPayment.Amount__c = 3122;
        controller2.setSelectedStudent(new List<String>{testStudentActual.Id, testStudentActual2.Id}); 
        controller2.TSNewPayment.CardNo__c = '223334444332';
        controller2.TSNewPayment.Exp_Date__c = '12/12';
        controller2.TSNewPayment.Card_Holder__c = 'ht';
        controller2.TSNewPayment.no_of_installments__c = '1';
        controller2.CreateTSPaymentData();
        controller2.getSelectedStudent();
    }
}