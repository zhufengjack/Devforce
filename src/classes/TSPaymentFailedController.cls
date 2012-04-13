public class TSPaymentFailedController 
{   
    public String ProcessResult {get; set;}
    
    public void processFailurePayment()
    {
       String memberId = ApexPages.currentPage().getParameters().get('memberId');
       String failureReason = ApexPages.currentPage().getParameters().get('reason');
       String phaseNumber = ApexPages.currentPage().getParameters().get('phase');
       String vcodeValue = ApexPages.currentPage().getParameters().get('vcode');
       String colDate = ApexPages.currentPage().getParameters().get('date');
       List<String> parameters = new List<String>{memberId, failureReason, phaseNumber,colDate};
       try
       {
           Boolean verificationPassed = ChinaTSUtility.validateSecuriteKey(parameters, vcodeValue);
           //verificationPassed = true;
           if(verificationPassed) 
           {
           	    Date collectedDate;
                if(memberId == null)
                {
                    throw new ParameterException('Member id is null.');
                }
                if(phaseNumber == null)
                {
                    throw new ParameterException('Phase number is null.');
                }
                try
                {
                    collectedDate = processDateString(colDate);
                }
                catch(Exception ex)
                {
                    throw new  ParameterException('Invalid date format.');
                }
                Boolean result = (new ChinaTSPaymentProcessBusiness()).processPaymentFailed(memberId, phaseNumber, failureReason, collectedDate);
                if(result == true)
                {
                    ProcessResult = 'Update Successful';
                }
                else
                {
                    ProcessResult = 'Update Failed';
                }
           }
           else
           {
               ProcessResult = 'Authentication Failed';
           }    
       }
       catch(Exception ex)
       {
            ProcessResult = ex.getMessage();
       }
                                  
    } 
    
    private Date processDateString(String dateParameter)
    {
        if(dateParameter != null)
        {
           List<String> splitList = dateParameter.split('-');
           Date resultDate = Date.newInstance(Integer.valueOf(splitList[0]), Integer.valueOf(splitList[1]), Integer.valueOf(splitList[2]));
           return resultDate;
        }
        else
        {
            return null;
        }
    }
    
    public class ParameterException extends Exception {}
    
    @isTest
    static void testPaymentFailedController()
    {
        String testVcode = ChinaTSUtility.getChinaTsSecurityToken(new String[]{'43234', '003', '3', '2011-4-16'});
        PageReference testPage = new PageReference('/apex/TSPaymentFailed?memberId=43234&reason=003&phase=3&date=2011-4-16&vcode=' + testVcode);
        test.setCurrentPage(testPage);
        TSPaymentFailedController controller = new TSPaymentFailedController();
        controller.processFailurePayment();
    }
}