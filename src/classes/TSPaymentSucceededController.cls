public class TSPaymentSucceededController 
{
    public String ProcessResult {get; set;}
    
    public void processSuccessPayment()
    {
       String memberId = ApexPages.currentPage().getParameters().get('memberId');
       String amount = ApexPages.currentPage().getParameters().get('amount');
       String colDate = ApexPages.currentPage().getParameters().get('date');
       String phaseNumber = ApexPages.currentPage().getParameters().get('phase');
       String vcodeValue = ApexPages.currentPage().getParameters().get('vcode');
       List<String> parameters = new List<String>{memberId, amount, phaseNumber, colDate};
       try
       {
           Boolean verificationPassed = ChinaTSUtility.validateSecuriteKey(parameters, vcodeValue);
           if(verificationPassed) 
           {
                Double currentAmount;
                Date collectedDate;
                if(memberId == null)
                {
                    throw new ParameterException('Member id is null.');
                }
                if(phaseNumber == null)
                {
                    throw new ParameterException('PhaseNumber is null.');
                }
                try
                {
                    currentAmount = Double.valueOf(amount);
                }
                catch(Exception ex)
                {
                    throw new ParameterException('Invalid amount format.');
                }
                try
                {
                    collectedDate = processDateString(colDate); 
                }
                catch(Exception ex)
                {
                    throw new ParameterException('Invalid date format.');
                }
                // Invoke utility.
                Boolean result = (new ChinaTSPaymentProcessBusiness()).processPaymentSucess(memberId, phaseNumber, collectedDate, currentAmount);
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
    static void testPaymentSucceededController()
    {
    	//String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';
        String testVcode = ChinaTSUtility.getChinaTsSecurityToken(new String[]{'87654', '9999', '2011-4-16', '2'});
        PageReference testPage = new PageReference('/apex/TSPaymentSucceeded?memberId=87654&amount=9999&date=2011-4-16&phase=2&vcode=' + testVcode);
        Test.setCurrentPage(testPage);
        TSPaymentSucceededController controller = new TSPaymentSucceededController();
        controller.processSuccessPayment();
    }
}