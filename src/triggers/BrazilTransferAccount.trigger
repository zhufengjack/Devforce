//Brazil team leader can only change student owner to his own team.
trigger BrazilTransferAccount on Account (before update) 
{
    Set<Id> newOwnerIds = new Set<Id>();
    for(Account acc : Trigger.new)
    {
        Account oldAccount = Trigger.oldMap.get(acc.Id);
        if(acc.OwnerId != oldAccount.OwnerId)   //changing owner
        {
            newOwnerIds.add(acc.OwnerId);
        }
    }
    if(newOwnerIds.size() > 0)
    {
        List<UserRole> roles = [select Id, Name from UserRole where Id=:UserInfo.getUserRoleId() limit 1];
        String currentUserRole = roles[0].Name;
        if(currentUserRole.contains('Brazil Sales Group'))
        {
            String teamName = currentUserRole.substring(currentUserRole.lastIndexOf(' ')); //teamName = '(A)', '(B)' or '(C)'
        
            List<User> owners = [select Id, UserRole.Name from User where Id in :newOwnerIds];
            for(Account acc : Trigger.new)
            {
                for(User owner : owners)
                {
                    if(acc.OwnerId == owner.Id)
                    {
                        String newTeamName = owner.UserRole.Name.substring(owner.UserRole.Name.lastIndexOf(' '));  //newTeamName = '(A)', '(B)' or '(C)'
                        if(teamName != newTeamName)
                        {   //only when teamName of newOwner equals teamName of current user, the transfer is allowed.
                            acc.addError('You can only change owner within your team');
                        }
                    }
                }
            }
        }
    }
}