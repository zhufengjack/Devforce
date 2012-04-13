/*
*   Auto assignment for brazil.
*/ 
public class BrazilAutoAssignment extends AutoAssignmentBase
{
    // Override method createEventAndReport.
    public void createEventAndReport(String userId, Opportunity opp)
    {
        if(userId != null && opp != null)
        {
            checkAssignConflict(userId, opp.Initial_Appt_Date__c); // Check conflict.
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
            newEvent.RecordTypeId = (recordTypes.size() > 0) ? recordTypes[0].Id : null;
            insert newEvent;
            // Create assignment report.
            China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
            report.Appointment_DateTime__c = newEvent.ActivityDateTime;
            report.Appointment_Date__c = newEvent.ActivityDate;
            report.Assignment_Time__c = DateTime.now();
            report.Opportunity__c = opp.Id;
            report.Sales_Consultant__c = userId;
            report.Assignment_Org__c = 'Brazil';
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
            //Map<String, Double> userToAllocation = getUserAllocation(userGroup, assignDatetime); 
            Map<String, Integer> user2Target = getOnDutySalesUser(userGroup, assignDatetime);
            resultUserId = handleAssignmentForBrazil(user2Target, assignDatetime);
            checkAssignmentStatus(opp);
            if(resultUserId != null)
            {
                //Change queue status.
                Boolean checkDemoTargetResult = checkDemoTargetLimited(user2Target, resultUserId, assignDatetime);
                if(checkDemoTargetResult == false)
                {
                    throw new NoSaleUserException('Assignment conflicted. Please try again.');
                }
                changeQueueStatus(opp.Id);
            }
            else
            {
                // Create a new queue. 
                createQueue(opp, 'Brazil', 'Assignment Failure by webservice'); 
                throw new NoSaleUserException('No CC is available. Please choose another time.');
            }
        }
        return resultUserId;
    }
    
    public String handleAssignmentForBrazil(Map<String, Integer> user2Target, Datetime assignDatetime)
    {
        String resultId;
        if(user2Target != null && assignDatetime != null)
        {
            Set<String> idleSalesIdSet = getIdleSalesUser(user2Target, assignDatetime); 
            Map<String, Double> user2ApptPercent = calculateAssignmentPercent(idleSalesIdSet, user2Target, assignDatetime.date());
            resultId = getMinApptPercentUser(user2ApptPercent);
        }
        return resultId;
    }
    
    public Map<String, Integer> getOnDutySalesUser(Set<String> userIds, Datetime initialApptDatetime)
    {
       Map<String, Integer> user2Target = new Map<String, Integer>();
       if(userIds != null && initialApptDatetime != null)
       {
           Date initialApptDate = initialApptDatetime.date();
           String onduty = 'On Duty';
           List<Sales_Monthly_Details__c> details = [select Id, DemoTarget__c, Sales_Consultant__c from Sales_Monthly_Details__c where Date__c = :initialApptDate and Sales_Consultant__c in :userIds and StartWorkingTime__c <= :initialApptDatetime and FinishWorkingTime__c >= :initialApptDatetime and Day_Status__c = :onduty and Sales_Monthly_Schedule_Summary__r.WorkingWeekday__c != null];
           for(Sales_Monthly_Details__c detail : details)
           {
               Integer demotarget =  (detail.DemoTarget__c != null)? detail.DemoTarget__c.intValue(): 0;
               user2Target.put(detail.Sales_Consultant__c, demotarget);
           }
       }
       return user2Target;
    }
    
    public Set<String> getIdleSalesUser(Map<String, Integer> user2Target, Datetime initialApptDatetime)
    {
        Set<String> idleSalesUserIdSet = new Set<String>();
        if(user2Target != null && user2Target.size() > 0)
        {
            Set<String> onDutySalesUserIdSet = user2Target.keySet();
            Set<String> busySalesUserIdSet = new Set<String>();
            List<China_Appt_Assignment_Report__c> assignmentReportDetails = [select Id, Sales_Consultant__c from China_Appt_Assignment_Report__c where  Appointment_DateTime__c = :initialApptDatetime and Sales_Consultant__c in :onDutySalesUserIdSet];
            for(China_Appt_Assignment_Report__c report : assignmentReportDetails)
            {
                busySalesUserIdSet.add(report.Sales_Consultant__c);
            }
            for(String salesUserId : onDutySalesUserIdSet)
            {
                if(!busySalesUserIdSet.contains(salesUserId))
                {
                    idleSalesUserIdSet.add(salesUserId);
                }
            }
            //idleSalesUserIdSet = getHaveRemainingTargetUser(user2Target, idleSalesUserIdSet, initialApptDatetime);
        }
        return idleSalesUserIdSet;
    }
    
    private Boolean checkDemoTargetLimited(Map<String, Integer> user2Target, String salesUserId, Datetime initialApptDatetime)
    {
        Boolean result = false;
        if(user2Target != null && salesUserId != null && initialApptDatetime != null)
        {
            Set<String> salesUserIds = getHaveRemainingTargetUser(user2Target, new Set<String>{salesUserId}, initialApptDatetime);
            if(salesUserIds != null && salesUserIds.size() > 0)
            {
                result = true;
            }
        }
        return result;
    }
    
    // Number of assigned appt should be less than demo target.
    private Set<String> getHaveRemainingTargetUser(Map<String, Integer> user2Target, Set<String> tempIdleSalesUserIds, Datetime initialApptDatetime)
    {
        Set<String> idleSalesUserIds = new Set<String>();
        if(tempIdleSalesUserIds != null && tempIdleSalesUserIds.size() > 0 && initialApptDatetime != null && user2Target != null)
        {
            Date initialApptDate = initialApptDatetime.date();
            Map<String, Integer> assignedOppNumberMap = new Map<String, Integer>();
            List<AggregateResult> assignmentReportAggregateResults = [select Sales_Consultant__c, count(Id) c from China_Appt_Assignment_Report__c where Appointment_Date__c = :initialApptDate and Sales_Consultant__c in :tempIdleSalesUserIds and Sales_Consultant__c != null GROUP BY Sales_Consultant__c];
            for(AggregateResult result : assignmentReportAggregateResults)
            {
                assignedOppNumberMap.put((Id)result.get('Sales_Consultant__c'), (Integer)result.get('c'));
            }
            for(String tempUserId : tempIdleSalesUserIds)
            {
                Integer assignedOppNumber = (assignedOppNumberMap.get(tempUserId) != null)? assignedOppNumberMap.get(tempUserId): 0;
                Integer salesDemoTargetNumber = (user2Target.get(tempUserId) != null)? user2Target.get(tempUserId): 0;
                if(salesDemoTargetNumber > assignedOppNumber)
                {
                    idleSalesUserIds.add(tempUserId);
                }
            }
        }
        return idleSalesUserIds;
    }
    
    private Map<String, Double> calculateAssignmentPercent(Set<String> salesUserIds, Map<String, Integer> demoTargetMap, Date apptDate)
    {
        Map<String, Double> assignmentPercentMap = new Map<String, Double>();
        if(salesUserIds != null && demoTargetMap != null)
        {
            Map<String, Integer> apptAmountMap = getSalesApptAmount(salesUserIds, apptDate);
            for(String userId : salesUserIds)
            {
                Double target = demoTargetMap.get(userId);
                Double apptAmount = apptAmountMap.get(userId);
                Double apptPercent = (target > 0)? apptAmount/target : 0;
                assignmentPercentMap.put(userId, apptPercent);
            }
        }
        return assignmentPercentMap;
    }
    
    private Map<String, Integer> getSalesApptAmount(Set<String> salesUserIds, Date apptDate)
    {
        Map<String, Integer> user2ApptAmount = new Map<String, Integer>();
        if(salesUserIds != null && salesUserIds.size() > 0)
        {
            List<AggregateResult> results = [select Count(Id) reportSum , Sales_Consultant__c from China_Appt_Assignment_Report__c where Appointment_Date__c = :apptDate and Sales_Consultant__c in :salesUserIds group by Sales_Consultant__c];
            for(AggregateResult result : results)
            {
                user2ApptAmount.put((String)result.get('Sales_Consultant__c'), (Integer)result.get('reportSum'));
            }
            for(String userId : salesUserIds)
            {
                if(!user2ApptAmount.keySet().contains(userId))
                {
                    user2ApptAmount.put(userId, 0);
                }
            }
        } 
        return user2ApptAmount;
    } 
    
    private String getMinApptPercentUser(Map<String, Double> user2ApptPercent)
    {
        String resultId; 
        if(user2ApptPercent != null && user2ApptPercent.size() > 0)
        {
            Double tempPercent;
            for(String userId : user2ApptPercent.keySet())
            {   
                if(tempPercent == null)
                {
                    tempPercent = user2ApptPercent.get(userId);
                    resultId = userId;
                }
                else
                {
                    Double currentUserPercent = user2ApptPercent.get(userId);
                    if(currentUserPercent <= tempPercent)
                    {
                        tempPercent = currentUserPercent;
                        resultId = userId;
                    }
                }
            }  
            Double finalUserPercent = user2ApptPercent.get(resultId);
            if(finalUserPercent >= 1)
            {
                resultId = null;
            }
        }
        return resultId;
    }
    
    private void checkAssignmentStatus(Opportunity currentOpportunity)
    {
        // Judgment whether this opportunity had been auto assigned.
        List<China_Appt_Assignment_Report__c> reports = [select Id from China_Appt_Assignment_Report__c where Opportunity__c = :currentOpportunity.Id];
        if(reports.size() > 0)
        {
            throw new OpportunityAssignedException('Opportunity "'+currentOpportunity.Name+'" had been auto assigned.');
        }
    }
    
    public List<Integer> calculateReportCount(Map<String, CountInfo> salesCountMap, Datetime assignDatetime, Set<String> ondutyUserIds, Set<String> allUserIds)
    {
        return null;
    }
    
    // Override method getCurrentUserGroup.
    public Set<String> getCurrentUserGroup(Opportunity currentOpportunity)
    {
        Set<String> resultUserIds = new Set<String>();
        if(currentOpportunity != null && currentOpportunity.Location__c != null)
        {
            String location = currentOpportunity.Location__c;
            location = (location != null)? location.toUpperCase(): location;
            List<User> salesUsers;
            if(location == 'call center')
            {
                salesUsers = [select Id, Name from User where UserRole.Name like 'Brazil Sales Group%' and (not UserRole.Name like '%lead%') and IsActive = true];
            }
            else
            {
                String roleName = 'Brazil ' + location + ' Sales';
                salesUsers = [select Id, Name from User where UserRole.Name = :roleName and IsActive = true];
            }
            for(User saleUser : salesUsers)
            {
                resultUserIds.add(saleUser.Id);
            }
        }
        return resultUserIds;
    }
    
    private void checkAssignConflict(String userId, Datetime assignmentTime)
    {
        if(userId != null && assignmentTime != null)
        {
            List<China_Appt_Assignment_Report__c> reports = [select Id from China_Appt_Assignment_Report__c where Sales_Consultant__c = :userId and Appointment_DateTime__c = :assignmentTime limit 1];
            if(reports.size() > 0)
            {
                throw new OpportunityAssignedException('Assignment conflicted. Please try again.');
            }
        }
    }
    
    @isTest
    static void testBrazilAutoAssignment()
    {
        Date currentDate = Date.newInstance(1999, 11, 19);
        Time startTime = Time.newInstance(9, 0, 0, 0);
        Time endTime = Time.newInstance(18, 0, 0, 0);
        Datetime startingWorkTime = Datetime.newInstance(currentDate, startTime);
        Datetime endWorkTime = Datetime.newInstance(currentDate, endTime);
        List<User> sales = [select Id, Name from User where UserRole.Name = 'Brazil Sales Group (B)' and IsActive = true limit 4];
        User sale1 = sales[0];
        User sale2 = sales[1];
        User sale3 = sales[2];
        User sale4 = sales[3];
        // Create monthly schedule summary.
        String weekWorkingDays = 'Monday;Tuesday;Wednesday;Saturday;';
        Sales_Month_Summary__c  summary = new Sales_Month_Summary__c(Date__c = currentDate, WorkingWeekday__c = weekWorkingDays);
        insert summary;
        // Sets 'on duty'. 
        List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, demoTarget__c = 2, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, demoTarget__c = 3, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));    
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, demoTarget__c = 2, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime)); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, demoTarget__c = 2, Day_Status__c = 'On Duty', Date__c = currentDate, StartWorkingTime__c = startingWorkTime, FinishWorkingTime__c = endWorkTime));
        insert monthlyDetails; 
        // creates assignment report.
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(9, 0, 0, 0)), Assignment_Org__c = 'Brazil'));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Appointment_Date__c = currentDate, Appointment_DateTime__c = Datetime.newInstance(currentDate, Time.newInstance(10, 30, 0, 0)), Assignment_Org__c = 'Brazil'));
        insert reports;
        Account student = new Account(Name = 'test');  
        insert student; 
        // Opportunity record type 'Brazil Sales Record Type'.
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'Brazil Sales Record Type' and SobjectType = 'Opportunity' limit 1];
        User tmUser = [select Id, Name from User where UserRole.Name = 'Brazil TM (B)' and isActive = true limit 1];
        Opportunity opp1 = new Opportunity(Name = 'test', Location__c = 'Call Center', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentDate, Time.newInstance(10, 0, 0, 0)), CloseDate = currentDate.addDays(5), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        Opportunity opp2 = new Opportunity(Name = 'test2', Location__c = 'Call Center', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentDate, Time.newInstance(10, 0, 0, 0)), CloseDate = currentDate.addDays(5), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        Opportunity opp3 = new Opportunity(Name = 'test3', Location__c = 'Call Center', AccountId = student.Id, Initial_Appt_Date__c = Datetime.newInstance(currentDate, Time.newInstance(10, 0, 0, 0)), CloseDate = currentDate.addDays(5), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        insert new Opportunity[]{opp1, opp2, opp3};
        // Start test
        BrazilAutoAssignment controller = new BrazilAutoAssignment();
        System.assertNotEquals(null, controller.autoAssignEvent(opp1)); 
        System.assertNotEquals(null, controller.autoAssignEvent(opp2));
        System.assertNotEquals(null, controller.autoAssignEvent(opp3));
    }
}