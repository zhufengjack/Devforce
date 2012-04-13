@isTest
private class TestSmartOpportunityExtension {

    public static testMethod void testMethods() {
        
        Account acc = new Account(Name = 'Account4Test');
        insert acc;        
        
        Opportunity opp = new Opportunity(Name = 'Opp4Test', CloseDate = System.today(), StageName = 'TestStage');
        insert opp;       
        
        Test.setCurrentPageReference(new Pagereference('Page.SmartOpportunityButton'));        
        ApexPages.standardController stdController = new ApexPages.standardController(opp); 
        SmartOpportunityExtension extension = new SmartOpportunityExtension (stdController);
        
        //test setAccountId() and getAccountId()
        extension.setAccountId(acc.id);
        System.assertEquals(acc.id, extension.getAccountId());
        
        //test getURL();
        String url = extension.getURL();
        System.assertEquals(true, url.toLowerCase().contains('smartopportunitybutton'));
        
        //test verify() step 1
        ApexPages.currentPage().getParameters().put('retURL', '/' + acc.id); 
        PageReference pr1 = extension.verify();
        System.System.debug(pr1.getURL());
        System.assertEquals(true, pr1.getURL().toLowerCase().contains('nopreviousopportunityexist'));
        
        //test verify() step 2
        opp.AccountId = acc.id;
        update opp;
        PageReference pr2 = extension.verify();
        System.System.debug(pr2.getURL());
        System.assertEquals(true, pr2.getURL().toLowerCase().contains('canonlycreatedonetimeperday'));
        
        //test verify() step 3
        Account acc2 = new Account(Name = 'Account4Test_2');
        insert acc2;
        Opportunity opp2 = [SELECT Id, AccountId FROM Opportunity WHERE CreatedDate != Today AND StageName != 'Closed Won' ORDER BY CreatedDate DESC LIMIT 1];
        //opp2.AccountId = acc2.id;
        //update opp2;
        ApexPages.currentPage().getParameters().put('retURL', '/' + opp2.AccountId); 
        PageReference pr3 = extension.verify();
        System.System.debug(pr3.getURL());
        System.assertEquals(true, pr3.getURL().toLowerCase().contains('recentopportunitynotclosedwon'));
        
        //test verify() step 4
        opp2 = [SELECT Id, AccountId FROM Opportunity WHERE CreatedDate != Today AND StageName = 'Closed Won' ORDER BY CreatedDate DESC LIMIT 1];
        //opp2.StageName = 'Closed Won';
        //update opp2;
        PageReference pr4 = extension.verify();
        System.System.debug(pr4.getURL());
        //System.assertEquals(true, pr4.getURL().toLowerCase().contains('choosechinasalestype'));        
    }
}