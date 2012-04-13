public class EtownServiceHelper 
{
    private static final String securityKey = 'sf@school@123';
    
    public static String getSecurityToken(String[] params)
    {
        String plainText = '';
        if(params != null)
        {
            params.sort();
            params.add(securityKey);
            for(String param : params)
            {
                plainText += param + ':';
            }
            plainText = plainText.substring(0, plainText.length() - 1);
            Blob encryptedText = Crypto.generateDigest('MD5', Blob.valueOf(plainText));
            return EncodingUtil.convertToHex(encryptedText);
        }
        return '';
    }
    
    public static String getSecurityToken(String field, String utcTokenDate)
    {
        return getSecurityToken(new String[] {utcTokenDate, field});
    }
    
    public static List<SelectOption> getLevelCode()
    {
        List<SelectOption> result = new List<SelectOption>();
        result.add(new SelectOption('0A', 'Beginner-Level0A'));
        result.add(new SelectOption('0B', 'Beginner-Level0B'));
        result.add(new SelectOption('1', 'Beginner-Level 1'));
        result.add(new SelectOption('2', 'Elementary-Level 2'));
        result.add(new SelectOption('3', 'Elementary-Level 3'));
        result.add(new SelectOption('4', 'Elementary-Level 4'));
        result.add(new SelectOption('5', 'Intermediate-Level 5'));
        result.add(new SelectOption('6', 'Intermediate-Level 6'));
        result.add(new SelectOption('7', 'Intermediate-Level 7'));
        result.add(new SelectOption('8', 'Upper Intermediate-Level 8'));
        result.add(new SelectOption('9', 'Upper Intermediate-Level 9'));
        result.add(new SelectOption('10', 'Upper Intermediate-Level 10'));
        result.add(new SelectOption('11', 'Advanced-Level 11'));
        result.add(new SelectOption('12', 'Advanced-Level 12'));
        result.add(new SelectOption('13', 'Advanced-Level 13'));
        result.add(new SelectOption('14', 'Upper Advanced-Level 14'));
        return result;
    }
    
    public static String getLevelCode(String text)
    {
    	String result = '';
    	if(text == null || text == '')
    	{
    		result = '0A';
    	}
    	else
    	{
	        for(SelectOption option : getLevelCode())
	        {
	            if(option.getLabel() == text)
	            {
	                result = option.getValue();
	                break;
	            }
	        }
    	}
        return result;
    }
    
    public static String translateDivisionCode(String divisionCode)
    {
        if(divisionCode == null)
        {
            return '';
        }
        else
        {
            return divisionCode.replaceAll('\\s','').replace('_', '');
        }
    }
    
    public static String getRedemptionCode(String name)
    {
        RedemptionCode__c code = RedemptionCode__c.getValues(name);
        if(code != null)
        {
            return code.Code__c;
        }
        else
        {
            return '';
        }
    }
    
    public static List<Map<String, Integer>> getSchoolCodeAndCityId(String schoolString)
    {
      Map<String, Integer> schoolCodeMap = new Map<String, Integer>
      {
         'BJ DFG' => 11,
         'BJ DWL' => 26,
         'BJ DZM' => 19,
         'BJ FXM' => 7,
         'BJ GM1' => 6,
         'BJ KRC' => 34,
         'BJ SYQ' => 23,
         'BJ XZM' => 20,
         'BJ ZGC' => 8,
         'GZ GYQ' => 15,
         'GZ JNX' => 35,
         'GZ JTP' => 12,
         'GZ THB' => 13,
         'GZ TJR' => 33,
         'SH DNR' => 21,
         'SH HHR' => 4,
         'SH HQC' => 25,
         'SH BBB' => 39,
         'SH LJZ' => 3,
         'SH PSQ' => 1,
         'SH WJC' => 16,
         'SH XJH' => 2,
         'SH XZG' => 36,
         'SH ZSP' => 9,
         'SZ CHC' => 28,
         'SZ DWG' => 14,
         'SZ HQB' => 24,
         'SZ NSD' => 22
      };
      Map<String, Integer> cityIdMap = new Map<String, Integer>{'All' => 0, 'SH All' => 1, 'BJ All' => 2, 'GZ All' => 3, 'SZ All' => 4};
      
      List<Map<String, Integer>> resultList = new List<Map<String, Integer>>();
      if(schoolString != null)
      {
           List<String> schoolStringList = schoolString.split(';');
           for(String schoolName : schoolStringList)
           {    
                Map<String, Integer> tempMap = new Map<String, Integer>();
                if(cityIdMap.get(schoolName) != null)
                {    
                     tempMap.put('CityId', cityIdMap.get(schoolName));
                }
                else if(schoolCodeMap.get(schoolName) != null)
                {
                     tempMap.put('SchoolCode', schoolCodeMap.get(schoolName));
                }
                if(tempMap.size() > 0)
                {
                     resultList.add(tempMap);
                }
           }
      }
      return resultList;
    }
    
    @isTest
    static void testGetSecurityToken()
    {
        String username = 'acmename';
        String utcTokenDate = DateTime.now().format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        String result = EtownServiceHelper.getSecurityToken(username, utcTokenDate);
        System.assert(result != null);
    }
    
    @isTest
    static void testGetLevelCode()
    {
        System.assert(getLevelCode() != null);
        System.assertEquals('', getLevelCode('Inherited'));
    }
    
    @isTest
    static void testGetSchoolCodeAndCityId()
    {
        String schools = 'GZ JTP;SH All;SH XJH';
        System.assertEquals(3, EtownServiceHelper.getSchoolCodeAndCityId(schools).size());
    }
}