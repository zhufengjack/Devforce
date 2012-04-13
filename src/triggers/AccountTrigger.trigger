trigger AccountTrigger on Account (before insert, after update, before delete) {
    if(Trigger.isAfter)
    {
    String str = 'Account';
    if(Trigger.isUpdate)
    {
        Account accNew = Trigger.new[0];
        Account accOld = Trigger.old[0];
        if(String.valueOf(UserInfo.getProfileId()).contains('00e40000001BNBS'))  // Live profile is Booking officer
        {
            if(accNew.OwnerId != accOld.OwnerId)//Change Owner
            {
                List<User> usersNew = [select Id, ProfileId from User where Id=:accNew.OwnerId];
                List<User> usersOld = [select Id, ProfileId from User where Id=:accOld.OwnerId];
                //Check new owner's profile and old owner's profile
                //if old owner is a sales, can not change owner
                if(String.ValueOf(usersOld[0].ProfileId).contains('00e40000000j20V'))
                {
                    accNew.addError('You can not change the owner of this account .');

                }
                else
                {
                    if(String.ValueOf(usersNew[0].ProfileId).contains('00e40000000j20V'))
                    {
                        List<Opportunity> opps = [select Id,StageName from Opportunity where AccountId=:accNew.Id and RecordTypeId='0124000000099sY'];
                        if(opps != null && opps.size()>0)
                        {
                            opps[0].StageName = 'Showed Up - Followup';
                            update opps[0];
                        }
                    }
                }
            }
        }
    }
    }
}