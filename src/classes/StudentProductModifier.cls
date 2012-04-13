global class StudentProductModifier implements Database.Batchable<sObject>
{
	public String query = '';//'select Id, Name, Product__c, Quantity__c, Refund_Amount__c, StudentActual__r.CNRefundTotal__c from StudentProduct__c where StudentActual__c != null and Product__r.family = \'Smart Product List\' ';
	Map<String, Id> productName2Id = new Map<String, Id>(); // product Name 和 product Id的映射
	Id premiumv2Id = [select Id from Product2 where Name = 'Premium v.2'].Id;
	
	global Database.QueryLocator Start(Database.BatchableContext BC)
	{

		return Database.getQueryLocator(query);
	}
	
	global void execute(Database.BatchableContext BC, List<StudentProduct__c> studentProducts)
	{
		// Clear history data
		productName2Id.clear();
		
		// 建立 product Name 和 product Id的映射， 后面建立 Student Product 时会使用。
		List<Product2> productList = [select Id, Name from Product2 Order By CreatedDate];
		for(Product2 pro : productList)
		{
			productName2Id.put(pro.Name, pro.Id);
		} 
		// Creates proudct map end.
		
		if(studentProducts != null && studentProducts.size() > 0)
		{
			for(StudentProduct__c studentProduct : studentProducts)
			{	
				String productName = studentProduct.Name;
				String newProductName = translateName(productName);
				Id newProductId = productName2Id.get(newProductName);
				studentProduct.Name = newProductName;
				studentProduct.Product__c = newProductId;
			}
			update studentProducts;
		}
	}
	
	private String translateName(String productName)
	{
		String result = 'Error Product Name(Null)';
		if(productName != null)
		{
			if(productName.contains('school') || productName == '3-month Executive Course' || productName == '6-month Smart Classic'|| productName == '12-month Smart Classic')
			{
				//productName = 'Premium v.2';
				return 'Premium v.2';
			}
			else if(productName.contains('home'))
			{
				return 'Home';
			}
			else if(productName == 'Alumni Club')
			{
				return 'Alumni Club_6';
			}
			return productName;
		}
		return result;
	}
	
	global void finish(Database.BatchableContext BC)
	{
	
	}
	
	@isTest
	static void testStudentProductModifier()
	{
		// To Do Test
		Actual__c a1 = new Actual__c();
		Actual__c a2 = new Actual__c();
		Actual__c a3 = new Actual__c();
		insert new Actual__c[]{a1, a2, a3};
		
		StudentActual__c sa1 = new StudentActual__c(Actual__c = a1.Id);
		StudentActual__c sa2 = new StudentActual__c(Actual__c = a2.Id);
		StudentActual__c sa3 = new StudentActual__c(Actual__c = a3.Id);
		insert new StudentActual__c[]{sa1, sa2, sa3};
		
		StudentProduct__c sp1 = new StudentProduct__c(Name = '15-month school', StudentActual__c = sa1.Id);
		StudentProduct__c sp2 = new StudentProduct__c(Name = '18-month school', StudentActual__c = sa2.Id);
		StudentProduct__c sp3 = new StudentProduct__c(Name = 'Premium 10', StudentActual__c = sa3.Id);
		insert new StudentProduct__c[]{sp1, sp2, sp3};
		
		Set<Id> studentProductIds = new Set<Id>();
		studentProductIds.add(sp1.Id);
		studentProductIds.add(sp2.Id);
		studentProductIds.add(sp3.Id);
		List<StudentProduct__c> sps = [select Id, Product__c, Quantity__c, Refund_Amount__c, StudentActual__r.CNRefundTotal__c from StudentProduct__c where Name != 'Premium v.2' and Name != null and StudentActual__c != null and Id in :studentProductIds];

		Test.startTest();
		StudentProductModifier sp = new StudentProductModifier();
		sp.query = 'select Id, Name, Product__c, Quantity__c, Refund_Amount__c, StudentActual__r.CNRefundTotal__c from StudentProduct__c where Name != \'Premium v.2\' and Name != null and StudentActual__c != null' + ' and Id in (\'' + sp1.Id + '\', \'' + sp2.Id + '\', \'' + sp3.Id + '\' )';
		Id batchProcessId = Database.executeBatch(sp);
		Test.stopTest();
		
		System.assertEquals('Premium v.2', [select Id, Name from StudentProduct__c where Id = :sp1.Id].Name);
		System.assertEquals('Premium 10', [select Id, Name from StudentProduct__c where Id = :sp3.Id].Name);
	}
}