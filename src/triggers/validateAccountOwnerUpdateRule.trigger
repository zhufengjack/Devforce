/*
*    Smart CC and NJ XJK SSO can not change student owner but the new owner profile name is 'China Smart B2B manager'.
*    Smart CSM can not change account owner, which is not in his own school.
*/
trigger validateAccountOwnerUpdateRule on Account (before update) 
{
    if(TriggerContextHelper.isFired)
    {
	User currentUser =  [select Id, Name, Profile.Name, SchoolName__c from User where Id = :UserInfo.getUserId() limit 1];
	String currentUserProfileName = currentUser.Profile.Name;
	String currentSchoolName = currentuser.SchoolName__c;
	
	if(currentUserProfileName == 'EF China Sales User' || currentUserProfileName == 'EF China Sales User New' || currentUserProfileName == 'EF China NJ SSO' || currentUserProfileName == 'EF China Sales Manager new')
	{
		Map<String, String> account2NewOwner = new Map<String, String>();
		Map<String, String> account2OldOwner = new Map<String, String>();
		for(Account acc : trigger.new)
		{
			if(acc.OwnerId != trigger.oldMap.get(acc.Id).OwnerId)
			{
				account2NewOwner.put(acc.Id, acc.OwnerId);
				account2OldOwner.put(acc.Id, trigger.oldMap.get(acc.Id).OwnerId);
			}
		}
		
		Map<String, String> user2ProfileName = new Map<String, String>();
		Map<String, String> user2SchoolName = new Map<String, String>();
		
		List<User> newOwners = [select Id, Profile.Name, SchoolName__c from User where Id in :account2NewOwner.values() Or Id in :account2OldOwner.values()];
		for(User u : newOwners)
		{
			user2ProfileName.put(u.Id, u.Profile.Name);
			user2SchoolName.put(u.Id, u.SchoolName__c);
		}
	 
		for(String accountId : account2NewOwner.keySet())
		{
			String userId = account2NewOwner.get(accountId);
			String oldUserId = account2OldOwner.get(accountId);
			Account tempAccount = trigger.newMap.get(accountId); 
			// Smart CC can not change account owner except the new owner profile name contains 'China Smart B2B manager'.	
			if(!(user2ProfileName.get(userId) == 'EF China Smart B2B Sales Manager') && (currentUserProfileName == 'EF China Sales User' || currentUserProfileName == 'EF China Sales User New' || currentUserProfileName == 'EF China NJ SSO'))
			{
				tempAccount.addError('You are not required to change student owner. Pls check with your Center Manager.');
			}
			// Smart CSM can not change account owner, which is not in his own school.
			if(currentUserProfileName == 'EF China Sales Manager new' && user2SchoolName.get(oldUserId) != currentSchoolName)
			{
				tempAccount.addError('you are not allowed to change other school’s data.');
			}
		}
	}
    }
}