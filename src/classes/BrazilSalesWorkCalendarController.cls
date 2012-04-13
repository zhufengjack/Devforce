/*
*   Controller for sales work calendar page.
*/
public class BrazilSalesWorkCalendarController
{ 
    public List<SelectOption> SalesUserList {get; set;}
    public Boolean DisableSaveButton {get; set;}
    public String SalesUserId {get; set;}
    public Integer DemoTarget {get; set;}
    public BrazilWorkCalendarDataUtility.WeekDay weekDay {get; set;} 
    public Sales_Month_Summary__c MonthSummary {get; set;}
    private String summaryId; 
    private Map<Integer, Boolean> workingWeekDayMap;
    private Map<Integer, Sales_Monthly_Details__c> monthlyDetailMap = new Map<Integer, Sales_Monthly_Details__c>();
    private Set<Integer> nonWorkingDaySet;
    private Integer intervalParameter = 0;
    private Sales_Month_Summary__c mainSummaryRecord;
    final String onduty = 'On Duty';
    final String dayOff = 'Day Off';
    
    public BrazilSalesWorkCalendarController()
    {
        summaryId = ApexPages.currentPage().getParameters().get('Id');
        DisableSaveButton = false;
        weekDay = new BrazilWorkCalendarDataUtility.WeekDay();
        initialCalendarData(summaryId);
        resetCalendarData();
    }
    
    public void resetCalendarData()
    {
        clearData();
        List<Sales_Monthly_Details__c> details = [select Id, DemoTarget__c, Day_Status__c, WeekDayStatus__c, Date__c, Day__c, Month__c, year__c, FinishWorkingTime__c, StartWorkingTime__c from Sales_Monthly_Details__c where Sales_Monthly_Schedule_Summary__c = :summaryId and Sales_Consultant__c = :SalesUserId order by Date__c];
        if(details.size() > 0)
        {
            DemoTarget = (details[0].DemoTarget__c == null)? DemoTarget: details[0].DemoTarget__c.intValue();
            for(Sales_Monthly_Details__c detail : details)
            {
                if(detail.day__c != null)
                {
                    Integer dayKey;
                    dayKey = Integer.valueOf(detail.day__c);
                    monthlyDetailMap.put(dayKey, detail);
                }
            }
            List<Sales_Monthly_Details__c> firstSeventDetails = new List<Sales_Monthly_Details__c>{monthlyDetailMap.get(1), monthlyDetailMap.get(2), monthlyDetailMap.get(3), monthlyDetailMap.get(4), monthlyDetailMap.get(5), monthlyDetailMap.get(6), monthlyDetailMap.get(7)};
            if(details[0].weekDayStatus__c == null)
            {
                initialNonWorkingDay(details, workingWeekDayMap, nonWorkingDaySet);
            }
            else
            {
                initialNonWorkingDay(details);
            }
            weekDay.setWeekCalendarDataAsBefore(firstSeventDetails);
        }
        else
        {
            resetInitialDateFromGroupData(summaryId);
        }
    } 
    
    public List<SelectOption> getStartWorkingTimeList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('9:00', '9:00'));
        options.add(new SelectOption('10:00', '10:00'));
        options.add(new SelectOption('11:00', '11:00'));
        options.add(new SelectOption('12:00', '12:00')); 
        return options;
    }
    
    public List<SelectOption> getFinishWorkingTimeList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('14:00', '14:00'));
        options.add(new SelectOption('18:00', '18:00'));
        options.add(new SelectOption('19:00', '19:00'));
        options.add(new SelectOption('20:00', '20:00'));
        options.add(new SelectOption('21:00', '21:00')); 
        return options;
    }
    
    private void resetInitialDateFromGroupData(String summaryIdValue)
    {
        if(summaryIdValue != null)
        {
            List<Sales_Month_Summary__c> summaries = [select Id, Year__c, Month__c, School__c, Date__c, DemoTarget__c, WorkingWeekday__c, NonWorkingDay__c from Sales_Month_Summary__c where Id = :summaryIdValue];
            if(summaries.size() > 0)
            { 
                MonthSummary.NonWorkingDay__c = summaries[0].NonWorkingDay__c;
                DemoTarget = (summaries[0].DemoTarget__c != null)? summaries[0].DemoTarget__c.intValue(): 0;
                mainSummaryRecord = summaries[0];
                weekDay.setCalendarDataToDefault();
            }
        }
    }
    
    public PageReference save()
    {
        try
        {
            checkAndDeleteOldDuplicateCalendarData(); // delete all duplicate calendar data.
            Set<Integer> currentNonWorkingDaySet = generateNonWorkingDaySet(MonthSummary.NonWorkingDay__c); 
            if(monthlyDetailMap.size() > 0)
            { // If sales calendar monthly detail has existed in system. 
                for(Integer workingDay : monthlyDetailMap.keySet())
                {
                    Sales_Monthly_Details__c detail = monthlyDetailMap.get(workingDay);
                    //Integer dayValue = (detail.day__c != null)? Integer.valueOf(detail.day__c): 0;
                    Integer weekDayValue = Math.mod(workingDay + intervalParameter, 7); // Get the week day of this date.
                    Date workingDate = detail.Date__c; 
                    BrazilWorkCalendarDataUtility.WeekDayEntity entity = weekDay.getWeekDayEntityMap().get(weekDayValue);
                    detail.DemoTarget__c = DemoTarget;
                    detail.StartWorkingTime__c = entity.getStartDatetime(workingDate); //Datetime.newInstance(workingDate, StartWorkingTime);
                    detail.FinishWorkingTime__c = entity.getFinishDatetime(workingDate); //Datetime.newInstance(workingDate, FinishWorkingTime);
                    Boolean isWorkingWeekDay = entity.isWorkingDay;
                    detail.WeekDayStatus__c = (isWorkingWeekDay)? onduty: dayOff;
                    if(currentNonWorkingDaySet.contains(workingDay))
                    {
                        detail.Day_Status__c = dayOff;
                    }
                    else 
                    {
                        detail.Day_Status__c = (isWorkingWeekDay != null && isWorkingWeekDay == true)? onduty: dayOff;
                    }
                } 
                update monthlyDetailMap.values();
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Save data successfully.'));
            }
            else
            { // If no monthly detail for sales in system. 
                createNewMonthDetailsForSales(currentNonWorkingDaySet);
                resetCalendarData();
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    private void checkAndDeleteOldDuplicateCalendarData()
    {
        if(mainSummaryRecord != null && mainSummaryRecord.Id != null)
        {
            String tempMonth = mainSummaryRecord.month__c;
            String tempYear = mainSummaryRecord.year__c;
            if(tempMonth != null && tempYear != null)
            {
                List<Sales_Monthly_Details__c> details = [select Id from Sales_Monthly_Details__c where Sales_Monthly_Schedule_Summary__c != :mainSummaryRecord.Id and Sales_Consultant__c = :SalesUserId and Sales_Consultant__c != null and year__c = :tempYear and Month__c = :tempMonth];
                if(details.size() > 0)
                {
                    delete details;
                }
            }
        }
    }
    
    private void createNewMonthDetailsForSales(Set<Integer> currentNonWorkingDaySet)
    {
        List<Sales_Monthly_Details__c> newMonthlyDetails = new List<Sales_Monthly_Details__c>();
        Date summaryDate = (mainSummaryRecord != null)? mainSummaryRecord.Date__c: null;
        Integer yearValue = (summaryDate != null)? summaryDate.year(): null;
        Integer monthValue = (summaryDate != null)? summaryDate.month(): null;
        Integer daysOfMonth = Date.daysInMonth(yearValue, monthValue);
        Integer firstWeekDayOfThisMonth = getWeekDay(yearValue, monthValue, 1);
        Integer intervalParameter = firstWeekDayOfThisMonth - 1;
        for(Integer i = 1; i <= daysOfMonth; i++)
        {
            Date tempDate = Date.newInstance(yearValue, monthValue, i);
            Integer tempWeekDay = Math.abs(Math.mod((i + intervalParameter), 7));
            // Get calendar entity.
            BrazilWorkCalendarDataUtility.WeekDayEntity entity = weekDay.getWeekDayEntityMap().get(tempWeekDay);
            Boolean isWorkingWeekDay = (entity.isWorkingDay != null && entity.isWorkingDay == true)? true: false;
            Boolean isNonWorkingDay = currentNonWorkingDaySet.contains(i);
            String dayStatus = (!isWorkingWeekDay || isNonWorkingDay)? dayOff: onduty;
            String weekDayStatus = (isWorkingWeekDay)? onduty: dayOff;
            Sales_Monthly_Details__c newMonthlyDetail = assignValueToMonthlyDetail(dayStatus, weekDayStatus, entity.getStartDatetime(tempDate), entity.getFinishDatetime(tempDate), tempDate);
            newMonthlyDetails.add(newMonthlyDetail);
        }
        insert newMonthlyDetails;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Save data successfully.'));
    }
    
    private Sales_Monthly_Details__c assignValueToMonthlyDetail(String dayStatus, String weekDayStatus, Datetime StartWorkingTime, Datetime FinishWorkingTime, Date tempDate)
    {
        Sales_Monthly_Details__c newMonthlyDetail = new Sales_Monthly_Details__c();
        newMonthlyDetail.Date__c = tempDate;
        newMonthlyDetail.StartWorkingTime__c = StartWorkingTime; //Datetime.newInstance(tempDate, StartWorkingTime);
        newMonthlyDetail.FinishWorkingTime__c = FinishWorkingTime; //Datetime.newInstance(tempDate, FinishWorkingTime);
        newMonthlyDetail.Day_Status__c = dayStatus;
        newMonthlyDetail.WeekDayStatus__c = weekDayStatus;
        newMonthlyDetail.DemoTarget__c = DemoTarget;
        newMonthlyDetail.Sales_Consultant__c = SalesUserId;
        newMonthlyDetail.Sales_Monthly_Schedule_Summary__c = mainSummaryRecord.Id;
        return newMonthlyDetail;
    }
    
    public PageReference returnToGroupCalendar()
    {
        PageReference groupCalendar = new PageReference('/apex/BrazilGroupWorkCalendar');
        return groupCalendar;
    }
    
    private void clearData()
    {
        monthlyDetailMap.clear();
    }
    
    private void initialCalendarData(String summaryId)
    {  
        monthSummary = new Sales_Month_Summary__c();
        List<Sales_Month_Summary__c> summaries = [select Id, Year__c, Month__c, School__c, Date__c, DemoTarget__c, WorkingWeekday__c, NonWorkingDay__c from Sales_Month_Summary__c where Id = :summaryId];
        if(summaries.size() > 0)
        {   
            mainSummaryRecord = summaries[0];
            monthSummary.NonWorkingDay__c = summaries[0].NonWorkingDay__c;
            monthSummary.School__c = summaries[0].School__c;
            DemoTarget = (summaries[0].DemoTarget__c != null)? summaries[0].DemoTarget__c.intValue(): 0; // Initialize from group calendar.
            workingWeekDayMap = generateWorkingWeekDayMap(summaries[0].WorkingWeekday__c); // Initialize from group calendar.
            nonWorkingDaySet = generateNonWorkingDaySet(summaries[0].NonWorkingDay__c); // Initialize from group calendar.
            SalesUserList = generateUserList(monthSummary.School__c); // Initialize sales list.
            SalesUserId = (SalesUserList.size() > 0)? SalesUserList[0].getValue(): ''; 
            intervalParameter = getWeekDay(Integer.valueOf(summaries[0].Year__c), Integer.valueOf(summaries[0].Month__c), 1) - 1;
        }
        else
        {
            DisableSaveButton = true;
        }
    }
    
    private Map<Integer, Boolean> generateWorkingWeekDayMap(String weekDayString)
    {
        Map<Integer, Boolean> resultMap = new Map<Integer, Boolean>{0 => false, 1 => false, 2 => false, 3 => false, 4 => false, 5 => false, 6 => false};
        Map<String, Integer> weekDay2Number = new Map<String, Integer>{'Sunday' => 0, 'Monday' => 1, 'Tuesday' => 2, 'Wednesday' => 3, 'Thursday' => 4, 'Friday' => 5, 'Saturday' => 6};
        if(weekDayString != null)
        {
            List<String> weekDayStringList = weekDayString.split(';');
            if(weekDayStringList != null)
            {
                for(String weekDay : weekDayStringList) 
                {
                    Integer weekDayNumber = weekDay2Number.get(weekDay);
                    if(weekDayNumber != null)
                    {
                        resultMap.put(weekDayNumber, true);
                    }
                }
            }
        }
        return resultMap;
    }
    
    private String formatTimeToString(Datetime datetimeValue)
    {
        String result = '';
        if(datetimeValue != null)
        {
            Integer hourValue = datetimeValue.hour();
            Integer minuteValue = datetimeValue.minute();
            String hourValueString = (hourValue < 10)? '0' + hourValue: hourValue + '';
            String minuteValueString = (minuteValue < 10)? '0' + minuteValue: minuteValue + '';
            result = hourValueString + ':' + minuteValueString;
        }
        return result;
    }
    
    private Time parseTimeString(String timeString)
    {
        Time result;
        try
        {
            if(timeString != null)
            {   
                List<String> parseHourList = timeString.split(':');
                if(parseHourList.size() == 2 )
                {
                    Integer hourValue = Integer.valueOf(parseHourList[0]);
                    Integer minuteValue = Integer.valueOf(parseHourList[1]);
                    result = Time.newInstance(hourValue, minuteValue, 0, 0);
                }
                else
                {
                    throw new CreateBrazilCalendarDataException('Invalid time format. Please check.');
                }
            }
        }
        catch(Exception ex)
        {
            throw new CreateBrazilCalendarDataException('Invalid time format. Please check.');
        }
        return result;
    }
    
    private Set<Integer> generateNonWorkingDaySet(String nonWorkingDayString)
    {
        Set<Integer> resultSet = new Set<Integer>();
        if(nonWorkingDayString != null)
        {
            List<String> nonWorkingDayStringList = nonWorkingDayString.split(';');
            if(nonWorkingDayStringList != null)
            {
                for(String dayValue : nonWorkingDayStringList)
                {
                    if(dayValue != null)
                    {
                        resultSet.add(Integer.valueOf(dayValue));
                    }
                }
            }
        }
        return resultSet;
    }
    
    private void initialNonWorkingDay(List<Sales_Monthly_Details__c> details, Map<Integer, Boolean> weekMap, Set<Integer> daySet)
    {
        if(details != null && weekMap != null && daySet != null)
        {  
            Set<Integer> tempNonWorkingDaySet = new Set<Integer>();
            for(Sales_Monthly_Details__c detail : details)
            {
                if(detail.day__c != null)
                {
                    Boolean isWorkingDay = isDefaultWorkingDay(Integer.valueOf(detail.day__c), weekMap, intervalParameter);
                    if(detail.Day_Status__c == dayOff && isWorkingDay)
                    {
                        tempNonWorkingDaySet.add(Integer.valueOf(detail.day__c));
                    }
                }
            }
            String resultString = ''; 
            for(Integer nonworkingDay : tempNonWorkingDaySet)
            {
                resultString += nonworkingDay;
                resultString += ';';
            }
            MonthSummary.NonWorkingDay__c = resultString; 
        }
    }
    
    // This method for new brazil calendar logic.
    private void initialNonWorkingDay(List<Sales_Monthly_Details__c> details)
    {
        if(details != null && details.size() > 0)
        {
            String resultString = ''; 
            for(Sales_Monthly_Details__c detail : details)
            {
                if(detail.day__c != null && detail.weekDayStatus__c == onduty && detail.Day_Status__c == dayOff)
                {
                    resultString += detail.day__c;
                    resultString += ';';
                }
            }
            MonthSummary.NonWorkingDay__c = resultString;
        }
    }
    
    private Boolean isDefaultWorkingDay(Integer dayValue, Map<Integer, Boolean> weekMap, Integer interval)
    {
        Boolean result = false;
        if(dayValue != null)
        {
            result = (weekMap.get(Math.mod(dayValue + interval, 7)) == true)? true: false;
        }
        return result;
    }
    
    private List<SelectOption> generateUserList(String salesRoleName)
    {
        List<SelectOption> options = new List<SelectOption>();
        if(salesRoleName != null)
        {
            List<User> salesUsers = [select Id, Name from User where UserRole.Name = :salesRoleName and isActive = true order by Name];
            for(User user: salesUsers)
            {   
                options.add(new SelectOption(user.Id, user.Name));
            }
        }
        return options;
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
    
    public class CreateBrazilCalendarDataException extends Exception {}
    
    @isTest
    static void testBrazilSalesWorkCalendarController()
    {
        // Creates test data.
        List<User> salesUsers = [select Id, Name, UserRole.Name, UserRoleId from User where IsActive = true and (UserRole.Name like 'Brazil % Sales' or (UserRole.Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%'))) limit 1];
        String testSalesUserRole = salesUsers[0].UserRole.Name; 
        List<User> allGroupUsers = [select Id, Name from User where UserRoleId = :salesUsers[0].UserRoleId and IsActive = true limit 10];
        String salesUserId = allGroupUsers[0].Id;
        Sales_Month_Summary__c summary = new Sales_Month_Summary__c();
        String startWorkingTimeString = '9:00';
        String finishWorkingTimeString = '21:00';
        // For Monday.
        summary.StartWorkingTime1__c = startWorkingTimeString;
        summary.FinishWorkingTime1__c = finishWorkingTimeString;
        // For Tuesday.
        summary.StartWorkingTime2__c = startWorkingTimeString;
        summary.FinishWorkingTime2__c = finishWorkingTimeString;
        // For Wednesday.
        summary.StartWorkingTime3__c = startWorkingTimeString;
        summary.FinishWorkingTime3__c = finishWorkingTimeString;
        // For Thursday.
        summary.StartWorkingTime4__c = startWorkingTimeString;
        summary.FinishWorkingTime4__c = finishWorkingTimeString;
       // For Friday.
        summary.StartWorkingTime5__c = startWorkingTimeString;
        summary.FinishWorkingTime5__c = finishWorkingTimeString;
        // For Saturday.
        summary.StartWorkingTime6__c = startWorkingTimeString;
        summary.FinishWorkingTime6__c = finishWorkingTimeString;
        // For Sunday.
        summary.StartWorkingTime7__c = startWorkingTimeString;
        summary.FinishWorkingTime7__c = finishWorkingTimeString;
        summary.DemoTarget__c = 15;
        summary.SummaryOrg__c = 'Brazil';
        summary.Manager__c = UserInfo.getUserId();
        summary.Sales_Amount__c = 10;
        summary.Date__c = Date.newInstance(1999, 2, 1);
        summary.School__c = testSalesUserRole;
        summary.WorkingWeekday__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Sunday';
        summary.NonWorkingDay__c = '14;15;16;17';
        insert summary;
        Integer daysInMonth = Date.daysInMonth(1999, 2);
        List<Sales_Monthly_Details__c> details = new List<Sales_Monthly_Details__c>();
        for(Integer i = 0; i < daysInMonth; i++)
        {
            Sales_Monthly_Details__c tempDetail = new Sales_Monthly_Details__c();
            tempDetail.Date__c = Date.newInstance(1999, 2, i + 1);
            tempDetail.Sales_Consultant__c = salesUserId;
            tempDetail.WeekDayStatus__c = 'On Duty';
            tempDetail.Sales_Monthly_Schedule_Summary__c = summary.Id;
            tempDetail.DemoTarget__c = 15;
            if(i == 13 || i == 14 || i == 15 || i == 16)
            {
                tempDetail.Day_Status__c = 'Day Off';
            }
            else
            {
                tempDetail.Day_Status__c = 'On Duty';
            }
            details.add(tempDetail);
        } 
        insert details;
        // Test for this controller.
        PageReference salesCalendarPage = new PageReference('/apex/BrazilSalesWorkCalendar?id=' + summary.Id);
        Test.setCurrentPage(salesCalendarPage);
        BrazilSalesWorkCalendarController testController = new BrazilSalesWorkCalendarController(); 
        testController.SalesUserId = salesUserId;
        testController.resetCalendarData();
        testController.DemoTarget = 12;
        testController.MonthSummary.NonWorkingDay__c = '14;15;16;17;21;22';
        testController.save();
        Date testDate = Date.newInstance(2011, 9, 19);
        Time testTime = Time.newInstance(9, 30, 40, 0);
        Datetime testDatetime = Datetime.newInstance(testDate, testTime);
        System.assertEquals('09:30', testController.formatTimeToString(testDatetime));
        List<Sales_Monthly_Details__c> details2 = [select Id, DemoTarget__c, Day_Status__c from Sales_Monthly_Details__c where Sales_Consultant__c = :salesUserId and Date__c = :Date.newInstance(1999, 2, 22)];
        System.assertEquals(12, details2[0].DemoTarget__c);
        testController.returnToGroupCalendar();
        List<Sales_Month_Summary__c> summaries = [select Id, Year__c, Month__c, School__c, Date__c, DemoTarget__c, WorkingWeekday__c, NonWorkingDay__c from Sales_Month_Summary__c where Id = :summary.Id];
        testController.mainSummaryRecord = summaries[0];
        Time tempStartWorkingTime = Time.newInstance(9, 0, 0, 0);
        Time tempFinishWorkingTime = Time.newInstance(22, 0, 0, 0);
        testController.getStartWorkingTimeList();
        testController.getFinishWorkingTimeList();
        testController.createNewMonthDetailsForSales(new Set<Integer>{1,2,3,4});
    }
}