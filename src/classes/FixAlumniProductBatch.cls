global class FixAlumniProductBatch implements Database.Batchable<sObject>
{
    public String queryString = '';
    
    public String queryString1 = 'select Id, Name, Actual__c, Actual__r.Opportunity__c, Actual__r.Opportunity__r.OwnerId, Actual__r.Opportunity__r.Name from StudentActual__c where CreatedDate > 2011-04-29T00:00:00Z and CreatedDate < 2011-04-29T23:00:00Z and CreatedById = \'00540000001MuFS\'';
    public String queryString2 = 'select Id, Name, Actual__c, Actual__r.Opportunity__c, Actual__r.Opportunity__r.OwnerId, Actual__r.Opportunity__r.Name from StudentActual__c where CreatedDate > 2011-05-03T00:00:00Z and CreatedDate < 2011-05-03T23:00:00Z and CreatedById = \'00540000001MuFS\'';
    
    private Integer updateActualAmount = 0;
    
    public void setQueryStringForPhase1()
    {
        queryString = queryString1; // 2011-04-29
    }
    
    public void setQueryStringForPhase2()
    {
        queryString = queryString2; // 2011-05-03
    }
    
    global database.Querylocator start(Database.BatchableContext BC)
    {  
        return Database.getQueryLocator(queryString);
    }
    
    global void execute(Database.BatchableContext BC, List<StudentActual__c> studentActuals)
    {
        if(studentActuals != null && studentActuals.size() > 0)
        {
            List<Actual__c> updatedActuals = new List<Actual__c>();
            //List<StudentActual__c> updatedStudentActuals= new List<StudentActual__c>();
            Map<Id, Id> actual2Opp = new Map<Id, Id>();
            for(StudentActual__c studentActual : studentActuals)
            {
            	actual2Opp.put(studentActual.Actual__c, studentActual.Actual__r.Opportunity__c);
            }
            
            List<Opportunity> opps = [select Id, (select Id, OwnerId from Actuals__r order by CreatedDate asc) from Opportunity where Id in :actual2Opp.values()];
            Map<Id, Id> opp2PreviousOwner = new Map<Id, Id>();
            if(opps.size() > 0)
            {
                for(Opportunity opp : opps)
                {
                    if(opp.Actuals__r.size() > 0)
                    {
                        opp2PreviousOwner.put(opp.Id, opp.Actuals__r[0].OwnerId);
                    }
                }
            }
            List<Actual__c> updateActuals = new List<Actual__c>();
            for(Id actualId : actual2Opp.keySet())
            {
                Id relatedOppId = actual2Opp.get(actualId);
                Id oldActualOwnerId = opp2PreviousOwner.get(relatedOppId);
                if(oldActualOwnerId != null)
                {
                    updateActuals.add(new Actual__c(Id = actualId, OwnerId = oldActualOwnerId));
                }
            }
            if(updateActuals.size() > 0)
            {
            	updateActualAmount = updateActualAmount + updateActuals.size();
                Database.update(updateActuals, false);
            }
        }
    }
    
    private void sendFinishedEmail()
    {
        Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
        List<String> toAddresses = new List<String>{'hobartcui@163.com', 'Jenny.Chen@ef.com'};
        mail.setToAddresses(toAddresses);
        mail.setSubject('FixAlumniProductBatch Finished');
        Datetime nowTime = Datetime.now();
        String dateString = nowTime.format();
        String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
        String htmlText = '';
        htmlText = htmlText + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
        htmlText = htmlText + ' Update Actual amount:' + updateActualAmount + '\r\n';
        mail.setPlainTextBody(htmlText);
        Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
    }
    
    global void finish(Database.BatchableContext BC)
    {
        sendFinishedEmail();
    }
    
    @isTest
    static void testFixAlumniProductBatch()
    {
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        Date otherDay = currentDate.addDays(1);
        Datetime otherTime = currentTime.addDays(1);
        Opportunity opp1 = new Opportunity(Name = 'test', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        Opportunity opp2 = new Opportunity(Name = 'test2', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        insert new List<Opportunity>{opp1, opp2};
        Actual__c actual1 = new Actual__c(Opportunity__c = opp1.Id);
        Actual__c actual2 = new Actual__c(Opportunity__c = opp2.Id);
        insert new List<Actual__c>{actual1, actual2};
        StudentActual__c studentActual1 = new StudentActual__c(Actual__c = actual1.Id, Name = 'test 01');
        StudentActual__c studentActual2 = new StudentActual__c(Actual__c = actual2.Id, Name = 'test 02');
        insert new List<StudentActual__c>{studentActual1, studentActual2};
        Test.startTest();
        FixAlumniProductBatch batch = new FixAlumniProductBatch();
        batch.queryString = 'select Id, Name, Actual__c, Actual__r.Opportunity__c, Actual__r.Opportunity__r.OwnerId, Actual__r.Opportunity__r.Name from StudentActual__c where Name like \'test%\'';
        Database.executeBatch(batch);
        batch.setQueryStringForPhase1();
        batch.setQueryStringForPhase2();
        Test.stopTest();
        //System.assertEquals('test', [select Id, Name from StudentActual__c where Id = :studentActual1.Id].Name);
    }
}