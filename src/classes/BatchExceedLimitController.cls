public class BatchExceedLimitController 
{
	public String ErrorMessage { get; set; }
	public String CnErrorMessage {get; set;}
	
	public BatchExceedLimitController()
	{
		String errorType = ApexPages.currentPage().getParameters().get('type');
		if(errorType == '0')
		{
			ErrorMessage = 'Your current request is in process. Please wait patiently. You can submit the new request when the previous one is completed.';
			CnErrorMessage = '你当前提交的request还在处理中。请耐心等待。当前面的request完成后，你会收到邮件，然后可以开始新的mass transfer request.';
		}
		else
		{
			ErrorMessage = 'Your can\'t submit this request now. 5 mass transfer request are in the queue currently. Please wait patiently and try again later.';
			CnErrorMessage = '当前request不能被提交，目前系统中有5个request在排队，请耐心等待，稍后再试。';
		}
	}
	
	@isTest
	static void testBatchExceedLimitController()
	{
		PageReference testPage = new PageReference('/apex/BatchExceedLimit');
		test.setCurrentPage(testPage);
		BatchExceedLimitController controller = new BatchExceedLimitController();
	}
	
	@isTest
	static void testCurrentUserBatchExceedLimit()
	{
		PageReference testPage = new PageReference('/apex/BatchExceedLimit?type=0');
		test.setCurrentPage(testPage);
		BatchExceedLimitController controller = new BatchExceedLimitController();
	}
}