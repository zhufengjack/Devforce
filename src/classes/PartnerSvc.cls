/*
 * Middle layer of EtownPartner__c object
 */
public class PartnerSvc 
{
    //updates record if matched with code, otherwise crate a new record
    public static void upsertPartner(EtownMemberInfoServiceHelper.PartnerInfo partnerInfo)
    {
        if(partnerInfo != null)
        {
            List<EtownPartner__c> partners = [select Id, Name, Code__c, CountryCode__c, ServerName__c, BusinessUnit__c from EtownPartner__c where Code__c != null and Code__c = :partnerInfo.PartnerCode limit 1];
            if(partners.size() > 0)
            {
                EtownPartner__c partner = partners[0];
                if(partnerInfo.PartnerCode != null && (partner.Name != partnerInfo.TrackName || partner.CountryCode__c != partnerInfo.CountryCode || partner.ServerName__c != partnerInfo.ServerName || partner.BusinessUnit__c != partnerInfo.BusinessUnit))
                {
                    partner.Name = partnerInfo.TrackName;
                    partner.CountryCode__c = partnerInfo.CountryCode;
                    partner.ServerName__c = partnerInfo.ServerName;
                    partner.BusinessUnit__c = partnerInfo.BusinessUnit; 
                    try
                    {
                        update partner;
                    }
                    catch(EtownException ex)
                    {
                        throw(new EtownException(ex.getMessage(), 0));
                    }
                }
            }
            else
            {
                if(partnerInfo.PartnerCode != null)
                {
                    EtownPartner__c partner = new EtownPartner__c();
                    partner.Name = partnerInfo.TrackName;
                    partner.Code__c = partnerInfo.PartnerCode;
                    partner.CountryCode__c = partnerInfo.CountryCode;
                    partner.ServerName__c = partnerInfo.ServerName;
                    partner.BusinessUnit__c = partnerInfo.BusinessUnit; 
                    try
                    {
                        insert partner;
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
    static void testPartnerSvc()
    {
    	 EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo = new  EtownMemberInfoServiceContract.FullMemberInfo();
    	 fullMemberInfo.PartnerInfo = new EtownMemberInfoServiceContract.PartnerInfo();
    	 fullMemberInfo.PartnerInfo.BusinessUnit = 'acmebu';
    	 fullMemberInfo.PartnerInfo.CountryCode = 'acmecc';
    	 fullMemberInfo.PartnerInfo.PartnerCode = 'acmepc';
    	 fullMemberInfo.PartnerInfo.ServerName = 'acme';
    	 fullMemberInfo.PartnerInfo.TrackName = 'acme';
    	 EtownMemberInfoServiceHelper.PartnerInfo partnerInfo = new  EtownMemberInfoServiceHelper.PartnerInfo(fullMemberInfo.PartnerInfo);
    	 PartnerSvc.upsertPartner(partnerInfo);
    	 
    	 fullMemberInfo.PartnerInfo.TrackName = 'newAcme';
    	 partnerInfo = new  EtownMemberInfoServiceHelper.PartnerInfo(fullMemberInfo.PartnerInfo);
    	 PartnerSvc.upsertPartner(partnerInfo);
    }
}