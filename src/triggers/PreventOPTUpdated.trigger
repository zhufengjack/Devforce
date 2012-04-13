// Field OPT Level and OPT Teacher cann't be updated. This trigger will validate the rule.
trigger PreventOPTUpdated on Contact (before update) 
{
    for(Contact student : Trigger.new)
    {
        Contact oldStudent = Trigger.oldMap.get(student.Id);
        if(oldStudent.OPT_Level__c  != null && oldStudent.OPT_Level__c != student.OPT_Level__c)
        {
            student.OPT_Level__c.addError('OPT Level is not updatable');
        }
        if(oldStudent.OPTTeacher__c != null && oldStudent.OPTTeacher__c != student.OPTTeacher__c)
        {
            student.OPTTeacher__c.addError('OPT Teacher is not updatable');
        }
    }
}