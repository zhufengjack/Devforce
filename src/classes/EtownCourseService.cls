/*
 * A web service of expiring, resuming and suspending course, called by Etown
 */
global class EtownCourseService
{
	private static EtownCourseRescheduleServiceStub.BasicHttpBinding_ISalesforceService rescheduleStub;
	private static EtownServiceStub.BasicHttpBinding_ISalesForceService oboeStub;
    private static final String oboeUsername = 'SalesforceSmartUser';
    private static final String oboePassword = 'SalesforceSmartPwd';
    private static final String commerceUsername = 'SFService';
    private static final String commercePassword = '12@c03f@3t0wn';
    
    //calls suspend course webservice
    public static EtownSuspendResult suspendInEtown(EtownSuspendParams params)
    {
    	EtownSuspendResult result;
    	if(!Test.isRunningTest())
    	{
	        if(rescheduleStub == null)
	        {
	            loginRescheduleEtownService();
	        }
	        if(params != null)
	        {
		        EtownCourseRescheduleServiceDataContract.SuspendParams paramsEtown = params.getParams();
		        EtownCourseRescheduleServiceDataContract.SuspendResult resultEtown = rescheduleStub.Suspend(paramsEtown);
		        if(resultEtown != null)
		    	{
		    		 result = new EtownSuspendResult(resultEtown);
		    	}
	        }
    	}
        return result;
    }
    
    //calls resume course webservice
    public static EtownResumeResult resumeInEtown(EtownResumeParams params)
    {
    	EtownResumeResult result;
    	if(!Test.isRunningTest())
    	{
	        if(rescheduleStub == null)
	        {
	            loginRescheduleEtownService();
	        }
	        if(params != null)
	        {
		        EtownCourseRescheduleServiceDataContract.ResumeParams paramsEtown = params.getParams();
		        EtownCourseRescheduleServiceDataContract.ResumeResult resultEtown = rescheduleStub.Resume(paramsEtown);
		        if(resultEtown != null)
		    	{
		    		 result = new EtownResumeResult(resultEtown);
		    	}
	        }
    	}
        return result;
    }
    
    //calls inactivate course webservice
    public static EtownInactivateResult inactivateInEtown(EtownInactivateParams params)
    {
    	EtownInactivateResult result;
    	if(!Test.isRunningTest())
    	{
	        if(rescheduleStub == null)
	        {
	            loginRescheduleEtownService();
	        }
	        if(params != null)
	        {
		        EtownCourseRescheduleServiceDataContract.InactivateParams paramsEtown = params.getParams();
		        EtownCourseRescheduleServiceDataContract.InactivateResult resultEtown = rescheduleStub.Inactivate(paramsEtown);
		        if(resultEtown != null)
		    	{
		    		 result = new EtownInactivateResult(resultEtown);
		    	}
	        }
    	}
        return result;
    }
    
    //calls cancel suspend record webservice
    public static EtownCancelSuspendResult cancelSuspendInEtown(EtownCancelSuspendParams params)
    {
    	EtownCancelSuspendResult result;
    	if(!Test.isRunningTest())
    	{
	        if(rescheduleStub == null)
	        {
	            loginRescheduleEtownService();
	        }
	        if(params != null)
	        {
		        EtownCourseRescheduleServiceDataContract.CancelSuspendParams paramsEtown = params.getParams();
		        EtownCourseRescheduleServiceDataContract.CancelSuspendResult resultEtown = rescheduleStub.CancelSuspend(paramsEtown);
		        if(resultEtown != null)
		    	{
		    		 result = new EtownCancelSuspendResult(resultEtown);
		    	}
	        }
    	}
        return result;
    }
    
    //calls map and sync contact webservice
	public static EtownLoadStudentResult loadStudentInEtown(EtownLoadStudentParams params)
	{
		EtownLoadStudentResult result; 
		if(!Test.isRunningTest())
    	{
	        if(oboeStub == null)
	        {
	            loginOboeEtownService();
	        }
	        if(params != null)
	        {
		        EtownServiceDataContract.LoadStudentParams paramsEtown = params.getParams();
		        EtownServiceDataContract.LoadStudentResult resultEtown = oboeStub.LoadStudent(paramsEtown);
		        if(resultEtown != null)
		    	{
		    		 result = new EtownLoadStudentResult(resultEtown);
		    	}
	        }
    	}
    	else //for test method
    	{
    		result = createTestLoadStudentResultData();
    	}
        return result;
	}
	
	public static EtownActivateResult activateInEtown(EtownActivateParams params)
	{
		EtownActivateResult result; 
		if(!Test.isRunningTest())
    	{
	        if(oboeStub == null)
	        {
	            loginOboeEtownService();
	        }
	        if(params != null)
	        {
		        EtownServiceDataContract.ActivateParams paramsEtown = params.getParams();
		        EtownServiceDataContract.ActivateResult resultEtown = oboeStub.Activate(paramsEtown);
		        if(resultEtown != null)
		    	{
	    			result = new EtownActivateResult(resultEtown);
		    	}
	        }
    	}
    	else //for test method
    	{
    		result = createTestActivateCourseResultData();
    	}
        return result;
	}
	
	public class EtownActivateResult
	{
		public EtownActivateResult(EtownServiceDataContract.ActivateResult result)
		{
			ErrorCode = result.ErrorCode;
			ErrorMessage = result.ErrorMessage;
			IsSuccess = result.IsSuccess;
			OrderId = result.Order_id;
			OrderEndDate = getChineseDate(result.OrderEndDate);
			OrderStartDate = getChineseDate(result.OrderStartDate);
		}
		
		public String ErrorCode { get; set; }
        public String ErrorMessage { get; set; }
        public Boolean IsSuccess { get; set; }
        public Date OrderEndDate { get; set; }
        public Date OrderStartDate { get; set; }
        public Long OrderId { get; set; }
        
        private Date getChineseDate(DateTime utcDateTime)
        {
        	Date myDate;
        	if(utcDateTime != null)
        	{
        		myDate = utcDateTime.addHours(8).dateGMT();
        	}
        	return myDate;
        }
	}
	
	public class EtownActivateParams
	{
		public String DivisionCode { get; set; } 
        public String EliteCode { get; set; }
        public String FreeRedemptionCode { get; set; }
        public Integer FreeRedemptionQty { get; set; }
        public Integer LevelQty { get; set; }
        public String MainRedemptionCode { get; set; }
        public Integer MainRedemptionQty { get; set; }
        public Integer MemberId { get; set; }
	    public Integer ProductId { get; set; }
        public String StartLevel { get; set; }
        
        public EtownServiceDataContract.ActivateParams getParams()
        {
        	EtownServiceDataContract.ActivateParams params = new EtownServiceDataContract.ActivateParams();
			params.DivisionCode = DivisionCode;
			params.EliteCode = EliteCode;
			params.FreeRedemptionCode = FreeRedemptionCode;
			params.FreeRedemptionQty = FreeRedemptionQty;
			params.LevelQty = LevelQty;
			params.MainRedemptionCode = MainRedemptionCode;
			params.MainRedemptionQty = MainRedemptionQty;
			params.Member_id = MemberId;
			params.Product_id = ProductId;
			params.StartLevel = StartLevel;
    		return params;
        }
	}
	
    private static void loginRescheduleEtownService()
    {
        rescheduleStub = new EtownCourseRescheduleServiceStub.BasicHttpBinding_ISalesforceService();
        rescheduleStub.endpoint_x = EtownServer__c.getInstance('EtownCourseReschedule').Url__c;
        rescheduleStub.timeout_x = 120 * 1000;   //2 minutes
        EtownCourseRescheduleServiceToken.UsernameToken_element token = new EtownCourseRescheduleServiceToken.UsernameToken_element();
        token.Username = commerceUsername;
        token.Password = commercePassword;
        EtownCourseRescheduleServiceToken.Security_element security = new EtownCourseRescheduleServiceToken.Security_element();
        security.UsernameToken = token;
        rescheduleStub.Security = security;
    } 
    
    private static void loginOboeEtownService()
    {
        oboeStub = new EtownServiceStub.BasicHttpBinding_ISalesForceService();
        oboeStub.endpoint_x = EtownServer__c.getInstance('Oboe server').Url__c;
        oboeStub.timeout_x = 120 * 1000;   //2 minutes
        EtownServiceToken.UsernameToken_element token = new EtownServiceToken.UsernameToken_element();
        token.Username = oboeUsername;
        token.Password = oboePassword;
        EtownServiceToken.Security_element security = new EtownServiceToken.Security_element();
        security.UsernameToken = token;
        oboeStub.Security = security;
    } 
        
    public class EtownSuspendParams
    {
    	public Integer MemberId { get; set; }
        public DateTime SuspendDate { get; set; }
        public DateTime ResumeDate { get; set; }
        public String ReasonCode { get; set; }
        
        public EtownCourseRescheduleServiceDataContract.SuspendParams getParams()
        {
        	EtownCourseRescheduleServiceDataContract.SuspendParams params = new EtownCourseRescheduleServiceDataContract.SuspendParams();
        	params.Member_id = MemberId;	
    		params.SuspendDate = SuspendDate; 
    		params.ResumeDate = ResumeDate; 
    		params.ReasonCode = ReasonCode;
    		return params;
        }
    }
    
    public class EtownSuspendResult
    {
    	public EtownSuspendResult(EtownCourseRescheduleServiceDataContract.SuspendResult result)
    	{
    		if(result != null)
    		{
	    		isSuccess = result.IsSuccess;
	    		ErrorCode = result.ErrorCode;
	    		ErrorMessage = (result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode;
	    		SuspendOperateId = result.Suspend_Operate_id;
	    		ResumeOperateId = result.Resume_Operate_id;
    		}
    	}
    	
    	public Boolean IsSuccess { get; set; }
    	public String ErrorCode { get; set; }
    	public String ErrorMessage { get; set; }
    	public Integer SuspendOperateId { get; set; }
        public Integer ResumeOperateId { get; set; }
    }
    
    public class EtownResumeParams
    {
    	public Integer MemberId { get; set; }
        public Integer ResumeId { get; set; }
        public String ReasonCode { get; set; }
        public Boolean IsResumeNow { get; set; }
        public DateTime ResumeDate { get; set; }
        
        public EtownCourseRescheduleServiceDataContract.ResumeParams getParams()
        {
        	EtownCourseRescheduleServiceDataContract.ResumeParams params = new EtownCourseRescheduleServiceDataContract.ResumeParams();
        	params.Member_id = MemberId;	
    		params.Resume_id = ResumeId; 
    		params.ReasonCode = ReasonCode; 
    		params.IsResumeNow = IsResumeNow;
    		params.ResumeDate = ResumeDate;
    		return params;
        }
    }
    
    public class EtownResumeResult
    {
    	public EtownResumeResult(EtownCourseRescheduleServiceDataContract.ResumeResult result)
    	{
    		if(result != null)
    		{
	    		isSuccess = result.IsSuccess;
	    		ErrorCode = result.ErrorCode;
	    		ErrorMessage = (result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode;
    		}
    	}
    	
    	public Boolean IsSuccess { get; set; }
    	public String ErrorCode { get; set; }
    	public String ErrorMessage { get; set; }
    }
    
    public class EtownInactivateParams
    {
    	public Integer MemberId { get; set; }
        
        public EtownCourseRescheduleServiceDataContract.InactivateParams getParams()
        {
        	EtownCourseRescheduleServiceDataContract.InactivateParams params = new EtownCourseRescheduleServiceDataContract.InactivateParams();
        	params.Member_id = MemberId;	
    		return params;
        }
    }
    
    public class EtownInactivateResult
    {
    	public EtownInactivateResult(EtownCourseRescheduleServiceDataContract.InactivateResult result)
    	{
    		if(result != null)
    		{
	    		isSuccess = result.IsSuccess;
	    		ErrorCode = result.ErrorCode;
	    		ErrorMessage = (result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode;
    		}
    	}
    	
    	public Boolean IsSuccess { get; set; }
    	public String ErrorCode { get; set; }
    	public String ErrorMessage { get; set; }
    }
    
    public class EtownCancelSuspendParams
    {
    	public Integer MemberId { get; set; }
        public Integer SuspendOperateId { get; set; }
        public Integer ResumeOperateId { get; set; }
        
        public EtownCourseRescheduleServiceDataContract.CancelSuspendParams getParams()
        {
        	EtownCourseRescheduleServiceDataContract.CancelSuspendParams params = new EtownCourseRescheduleServiceDataContract.CancelSuspendParams();
        	params.Member_id = MemberId;	
    		params.Suspend_Operate_id = SuspendOperateId; 
    		params.Resume_Operate_id = ResumeOperateId; 
    		return params;
        }
    }
    
    public class EtownCancelSuspendResult
    {
    	public EtownCancelSuspendResult(EtownCourseRescheduleServiceDataContract.CancelSuspendResult result)
    	{
    		if(result != null)
    		{
	    		isSuccess = result.IsSuccess;
	    		ErrorCode = result.ErrorCode;
	    		ErrorMessage = (result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode;
    		}
    	}
    	
    	public Boolean IsSuccess { get; set; }
    	public String ErrorCode { get; set; }
    	public String ErrorMessage { get; set; }
    }
    
    public class EtownLoadStudentParams
    {
		public Boolean RequireSyncReschedule { get; set; }
        public String Username { get; set; }
        
        public EtownServiceDataContract.LoadStudentParams getParams()
        {
        	EtownServiceDataContract.LoadStudentParams params = new EtownServiceDataContract.LoadStudentParams();
        	params.Username = Username;
        	params.RequireSyncReschedule = RequireSyncReschedule;
        	return params;
        }
    }
    
    public class EtownLoadStudentResult
    {
    	public EtownLoadStudentResult(EtownServiceDataContract.LoadStudentResult result)
    	{
    		if(result != null)
    		{
	    		IsSuccess = result.IsSuccess;
	    		ErrorCode = result.ErrorCode;
	    		ErrorMessage = (result.ErrorMessage != '' && result.ErrorMessage != null) ? result.ErrorMessage : result.ErrorCode;
	    		MemberInfo = new EtownMemberInfo(result.MemberInfo);
    		}
    	}
    	
    	public String ErrorCode { get; set; }
        public String ErrorMessage { get; set; }
        public Boolean IsSuccess { get; set; }
        public EtownMemberInfo MemberInfo { get; set; }
    }
    
    public class EtownMemberInfo
    {
    	public EtownMemberInfo(EtownServiceDataContract.MemberInfo memberInfo)
    	{
    		if(memberInfo != null)
    		{
	    		CurrentLevel = memberInfo.CurrentLevel;
	    		CurrentSchool = memberInfo.CurrentSchool;
	    		MemberId = memberInfo.Member_id;
	    		Status = memberInfo.Status;
	    		Email = memberInfo.Email;
	    		MobilePhone = memberInfo.MobilePhone;
	    		RescheduleList = new EtownCourseRescheduleList(memberInfo.RescheduleList);
    		}
    	}
    	
    	public String CurrentLevel { get; set; }
        public String CurrentSchool { get; set; }
        public Integer MemberId { get; set; }
        public String Email { get; set; }
        public String MobilePhone { get; set; }
        public EtownCourseRescheduleList RescheduleList { get; set; }
        public String Status { get; set; }
    }
    
    public class EtownCourseRescheduleList
    {
    	public EtownCourseRescheduleList(EtownServiceDataContract.ArrayOfRescheduleInfo ArrayInfo)
    	{
    		ReshceduleInfoList = new List<EtownCourseRescheduleInfo>();
    		if(ArrayInfo != null && ArrayInfo.RescheduleInfo != null)
    		{
	    		for(EtownServiceDataContract.RescheduleInfo info : ArrayInfo.RescheduleInfo)
	    		{
	    			ReshceduleInfoList.add(new EtownCourseRescheduleInfo(info));
	    		}
    		}
    	}
    	public List<EtownCourseRescheduleInfo> ReshceduleInfoList { get; set; }
    }
    
    public class EtownCourseRescheduleInfo
    {
    	public EtownCourseRescheduleInfo(EtownServiceDataContract.RescheduleInfo info)
    	{
    		if(info != null)
    		{
	    		OperateDate = info.OperateDate;
	    		OperateType = info.OperateType;
	    		OperateId = info.Operate_id;
    		}
    	}
    	
    	public DateTime OperateDate { get; set; } 
        public String OperateType { get; set; } 
        public Integer OperateId { get; set; }
    }
    
    //The webservice methods which ara expiring, resuming and suspending course, called by Etown
	webservice static StudentExpireResult expire(StudentExpireParams param)
	{
		StudentExpireResult result = new StudentExpireResult();
		result.IsSuccess = false;
		result.ErrorCode = '0';
		if(param != null && param.MemberId != null)
		{
			List<Contact> students = [select Id, EtownMemberId__c, Status__c from Contact where EtownMemberId__c = :param.MemberId limit 1];
			if(students.size() > 0)
			{
				if(students[0].Status__c == 'Expired')
				{
					result.IsSuccess = true;
				}
				else  
				{
					try 
					{
						update new Contact(Id = students[0].Id, Status__c = 'Expired');
						result.IsSuccess = true;
					}
					catch(Exception ex)
					{
						String error = ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n The member Id of contact:' + param.MemberId;
						EtownCourseHelper.sendErrorInfoEmail('An error occurred on expire method of EtownCourseService class', error);
						result.ErrorMessage = ex.getMessage();						
					}
				}
			}
		}
		else
		{
			result.ErrorMessage = 'StudentExpireParams or MemberId is null';
		}
		return result;
	}
	
	webservice static StudentSuspendResult suspend(StudentSuspendParams param)
	{
		StudentSuspendResult result = new StudentSuspendResult();
		result.IsSuccess = false;
		result.ErrorCode = '0';
		if(param != null) 
		{
			EtownCourseHelper.StudentActionParams actionParams = new EtownCourseHelper.StudentActionParams();
			actionParams.MemberId = param.MemberId;
			actionParams.OperateId = param.OperateId;
			actionParams.ActionTypeName = EtownCourseHelper.ActionType.SUSPEND;
			try
			{
				EtownCourseHelper.updateStatusAndDate(actionParams);
				result.IsSuccess = true;
			}
			catch(Exception ex)
			{
				String error = ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n The member Id of contact:' + param.MemberId + ' OperateId:' + param.OperateId;
				EtownCourseHelper.sendErrorInfoEmail('An error occurred on suspend method of EtownCourseService class', error);
				result.ErrorMessage = ex.getMessage();
			}
		}
		else
		{
			result.ErrorMessage = 'StudentSuspendParams is null';
		}
		return result;
	}
	
	webservice static StudentResumeResult resume(StudentResumeParams param)
	{
		StudentResumeResult result = new StudentResumeResult();
		result.IsSuccess = false;
		result.ErrorCode = '0';
		if(param != null)
		{
			EtownCourseHelper.StudentActionParams actionParams = new EtownCourseHelper.StudentActionParams();
			actionParams.MemberId = param.MemberId;
			actionParams.OperateId = param.OperateId;
			actionParams.ActionTypeName = EtownCourseHelper.ActionType.RESUME;
			try
			{
				EtownCourseHelper.updateStatusAndDate(actionParams);
				result.IsSuccess = true;
			}
			catch(Exception ex)
			{
				String error = ex.getMessage() + '\r\n' + ex.getStackTraceString() + '\r\n The member Id of contact:' + param.MemberId + ' OperateId:' + param.OperateId;
				EtownCourseHelper.sendErrorInfoEmail('An error occurred on resume method of EtownCourseService class', error);
				result.ErrorMessage = ex.getMessage();
			}
		}
		else
		{
			result.ErrorMessage = 'StudentResumeParams is null';
		}
		return result;
	}
	
	//To use by expire course
	global class StudentExpireParams
	{
		webservice Integer MemberId;
	}
	
	global class StudentExpireResult
	{
		webservice Boolean IsSuccess;
		webservice String ErrorCode;
		webservice String ErrorMessage;
	}
	
	//To use by resume course
	global class StudentResumeParams
	{
		webservice Integer MemberId;
        webservice Integer OperateId;
	}
	
	global class StudentResumeResult
	{
		webservice Boolean IsSuccess;
		webservice String ErrorCode;
		webservice String ErrorMessage;
	}
	
	//To use by suspend course
	global class StudentSuspendParams
	{
		webservice Integer MemberId;
        webservice Integer OperateId;
	}
	
	global class StudentSuspendResult
	{
		webservice Boolean IsSuccess;
		webservice String ErrorCode;
		webservice String ErrorMessage;
	}
	
	//for test mehtod
	private static EtownLoadStudentResult createTestLoadStudentResultData()
	{
		EtownServiceDataContract.LoadStudentResult testResult = new EtownServiceDataContract.LoadStudentResult();
		testResult.IsSuccess = true;
    	EtownServiceDataContract.MemberInfo testMemberInfo = new EtownServiceDataContract.MemberInfo();
        testMemberInfo.Status = 'Active';
    	testMemberInfo.Member_id = -0000000012;
    	List<EtownServiceDataContract.RescheduleInfo> testInfos = new List<EtownServiceDataContract.RescheduleInfo>();
    	EtownServiceDataContract.RescheduleInfo	testInfo1Resume = new EtownServiceDataContract.RescheduleInfo();
    	testInfo1Resume.OperateDate = DateTime.now();
    	testInfo1Resume.OperateType = 'Resume';
    	testInfo1Resume.Operate_id = 123;
    	EtownServiceDataContract.RescheduleInfo	testInfo2Suspend = new EtownServiceDataContract.RescheduleInfo();
    	testInfo2Suspend.OperateDate = DateTime.now().addDays(10);
    	testInfo2Suspend.OperateType = 'Suspend';
    	testInfo2Suspend.Operate_id = 124;
    	EtownServiceDataContract.RescheduleInfo	testInfo2Resume = new EtownServiceDataContract.RescheduleInfo();
    	testInfo2Resume.OperateDate = DateTime.now().addDays(20);
    	testInfo2Resume.OperateType = 'Resume';
    	testInfo2Resume.Operate_id = 125;
    	testInfos.add(testInfo2Resume);
    	testInfos.add(testInfo2Suspend);
    	testInfos.add(testInfo1Resume);
    	EtownServiceDataContract.ArrayOfRescheduleInfo testRescheduleList = new EtownServiceDataContract.ArrayOfRescheduleInfo();
    	testRescheduleList.RescheduleInfo = testInfos;
    	testMemberInfo.RescheduleList = testRescheduleList;
    	testResult.MemberInfo = testMemberInfo;
		return new EtownLoadStudentResult(testResult);
	}
	
	private static EtownActivateResult createTestActivateCourseResultData()
	{
		EtownServiceDataContract.ActivateResult result = new EtownServiceDataContract.ActivateResult();
		result.IsSuccess = true;
		result.Order_id = 123424143;
		result.OrderStartDate = Date.today();
		result.OrderEndDate = Date.today().addDays(20);
		return new EtownActivateResult(result);
	}
	
	@isTest
	static void testEtownCourseService()
	{
		EtownCourseService.loginOboeEtownService();
		EtownCourseService.loginRescheduleEtownService();
		EtownCourseService.EtownMemberInfo info = new EtownCourseService.EtownMemberInfo(new EtownServiceDataContract.MemberInfo());
		EtownCourseService.EtownCourseRescheduleList rescheduleList = new EtownCourseService.EtownCourseRescheduleList(new EtownServiceDataContract.ArrayOfRescheduleInfo());
		EtownCourseService.EtownCourseRescheduleInfo crInfo = new EtownCourseService.EtownCourseRescheduleInfo(new EtownServiceDataContract.RescheduleInfo());
	}
	
	@isTest
	static void testSuspendInEtown()
	{
		EtownCourseService.EtownSuspendParams params = new EtownCourseService.EtownSuspendParams();
		params.MemberId = 1122;
		params.SuspendDate = Date.today();
		params.ResumeDate = Date.today().addDays(7);
		params.ReasonCode = '0';
		params.getParams();
		EtownCourseService.suspendInEtown(params);
		EtownCourseService.EtownSuspendResult result = new EtownCourseService.EtownSuspendResult(new EtownCourseRescheduleServiceDataContract.SuspendResult());
	}
	
	@isTest
	static void testResumeInEtown()
	{
		EtownCourseService.EtownResumeParams params = new EtownCourseService.EtownResumeParams();
		params.MemberId = 1122;
		params.ResumeId = 2211;
		params.ResumeDate = Date.today().addDays(7);
		params.ReasonCode = '0';
		params.IsResumeNow = true;
		params.getParams();
		EtownCourseService.resumeInEtown(params);
		EtownCourseService.EtownResumeResult result = new EtownCourseService.EtownResumeResult(new EtownCourseRescheduleServiceDataContract.ResumeResult());
	}
	
	@isTest
	static void testInactivateInEtown()
	{
		EtownCourseService.EtownInactivateParams params = new EtownCourseService.EtownInactivateParams();
		params.MemberId = 1122;
		params.getParams();
		EtownCourseService.inactivateInEtown(params);
		EtownCourseService.EtownInactivateResult result = new EtownCourseService.EtownInactivateResult(new EtownCourseRescheduleServiceDataContract.InactivateResult());
	}
	
	@isTest
	static void testCancelSuspendInEtown()
	{
		EtownCourseService.EtownCancelSuspendParams params = new EtownCourseService.EtownCancelSuspendParams();
		params.MemberId = 1122;
		params.SuspendOperateId = 2211;
		params.ResumeOperateId = 4534;
		params.getParams();
		EtownCourseService.cancelSuspendInEtown(params);
		EtownCourseService.EtownCancelSuspendResult result = new EtownCourseService.EtownCancelSuspendResult(new EtownCourseRescheduleServiceDataContract.CancelSuspendResult());
	}
	
	@isTest
	static void testLoadStudentInEtown()
	{
		EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
		params.RequireSyncReschedule = true;
		params.UserName = 'Test';
		params.getParams();
		EtownCourseService.loadStudentInEtown(params);
		EtownCourseService.EtownLoadStudentResult result = new EtownCourseService.EtownLoadStudentResult(new EtownServiceDataContract.LoadStudentResult());
	}
	
	@isTest
	static void testSuspend()
	{
		EtownCourseService.StudentSuspendParams params = new EtownCourseService.StudentSuspendParams();
		params.MemberId = 1111;
		params.OperateId = 2222;
		EtownCourseService.StudentSuspendResult result = new EtownCourseService.StudentSuspendResult();
		EtownCourseService.suspend(params);
	}
	
	@isTest
	static void testExpire()
	{
		EtownCourseService.StudentExpireParams params = new EtownCourseService.StudentExpireParams();
		params.MemberId = 1111;
		EtownCourseService.StudentExpireResult result = new EtownCourseService.StudentExpireResult();
		EtownCourseService.expire(params);
	}
	
	@isTest
	static void testResume()
	{
		EtownCourseService.StudentResumeParams params = new EtownCourseService.StudentResumeParams();
		params.MemberId = 1111;
		params.OperateId = 2222;
		EtownCourseService.StudentResumeResult result = new EtownCourseService.StudentResumeResult();
		EtownCourseService.resume(params);
	}
	
	@isTest
	static void testActivate()
	{
		EtownCourseService.EtownActivateParams params = new EtownCourseService.EtownActivateParams();
		params.DivisionCode = 'bj';
		params.EliteCode = 'acme';
		params.FreeRedemptionCode = 'acme';
		params.FreeRedemptionQty = 1;
		params.LevelQty = 1;
		params.MainRedemptionCode = 'acme';
		params.MainRedemptionQty = 1;
		params.MemberId = 0000011100;
		params.getParams();
		EtownCourseService.EtownActivateResult result = new EtownCourseService.EtownActivateResult(new EtownServiceDataContract.ActivateResult());
		EtownCourseService.activateInEtown(params);
	}
}