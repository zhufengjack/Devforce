/*
*	When a account owner be changed, The related opportunities owner will be changed to the same owner.
*  This trigger will updates field 'B2C_Sales_Name__c' and 'B2C_School_Name__c' when the owner of opportunity changed from cc to b2b manager.
*   Also a email will be sent to csm.
*/
trigger UpdateRelatedOpportunityFields on Account (after update) 
{
	Map<String, String> acc2OldOwner = new Map<String, String>();
    Map<String, String> acc2NewOwner = new Map<String, String>();
	
	Set<String> accountIds = new Set<String>();
	for(Account acc : trigger.new )
	{
		if(acc.OwnerId != trigger.oldMap.get(acc.Id).OwnerId)
		{  
			acc2OldOwner.put(acc.Id, trigger.oldMap.get(acc.Id).OwnerId);
			acc2NewOwner.put(acc.Id, acc.OwnerId);
		}
	}
	//if has owner changed
	if(acc2OldOwner.size() > 0 || acc2NewOwner.size() > 0)
	{
		List<User> accOwners = [select Id, Name, Profile.Name, SchoolName__c from User where (Id in :acc2OldOwner.values() or Id in :acc2NewOwner.values())];
		Map<String, User> id2User = new Map<String, User>();
		for(User u : accOwners)
		{  
			id2User.put(u.Id, u);
		}
		
		for(String accId : acc2NewOwner.keySet())
		{  
			String oldUserProfileName = id2User.get(acc2OldOwner.get(accId)).Profile.Name;
			String newUserProfileName = id2User.get(acc2NewOwner.get(accId)).Profile.Name;
			if(newUserProfileName == 'EF China Smart B2B Sales Manager' && (oldUserProfileName == 'EF China Sales User' || oldUserProfileName == 'EF China Sales User New'))
			{
				 accountIds.add(accId); //changed owner from cc to b2b manager
			}
		}
		
		//transfers all opportunities to the same owner as account, and logs the old owner id, school
		if(accountIds.size() > 0)
		{
			List<Opportunity> relatedOppList = [select Id, B2C_Sales_Name__c, B2C_School_Name__c, AccountId, OwnerId, Owner.Profile.Name, Owner.SchoolName__c from Opportunity where AccountId in :accountIds];
			Map<String, List<String>> schoolName2Opps = new Map<String, List<String>>(); 
			for(Opportunity opp : relatedOppList)
			{
				opp.B2C_Sales_Name__c = acc2OldOwner.get(opp.AccountId);
				String b2cSchoolName = id2User.get(acc2OldOwner.get(opp.AccountId)).SchoolName__c;
				b2cSchoolName = (b2cSchoolName == null) ? '' : b2cSchoolName;
				opp.B2C_School_Name__c = b2cSchoolName.replace('_', ' ');
				opp.OwnerId = acc2NewOwner.get(opp.AccountId);
				String oldSchoolName = id2User.get(acc2OldOwner.get(opp.AccountId)).SchoolName__c;
			 	if(schoolName2Opps.containsKey(oldSchoolName))
			 	{
			 		schoolName2Opps.get(oldSchoolName).add(opp.Id);
			 	}
			 	else
			 	{
			 		List<String> tempList = new List<String>();
			 		tempList.add(opp.Id);
			 		schoolName2Opps.put(oldSchoolName, tempList);
			 	}
			}
			
			update relatedOppList;
			
			//sends email to CSM
			List<User> managerUsers = [select Id, Name, Alias, Email, SchoolName__c from User where SchoolName__c in : schoolName2Opps.keySet() and Profile.Name = 'EF China Sales Manager new' and IsActive = true];
			if(managerUsers.size() > 0)
			{
					Map<String, Contact> user2Contact = new Map<String, Contact>();
					for(User tempUser : managerUsers)
					{
						user2Contact.put(tempUser.Id, new contact(LastName = tempUser.Alias, Email = tempUser.Email));  //tempUser.Email
					}
					insert user2Contact.values();
					
					/*String emailTemplateName = 'CN Smart B2C to B2B deal reminder';
					List<EmailTemplate> templates = [select Id from EmailTemplate where Name = :emailTemplateName];
					String emailTemplateId = '00X90000000cqEp';
					if(templates.size() > 0)
					{
						emailTemplateId = templates[0].Id;
					} */
					
					String emailTemplateId = '00X90000000cqEp';
					List<Messaging.Singleemailmessage> mailList = new List<Messaging.Singleemailmessage>();
					for(User managerUser : managerUsers)
					{
						Contact currentContact = user2Contact.get(managerUser.Id);
						for(String oppId : schoolName2Opps.get(managerUser.SchoolName__c))
						{	
							Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
							mail.setTemplateId(emailTemplateId);
							mail.setTargetObjectId(currentContact.Id);
							mail.setSaveAsActivity(false);
							mail.setWhatId(oppId);
							mailList.add(mail);
						}
					}
					Messaging.sendEmail(mailList);
					
					delete user2Contact.values();
			}	
		}
	}
}