@isTest
private class TestTriggerScript {
    static testMethod void testscript(){
	Lead lead = new Lead();
	lead.LastName = 'test lead';
	lead.Company = '123';
	lead.OwnerId = '005400000015lTI';
	insert lead;

	   Task task1 = new Task();
	   task1.ownerId =  userinfo.getUserId();
	   task1.subject = 'Email:my email';
	   task1.Status = 'In Progress'; 
	   task1.Priority = 'Normal';
	   task1.Appt_Status__c = 'Show';
	   insert task1; 

	   task1 = [select Subject from Task where Id=:task1.Id];
	   task1.subject = 'test task1';
	   task1.WhatId = '0064000000BnalN';
	   update task1;
		
	   Actual__c actual = new Actual__c();
	   actual.Name = 'xxx';

	   insert actual;

	   actual = [select Id,Name from Actual__c where Id=:actual.id];
	   actual.Name = 'update xxx';
	   update actual;
	   

	    actual = [select Id,Name from Actual__c where Id=:actual.id];
	    //delete actual;

	    Id oppOwnerId = '005400000016ODp';
	   Opportunity opp = new Opportunity();
	    opp.Name = 'test opp';
	    opp.CloseDate = Date.today();
	    opp.StageName = 'Appt No Show - Call Later';
	    opp.ownerId = UserInfo.getUserId();//oppOwnerId;
	    insert opp;
	
	    opp = [select Id,Name from Opportunity where Id=:opp.id];
	   opp.Name = 'update xxx';
	   update opp;
	   

	   opp = [select Id,Name from Opportunity where Id=:opp.id];
	   delete opp;
	
	    //test class
	Account acc = new Account();
	acc.Name = '123';
	insert acc;

	Contact con = new Contact();
	con.firstName = '123';
	con.lastName = '122';
	insert con;
	
	

	//test Event Trigger
	Event event = new Event();
	event.RecordTypeId = '0123000000096T6AAI';
	event.WhatId = '0064000000BY71N';
	event.ActivityDate = Date.newInstance(2009,3,13);
	event.ActivityDateTime = DateTime.newInstance(2009,3,13);
	event.Appt_Status__c = 'Scheduled';
	event.EF_Office__c = 'SH LJZ';
	event.OwnerId = [select Id from User where IsActive=true and Profile.Name='EF China Sales User New' limit 1].Id;
	event.Subject = 'xxx';
	event.Auto_Assignment__c = true;
	event.DurationInMinutes = 1200;
	insert event;

	event = [select Subject from event where Id=:event.Id];
	event.subject = 'aaabbbb';
	update event;

	China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
	report.Opportunity__c = '0064000000BY71N';
	report.Sales_Consultant__c = '005400000016buJ';
	report.School__c = 'SH LJZ';
	report.Lead_Source__c = 'Online';
	report.Assignment_Time__c = DateTime.newInstance(2009,3,13);
	report.Appointment_DateTime__c = DateTime.newInstance(2009,3,13);
	report.Appointment_Date__c = Date.newInstance(2009,3,13);

	insert report;

	PaymentData__c payment = new PaymentData__c();
	payment.Pay_Type__c = 'China Smart Payment';
	payment.Actual__c = 'a004000000Bcxm6';
	payment.Amount__c = 2000;

	insert payment;
	
	payment = [select Amount__c from PaymentData__c where Id=:payment.Id];
	payment.Amount__c = 1000;

	//update payment;

	payment = [select Amount__c from PaymentData__c where Id=:payment.Id];
	delete payment;

	
	ComputeOpportunity.GetOpportunitySalesLocation(oppOwnerId);

	//SmartReportService.ComputeAllSmartReport(oppOwnerId);
	//Id sysOwnerId = '005400000016ZK4';
	//SmartReportService.ComputeSycSmartReport(oppOwnerId);
	
    }
}