/*
* Gets student actuals with payment records created today and sends this information to cashiers in each school via email.
*/
public class DailyDiscrepancyReportService
{ 
    public static final String FinanceUserProfileId = '00e40000000jdzW'; 
    public static final String DailyDiscrepancyReportEmailTemplate = '00X90000000crtV'; //'00XO0000000LweU':sand box. '00X90000000crtV';
    public List<String> schoolNames = new List<String>();
    
    private Map<String, List<StudentActual__c>> studentActualMap = new Map<String, List<StudentActual__c>>();  //key: school name, value: list of student actual
    private EmailTemplate discrepancyTemplate;

    public DailyDiscrepancyReportService(List<String> schoolNameList) 
    {
            schoolNames = schoolNameList;
        List<StudentActual__c> studentActuals = getStudentActuals().values();
                 
        if(!studentActuals.isEmpty())
        { 
            for(StudentActual__c student : studentActuals)
            { 
                //groups student actuals by scholl
                String name = student.Name;
                String schoolName = student.Actual__r.Sales_Appt_Locations_2__c;      
                if(!studentActualMap.containsKey(schoolName))
                {
                    studentActualMap.put(schoolName, new List<StudentActual__c> { student });
                }
                else
                {
                    studentActualMap.get(schoolName).add(student);
                }
            }
        }  
    }
    
    public EmailTemplate Template
    {
        get
        {
            if(discrepancyTemplate == null)
            {
                EmailTemplate template = [select Id, Subject, HtmlValue, Body from EmailTemplate where Id =:DailyDiscrepancyReportEmailTemplate limit 1];
                return template;
            }
            return discrepancyTemplate;
        }
    }
    
    public void sendEmail()
    {
        if(studentActualMap.size() > 0)
        { 
            List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
            List<User> userList = [select Id, Name, Email, SchoolName__c, UserRoleId, UserRole.Name from User where ProfileId = :FinanceUserProfileId and IsActive=true];          
            if(userList.size() > 0)
            {
                for(User user : userList)
                {
                    String currentSchoolName = user.SchoolName__c.replace('_', ' ');
                    if(studentActualMap.containsKey(currentSchoolName))
                    {  
                        List<StudentActual__c> students = studentActualMap.get(currentSchoolName);
                        emails.add(GenerateEmailReport(currentSchoolName, user, students));   
                    }   
                }
                Messaging.sendEmail(emails);
            }       
        }   
    }
    
    //generates the discrepancy report with the specified cashier and student actuals.
    private Messaging.SingleEmailMessage GenerateEmailReport(String schoolName, User cashier, List<StudentActual__c> students)
    {
        Map<String, List<StudentActual__c>> teamActualMap = new Map<String, List<StudentActual__c>>();  //key: actual id, value: list of student actuals
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        for(StudentActual__c student : students)
        {
            //groups students by actual
            if(teamActualMap.containsKey(student.Actual__c))
            {
                teamActualMap.get(student.Actual__c).add(student);
            }
            else
            {
                teamActualMap.put(student.Actual__c, new List<StudentActual__c> { student });
            }
        }
        ReportBuilder builder = new ReportBuilder(schoolName);
        builder.setData(teamActualMap);
        String report = builder.BuildResult();
         
        mail.setToAddresses(new String[]{ cashier.Email }); 
        mail.setCcAddresses(new String[]{ 'Anita.Lu@ef.com' });
        mail.setBccAddresses(new String[] { 'hobart.cui@meginfo.com' });
        mail.setSenderDisplayName('Englishtown Salesforce Team');
        //mail.setPlainTextBody(plainTextBody);
        mail.setUseSignature(false);                 
        
        
        mail.setSubject(Template.Subject);
        String emailBody = (Template.Body).replace('{!body}', report).replace('{!name}', cashier.Name);
        mail.setHtmlBody(emailBody);
        return mail;
    }
    
    //report builder class, to build the discrepancy report html.
    public class ReportBuilder
    {
        private String reportHeader = '<hr/><br/><div style="text-align:center">Daily Discrepancy Report ({!SchoolName} ' + convertValue(Date.today()) + ')</div><br/>';
        private String tableHeader = '<table cellspacing="0" width="100%" border="1" style="border-color:#F0F0F0;background-color:#F5F5F5;font-family:arial;font-size:10pt;" >' + 
                                                        '<tr>'+
                                                            '<th>Actual Name</th>'+
                                                            '<th>Sales Type</th>'+
                                                            '<th>Stage</th>'+
                                                            '<th>Close Date</th>'+ 
                                                            '<th>Contract Type</th>'+
                                                            '<th>Final Price</th>'+
                                                            '<th>CN Payment Total</th>'+
                                                            '<th>Refund Amount</th>'+
                                                            '<th>CN Refund Total</th>'+
                                                            '<th>Student</th>'+
                                                            '<th>CN Actual Collection</th>'+
                                                            '<th>CN Actual Refund</th>'+
                                                        '</tr>';
        /*private String tableRowHeader = '<tr><td colspan="5"><a href="https://ap1.salesforce.com/{!ActualId}"><b>{!ActualName}</b></a></td></tr>' + 
                                          '<tr><td colspan="5"><b>Close Date: {!CloseDate}</b></td></tr>' +
                                          '<tr><td colspan="5"><b>Contract Type: {!ContractType}</b></td></td>';
        private String tableSubRow = '<tr>' +
                                        '<td>{!StudentActualName}</td>' + 
                                        '<td align="right">{!FinalPrice}</td>' +
                                        '<td align="right">{!CNPaymentTotal}</td>' +
                                        '<td align="right">{!RefundAmount}</td>' +
                                        '<td align="right">{!CNRefundTotal}</td>' +
                                     '</tr>';
         */
        private String tableRowHeader = '<tr>'+
                                                            '<td align="center"><a href="https://ap1.salesforce.com/{!ActualId}"><b>{!ActualName}</b></a></td>'+
                                                            '<td align="center">{!SalesType}</td>'+
                                                            '<td align="center">{!Stage}</td>'+
                                                            '<td align="center">{!CloseDate}</td>'+
                                                            '<td align="center">{!ContractType}</td>'+
                                                            '<td align="right">{!FinalPrice}</td>'+
                                                            '<td align="right">{!CNPaymentTotal}</td>'+
                                                            '<td align="right">{!RefundAmount}</td>'+
                                                            '<td align="right">{!CNRefundTotal}</td>'+
                                                            '<td align="center">{!StudentActual}</td>'+
                                                            '<td align="right">{!ActualCollection}</td>'+
                                                            '<td align="right">{!ActualRefund}</td>'+
                                                        '</tr>';
        private String tableFooter = '</table><br/>';
        private String reportFooter = '<hr/>';
        
        private Map<String, List<StudentActual__c>> data;
        
        public void SetData(Map<String, List<StudentActual__c>> data)
        {
            this.data = data;
        }
        
        public ReportBuilder(String schoolName)
        {
            data = new Map<String, List<StudentActual__c>>();
            reportHeader = reportHeader.replace('{!SchoolName}', schoolName);
        }
        
        public String BuildResult()
        {
            String result = reportHeader;

            result += tableHeader;
            for(String actualId : data.keySet())
            {
                List<StudentActual__c> students = data.get(actualId);
                if(students.size() > 0 && students[0].Actual__r != null)
                {
                    String actualName = students[0].Actual__r.Name;
                    String closeDate = convertValue(students[0].Actual__r.Close_Date__c);
                    String contractType = (students[0].Actual__r.Contract_Type__c == null)?'':students[0].Actual__r.Contract_Type__c;
                    String finalPrice = convertValue(students[0].Actual__r.Final_Price__c);
                    String paymentTotal = convertValue(students[0].Actual__r.CN_Payment_Total__c);
                    String refundAmount = convertValue(students[0].Actual__r.Refund_Amount__c);
                    String cnRefundTotal = convertValue(students[0].Actual__r.CN_Refund_Total__c);
                    String actualResult = tableRowHeader.replace('{!ActualId}', actualId).replace('{!ActualName}', actualName).replace('{!CloseDate}', closeDate).replace('{!ContractType}', contractType).replace('{!FinalPrice}', finalPrice).replace('{!CNPaymentTotal}', paymentTotal).replace('{!RefundAmount}', refundAmount).replace('{!CNRefundTotal}', cnRefundTotal);
                        for(StudentActual__c studentActual : students)
                        {
                            String tempRow = actualResult;
                            String studentName = studentActual.Name;
                            String cnActualCollection = convertValue(studentActual.CN_Gross_Revenue__c);
                            String cnActualrefund = convertValue(studentActual.CN_Total_Refund__c);
                            String salesType = studentActual.Actual__r.China_Sales_Type__c;
                            String stage = studentActual.Actual__r.Opportunity__r.StageName;
                            result += tempRow.replace('{!StudentActual}', studentName).replace('{!ActualCollection}', cnActualCollection).replace('{!ActualRefund}', cnActualrefund).replace('{!SalesType}', salesType).replace('{!Stage}', stage);
                        }
                }
            }
            result += tableFooter;    
            result += reportFooter;
            return result;
        }
        
        private String convertValue(Date value)
        {
            return (value == null)? '' : value.year() + '-' + value.month() + '-' + value.day();
        }
        private String convertValue(Decimal value)
        {
            return (value == null)? '' : String.valueOf(value);
        }
    }
    
    private Map<Id, StudentActual__c> getStudentActuals()
    {
            Map<Id, StudentActual__c> studentActualMap = new Map<Id, StudentActual__c>();
        List<StudentActual__c> studentActuals = [select Id, Name, FinalPrice__c, CN_Gross_Revenue__c, CN_Total_Refund__c, CNPaymentTotal__c, RefundAmount__c, CNRefundTotal__c, Actual__c, Actual__r.CN_Gross_Revenue__c, Actual__r.China_Sales_Type__c, Actual__r.Opportunity__r.StageName, Actual__r.Name, Actual__r.Close_Date__c, Actual__r.Contract_Type__c, Actual__r.Sales_Appt_Locations_2__c, Actual__r.Final_Price__c, Actual__r.CN_Payment_Total__c, Actual__r.CN_Refund_Total__c, Actual__r.Refund_Amount__c, (select Id from StudentProducts__r limit 1) from StudentActual__c where Id in (select StudentActual__c from PaymentData__c where (CreatedDate = TODAY or CreatedDate = LAST_N_DAYS:6) and Actual__r.RecordType.Name like 'China Smart%' and Pay_Type__c = 'China Smart Payment'  and Actual__r.Sales_Appt_Locations_2__c in :schoolNames)];
        for(StudentActual__c studentActual : studentActuals)
        {
            Boolean judgementResult = judgementReportStudentActual(studentActual);
            if(judgementResult && !studentActualMap.containsKey(studentActual.Id))
            {
                studentActualMap.put(studentActual.Id, studentActual);
            }
        }
        return studentActualMap;
    }
    
    private Boolean judgementReportStudentActual(StudentActual__c studentActual)
    {
            if(studentActual != null)
            {
                if(studentActual.Actual__r.Final_Price__c != studentActual.Actual__r.CN_Payment_Total__c)
                {
                	    if(studentActual.Actual__r.China_Sales_Type__c != 'Deposit' && studentActual.Actual__r.China_Sales_Type__c != 'Double Pay')
                	    {
                	       return true;
                	    }
                }
                if(studentActual.Actual__r.Refund_Amount__c != studentActual.Actual__r.CN_Refund_Total__c)
                {
                	    if(studentActual.Actual__r.China_Sales_Type__c != 'Deposit' && studentActual.Actual__r.China_Sales_Type__c != 'Double Pay')
                	    {
                	       return true;
                	    }
                }
                if(studentActual.Actual__r.China_Sales_Type__c != 'Deposit' && studentActual.Actual__r.China_Sales_Type__c != 'Double Pay')
                {
                    if(studentActual.StudentProducts__r.size() == 0)
                    {
                        return true;
                    }
                }
                if(studentActual.Actual__r.China_Sales_Type__c == 'Deposit' && studentActual.Actual__r.CN_Gross_Revenue__c != 0)
                {
                    return true;
                }
                if(studentActual.Actual__r.Opportunity__r.StageName != 'Closed Won')
                {
                    return true;
                }
            }
            return false;
    }
    
    @isTest
    static void testService()
    {
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        Date otherDay = currentDate.addDays(1);
        Datetime otherTime = currentTime.addDays(1); 
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1];
    
        Account student = new Account(Name = 'Jimmy01');
        insert student;
        Contact cont = new Contact(LastName = 'acme1 name', EtownMemberId__c = 234, AccountId = student.Id, Email = 'acme@g.com', phone = '123456');
        insert cont;
        
        Opportunity opp = new Opportunity(Name = 'Jimmy test1', AccountId = student.Id, Location__c = 'BJ CYM', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        insert opp;
        Actual__c testActual = new Actual__c(Account__c = student.Id,Opportunity__c = opp.Id, China_Sales_Type__c = 'New');
        insert testActual;
        
        StudentActual__c studentActual = new StudentActual__c(Actual__c = testActual.Id, Student__c = cont.Id, EliteCard__c = '1234', StartingLevel__c = 'Beginner-Level0A');
        insert studentActual;
        
        Product2 product = new Product2(Name = 'Premium 10', EtownId__c = '123456789', IsLevel__c = true);
        Product2 product2 = new Product2(Name = 'test', EtownId__c = '12345678');
        insert new Product2[]{product, product2};
        
        StudentProduct__c studentProduct = new StudentProduct__c(StudentActual__c = studentActual.Id, product__c = product.Id, LevelsPurchased__c = '3', FreeLength__c = '4');
        insert studentProduct;
        
        PaymentData__c pd1 = new PaymentData__c(Actual__c = testActual.Id, Pay_Type__c = 'China Smart Payment', StudentActual__c = studentActual.Id, Amount__c = 100.00 ); 
        insert pd1;
        PaymentData__c pd2 = new PaymentData__c(Actual__c = testActual.Id, Pay_Type__c = 'China Smart Payment', StudentActual__c = studentActual.Id, Amount__c = 63.00); 
        insert pd2;
        
        List<PaymentData__c> payments = [select StudentActual__c, Actual__r.Sales_Appt_Locations_2__c from PaymentData__c where CreatedDate = TODAY and  Actual__r.RecordType.Name like 'China Smart%' and Actual__r.Sales_Appt_Locations_2__c != null limit 2];
        List<String> schoolNameList = new List<String>();
        for(PaymentData__c payment : payments)
        {
            schoolNameList.add(payment.Actual__r.Sales_Appt_Locations_2__c);
        }
        schoolNameList.add('BJ CYM');
        DailyDiscrepancyReportService ddr = new DailyDiscrepancyReportService(schoolNameList);
        ddr.sendEmail();
    } 
}