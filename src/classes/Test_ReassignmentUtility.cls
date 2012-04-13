@isTest
private class Test_ReassignmentUtility{
 
    //testing method
    public static testMethod void testMethods(){
    	User u = [select Id from User where IsActive = true limit 1];
    	String strUserName = ReassignmentUtility.getOwnerName(u.Id);
    	
    	List<Account> accs = [select Id,Name from Account limit 10];
    	Set<Id> accIds = ReassignmentUtility.InitAccountIdSet(accs);
    	String strQuery = 'select Id,OwnerId,AccountId,StageName from Opportunity where AccountId in :accountIds';
    	List<Opportunity> opps = ReassignmentUtility.QueryMatchItems(strQuery,accs);
    	accs = ReassignmentUtility.FindTranAccByOpp(opps);
    	String strDate1 = ReassignmentUtility.getTargetDate('20/11/2009');//dd/MM/YYYY
    	String strDate2 = ReassignmentUtility.getTargetEndDate('20/11/2009');
    	String strTempSql = '';
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','1','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','2','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','3','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','4','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','1','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','2','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','3','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','4','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','1','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','2','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','3','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','4','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','1','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','2','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','3','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','4','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','1','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','2','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','3','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','4','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','0','20/11/2009','20/11/2009','0','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','0','20/11/2009','20/11/2009','1','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','0','20/11/2009','20/11/2009','2','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','0','20/11/2009','20/11/2009','3','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','0','20/11/2009','20/11/2009','4','0','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','1','20/11/2009','20/11/2009','0','1','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','2','20/11/2009','20/11/2009','0','2','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','3','20/11/2009','20/11/2009','0','3','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','0','4','20/11/2009','20/11/2009','0','4','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','1','20/11/2009','20/11/2009','1','1','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','2','20/11/2009','20/11/2009','1','2','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','3','20/11/2009','20/11/2009','1','3','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','1','4','20/11/2009','20/11/2009','1','4','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','1','20/11/2009','20/11/2009','2','1','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','2','20/11/2009','20/11/2009','2','2','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','3','20/11/2009','20/11/2009','2','3','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','2','4','20/11/2009','20/11/2009','2','4','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','1','20/11/2009','20/11/2009','3','1','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','2','20/11/2009','20/11/2009','3','2','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','3','20/11/2009','20/11/2009','3','3','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','3','4','20/11/2009','20/11/2009','3','4','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','1','20/11/2009','20/11/2009','4','1','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','2','20/11/2009','20/11/2009','4','2','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','3','20/11/2009','20/11/2009','4','3','21/11/2009','21/11/2009');
    	strTempSql = ReassignmentUtility.GenerateSOQL('Close-won','4','4','20/11/2009','20/11/2009','4','4','21/11/2009','21/11/2009');
    	system.debug(strTempSql);
    }
}