/*
*controller for overrideActualpage
*/
public class OverrideActualPageController 
{
    public String actualId;
    public String paymentId;
    String[] selectedStudent = new String[]{};
    String selectedStudentPos;
    
    public OverrideActualPageController(ApexPages.StandardController controller)
    {
        User currentUser = [Select SchoolName__c, ProfileId From User where Id = :UserInfo.getUserId() limit 1];
        String currentUserProfileId = currentUser.ProfileId;
        String currentUserSchoolName = (currentUser.SchoolName__c == null ) ? '' : currentUser.SchoolName__c.replace('_', ' ');
        AllStudentsForCurrentUser = new List<StudentInfo>();
        studentActualMap = new Map<String,String>();
        AllStudentActuals = new List<SelectOption>();
        actualId = ApexPages.currentPage().getParameters().get('id');
        NewPayment = new PaymentData__c(Actual__c = actualId);
        NewPaymentPos = new PaymentData__c(Actual__c = actualId);
        //if the user's role name contains school ,just display the syudent actual which in whose school 
        if(GetAStringInList(currentUserSchoolName, getEntryCenterPicklistValues()))
        {
            List<Actual__c> actuals = [select Id, Name,  (Select Id, Name, EntryCenter__c, EliteCard__c, Student__c, Individual_Portion__c, FinalPrice__c, Status__c, CNPaymentTotal__c From Student_Actuals__r where EntryCenter__c = :currentUserSchoolName)  from Actual__c where Id = :actualId limit 1];
            if(actuals.size() > 0)
            {
                Actual = actuals[0];
            }
        }
        else
        {
            List<Actual__c> actuals = [select Id, Name,  (Select Id, Name, EntryCenter__c, EliteCard__c, Student__c, Individual_Portion__c, FinalPrice__c, Status__c, CNPaymentTotal__c From Student_Actuals__r)  from Actual__c where Id = :actualId limit 1];
            if(actuals.size() > 0)
            {
                Actual = actuals[0];
            }
        }
        if(Actual != null && !Actual.Student_Actuals__r.isEmpty())
        {
            for(StudentActual__c student : Actual.Student_Actuals__r)
            {
                if(!studentActualMap.containsKey(student.Id))
                {
                    studentActualMap.put(student.Id, student.Name);
                    StudentInfo currentStudent = new StudentInfo(student.Id,student.Name, student.EntryCenter__c);
                    currentStudent.finalPrice = (student.FinalPrice__c != null)?('$' + String.valueof(student.FinalPrice__c)):'N/A';
                    currentStudent.paymentTotal = (student.CNPaymentTotal__c != null)?(String.valueof(student.CNPaymentTotal__c)):'0';
                    currentSTudent.Status = student.Status__c;
                    currentStudent.IndividualPortain = (student.Individual_Portion__c != null)?('$' + (String.valueof(student.Individual_Portion__c))):'';
                    currentStudent.EliteCard = student.EliteCard__c;
                    currentStudent.studentId = student.Student__c;
                    AllStudentsForCurrentUser.add(currentStudent);
                    AllStudentActuals.add(new  SelectOption(student.Id,student.Name));
                }
            }
        }
    }
    
    public PageReference checkActualRecordType()
    {
        String initialActualId = ApexPages.currentPage().getParameters().get('id');
        List<Actual__c> actuals = [select Id, RecordType.Name from Actual__c where Id = :initialActualId];
        if(actuals.size() > 0)
        {
            if(actuals[0].RecordType.Name == 'China TS Actual Record Type' || actuals[0].RecordType.Name == 'China mini actual record type')
            {
                PageReference chinaTSActualViewPage = new pageReference('/apex/OverrideChinaTSActualView?id=' + initialActualId); // + '/e?nooverride=1
                return chinaTSActualViewPage;
            }
        }
        return null;
    }
    
    public OverrideActualPageController()
    {
        RefundRecord = new China_Smart_Refund__c();
        RefundRecord.Refund_Date_China__c = date.today();
        InitRefundAmount = 0;
        String amountStr = Apexpages.currentPage().getParameters().get('amount');
        String paymentId = ApexPages.currentPage().getParameters().get('paymentId');
        if(paymentId != null)
        {
            List<PaymentData__c> tempPayments = [select Id, Payment_method__c from PaymentData__c where Id = :paymentId];
            if(tempPayments.size() > 0)
            {
                RefundRecord.Refund_Payment_Method__c = tempPayments[0].Payment_method__c;
            }
        }
        if(amountStr != null)
        {
            try
            {
                InitRefundAmount = double.valueof(amountStr);
            }
            catch(Exception ex)
            {
                InitRefundAmount = 0;
            }
        }
    }
    
    public String[] getSelectedStudent()
    {
        return selectedStudent;
    }
    public void setSelectedStudent(String[] students)
    {
        this.selectedStudent = students;    
    }
    
    public String getSelectedStudentPos()
    {
        return selectedStudentPos;
    }
    public void setSelectedStudentPos(String student)
    {
        this.selectedStudentPos = student;  
    }
    
    public Actual__c Actual {get;set;}
    public China_Smart_Refund__c RefundRecord {get;set;}
    public double InitRefundAmount {get;set;}
    public Map<String,String> studentActualMap {get;set;}
    public List<StudentInfo> AllStudentsForCurrentUser {get;set;}
    public List<SelectOption> AllStudentActuals {get;set;}
    public PaymentData__c NewPayment{get;set;}
    public PaymentData__c NewPaymentPos{get;set;}
    public String BankName {get;set;}
    
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
    //get all payment records for this actual
    public List<PaymentInfo> Payments
    {
        get
        {
            List<paymentInfo> records = new List<PaymentInfo>();
            if(actualId != null)
            {
                List<PaymentData__c> items = [select Id, Name, Actual__c, Amount__c, BankName__c, CardNo__c, Card_Holder__c, Exp_Date__c, OperateType__c, OriginTrace__c, SysTraceNo__c, Payment_method__c, TransDatetime__c, TransType__c, StudentActual__c, StudentActual__r.Name, Pay_Type__c, Deposit_Type__c, Withdraw_Deposit__c, Total_Refund_Amount__c from PaymentData__c where Actual__c= :actualId and StudentActual__c = null order by CreatedDate];
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
                        if(item.StudentActual__r != null)
                        {                       
                            record.StudentActualId = item.StudentActual__c;
                            record.StudentActualname = item.StudentActual__r.Name;                  
                        }
                        else
                        {
                            if(!studentActualMap.keyset().isEmpty())
                            {
                                record.IsDisabledPayDesButton = true;
                                record.IsCanRefund = true;
                            }
                        }
                        records.add(record);
                        index++;
                    }
                }
                
            }
            return records;
        }
    }
    //refund for a payment record
    public PageReference Refund()
    {
        String paymentId = ApexPages.currentPage().getParameters().get('paymentId');
        if(paymentId != null)
        {
            RefundRecord.China_Payment_Data__c = paymentId;
            Boolean isValid = true;
            if(RefundRecord.Refund_Amount__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount is blank for the refud record.'));
                isValid = false;
            }
            if(RefundRecord.Refund_Date_China__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund Date is blank for the refud record.'));
                isValid = false;
            }
            /*if(RefundRecord.Refund_Type_China__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund Type is blank for the refud record.'));
                isValid = false;
            }*/
            if(isValid && RefundRecord.Id == null)
            {
                try
                {
                    insert RefundRecord;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'you have successed to create a refund record.<script>setTimeout("window.close()", 3000)</script>'));
                }
                catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
                }
            }   
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No payment data specfited for the refud record.'));
        }
        return null;
    }
    
    //create payment record
    public Pagereference CreatePaymentData()
    {   
        Boolean isValid = true;
        newPayment.BankName__c = BankName;
        if(SelectedStudent.isEmpty())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must select a student.'));
            isValid = false;
        }
        if(NewPayment.Amount__c == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount is null.'));
            isValid = false;
        }
        if(NewPayment.Pay_Type__c == null || NewPayment.Pay_Type__c == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Pay type is null.'));
            isValid = false;
        }
        if(NewPayment.Card_Holder__c == null || NewPayment.Card_Holder__c == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Card Holder is null.'));
            isValid = false;
        }
        if(NewPayment.no_of_installments__c == null || NewPayment.no_of_installments__c == '')
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You must provide a number for installments.'));
            isValid = false;
        }
        if(NewPayment.Payment_method__c == 'POS' || NewPayment.Payment_method__c == 'BANK TRANSFER' || NewPayment.Payment_method__c == 'ONLINE PAYMENT-99BILL')
        {
            if(newPayment.BankName__c == null || newPayment.BankName__c == '')
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Bank Name is null.'));
                isValid = false;
            }
        }
        if(isValid)
        {
            List<PaymentData__c> records = new List<PaymentData__c>();
            if(SelectedStudent.size() > 1)
            {
                PaymentData__c totalPayment1 = new PaymentData__c();
                PaymentData__c totalPayment2 = new PaymentData__c();                
                totalPayment1.Amount__c = NewPayment.Amount__c;
                totalPayment1.Actual__c = actualId;
                totalPayment1.Exp_Date__c = NewPayment.Exp_Date__c;
                totalPayment1.TransDatetime__c = datetime.now();
                totalPayment1.Payment_method__c = NewPayment.Payment_method__c;
                totalPayment1.Pay_Type__c = NewPayment.Pay_Type__c;
                totalPayment1.Card_Holder__c = NewPayment.Card_Holder__c;
                totalPayment1.CardNo__c = NewPayment.CardNo__c;
                totalPayment1.BankName__c = NewPayment.BankName__c;
               
                totalPayment2.Amount__c = 0 - NewPayment.Amount__c;
                totalPayment2.Actual__c = actualId;
                totalPayment2.Pay_Type__c = NewPayment.Pay_Type__c;
                totalPayment2.TransDatetime__c = datetime.now();
                records.add(totalPayment1);
                records.add(totalPayment2);
                double subAmount = NewPayment.Amount__c/SelectedStudent.size(); 
                for(String studentId : SelectedStudent)
                {
                    PaymentData__c  record = new PaymentData__c(Actual__c = actualId, StudentActual__c = studentId, Amount__c = subAmount, no_of_installments__c = NewPayment.no_of_installments__c);
                    record.Pay_Type__c = NewPayMent.Pay_Type__c;
                    record.Payment_method__c = NewPayment.Payment_method__c;
                    record.TransDatetime__c = datetime.now();
                    records.add(record);
                }
            }
            else
            {
                PaymentData__c  record = new PaymentData__c(Actual__c = actualId, StudentActual__c = SelectedStudent[0], no_of_installments__c = NewPayment.no_of_installments__c);
                record.Amount__c = NewPayment.Amount__c;
                record.Pay_Type__c = NewPayMent.Pay_Type__c;
                record.TransDatetime__c = datetime.now();
                record.Exp_Date__c = NewPayment.Exp_Date__c;
                record.Payment_method__c = NewPayment.Payment_method__c;
                record.Card_Holder__c = NewPayment.Card_Holder__c;
                record.CardNo__c = NewPayment.CardNo__c;
                record.BankName__c = NewPayment.BankName__c;
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
    
        //get all school
    private List<String> getEntryCenterPicklistValues()
    {
        List<String> entryCenters = new List<String>();    
        Schema.Describefieldresult fieldResult = StudentActual__c.EntryCenter__c.getDescribe();
        List<Schema.Picklistentry> picklistEntries = fieldResult.getPicklistValues();
        for(Schema.Picklistentry entry : picklistEntries)
        {
            entryCenters.add(entry.getValue());
        }
        return entryCenters;
    }
    
    //Judge the specfiled string in a list
    private Boolean GetAStringInList(String targetStr, List<String> items)
    {
        for(String item : items)
        {
            if(item == targetStr)
            {
                return true;
            }
        }
        return false;   
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
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have successfully paid with desposit.<script>setTimeout("window.location=window.location;", 3000)</script>'));
                }
                Catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to pay with desposit.\r\n' + ex.getMessage()));
                }
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to pay with desposit.\r\n' + ex.getMessage()));
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
    
    @isTest
    static void testController()
    {
        List<PaymentData__c> payments = [select Id, Actual__c from PaymentData__c where Actual__c != null and StudentActual__c != null and Actual__r.StudentActualCount__c > 0 limit 1];
        Actual__c actual = [select Id ,(Select Id From Student_Actuals__r) from Actual__c where Id = :payments[0].Actual__c limit 1];
        List<STring> currentSelectStudents = new List<STring>();
        for(StudentActual__c student : actual.Student_Actuals__r)
        {
            currentSelectStudents.add(student.Id);
        }
        ApexPages.StandardController sc = new ApexPages.StandardController(actual);
        pageReference currentPage = new PageReference('/apex/OverrideActualView?id=' + actual.Id); 
        test.setCurrentPage(currentPage);
        OverrideActualPageController controller = new OverrideActualPageController(sc);
        List<PaymentInfo> results = controller.Payments;
        if(results.size() > 0)
        {
            results[0].PayWithDeposit();
        }
        system.assert(results != null);
        List<StudentInfo> allSTudents = controller.AllStudentsForCurrentUser;
        controller.selectedStudent = currentSelectStudents;
        controller.NewPayment.Amount__c = 100;
        controller.NewPayment.Pay_Type__c = '123';
        controller.NewPayment.no_of_installments__c = '2';
        controller.NewPayment.Card_Holder__c = '3';
        controller.NewPayment.Payment_method__c = 'POS';
        controller.NewPayment.BankName__c = '中国银行 BOC'; 
        controller.BankName = '中国银行 BOC';
        controller.CreatePaymentData();
        List<SelectOption> backItems = controller.getItems();
        system.assert(backItems != null);
        pageReference currentPage2 = new PageReference('/apex/RefundDialog?paymentId=' + payments[0].Id); 
        Test.setCurrentPage(currentPage2);
        OverrideActualPageController controller2 = new OverrideActualPageController();
        controller2.Refund();
    } 
    
    @isTest
    static void testPaywithDeposit()
    {
        PaymentInfo payment = new PaymentInfo();
        payment.RefundAmount = 500;
        payment.Amount = 100;
        payment.StudentActualId = 'N/A';
        payment.PayWithDeposit();
    }
}