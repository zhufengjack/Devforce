/*
*  This trigger will close old advise tasks for a student.
*/
trigger CloseOldStudyAdviseTask on Task (after insert) 
{
	Id studyAdviseTaskRecordTypeId;
    try
    {
        studyAdviseTaskRecordTypeId = [select Id from RecordType where Name = 'Study Advise' and SobjectType = 'Task'].Id;
    }
    catch(Exception ex){}
    if(studyAdviseTaskRecordTypeId != null)
    {
	    Set<Id> contactIds = new Set<Id>();
	    for(Task task : trigger.new)
	    {
	        if(task.WhoId != null && task.RecordTypeId == studyAdviseTaskRecordTypeId)
	        {
	            contactIds.add(task.WhoId);
	        }
	    }
	    if(contactIds.size() > 0)
	    {
	        List<Task> historyOpenTasks = [select Id, Status from Task where IsClosed = false and RecordTypeId = :studyAdviseTaskRecordTypeId and WhoId in :contactIds and Id not in :trigger.newMap.keySet()];
	        if(historyOpenTasks.size() > 0)
	        {
		        for(Task task : historyOpenTasks)
	            {
	                task.Status = 'Closed by System';
	            }
	            update historyOpenTasks;
	        }
	    }
    }
}