@isTest
private class Test_OwnerReassignUtility{
 
    //testing method
    public static testMethod void testMethods()
    {
        /*OwnerReassignUtility ownerUtility = new OwnerReassignUtility();
        List<Account> accs =[select Id,Name from Account limit 20];
        List<User> users = [select Id from User where IsActive=true and Profile.Name = 'EF China Sales User New' limit 6];
        List<String> userIds = new List<String>();
        for(User u:users)
        {
            userIds.add(u.Id);
        }
        Map<Id,Integer> mapAmount = new Map<Id,Integer>();
        for(User u:users)
        {
            mapAmount.put(u.Id,2);
        }
        Set<Id> requestAccIds = new Set<Id>();
        for(Account acc:accs)
        {
            requestAccIds.add(acc.Id);
        }
    
        //List<Reassign_Request__c> reassignReq = [select Id,Orginal_OwnerId__c,Reassign_Data_ID__c from Reassign_Request__c limit 12];
        //ownerUtility.TransferAccountByUsers(userIds,mapAmount,reassignReq);
        
        List<Opportunity> opps2 = [select Id,OwnerId,StageName,Name,AccountId from Opportunity where AccountId in:requestAccIds limit 10];
        ownerUtility.TransferAccountByOwner(accs,opps2,users[0].Id);
        ownerUtility.GetToUsersName(userIds);*/
    }
}