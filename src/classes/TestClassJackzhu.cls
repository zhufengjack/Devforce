/**
 *
 */
@isTest
private class TestClassJackzhu {
/*
    static testMethod void myUnitTest() {
        // TO DO: implement unit test
        User u1=[select id,username from user where id='00540000000rnP7'];
       User u2=[select id,Username from User where id='00530000000rEJc'];
       System.runAs(u1){
        Account acc=new Account();
        acc.name='testforacc';
        insert acc;
        Opportunity opp=new Opportunity();
        opp.Name='testforopp';
        opp.AccountId=acc.Id;
        opp.StageName='set appt';
        opp.closedate=System.today();
        insert opp;
        Actual__c acu=new Actual__c();
        acu.Opportunity_owner__c=u1.Id;
        acu.Opportunity__c =opp.id;
        insert acu;
        opp.OwnerId=u2.Id;
        update opp;
       }
       
        
       
        
    }*/ 
    static testMethod void testContactTrigger()
    {
        
    Contact con1=new Contact();
    con1.FirstName='jack';
    con1.LastName='zhu';
    con1.Email='jack.zhu22@ef.com';
    insert con1;
    Contact con2=new Contact();
    con2.FirstName='jack';
    con2.LastName='zhu';
    con2.Email='jack.zhu33@ef.com';
    insert con2;
    
    }
   /** static testMethod void testCaseTrigger()
    {
    Case c1=new Case();
    RecordType rt1=[select Id from RecordType where name ='ETown Student Case'limit 1];
    c1.RecordTypeId=rt1.Id;
    c1.Subject='Help to solve issue';
    c1.Type='';
    c1.Reason='';
    c1.Origin='';
    c1.Description='';
    c1.Functions__c='';
    insert c1;
   
    Case c2=new Case();
    c2.RecordTypeId='012400000009bCb';
    c2.Subject='Help to solve issue2';
    c2.Type='';
    c2.Reason='';
    c2.Origin='';
    c2.Description='';
    c2.Functions__c='';
    c2.Status='new';
    insert c2;
    c2.Status='In Progress';
    update c2;
    User u1=[select Id,Name from user where Profile.Id ='00e40000000i0Pm' and IsActive=true limit 1];
    System.runAs(u1){
    
     Case c3=new Case();
    c3.RecordTypeId='012400000009bCb';
    c3.Subject='Help to solve issue2';
    c3.Type='';
    c3.Reason='';
    c3.Origin='';
    c3.Description='';
    c3.Functions__c='';
    c3.Status='new';
    insert c3;
     c3.Status='In Progress';
    update c3;
    
    }
    
    
     }
     */
    static testMethod void testTeacherInductionTrainingTrigger()
    {
    /**this testmethod is for contacttrigger, 
    *the function of this trigger is when user change status to training confirmed, 
    *system generate an introduction and training record automatically.
    */
    Account a1=new Account();
    a1.Name='etown teachers';
    insert a1;
    Contact c1=new Contact();
    c1.FirstName='zhufengjackzhu';
    c1.LastName='zhu';
    c1.RecordTypeId='01290000000MV39';
    c1.Email='zhufengjack@ef.com';
    c1.Phone='18621917690';
    c1.Teacher_recuritment_status__c='Training confirmed';
    insert c1;
    
    }
    static testMethod void testLeadTrigger()
    {
    /**
    @author Jack Zhu
    @Date 2011-10-21
    @Trigger Name:LeadTrigger
    @function: to test whether  Lead trigger can work correctly ChinaSmartLeadRecordType. recordtype id 0124000000099rk
    */
    Lead smartnewlead=new lead();
    Lead tsnewLead=new Lead();
    smartnewlead.Company='Smart';
    smartnewlead.LastName='zhu';
    smartnewlead.Status='new';
    smartnewlead.Partner_Ad_Channel__c='Booth';
    String id=[select id from RecordType where RecordType.Name='China Smart Lead Record Type'limit 1].Id;
    smartnewlead.RecordTypeId=id;
    smartnewlead.CN_Province_Name__c='cn_sh';
    smartnewlead.CN_City__c='Huangpu';
    insert smartnewlead;
    system.debug('smartnewlead'+smartnewlead.Id);
    
    
    tsnewLead.Company='TS';
    tsnewLead.LastName='zhu';
    tsnewLead.Status='new';
    tsnewLead.Partner_Ad_Channel__c='Booth';
    String otherrecordtypeid=[select id from RecordType where RecordType.Name ='China TS Lead Record Type' and SobjectType ='Lead'limit 1].Id;
    tsnewLead.RecordTypeId=otherrecordtypeid;
    insert tsnewLead;
    system.debug('tsnewLead'+tsnewLead.Id);
    }
}