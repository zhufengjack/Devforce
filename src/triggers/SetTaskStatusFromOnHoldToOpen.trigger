/*
 * Tasks should automatically come out of the “on hold” status once the phone or mobile has been updated in Salesforce.
 * From “on hold” to “open”
 */
trigger SetTaskStatusFromOnHoldToOpen on Contact (after update) 
{
    Set<Id> contactIds = new Set<Id>();
    if(Trigger.isUpdate)
    {
        for(Contact con : Trigger.new) 
        {
            Contact oldCon = Trigger.oldMap.get(con.Id);
            if((con.Phone != oldCon.Phone && con.Phone != null) || (con.MobilePhone != oldCon.MobilePhone && con.MobilePhone != null))
            {
                contactIds.add(con.Id);
            }
        }
    }
    if(contactIds.size() > 0)
    {
        String studyAdviseTaskRecordTypeId = '01290000000Mz1k';
        List<Task> updatingTasks = new List<Task>();
        for(Task task : [select Id, Status from Task where Status = 'On-Hold' and WhoId in :contactIds and RecordTypeId = :studyAdviseTaskRecordTypeId])
        {
            task.Status = 'Open';
            updatingTasks.add(task);
        }
        update updatingTasks;
    }
}