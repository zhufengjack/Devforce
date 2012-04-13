public class EtownStudentCaseSvc 
{
    
    public static Id getQueueIdByName(String queueName)
    {
    	Id queueId;
    	if(queueName != null && queueName != '')
        {
        	queueId = [Select QueueId, Queue.Id from QueueSobject where Queue.Name =: queueName limit 1].Queue.Id;
        }
    	return queueId;
    }
    
    public static Id getProfileIdByName(String profileName)
    {
    	Id profileId;
    	if(profileName != null && profileName != '')
        {
        	profileId = [Select Id from Profile where Name =: profileName limit 1].Id;
        }
        return profileId;
    }
    
    public static Id getRecordtypeIdByName(String sobjectName, String recordtypeName)
    {
    	Id recordtypeId;
    	if(recordtypeName != null && recordtypeName != '' && sobjectName != null && sobjectName !='')
        {
        	recordtypeId = [Select Id from RecordType r where SobjectType =: sobjectName and Name =:recordtypeName limit 1].Id;
        }
    	return recordtypeId;
    }
    
    public static Id getRoleIdByName(String roleName)
    {
    	Id roleId;
    	if(roleName != null && roleName != '')
        {
        	roleId = [Select Id from UserRole where Name =: roleName].Id;
        }
    	return roleId;
    }
}