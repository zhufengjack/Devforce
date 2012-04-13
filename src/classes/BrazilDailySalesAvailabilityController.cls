/*
*   Controller for "Brazil Daily Sales Availability Report" page.
*/
public class BrazilDailySalesAvailabilityController 
{
    public List<TimeSlotApptBookingSituation> ApptBookingSituations {get; set;}
    public List<SelectOption> CenterList {get; set;}
    public String CenterName {get; set;}
    public String teamRoleId {get; set;}
    public String ApptReportDate {get; set;}
    public String D0DateString {get; set;}
    public String D1DateString {get; set;}
    public String D2DateString {get; set;}
    private Map<String, TimeSlotApptBookingSituation> timeSlot2TimeSlotSituation;
    
    public BrazilDailySalesAvailabilityController()
    {
        initial();
    }
    
    // We use this method to get "timeSlot2TimeSlotSituation" map in test method.
    public Map<String, TimeSlotApptBookingSituation> getInternalTimeSlotApptBookingSituationMap()
    {
        return timeSlot2TimeSlotSituation;
    }
    
    private void initial()
    {
        CenterName = 'Call Center'; 
        ApptReportDate = Date.today().format();
        CenterList = initialCenterList();
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
            Map<Integer, Date> availableDateMap = generateAvailableDateMap(currentReportDate);
            Map<String, RemainApptInfo> salesRemainApptMap = new Map<String, RemainApptInfo>(); // The initial number of appt is demo target.
            Date endReportDate = availableDateMap.get(2);
            initialTableData();
            Set<String> teamRoleIdSet = getTeamRoleIdSet(CenterName);
            Set<String> userIdSet = getUserIds(teamRoleIdSet);
            initialDailyMaxTarget(userIdSet, availableDateMap, endReportDate, salesRemainApptMap);
            initialScheduledApptAmount(userIdSet, availableDateMap, endReportDate, salesRemainApptMap);
            InitialDateString(availableDateMap);
            resetApptCapacity(salesRemainApptMap);
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }
    
    public String formatTimeToString(Time tValue)
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
    
    private void resetApptCapacity(Map<String, RemainApptInfo> salesRemainApptMap)
    {
        Set<String> d0ReachCapSalesIds = new Set<String>();
        Set<String> d1ReachCapSalesIds = new Set<String>();
        Set<String> d2ReachCapSalesIds = new Set<String>();
        generateReachCapSalesIdSet(d0ReachCapSalesIds, d1ReachCapSalesIds, d2ReachCapSalesIds, salesRemainApptMap);
        if(d0ReachCapSalesIds.size() > 0)
        {
            for(String reachCapSalesId : d0ReachCapSalesIds)
            {
                for(TimeSlotApptBookingSituation situation : ApptBookingSituations)
                {
                    BookingSituation d0Situation = situation.D0BookingSituation;
                    if(!d0Situation.scheduledSalesIds.contains(reachCapSalesId) && d0Situation.salesIdsInMaxAvailableAmount.contains(reachCapSalesId))
                    {
                        d0Situation.maxAvailableScheduleAmount--;
                    }
                }
            }
        }
        
        if(d1ReachCapSalesIds.size() > 0)
        {
            for(String reachCapSalesId : d1ReachCapSalesIds)
            {
                for(TimeSlotApptBookingSituation situation : ApptBookingSituations)
                {
                    BookingSituation d1Situation = situation.D1BookingSituation;
                    if(!d1Situation.scheduledSalesIds.contains(reachCapSalesId) && d1Situation.salesIdsInMaxAvailableAmount.contains(reachCapSalesId))
                    {
                        d1Situation.maxAvailableScheduleAmount--;
                    }
                }
            }
        }
        
        if(d2ReachCapSalesIds.size() > 0)
        {
            for(String reachCapSalesId : d2ReachCapSalesIds)
            {
                for(TimeSlotApptBookingSituation situation : ApptBookingSituations)
                {
                    BookingSituation d2Situation = situation.D2BookingSituation;
                    if(!d2Situation.scheduledSalesIds.contains(reachCapSalesId) && d2Situation.salesIdsInMaxAvailableAmount.contains(reachCapSalesId))
                    {
                        d2Situation.maxAvailableScheduleAmount--;
                    }
                }
            }
        }
    }
    
    private void generateReachCapSalesIdSet(Set<String> d0ReachCapSalesIds, Set<String> d1ReachCapSalesIds, Set<String> d2ReachCapSalesIds, Map<String, RemainApptInfo> salesRemainApptMap)
    {
        if(salesRemainApptMap != null)
        {
            for(String salesId : salesRemainApptMap.keySet())
            {
                RemainApptInfo tempRemainApptInfo = salesRemainApptMap.get(salesId);
                if(tempRemainApptInfo.d0RemainAmount <= 0)
                {
                    d0ReachCapSalesIds.add(salesId);
                }
                if(tempRemainApptInfo.d1RemainAmount <= 0)
                {
                    d1ReachCapSalesIds.add(salesId);
                }
                if(tempRemainApptInfo.d2RemainAmount <= 0)
                {
                    d2ReachCapSalesIds.add(salesId);
                }
            }
        }
    }
    
    private void InitialDateString(Map<Integer, Date> availableDateMap)
    {
        if(availableDateMap != null)
        {
            D0DateString = availableDateMap.get(0).format();
            D1DateString = availableDateMap.get(1).format();
            D2DateString = availableDateMap.get(2).format();
        }
    }
    
    private Map<Integer, Date> generateAvailableDateMap(Date currentReportDate)
    {
        Map<Integer, Date> resultMap = new Map<Integer, Date>();
        if(currentReportDate != null)
        {
            Date tempDate = currentReportDate;
            do
            {
                if(isSunday(tempDate))
                {   // Skip Sunday.
                    tempDate = tempDate.addDays(1);
                }
                else
                {
                    resultMap.put(resultMap.size(), tempDate);
                    tempDate = tempDate.addDays(1);
                }
            }
            while(resultMap.size() < 3);
        }
        return resultMap;
    }
    
    private Boolean isSunday(Date dateValue)
    {
        Boolean result = false;
        if(dateValue != null)
        {
            Integer weekDaycode = getWeekDay(dateValue.year(), dateValue.month(), dateValue.day());
            if(weekDaycode == 0)
            {
                result = true;
            }
        }
        return result;
    }
    
    private void initialTableData()
    {
        Time StartTime = Time.newInstance(9, 0, 0, 0);
        Integer tableSize = 25; // Table row.
        Integer timeSlotSize = 30; // 30 minutes.
        ApptBookingSituations = new List<TimeSlotApptBookingSituation>();
        timeSlot2TimeSlotSituation = new Map<String, TimeSlotApptBookingSituation>(); 
        for(Integer i = 0; i < tableSize; i++)
        {
            TimeSlotApptBookingSituation situation = new TimeSlotApptBookingSituation(StartTime.addMinutes(timeSlotSize * i)); 
            ApptBookingSituations.add(situation);
            timeSlot2TimeSlotSituation.put(situation.TimeSlot, situation);
        }
    }
    
    private void initialDailyMaxTarget(Set<String> userIdSet, Map<Integer, Date> availableDateMap, Date endReportDate, Map<String, RemainApptInfo> salesRemainApptMap)
    {
        if(userIdSet != null)
        {
            String onduty = 'On Duty';
            Date currentReportDate = availableDateMap.get(0); 
            List<Sales_Monthly_Details__c> details = [select Id, Date__c, Sales_Consultant__c, DemoTarget__c, StartWorkingTime__c, FinishWorkingTime__c from Sales_Monthly_Details__c where Day_Status__c = :onduty and Sales_Consultant__c in :userIdSet and Date__c >= :currentReportDate and Date__c <= :endReportDate and StartWorkingTime__c != null];
            for(Sales_Monthly_Details__c detail : details)
            {
                Integer demoTarget = (detail.DemoTarget__c != null)? detail.DemoTarget__c.IntValue(): 0;
                salesRemainApptMap.put(detail.Sales_Consultant__c, new RemainApptInfo(demoTarget, demoTarget, demoTarget)); // Uses demo target to initialize this map.
                for(TimeSlotApptBookingSituation apptBookingSituation : ApptBookingSituations)
                {
                    apptBookingSituation.setDailyMaxTarget(availableDateMap, detail.Date__c, detail.StartWorkingTime__c,  detail.FinishWorkingTime__c, detail.Sales_Consultant__c);
                }
            }
        }
    }
    
    private void initialScheduledApptAmount(Set<String> userIdSet, Map<Integer, Date> availableDateMap, Date endReportDate, Map<String, RemainApptInfo> salesRemainApptMap)
    {
        if(userIdSet != null)
        {   
            Date currentReportDate = availableDateMap.get(0);
            List<China_Appt_Assignment_Report__c> assignmentReportDetails = [select Id, Sales_Consultant__c, Appointment_DateTime__c, Appointment_Date__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :userIdSet and Appointment_Date__c >= :currentReportDate and Appointment_Date__c <= :endReportDate];
            for(China_Appt_Assignment_Report__c report : assignmentReportDetails)
            {
                String timeString = formatTimeToString(report.Appointment_DateTime__c.time());
                TimeSlotApptBookingSituation tempApptBookingSituation = timeSlot2TimeSlotSituation.get(timeString);
                if(tempApptBookingSituation != null)
                {
                    tempApptBookingSituation.setScheduledApptAmount(availableDateMap, report.Appointment_Date__c, report.Sales_Consultant__c, salesRemainApptMap);
                }
            }
        }
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
    
    private Integer getWeekDay(Integer yearValue, Integer monthValue, Integer dayValue)
    {
        Integer week;
        if(monthValue == 1)
        {
            monthValue = 13;
            yearValue = yearValue - 1;
        }
        if(monthValue == 2)
        {
            monthValue = 14;
            yearValue = yearValue - 1;
        }
        Integer y = Math.mod(yearValue, 100);
        Integer c = Math.ceil(yearValue/100).intValue();
        Integer m = monthValue;
        Integer d = dayValue;
        week = y + y / 4 + c / 4 - 2 * c + 26 * ( m + 1 ) / 10 + d - 1;
        week = Math.mod(week, 7);
        if(week < 0)
        {
            week = week + 7;
        }
        return week;
    }
    
    public class TimeSlotApptBookingSituation
    {
        public String TimeSlot {get; set;}
        public BookingSituation D0BookingSituation {get; set;}
        public BookingSituation D1BookingSituation {get; set;}
        public BookingSituation D2BookingSituation {get; set;}
        public Time slotStartTime;

        public TimeSlotApptBookingSituation(Time tValue)
        {
            D0BookingSituation = new BookingSituation();
            D1BookingSituation = new BookingSituation();
            D2BookingSituation = new BookingSituation();
            setAssociatedTime(tValue);
        }
        
        public void setAssociatedTime(Time tValue)
        {
            slotStartTime = tValue;
            TimeSlot = formatTimeToString(tValue);
        }
        
        public void setDailyMaxTarget(Map<Integer, Date> availableDateMap, Date scheduleDetailDate, Datetime scheduleDetailStartTime, Datetime scheduleDetailEndTime, String salesId)
        {
            if(availableDateMap != null && scheduleDetailDate != null && scheduleDetailStartTime != null && scheduleDetailEndTime != null)
            {   // startReportDate
                Time startTime = scheduleDetailStartTime.time();
                Time endTime = scheduleDetailEndTime.time();
                if(availableDateMap.get(0) == scheduleDetailDate)
                {
                    processBookingSituationForMaxTarget(D0BookingSituation, startTime, endTime, salesId);
                }
                else if(scheduleDetailDate == availableDateMap.get(1))
                {
                    processBookingSituationForMaxTarget(D1BookingSituation, startTime, endTime, salesId);
                }
                else if(scheduleDetailDate == availableDateMap.get(2))
                {
                    processBookingSituationForMaxTarget(D2BookingSituation, startTime, endTime, salesId);
                }
            }
        }
        
        public void setScheduledApptAmount(Map<Integer, Date> availableDateMap, Date scheduleDetailDate, String salesId, Map<String, RemainApptInfo> salesRemainApptMap)
        {
            if(availableDateMap != null && scheduleDetailDate != null && salesRemainApptMap != null)
            {   // startReportDate
                RemainApptInfo tempRemainApptInfo = salesRemainApptMap.get(salesId);
                if(availableDateMap.get(0) == scheduleDetailDate)
                {
                    D0BookingSituation.scheduledAmountSum();
                    D0BookingSituation.addSales(salesId);
                    RemainApptInfo RemainApptInfo = salesRemainApptMap.get(salesId);
                    if(tempRemainApptInfo != null)
                    {
                        tempRemainApptInfo.reduceD0RemainAmount();
                    }
                }
                else if(scheduleDetailDate == availableDateMap.get(1))
                {
                    D1BookingSituation.scheduledAmountSum();
                    D1BookingSituation.addSales(salesId);
                    if(tempRemainApptInfo != null)
                    {
                        tempRemainApptInfo.reduceD1RemainAmount();
                    }
                }
                else if(scheduleDetailDate == availableDateMap.get(2))
                {
                    D2BookingSituation.scheduledAmountSum();
                    D2BookingSituation.addSales(salesId);
                    if(tempRemainApptInfo != null)
                    {
                        tempRemainApptInfo.reduceD2RemainAmount();
                    }
                }
            }
        }
        
        private void processBookingSituationForMaxTarget(BookingSituation situation, Time startTime, Time endTime, String salesId)
        {
            if(slotStartTime >= startTime && slotStartTime < endTime)
            {
                situation.maxAvailableScheduleAmountSum(salesId);
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
    
    public class BookingSituation
    {
        public String Situation 
        {
            get
            {
                if(maxAvailableScheduleAmount - scheduledAmount <= 0)
                {
                    return 'Full';
                }
                else
                {
                    return String.valueOf(maxAvailableScheduleAmount - scheduledAmount);
                }
            }
            set;
        }
        public Integer maxAvailableScheduleAmount = 0; 
        public Integer scheduledAmount = 0;
        public Set<String> scheduledSalesIds = new Set<String>();
        public Set<String> salesIdsInMaxAvailableAmount = new Set<String>();
        
        public void maxAvailableScheduleAmountSum(String salesId)
        {
            maxAvailableScheduleAmount = maxAvailableScheduleAmount + 1;
            salesIdsInMaxAvailableAmount.add(salesId);
        }
        
        public void scheduledAmountSum()
        {
            scheduledAmount = scheduledAmount + 1;
        }
        
        public void addSales(String salesId)
        {
            if(scheduledSalesIds != null && salesId != null)
            {
                scheduledSalesIds.add(salesId);
            }
        }
    }
    
    public class RemainApptInfo
    {
        public Integer d0RemainAmount = 0;
        public Integer d1RemainAmount = 0;
        public Integer d2RemainAmount = 0;
        
        public RemainApptInfo(Integer d0Value, Integer d1Value, Integer d2Value)
        {
            d0RemainAmount = (d0Value != null)? d0Value: 0;
            d1RemainAmount = (d1Value != null)? d1Value: 0;
            d2RemainAmount = (d2Value != null)? d2Value: 0;
        } 
        
        public void reduceD0RemainAmount()
        {
            d0RemainAmount = d0RemainAmount - 1;
        }
        
        public void reduceD1RemainAmount()
        {
            d1RemainAmount = d1RemainAmount - 1;
        }
        
        public void reduceD2RemainAmount()
        {
            d2RemainAmount = d2RemainAmount - 1;
        }
    }
    
    public class GenerateReportException extends Exception {}
    
    @isTest
    static void testBrazilDailySalesAvailabilityController()
    {
        TimeSlotApptBookingSituation situation = new TimeSlotApptBookingSituation(Time.newInstance(9, 30, 0, 0));
        System.assertEquals('09:30', situation.TimeSlot);
        // Create test data.
        Date currentDate = Date.newInstance(1999, 11, 19);
        Date date2 = currentDate.addDays(1);
        Date date3 = currentDate.addDays(2);
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
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date2, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date3, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));    
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date2, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));    
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date3, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));    
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime.addMinutes(30), FinishWorkingTime__c = endWorkTime.addHours(-2))); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date2, StartWorkingTime__c = startingWorkTime.addMinutes(30), FinishWorkingTime__c = endWorkTime.addHours(-2))); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date3, StartWorkingTime__c = startingWorkTime.addMinutes(30), FinishWorkingTime__c = endWorkTime.addHours(-2))); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date2, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, DemoTarget__c = 3, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = date3, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        insert monthlyDetails; 
        // creates assignment report.
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(10, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        insert reports;
        BrazilDailySalesAvailabilityController controller = new BrazilDailySalesAvailabilityController();
        controller.teamRoleId = testRoleId;
        controller.ApptReportDate = currentDateStringFormat;
        controller.refresh();
        Map<String, TimeSlotApptBookingSituation> tempTimeSlotApptBookingSituationMap = controller.getInternalTimeSlotApptBookingSituationMap();
        TimeSlotApptBookingSituation tempApptBookingSituation1 = tempTimeSlotApptBookingSituationMap.get('09:00');
        System.assertEquals('09:00', tempApptBookingSituation1.TimeSlot);
        System.assertEquals(3, tempApptBookingSituation1.D0BookingSituation.maxAvailableScheduleAmount);
        System.assertEquals(1, tempApptBookingSituation1.D0BookingSituation.scheduledAmount);
        TimeSlotApptBookingSituation tempApptBookingSituation2 = tempTimeSlotApptBookingSituationMap.get('09:30');
        System.assertEquals(4, tempApptBookingSituation2.D0BookingSituation.maxAvailableScheduleAmount);
        System.assertEquals(2, tempApptBookingSituation2.D0BookingSituation.scheduledAmount); 
    }
}