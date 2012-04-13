/*
 * sets the opp owner name
 */
trigger SetOppOwnerName on Opportunity (before update, before insert) 
{
    Set<Id> ownerIds = new Set<Id>();
    for(Opportunity student : Trigger.new)
    {
        if(Trigger.isUpdate)
        {
            Opportunity oldStudent = Trigger.oldMap.get(student.Id);
            if(student.OwnerId != oldStudent.OwnerId)  
            {
                ownerIds.add(student.OwnerId);
            }
        }
        else if(Trigger.isInsert)
        {
            ownerIds.add(student.OwnerId);
        }               
    }
    if(ownerIds.size() > 0)
    {
        List<User> owners = [select Id, Name from User where Id in :ownerIds];
        for(Opportunity student : Trigger.new)
        {
            for(User owner : owners)
            {
                if(student.OwnerId == owner.Id)
                {
                    student.StudentOwner__c = owner.Name;
                }
            }
        }
    }
}