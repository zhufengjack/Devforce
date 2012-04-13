public class BrazilWorkCalendarDataUtility 
{
    public class WeekDay
    {
        public WeekDayEntity Monday 
        {
            get;
            set
            {
                Monday = value;
            }
        }
        
        public WeekDayEntity Tuesday 
        {
            get; 
            set
            {
                Tuesday = value;
            }
        }
        
        public WeekDayEntity Wednesday 
        {
            get; 
            set
            {
                Wednesday = value;
            }
        }
        
        public WeekDayEntity Thursday 
        {
            get; 
            set
            {
                Thursday = value;
            }
        }
        
        public WeekDayEntity Friday 
        {
            get; 
            set
            {
                Friday = value;
            }
        }
        
        public WeekDayEntity Saturday 
        {
            get; 
            set
            {
                Saturday = value;
            }
        }
        
        public WeekDayEntity Sunday 
        {
            get
            {
                Sunday.isWorkingDay = false;
                return Sunday;
            } 
            set
            {
                value.isWorkingDay = false;
                Sunday = value;
            }
        }
        
        final String onduty = 'On Duty';
        final String dayOff = 'Day Off'; 
        private Map<Integer, WeekDayEntity> weekDayEntityMap = new Map<Integer, WeekDayEntity>();
        
        public WeekDay()
        {
            // Initial weekDayEntityMap.
            Monday = new WeekDayEntity();
            Tuesday = new WeekDayEntity(); 
            Wednesday = new WeekDayEntity();
            Thursday = new WeekDayEntity();
            Friday = new WeekDayEntity();
            Saturday = new WeekDayEntity();
            Sunday = new WeekDayEntity();
            Sunday.isWorkingDay = false;
            weekDayEntityMap.put(1, Monday);
            weekDayEntityMap.put(2, Tuesday);
            weekDayEntityMap.put(3, Wednesday);
            weekDayEntityMap.put(4, Thursday);
            weekDayEntityMap.put(5, Friday);
            weekDayEntityMap.put(6, Saturday);
            weekDayEntityMap.put(0, Sunday);
        }
        
        public Map<Integer, WeekDayEntity> getWeekDayEntityMap()
        {
            return weekDayEntityMap;
        }
        
        public void setCalendarDataToDefault()
        {
        	String defaultStartTime = '9:00';
        	String defaultFinishTime = '18:00';
            this.Monday.setToOnduty();
            this.Monday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Tuesday.setToOnduty();
            this.Tuesday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Wednesday.setToOnduty();
            this.Wednesday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Thursday.setToOnduty();
            this.Thursday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Friday.setToOnduty();
            this.Friday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Saturday.setToOnduty();
            this.Saturday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
            this.Sunday.setToDayOff();
            this.Sunday.setStartAndFinishWorkingTime(defaultStartTime, defaultFinishTime);
        }
        
        public void setWeekCalendarDataAsBefore(List<Sales_Monthly_Details__c> monthlyDetails)
        {
            if(monthlyDetails != null && monthlyDetails.size() == 7)
            {
            	Map<Integer, Sales_Monthly_Details__c> weekDay2MonthlyDetail = new Map<Integer, Sales_Monthly_Details__c>();
                for(Sales_Monthly_Details__c detail : monthlyDetails)
                {
                	Integer yearValue = (detail.year__c != null)? Integer.valueOf(detail.year__c): 0;
                	Integer monthValue = (detail.month__c != null)? Integer.valueOf(detail.month__c): 0;
                	Integer dayValue = (detail.day__c != null)? Integer.valueOf(detail.day__c): 0; 
                    Integer tempKey = getWeekDay(yearValue, monthValue, dayValue);
                    assignValuesToWeekEntity(tempKey, detail);
                }
            }
        }
        
        public void assignValuesToWeekEntity(Integer weekDayNum, Sales_Monthly_Details__c detail)
        {
            if(weekDayNum != null && detail != null && weekDayEntityMap != null)
            {
                WeekDayEntity entity = weekDayEntityMap.get(weekDayNum);
                entity.isWorkingDay = (detail.WeekDayStatus__c == onduty || (detail.WeekDayStatus__c == null && detail.Day_Status__c != null))? true: false;
                entity.setStartAndFinishWorkingTime(formatTimeToString(detail.StartWorkingTime__c), formatTimeToString(detail.FinishWorkingTime__c));
            }
        }

        public Map<Integer, WeekDayEntity> generateWorkingDayMap(Integer yearValue, Integer monthValue)
        {
            Integer daysOfMonth = Date.daysInMonth(yearValue, monthValue);
            Integer firstWeekDayOfThisMonth = getWeekDay(yearValue, monthValue, 1);
            Integer intervalParameter = firstWeekDayOfThisMonth - 1;
            Map<Integer, WeekDayEntity> WorkingDayMap = new Map<Integer, WeekDayEntity>();
            for(Integer i = 1; i <= daysOfMonth; i++)
            {
                Integer tempWeekDay = Math.abs(Math.mod((i + intervalParameter), 7));
                WorkingDayMap.put(i, weekDayEntityMap.get(tempWeekDay));
            }
            return WorkingDayMap;
        }
        
        public String generateWorkingDayString()
        {
            String result = '';
            Map<Integer, String> weekDayLableMap = new Map<Integer, String>{0 => 'Sunday', 1 => 'Monday', 2 => 'Tuesday', 3 => 'Wednesday', 4 => 'Thursday', 5 => 'Friday', 6 => 'Saturday'};
            for(Integer weekDayKey : weekDayEntityMap.keySet())
            {  
                if(weekDayEntityMap.get(weekDayKey).isWorkingDay)
                {
                    result += weekDayLableMap.get(weekDayKey) + ';';
                }
            }
            return result; 
        }  
        
        public void setWeekWorkingDay(String weekWorkingDayString)
        {
            if(weekWorkingDayString != null)
            {
                List<String> weekdayList = weekWorkingDayString.split(';');
                Set<String> weekdaySet = new Set<String>();
                weekdaySet.addAll(weekdayList); 
                this.Monday.isWorkingDay = weekdaySet.contains('Monday');
                this.Tuesday.isWorkingDay = weekdaySet.contains('Tuesday');
                this.Wednesday.isWorkingDay = weekdaySet.contains('Wednesday');
                this.Thursday.isWorkingDay = weekdaySet.contains('Thursday');
                this.Friday.isWorkingDay = weekdaySet.contains('Friday');
                this.Saturday.isWorkingDay = weekdaySet.contains('Saturday');
                this.Sunday.isWorkingDay = weekdaySet.contains('Sunday');
            }
        }
        
        // initialize start time and finish time.
        public void setStartAndFinishWorkingTime(Sales_Month_Summary__c summary)
        {
            this.Monday.setStartAndFinishWorkingTime(summary.StartWorkingTime1__c, summary.FinishWorkingTime1__c);
            this.Tuesday.setStartAndFinishWorkingTime(summary.StartWorkingTime2__c, summary.FinishWorkingTime2__c);
            this.Wednesday.setStartAndFinishWorkingTime(summary.StartWorkingTime3__c, summary.FinishWorkingTime3__c);
            this.Thursday.setStartAndFinishWorkingTime(summary.StartWorkingTime4__c, summary.FinishWorkingTime4__c);
            this.Friday.setStartAndFinishWorkingTime(summary.StartWorkingTime5__c, summary.FinishWorkingTime5__c);
            this.Saturday.setStartAndFinishWorkingTime(summary.StartWorkingTime6__c, summary.FinishWorkingTime6__c);
            this.Sunday.setStartAndFinishWorkingTime(summary.StartWorkingTime7__c, summary.FinishWorkingTime7__c);
        }
        
        public void setStartAndFinishWorkingTime(String start, String finish)
        {
            this.Monday.setStartAndFinishWorkingTime(start, finish);
            this.Tuesday.setStartAndFinishWorkingTime(start, finish);
            this.Wednesday.setStartAndFinishWorkingTime(start, finish);
            this.Thursday.setStartAndFinishWorkingTime(start, finish);
            this.Friday.setStartAndFinishWorkingTime(start, finish);
            this.Saturday.setStartAndFinishWorkingTime(start, finish);
            this.Sunday.setStartAndFinishWorkingTime(start, finish);
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
    }
    
    public class WeekDayEntity
    {
        public Boolean isWorkingDay{get; set;}
        public String StartWorkingTime {get; set;}
        public String FinishWorkingTime {get; set;}
        
        public void setStartAndFinishWorkingTime(String start, String finish)
        {
            StartWorkingTime = start;
            FinishWorkingTime = finish;
        }
        
        public void setToOnDuty()
        {
            this.isWorkingDay = true;
        }
        
        public void setToDayOff()
        {
            this.isWorkingDay = false;
        }
        
        public Time getStartTime()
        {
            return parseTimeString(StartWorkingTime);
        }
        
        public Time getFinishTime()
        {
            return parseTimeString(FinishWorkingTime);
        }
        
        public Datetime getStartDatetime(Date dateValue)
        {
            Datetime result = null;
            if(dateValue != null && getStartTime() != null)
            {
                result = Datetime.newInstance(dateValue, getStartTime());
            }
            return result;
        }
        
        public Datetime getFinishDatetime(Date dateValue)
        {
            Datetime result = null;
            if(dateValue != null && getFinishTime() != null)
            {
               result = Datetime.newInstance(dateValue, getFinishTime());
            }
            return result;
        }
        
        private Time parseTimeString(String timeString)
        {
            Time result; 
            try
            {
                if(timeString != null && timeString != '')
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
                        throw new BrazilWorkCalendarException('Invalid time format. Please check.');
                    }
                }
            }
            catch(Exception ex)
            {
                throw new BrazilWorkCalendarException('Invalid time format. Please check.');
            }
            return result;
        }
    }
    
    public class BrazilWorkCalendarException extends Exception {}
    
    @isTest
    static void testBrazilWorkCalendarDataUtility()
    {
        WeekDay testWeekDay = new WeekDay();
        String startWorkingTimeString = '9:00';
        String finishWorkingTimeString = '21:00';
        system.assertEquals(7, testWeekDay.getWeekDayEntityMap().size());
        testWeekDay.setCalendarDataToDefault();
        List<User> salesUsers = [select Id, Name, UserRole.Name, UserRoleId from User where IsActive = true and (UserRole.Name like 'Brazil % Sales' or (UserRole.Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%'))) limit 1];
        String salesUserId = salesUsers[0].Id;
        Sales_Month_Summary__c summary = new Sales_Month_Summary__c();
        summary.DemoTarget__c = 15;
        summary.SummaryOrg__c = 'Brazil';
        summary.Manager__c = UserInfo.getUserId();
        summary.Sales_Amount__c = 10;
        summary.Date__c = Date.newInstance(1998, 3, 1);
        summary.School__c = 'Brazil Role';
        summary.WorkingWeekday__c = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        summary.NonWorkingDay__c = '14;15;16;17';
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
        insert summary;
        Integer detailSize = 7;
        List<Sales_Monthly_Details__c> testDetails = new List<Sales_Monthly_Details__c>();
        Time testStartTime = Time.newInstance(9, 0, 0, 0);
        Time testFinishTime = Time.newInstance(21, 0, 0, 0);
        for(Integer i = 0; i < detailSize; i++)
        {
        	Date tempDetailDate = Date.newInstance(1998, 3, i);
            Sales_Monthly_Details__c newMonthlyDetail = new Sales_Monthly_Details__c();
            newMonthlyDetail.Date__c = tempDetailDate;
            newMonthlyDetail.StartWorkingTime__c = Datetime.newInstance(tempDetailDate, testStartTime);
            newMonthlyDetail.FinishWorkingTime__c = Datetime.newInstance(tempDetailDate, testFinishTime);
            newMonthlyDetail.Day_Status__c = 'On Duty';
            newMonthlyDetail.WeekDayStatus__c = 'On Duty';
            newMonthlyDetail.DemoTarget__c = 9;
            newMonthlyDetail.Sales_Consultant__c = salesUserId;
            newMonthlyDetail.Sales_Monthly_Schedule_Summary__c = summary.Id;
            testDetails.add(newMonthlyDetail);
        }
        insert testDetails;
        List<Sales_Monthly_Details__c> testDetails2 = [select Id, DemoTarget__c, Day_Status__c, WeekDayStatus__c, Date__c, Day__c, Month__c, year__c, FinishWorkingTime__c, StartWorkingTime__c from Sales_Monthly_Details__c where Id in :testDetails];
        testWeekDay.setWeekCalendarDataAsBefore(testDetails2);
        System.assertEquals(true, testWeekDay.Monday.isWorkingDay);
        Integer yearValue = 1998;
        Integer monthValue = 7;
        Map<Integer, WeekDayEntity> testWorkingDayMap = testWeekDay.generateWorkingDayMap(yearValue, monthValue);
        System.assertEquals(31, testWorkingDayMap.size());
        testWeekDay.generateWorkingDayString();
        String weekWorkingDayString = 'Monday;Tuesday;Wednesday;Thursday;Friday';
        testWeekDay.setWeekWorkingDay(weekWorkingDayString);
        System.assertEquals(false, testWeekDay.Saturday.isWorkingDay);
        System.assertEquals(true, testWeekDay.Friday.isWorkingDay);
        List<Sales_Month_Summary__c> summaries = [select Id, WorkingWeekday__c, DemoTarget__c, NonWorkingDay__c, 
                                                    StartWorkingTime1__c, StartWorkingTime2__c, StartWorkingTime3__c, StartWorkingTime4__c, StartWorkingTime5__c, StartWorkingTime6__c, StartWorkingTime7__c, 
                                                    FinishWorkingTime1__c, FinishWorkingTime2__c, FinishWorkingTime3__c, FinishWorkingTime4__c, FinishWorkingTime5__c, FinishWorkingTime6__c, FinishWorkingTime7__c 
                                                    from Sales_Month_Summary__c 
                                                    where Id = :summary.Id
                                                    limit 1
                                                  ];
        testWeekDay.setStartAndFinishWorkingTime(summaries[0]);
        testWeekDay.setStartAndFinishWorkingTime('10:00', '18:00');
        testWeekDay.getWeekDayEntityMap().get(1).getStartTime();
        testWeekDay.getWeekDayEntityMap().get(1).getFinishTime();
        testWeekDay.getWeekDayEntityMap().get(1).getStartDatetime(Date.newInstance(1998, 3, 1));
        testWeekDay.getWeekDayEntityMap().get(1).getFinishDatetime(Date.newInstance(1998, 3, 1));
    }
}