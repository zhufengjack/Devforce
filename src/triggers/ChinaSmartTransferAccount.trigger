trigger ChinaSmartTransferAccount on Account (after update) {
  /**
  *if current user's profile is EF China Smart Booking Officer,When our student(account) came to our center,
  *then this student told our booking office his mobile or email. When our booking officer change owner from TM(CCA from Call Center) to
  * CC who is sales in center for this student. this trigger will change opportunity owner automatically to sales.
  */
    Account accNew = Trigger.new[0];
    Account accOld = Trigger.old[0];
    //if(String.valueOf(UserInfo.getProfileId()).contains('00eR0000000DzFl'))  // Sandbox env 00eR0000000DzFl
    if(String.valueOf(UserInfo.getProfileId()).contains('00e40000001BNBS'))    // Sandbox env 00eR0000000DzFl
    {
        if(accNew.OwnerId != accOld.OwnerId)//Change Owner
        {
        	Id currentUserId = (Id)Userinfo.getUserId();
        	Set<Id> userIds = new Set<Id>{accNew.OwnerId, accOld.OwnerId, currentUserId};
        	User newUser, oldUser, currentUser;
        	
        	List<User> users = [select Id, ProfileId, UserRoleId, UserRole.Name from User where Id in :userIds];
        	for(User tempUser : users)
        	{
        		if(tempUser.Id == accNew.OwnerId)
        		{
        			newUser = tempUser;
        		}
        		if(tempUser.Id == accOld.OwnerId)
        		{
        			oldUser = tempUser;
        		}
        		 if(tempUser.Id == currentUserId)
        		{
        			currentUser = tempUser;
        		}
        	}
           
            //****************************************************
            //BY Jimmy Yang 01 ---- start
            
            //get current user's rolename
            String currentUserRoleName = currentUser.UserRole.Name;
                
            //get the newly assigned user's rolename
            String newUserRoleName =	newUser.UserRole.Name; //newUserRole.name;

            //get the school names of the current user and the new one
            String schoolName1 = currentUserRoleName.substring(0, currentUserRoleName.indexof(' ', 6));
            STring schoolName2 = newUserRoleName.substring(0, currentUserRoleName.indexof(' ', 6));
            
            if (!schoolName1.equals(schoolName2)) {
                accNew.addError('You can only change to CC in your school. 你只可以分配给本学校的销售。');
            }
                        
            //BY Jimmy Yang 01 ---- end
            //*****************************************************
            
                
            //Check new owner's profile and old owner's profile
            //if old owner is a sales, can not change owner
            if(String.ValueOf(oldUser.ProfileId).contains('00e40000000j20V'))       //pro env 00e40000000j20V
            {
                accNew.addError('You can not change the owner of this account.');

            }
            else
            {
                if(String.ValueOf(newUser.ProfileId).contains('00e40000000j20V'))       //pro env 00e40000000j20V
                {
                    List<Opportunity> opps = [select Id,StageName from Opportunity where AccountId=:accNew.Id and RecordTypeId='0124000000099sY' and StageName!='Expired'];
                    if(opps != null && opps.size()>0)
                    {
                        opps[0].StageName = 'Showed Up - Followup';
                        update opps[0];
                    }
                }
            }
            
            //*******************************************************************
            //BY Jimmy Yang 02 ---- start
            
            //transfer related event which satisifying certain condition
            List<Event> events = [SELECT Id, OwnerId, Subject, Appt_Status__c FROM Event WHERE AccountId = :accOld.Id];
            List<Event> sEvents = new List<Event>();
            if (events != null && events.size() > 0) {
                for ( Event event : events) {
                    if (event.Subject.contains('Sales Demo') && event.Appt_Status__c == 'Scheduled') {
                        event.OwnerId = accNew.OwnerId;
                        sEvents.add(event);
                    }
                }
            }
            update sEvents; 
            
            //BY Jimmy Yang 02 ---- End
            //*******************************************************************
        }
    }
}