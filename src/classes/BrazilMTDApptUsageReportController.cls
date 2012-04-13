/*
*    Controller for "BrazilMTDApptUsageReport". 
*/
public class BrazilMTDApptUsageReportController 
{
	public List<ApptUsageSituation>  ApptUsageSituations {get; set;}
    public List<SelectOption> CenterList {get; set;}
    public String CenterName {get; set;}
    public String teamRoleId {get; set;}
    public String ApptReportDate {get; set;}
    public String reportDataExport {get; set;}
    private Map<String, ApptUsageSituation> timeSlot2ApptUsageSituation;
    
    public BrazilMTDApptUsageReportController()
    {
        initial();
    }
    
    private void initial()
    {
        CenterName = 'Call Center'; 
        ApptReportDate = Date.today().format();
        CenterList = initialCenterList();
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
    
    private String generateCenterKeyWord(String roleValue)
    {
        String result = '';
        if(roleValue != null)
        {
            result = roleValue.replace('Brazil', '').replace('Sales Manager', '').trim();
        }
        return result;
    }
    
    public void refresh()
    {
        try
        {
            Date currentReportDate = Date.parse(ApptReportDate);
            initialTableData();
            Set<String> teamRoleIdSet = getTeamRoleIdSet(CenterName);
            Set<String> userIdSet = getUserIds(teamRoleIdSet);
            Map<String, RemainApptInfo> salesRemainApptMap = new Map<String, RemainApptInfo>(); // Store remain appt info.
            initialDailyMaxTarget(userIdSet, currentReportDate, salesRemainApptMap);
            initialScheduledApptAmount(userIdSet, currentReportDate, salesRemainApptMap);
            resetApptCapacity(salesRemainApptMap);
            calculateUsagePercent();
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }
    
    // We use this method in export page action.
    public void exportReport()
    {
    	String dateParameter = ApexPages.currentPage().getParameters().get('dateParameter');
    	String centerParameter = ApexPages.currentPage().getParameters().get('centerParameter');
    	if(dateParameter != null && centerParameter != null)
    	{
	        ApptReportDate = dateParameter;
	        CenterName = centerParameter;
	        refresh();
    	}
    }
    
    private void resetApptCapacity(Map<String, RemainApptInfo> salesRemainApptMap)
	{
		if(salesRemainApptMap != null)
		{
			//ApptUsageSituations
			Set<String> noRemainApptCapacitySales = generateNoRemainApptCapacitySalesSet(salesRemainApptMap);
			for(String noRemainUserId : noRemainApptCapacitySales)
			{
			    for(ApptUsageSituation aSituation : ApptUsageSituations)
			    {
			        if(!aSituation.salesIds.contains(noRemainUserId) && aSituation.salesIdsInMaxAvailableAmount.contains(noRemainUserId))
			        {
			            aSituation.reduceCapacity();
			        }
			    }
			}
		}
	}
	
	private Set<String> generateNoRemainApptCapacitySalesSet(Map<String, RemainApptInfo> salesRemainApptMap)
	{
	    Set<String> noRemainApptCapacitySales = new Set<String>();
	    if(salesRemainApptMap != null && salesRemainApptMap.size() > 0)
	    {
	       for(String userId : salesRemainApptMap.keySet())
			{
			    if(salesRemainApptMap.get(userId).isReachedTarget())
			    {
			        noRemainApptCapacitySales.add(userId);
			    }
			} 
	    }
	    return noRemainApptCapacitySales;
	}
    
    private void initialTableData()
    {
        Time StartTime = Time.newInstance(9, 0, 0, 0);
        Integer tableSize = 25; // Table row.
        Integer timeSlotSize = 30; // 30 minutes.
        ApptUsageSituations = new List<ApptUsageSituation>();
        timeSlot2ApptUsageSituation = new Map<String, ApptUsageSituation>(); 
        for(Integer i = 0; i < tableSize; i++)
        {
            ApptUsageSituation situation = new ApptUsageSituation(StartTime.addMinutes(timeSlotSize * i)); 
            ApptUsageSituations.add(situation);
            timeSlot2ApptUsageSituation.put(situation.TimeSlot, situation);
        }
    }
    
    private Set<String> getTeamRoleIdSet(String centerNameValue)
    {
        Set<String> teamRoleIdSet = new Set<String>();
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
                    teamRoleIdSet.add(role.Id);
                }
            }
        }
        return teamRoleIdSet;
    }
    
    private Set<String> getUserIds(Set<String> roleIdValues)
    {
        Set<String> resultSet = new Set<String>();
        List<user> tempUsers = [select Id from User where UserRoleId in :roleIdValues and IsActive = true];
        for(User user : tempUsers)
        {
            resultSet.add(user.Id);
        }
        return resultSet;
    }
    
    private void initialDailyMaxTarget(Set<String> userIdSet, Date currentReportDate, Map<String, RemainApptInfo> salesRemainApptMap)
    {
        if(userIdSet != null)
        {
            String onduty = 'On Duty';
            List<Sales_Monthly_Details__c> details = [select Id, Date__c, DemoTarget__c, Sales_Consultant__c, StartWorkingTime__c, FinishWorkingTime__c from Sales_Monthly_Details__c where Day_Status__c = :onduty and Sales_Consultant__c in :userIdSet and Date__c = :currentReportDate and StartWorkingTime__c != null];
            for(Sales_Monthly_Details__c detail : details)
            {
            	RemainApptInfo tempRemainApptInfo = new RemainApptInfo();
            	tempRemainApptInfo.setApptTarget((detail.DemoTarget__c != null)? detail.DemoTarget__c.intValue(): 0);
            	salesRemainApptMap.put(detail.Sales_Consultant__c, tempRemainApptInfo);
                for(ApptUsageSituation situation : ApptUsageSituations)
                {
                    situation.setDailyCapacityTarget(detail.StartWorkingTime__c,  detail.FinishWorkingTime__c, detail.Sales_Consultant__c);
                }
            }
        }
    }
    
    private void initialScheduledApptAmount(Set<String> userIdSet, Date currentReportDate, Map<String, RemainApptInfo> salesRemainApptMap)
    {
        if(userIdSet != null)
        {
            List<China_Appt_Assignment_Report__c> assignmentReportDetails = [select Id, Sales_Consultant__c, Appointment_DateTime__c, Appointment_Date__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :userIdSet and Appointment_Date__c = :currentReportDate];
            for(China_Appt_Assignment_Report__c report : assignmentReportDetails)
            {
            	reduceRemainCap(salesRemainApptMap, report.Sales_Consultant__c);
                String timeString = formatTimeToString(report.Appointment_DateTime__c.time());
                ApptUsageSituation usageSituation = timeSlot2ApptUsageSituation.get(timeString);
                if(usageSituation != null)
                {
                    usageSituation.addScheduledApptAmount();
                    usageSituation.addSales(report.Sales_Consultant__c);
                }
            }
        }
    }
    
    private void reduceRemainCap(Map<String, RemainApptInfo> salesRemainApptMap, String userId)
	{
	    if(salesRemainApptMap != null && userId != null)
	    {
	        RemainApptInfo tempRemainAppt = salesRemainApptMap.get(userId);
	        if(tempRemainAppt != null)
	        {
	            tempRemainAppt.reduceRemainApptAmount();
	        }
	    }
	}
    
    private void calculateUsagePercent()
    {
        if(ApptUsageSituations != null && ApptUsageSituations.size() > 0)
        {
            for(ApptUsageSituation situation : ApptUsageSituations)
            {
                situation.calculateUsagePercent();
            }
        }
    }
    
    private String formatTimeToString(Time tValue)
    {
        String result = '';
        if(tValue != null)
        {
            Integer hourValue = tValue.hour();
            Integer minuteValue = tValue.minute();
            String hourString = (hourValue < 10)? '0' + hourValue: String.valueOf(hourValue);
            String minuteString = (minuteValue < 10)? '0' + minuteValue: String.valueOf(minuteValue);
            result = hourString + ':' + minuteString;
        }
        return result;
    }
    
    public class ApptUsageSituation
    {
        public String TimeSlot {get; set;}
        public Integer Capacity {get; set;}
        public Integer Usage {get; set;}
        public Double UsagePercent {get; set;}
        public Time slotStartTime;
        public Set<String> salesIds = new Set<String>();
        public Set<String> salesIdsInMaxAvailableAmount = new Set<String>();
        
        public ApptUsageSituation(Time tValue)
        {
            Capacity = 0;
            Usage = 0;
            UsagePercent = 0; 
            setAssociatedTime(tValue);
        }
        
        public void addSales(String salesId)
        {
            salesIds.add(salesId);
        }
        
        public void setAssociatedTime(Time tValue)
        {
            slotStartTime = tValue;
            TimeSlot = formatTimeToString(tValue);
        }
        
        public void calculateUsagePercent()
        {
            if(Capacity == 0 || Capacity == null)
            {
                UsagePercent = 0;
            }
            else
            {
                UsagePercent = (Usage / (Capacity * 1.0)) * 100;
            }
        }
        
        public void setDailyCapacityTarget(Datetime scheduleDetailStartTime, Datetime scheduleDetailEndTime, String salesId)
        {
            if(scheduleDetailStartTime != null && scheduleDetailEndTime != null)
            {
                Time startTime = scheduleDetailStartTime.time();
                Time endTime = scheduleDetailEndTime.time();
                processBookingSituationForMaxTarget(startTime, endTime, salesId);
            }
        }
        
        public void addScheduledApptAmount()
        {
            Usage = Usage + 1;
        }
        
        public void reduceCapacity()
        {
            if(Capacity != null)
            {
                Capacity--;
            }
        }
        
        private void processBookingSituationForMaxTarget(Time startTime, Time endTime, String salesId)
        {
            if(slotStartTime >= startTime && slotStartTime < endTime)
            {
                Capacity = Capacity + 1;
                salesIdsInMaxAvailableAmount.add(salesId);
            }
        }
        
	    private String formatTimeToString(Time tValue)
	    {
	        String result = '';
	        if(tValue != null)
	        {
	            Integer hourValue = tValue.hour();
	            Integer minuteValue = tValue.minute();
	            String hourString = (hourValue < 10)? '0' + hourValue: String.valueOf(hourValue);
	            String minuteString = (minuteValue < 10)? '0' + minuteValue: String.valueOf(minuteValue);
	            result = hourString + ':' + minuteString;
	        }
	        return result;
	    }
    }
    
    public class RemainApptInfo
    {
        public Integer remainApptAmount = 0;
        
        public void setApptTarget(Integer targetValue)
        {
            if(targetValue != null)
            {
                remainApptAmount = targetValue;
            }
        }
        
        public Boolean isReachedTarget()
        {
            if(remainApptAmount != null && remainApptAmount > 0)
            {
                return false;
            }
            else
            {
                return true;
            }
        }
        
        public void reduceRemainApptAmount()
        {
            if(remainApptAmount != null)
            {
                remainApptAmount--;
            }
        }
    }

    public class GenerateReportException extends Exception {}

    @isTest
    static void testBrazilMTDApptUsageReportController()
    {
    	// Test ApptUsageSituation class.
    	ApptUsageSituation apptUsage = new ApptUsageSituation(Time.newInstance(9, 30, 0, 0));
        System.assertEquals('09:30', apptUsage.TimeSlot);
        System.assertEquals(Time.newInstance(9, 30, 0, 0), apptUsage.slotStartTime);
        Datetime testStartWorkingDatetime = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0));
        Datetime testEndWorkingDatetime = Datetime.newInstance(Date.today(), Time.newInstance(17, 0, 0, 0));
        apptUsage.setDailyCapacityTarget(testStartWorkingDatetime, testEndWorkingDatetime, 'testid1');
        System.assertEquals(1, apptUsage.Capacity);
        apptUsage.setDailyCapacityTarget(testStartWorkingDatetime, testEndWorkingDatetime, 'testid1');
        apptUsage.setDailyCapacityTarget(testStartWorkingDatetime, testEndWorkingDatetime, 'testid1');
        System.assertEquals(3, apptUsage.Capacity);
        System.assertEquals(0, apptUsage.Usage);
        apptUsage.addScheduledApptAmount();
        System.assertEquals(1, apptUsage.Usage);
        apptUsage.setDailyCapacityTarget(testStartWorkingDatetime, testEndWorkingDatetime, 'testid1');
        apptUsage.calculateUsagePercent();
        System.assertEquals(25.0, apptUsage.UsagePercent);
        // Test BrazilMTDApptUsageReportController logic.
        Date currentDate = Date.newInstance(1999, 11, 19);
        String currentDateStringFormat = currentDate.format();
        Time startTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(18, 0, 0, 0);
        Datetime startingWorkTime = Datetime.newInstance(currentDate, startTime);
        Datetime endWorkTime = Datetime.newInstance(currentDate, endTime);
        List<User> sales = [select Id, Name, UserRoleId from User where UserRole.Name = 'Brazil Sales Group (B)' and IsActive = true limit 4];
        String testRoleId = sales[0].UserRoleId;
        User sale1 = sales[0];
        User sale2 = sales[1];
        User sale3 = sales[2];
        User sale4 = sales[3];
        // Create monthly schedule summary.
        Sales_Month_Summary__c  summary = new Sales_Month_Summary__c(Date__c = currentDate);
        insert summary;
        List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime.addHours(-2)));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime.addHours(2), FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        insert monthlyDetails;
        // creates assignment report.
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(10, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        insert reports;
        BrazilMTDApptUsageReportController controller = new BrazilMTDApptUsageReportController();
        controller.teamRoleId = testRoleId;
        controller.ApptReportDate = currentDateStringFormat;
        controller.refresh();
        Map<String, ApptUsageSituation> tempMap = controller.timeSlot2ApptUsageSituation;
        System.assertEquals(3, tempMap.get('09:00').Capacity);
        System.assertEquals(4, tempMap.get('11:00').Capacity);
        System.assertEquals(1, tempMap.get('09:30').Usage);
        System.assertEquals(1, tempMap.get('10:30').Usage);
        // Test for "BrazilMTDApptUsageReportExport".
        PageReference reportExportPage = new PageReference('/apex/BrazilMTDApptUsageReportExport?dateParameter=' + currentDateStringFormat + '&centerParameter=Call Center');
        Test.setCurrentPage(reportExportPage);
        (new BrazilMTDApptUsageReportController()).exportReport();
    }
}