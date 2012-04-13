// Sends email to csm.
trigger SendEmailToCSM on Opportunity (after update) 
{
    /*Map<String, String> opp2NewOwner = new Map<String, String>();
    Map<String, String> opp2OldOwner = new Map<String, String>();
    Map<String, List<String>> oldOwner2OppIs = new Map<String, List<String>>();

    for(Opportunity opp : trigger.new)
    {
        if(opp.OwnerId != trigger.oldMap.get(opp.Id).OwnerId)
        {
            opp2NewOwner.put(opp.Id, opp.OwnerId);
            opp2OldOwner.put(opp.Id, trigger.oldMap.get(opp.Id).OwnerId);
        }
    }
    
    if(opp2OldOwner.size() > 0)
    {
        Map<String, User> userMap = new Map<String, User>();
        List<User> owners = [select Id, Profile.Name, UserRole.Name, SchoolName__c from User where Id in :opp2NewOwner.values() or Id in :opp2OldOwner.values()];
        for(User oppOwner : owners)
        {
            userMap.put(oppOwner.Id, oppOwner);
        }
        
        Map<String, List<String>> school2Opps = new Map<String, List<String>>();
        for(String oppId : opp2NewOwner.keySet())
        {
            User oldOwner = userMap.get(opp2OldOwner.get(oppId));
            User newOwner = userMap.get(opp2NewOwner.get(oppId));
            if((oldOwner.Profile.Name == 'EF China Sales User' || oldOwner.Profile.Name == 'EF China Sales User New') && newOwner.Profile.Name == 'EF China Smart B2B Sales Manager')
            {
                if(school2Opps.containsKey(oldOwner.SchoolName__c))
                {
                    school2Opps.get(oldOwner.SchoolName__c).add(oppId);
                }
                else
                {
                    List<String> oppIds = new List<String>();
                    oppIds.add(oppId);
                    school2Opps.put(oldOwner.SchoolName__c, oppIds);
                }
            }
        }

        //Sends an email to Center sales manager of this school, whose role equals China XXX Sales manager and contain the same school name with B2C Sales.
        List<User> managerUsers = [select Id, Name, Alias, Email, SchoolName__c from User where SchoolName__c in :school2Opps.keySet() and Profile.Name = 'EF China Sales Manager new' and IsActive = true];
        if(managerUsers.size() > 0)
        {
            Account tempAccount = new Account(Name = 'temp account');
            insert tempAccount;
            Map<String, Contact> user2Contact = new Map<String, Contact>();
            for(User tempUser : managerUsers)
            {
                user2Contact.put(tempUser.Id, new contact(LastName = tempUser.Alias, AccountId = tempAccount.Id, Email = tempUser.Email));  //tempUser.Email
            }
            insert user2Contact.values();
            
            String emailTemplateName = 'CN Smart B2C to B2B deal reminder';
            List<EmailTemplate> templates = [select Id from EmailTemplate where Name = :emailTemplateName];
            String emailTemplateId;
            if(templates.size() > 0)
            {
                emailTemplateId = templates[0].Id;
            }
            List<Messaging.Singleemailmessage> mailList = new List<Messaging.Singleemailmessage>();
            for(User managerUser : managerUsers)
            {
                Contact currentContact = user2Contact.get(managerUser.Id);
                for(String oppId : School2Opps.get(managerUser.SchoolName__c))
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
            delete tempAccount;
        }
    }*/
}