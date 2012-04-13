public class ChooseChinaSalesType { 
    String salesType = null;
    
    public PageReference createOpportunity() {
        String accId = ApexPages.currentPage().getParameters().get('accId');        
        String oppId = ApexPages.currentPage().getParameters().get('opk');
        System.System.debug('****** accId = ' + accId + '****** : oppId = ' + oppId + '******');
        
        if (accid != null && !accId.equals('') && !accId.equals(' ')) {
            Opportunity recentOpp = [SELECT Id, Name, LeadSource, Phone2__c, Mobile__c, Email__c, Partner_Ad_Channel__c FROM Opportunity WHERE AccountId = :accId ORDER BY CreatedDate DESC Limit 1];
            Opportunity opp = new Opportunity();
            opp.AccountId = accId;
            opp.Name = recentOpp.Name;          
            opp.LeadSource = recentOpp.LeadSource;
            opp.Phone2__c = recentOpp.Phone2__c;
            opp.Mobile__c = recentOpp.Mobile__c;
            opp.Email__c = recentOpp.Email__c;
            opp.Partner_Ad_Channel__c = recentOpp.Partner_Ad_Channel__c;
            opp.China_Sales_Type__c = getSalesType();           
            opp.Initial_Appt_Date__c = System.now();
            opp.CloseDate = System.today();
            opp.StageName = 'Set Appt';
               
            /*if ( opp.China_Sales_Type__c == '' || opp.China_Sales_Type__c == ' ' || opp.China_Sales_Type__c == null) {
                ApexPages.Message dupeMsg = new ApexPages.Message(ApexPages.Severity.ERROR, '请选择类型');
                ApexPages.addMessage(dupeMsg);
                return null;           
            } */
            oppId = recentOpp.Id;
            List<Opportunity> opps = [SELECT Id FROM Opportunity WHERE AccountId = :accId AND CreatedDate = Today AND ConvertedFromLead__c != 1001];
            if ( opps.size() == 0 ) {
                Opportunity opp2 = [SELECT BJ_Marketing__c, GZ_Marketing__c, HZ_Marketing__c, SZ_Marketing__c, SH_Marketing__c,Mini_EAST_Local_Marketing__c,Mini_South_Local_Marketing__c,Mini_West_Local_marketing__c,TS_Local_Marketing__c FROM Opportunity WHERE ID = :oppId LIMIT 1];
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
                opp.Mini_EAST_Local_Marketing__c=opp2.Mini_EAST_Local_Marketing__c;
                opp.Mini_South_Local_Marketing__c=opp2.Mini_South_Local_Marketing__c;
                opp.Mini_West_Local_marketing__c=opp2.Mini_West_Local_marketing__c;
                opp.TS_Local_Marketing__c=opp2.TS_Local_Marketing__c;
                
                opp.ConvertedFromLead__c = 1002;    //'1002' means that this opportunity is created by EF China sales user new via student opportunity related list
                insert opp;
                return new PageReference('/' + opp.id + '/e?retURL=/' + opp.id );
            } else {
                return page.CanOnlyCreatedOneTimePerDay;
            }       
        }
        return null;   
    }
    
    public List<SelectOption> getSalesTypes() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Upgrade 1','Upgrade 1'));
        options.add(new SelectOption('Upgrade 2','Upgrade 2'));
        options.add(new SelectOption('Upgrade 3','Upgrade 3'));
        options.add(new SelectOption('Renewal','Renewal'));
        options.add(new SelectOption('Double Pay','Double Pay'));
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