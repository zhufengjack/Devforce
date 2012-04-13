/*
*   Smart CC can not change opportunity owner except the new owner profile name contains 'China Smart B2B manager';
*   If an Opportunity transferred from school sales to B2B, Updates field 'B2C_Sales_Name__c' and 'B2C_School_Name__c';
*/
trigger validateOpportunityOwnerUpdateRule on Opportunity (before update) 
{
     String currentUserProfileName = [select Id, Name from Profile where Id = :Userinfo.getProfileId() limit 1].Name;
     
     Map<String, String> opp2OldOwner = new Map<String, String>();
     Map<String, String> opp2NewOwner = new Map<String, String>();
     for(Opportunity opp : trigger.new)
     {
        if(opp.OwnerId != trigger.oldMap.get(opp.Id).OwnerId)
        {
            opp2OldOwner.put(opp.Id, trigger.oldMap.get(opp.Id).OwnerId);
            opp2NewOwner.put(opp.Id, opp.OwnerId);
        }
     }

     List<User> owners = [select Id, Name, Profile.Name, UserRole.Name, SchoolName__c from User where Id in :opp2NewOwner.values() Or Id in :opp2OldOwner.values()];
     Map<String, User> userMap = new Map<String, User>();
     
     for(User u : owners)
     {
        userMap.put(u.Id, u);
     }
    
     //Smart CC can not change opportunity owner except the new owner profile name contains 'China Smart B2B manager'.  
     if(currentUserProfileName == 'EF China Sales User' || currentUserProfileName == 'EF China Sales User New')
     {    
         for(String oppId : opp2NewOwner.keySet())
         {
            if(!(userMap.get(opp2NewOwner.get(oppId)).Profile.Name == 'EF China Smart B2B Sales Manager'))
            {
                trigger.newMap.get(oppId).addError('You are not allowed to change opportunity owner. Pls check with your CM.');
            }
         }
     }
    
    // Updates field 'B2C_Sales_Name__c' and 'B2C_School_Name__c'.
     for(String oppId : opp2OldOwner.keySet())
     {
        User tempUser = userMap.get(opp2OldOwner.get(oppId));
        if((tempUser.Profile.Name == 'EF China Sales User' || tempUser.Profile.Name == 'EF China Sales User New') && userMap.get(opp2NewOwner.get(oppId)).Profile.Name == 'EF China Smart B2B Sales Manager')
        {  
            trigger.newMap.get(oppId).B2C_Sales_Name__c = tempUser.Id;
            trigger.newMap.get(oppId).B2C_School_Name__c = (tempUser.SchoolName__c != null && tempUser.SchoolName__c != '') ? tempUser.SchoolName__c.replace('_', ' ') : null ;
        }
     }
}