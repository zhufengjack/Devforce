global class CopyEmailFromOpportunityToAccountBatch implements Database.Batchable<sObject>, Database.stateful
{
     public String queryOpp = 'select Id, Email__c, AccountId from Opportunity where Email__c != null and Account.Email__c = null and AccountId != null';
     private Integer accountAmount = 0;
     private Integer contactAmount = 0;
     
     public void addOrderByToQuery()
     {
         queryOpp = queryOpp + ' Order by lastModifiedDate';
     }
     
     global database.Querylocator start(Database.BatchableContext BC)
     {
         return Database.getQueryLocator(queryOpp);
     }
     
     global void execute(Database.BatchableContext BC, List<Opportunity> opps)
     {
         if(opps.size() > 0)
         {
             Map<Id, Account> updateAccountMap = new Map<Id, Account>();
             Map<Id, String> account2Email = new Map<Id, String>();
             for(Opportunity opp : opps)
             {
                 Account tempAccount = new Account(Id = opp.AccountId, Email__c = opp.Email__c);
                 account2Email.put(opp.AccountId, opp.Email__c);
                 updateAccountMap.put(opp.AccountId, tempAccount);
             }
             // For contact.
             Map<Id, Contact> accountId2Contact = new Map<Id, Contact>();
             List<Account> relateAccounts = [select Id, (select Id, Email from Contacts limit 3) from Account where Id in :updateAccountMap.keySet()];
             for(Account acc : relateAccounts)
             {
                 if(acc.Contacts.size() == 1)
                 {
                     Contact tempContact = acc.Contacts[0];
                     tempContact.Email = account2Email.get(acc.Id);
                     accountId2Contact.put(acc.Id, tempContact);
                 }
             }

             // update records.
             if(updateAccountMap.size() > 0)
             {
                 accountAmount = accountAmount + updateAccountMap.size();
                 Database.update(updateAccountMap.values(), false);
             }
             if(accountId2Contact.size() > 0)
             {
                 contactAmount = contactAmount + accountId2Contact.size();
                 Database.update(accountId2Contact.values(), false);
             }
         }
     }
     
     global void finish(Database.BatchableContext BC)
     {
         Messaging.SingleEmailMessage mail = new Messaging.Singleemailmessage();
         List<String> toAddresses = new List<String>{'hobartcui@163.com', 'alex.shine.1987@gmail.com'};
         mail.setToAddresses(toAddresses);
         mail.setSubject('Copy email from opportunity to account result');
         Datetime nowTime = Datetime.now();
         String dateString = nowTime.format();
         String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
         String htmlText = '';
         htmlText = htmlText + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
         htmlText = htmlText + ' udpate account amount：' + accountAmount + '\r\n';
         htmlText = htmlText + ' udpate contact amount：' + contactAmount + '\r\n';
         mail.setPlainTextBody(htmlText);
         Messaging.sendEmail(new List<Messaging.Singleemailmessage>{mail});
     }
     
     @isTest
     static void testCopyEmailForOpportunityToAccountBatch()
     {
         String accRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and sObjectType = 'Account'].Id;
         Account account1 = new Account(Name = 'test acc1', RecordTypeId = accRecordTypeId);
         Account account2 = new Account(Name = 'test acc2', RecordTypeId = accRecordTypeId);
         Account account3 = new Account(Name = 'test acc3', RecordTypeId = accRecordTypeId);
         Account account4 = new Account(Name = 'test acc4', RecordTypeId = accRecordTypeId);
         insert new List<Account>{account1, account2, account3, Account4}; 
         Date currentDate = Date.today();
         currentDate = currentDate.addYears(5);
         Datetime currentTime = Datetime.now();
         currentTime = currentTime.addYears(5);
         Date otherDay = currentDate.addDays(1);
         Datetime otherTime = currentTime.addDays(1);
         Opportunity opp1 = new Opportunity(Name = 'opp 1', AccountId = account1.Id, Email__c = 'test.opp1.copy@email.com', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
         Opportunity opp2 = new Opportunity(Name = 'opp 2', AccountId = account2.Id, Email__c = 'test.opp2.copy@email.com', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
         Opportunity opp3 = new Opportunity(Name = 'opp 3', AccountId = account2.Id, Email__c = 'test.opp3.copy@email.com', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
         Opportunity opp4 = new Opportunity(Name = 'opp 4', AccountId = account2.Id, Email__c = 'test.opp4.copy@email.com', Initial_Appt_Date__c = currentTime, CloseDate = currentDate.addDays(10), StageName = 'Closed Won', China_Sales_Type__c = 'New');
         insert new List<Opportunity>{opp1, opp2, opp3, opp4};
         Contact contact1 = new Contact(Lastname = 'test contact1', AccountId = account1.Id);
         insert contact1;
         Test.startTest();
         CopyEmailFromOpportunityToAccountBatch batch = new CopyEmailFromOpportunityToAccountBatch();
         batch.queryOpp = batch.queryOpp + ' and Email__c like \'test.opp%\' ';
         batch.addOrderByToQuery();
         Database.executeBatch(batch);
         Test.stopTest();
         System.assertEquals('test.opp1.copy@email.com', [select Email__c from Account where Id = :account1.Id].Email__c);
     }
}