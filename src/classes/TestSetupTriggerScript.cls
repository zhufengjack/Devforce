@isTest
private class TestSetupTriggerScript {
    static testMethod void testscript(){

	///////////////////////////////////
	//test user Trigger
	///////////////////////////////////
	User user = [select Id,IsActive from User where Id='00540000001Ms5I'];
	user.Alias = 'test1_bj';
	user.Locale__c = 'China';
	user.Functions__c = 'China Smart Schools';
	update user;
	///////////////////////////////////
	//End of test user Trigger
	///////////////////////////////////


    }
    /**
    *以下测试方法由Jack Zhu 编写
    *the following test methods is coded by Jack zhu from ef
    */
    
    /**
    *该方法是测试ActualTrigger是否正确
    *目的：当Actual创建时，自动更新Frist show up 与Close Date
    *当First show up 晚于Close Date时，自定将First show up 与Close Date 设置为同一天，如果first show up 早于Close Date则保持不变
    *当创建Actual时，自动根据Actual更新Opportunity上的Close Date First show up，amount.
    *当更新Actual时，自动判断当elite card 发生变化时，自动更新Account 上的elite card，当其它发生变化时，改变相应的值，例如金额发生变化，则相应修改Opp上的金额
    */
    static testmethod void testActualTrigger(){
    	Account a1=new Account();
    	a1.Elite_card__c='bj0000090';
    	a1.Name='a1';
    	insert a1;
    	
    	Opportunity opp1=new Opportunity();
    	opp1.Name = 'test opp';
	    opp1.CloseDate = Date.today();
	    opp1.First_Visit__c=Date.today();
	    opp1.StageName = 'Appt No Show - Call Later';
	    opp1.AccountId=a1.Id;
		insert opp1;
    	
    	Actual__c act1=new Actual__c();
    	act1.Close_date__c=Date.today()-1;
    	act1.CN_Payment_Total__c=1000;
    	act1.Elite_Card__c='bj0000090';
    	act1.Opportunity__c=opp1.Id;
    	act1.Account__c=a1.Id;
    	insert act1;
    	
    	act1.CN_Payment_Total__c=2000;
    	act1.Elite_Card__c='bj0000009';
    	update act1;
    	
    	Actual__c act2=new Actual__c();
    	act2.Close_date__c=Date.today();
    	act2.CN_Payment_Total__c=1000;
    	act2.Elite_Card__c='bj0000090';
    	act2.Opportunity__c=opp1.Id;
    	act2.Account__c=a1.Id;
    	insert act2;
    	
    	
    	
    	
    }
}