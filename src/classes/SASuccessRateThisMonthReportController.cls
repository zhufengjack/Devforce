/*
 * Controller of page SASuccessRateThisMonthReport
 */
public with sharing class SASuccessRateThisMonthReportController 
{
    public SASuccessRateThisMonthReportController()
    {
        ApexPages.currentPage().getHeaders().put('X-UA-Compatible', 'IE=EmulateIE7');
    }
    
    public Decimal SuccessRate
    {
        get
        {
            Decimal result = 0;
            Integer accomplishedCount = [select count() from Task where ActivityDate=THIS_MONTH and OwnerId=:UserInfo.getUserId() and Status='Accomplished' and RecordType.Name='Study Advise'];
            Integer unaccomplishedCount = [select count() from Task where ActivityDate=THIS_MONTH and OwnerId=:UserInfo.getUserId() and Status='Unaccomplished' and Attempt__c=3 and RecordType.Name='Study Advise'];
            if(accomplishedCount + unaccomplishedCount > 0)
            {
                result = Math.round(accomplishedCount  * 1.0 / (accomplishedCount + unaccomplishedCount)* 1000) / 10.0;
            }
            return result;
        }
    }
    
    @isTest
    static void testSASuccessRateThisMonthReportController()
    {
        SASuccessRateThisMonthReportController controller = new SASuccessRateThisMonthReportController();
        Decimal rate = controller.SuccessRate;
    }
}