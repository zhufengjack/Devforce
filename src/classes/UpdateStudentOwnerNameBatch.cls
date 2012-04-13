/**
 * updates StudentOwner__c
*/
global class UpdateStudentOwnerNameBatch implements Database.Batchable<sObject>
{
    global final String soql= null;
    global final String sObjectType= null;
    global final Id chinaSmartRecordTypeId = '012O00000004InO';
    
    global UpdateStudentOwnerNameBatch(String soql, String sObjectType)
    {
        this.soql= soql;
        this.sObjectType = sObjectType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return Database.getQueryLocator(soql);
    }
       
    global void execute(Database.BatchableContext bc,  List<sObject> sObjects)
    {
        UpdateStudentOwnerName(sObjects);
    }
    
    global void finish(Database.BatchableContext bc)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(new String[] {'gerald.wang@meginfo.com'});
        mail.setSenderDisplayName('Englishtown Salesforce Team'); 
        mail.setSubject('update student owner name Completed'); 
        mail.setPlainTextBody('update student owner name Completed.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    //processes accounts or opportunities
    private void updateStudentOwnerName(List<sObject> sObjects)
    {	
        if(this.sObjectType == 'Account')
        {
            List<Account> results = new List<Account>();
            for(sObject account : sObjects)
            {
                Account result = (Account)account;
                result.StudentOwner__c = result.Owner.Name;
                results.add(result);
            }      
            try
            {
                update results;
            }
            catch(exception ex)
            {               
            }
       }
       else if(this.sObjectType == 'Opportunity')
       {
           List<Opportunity> results = new List<Opportunity>();
           for(sObject opp : sObjects)
           {
               Opportunity result = (Opportunity)opp;
               result.StudentOwner__c = result.Owner.Name;
               results.add(result);
            }      
            try
            {
                update results;
            }
            catch(exception ex)
            {               
            }
       }
    }
 	/*
 	@isTest
    static void testUpdateStudentOwnerNameBatch()
    {
        Id chinaSmartAccountRecordTypeId = '012O00000004InO';
        Id chinaSmartOppRecordTypeId = '0124000000099sY';
        String soql = 'select Owner.Name, StudentOwner__c from Account where StudentOwner__c= null and RecordTypeId = \'' + chinaSmartAccountRecordTypeId + '\'  limit 10';
        String sObjectType = 'Account';
        Test.StartTest();
        UpdateStudentOwnerNameBatch  updateBatch = new UpdateStudentOwnerNameBatch(soql, sObjectType);
        ID batchprocessid = Database.executeBatch(updateBatch);
        String sObjectType2 = 'Opportunity';
        String soql2 = 'select Owner.Name, StudentOwner__c from Opportunity where StudentOwner__c= null and RecordTypeId = \'' + chinaSmartOppRecordTypeId + '\'  limit 10';
        UpdateStudentOwnerNameBatch  updateBatch2 = new UpdateStudentOwnerNameBatch(soql2, sObjectType2);
        ID batchprocessid2 = Database.executeBatch(updateBatch2);
        Test.StopTest();
    }
    */
    
}