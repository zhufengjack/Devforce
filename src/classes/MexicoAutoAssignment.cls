/*
*   Auto assignment for mexico.
*/ 
public class MexicoAutoAssignment extends AutoAssignmentBase
{
    // Override method createEventAndReport.
    public void createEventAndReport(String userId, Opportunity opp)
    {
        if(userId != null && opp != null)
        {
            List<RecordType> recordTypes = [select Id from RecordType where Name = 'Telesales Meeting'];
            List<User> users = [select Id, UserRole.Name from User where Id=:opp.OwnerId];
            String roleName = (users.size() > 0) ? users[0].UserRole.Name : null;
            // Create event.
            Event newEvent = new Event();
            newEvent.DurationInMinutes = 15;
            if(opp.Initial_Appt_Date__c != null)
            { 
                newEvent.ActivityDateTime = opp.Initial_Appt_Date__c;
                newEvent.ActivityDate = date.newInstance(opp.Initial_Appt_Date__c.year(), opp.Initial_Appt_Date__c.month(), opp.Initial_Appt_Date__c.day());
            }
            newEvent.OwnerId = userId;
            newEvent.WhatId = opp.Id;
            newEvent.Subject = 'Sales Demo (1)';
            newevent.IsReminderSet=true;
            newEvent.ReminderDateTime=newEvent.ActivityDateTime.addMinutes(-5);
            newEvent.RecordTypeId = (recordTypes.size() > 0) ? recordTypes[0].Id : null;
            insert newEvent;
            // Create assignment report.
            China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
            report.Appointment_DateTime__c = newEvent.ActivityDateTime;
            report.Appointment_Date__c = newEvent.ActivityDate;
            report.Assignment_Time__c = DateTime.now();
            report.Opportunity__c = opp.Id;
            report.Sales_Consultant__c = userId;
            if(opp.RecordType.Name == 'US Sales Record Type')
            {
                report.Assignment_Org__c = 'US'; 
            }
            else
            {
                report.Assignment_Org__c = 'Mexico';
            }
            report.School__c = roleName;
            report.OwnerId = userId;
            insert report;
        }
    }   
     
    // Override method autoAssignUser.
    public String autoAssignUser(Opportunity opp)
    {
        String resultUserId;
        if(opp != null)
        {
            set<String> userGroup = getCurrentUserGroup(opp); // Get all user that location 
            Datetime assignDatetime = opp.Initial_Appt_Date__c;
            Map<String, Double> userToAllocation = getUserAllocation(userGroup, assignDatetime);
            resultUserId = handleAssignment(userToAllocation, assignDatetime, userGroup);
            if(resultUserId != null)
            {
                //Change queue status.
                changeQueueStatus(opp.Id);
            }
            else
            {
                // Create a new queue. 
                createQueue(opp, 'Mexico', 'Assignment Failure by webservice'); 
                throw new NoSaleUserException('No user has been assigned, the opportunity has been added to queue.');
            }
        }
        return resultUserId;
    }
     
    // Implements method calculateReportCount. 
   public List<Integer> calculateReportCount(Map<String, CountInfo> salesCountMap, Datetime assignDatetime, Set<String> ondutyUserIds, Set<String> allUserIds)
    {
            if(salesCountMap != null && assignDatetime != null && ondutyUserIds != null && allUserIds != null)
            {
            String year = String.valueOf(assignDatetime.year());
            String month = String.valueOf(assignDatetime.month());
            String day = String.valueOf(assignDatetime.day());
            
            Datetime startDateTime;
            Datetime endDateTime;

            Time currentOpportunityTime = assignDatetime.time();
            if(currentOpportunityTime >= Time.newInstance(9, 0, 0, 0) && currentOpportunityTime < Time.newInstance(15, 0, 0, 0))
            {// 9am to 15pm.
                startDateTime = Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 9, 0, 0);
                endDateTime = Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 15, 0, 0);
            }
            else if(currentOpportunityTime >= Time.newInstance(15, 0, 0, 0) && currentOpportunityTime < Time.newInstance(16, 30, 0, 0))
            {//15pm to 16:30pm
                startDateTime = Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 15, 0, 0);
                endDateTime = Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 16, 30, 0);
            }
            else if(currentOpportunityTime >= Time.newInstance(16, 30, 0, 0) && currentOpportunityTime < Time.newInstance(22, 0, 0, 0))
            {//16:30pm to 22pm
                startDateTime = Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 16, 30, 0);
                endDateTime =  Datetime.newInstance(assignDatetime.year(), assignDatetime.month(), assignDatetime.day(), 22, 0, 0);
            }
            
            List<Integer> totalReportCountList = new List<Integer>();

            Integer dailyCount = 0; // 当天总计.
            Integer monthlyCount = 0; // 本月总计.
            
            for(China_Appt_Assignment_Report__c assignReport : [select Id, Lead_Source__c, Day__c, Sales_Consultant__c, Appointment_DateTime__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :allUserIds and Year__c =:year and Month__c =:month and (Assignment_Org__c = 'Mexico' or Assignment_Org__c = 'US') order by Sales_Consultant__c])
            {
                monthlyCount++;
                if(assignDatetime >= startDateTime && assignDatetime < endDateTime)
                {
                    dailyCount++;
                }
                calculateReportCountForOndutySale(salesCountMap, ondutyUserIds, assignReport, startDatetime, endDatetime);
            } 
            totalReportCountList.add(dailyCount);
            totalReportCountList.add(monthlyCount);
            return totalReportCountList;
            }
            return null;
    }
     
    // Overload method 
    public void calculateReportCountForOndutySale(Map<String, CountInfo> salesCountMap, Set<String> ondutyUserIds, China_Appt_Assignment_Report__c assignReport, Datetime startDatetime, Datetime endDatetime)
    {
            if(salesCountMap != null && ondutyUserIds != null && assignReport != null && startDatetime != null && endDatetime != null)
            {
            if(ondutyUserIds.contains(assignReport.Sales_Consultant__c))
            {
                if(salesCountMap.containsKey(assignReport.Sales_Consultant__c))
                { // If the sales data has been exit in map.
                    CountInfo tempCountInfo = salesCountMap.get(assignReport.Sales_Consultant__c);
                    tempCountInfo.monthlyCount++;
                    if(startDatetime <= assignReport.Appointment_DateTime__c && assignReport.Appointment_DateTime__c < endDatetime)
                    {
                        tempCountInfo.dailyCount++;
                    }
                }
                else
                {
                    countInfo newCountInfo = new CountInfo();
                    newCountInfo.userId = assignReport.Sales_Consultant__c;
                    newCountInfo.monthlyCount++;
                    if(startDatetime <= assignReport.Appointment_DateTime__c && assignReport.Appointment_DateTime__c < endDatetime)
                    {
                        newCountInfo.dailyCount++;
                    }
                    salesCountMap.put(assignReport.Sales_Consultant__c, newCountInfo);
                }
            }
            }
    }
    
    // Gets all users for Mexico.
    public override Map<String, Double> getUserAllocation(Set<String> userIds, Datetime assignDatetime)
    {
        if(userIds != null && assignDatetime != null)
        {
            String strYear = String.valueOf(assignDatetime.year());
            String strMonth = String.valueOf(assignDatetime.month());
            String strDay = String.valueOf(assignDatetime.day());
            
            List<Sales_Monthly_Details__c> salesMonthlyDetails = new List<Sales_Monthly_Details__c>();
            Time currentOpportunityTime = assignDatetime.time();
            if(currentOpportunityTime >= Time.newInstance(9, 0, 0, 0) && currentOpportunityTime < Time.newInstance(15, 0, 0, 0))
            { // 9am to 15pm.
                salesMonthlyDetails  = [select Sales_Consultant__c, Sales_Consultant__r.Alias from Sales_Monthly_Details__c where Year__c=:strYear and Month__c =:strMonth and day__c=:strDay and Day_Status__c='Morning Duty' and Sales_Consultant__c in :userIds and Sales_Consultant__r.IsActive = true];
            }
            else if(currentOpportunityTime >= Time.newInstance(15, 0, 0, 0) && currentOpportunityTime < Time.newInstance(16, 30, 0, 0))
            { //15pm to 16:30pm
                salesMonthlyDetails  = [select Sales_Consultant__c, Sales_Consultant__r.Alias from Sales_Monthly_Details__c where Year__c=:strYear and Month__c =:strMonth and day__c=:strDay and (Day_Status__c = 'Morning Duty' or Day_Status__c = 'Evening Duty') and Sales_Consultant__c in :userIds and Sales_Consultant__r.IsActive = true];
            }
            else if(currentOpportunityTime >= Time.newInstance(16, 30, 0, 0) && currentOpportunityTime < Time.newInstance(22, 0, 0, 0))
            { //16:30pm to 22pm
                salesMonthlyDetails  = [select Sales_Consultant__c, Sales_Consultant__r.Alias from Sales_Monthly_Details__c where Year__c=:strYear and Month__c =:strMonth and day__c=:strDay and Day_Status__c = 'Evening Duty' and Sales_Consultant__c in :userIds and Sales_Consultant__r.IsActive = true];
            }

            Set<String> ondutyUserIds = new Set<String>();
            for(Sales_Monthly_Details__c detail : salesMonthlyDetails)
            {
                ondutyUserIds.add(detail.Sales_Consultant__c);
            }
            // Select current month allocation(on duty sales).
            Map<String, Double> resultMap = new Map<String, Double>();
            List<Sales_Team_Appointment_Allocation__c> currentMonthAllocations = [select Allocation__c, Sales_consultant__c, School__c from Sales_Team_Appointment_Allocation__c where Year__c =:strYear and Month__c =:strMonth and Allocation__c != 'undefined'and Sales_consultant__c in :ondutyUserIds order by LastModifiedDate DESC];
            for(Sales_Team_Appointment_Allocation__c allocation : currentMonthAllocations)
            {
                if(allocation.Allocation__c != null && allocation.Allocation__c != 'undefined')
                {
                    String tempAllocation = allocation.Allocation__c.replace('%','');
                    resultMap.put(allocation.Sales_consultant__c, Double.valueOf(tempAllocation)/100);
                }
            }
            return resultMap;
        }
        return null;
    }
    
    
    // Override method getCurrentUserGroup.
    public Set<String> getCurrentUserGroup(Opportunity currentOpportunity)
    {
        Set<String> resultUserIds = new Set<String>(); 
        List<User> salesUserList; 
        if(currentOpportunity.RecordType.Name == 'Mexico Sales Record Type')
        {
            salesUserList = [select Id, Name from User where (UserRole.Name like 'Mexico Sales Group %' and (not UserRole.Name like '%lead%')) and IsActive = true];
        }
        else if(currentOpportunity.RecordType.Name == 'US Sales Record Type')
        {
            salesUserList = [select Id, Name from User where UserRole.Name like 'US Sales Group %' and IsActive = true];
        }
        if(salesUserList != null)
        {
            for(User tempUser : salesUserList)
            {
                resultUserIds.add(tempUser.Id);
            }
        } 
        return resultUserIds;
    }
    
    @isTest
    static void testMexicoAutoAssignment()
    {
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        Date otherDay = currentDate.addDays(1);
        Datetime otherTime = currentTime.addDays(1); 
    
        List<User> sales = [select Id, Name from User where UserRole.Name = 'Mexico Sales Group (A)' and IsActive = true limit 4];
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
        Sales_Month_Summary__c  summary = new Sales_Month_Summary__c(Date__c = currentDate);
        insert summary;
        // Sets 'on duty'. 
            List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'Morning Duty', Date__c = currentDate));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'Evening Duty', Date__c = currentDate));    
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'Morning Duty', Date__c = currentDate)); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'Evening Duty', Date__c = currentDate));
        insert monthlyDetails;   
        // creates assignment report.
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 10,10, 0), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = otherDay, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 10,10, 0).addDays(1), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = otherDay, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 10,10, 0).addDays(1), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 15,10, 0), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = otherDay, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 15,10, 0).addDays(1), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 19,10, 0), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = otherDay, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 19,10, 0).addDays(1), Assignment_Org__c = 'Mexico'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 15,10, 0), Assignment_Org__c = 'Mexico'));
        insert reports;
        Account student = new Account(Name = 'test');  
        insert student; 
        // Opportunity record type 'Mexico Sales Record Type'.
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'Mexico Sales Record Type' limit 1];
        Opportunity morningOpp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 10,10, 0), CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        Opportunity afternoonOpp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 15,20, 0), CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        Opportunity eveningOpp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentTime.year(), currentTime.month(), currentTime.day(), 19,10, 0), CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        insert new Opportunity[]{morningOpp, afternoonOpp, eveningOpp};
        List<Opportunity> testOppList = [select Id, Name, Location__c, recordTypeId, recordType.Name, LeadSource, AccountId, OwnerId, Initial_Appt_Date__c, CloseDate, Event_subject__c from Opportunity where Id in :new List<Id>{morningOpp.Id, afternoonOpp.Id, eveningOpp.Id}];
        for(Opportunity opp : testOppList)
        {
            if(opp.Id == morningOpp.Id)
            {
                morningOpp = opp;
            }
            else if(opp.Id == afternoonOpp.Id)
            {
                afternoonOpp = opp;
            }
            else if(opp.Id == eveningOpp.Id)
            {
                eveningOpp = opp;
            }
        }
        // Start test
        MexicoAutoAssignment controller = new MexicoAutoAssignment();
        System.assertNotEquals(null, controller.autoAssignEvent(morningOpp)); 
        System.assertNotEquals(null, controller.autoAssignEvent(afternoonOpp));
        System.assertNotEquals(null, controller.autoAssignEvent(eveningOpp));
    }
}