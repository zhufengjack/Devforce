/*
    Controller for RSDWorkCalendar.
*/
public class RSDWorkCalendarController 
{
    public String SelectSchoolName { get; set; }
    public String HolidayDateString { get; set; }
    private Id dayOnEmailTemplateId; // = '00XO0000000LxhZ';
    private Id dayOffEmailTemplateId; // = '00XO0000000Lxd3';

    private static Id accountRecordTypeId 
    {
        get 
        { 
             List<RecordType> b2bAccountRecordTypes = [select Id, Name from RecordType where Name = 'China Smart B2B record type' and SobjectType = 'Account']; 
            if(b2bAccountRecordTypes.size() > 0)
            {
                return b2bAccountRecordTypes[0].Id;
            }
            return null;
        }
    }
    
    public RSDWorkCalendarController()
    {
        dayOnEmailTemplateId = [select Id from EmailTemplate where Name = 'Please be noted that this center has all CC on duty!' limit 1].Id;
        dayOffEmailTemplateId = [select Id from EmailTemplate where Name = 'Please be noted that this center has no CC on duty!' limit 1].Id;
    }
    
    public List<SelectOption> getSchoolList()
    {
        List<SelectOption> options = new List<SelectOption>();
        List<User> users = [select Id, Name, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
        String roleName;
        String profileName;
        if(users.size() > 0)
        {
            roleName = users[0].UserRole.Name;
            profileName = users[0].Profile.Name;
            profileName = profileName.toLowerCase();
        }
        
        List<SchoolAndManager__c> schoolAndManagerList;
        if(profileName.contains('system administrator'))
        {
            schoolAndManagerList = [select Id, Name, ManagerRole__c, ManagerRole2__c from SchoolAndManager__c order by Name asc];
        }
        else  if(profileName == 'EF China Regional Sales Director')
        {   
        	    schoolAndManagerList = [select Id, Name, ManagerRole__c, ManagerRole2__c from SchoolAndManager__c where (ManagerRole__c = :roleName and ManagerRole__c != null) or (ManagerRole2__c = :roleName and ManagerRole2__c != null) order by Name asc];
        }
        
        if(schoolAndManagerList != null && schoolAndManagerList.size() > 0)
        {
            for(SchoolAndManager__c schoolAndManager : schoolAndManagerList)
	        {
	            options.add(new SelectOption(schoolAndManager.Name, schoolAndManager.Name));   
	        }
        }
        return options;
    }
    
    public void save()
    {
        if(HolidayDateString != null && HolidayDateString != '')
        {
            List<String> holidayStringSplitList = HolidayDateString.split(':');
            if(holidayStringSplitList.size() > 0)
            {
                String yearString = holidayStringSplitList[0].replace('Year=', '');
                String monthString = holidayStringSplitList[1].replace('Month=', '');
                String currentDateString = holidayStringSplitList[2];
                List<String> currentDateList = currentDateString.split('/');
                Date limitDate = generateLimitDate(currentDateList);
                holidayStringSplitList.remove(2);
                holidayStringSplitList.remove(1);
                holidayStringSplitList.remove(0);
                Integer year = Integer.valueOf(yearString);
                Integer month = Integer.valueOf(monthString);
                Set<Integer> holidays = new Set<Integer>();
                for(String day : holidayStringSplitList)
                {
                    holidays.add(Integer.valueOf(day));
                }
                List<Id> emailReceivers = generateEmailUserList();
                Set<Integer> oldHolidayDates =  processOldHolidays(year, month, holidays, emailReceivers, limitDate);
                processNewHolidays(year, month, holidays, emailReceivers, limitDate, oldHolidayDates);
            }
        }
        // Year=2010:Month=12:1:2:3:9:16
    }
    
    private Set<Integer> processOldHolidays(Integer yearValue, Integer monthValue, Set<Integer> newHolidaySet, List<Id> receivers, Date limitDate)
    {
        List<Date> deletedHolidays = new List<Date>();
        List<Holiday> deletedList = new List<Holiday>();
        String holidayName = 'Smart Day Off ' + SelectSchoolName;
        Date startDate = generateStartDate(yearValue, monthValue);
        Date endDate = generateEndDate(yearValue, monthValue);
        Set<Integer> oldHolidayDates = new Set<Integer>();
        List<Holiday> holidays = [select Id, Name, ActivityDate from Holiday where Name = :holidayName and ActivityDate >= :startDate and ActivityDate < :endDate and ActivityDate >= :limitDate];
        for(Holiday holiday : holidays)
        {
            Integer tempDay = holiday.ActivityDate.day();
            oldHolidayDates.add(tempDay);
            if(!newHolidaySet.contains(tempDay))
            {
                deletedHolidays.add(holiday.ActivityDate);
                deletedList.add(holiday);
            }
        }
        // send email.
        if(deletedHolidays.size() > 0)
        {
            sendEmailToUser(deletedHolidays, receivers, dayOnEmailTemplateId, SelectSchoolName, 'On Duty');
        }
        delete deletedList;
        return oldHolidayDates;
    }
    
    private void processNewHolidays(Integer yearValue, Integer monthValue, Set<Integer> newHolidaySet, List<Id> receivers, Date limitDate, Set<Integer> oldHolidayDates)
    {
        List<Holiday> newHolidays = new List<Holiday>();
        List<Date> newHolidayDates = new List<Date>();
        for(Integer day : newHolidaySet)
        {
            String holidayName = 'Smart Day Off ' + SelectSchoolName;
            Date holidayActivityDate =  Date.newInstance(yearValue, monthValue, day);
            if(holidayActivityDate >= limitDate && !oldHolidayDates.contains(day))
            {
                Holiday newHoliday = new Holiday(Name = holidayName, ActivityDate = holidayActivityDate);
                newHolidays.add(newHoliday);
                newHolidayDates.add(newHoliday.ActivityDate);
            }
        }
        List<Id> tempObjectIds = new List<Id>();
        if(newHolidays.size() > 0)
        {
            insert newHolidays;
            sendEmailToUser(newHolidayDates, receivers, dayOffEmailTemplateId, SelectSchoolName, 'Day Off'); // send email
        }
    }
    
    private Date generateStartDate(Integer yearValue, Integer monthValue)
    {
        if(yearValue != null && monthValue != null)
        {
            return date.newInstance(yearValue, monthValue, 1);
        }
        return null;
    }
    
    private Date generateEndDate(Integer yearValue, Integer monthValue)
    {
        if(yearValue != null && monthValue != null)
        {
            yearValue = (monthValue == 12) ? (yearValue + 1) : yearValue;
            monthValue = (monthValue == 12) ? 1 : (monthValue + 1) ;
            return date.newInstance(yearValue, monthValue, 1);
        }
        return null;
    }
    
    private Date generateLimitDate(List<String> dateList)
    {
        Date resultDate = Date.newInstance(Integer.valueOf(dateList[0]), Integer.valueOf(dateList[1]), Integer.valueOf(dateList[2]));
        resultDate = resultDate.addDays(14);
        return resultDate;
    }
    
    private List<Id> generateEmailUserList()
    {
        List<User> users;
        List<Id> userIds = new List<Id>();
        if(SelectSchoolName != null && SelectSchoolName != '')
        {
        	    SchoolAndManager__c schoolAndManager = SchoolAndManager__c.getInstance(SelectSchoolName); 
        	    if(schoolAndManager != null)
        	    {
	        	    String schoolName = SelectSchoolName.replace(' ', '_');
	            String salesManagerRoleName = 'China ' + schoolName + ' Sales Manager';
	            String rsdManagerRoleName = schoolAndManager.ManagerRole__c;//ManagerRole__c, ManagerRole2__c
	            String rsdRegionManagerRoleName = schoolAndManager.ManagerRole2__c;
	        	    Users = [select Id, Email, Profile.Name, UserRole.Name from User where ((Profile.Name = 'EF China Telemarketing Manager' and UserRole.Name = 'China Telemarketing Manager') or (Profile.Name = 'EF China Smart CSO manager' and UserRole.Name = 'China Sales Director') or (Profile.Name = 'EF China Sales Manager new' and UserRole.Name = :salesManagerRoleName) or (Profile.Name = 'EF China Regional Sales Director' and UserRole.Name = :rsdManagerRoleName and UserRole.Name != null) or (Profile.Name = 'EF China Regional Sales Director' and UserRole.Name = :rsdRegionManagerRoleName and UserRole.Name != null)) and IsActive = true];
        	    }
        }
       
        if(users != null && users.size() > 0)
        { 
            for(User user : users)
            {
                userIds.add(user.Id);
            }
        }
        return userIds;
    }
    
    private static void updateSalesMonthlyDetail(List<Date> changeDates, String changeStatus, String changeSchool)
    { 
        if(changeSchool != null && changeSchool != '' && changeDates != null )
        {  
            List<Sales_Monthly_Details__c> details = [select Id, School__c, Day_Status__c from Sales_Monthly_Details__c where Date__c in :changeDates and School__c = :changeSchool];
            for(Sales_Monthly_Details__c detail : details)
            {
                detail.Day_Status__c = changeStatus;
            }
            update details;
        }
    }
    
    @future
    private static void sendEmailToUser(List<Date> holidays, List<Id> receivers, Id templateId, String saleUserSchoolName, String status)
    {
        if(holidays != null && holidays.size() > 0 && receivers != null && receivers.size() > 0) 
        {
            // Creates contact.
            try{
	            String userSchoolName = saleUserSchoolName.replace(' ', '_');
	            updateSalesMonthlyDetail(holidays, status, userSchoolName);
	            User saleUser = [select Id from User where SchoolName__c = :userSchoolName and IsActive = true limit 1];
	            Account tempAccount = new Account(Name = 'temp account', RecordTypeId = accountRecordTypeId);
	            insert tempAccount;
	            List<Contact> contacts = new List<Contact>();
	            List<User> userList = [select Id, Name, Email from User where Id in :receivers];
	            for(User user : userList)
	            {
	                contacts.add(new Contact(LastName = 'temp contact', AccountId = tempAccount.Id, Email = user.Email));
	            }
	            insert contacts;
	            
	            // Creates China Sma Sales Monthly Schedule Details.
	            Sales_Month_Summary__c monthSummary = new Sales_Month_Summary__c(Date__c = Date.today());           
	            insert monthSummary;
	            List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
	            for(Date holiday : holidays)
	            {
	                monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Monthly_Schedule_Summary__c = monthSummary.Id, Date__c = holiday, Sales_Consultant__c = saleUser.Id));
	            }
	            insert monthlyDetails;
	            
	            List<Messaging.Singleemailmessage> mails = new List<Messaging.Singleemailmessage>();
	            for(Sales_Monthly_Details__c monthDetail : monthlyDetails)
	            {
	                for(Contact contact : contacts)
	                {
	                    Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
	                    mail.setTargetObjectId(contact.Id);
	                    mail.setWhatId(monthDetail.Id);
	                    mail.setTemplateId(templateId);
	                    mail.setSaveAsActivity(false);
	                    mails.add(mail);
	                }
	            }
	            Messaging.sendEmail(mails);
	            // Delete temp data.
	            delete monthSummary;
	            delete contacts;
	            delete tempAccount;
            }
            catch(Exception ex){}

        }
    }
    
    @isTest
    static void testRSDWorkCalendarController()
    {
        RSDWorkCalendarController testController = new RSDWorkCalendarController();
        testController.getSchoolList();
        String testDateString = 'Year=2010:Month=11:2010/11/1:4:21:25:27';
        testController.HolidayDateString = testDateString;
        testController.SelectSchoolName = 'BJ DWL';
        testController.save();
    }
    @isTest
    static void testSendEmail()
    { //sendEmailToUser(List<Date> holidays, List<Id> receivers, Id templateId)
        // dayOffEmailTemplateId
        RSDWorkCalendarController con = new RSDWorkCalendarController();
        List<Date> testDateList = new List<Date>();
        Date currentDate = Date.today();
        testDateList.add(currentDate.addDays(1));
        testDateList.add(currentDate.addDays(2));
        testDateList.add(currentDate.addDays(3));
        List<User> userList = [select Id from User where IsActive = true limit 3];
        List<Id> receiveIds = new List<Id>();
        for(User user : userList)
        {
            receiveIds.add(user.Id);
        }
        RSDWorkCalendarController.sendEmailToUser(testDateList, receiveIds, con.dayOffEmailTemplateId, 'BJ DWL', 'Day Off');
    }
}