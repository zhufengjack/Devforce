/*
*    This class for all auto assignment logic.
*/
global class AutoAssignmentWebService
 {
    WebService static Boolean checkRemainingAppts(String schoolName, String year, String month, String day)
    {   
        Boolean result = false;
        if(checkProfile())
        {
            return true;
        } 
        if(schoolName != null && year != null && month != null && day != null)
        {
            List<Appt_Max_target__c> maxTargets = [select Id, Max_target__c from Appt_Max_target__c where School__c = :schoolName and Year__c = :year and Month__c = :month and Day__c = :day order by CreatedDate DESC limit 1];
            if(maxTargets.size() > 0)
            {
                Integer maxNum = (maxTargets[0].Max_target__c == null) ? 0 : maxTargets[0].Max_target__c.intValue();
                Integer apptReportCount = [select count() from China_Appt_Assignment_Report__c where School__c = :schoolName and Year__c = :year and Month__c = :month and Day__c = :day];
                if(apptReportCount < maxNum)
                {
                    result = true;
                }
            } 
        } 
        return result;
    }
    
    private static Boolean checkProfile()
    {
        String currentProfileName = [select Name from Profile where Id = :UserInfo.getProfileId()].Name;
        currentProfileName = currentProfileName.toLowerCase();
        if(currentProfileName.contains('system administrator'))
        {
            return true;
        }
        else
        {
            return false;
        }
    }
    
    WebService static void autoAssignQueue(String queueIds)
    {
        if(queueIds != null && queueIds != '')
        {
            List<String> queueIdList = queueIds.split(','); 
            List<Auto_Assignment_Queue__c> queues = [select Id, Opportunity__c, Status__c from Auto_Assignment_Queue__c where Opportunity__c != null and Id in :queueIdList and Status__c = 'Queue'];
            Map<String, Auto_Assignment_Queue__c> opp2Queue = new Map<String, Auto_Assignment_Queue__c>(); 
            for(Auto_Assignment_Queue__c queue : queues)
            {
                opp2Queue.put(queue.Opportunity__c, queue);
            }
            Set<String> oppAssignIds = opp2Queue.keySet();
            List<Auto_Assignment_Queue__c> updateQueues = new List<Auto_Assignment_Queue__c>();
            List<China_Appt_Assignment_Report__c> reports = [select Id, Opportunity__c from China_Appt_Assignment_Report__c where Opportunity__c in :opp2Queue.keySet()];
            for(China_Appt_Assignment_Report__c report : reports)
            {
                if(opp2Queue.containsKey(report.Opportunity__c))
                {
                    Auto_Assignment_Queue__c tempQueue = opp2Queue.get(report.Opportunity__c); 
                    tempQueue.Status__c = 'Assigned';
                    updateQueues.add(tempQueue);
                    oppAssignIds.remove(report.Opportunity__c);
                }
            } 
            update updateQueues;
            for(String oppId : oppAssignIds)
            {  
                assignOpportunity(oppId);
            }
        }
    }
    
    WebService static String assignOpportunity(String oppId)
    {
        String resultMessage = 'Assign Successfully';
        try
        {
            List<Opportunity> currentOpportuntiys = [select Id, Name, Location__c, recordTypeId, recordType.Name, LeadSource, AccountId, OwnerId, Initial_Appt_Date__c, CloseDate, Event_subject__c from Opportunity where Id = :oppId limit 1];
            if(currentOpportuntiys.size() > 0)
            {
                String currentRecordType = currentOpportuntiys[0].recordType.Name;
                if(currentRecordType == 'China Smart Record Type')
                {
                    assignChinaSmartOpportunity(currentOpportuntiys[0]);
                }
                else if(currentRecordType == 'China Telesales Record Type')
                {
                    assignCNTSOpportunity(currentOpportuntiys[0]);
                }
                else if(currentRecordType == 'Brazil Sales Record Type')
                {
                    assignBrazilOpportunity(currentOpportuntiys[0]);
                }
                else if(currentRecordType == 'Mexico Sales Record Type' || currentRecordType == 'US Sales Record Type')
                {
                    assignMexicoOpportunity(currentOpportuntiys[0]);
                }
                else
                {
                    throw new OpportunityAssignedException('Error: you can only assign opportunity that record type in \'China Smart Record Type\', \'China Telesales Record Type\', \'US Sales Record Type\' and \'Brazil Sales Record Type\'.');
                }
            }
        }
        catch(Exception ex)
        {
            resultMessage = ex.getMessage();
        }
        return resultMessage;
    }
    
    // Method for china smart school.
    private static void assignChinaSmartOpportunity(Opportunity opp)
    {
        checkLeadToShowSchool(opp.Location__c);
        ChinaSmartAutoAssignment autoAssignment = new ChinaSmartAutoAssignment();
        autoAssignment.autoAssignEvent(opp);
    } 
    
    // Method for CNTS.
    private static void assignCNTSOpportunity(Opportunity opp)
    {
        ChinaTSAutoAssignment autoAssignment = new ChinaTSAutoAssignment();
        autoAssignment.autoAssignEvent(opp);
    }
    
    // Method for brazil.
    private static void assignBrazilOpportunity(Opportunity opp)
    {
        BrazilAutoAssignment autoAssignment = new BrazilAutoAssignment();
        lockOpportunityRecords(opp.recordType.Name, opp.Initial_Appt_Date__c, opp.Location__c);
        autoAssignment.autoAssignEvent(opp);
    }
    
    // Method for Mexico.
    private static void assignMexicoOpportunity(Opportunity opp)
    {
        MexicoAutoAssignment autoAssignment = new MexicoAutoAssignment();
        autoAssignment.autoAssignEvent(opp);
    }
    
    private static void checkLeadToShowSchool(String schoolName)
    {
       if(schoolName != null && schoolName != '')
       {
           List<String> leadToShowSchools = RemainingApptsHelper.getValidOriginalSchools();
           for(String leadToShowSchool : leadToShowSchools)
           {
               if(schoolName == leadToShowSchool)
               {
                   throw new OpportunityAssignedException('该学校属于leads to show模式学校，无需点击auto assign button.');
               }
           }
       }
    }
    
    private static void lockOpportunityRecords(String recordTypeName, Datetime initialApptDate, String apptLocation)
    {
        if(recordTypeName != null && initialApptDate != null && apptLocation != null)
        {
        	try
        	{
                List<Opportunity> opps = [select Id from Opportunity where RecordType.Name = :recordTypeName and Initial_Appt_Date__c = :initialApptDate and Location__c = :apptLocation for update];
        	}
        	catch(Exception ex)
        	{
        	    throw new OpportunityAssignedException('Assignment conflicted. Please try again!');
        	}
        }
    }

    public class OpportunityAssignedException extends Exception{}
    
    @isTest
    static void testAutoAssignmentWebService()
    {
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        Date otherDay = currentDate.addDays(1);
        Datetime otherTime = currentTime.addDays(1); 
        Account student = new Account(Name = 'test');
        insert student;
        List<RecordType> recordTypes = [select Id, Name from RecordType where Name = 'China Smart Record Type' and SobjectType = 'Opportunity' limit 1];
        Opportunity opp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt',  RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        insert opp;
        AutoAssignmentWebService.assignOpportunity(opp.Id);
        recordTypes = [select Id, Name from RecordType where Name = 'China Telesales Record Type' limit 1];
        opp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt',  RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        insert opp;
        AutoAssignmentWebService.assignOpportunity(opp.Id);
        recordTypes = [select Id, Name from RecordType where Name = 'Brazil Sales Record Type' limit 1];
        opp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt',  RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        insert opp; 
        AutoAssignmentWebService.assignOpportunity(opp.Id);
        recordTypes = [select Id, Name from RecordType where Name = 'Mexico Sales Record Type' limit 1];
        opp = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt',  RecordTypeId = recordTypes[0].Id, China_Sales_Type__c = 'New');
        insert opp;
        AutoAssignmentWebService.assignOpportunity(opp.Id);
        // Test for method autoAssignQueue.
        Opportunity opp1 = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp2 = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp3 = new Opportunity(Name = 'test', AccountId = student.Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        insert new Opportunity[]{opp1, opp2, opp3};
        Auto_Assignment_Queue__c queue1 = new Auto_Assignment_Queue__c(Opportunity__c = opp1.Id, Status__c = 'Queue');
        Auto_Assignment_Queue__c queue2 = new Auto_Assignment_Queue__c(Opportunity__c = opp2.Id, Status__c = 'Queue');
        Auto_Assignment_Queue__c queue3 = new Auto_Assignment_Queue__c(Opportunity__c = opp3.Id, Status__c = 'Queue');
        insert new Auto_Assignment_Queue__c[]{queue1, queue2, queue3};
        China_Appt_Assignment_Report__c report1 = new China_Appt_Assignment_Report__c(Opportunity__c = opp1.Id);
        insert report1;
        String oppIds = opp1.Id + ',' + opp2.Id + ',' + opp3.Id;
        AutoAssignmentWebService.autoAssignQueue(oppIds);
        // Tests for capping.
        AutoAssignmentWebService.checkProfile();
        Date currenDate = Date.today().addYears(20);
        User tempUser = [select Id, SchoolName__c from User where UserRole.Name = 'China BJ_DWL Sales Manager' limit 1];
        System.runAs(tempUser)
        {
            String userSchoolName = tempUser.SchoolName__c.replace('_',' ');
            Appt_Max_target__c maxTarget = new Appt_Max_target__c(Date__c = currentDate, School__c = userSchoolName);
            insert maxTarget;
            maxTarget = [select Id, Day__c, Month__c, Year__c, School__c from Appt_Max_target__c where Id = :maxTarget.Id];
            AutoAssignmentWebService.checkRemainingAppts(userSchoolName, maxTarget.Year__c, maxTarget.Month__c, maxTarget.Day__c);
        }
        // Test for method checkLeadToShowSchool
        
        List<String> leadToShowSchools = RemainingApptsHelper.getValidOriginalSchools();
        String testSchool = (leadToShowSchools.size() > 0) ? leadToShowSchools[0] : '';
        try
        {
            AutoAssignmentWebService.checkLeadToShowSchool(testSchool);
        }
        catch(Exception ex)
        {
            System.assertEquals('该学校属于leads to show模式学校，无需点击auto assign button.', ex.getMessage());
        }
        
    }
}