/*
 * Middle layer of EtownCorporate__c object
 */
public class CorporateSvc 
{
    //updates record if matched with code, otherwise crates a new record
    public static void upsertCorporate(EtownMemberInfoServiceHelper.CorporateInfo corporateInfo)
    {
        if(corporateInfo != null)
        {
            List<EtownCorporate__c> corporates = [select Id, Name, Code__c from EtownCorporate__c where Code__c != null and Code__c = :corporateInfo.CorporateCode limit 1];
            if(corporates.size() > 0)
            {
                EtownCorporate__c corporate = corporates[0];
                if(corporateInfo.CorporateCode != null && corporate.Name != corporateInfo.CorporateName)
                {
                    corporate.Name = corporateInfo.CorporateName;
                    try
                    {
                        update corporate;
                    }
                    catch(EtownException ex)
                    {
                        throw(new EtownException(ex.getMessage(), 0));
                    }
                }
            }
            else
            {
                if(corporateInfo.CorporateCode != null)
                {
                    EtownCorporate__c corporate = new EtownCorporate__c();
                    corporate.Name = corporateInfo.CorporateName;
                    corporate.Code__c = corporateInfo.CorporateCode;
                    try
                    {
                        insert corporate;
                    }
                    catch(EtownException ex)
                    {
                        throw(new EtownException(ex.getMessage(), 0));
                    }
                }
            }
        }
    }
    
    @isTest
    static void testCorporateSvc()
    {
    	 EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo = new  EtownMemberInfoServiceContract.FullMemberInfo();
    	 fullMemberInfo.CorporateInfo = new EtownMemberInfoServiceContract.CorporateInfo();
    	 fullMemberInfo.CorporateInfo.CorporateCode = 'acmecc';
    	 fullMemberInfo.CorporateInfo.CorporateName = 'acme';
    	 EtownMemberInfoServiceHelper.CorporateInfo corporateInfo = new  EtownMemberInfoServiceHelper.CorporateInfo(fullMemberInfo.CorporateInfo);
    	 CorporateSvc.upsertCorporate(corporateInfo);
    	 
    	 fullMemberInfo.CorporateInfo.CorporateName = 'newAcme';
    	 corporateInfo = new  EtownMemberInfoServiceHelper.CorporateInfo(fullMemberInfo.CorporateInfo);
    	 CorporateSvc.upsertCorporate(corporateInfo);
    }
}