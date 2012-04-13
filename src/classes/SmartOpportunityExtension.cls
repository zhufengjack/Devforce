public class SmartOpportunityExtension {
    
    //public List<Opportunity> opportunities;
    public String accountId;
    
    public String getAccountId() {
        return accountId;
    } 
    
    public void setAccountId (String accId) {
        accountId = accId;
    }
    
    /*public ApexPages.StandardSetController setCon {
        get {
            if (setCon == null) {
                setCon = new ApexPages.StandardSetController(
                    [SELECT Id, Name, CreatedById, CreatedDate FROM Opportunity Order By CreatedDate]);
            }
            return setCon;
        }
        set;
    }*/
    
    public Opportunity getRecentOpportunity() {
        return [SELECT Id, Name, StageName, LeadSource, Phone2__c, Mobile__c, Email__c, Partner_Ad_Channel__c FROM Opportunity WHERE AccountId = :getAccountId() ORDER BY CreatedDate DESC Limit 1];
    }
    
    public SmartOpportunityExtension (ApexPages.StandardController stdController) {
        //opportunities = (List<Opportunity>) stdSetController.getRecords();
        
    }
    
    public String getURL() {
        return ApexPages.currentPage().getURL();
    }
    
    public PageReference verify() {
        //get the original retURL which include the account's id
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
		String accountID;
		if(retURL.length() >= 16)
		{
			accountID = retURL.substring(1,16);
		}
		else
		{
			accountID = retURL.substring(1);
		}        
        //set this accountId to the member variable
        setAccountId(accountID);
                               
        //if there is no previous opportunity exist under a student, prompt an error message to the sales
        Opportunity[] opps = [SELECT Name FROM Opportunity WHERE AccountId = :accountID];
        if (opps.size() == 0 ) {
            PageReference pr = page.NoPreviousOpportunityExist;
            pr.getParameters().put('retURL',getAccountId());
            return pr;
        } 
        
        //can only create an opportunity for one student every day
        Opportunity[] opps2 = [SELECT Name FROM Opportunity WHERE AccountId = :accountID AND CreatedDate = Today AND ConvertedFromLead__c != 1001];
        if (opps2.size() > 0) {
            PageReference pr = page.CanOnlyCreatedOneTimePerDay;
            pr.getParameters().put('retURL',getAccountId());
            return pr;
        }
        
        //verify if the stage of the most closest opportunity is 'Closed Won', if not, prompt an error message
        Opportunity opp = getRecentOpportunity();
        if (opp != null && opp.stageName != 'Closed Won') {
            PageReference pr = page.RecentOpportunityNotClosedWon;
            pr.getParameters().put('retURL',getAccountId());
            return pr;
        }
        
        PageReference pr = page.ChooseChinaSalesType;
        pr.getParameters().put('accId',getAccountId());
        pr.getParameters().put('name',getRecentOpportunity().Name);
        pr.getParameters().put('opk',getRecentOpportunity().Id);       
        pr.getParameters().put('p2',getRecentOpportunity().Phone2__c);        
        pr.getParameters().put('Mobile',getRecentOpportunity().Mobile__c);
        pr.getParameters().put('email',getRecentOpportunity().Email__c);
        pr.getParameters().put('ls', getRecentOpportunity().LeadSource);
        pr.getParameters().put('PAC', getRecentOpportunity().Partner_Ad_Channel__c);        
        return pr;
        
    }
}