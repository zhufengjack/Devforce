public class BrazilSalesDailyApptReportController 
{
	public List<ApptSummaryInfo> ApptSummaries {get; set;}
	public List<SelectOption> CenterList {get; set;}
	public String CenterName {get; set;}
	public List<SelectOption> teamRoleList {get; set;}
	public String teamRoleId {get; set;}
	public String ApptReportDate {get; set;}
	
	public BrazilSalesDailyApptReportController()
	{
	    initial();
	}
	
	public void resetTeamRoleList()
	{
	    teamRoleList = getTeamRoles(CenterName);
	}
	
	private void initial()
	{
        CenterName = 'Call Center';
        ApptSummaries = new List<ApptSummaryInfo>();
        CenterList = initialCenterList();
        resetTeamRoleList();
	}
	
	private List<SelectOption> initialCenterList()
	{
	    List<SelectOption> options = new List<SelectOption>();
	    options.add(new SelectOption('Call Center', 'Call Center'));
	    List<UserRole> managerRoles = [select Id, Name from UserRole where Name like 'Brazil % Sales Manager']; 
	    if(managerRoles.size() > 0)
	    {
	        for(UserRole role : managerRoles)
	        {
	        	String roleKeyWord = generateCenterKeyWord(role.Name);
	            options.add(new SelectOption(role.Name, roleKeyWord));
	        }
	    }
	    return options;
	}
	
	private List<SelectOption> getTeamRoles(String centerNameValue)
	{
	    List<SelectOption> options = new List<SelectOption>();
	    if(centerNameValue != null)
	    {
	    	List<UserRole> teamSalesRoles;
            if(centerNameValue == 'call center')
            {
                teamSalesRoles = [select Id, Name from UserRole where Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%') order by Name]; 
            }
            else
            {   // Brazil Rio Sales Manager
            	String centerKeyWord = generateCenterKeyWord(centerNameValue);
            	String salesRoleName = 'Brazil ' + centerKeyWord + ' Sales'; 
                teamSalesRoles = [select Id, Name from UserRole where Name = :salesRoleName order by Name];
            }
            if(teamSalesRoles != null && teamSalesRoles.size() > 0)
            {
                for(UserRole role : teamSalesRoles)
                {
                    options.add(new SelectOption(role.Id, role.Name));
                }
            }
	    }
	    return options;
	}
	
	private String generateCenterKeyWord(String roleValue)
	{
	    String result = '';
	    if(roleValue != null)
	    {
	        result = roleValue.replace('Brazil', '').replace('Sales Manager', '').trim();
	    }
	    return result;
	}
	
	private void clearApptSummaries()
	{
		if(ApptSummaries != null)
		{
		    ApptSummaries.clear();
		}
	}
	
	public void runReport()
	{
		try
		{
			clearApptSummaries();
		    List<User> salesList = findTeamSalesMember(teamRoleId); 
		    Map<String, User> salesMap = generateUserMap(salesList);
		    Date currentReportDate = Date.parse(ApptReportDate);
		    Map<String, Integer> demoTargetMap = generateOnDutySalesTarget(salesMap.keySet(), currentReportDate);
		    Map<String, Integer> apptScheduleAmountMap = generateApptScheduleAmount(salesMap.keySet(), currentReportDate);
		    Map<String, double> apptSchedulePercentMap = calculateApptSchedulePercent(demoTargetMap, apptScheduleAmountMap); 
		    ApptSummaries = createApptSummaryList(salesList, demoTargetMap, apptScheduleAmountMap, apptSchedulePercentMap);
		} 
		catch(Exception ex)
		{
		    ApexPages.addMessages(ex);
		}
	}
	
	private List<User> findTeamSalesMember(String roleId)
	{
        List<User> salesUsers;
        if(roleId != null)
        {   
            salesUsers = [select Id, Name from User where UserRoleId = :roleId and IsActive = true order by Name];
        }
        return salesUsers;
	}
	
	private Map<String, User> generateUserMap(List<User> salesUsers)
	{
		Map<String, User> salesMemberMap = new Map<String, User>();
		if(salesUsers != null && salesUsers.size() > 0)
		{
		    for(User sales : salesUsers)
		    {
                salesMemberMap.put(sales.Id, sales); 
		    }
		}
	    return salesMemberMap;
	}
	
	private Map<String, Integer> generateOnDutySalesTarget(Set<String> salesUserIds, Date summryReportDate)
	{
	    Map<String, Integer> demoTargetMap = new Map<String, Integer>();
	    if(salesUserIds != null && salesUserIds.size() > 0 && summryReportDate != null)
	    {
	    	String onduty = 'On Duty';
	        List<Sales_Monthly_Details__c> details = [select Id, DemoTarget__c, Sales_Consultant__c from Sales_Monthly_Details__c where Date__c = :summryReportDate and Sales_Consultant__c in :salesUserIds and Day_Status__c = :onduty and Sales_Consultant__c != null];
	        for(Sales_Monthly_Details__c detail : details)
	        {
	            Integer demoTarget = (detail.DemoTarget__c == null)? 0: detail.DemoTarget__c.intValue();
	            demoTargetMap.put(detail.Sales_Consultant__c, demoTarget);
	        }
	    }
	    return demoTargetMap;
	}
	
	private Map<String, Integer> generateApptScheduleAmount(Set<String> salesUserIds, Date summryReportDate)
	{
	    Map<String, Integer> apptScheduleAmountMap = new Map<String, Integer>();
	    if(salesUserIds != null && summryReportDate != null)
	    {
	        List<AggregateResult> results = [select Count(Id) reportSum , Sales_Consultant__c from China_Appt_Assignment_Report__c where Appointment_Date__c = :summryReportDate and Sales_Consultant__c in :salesUserIds group by Sales_Consultant__c];
	        for(AggregateResult result : results)
	        {
	            apptScheduleAmountMap.put((String)result.get('Sales_Consultant__c'), (Integer)result.get('reportSum'));
	        }
	        for(String userId : salesUserIds)
	        {
	            if(!apptScheduleAmountMap.keySet().contains(userId))
	            {
	                apptScheduleAmountMap.put(userId, 0);
	            }
	        }
	    }
	    return apptScheduleAmountMap;
	}
	
	private Map<String, double> calculateApptSchedulePercent(Map<String, Integer> demoTargetMap, Map<String, Integer> apptScheduleAmountMap)
	{
		Map<String, double> apptSchedulePercentMap = new Map<String, double>();
		if(demoTargetMap != null && apptScheduleAmountMap != null)
		{
			for(String userId : demoTargetMap.keySet())
			{
				Double target = demoTargetMap.get(userId);
	            Double apptAmount = (apptScheduleAmountMap.get(userId) != null)? apptScheduleAmountMap.get(userId): 0;
	            Double apptPercent = (target > 0)? apptAmount/target : 0;
	            apptSchedulePercentMap.put(userId, apptPercent);
			}
		}
	    return apptSchedulePercentMap;
	}
	
	private List<ApptSummaryInfo> createApptSummaryList(List<User> salesList, Map<String, Integer> demoTargetMap, Map<String, Integer> apptScheduleAmountMap, Map<String, double> apptSchedulePercentMap)
	{
		List<ApptSummaryInfo> ApptSummaryInfo = new List<ApptSummaryInfo>();
		if(salesList != null && demoTargetMap != null && apptScheduleAmountMap != null && apptSchedulePercentMap != null)
		{
		    for(User sales : salesList)
		    {
		    	Integer demoTarget = (demoTargetMap.get(sales.Id) != null)? demoTargetMap.get(sales.Id): 0;
		    	Integer apptScheduleAmount = (apptScheduleAmountMap.get(sales.Id) != null)? apptScheduleAmountMap.get(sales.Id): 0;
		    	Double apptSchedulePercent = (apptSchedulePercentMap.get(sales.Id) != null)? apptSchedulePercentMap.get(sales.Id): 0;
		        ApptSummaryInfo summaryInfo = new ApptSummaryInfo(sales.Id, sales.Name, demoTarget, apptScheduleAmount, apptSchedulePercentMap.get(sales.Id));
		        ApptSummaryInfo.add(summaryInfo);
		    }
		}
	    return ApptSummaryInfo;
	}
	
    public class ApptSummaryInfo
    {
        public String UserId {get; set;}
        public String SalesName {get; set;}
        public Integer ApptTarget {get; set;}
        public Integer ApptScheduled {get; set;}
        public Double AssignmentPercent {get; set;}
        
        public ApptSummaryInfo(String userIdValue, String salesNameValue, Integer target, Integer scheduled, Double percent)
        {
            UserId = userIdValue;
            SalesName = salesNameValue;
            ApptTarget = target;
            ApptScheduled = scheduled;
            AssignmentPercent = (percent != null)? percent * 100: 0;
        }
        
        private String formatApptPercent(double percent)
        {
            String result = '0';
            if(percent != null)
            {  
            	Integer tempPercentValue = Math.round(percent * 10000);
            	if(tempPercentValue == 0)
            	{
            	    result = '0';
            	}
            	else
            	{
            	    result = String.valueOf(tempPercentValue/(100*1.0));
            	}
            }
            return result;
        }
    }
    
    @isTest
    static void testBrazilSalesDailyApptReportController()
    {
        // Test for ApptSummaryInfo inner class.
        ApptSummaryInfo summaryInfo = new ApptSummaryInfo('userId', 'userName', 30, 13, Double.valueOf(13/(30*1.0)));
        // Creates test data.
        List<User> salesUsers = [select Id, Name, UserRole.Name, UserRoleId from User where IsActive = true and (UserRole.Name like 'Brazil % Sales' or (UserRole.Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%'))) limit 1];
        String testSalesUserRole = salesUsers[0].UserRole.Name; 
        String testSalesUserRoleId = salesUsers[0].UserRole.Id;
        List<User> allGroupUsers = [select Id, Name from User where UserRoleId = :salesUsers[0].UserRoleId and IsActive = true limit 10];
        String salesUserId = allGroupUsers[0].Id;
        BrazilSalesDailyApptReportController testController = new BrazilSalesDailyApptReportController();
        testController.teamRoleId = testSalesUserRoleId; 
        testController.ApptReportDate = '19/11/1999';
        testController.runReport();
        Sales_Month_Summary__c summary = new Sales_Month_Summary__c();
        summary.DemoTarget__c = 15;
        summary.SummaryOrg__c = 'Brazil';
        summary.Manager__c = UserInfo.getUserId();
        summary.Sales_Amount__c = 10;
        summary.Date__c = Date.newInstance(1999, 11, 19);
        summary.School__c = testSalesUserRole;
        summary.WorkingWeekday__c = 'Tuesday;Wednesday;Thursday;Friday;Sunday';
        summary.NonWorkingDay__c = '14;15;16;17';
        insert summary;
        Sales_Monthly_Details__c tempDetail = new Sales_Monthly_Details__c();
        tempDetail.Date__c = Date.newInstance(1999, 11, 19);
        tempDetail.Sales_Consultant__c = salesUserId;
        tempDetail.Sales_Monthly_Schedule_Summary__c = summary.Id;
        tempDetail.DemoTarget__c = 15;
        tempDetail.Day_Status__c = 'On Duty';
        insert tempDetail;
        Account acc = new account(Name = 'test acc');
        insert acc;
        Contact con = new Contact(AccountId = acc.Id, LastName = 'test con');
        insert con;
        Date testDate = Date.newInstance(1999, 11, 19);
        Opportunity opp1 = new Opportunity(Name = 'test', AccountId = acc.Id, Initial_Appt_Date__c = testDate, CloseDate = testDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        insert opp1;
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        China_Appt_Assignment_Report__c assignmentReport1 = new China_Appt_Assignment_Report__c();
        assignmentReport1.Sales_Consultant__c = salesUserId;
        assignmentReport1.Opportunity__c = opp1.Id;
        assignmentReport1.Appointment_Date__c = testDate;
        reports.add(assignmentReport1);
        China_Appt_Assignment_Report__c assignmentReport2 = new China_Appt_Assignment_Report__c();
        assignmentReport2.Sales_Consultant__c = salesUserId;
        assignmentReport2.Opportunity__c = opp1.Id;
        assignmentReport2.Appointment_Date__c = testDate;
        reports.add(assignmentReport2);
        insert reports;
        testController.runReport();
        for(ApptSummaryInfo info : testController.ApptSummaries)
        {
            if(info.UserId == testSalesUserRoleId)
            {
                System.assertEquals(2.0/15.0, info.AssignmentPercent);
            }
        }
    }
}