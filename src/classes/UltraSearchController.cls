/**
 * controller for page :UltraSearch
 */
global class UltraSearchController 
{
    private String country;
    
    public UltraSearchController()
    {
        country = getUserCountryName();
    }
    
    public Boolean IsChinaProfile{ get; set; }
    
    public SearchResult getSearchResult()
    {
        SearchResult result = new SearchResult();
        String searchKeyword = ApexPages.currentPage().getParameters().get('keyword');
        if(searchKeyword != null && searchKeyword != '' && searchKeyword.length() > 2)
        {
            searchKeyword  += '*' ;
            List<List<SObject>> searchAccountList = [FIND :searchKeyword IN ALL FIELDS RETURNING Account (Id, Name, Owner.FirstName, OwnerId, BillingState, CreatedDate, Activity_last_modified_date__c where RecordType.Name like :country + '%' )];
            result.Accounts = ((List<Account>)searchAccountList[0]);
            
            List<List<SObject>> searchContactList = [FIND :searchKeyword IN ALL FIELDS RETURNING Contact (Id, Name, Account.Name, AccountId,  Owner.Alias, OwnerId,  CreatedDate, LastModifiedDate where RecordType.Name like :country + '%')];
            result.Contacts = ((List<Contact>)searchContactList[0]);
            
            List<List<SObject>> searchOpportunityList = [FIND :searchKeyword IN ALL FIELDS RETURNING Opportunity (Id, Name, Account.Name, AccountId, Location__c, StageName, Owner.Name, OwnerId, CreatedDate, Initial_Appt_Date__c, First_Visit__c, LastmodifiedDate where RecordType.Name like :country + '%')];            
            result.Opportunities = ((List<Opportunity>)searchOpportunityList[0]);

            List<List<SObject>> searchLeadList = [FIND :searchKeyword IN ALL FIELDS RETURNING Lead (Id, Name, School_of_Interest__c, CN_City__c, Status, Partner_Ad_Channel__c, CreatedDate, LastmodifiedDate where RecordType.Name like :country + '%')];            
            result.Leads = ((List<Lead>)searchLeadList[0]);
        }
        else
        {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Your search term must have 2 or more characters.'));
        }
        return result;
    }
    
    private static String getUserCountryName()
    {
        String countryName = 'Unkown';
        List<UserRole> roles = [select Name from UserRole where Id = :UserInfo.getUserRoleId()];
        if(roles.size() > 0)
        {
            String roleName = roles[0].Name;
            Integer index = roleName.indexOf(' ');
            if(roleName == 'Englishtown')
            {
                countryName = '';
            }
            else if(index != -1)
            {
                countryName = roleName.substring(0, index);
            }
            
        }
        return countryName;
    }
    
    @RemoteAction 
    global static String getLeadConvertInfo(String leadId)
    {
        String message;
        Integer convertMethod = LeadConvertHelper.getConvertMethod(leadId);

        if(convertMethod == 0)
        {
            message = 'No, you can\'t convert.';
        }
        else
        {
            message = 'Yes, you can convert.';
        }
        return message; 
    }
    
     
    public class SearchResult
    {
        public SearchResult()
        {
            Accounts = new List<Account>();
            Contacts = new List<Contact>();
            Opportunities = new List<Opportunity>();
            Leads = new List<Lead>();
        }
        public List<Account> Accounts { get; set; }
        public List<Contact> Contacts { get; set; }
        public List<Opportunity> Opportunities { get; set; }
        public List<Lead> Leads { get; set; }
    }
    
    @isTest
    static void testController()
    {
        Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
        Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
        insert testOpportunity1;
        PageReference testPage = new PageReference('/UltraSearch?keyword=acme');
        test.setCurrentPage(testPage);
        UltraSearchController controller = new UltraSearchController();
        SearchResult result = controller.getSearchResult();
        system.assert(result.Accounts != null);
        system.assert(result.Contacts != null);
        system.assert(result.Opportunities != null);
        system.assert(result.Leads != null);
        Lead lead = new Lead(LastName='acme', Company='acme');
        insert lead;
        system.assertEquals(UltraSearchController.getLeadConvertInfo(String.valueOf(lead.Id)), 'Yes, you can convert.');
    }
}