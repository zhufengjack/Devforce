/*
*    This class for china TS course activation.
*/
public class ChinaTSActivateCourseService 
{
    private ChinaTsServiceStub.BasicHttpBinding_ISalesforceService service = new ChinaTsServiceStub.BasicHttpBinding_ISalesforceService();
    private final String eCommerceUsername = 'CommerceSalesforce';
    private final String eCommercePassword = 'so2#6)=|~nzH^';
    
    public ChinaTSActivateCourseService()
    {
       service.timeout_x = 60 * 1000 * 2; //timeout is 2 minute.
       service.Security = new ChinaTSIdentityValidation.Security_element();
       service.Security.UsernameToken = new ChinaTSIdentityValidation.UsernameToken_element();
       service.Security.UsernameToken.Username = eCommerceUsername;
       service.Security.UsernameToken.Password = eCommercePassword;
    }
    
    // Activate course.   
    public Boolean upgradeProduct(String memberId, String offerId, String actualId, String redemptionCode)
    {   
        Boolean result = false;
        if(memberId != null && offerId != null)
        { 
            Integer memberIdValue;
            try
            {
                memberIdValue = Integer.valueOf(memberId);
            }
            catch(Exception ex)
            {
                memberIdValue = 0;
            }
             
            String utcTokenDate = ChinaTSUtility.generateUtcTokenDate(); 
            String securityToken = ChinaTSUtility.getChinaTsSecurityToken(new List<String>{memberId, utcTokenDate}); // should be change.
            ChinaTsServiceAccountInfo.CreateAccountResult webServiceResult;
            ChinaTsServiceAccountInfo.CreateAccountParams accountParams = new ChinaTsServiceAccountInfo.CreateAccountParams();
            ChinaTsServiceMemberInfo.MemberInfo memberInfo = new ChinaTsServiceMemberInfo.MemberInfo();
            memberInfo.Member_id = memberIdValue;
            memberInfo.PartnerCode = 'None';
            accountParams.Member = memberInfo;
            accountParams.RedemptionCode = redemptionCode;
            try
            {
                 webServiceResult = service.CreateAccountForMember(accountParams, utcTokenDate, securityToken);
            }
            catch(Exception ex)
            {
                 throw new UpgradeAndRetryException(ex.getMessage());
            }
           
            if(webServiceResult.IsSucceed == true)
            {
                update new actual__c(Id = actualId, ActivationStatus__c = 'Activated');
                return true;
            }
            else
            {
                throw new UpgradeAndRetryException('Activating failed.Error Code: '+ webServiceResult.ErrorCode);
            }
            
        }
        return result;
    }
    
    public Boolean retryPurchase(Integer memberId, String offerId, String actualId)
    {
        Boolean result = false;
        if(memberId != null && offerId != null)
        {   
            String utcTokenDate = ChinaTSUtility.generateUtcTokenDate(); 
            String securityToken = ChinaTSUtility.getChinaTsSecurityToken(new List<String>{String.valueOf(memberId), utcTokenDate}); // should be change.
            ChinaTsServiceReactivateResult.ReactivateAccountResult webServiceResult;
            try
            {
                 webServiceResult = service.ReactivateAccount(memberId, utcTokenDate, securityToken);
            }
            catch(Exception ex)
            {
                throw new UpgradeAndRetryException('Retrying failed.'+ ex.getMessage());
            }
            
            if(webServiceResult.IsSucceed == true)
            {
                 try
                 {
                     update new actual__c(Id = actualId, Status__c = 'In Progress');
                 }
                 catch(Exception ex)
                 {
                     throw new UpgradeAndRetryException('Update actual failed.');
                 }
                 return true;
            }
            else
            {
                throw new UpgradeAndRetryException('Retrying failed. Error Code: '+ webServiceResult.ErrorCode);
            }
        }
        return result;
    }
    
    public class UpgradeAndRetryException extends Exception {}
    
    @isTest
    static void testChinaTSActivateCourseService()
    {
    	ChinaTSActivateCourseService controller = new ChinaTSActivateCourseService();
        try
        {
            controller.upgradeProduct('232323', 'TEST99999', 'testActualId', 'TEST99999');
        }
        catch(Exception ex){}
        try
        {
            controller.retryPurchase(232323, 'TEST99999', 'testActualId');
        }
        catch(Exception ex){}
    }
}