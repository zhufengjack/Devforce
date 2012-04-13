/*
*    Controller for "China Ts Refund Dialog" page.
*/
public class ChinaTSRefundDialogController 
{
	public China_Smart_Refund__c RefundRecord {get;set;}
	public double InitRefundAmount {get;set;}
	private PaymentData__c currentPayment;
	
    public ChinaTSRefundDialogController()
    {
        String paymentId = ApexPages.currentPage().getParameters().get('paymentId');
        List<PaymentData__c> payments;
        if(paymentId != null && paymentId != '')
        {
        	payments = [select Id, Payment_method__c from PaymentData__c where Id = :paymentId];
        }
        if(payments == null || payments.size() < 0)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No payment data specfited for the refud record.'));
        }
        else
        {
        	// Initial payment data.
        	currentPayment = payments[0];
        }
        RefundRecord = new China_Smart_Refund__c();
        RefundRecord.Refund_Date_China__c = date.today();
        RefundRecord.Refund_Payment_Method__c = (currentPayment != null)? currentPayment.Payment_method__c: '';
        InitRefundAmount = 0;
        String amountStr = Apexpages.currentPage().getParameters().get('amount');
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
    
    public PageReference tsRefund()
    {
        String paymentId = ApexPages.currentPage().getParameters().get('paymentId');
        String refundAmountLimitedString = ApexPages.currentPage().getParameters().get('amount');
        if(paymentId != null)
        {
            Double refundAmountLimited = (refundAmountLimitedString == null)? 0: Double.valueOf(refundAmountLimitedString);
            RefundRecord.China_Payment_Data__c = paymentId;
            Boolean isValid = true;
            if(RefundRecord.Refund_Amount__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Amount is blank for the refud record.'));
                isValid = false;
            }
            else if(RefundRecord.Refund_Amount__c > refundAmountLimited)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund amount can\'t greater than ' + refundAmountLimited + '.'));
                isValid = false;
            }
            if(RefundRecord.Refund_Date_China__c == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Refund Date is blank for the refud record.'));
                isValid = false;
            }
            if(isValid && RefundRecord.Id == null)
            {
                try
                {
                    insert RefundRecord;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'you have successed to create a refund record.<script>refreshParent();</script>'));
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
    
    @isTest
    static void testChinaTSRefundDialogController()
    {
        String chinaTSActualRecordTypeId = [select Id, Name from RecordType where Name = 'China TS Actual Record Type' and SobjectType = 'Actual__c'].Id;
        Actual__c testActual = new Actual__c(RecordTypeId = chinaTSActualRecordTypeId);
        insert testActual;
        StudentActual__c testStudentActual = new StudentActual__c(Actual__c = testActual.Id, Name = 'Test cnts student actual');
        insert testStudentActual;
        PaymentData__c payment1 = new PaymentData__c(Actual__c = testActual.Id, Amount__c = 3000, StudentActual__c = testStudentActual.Id, Pay_Type__c = 'China TS Payment', TransDatetime__c = datetime.now(), Status__c = 'Paid');
        insert payment1;
        PageReference testpage = new PageReference('/apex/ChinaTSRefundDialog?paymentId=' + payment1.Id + '&amount=' + 3000);
        Test.setCurrentPage(testpage);
        ChinaTSRefundDialogController controller = new ChinaTSRefundDialogController();
        controller.RefundRecord.Refund_Amount__c = null;
        controller.tsRefund();
        controller.RefundRecord.Refund_Amount__c = 3001;
        controller.tsRefund();
        controller.RefundRecord.Refund_Amount__c = 3000;
        controller.tsRefund();
    }
}