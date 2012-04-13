/*
 * a helper class for custom setting called SchoolInfo
 */
public class SchoolInfoHelper
{

	public static String getBU(String name)
	{
		String schoolName = praseSchoolName(name);
		return (SchoolAddress__c.getInstance(schoolName) != null) ? SchoolAddress__c.getInstance(schoolName).BU__c : null;
	}

	//gets Address from schoolInfo according school name
	public static String getAddress(String name)
	{
		String schoolName = praseSchoolName(name);
		return (SchoolAddress__c.getInstance(schoolName) != null) ? SchoolAddress__c.getInstance(schoolName).Address__c : null;
	}

	public static SchoolAddress__c getSchoolAddressObject(String name)
	{
		String schoolName = praseSchoolName(name);
		return SchoolAddress__c.getInstance(schoolName);
	}

	//replace ' ' to '_', such as 'BJ YYC' to 'BJ_YYC'
	public static String praseSchoolName(String name)
	{
		String schoolName;
		if(name != null)
		{
			schoolName = name.replace(' ','_');
		}
		return schoolName;
	}

	@isTest
	static void testSchoolInfoHelper()
	{
		SchoolAddress__c schoolAddress = new SchoolAddress__c(Name = 'BJ_DZMTest', Address__c = 'beijing', Code__c = 10, Bu__c = 'smart', IsLeadToShowSchool__c = true);
		insert schoolAddress;
		system.assertEquals('smart', getBU('BJ DZMTest'));
		system.assertEquals('beijing', getAddress('BJ DZMTest'));
		system.assertEquals('BJ_DZMTest', getSchoolAddressObject('BJ DZMTest').Name);
	}
}