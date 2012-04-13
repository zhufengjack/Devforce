//Brazil team leader can only change opportunity owner to his own team.
trigger BrazilTransferOpportunity on Opportunity (before update) 
{
    Set<Id> newOwnerIds = new Set<Id>();
    for(Opportunity opp : Trigger.new)
    {
        Opportunity oldOpp = Trigger.oldMap.get(opp.Id);
        if(opp.OwnerId != oldOpp.OwnerId)   //changing owner
        {
            newOwnerIds.add(opp.OwnerId);
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
            for(Opportunity opp : Trigger.new)
            {
                for(User owner : owners)
                {
                    if(opp.OwnerId == owner.Id)
                    {
                        String newTeamName = owner.UserRole.Name.substring(owner.UserRole.Name.lastIndexOf(' '));  //newTeamName = '(A)', '(B)' or '(C)'
                        if(teamName != newTeamName)
                        {   //only when the teamname of new owner equals teamname of current user, the transfer is allowed.
                            opp.addError('You can only change owner within your team');
                        }
                    }
                }
            }
        }
    }
}