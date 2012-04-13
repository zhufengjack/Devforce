/*
*   If student actual is inserted and updated, This trigger will copy elite code and entry center to student. 
*/
trigger CopyEliteCardToStudent on StudentActual__c (after insert, after update) 
{
    Map<Id, String> studentToElitCard = new Map<Id, String>();
    Map<Id, String> studentToEntryCenter = new Map<Id, String>();
    Map<Id, String> studentToIDNumber = new Map<Id, String>();
    if(trigger.isUpdate)
    {
        for(StudentActual__c studentActual : trigger.new)
        {
            if(studentActual.Student__c != null)
            {
                if(studentActual.EntryCenter__c != trigger.oldMap.get(studentActual.Id).EntryCenter__c && studentActual.EntryCenter__c != null)
                {
                    studentToEntryCenter.put(studentActual.Student__c, studentActual.EntryCenter__c);
                }
                if(studentActual.IDNumber__c != trigger.oldMap.get(studentActual.Id).IDNumber__c && studentActual.IDNumber__c != null)
                {
                    studentToIDNumber.put(studentActual.Student__c, studentActual.IDNumber__c);
                }
            }
        }   
    }
    else if(trigger.isInsert)
    {
        for(StudentActual__c studentActual : trigger.new)
        {
            if(studentActual.Student__c != null)
            {
                if(studentActual.EntryCenter__c != null)
                {
                    studentToEntryCenter.put(studentActual.Student__c, studentActual.EntryCenter__c);
                }
                if(studentActual.IDNumber__c != null)
                {
                    studentToIDNumber.put(studentActual.Student__c, studentActual.IDNumber__c);
                }
            }
        }
    }
    
    Map<Id, Contact> studentMap = new Map<Id, Contact>();
    // For EntryCenter.
    for(Id studentId : studentToEntryCenter.keySet())
    {
        if(studentMap.containsKey(studentId))
        {
            Contact tempStudent = studentMap.get(studentId);
            tempStudent.EntryCenter__c = studentToEntryCenter.get(studentId);
        }
        else
        {
            studentMap.put(studentId, new Contact(Id = studentId, EntryCenter__c = studentToEntryCenter.get(studentId)));
        }
    }
    // For IDNumber.
    for(Id studentId : studentToIDNumber.keySet())
    {
        if(studentMap.containsKey(studentId))
        {
            Contact tempStudent = studentMap.get(studentId);
            tempStudent.IDNumber__c = studentToIDNumber.get(studentId);
        }
        else
        {
            studentMap.put(studentId, new Contact(Id = studentId, IDNumber__c = studentToIDNumber.get(studentId)));
        }
    }
    
    if(studentMap.size() > 0)
    {
        update studentMap.values();
    }
}