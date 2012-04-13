/**
 *class using for getting appt details
*/
public class RemainingApptsHelper   
{
    private static final Id chinaSmartOppRecordTypeId = '0124000000099sY';
    private static List<String> leadToShowSchools 
    {
        get
        {
          	return getleadToShowSchools();
        }
    }
    
    public RemainingApptsHelper() {}
    
    //gets original schools which we defined
    public static List<String> getValidOriginalSchools()
    {
        return  leadToShowSchools;
    }
    
    //gets specified school is lead to show schools
    public static Boolean isLeadToShowSchool(String currentSchool)
    {
        for(String leadToShowSchool : leadToShowSchools)
        {
            if(leadToShowSchool == currentSchool)
            {
                return true;
            }
        }
        return false;
    }
    //gets schools which using the lead to show
    public static List<String> getValidSchools(List<String> schools)
    {
        for(Integer i = 0; i < schools.size(); i++)
        {
            Boolean isFound = false;
            for(String leadToShowSchool : leadToShowSchools)
            {
                if(schools[i] == leadToShowSchool)
                {
                    isFound = true;                 
                    break;
                }
            }
            if(!isFound)
            {
                schools.remove(i);
            }
        }
        return schools;
    }
    
    //gets remainingAppt count by specified school and scheduleDate
    public static Integer getRemainingApptCount(String school, Date scheduleDate)
    {
        Integer remainApptCount = 0;
        Integer usedApptCount = [select Count() from Opportunity where Location__c =:school and Reschedule_appt_Date__c =:scheduleDate and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt'];
        List<Appt_Max_target__c> targets = [select Max_target__c from Appt_Max_target__c where School__c =:school and Date__c =:scheduleDate order by CreatedDate desc limit 1];
        if(!targets.isEmpty() && targets[0].Max_target__c != null)
        {
            remainApptCount = targets[0].Max_target__c.intvalue() - usedApptCount;
        }
        return remainApptCount;
    }
    
    //gets app detail for a school and specified
    public static ApptDetailInfo2 getApptDetailBySchoolAndDate(String school, Date scheduleDate)
    {
        ApptDetailInfo2 result = new ApptDetailInfo2(school, scheduleDate, 0, 0);
        result.UsedApptCount = [select Count() from Opportunity where Location__c =:school and Reschedule_appt_Date__c =:scheduleDate and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt'];
        List<Appt_Max_target__c> targets = [select Max_target__c from Appt_Max_target__c where School__c =:school and Date__c =:scheduleDate limit 1];
        if(!targets.isEmpty() && targets[0].Max_target__c != null)
        {
            result.MaxApptCount = targets[0].Max_target__c.intValue();
            result.RemainingApptCount = result.MaxApptCount - result.UsedApptCount;
        }
        return result;
    }
    
    //gets appt detail for a school by some specified days  
    public static List<ApptDetailInfo2> getApptDetailsBySchool(String schoolName, Integer days)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        Map<Date, Integer> ApptDateMap = new Map<Date, Integer>();
        AggregateResult[] groupedResults = [select count(Id), Reschedule_appt_Date__c from Opportunity where Location__c = :schoolName and Reschedule_appt_Date__c >= :currentDay and Reschedule_appt_Date__c <= :currentDay.addDays(days) and Reschedule_appt_Date_Time__c >= :currentDay.addDays(-1) and Reschedule_appt_Date_Time__c <= :currentDay.addDays(days+1) and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c];
        for(AggregateResult res : groupedResults)
        {
             ApptDateMap.put((Date)res.get('Reschedule_appt_Date__c'),  (Integer)res.get('expr0'));     
        }
        List<Appt_Max_target__c> targets = [select Max_target__c, Date__c from Appt_Max_target__c where School__c =:schoolName and Date__c >= :currentDay and Date__c <= :currentDay.addDays(days) order by CreatedDate];
        for(Appt_Max_target__c target : targets)
        {
            Integer currentDateApptCount = ApptDateMap.get(target.Date__c);
            if(currentDateApptCount == null)
            {
                currentDateApptCount = 0;
            }
            else
            {
                ApptDateMap.remove(target.Date__c);
            }
            ApptDetailInfo2 result = new ApptDetailInfo2(schoolName, target.Date__c, target.Max_target__c.intvalue(), currentDateApptCount);
            results.add(result);
        }
        for(Date schoolDate : ApptDateMap.keyset())
        {
            Integer currentDateApptCount = ApptDateMap.get(schoolDate);
            ApptDetailInfo2 result = new ApptDetailInfo2(schoolName, schoolDate, 0, currentDateApptCount);
            results.add(result); 
        }
        results = SortList(results);
        return results;
    }
    
    //gets Appt detail for a specified city and days
    public static List<ApptDetailInfo2> getApptDetailsByCity(String city, Integer days)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        String cityParm = city + '%';
        List<AggregateResult> groupedResults = [select count(Id), Reschedule_appt_Date__c, Location__c from Opportunity where Location__c Like :cityParm and Location__c in :leadToShowSchools and Reschedule_appt_Date__c >= :currentDay and Reschedule_appt_Date__c <= :currentDay.addDays(days) and Reschedule_appt_Date_Time__c >= :currentDay.addDays(-1) and Reschedule_appt_Date_Time__c <= :currentDay.addDays(days+1) and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c, Location__c];
        List<Appt_Max_target__c> targets = [select Max_target__c, SchoolAndDate__c, Date__c, School__c from Appt_Max_target__c where City__c = :city and School__c in :leadToShowSchools and Date__c >= :currentDay and Date__c <= :currentDay.addDays(days) order by CreatedDate];
        Map<String, Appt_Max_target__c> schoolDateMap = new  Map<String, Appt_Max_target__c>();
        for(Appt_Max_target__c target : targets)
        {
           schoolDateMap.put(target.SchoolAndDate__c, target); 
        }
        results = getApptDetailsByAggregateResultAndTargets(groupedResults, schoolDateMap.values());
        return results;
    }
    
    //gets Appt detail for a specified city and days for testing
    public static List<ApptDetailInfo2> getApptDetailsByCityForTest(String city)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        String cityParm = city + '%';
        List<AggregateResult> groupedResults = [select count(Id), Reschedule_appt_Date__c, Location__c from Opportunity where Location__c Like :cityParm and Reschedule_appt_Date__c >= :currentDay and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c, Location__c limit 5];
        List<Appt_Max_target__c> targets = [select Max_target__c, SchoolAndDate__c, Date__c, School__c from Appt_Max_target__c where City__c = :city and Date__c >= :currentDay limit 5];
        Map<String, Appt_Max_target__c> schoolDateMap = new  Map<String, Appt_Max_target__c>();
        for(Appt_Max_target__c target : targets)
        {
           schoolDateMap.put(target.SchoolAndDate__c, target); 
        }
        results = getApptDetailsByAggregateResultAndTargets(groupedResults, schoolDateMap.values());
        return results;
    }
    
    //gets confirmed appt detail by some specified schools and days.
    public static List<ApptDetailInfo2> getConfirmedApptDetailsBySchools(List<String> schools, Integer days)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        List<AggregateResult> groupedResults = [select count(Id), Reschedule_appt_Date__c, Location__c from Opportunity where Check_confirmation__c = true and  Location__c in :schools and Reschedule_appt_Date__c >= :currentDay and Reschedule_appt_Date__c <= :currentDay.addDays(days)and Reschedule_appt_Date_Time__c >= :currentDay.addDays(-1) and Reschedule_appt_Date_Time__c <= :currentDay.addDays(days+1) and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c, Location__c];
        List<Appt_Max_target__c> targets = [select Max_target__c, Date__c, SchoolAndDate__c, School__c from Appt_Max_target__c where School__c in :schools and Date__c >= :currentDay and Date__c <= :currentDay.addDays(days) order by CreatedDate];
        Map<String, Appt_Max_target__c> schoolDateMap = new  Map<String, Appt_Max_target__c>();
        for(Appt_Max_target__c target : targets)
        {
          schoolDateMap.put(target.SchoolAndDate__c, target); 
        }
        results = getApptDetailsByAggregateResultAndTargets(groupedResults, schoolDateMap.values());
        return results;
    }
    
        //gets appt detail by some specified schools and days.
    public static List<ApptDetailInfo2> getApptDetailsBySchools(List<String> schools, Integer days)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        List<AggregateResult> groupedResults = [select count(Id), Reschedule_appt_Date__c, Location__c from Opportunity where Location__c in :schools and Reschedule_appt_Date__c >= :currentDay and Reschedule_appt_Date__c <= :currentDay.addDays(days) and Reschedule_appt_Date_Time__c >= :currentDay.addDays(-1) and Reschedule_appt_Date_Time__c <= :currentDay.addDays(days+1) and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c, Location__c];
        List<Appt_Max_target__c> targets = [select Max_target__c, Date__c, SchoolAndDate__c, School__c from Appt_Max_target__c where School__c in :schools and Date__c >= :currentDay and Date__c <= :currentDay.addDays(days) order by CreatedDate];
        Map<String, Appt_Max_target__c> schoolDateMap = new  Map<String, Appt_Max_target__c>();
        for(Appt_Max_target__c target : targets)
        {
          schoolDateMap.put(target.SchoolAndDate__c, target);
        }
        results = getApptDetailsByAggregateResultAndTargets(groupedResults, schoolDateMap.values());
        return results;
    }
    
    //gets appt detail by some specified schools and days.for test method
    public static List<ApptDetailInfo2> getApptDetailsBySchoolsForTest(List<String> schools, Integer days)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Date currentDay = Date.today();
        List<AggregateResult> groupedResults = [select count(Id), Reschedule_appt_Date__c, Location__c from Opportunity where Location__c in :schools and Reschedule_appt_Date__c >= :currentDay and Reschedule_appt_Date__c <= :currentDay.addDays(days) and Reschedule_appt_Date_Time__c >= :currentDay.addDays(-1) and Reschedule_appt_Date_Time__c <= :currentDay.addDays(days+1) and RecordTypeId = :chinaSmartOppRecordTypeId and StageName = 'Set Appt' group by Reschedule_appt_Date__c, Location__c limit 100];
        List<Appt_Max_target__c> targets = [select Max_target__c, Date__c, SchoolAndDate__c, School__c from Appt_Max_target__c where School__c in :schools and Date__c >= :currentDay and Date__c <= :currentDay.addDays(days) order by CreatedDate];
        Map<String, Appt_Max_target__c> schoolDateMap = new  Map<String, Appt_Max_target__c>();
        for(Appt_Max_target__c target : targets)
        {
          schoolDateMap.put(target.SchoolAndDate__c, target);
        }
        results = getApptDetailsByAggregateResultAndTargets(groupedResults, schoolDateMap.values());
        return results;
    }
    
    //get Appt Detail by a group of ApptDetailInfo2s,group by these appts by school
    public static map<String, List<ApptDetailInfo2>> getSchoolApptDetailsMap(List<ApptDetailInfo2> items)
    {
        map<String, List<ApptDetailInfo2>> results = new map<String, List<ApptDetailInfo2>>();
        for(ApptDetailInfo2 item : items)
        {
            if(results.containsKey(item.SchoolName))
            {
                List<ApptDetailInfo2> subItems = results.get(item.SchoolName);
                subItems.add(item);
            }
            else
            {
                List<ApptDetailInfo2> subItems = new List<ApptDetailInfo2>();
                subItems.add(item);
                results.put(item.SchoolName, subItems);
            }
        }
        for(String school : results.keyset())
        {
            List<ApptDetailInfo2> details = results.get(school);
            details = SortList(details);
        }
        return results;
    }
    //gets hourly capping cunt detail
    public static map<Integer, Integer> getHourlyCountMap(String school, Date scheduleDate)
    {
      	map<Integer, Integer> hourlyMap = new map<Integer, Integer>();
      	List<Opportunity> items = [select Reschedule_appt_Date_Time__c  from Opportunity where Location__c = :school and Reschedule_appt_Date__c = :scheduleDate and Check_confirmation__c = true and StageName = 'Set Appt' and RecordTypeId = :chinaSmartOppRecordTypeId order by Reschedule_appt_Date_Time__c];
      	for(Opportunity item : items)
      	{
        	if(item.Reschedule_appt_Date_Time__c != null)
        	{
          		if(hourlyMap.containsKey(item.Reschedule_appt_Date_Time__c.hour()))
          		{
            		Integer currentCount = hourlyMap.get(item.Reschedule_appt_Date_Time__c.hour());
            		currentCount++;
					hourlyMap.put(item.Reschedule_appt_Date_Time__c.hour(), currentCount);
          		}
          		else
          		{
            		hourlyMap.put(item.Reschedule_appt_Date_Time__c.hour(), 1);
          		}
        	}       
      	}
      	return hourlyMap;
    }
    
    //gets hourly capping detail map by a school and a date,key:hour,value:max targets
    public static map<Integer, Integer> getHourlyTotalMap(String school, Date scheduleDate)
    {
      	map<Integer, Integer> hourlyMap = new map<Integer, Integer>();
      	List<China_Appointment_Max_target_detail__c> details = [select School__c, Time__c, Date__c, Max_target__c from China_Appointment_Max_target_detail__c where School__c =:school and Date__c =:scheduleDate];
      	for(China_Appointment_Max_target_detail__c detail : details)
      	{
        	if(detail.Time__c != null && detail.Max_target__c != null)
	        {
	          	hourlyMap.put(detail.Time__c.hour(), detail.Max_target__c.round().intValue());
	        }       
      	}
      	return hourlyMap;
    }
    
    //gets remianing appt count by hourly with specified school and date
    public static Integer getRemianingApptByHourly(Opportunity currentOpp)
    {
      	Integer currentHour = currentOpp.Reschedule_appt_Date_Time__c.hour();
      	map<Integer, Integer> hourlyCountMap = getHourlyCountMap(currentOpp.Location__c, currentOpp.Reschedule_appt_Date__c);
      	map<Integer, Integer> hourlyTotalMap = getHourlyTotalMap(currentOpp.Location__c, currentOpp.Reschedule_appt_Date__c);
      	if(hourlyTotalMap.get(currentHour) != null)
      	{
        	if(hourlyCountMap.get(currentHour) != null)
	        {
	          	return hourlyTotalMap.get(currentHour) - hourlyCountMap.get(currentHour);
	        }
        	return hourlyTotalMap.get(currentHour);
      	}
      	return 0;
    }
    
    //gets Appt detail by specified AggregateResult[] and targets
    private static List<ApptDetailInfo2> getApptDetailsByAggregateResultAndTargets(List<AggregateResult> groupedResults, List<Appt_Max_target__c> targets)
    {
        List<ApptDetailInfo2> results = new List<ApptDetailInfo2>();
        Map<String, Integer> ApptSchoolDateMap = new Map<String, Integer>();
        for(AggregateResult res : groupedResults)
        {
            Date currentScheduleDate = (Date)res.get('Reschedule_appt_Date__c');
            String year = String.valueof(currentScheduleDate.year());
            String month = (currentScheduleDate.month() >= 10)?(String.valueof((currentScheduleDate.month()))):('0' + String.valueOf(currentScheduleDate.month()));
            String day = (currentScheduleDate.day() >= 10)?(String.valueof((currentScheduleDate.day()))):('0' + String.valueOf(currentScheduleDate.day()));
            String tag = (String)res.get('Location__c') + year + '-' + month + '-' + day;
            Integer appCount = (Integer)res.get('expr0');
            ApptSchoolDateMap.put(tag, appCount);     
        }
        for(Appt_Max_target__c target : targets)
        {
            Integer currentDateApptCount = ApptSchoolDateMap.get(target.SchoolAndDate__c);
            if(currentDateApptCount == null)
            {
                currentDateApptCount = 0;
            }
            else
            {
                ApptSchoolDateMap.remove(target.SchoolAndDate__c);
            }
            ApptDetailInfo2 result = new ApptDetailInfo2(target.School__c, target.Date__c, target.Max_target__c.intvalue(), currentDateApptCount);
            results.add(result);        
        }
        for(String schoolDate : ApptSchoolDateMap.keyset())
        {
            Integer currentDateApptCount = ApptSchoolDateMap.get(schoolDate);
            String currentSchool = schoolDate.substring(0, (schoolDate.length() - 10));
            Date currentDate = date.valueof(schoolDate.substring(schoolDate.length() - 10));
            ApptDetailInfo2 result = new ApptDetailInfo2(currentSchool, currentDate, 0, currentDateApptCount);
            results.add(result); 
        }
        return results;
    }
    
    public static List<ApptDetailInfo2> CompleteList(List<ApptDetailInfo2> items, Integer days)
    {
        map<Date, ApptDetailInfo2> dateApptMap = new map<Date, ApptDetailInfo2>();
        for(ApptDetailInfo2 item : items)
        {
            dateApptMap.put(item.ScheduleDate, item);
        }
        for(Integer i = 0; i <= days; i++)
        {
            if(dateApptMap.get(Date.today().addDays(i)) == null)
            {
                items.add(new ApptDetailInfo2(items[0].SchoolName, Date.today().addDays(i), 0, 0));
            }
        }
        return SortList(items);
    }
    
    //gets all lead to show schools
    private static List<String> getleadToShowSchools()
    {
        List<String> allLeadToShowSchools = new List<String>();
        List<SchoolAddress__c> LTSchools = [select Name from SchoolAddress__c where IsLeadToShowSchool__c = true];
        for(SchoolAddress__c LTSchool : LTSchools)
        {
          allLeadToShowSchools.add(LTSchool.Name.replace('_', ' '));
        }
        return allLeadToShowSchools;
    }
    
    //sorts List<ApptDetailInfo2> by ScheduleDate
    private static List<ApptDetailInfo2> SortList(List<ApptDetailInfo2> items)
    {
        Integer i, j;
        ApptDetailInfo2 temp;    
        Boolean done = false;    
        j = 1;    
        while ((j < items.size()) && (!done))  
        {    
            done = true;    
            for (i = 0; i < items.size() - j; i++)    
            {    
                if (items[i].ScheduleDate > items[i + 1].ScheduleDate)    
                {    
                    done = false;    
                    temp = items[i];    
                    items[i] = items[i + 1];
                    items[i + 1] = temp;    
                }    
            }    
            j++;    
        }  
        return items;
    }
   //an entity class for appt detail of a school as a specified date.
    public class ApptDetailInfo2 
    {
      	public ApptDetailInfo2(String schoolName, Date scheduleDate, Integer maxApptCount, Integer usedApptCount)
      	{
        	this.SchoolName = schoolName;
	        this.ScheduleDate = scheduleDate;
	        this.MaxApptCount = maxApptCount;
	        this.UsedApptCount = usedApptCount;
	        this.RemainingApptCount = maxApptCount - usedApptCount;
      	}
      	public String SchoolName {get; set;}
      	public Date ScheduleDate {get; set;}
      	public Integer MaxApptCount {get; set;}
      	public Integer UsedApptCount {get; set;}
      	public Integer RemainingApptCount {get; set;}
    }
    
    @isTest
    static void testClass()
    {
      	Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
      	List<Opportunity> testOpportunites = new List<Opportunity>();
      	Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
	    testOpportunites.add(testOpportunity1);
      	Opportunity testOpportunity2 = new Opportunity(name = 'acme', location__c = 'SH LJZ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
      	testOpportunites.add(testOpportunity2);
      	Opportunity testOpportunity3 = new Opportunity(name = 'acme', location__c = 'SH BBB', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, Check_confirmation__c = true, CloseDate = date.today());
      	testOpportunites.add(testOpportunity3);
      	insert testOpportunites;
      	List<Appt_Max_target__c> testTargets = new List<Appt_Max_target__c>();
      	Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
      	testTargets.add(testTarget1);
	    Appt_Max_target__c testTarget2 = new Appt_Max_target__c(Max_target__c = 1, School__c = 'SH LJZ', Date__c = date.today());
      	testTargets.add(testTarget2);
      	Appt_Max_target__c testTarget3 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH BBB', Date__c = date.today());
      	testTargets.add(testTarget3);
      	insert testTargets;
      	RemainingApptsHelper helper = new RemainingApptsHelper();
      	Boolean isLeadToShowSchool = RemainingApptsHelper.isLeadToShowSchool('SH PSQ');
      	system.assert(isLeadToShowSchool);
      	List<String> schools = RemainingApptsHelper.getValidOriginalSchools();
      	system.assert(schools != null);
      	List<String> testSchools = new List<String>{'aaa', 'SH LJZ'};
      	List<String> validSchools = RemainingApptsHelper.getValidSchools(testSchools);
      	system.assert(validSchools != null);
      	RemainingApptsHelper.ApptDetailInfo2 results1 = RemainingApptsHelper.getApptDetailBySchoolAndDate('SH PSQ', date.today());
      	system.assert(results1 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results2 = RemainingApptsHelper.getApptDetailsBySchools(new List<String>{'SH PSQ', 'SH LJZ'}, 7);
      	system.assert(results2 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results3 = RemainingApptsHelper.getConfirmedApptDetailsBySchools(new List<String>{'SH PSQ', 'SH BBB'}, 7);
      	system.assert(results3 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results4 = RemainingApptsHelper.getApptDetailsBySchool('SH PSQ', 7);
      	system.assert(results4 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results5 = RemainingApptsHelper.getApptDetailsByCity('SH', 7);
      	system.assert(results5 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results6 = RemainingApptsHelper.CompleteList(results5, 7);
      	system.assert(results6 != null);
      	List<RemainingApptsHelper.ApptDetailInfo2> results7 = RemainingApptsHelper.getApptDetailsBySchoolsForTest(new List<String>{'SH PSQ', 'SH LJZ'}, 7);
      	system.assert(results7 != null);
      	map<String, List<RemainingApptsHelper.ApptDetailInfo2>> schoolApptmap = RemainingApptsHelper.getSchoolApptDetailsMap(results2);
      	system.debug(schoolApptmap.get('SH PSQ') != null);
      	Map<Integer, Integer> hourMap = RemainingApptsHelper.getHourlyCountMap('SH LJZ', date.today());
      	system.debug(hourMap != null);
      	Map<Integer, Integer> hourMap2 = RemainingApptsHelper.getHourlyTotalMap('SH BBB', date.today());
      	system.debug(hourMap2 != null);
      	Integer remainingAppt = RemainingApptsHelper.getRemainingApptCount('SH PSQ', date.today());
      	Integer remainingApptHourly = RemainingApptsHelper.getRemianingApptByHourly(testOpportunity1);
      	system.assert(remainingApptHourly >= 0);
    }
}