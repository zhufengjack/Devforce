trigger China_Appt_Assignment_ReportTrigger on China_Appt_Assignment_Report__c (before insert) {
	if(Trigger.isBefore)
	{
		if(Trigger.isInsert)
		{
			China_Appt_Assignment_Report__c report = Trigger.new[0];
			String strSchool = report.School__c;
			Date dt = report.Appointment_Date__c;
			List<Appt_Max_target__c> maxTarget = [select Max_target__c 
			from Appt_Max_target__c where 
			School__c=:strSchool and Date__c=:dt order by CreatedDate DESC limit 1];
			if(maxTarget != null && maxTarget.size()>0)
			{
				try
				{
					Double dblTarget = maxTarget[0].Max_target__c;
					Integer reportsCount = [select count() from 
					China_Appt_Assignment_Report__c where 
					School__c=:strSchool and Appointment_Date__c=:dt limit 200];
					
					if(reportsCount > dblTarget)
					{
						//如果已分派的数量超过最大数量，则创建邮件请求
						China_Auto_Assign_Notify__c notify = new China_Auto_Assign_Notify__c();
						notify.School__c = strSchool;
						notify.Notify_Type__c = 'Max Target';
						notify.Date__c = dt;
						//notify.Send_Email_Notify__c
						insert notify;
					}
				}
				catch(Exception e)
				{
					
				}
			}
			
		}
	}
}