/*
 * Middle layer of EtownDivision__c object
 */
public class DivisionSvc 
{
    //updates record if matched with code, otherwise crate a new record 
    public static void upsertDivision(EtownMemberInfoServiceHelper.CorporateInfo corporateInfo)
    {
        if(corporateInfo != null)
        {
            List<EtownDivision__c> divisions = [select Id, Name, Code__c from EtownDivision__c where Code__c != null and Code__c = :corporateInfo.DivisionCode limit 1];
            if(divisions.size() > 0)
            {
                EtownDivision__c division = divisions[0];
                if(corporateInfo.DivisionCode != null && division.Name != corporateInfo.DivisionName)
                {
                    division.Name = corporateInfo.DivisionName;
                    division.CorporateCode__c = corporateInfo.CorporateCode;
                    try
                    {
                        update division;
                    }
                    catch(EtownException ex)
                    {
                        throw(new EtownException(ex.getMessage(), 0));
                    }
                }
            }
            else
            {
                if(corporateInfo.DivisionCode != null)
                {
                    EtownDivision__c division = new EtownDivision__c();
                    division.Name = corporateInfo.DivisionName;
                    division.Code__c = corporateInfo.DivisionCode;
                    division.CorporateCode__c = corporateInfo.CorporateCode;
                    try
                    {
                        insert division;
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
    static void testDivisionSvc()
    {
    	 EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo = new  EtownMemberInfoServiceContract.FullMemberInfo();
    	 fullMemberInfo.CorporateInfo = new EtownMemberInfoServiceContract.CorporateInfo();
    	 fullMemberInfo.CorporateInfo.DivisionCode = 'acmecc';
    	 fullMemberInfo.CorporateInfo.DivisionName = 'acme';
    	 EtownMemberInfoServiceHelper.CorporateInfo corporateInfo = new  EtownMemberInfoServiceHelper.CorporateInfo(fullMemberInfo.CorporateInfo);
    	 DivisionSvc.upsertDivision(corporateInfo);
    	 
    	 fullMemberInfo.CorporateInfo.DivisionName = 'newAcme';
    	 corporateInfo = new  EtownMemberInfoServiceHelper.CorporateInfo(fullMemberInfo.CorporateInfo);
    	 DivisionSvc.upsertDivision(corporateInfo);
    }
}