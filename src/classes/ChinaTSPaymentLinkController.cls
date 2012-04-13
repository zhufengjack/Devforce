public class ChinaTSPaymentLinkController
{
    public String OppIdValue {get; set;}
    public String VeriCode 
    {
        get
        {
            String tempCode;
            tempCode = generateAuthenticationKey();
            return tempCode;
        } 
        set;
    }
    
    private static final String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';
    
    private String generateAuthenticationKey()
    {
        if(OppIdValue != null)
        {
            try
            {
                return ChinaTSUtility.getChinaTsSecurityToken(new List<String>{OppIdValue});
            }
            catch(Exception ex){}
        }
        return null;
    }
    
    @isTest
    static void testChinaTSPaymentLinkController()
    {
        ChinaTSPaymentLinkController controller = new ChinaTSPaymentLinkController();
        controller.OppIdValue = '00XO0000000Lxpd';
        controller.generateAuthenticationKey();
        System.assertEquals(controller.generateAuthenticationKey(), controller.VeriCode);
    }
}