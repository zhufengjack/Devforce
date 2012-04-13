@isTest
private class TestChinaSmartTransferAccount {

    public static testMethod void testMethods() { 
            
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'EF China Smart Booking Officer' LIMIT 1]; 
        User u = [SELECT Id FROM User WHERE ProfileId = :profile.Id AND IsActive = true LIMIT 1];
        System.runAS(u) {
            Account acc = new Account(Name = 'Account4Test');
            insert acc;
                        
            Profile pf = [SELECT Id FROM Profile WHERE Name = 'EF China Sales User New' LIMIT 1];
            User user = [SELECT Id FROM User WHERE ProfileId = :pf.Id AND IsActive = true LIMIT 1];
            
            try {
                acc.OwnerId = user.Id;
                acc.Booking_Officer_Name__c = Userinfo.getUserRoleId();
                update acc;
            } Catch (DMLException e) {
                System.assertequals(true, e.getMessage().contains('你只可以分配给本学校的销售'));
            }
            
            
        }
        
    }
}