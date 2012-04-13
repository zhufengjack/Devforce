global class DepositStudentProductProcessor implements Database.Batchable<sObject>
{
	public String query = 'select Id, Name, Product__c from StudentProduct__c where StudentActual__r.Actual__r.China_Sales_Type__c = \'Deposit\' and Product__c = null and StudentActual__r.Actual__r.RecordType.Name = \'China Smart Actual Record Type\' ';
	
	global Database.QueryLocator Start(Database.BatchableContext BC)
	{
		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<StudentProduct__c> studentProductList)
	{
		if(studentProductList.size() > 0)
		{
			List<StudentProduct__c> deleteList = new List<StudentProduct__c>();
			for(StudentProduct__c sProduct : studentProductList)
			{
				if(checkStudentProductName(sProduct.Name, sProduct.Id))
				{
					deleteList.add(new StudentProduct__c(Id = sProduct.Id));
				}
			}
			delete deleteList;
		}
	}
	
	private Boolean checkStudentProductName(String sName, String sId)
	{
		if(sName != null && sId != null && sName.length() == 15)
		{
			sId = (sId.length() > 15) ? sId.substring(0, 15) : sId;
			if(sId.equals(sName))
			{
				return true;
			}
		}
		return false;
	}
	
	global void finish(Database.BatchableContext BC)
	{
	
	}
	
	@isTest
	static void testDepositStudentProductProcessor()
	{
		Id actualRecordTypeId = [select Id from RecordType where Name = 'China Smart Actual Record Type' and SobjectType = 'Actual__c'].Id;
		Actual__c a1 = new Actual__c(RecordTypeId = actualRecordTypeId, China_Sales_Type__c = 'Deposit');
		Actual__c a2 = new Actual__c(RecordTypeId = actualRecordTypeId, China_Sales_Type__c = 'Deposit');
		Actual__c a3 = new Actual__c(RecordTypeId = actualRecordTypeId, China_Sales_Type__c = 'Deposit');
		insert new Actual__c[]{a1, a2, a3};
		
		StudentActual__c sa1 = new StudentActual__c(Actual__c = a1.Id);
		StudentActual__c sa2 = new StudentActual__c(Actual__c = a2.Id);
		StudentActual__c sa3 = new StudentActual__c(Actual__c = a3.Id);
		insert new StudentActual__c[]{sa1,sa2, sa3};
		
		StudentProduct__c sp1 = new StudentProduct__c(StudentActual__c = sa1.Id);
		StudentProduct__c sp2 = new StudentProduct__c(StudentActual__c = sa2.Id);
		StudentProduct__c sp3 = new StudentProduct__c(StudentActual__c = sa3.Id);
		insert new StudentProduct__c[]{sp1, sp2, sp3};
		
		Set<Id> spIds = new Set<Id>();
		spIds.add(sp1.Id);
		spIds.add(sp2.Id);
		spIds.add(sp3.Id);
		
		Test.startTest();
		DepositStudentProductProcessor batch = new DepositStudentProductProcessor();
		batch.query = batch.query + ' and id in (\''+ sp1.Id +'\', \''+ sp2.Id +'\', \''+ sp3.Id +'\')';
		Id batchProcessId = DataBase.executeBatch(batch);
		Test.stopTest();
		
		List<StudentProduct__c> studentProducts = [select Id from StudentProduct__c where id in :spIds];
		System.assertEquals(0, studentProducts.size());
	}
}