public class ChooseChinaSalesType2 {
    String salesType = null;
    
    public PageReference createOpportunity() {
        String accountId = ApexPages.currentPage().getParameters().get('accId');        
        String leadSource = ApexPages.currentPage().getParameters().get('ls');
        String phone = ApexPages.currentPage().getParameters().get('p2');
        String mobile = ApexPages.currentPage().getParameters().get('Mobile');
        String email = ApexPages.currentPage().getParameters().get('email');
        String pac = ApexPages.currentPage().getParameters().get('PAC');
        String name = ApexPages.currentPage().getParameters().get('name');
        String oppId = ApexPages.currentPage().getParameters().get('opk');
        Opportunity opp = new Opportunity();
        opp.AccountId = accountId;
        opp.LeadSource = leadSource;
        opp.Phone2__c = phone;
        opp.Mobile__c = mobile;
        opp.Email__c = email;
        opp.Partner_Ad_Channel__c = pac;
        opp.Initial_Appt_Date__c = System.now();
        opp.CloseDate = System.today();
        opp.China_Sales_Type__c = getSalesType();
        if ( opp.China_Sales_Type__c == '' || opp.China_Sales_Type__c == ' ' || opp.China_Sales_Type__c == null) {
            ApexPages.Message dupeMsg = new ApexPages.Message(ApexPages.Severity.ERROR, '请选择类型');
            ApexPages.addMessage(dupeMsg);
            return null;           
        } 
        opp.StageName = 'Set Appt';
        opp.Name = name;
        List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :accountId AND CreatedDate = Today AND ConvertedFromLead__c != 1001];
        if ( opps.size() == 0 ) {
            Opportunity opp2 = [SELECT BJ_Marketing__c, GZ_Marketing__c, HZ_Marketing__c, SZ_Marketing__c, SH_Marketing__c FROM Opportunity WHERE ID = :oppId LIMIT 1];
            if (opp2.BJ_Marketing__c != null && !opp2.BJ_Marketing__c.equals('') && !opp2.BJ_Marketing__c.equals(' ')) {
                opp.BJ_Marketing__c = opp2.BJ_Marketing__c;
            }
            if (opp2.GZ_Marketing__c != null && !opp2.GZ_Marketing__c.equals('') && !opp2.GZ_Marketing__c.equals(' ')) {
                opp.GZ_Marketing__c = opp2.GZ_Marketing__c;
            }
            if (opp2.HZ_Marketing__c != null && !opp2.HZ_Marketing__c.equals('') && !opp2.HZ_Marketing__c.equals(' ')) {
                opp.HZ_Marketing__c = opp2.HZ_Marketing__c;
            }
            if (opp2.SZ_Marketing__c != null && !opp2.SZ_Marketing__c.equals('') && !opp2.SZ_Marketing__c.equals(' ')) {
                opp.SZ_Marketing__c = opp2.SZ_Marketing__c;
            }
            if (opp2.SH_Marketing__c != null && !opp2.SH_Marketing__c.equals('') && !opp2.SH_Marketing__c.equals(' ')) {
                opp.SH_Marketing__c = opp2.SH_Marketing__c;
            }
            opp.ConvertedFromLead__c = 1002;    //'1002' means that this opportunity is created by EF China sales user new via student opportunity related list
            insert opp;
            return new PageReference('/' + opp.id + '/e?retURL=/' + opp.id);
        } else {
            return page.CanOnlyCreatedOneTimePerDay;
        }        
    }
    
    public List<SelectOption> getSalesTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Renew','Renew'));
        options.add(new SelectOption('Upgrade','Upgrade'));
        options.add(new SelectOption('Downgrade','Downgrade'));
        return options;
    }
    
    public String getSalesType() {
        return salesType;
    }
    
    public void setSalesType(String salesType) { 
        this.salesType = salesType;
    }
    
}