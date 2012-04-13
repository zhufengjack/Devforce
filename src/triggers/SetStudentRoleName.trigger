/*
 * sets the role_name of the owner to the account
 * Student_Owner_Role of Account
 */
trigger SetStudentRoleName on Account (before insert, before update) 
{
    Set<Id> ownerIds = new Set<Id>();
    for(Account student : Trigger.new)
    {
        if(Trigger.isUpdate)
        {
            Account oldStudent = Trigger.oldMap.get(student.Id);
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
        List<User> owners = [select Id, UserRole.Name, Name from User where Id in :ownerIds];
        for(Account student : Trigger.new)
        {
            for(User owner : owners)
            {
                if(student.OwnerId == owner.Id)
                {
                    student.Student_Owner_Role__c = owner.UserRole.Name;
                    student.StudentOwner__c = owner.Name;
                }
            }
        }
    }
}