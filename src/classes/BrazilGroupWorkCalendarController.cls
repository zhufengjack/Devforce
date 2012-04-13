/*
*  Controller for group calendar.
*/ 
public class BrazilGroupWorkCalendarController 
{
    public String Center {get; set;}
    public String SalesRoleName {get; set;}
    public Integer year {get; set;}
    public Integer month {get; set;}
    public Integer DemoTarget {get; set;}
    public BrazilWorkCalendarDataUtility.WeekDay weekDay {get; set;}
    public Sales_Month_Summary__c monthSummary {get; set;}
    public List<SelectOption> SalesGroupList {get; set;}
    public Boolean CalendarForThisMonthIsSetUp {get; set;}
    
    public BrazilGroupWorkCalendarController()
    {
        try
        {
            initialControllerData();
            resetSalesGroupList();
            initialSalesRoleName();
            resetSalesGroupCalendarData();
        }
        catch(Exception ex)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, ex.getMessage()));
        }
    } 
       
    public List<SelectOption> getCallCenterList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Call Center', 'Call Center'));
        List<UserRole> managerRoles = [select Id, Name from UserRole where Name like 'Brazil % Sales Manager']; 
        if(managerRoles.size() > 0)
        {
            for(UserRole role : managerRoles)
            {
                String roleKeyWord = generateCenterKeyWord(role.Name);
                options.add(new SelectOption(roleKeyWord, roleKeyWord));
            } 
        }
        return options;
    }
    
    public void resetSalesGroupList()
    {
        SalesGroupList = generateSalesGroupList();
    }
    
    public void resetSalesGroupCalendarData()
    {
        String yearValue = String.valueOf(year);
        String monthValue = String.valueOf(month);
        List<Sales_Month_Summary__c> summaries = [select Id, WorkingWeekday__c, DemoTarget__c, NonWorkingDay__c, 
                                                    StartWorkingTime1__c, StartWorkingTime2__c, StartWorkingTime3__c, StartWorkingTime4__c, StartWorkingTime5__c, StartWorkingTime6__c, StartWorkingTime7__c, 
                                                    FinishWorkingTime1__c, FinishWorkingTime2__c, FinishWorkingTime3__c, FinishWorkingTime4__c, FinishWorkingTime5__c, FinishWorkingTime6__c, FinishWorkingTime7__c 
                                                    from Sales_Month_Summary__c 
                                                    where Year__c = :yearValue and month__c = :monthValue and SummaryOrg__c = 'Brazil' and School__c = :SalesRoleName and WorkingWeekday__c != null 
                                                    limit 2
                                                  ];
        if(summaries.size() > 0)
        {
            setCalendarDataAsBefore(summaries[0]);
            CalendarForThisMonthIsSetUp = true;
            if(summaries.size() == 2)
            {
                throw new CreateBrazilCalendarDataException('Error: Find more than one Month Summary record. Please contact system administrator.');
            }
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Calendar has been set up.'));
        }
        else
        {
            CalendarForThisMonthIsSetUp = false;
            setCalendarDataAsDefault();
        }
    }
    
    public PageReference saveAndNextPage()
    {
        PageReference salesWorkCalendar;
        String summaryId;
        try
        {
            summaryId = saveCalendarData();
            List<Sales_Month_Summary__c> summaries = [select Id from Sales_Month_Summary__c where Id = :summaryId];
            if(summaries.size() > 0)
            {
                salesWorkCalendar = new PageReference('/apex/BrazilSalesWorkCalendar?Id=' + summaryId);
            }
            else
            {
                throw new CreateBrazilCalendarDataException('Create calendar data fail.');
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return salesWorkCalendar;
    }
    
    public PageReference next()
    {
        PageReference salesWorkCalendar;
        if(monthSummary != null && monthSummary.Id != null)
        {
            salesWorkCalendar = new PageReference('/apex/BrazilSalesWorkCalendar?Id=' + monthSummary.Id);
        }
        return salesWorkCalendar;
    }
    
    private void initialSalesRoleName()
    {
        if(SalesGroupList != null && SalesGroupList.size() > 0)
        {
            SalesRoleName = SalesGroupList[0].getValue();
        }
    }
    
    private void deleteErrorData(String summaryId)
    {
        if(summaryId != null)
        {
            delete new Sales_Month_Summary__c(Id = summaryId);
        }
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
    
    private void setCalendarDataAsBefore(Sales_Month_Summary__c summary)
    {
        DemoTarget = (summary.DemoTarget__c != null)? summary.DemoTarget__c.intValue(): 0;
        monthSummary = summary;
        weekDay.setWeekWorkingDay(summary.WorkingWeekday__c);
        // Added a new method to initial start work and finish work.
        weekDay.setStartAndFinishWorkingTime(summary);
    }
    
    private void setCalendarDataAsDefault()
    { 
        monthSummary = new Sales_Month_Summary__c();
        String weekWorkingDayString = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday';
        String defaultStart = '9:00';
        String defaultFinish = '18:00';
        DemoTarget = null;
        weekDay.setWeekWorkingDay(weekWorkingDayString);
        weekDay.setStartAndFinishWorkingTime(defaultStart, defaultFinish);
    }
     
    private String saveCalendarData()
    {
        String summaryId;
        Sales_Month_Summary__c tempMonthSummary = new Sales_Month_Summary__c();
        // Delete old sales calendar data.
        if(monthSummary.Id != null)
        {
            delete new Sales_Month_Summary__c(Id = monthSummary.Id);
            monthSummary = new Sales_Month_Summary__c(NonWorkingDay__c = monthSummary.NonWorkingDay__c);
        }
        // Create new sales calendar data.
        List<User> salesUsers = getSalesUsers(SalesRoleName);
        summaryId = createMonthSummary(salesUsers.size());
        try
        {
            createMonthDetail(summaryId, salesUsers);
        }
        catch(Exception ex)
        {
            deleteErrorData(summaryId);
            throw ex;
        }
        return summaryId;
    }
    
    private String createMonthSummary(Integer salesAmount)
    {
        String resultId;
        if(salesAmount != null && salesAmount > 0)
        {
            monthSummary.DemoTarget__c = DemoTarget;
            monthSummary.SummaryOrg__c = 'Brazil';
            monthSummary.Manager__c = UserInfo.getUserId();
            monthSummary.Sales_Amount__c = salesAmount;
            monthSummary.Date__c = Date.newInstance(year, month, 1);
            monthSummary.School__c = SalesRoleName;
            monthSummary.WorkingWeekday__c = weekDay.generateWorkingDayString();
            // For Monday.
            monthSummary.StartWorkingTime1__c = weekDay.Monday.StartWorkingTime;
            monthSummary.FinishWorkingTime1__c = weekDay.Monday.FinishWorkingTime;
            // For Tuesday.
            monthSummary.StartWorkingTime2__c = weekDay.Tuesday.StartWorkingTime;
            monthSummary.FinishWorkingTime2__c = weekDay.Tuesday.FinishWorkingTime;
            // For Wednesday.
            monthSummary.StartWorkingTime3__c = weekDay.Wednesday.StartWorkingTime;
            monthSummary.FinishWorkingTime3__c = weekDay.Wednesday.FinishWorkingTime;
            // For Thursday.
            monthSummary.StartWorkingTime4__c = weekDay.Thursday.StartWorkingTime;
            monthSummary.FinishWorkingTime4__c = weekDay.Thursday.FinishWorkingTime;
            // For Friday.
            monthSummary.StartWorkingTime5__c = weekDay.Friday.StartWorkingTime;
            monthSummary.FinishWorkingTime5__c = weekDay.Friday.FinishWorkingTime;
            // For Saturday.
            monthSummary.StartWorkingTime6__c = weekDay.Saturday.StartWorkingTime;
            monthSummary.FinishWorkingTime6__c = weekDay.Saturday.FinishWorkingTime;
            // For Sunday.
            monthSummary.StartWorkingTime7__c = weekDay.Sunday.StartWorkingTime;
            monthSummary.FinishWorkingTime7__c = weekDay.Sunday.FinishWorkingTime;
            insert monthSummary;
            resultId = monthSummary.Id;
        }
        return resultId;
    }
    
    private void createMonthDetail(String summaryId, List<User> salesUsers)
    {
        List<Sales_Monthly_Details__c> monthDetails = new List<Sales_Monthly_Details__c>();
        if(summaryId != null && salesUsers.size() > 0)
        {
            Map<Integer, BrazilWorkCalendarDataUtility.WeekDayEntity> workingDayMap = weekDay.generateWorkingDayMap(year, month); 
            Set<Integer> nonWorkingDaySet = generateNonWorkingDaySet(monthSummary.NonWorkingDay__c);
            Set<String> SalesUserIds = new Set<String>(); // Store sales user id in this set. After create detail object, we will check duplicate data for all users whose id in this set.
            for(User sales : salesUsers)
            {
                List<Sales_Monthly_Details__c> results = createMonthDetailForIndividualSales(summaryId, sales.Id, workingDayMap, nonWorkingDaySet);
                if(results.size() > 0)
                {
                    monthDetails.addAll(results);
                    SalesUserIds.add(sales.Id);
                }
            } 
            if(monthDetails.size() > 0)
            {
                insert monthDetails;
                checkAndDeleteDuplicateDetailData(SalesUserIds, summaryId, year, month);
            }
            else
            {
                delete new Sales_Month_Summary__c(Id = summaryId);
            } 
        }
    }
    
    // Delete duplicate data.
    private void checkAndDeleteDuplicateDetailData(Set<String> salesUserIds, String summaryId, Integer yearValue, Integer monthValue)
    {
        if(SalesUserIds != null && SalesUserIds.size() > 0 && yearValue != null && monthValue != null && summaryId != null)
        {
            String tempYear = String.valueOf(yearValue);
            String tempMonth = String.valueOf(monthValue);
            List<Sales_Monthly_Details__c> tempDetails = [select Id from Sales_Monthly_Details__c where Sales_Monthly_Schedule_Summary__c != :summaryId and Sales_Consultant__c in :salesUserIds and Sales_Consultant__c != null and year__c = :tempYear and Month__c = :tempMonth];
            if(tempDetails.size() > 0)
            {
                delete tempDetails;
            }
        }
    }
    
    private List<Sales_Monthly_Details__c> createMonthDetailForIndividualSales(String summaryId, String salesUserId, Map<Integer, BrazilWorkCalendarDataUtility.WeekDayEntity> workingDayMap, Set<Integer> nonWorkingDaySet)
    {
        List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
        if(summaryId != null && salesUserId != null && workingDayMap != null)
        {
            for(Integer dayInMonth : workingDayMap.keySet())
            {
                Sales_Monthly_Details__c tempDetail = new Sales_Monthly_Details__c();
                BrazilWorkCalendarDataUtility.WeekDayEntity tempWeekDayEntity = workingDayMap.get(dayInMonth);
                tempDetail.Date__c = Date.newInstance(year, month, dayInMonth);
                tempDetail.StartWorkingTime__c = tempWeekDayEntity.getStartDatetime(tempDetail.Date__c);
                tempDetail.FinishWorkingTime__c = tempWeekDayEntity.getFinishDatetime(tempDetail.Date__c);
                tempDetail.Sales_Consultant__c = salesUserId;
                tempDetail.Sales_Monthly_Schedule_Summary__c = summaryId;
                tempDetail.DemoTarget__c = DemoTarget;  
                tempDetail.Day_Status__c = (tempWeekDayEntity.isWorkingDay && !nonWorkingDaySet.contains(dayInMonth))? 'On Duty': 'Day Off';
                tempDetail.weekDayStatus__c = (tempWeekDayEntity.isWorkingDay)? 'On Duty': 'Day Off';
                monthlyDetails.add(tempDetail);
            }
        }
        return monthlyDetails;
    }
    
    private List<User> getSalesUsers(String roleNameValue)
    {
        List<User> users;
        if(roleNameValue != null)
        {
            users = [select Id from User where UserRole.Name = :roleNameValue and IsActive = true];
        }
        return users;
    }
    
    private List<SelectOption> generateSalesGroupList()
    {
        List<SelectOption> options = new List<SelectOption>();
        List<UserRole> userRoles;
        if(Center == 'call center')
        {
            userRoles = [select Id, Name from UserRole where Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%') order by Name];
        }
        else
        {
            String salesRoleName = 'Brazil ' + Center + ' Sales'; 
            userRoles = [select Id, Name from UserRole where Name = :salesRoleName order by Name];
        }
        if(userRoles != null)
        {
            for(UserRole role : userRoles)
            {
                options.add(new SelectOption(role.Name, role.Name));
            }
        }
        return options;
    }
    
    private void initialControllerData()
    {
        year = Date.today().year();
        month = Date.today().month();
        Center = 'call center';
        weekDay = new BrazilWorkCalendarDataUtility.weekDay();
    }
    
    private Set<Integer> generateNonWorkingDaySet(String nonWorkingDayQueue)
    {
        Set<Integer> resultSet = new Set<Integer>();
        if(nonWorkingDayQueue != null)
        {
            List<String> nonWorkingDays = nonWorkingDayQueue.split(';');
            for(String nonWorkingDay : nonWorkingDays)
            {
                resultSet.add(Integer.valueOf(nonWorkingDay));
            }
        }
        return resultSet;
    }
    
    public List<SelectOption> getYearList()
    {
        List<SelectOption> options = new List<SelectOption>();
        Integer currentYear = Date.today().year();
        List<Integer> years = new List<Integer>();
        for(Integer i = currentYear - 2; i < currentYear + 5; i++)
        {
            options.add(new SelectOption(String.valueOf(i), String.valueOf(i)));
        }  
        return options;
    }
    
    public List<SelectOption> getMonthList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('1', 'January')); 
        options.add(new SelectOption('2', 'February')); 
        options.add(new SelectOption('3', 'March')); 
        options.add(new SelectOption('4', 'April')); 
        options.add(new SelectOption('5', 'May')); 
        options.add(new SelectOption('6', 'June')); 
        options.add(new SelectOption('7', 'July')); 
        options.add(new SelectOption('8', 'August')); 
        options.add(new SelectOption('9', 'September')); 
        options.add(new SelectOption('10', 'October'));
        options.add(new SelectOption('11', 'November')); 
        options.add(new SelectOption('12', 'December')); 
        return options;
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
    
    public class CreateBrazilCalendarDataException extends Exception {}
    
    @isTest
    static void testBrazilGroupWorkCalendarController()
    {
        // Test weekDay class end.
        BrazilGroupWorkCalendarController testController = new BrazilGroupWorkCalendarController();
        System.assertEquals(12, testController.getMonthList().size());
        System.assertEquals([select Id, Name from UserRole where Name like 'Brazil % Sales Manager'].size() + 1, testController.getCallCenterList().size());
        System.assertEquals(7, testController.getYearList().size());
        //Test for saving work calendar.
        List<User> salesUsers = [select Id, Name, UserRole.Name, UserRoleId from User where IsActive = true and (UserRole.Name like 'Brazil % Sales' or (UserRole.Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%'))) limit 1];
        String testSalesUserRole = salesUsers[0].UserRole.Name; 
        List<User> allGroupUsers = [select Id, Name from User where UserRoleId = :salesUsers[0].UserRoleId and IsActive = true limit 10];
        Integer salesAmount = allGroupUsers.size(); 
        BrazilGroupWorkCalendarController testController2 = new BrazilGroupWorkCalendarController();
        testController2.DemoTarget = 15;
        testController2.SalesRoleName = testSalesUserRole;
        testController2.year = 1993;
        testController2.month = 9;
        testController2.monthSummary.NonWorkingDay__c = '13;14;15';
        PageReference nextPage = testController2.saveAndNextPage();
        System.assertNotEquals(null, nextpage);
        List<Sales_Monthly_Details__c> monthlyDetails = [select Id, Sales_Consultant__c, Sales_Monthly_Schedule_Summary__c, DemoTarget__c, Day_Status__c, Year__c, Month__c from Sales_Monthly_Details__c where Year__c = '1993' and Month__c = '9' and Sales_Consultant__c = :allGroupUsers[0].Id];
        System.assertEquals(30, monthlyDetails.size());
        PageReference nextPage2 = testController2.next();
        testController2.getFinishWorkingTimeList();
        testController2.getStartWorkingTimeList();
        Sales_Month_Summary__c summary2 = [select Id, WorkingWeekday__c, DemoTarget__c, NonWorkingDay__c, 
                                                    StartWorkingTime1__c, StartWorkingTime2__c, StartWorkingTime3__c, StartWorkingTime4__c, StartWorkingTime5__c, StartWorkingTime6__c, StartWorkingTime7__c, 
                                                    FinishWorkingTime1__c, FinishWorkingTime2__c, FinishWorkingTime3__c, FinishWorkingTime4__c, FinishWorkingTime5__c, FinishWorkingTime6__c, FinishWorkingTime7__c 
                                                    from Sales_Month_Summary__c 
                                                    where Id = :monthlyDetails[0].Sales_Monthly_Schedule_Summary__c
                                                    limit 1
                                                  ];
        testController2.setCalendarDataAsBefore(summary2);
    }
}