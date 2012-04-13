/*
*   This controller for page "TS Opportuntity Query". Etown will visit this page and post two parameters(opid and vcode) to this page.
*   Our program will use oppid to query opp number and offerid(couponCode).
*   If it fails, a error code will be return.
*   If successful, we will return "opNumber(opp-907652)&couponCode".   
*/
public class TSOpportunityQueryController 
{
    public String ResultMessage {get; set;}
    
    public TSOpportunityQueryController()
    {
        String oppId = ApexPages.currentPage().getParameters().get('opid');
        String vcodeValue = ApexPages.currentPage().getParameters().get('vcode');
        List<String> parameters = new List<String>{oppId};
        try
        {
            //ChinaTsPaymentProcessUtility utility = new ChinaTsPaymentProcessUtility();
            Boolean verificationPassed = ChinaTSUtility.validateSecuriteKey(parameters, vcodeValue);
            if(verificationPassed)
            {
                List<Opportunity> opps = [select Id, Opportunity_Number__c, Location__c, (select Id, PricebookEntry.Product2.OfferId__c from OpportunityLineItems) from Opportunity where Id = :oppId];
                if(opps.size() <= 0)
                {
                    ResultMessage = 'INVALIDID';
                }
                else
                {
                    if(opps[0].OpportunityLineItems.size() > 0)
                    {
                        String appLocation = judgeAppLocation(opps[0].Location__c);
                        ResultMessage = opps[0].Opportunity_Number__c + '&' + opps[0].OpportunityLineItems[0].PricebookEntry.Product2.OfferId__c + '&' + appLocation; // Why pass opportunity number? not id? 
                    }
                    else
                    {
                        ResultMessage = 'NOPRODUCT';
                    }
                }
            }
            else
            {
               ResultMessage = 'INVALIDVCODE';
            }
            
        }
        catch(Exception ex)
        {
            ResultMessage = 'UNKNOWNEXCEPTION';
        }
    }
    
    private String judgeAppLocation(String location)
    {
        Map<String, String> appLocationMap = new Map<String, String>{'Tele-sale GZ' => 'GuangZhou', 'Tele-sale SH' => 'ShangHai'};
        return appLocationMap.get(location);
    }
    
    @isTest
    static void testTSOpportunityQueryController()
    {
        Opportunity testOpp = new Opportunity(Name = 'test', Initial_Appt_Date__c = Datetime.now(), CloseDate = Date.today().addDays(10), StageName = 'Set Appt', China_Sales_Type__c = 'New');
        insert testOpp;
        String testOppId = testOpp.Id;
        testOppId = (testOppId.length() > 15)?testOppId.substring(0, 15):testOppId;
        //String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';
        List<String> parameters = new List<String>{testOppId}; 
        String verificationCode = ChinaTSUtility.getChinaTsSecurityToken(parameters);
        PageReference testPage = new PageReference('/apex/TSOpportunityQuery?opid=' + testOppId + '&vcode=' + verificationCode);
        test.setCurrentPage(testPage);
        TSOpportunityQueryController controller = new TSOpportunityQueryController();
        // Test for method judgeAppLocation.
        System.assertEquals('GuangZhou', controller.judgeAppLocation('Tele-sale GZ'));
    }
}