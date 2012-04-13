@isTest
private class TestChooseChinaSalesType{
 
    //testing method
    public static testMethod void testMethods() {
                
        //step 1: prepare the test data
        Account acc = new Account(Name = 'Account4Test');
        insert acc;
         
        Opportunity opp = new Opportunity(Name = 'Opp4Test', CloseDate = System.Today(), StageName = 'Closed Won',
                                            AccountId = acc.id);
        opp.LeadSource = 'leadSource';
        opp.Phone2__c = '12345678';
        opp.Mobile__c = '13888123456';
        opp.Email__c = 'test@test.com';
        opp.Partner_Ad_Channel__c = 'pac';
                
        opp.ConvertedFromLead__c = 1001;
        opp.BJ_Marketing__c = 'BJ_Marketing__c';
        opp.GZ_Marketing__c = 'GZ_Marketing__c';
        opp.HZ_Marketing__c = 'HZ_Marketing__c';
        opp.SZ_Marketing__c = 'SZ_Marketing__c';
        opp.SH_Marketing__c = 'SH_Marketing__c';
        insert opp;
        
        Test.setCurrentPageReference(new Pagereference('Page.ChooseChinaSalesType'));    
        ApexPages.currentPage().getParameters().put('accId', acc.id);        
        ApexPages.currentPage().getParameters().put('ls', opp.LeadSource);
        ApexPages.currentPage().getParameters().put('p2', opp.Phone2__c = '12345678');
        ApexPages.currentPage().getParameters().put('Mobile', opp.Mobile__c);
        ApexPages.currentPage().getParameters().put('email', opp.Email__c);
        ApexPages.currentPage().getParameters().put('PAC', opp.Partner_Ad_Channel__c);
        ApexPages.currentPage().getParameters().put('name', acc.Name);
        ApexPages.currentPage().getParameters().put('opk', opp.Id);

        ChooseChinaSalesType ccst = new ChooseChinaSalesType();
        
        List<SelectOption> options = ccst.getSalesTypes();
        System.assertequals(6, options.size());        
        
        PageReference pr1 = ccst.createOpportunity();
        //System.assertequals(null, pr1);
        
        ccst.setSalesType('Renew');
        PageReference pr2 = ccst.createOpportunity();        
        System.System.debug(pr2.getURL().toLowerCase());
        //System.assertequals(true, pr2.getURL().toLowerCase().contains('salesforce'));
        
        opp.ConvertedFromLead__c = 1003;
        update opp;
        PageReference pr3 = ccst.createOpportunity();        
        System.System.debug(pr3.getURL().toLowerCase());
        System.assertequals(true, pr3.getURL().toLowerCase().contains('canonlycreatedonetimeperday'));

                
    }
}