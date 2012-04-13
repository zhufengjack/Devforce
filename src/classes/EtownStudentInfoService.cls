global class EtownStudentInfoService 
{   
    webservice static String checkAndUpdateStudentInfo(String studentId)
    { 
    	String message = '';
        Datetime currentTime = System.now();
        
        List<Contact> students = [select Id, Name, EtownUserName__c, LastRefreshDate__c, IsRescheduleSynced__c  from Contact where Id =:studentId and EtownUserName__c != null limit 1];
        if(students.size() > 0)
        {   
			Contact student = students[0];
            EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
            params.Username = student.EtownUserName__c;
            params.RequireSyncReschedule = (!student.IsRescheduleSynced__c);
            EtownCourseService.EtownLoadStudentResult result;
            try
            { 
	            result = EtownCourseService.loadStudentInEtown(params);
            }
            catch(Exception ex)
            {
            	throw(ex);
            }
            if(result != null && result.MemberInfo != null)
            {
	            EtownCourseService.EtownMemberInfo memberInfo = result.MemberInfo;
	            EtownCourseService.EtownCourseRescheduleList reshceudles = memberInfo.RescheduleList;
	            
	            String currentLevel = memberInfo.CurrentLevel;
	            String currentSchool = memberInfo.CurrentSchool;
	            String currentStatus = memberInfo.Status;
	            if(result.IsSuccess)
	            {
	            	Contact con = new Contact(Id=student.Id, Status__c=currentStatus, StudyCenter__c=currentSchool, CurrentLevel__c=currentLevel, LastRefreshDate__c=currentTime);
	            	if(!student.IsRescheduleSynced__c)
	            	{
	            		createRescheduleRecords(student.Id, memberInfo.RescheduleList);
	            		con.IsRescheduleSynced__c = true;
	            	} 
	            	try
	                { 
	                    update con;
	                    message = 'Success';
	                }
	                catch(Exception ex)
	                {
	                    message = 'An error occurred while updating contact information.';
	                }
	            }
	            else
	            {
	                message = result.ErrorMessage;
	            }
            }
        }
        return message;
    }
    
    private static void createRescheduleRecords(Id contactId, EtownCourseService.EtownCourseRescheduleList reschedules)
    {
    	if(reschedules != null)
    	{
    		if(reschedules.ReshceduleInfoList != null && reschedules.ReshceduleInfoList.size() != 0)
    		{
    			Boolean isSuccess = true;
	    		List<CourseReschedule__c> createdReschedules = new List<CourseReschedule__c>();
	    		for(EtownCourseService.EtownCourseRescheduleInfo info : reschedules.ReshceduleInfoList)
	    		{
	    			CourseReschedule__c reschedule = new CourseReschedule__c();
	    			reschedule.Contact__c = contactId;
	    			reschedule.ScheduleJobId__c = info.OperateId;
	    			reschedule.ScheduleDate__c = (info.OperateDate != null) ? info.OperateDate.dateGmt() : null;
	    			reschedule.Type__c = info.OperateType;
	    			reschedule.Status__c = 'Not start yet';
	    			createdReschedules.add(reschedule);
	    		}
	    		if(Math.mod(reschedules.ReshceduleInfoList.size(), 2) != 0)
	    		{
		    		List<EtownCourseService.EtownCourseRescheduleInfo> rescheduleInfos = sortRescheduleRecordsByAsc(reschedules.ReshceduleInfoList);
		    		if(rescheduleInfos[0].OperateType == 'Resume')
		    		{
		    			CourseReschedule__c reschedule = new CourseReschedule__c();
		    			reschedule.Contact__c = contactId;
		    			reschedule.ScheduleDate__c = Date.newInstance(1900, 01, 01);
		    			reschedule.Type__c = 'Suspend';
		    			reschedule.Status__c = 'Completed';
		    			createdReschedules.add(reschedule);
		    		}
		    		else
		    		{
		    			isSuccess = false;
		    		}
	    		}
	    		if(isSuccess)
	    		{
		    		try
		    		{
		    			insert createdReschedules;
		    		}
		    		catch(Exception ex)
		    		{
		    			isSuccess = false;
		    		}
		    	}
	    		else
	    		{
	    			EtownCourseHelper.sendErrorInfoEmail('Failed to sync reschedule infomation', 'Please check the Etwon Reschedule record. Contact Id:' + contactId);
	    		}
    		}
    	}
    }
    
    private static List<EtownCourseService.EtownCourseRescheduleInfo> sortRescheduleRecordsByAsc(List<EtownCourseService.EtownCourseRescheduleInfo> rescheduleInfos)
    {
    	if(rescheduleInfos != null)
    	{
    		Boolean isExchanged = false;
    		EtownCourseService.EtownCourseRescheduleInfo temp;
    		Integer len = rescheduleInfos.size();
    		for(Integer i = 0; i < len - 1; i++)
    		{
    			for(Integer j = len - 1; j > i; j--)
    			{
    				EtownCourseService.EtownCourseRescheduleInfo nInfo = rescheduleInfos[j];
    				EtownCourseService.EtownCourseRescheduleInfo pInfo = rescheduleInfos[j-1];
    				if(nInfo.OperateDate < pInfo.OperateDate)
    				{
    					temp = nInfo;
    					rescheduleInfos[j] = pInfo;
    					rescheduleInfos[j-1] = temp;
    					isExchanged = true;
    				}
    			}
    			if(!isExchanged)
    			{
    				break;
    			}
    		}
    	}
    	return rescheduleInfos;
    }
    
    @isTest
    static void testEtownStudentInfoService()
    {
        Contact testCon = new Contact(LastName = 'acme', EtownUserName__c = 'test1212');
        insert testCon;
        EtownStudentInfoService.checkAndUpdateStudentInfo(testCon.Id);
    }
}