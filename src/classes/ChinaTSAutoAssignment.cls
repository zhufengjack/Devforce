/*
*  Auto assignment for china TS.
*/
public class ChinaTSAutoAssignment extends AutoAssignmentBase
{
	private String roleName;
	
	// Override method createEventAndReport.
	public void createEventAndReport(String userId, Opportunity tempOpportunity)
	{
		if(userId != null && tempOpportunity != null)
		{
			// Create and assign event.
			List<RecordType> recordTypes = [select Id from RecordType where Name = 'CN TS Telesales Meeting'];
			Event newEvent = new Event();
	        newEvent.DurationInMinutes = 15;
	        if(tempOpportunity.Initial_Appt_Date__c != null)
	        {
		        	newEvent.ActivityDateTime = tempOpportunity.Initial_Appt_Date__c;
		        newEvent.ActivityDate = date.newInstance(tempOpportunity.Initial_Appt_Date__c.year(), tempOpportunity.Initial_Appt_Date__c.month(), tempOpportunity.Initial_Appt_Date__c.day());
	        }
	        newEvent.OwnerId = userId;
	        newEvent.WhatId = tempOpportunity.Id;
	        newEvent.Subject = 'Web Demo '+roleName;
	        newEvent.RecordTypeId = (recordTypes.size() > 0) ? recordTypes[0].Id : null;
	        insert newEvent; 
	        // Create assignment report.
			China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
	        report.Appointment_DateTime__c = newEvent.ActivityDateTime;
	        report.Appointment_Date__c = newEvent.ActivityDate;
	        report.Assignment_Time__c = DateTime.now();
	        report.Opportunity__c = tempOpportunity.Id;
	        report.Sales_Consultant__c = userId;
	        report.Assignment_Org__c = 'Chinese TS';
	        report.School__c = roleName;
	        report.OwnerId = userId;
	        insert report;
		}
	}
	
	// Override method autoAssignUser.
	public String autoAssignUser(Opportunity tempOpportunity)
	{
		String resultUserId;
		if(tempOpportunity != null)
		{
			set<String> userGroup = getCurrentUserGroup(tempOpportunity); // Get all user that location 
			Datetime assignDatetime = tempOpportunity.Initial_Appt_Date__c;
			Map<String, Double> userToAllocation = getUserAllocation(userGroup, assignDatetime);
			resultUserId = handleAssignment(userToAllocation, assignDatetime, userGroup);
			if(resultUserId != null)
			{
				// Change queue status.
				changeQueueStatus(tempOpportunity.Id);
			}
			else
			{
				String tsGroup; 
				if(roleName != null)
				{
					tsGroup = roleName.replace('China Telesales', '').replace('CC', '').trim();
				}
				createQueue(tempOpportunity, tsGroup, 'Assignment Failure by webservice');
				throw new NoSaleUserException('No user has been assigned, the opportunity has been added to queue.');
			}
		}
		return resultUserId;
	}
	
	// Implements method calculateReportCount.  Calculates finished rate.
	public  List<Integer> calculateReportCount(Map<String, CountInfo> salesCountMap, Datetime assignDatetime, Set<String> ondutyUserIds, Set<String> allUserIds)
	{
		if(salesCountMap != null && assignDatetime != null && ondutyUserIds != null && allUserIds != null)
		{
            String year = String.valueOf(assignDatetime.year());
            String month = String.valueOf(assignDatetime.month());
            String day = String.valueOf(assignDatetime.day());
            
			List<Integer> totalReportCountList = new List<Integer>();

            Integer dailyCount = 0; // 当天总计 .
            Integer monthlyCount = 0; // 本月总计 .
            
            for(China_Appt_Assignment_Report__c assignReport : [select Id, Lead_Source__c, Day__c, Sales_Consultant__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :allUserIds and Year__c =:year and Month__c =:month and Assignment_Org__c = 'Chinese TS' order by Sales_Consultant__c])
            {
				monthlyCount++;
	            dailyCount = (assignReport.Day__c == day) ? (dailyCount + 1) : dailyCount;
	            calculateReportCountForOndutySale(salesCountMap, ondutyUserIds, assignReport, day);
            }
            totalReportCountList.add(dailyCount);
            totalReportCountList.add(monthlyCount);
            return totalReportCountList;
		}
		return null;
	}
	
	// Implements method getCurrentUserGroup.
	public Set<String> getCurrentUserGroup(Opportunity currentOpportunity)
	{
		Set<String> resultUserIds = new Set<String>();
		if(currentOpportunity != null)
		{
			List<User> users = [select Id, UserRole.Name from User where Id = :currentOpportunity.OwnerId limit 1];
			if(users.size() > 0)
			{
			    if(users[0].UserRole.name != null && users[0].UserRole.name.indexOf('China Telesales')>=0 && users[0].UserRole.name.indexOf('TM')>=0)
			    {
				      //user is a telesales TM
				      roleName = users[0].UserRole.Name.replace('TM','CC');
				      List<User> saleUsers = [select Id, Name from User where UserRole.Name = :roleName and IsActive = true];
				      for(User saleUser : saleUsers)
				      {
				      	resultUserIds.add(saleUser.Id);
				      }
			    }
			}
		}
		return resultUserIds;
	}
	
	@isTest
	static void testChinaTSAutoAssignment()
	{
    	Date currentDate = Date.today();
    	currentDate = currentDate.addYears(5);
    	Datetime currentTime = Datetime.now();
    	currentTime = currentTime.addYears(5);
    	Date otherDay = currentDate.addDays(1);
    	Datetime otherTime = currentTime.addDays(1); 
    	
    	List<User> sales = [select Id, Name from User where UserRole.Name = 'China Telesales Shanghai CC (A)' and IsActive = true limit 4];
		User sale1 = sales[0];
		User sale2 = sales[1];
		User sale3 = sales[2];
		User sale4 = sales[3];
		// Sets allocation for each user.
		List<Sales_Team_Appointment_Allocation__c> allocations = new List<Sales_Team_Appointment_Allocation__c>();
		allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale1.Id, Allocation__c = '50%', Date__c = currentDate));
		allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale2.Id, Allocation__c = '30%', Date__c = currentDate));
		allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale3.Id, Allocation__c = '25%', Date__c = currentDate));
		allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale4.Id, Allocation__c = '25%', Date__c = currentDate));
		insert allocations;
		// Create monthly schedule summary.
		Sales_Month_Summary__c  summary = new Sales_Month_Summary__c(Date__c = currentDate, School__c = 'China Telesales Shanghai CC (A)' );
		insert summary;
		// Sets 'on duty'. 
    	List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
		monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));
		monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));   	
		monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate)); 
		monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));
		insert monthlyDetails;
		// creates assignment report.
		List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = otherDay, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = otherDay, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = otherDay, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = otherDay, Assignment_Org__c = 'Chinese TS'));
		reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Assignment_Org__c = 'Chinese TS'));
		insert reports;
		Account student = new Account(Name = 'test');  
		insert student; 
		// Opportunity record type 'China Telesales Record Type'.
		List<User> tmUsers = [select Id from User where UserRole.Name = 'China Telesales Shanghai TM (A)' limit 1];
		List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Telesales Record Type' limit 1];
		Opportunity opp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id, OwnerId = tmUsers[0].Id);
		insert opp;
		// Start test
		ChinaTSAutoAssignment controller = new ChinaTSAutoAssignment();
		System.assertNotEquals(null, controller.autoAssignEvent(opp));
	}
}