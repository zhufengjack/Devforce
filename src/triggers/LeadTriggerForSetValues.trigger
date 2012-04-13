//sets LeadSource, InitialAppDate, CNCity, CNProvince and School
trigger LeadTriggerForSetValues on Lead (before insert) 
{
    if(UserInfo.getProfileId().contains('00e40000001BNBS'))
    {
        String currentUserRoleName;
        for(UserRole role : [Select Name From UserRole where Id =:UserInfo.getUserRoleId() limit 1]) 
        {
            currentUserRoleName = role.Name; 
        } 
        for(Lead currLead : Trigger.new)
        {
            currLead.LeadSource = 'Direct to center';
            currLead.Initial_Appt_Date__c = Datetime.now();
            if(currentUserRoleName != null && currentUserRoleName.toLowerCase().contains('china') && currentUserRoleName.toLowerCase().contains('booking officer'))
            {
                String strProvince  = '';
                String strCity = '';
                if(MatchInfo(currentUserRoleName, 'SH_'))
                {
                    strProvince = 'cn_sh';
                    strCity = 'Shanghai';
                }
                if(MatchInfo(currentUserRoleName, 'BJ_'))
                {
                    strProvince = 'cn_bj';
                    strCity = 'Beijing';
                }
                if(MatchInfo(currentUserRoleName, 'SZ_'))
                {
                    strProvince = 'cn_gd';
                    strCity = 'Shenzhen';
                }
                if(MatchInfo(currentUserRoleName, 'GZ_'))
                {
                    strProvince = 'cn_gd';
                    strCity = 'Guangzhou';
                }
                currLead.CN_City__c = strCity;
                currLead.CN_Province_Name__c = strProvince;
                currLead.School_of_Interest__c = GetSchool(currentUserRoleName);
            }
        }
    }
    
    private Boolean MatchInfo(String outterString, String innerString)
    {
        if(outterString.contains(innerString))
        {
            return true;
        }
        return false;
    }
     private String GetSchool(String roleName)
     {
        List<String> subStrings = roleName.split(' ');
        String targetString = subStrings[1];
        return targetString.replace('_', ' ');
     }   
}