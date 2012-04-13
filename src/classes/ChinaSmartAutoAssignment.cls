/*
*  Auto assignment for china smart school.
*/
public class ChinaSmartAutoAssignment extends AutoAssignmentBase
{
    private Integer sourceType = 0; // 1 --- inbound, 2 --- outbound.
    
    // Override method createEventAndReport.
    public void createEventAndReport(String userId, Opportunity tempOpportunity)
    {
        if(userId != null && tempOpportunity != null)
        {
            // Create and assign event.
            List<RecordType> recordTypes = [select Id from RecordType where Name = 'CN F2F Sales Meeting'];
            Event newEvent = new Event();
            newEvent.DurationInMinutes = 60;
            if(tempOpportunity.Initial_Appt_Date__c != null)
            {
                newEvent.ActivityDateTime = tempOpportunity.Initial_Appt_Date__c;
                newEvent.ActivityDate = Date.newInstance(tempOpportunity.Initial_Appt_Date__c.year(), tempOpportunity.Initial_Appt_Date__c.month(), tempOpportunity.Initial_Appt_Date__c.day());
            } 
            newEvent.OwnerId = userId;
            newEvent.EF_Office__c = tempOpportunity.Location__c;
            newEvent.Owner__c = 'Junior CC';
            newEvent.WhatId = tempOpportunity.Id;
            newEvent.Subject = (tempOpportunity.Event_subject__c != null) ? tempOpportunity.Event_subject__c : 'Sales Demo (1)';
            newEvent.RecordTypeId = (recordTypes.size() > 0) ?  recordTypes[0].Id : null;
            insert newEvent;
            // Create assignment report.
            China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
            report.Appointment_DateTime__c = newEvent.ActivityDateTime;
            report.Appointment_Date__c = newEvent.ActivityDate;
            report.Assignment_Time__c = DateTime.now();
            report.Lead_Source__c = (tempOpportunity.LeadSource.indexOf('Online')<0) ? tempOpportunity.LeadSource : 'Online';
            report.Opportunity__c = tempOpportunity.Id;
            report.Sales_Consultant__c = userId;
            report.School__c = tempOpportunity.Location__c;
            report.OwnerId = userId;
            insert report;
        }
    }
    
    // Override method autoAssignUser.
    public String autoAssignUser(Opportunity tempOpportunity)
    {   
        String resultUserId;
        if(tempOpportunity != null)
        {
            set<String> userGroup = getCurrentUserGroup(tempOpportunity); // Get all user that location 
            String leadSource = tempOpportunity.LeadSource;
            Datetime assignDatetime = tempOpportunity.Initial_Appt_Date__c;
            Map<String, Double> userToAllocation = getUserAllocation(userGroup, assignDatetime);  
            if(leadSource == 'inbound call')
            {   
            	System.debug('Debug Information: China leadSource type: inbound call' );
                // process inbound function.
                sourceType = 1;
                resultUserId = handleAssignmentExtension(userToAllocation, assignDatetime, userGroup);
            }
            else 
            {
            	System.debug('Debug Information: China leadSource type: outbound call' );
                // process outbound function.
                sourceType = 2;
                resultUserId = handleAssignment(userToAllocation, assignDatetime, userGroup);
            }  
            System.debug('Debug Information 最终销售Id:' + resultUserId);
            // Process queue.
            if(resultUserId != null)
            {
                // Change queue status.
                changeQueueStatus(tempOpportunity.Id);
            }
            else
            {
                // Create a new queue for current opportunity.
                createQueue(tempOpportunity, tempOpportunity.Location__c, 'Assignment Failure by webservice');
                throw new NoSaleUserException('No user has been assigned, the opportunity has been added to queue.');
            } 
        }

        return resultUserId;
    }
   
    // Implements method calculateReportCount. Calculates finished rate.
    public  List<Integer> calculateReportCount(Map<String, CountInfo> salesCountMap, Datetime assignDatetime, Set<String> ondutyUserIds, Set<String> allUserIds)
    {
        if(salesCountMap != null && assignDatetime != null && ondutyUserIds != null && allUserIds != null)
        {
            String year = String.valueOf(assignDatetime.year());
            String month = String.valueOf(assignDatetime.month());
            String day = String.valueOf(assignDatetime.day());
            
            List<Integer> totalReportCountList = new List<Integer>();

            Integer dailyCount = 0; // Daily summary for inbound, outbound or total. 
            Integer monthlyCount = 0; // Monthly summary for inbound, outbound or total.
            
            // Select all report this month.
            if(sourceType == 1)
            {
                for(China_Appt_Assignment_Report__c assignReport : [select Id, Lead_Source__c, Day__c, Sales_Consultant__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :allUserIds and Lead_Source__c = 'Inbound Call' and Year__c =:year and Month__c =:month order by Sales_Consultant__c])
                {
                    monthlyCount++;
                    dailyCount = (assignReport.Day__c == day) ? (dailyCount + 1) : dailyCount;
                    calculateReportCountForOndutySale(salesCountMap, ondutyUserIds, assignReport, day);
                }
            }
            else if(sourceType == 2)
            {
                for(China_Appt_Assignment_Report__c assignReport : [select Id, Lead_Source__c, Day__c, Sales_Consultant__c from China_Appt_Assignment_Report__c where Sales_Consultant__c in :allUserIds and Lead_Source__c != 'Inbound Call' and Year__c =:year and Month__c =:month order by Sales_Consultant__c])
                {
                    monthlyCount++;
                    dailyCount = (assignReport.Day__c == day) ? (dailyCount + 1) : dailyCount;
                    calculateReportCountForOndutySale(salesCountMap, ondutyUserIds, assignReport, day);
                }
            }
            totalReportCountList.add(dailyCount); 
            totalReportCountList.add(monthlyCount);
            System.debug('Debug Information#今天分配总数量:' + dailyCount + '#本月分配总数量:' + monthlyCount);
            return totalReportCountList;
        }
        return null;
    }
 
    // Override method getCurrentUserGroup.
    //returns a list of user id
    public set<String> getCurrentUserGroup(Opportunity currentOpportunity)
    {
        Set<String> userIds = new Set<String>();
        if(currentOpportunity != null && currentOpportunity.Location__c != null)
        {
            String location = currentOpportunity.Location__c.replace(' ', '_');
            String userRoleName = 'China ' + location + ' Sales Consultant';
            String ftmRoleName = 'China ' + location + ' FTM';
            List<User> saleUsers = [select Id, Name from User where (UserRole.Name = :userRoleName or UserRole.Name = :ftmRoleName) and IsActive = true];
            for(User saleUser : saleUsers)
            {
                userIds.add(saleUser.Id); 
                System.debug('Debug Infomation: SaleUser Id#Name:'+saleUser.Id + '#'+saleUser.Name);
            }
        }
        return userIds;
    }
    
    @isTest
    static void testChinaSmartAutoAssignment()
    {
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        Date otherDay = currentDate.addDays(1);
        Datetime otherTime = currentTime.addDays(1); 
        
        List<User> sales = [select Id, Name from User where UserRole.Name = 'China BJ_GM1 Sales Consultant' and IsActive = true limit 4];
        User sale1 = sales[0];
        User sale2 = sales[1];
        User sale3 = sales[2];
        User sale4 = sales[3];
        // Sets allocation for each user.
        List<Sales_Team_Appointment_Allocation__c> allocations = new List<Sales_Team_Appointment_Allocation__c>();
        allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale1.Id, Allocation__c = '50%', School__c = 'BJ GM1', Date__c = currentDate));
        allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale2.Id, Allocation__c = '30%', School__c = 'BJ GM1', Date__c = currentDate));
        allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale3.Id, Allocation__c = '25%', School__c = 'BJ GM1', Date__c = currentDate));
        allocations.add(new Sales_Team_Appointment_Allocation__c(Sales_consultant__c = sale4.Id, Allocation__c = '25%', School__c = 'BJ GM1', Date__c = currentDate));
        insert allocations;
        // Create monthly schedule summary.
        Sales_Month_Summary__c  summary = new Sales_Month_Summary__c(Date__c = currentDate, School__c = 'BJ GM1' );
        insert summary;
        // Sets 'on duty'. 
        List<Sales_Monthly_Details__c> monthlyDetails = new List<Sales_Monthly_Details__c>();
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale1.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale2.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));     
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale3.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate)); 
        monthlyDetails.add(new Sales_Monthly_Details__c(Sales_Consultant__c = sale4.Id, Sales_Monthly_Schedule_Summary__c = summary.Id, Day_Status__c = 'On Duty', Date__c = currentDate));
        insert monthlyDetails;
        // creates assignment report.
        List<China_Appt_Assignment_Report__c> reports = new List<China_Appt_Assignment_Report__c>();
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Lead_Source__c = 'Inbound Call',    Appointment_Date__c = otherDay));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Lead_Source__c = 'Inbound Call',    Appointment_Date__c = currentDate));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Lead_Source__c = 'Outbound Call',   Appointment_Date__c = otherDay));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale1.Id, Lead_Source__c = 'Outbound Call',   Appointment_Date__c = currentDate));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Lead_Source__c = 'Inbound Call',    Appointment_Date__c = otherDay));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Lead_Source__c = 'Inbound Call',    Appointment_Date__c = currentDate));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Lead_Source__c = 'Outbound Call',   Appointment_Date__c = otherDay));
        reports.add(new China_Appt_Assignment_Report__c(Sales_Consultant__c = sale2.Id, Lead_Source__c = 'Outbound Call',   Appointment_Date__c = currentDate));
        insert reports;
        Account student = new Account(Name = 'test');
        insert student;
        // Opportunity record type 'China Smart Record Type'.
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1];
        Opportunity inboundOpp = new Opportunity(Name = 'test', AccountId = student.Id, Location__c = 'BJ GM1', Initial_Appt_Date__c = currentTime, LeadSource = 'Inbound Call', CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        Opportunity outboundOpp = new Opportunity(Name = 'test', AccountId = student.Id, Location__c = 'BJ GM1', Initial_Appt_Date__c = currentTime, LeadSource = 'Outbound Call', CloseDate = currentDate.addDays(10), StageName = 'Set Appt', RecordTypeId = recordTypes[0].Id);
        insert new Opportunity[]{inboundOpp, outboundOpp};
        // Start test
        ChinaSmartAutoAssignment controller = new ChinaSmartAutoAssignment();
        System.assertNotEquals(null, controller.autoAssignEvent(inboundOpp));
        System.assertNotEquals(null, controller.autoAssignEvent(outboundOpp)); 
    }
}