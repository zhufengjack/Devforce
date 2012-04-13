global class ActualDataTransfer implements Database.Batchable<sObject>
{
	static Map<String, Id> productName2Id = new Map<String, Id>(); // product Name 和 product Id的映射
	Map<Id, Id> account2Contact  = new Map<Id, Id>(); // 建立studentActual时候用到
	Map<Id, China_Smart_Refund__c> actual2Refund = new Map<Id, China_Smart_Refund__c>(); // 当前历史actual相关联的 China_Smart_Refund__c 数据
	public String actualQuery = 'select Id,' + 
					'Account__c,' + 
					'Opportunity__r.Name,' +
					'Opportunity__r.AccountId,' +
					'Contract_Type__c,' +
					'Contract_number__c,' +
					'IDNumber__c,' +
					'CN_Deposit_Total__c,' +
					'CN_Refund_Total__c,' +
					'CN_Payment_Total__c,' +
					'Elite_Card__c,' +
					'Invoice__c,' +
					'China_Product_List__c,' +
					'Sales_Appt_Locations_2__c,' +
					'China_Product_Length__c,' +
					'Length_for_Extra_Code__c,' +
					'Length_For_Promotion_Code__c,' +
					'China_Redemption_Code__c,' +
					'(select Id, Amount__c from China_Payment_Data__r) ' +
				'from Actual__c where ' + 
				'RecordType.Name = \'China Smart Actual Record Type\' and StudentActualCount__c = 0'
				;

	global Database.QueryLocator Start(Database.BatchableContext BC)
	{
		// Creates proudct map end.
		return Database.getQueryLocator(actualQuery);
	}
	
	global void execute(Database.BatchableContext BC, List<Actual__c> actuals)
	{
		if(actuals != null && actuals.size() > 0)
		{	
			// Clear history data;
			account2Contact.clear();
			actual2Refund.clear();
			productName2Id.clear();
			
			// 建立 product Name 和 product Id的映射， 后面建立 Student Product 时会使用。
			List<Product2> productList = [select Id, Name from Product2 Order By CreatedDate];
			for(Product2 pro : productList)
			{
				productName2Id.put(pro.Name, pro.Id);
			}
			
			// 1.2, 构建数据
			Set<Id> relatedAccountIds = new Set<Id>();
			Map<Id, Actual__c> actualMap = new Map<Id, Actual__c>();
			Map<Id, StudentActual__c> newStudentActualMap = new Map<Id, StudentActual__c>();
			
			for(Actual__c actual : actuals)
			{
				//if(actual.China_Payment_Data__r.size() > 0)
				//{
					if(actual.Account__c != null)
					{
						relatedAccountIds.add(actual.Account__c);
					}
					else if(actual.Opportunity__r.AccountId != null)
					{
						relatedAccountIds.add(actual.Opportunity__r.AccountId);
						actual.Account__c = actual.Opportunity__r.AccountId; // 当 actual上面Account为空时，给Account赋值
					}
					
					//如果 contract type 为 null 那么就把它变成B2C
					if(actual.Contract_Type__c == null)
					{
						actual.Contract_Type__c = 'B2C';
					}
					
					actualMap.put(actual.Id, actual);
				//}
			}
		 
			// 2, 找出全部的 contact id （这个东西会在建立studentActual时候用到）
			//Map<Id, Id> account2Contact  = new Map<Id, Id>();
			List<Contact> oldContactList = [select Id, AccountId from Contact where AccountId in :relatedAccountIds Order by CreatedDate];
			for(Contact con : oldContactList)
			{
				account2Contact.put(con.AccountId, con.Id);
			}
			
			//3, 找出 所有和 当前历史actual相关联的 China_Smart_Refund__c 数据，因为这个数据后面会用的，并建立map存储， 其中存储的 refund对象 为最后创建的那个。
			//Map<Id, China_Smart_Refund__c> actual2Refund = new Map<Id, China_Smart_Refund__c>();
			List<China_Smart_Refund__c> refundList = [select Id, Refund_Type_China__c, Refunded_invoice__c, Refund_Date_China__c, China_Payment_Data__r.Actual__c from China_Smart_Refund__c where China_Payment_Data__r.Actual__c in : actualMap.keySet() and China_Payment_Data__r.Pay_Type__c = 'China Smart Payment' order by CreatedDate ];
			for(China_Smart_Refund__c refund : refundList)
			{
				actual2Refund.put(refund.China_Payment_Data__r.Actual__c, refund);
			}
			
			//4, 创建studentActual
			Map<Id, StudentActual__c> actual2StudentActual = new Map<Id, StudentActual__c>();
			for(Actual__c actual : ActualMap.values())
			{
				createdStudentActuals(actual, actual2StudentActual);
			}
			insert actual2StudentActual.values();
			
			//4.1 如果 contract type 为 null 那么就把它变成B2C， Account 要填上！
			
			update actualMap.values();
			
			//5, Update related paymentData.
			
			updatePaymentData(actualMap, actual2StudentActual);
			
			//5.1, 选择新Actual数据 （CN Refund Total 已经改变）
			actuals = [select Id, 
								CN_Deposit_Total__c,
								CN_Refund_Total__c,
								CN_Payment_Total__c,
								China_Product_List__c,
								Sales_Appt_Locations_2__c,
								China_Product_Length__c,
								Length_for_Extra_Code__c,
								Length_For_Promotion_Code__c
							from Actual__c where Id in :ActualMap.keySet() 
							];
			
			//创建新的 Actual Map	.				 
			ActualMap.clear(); // 清空原有actual map.
			for(Actual__c tempActual : actuals)
			{
				ActualMap.put(tempActual.Id, tempActual);		
			}
			
			//6, 创建 studentProduct.
			Map<Id, StudentProduct__c> actual2StudentProduct = new Map<Id, StudentProduct__c>();
			for(Actual__c actual : ActualMap.values())
			{
				createdStudentProducts(actual, actual2StudentProduct, actual2StudentActual);
			}
			insert actual2StudentProduct.values();
			System.debug('@@@@@@[End......] ');	
		}
	}
	
	private void createdStudentActuals(Actual__c tempActual, Map<Id, StudentActual__c> actual2StudentActual)
	{
		if(tempActual != null)
		{
			String studentActualName = tempActual.Opportunity__r.Name;
			if(studentActualName != null && studentActualName.length() > 80)
			{
				studentActualName = studentActualName.substring(0, 80);
			}
			
			//1,建立 StudentActual
			StudentActual__c newStudentActual = new StudentActual__c(
																		Name = studentActualName,
																		Actual__c = tempActual.Id, // 所属的Actual。
																		Student__c = account2Contact.get(tempActual.Account__c),
																		ContractNo__c = tempActual.Contract_number__c, //已经检查
																		IDNumber__c = tempActual.IDNumber__c,//已经检查
																		EliteCard__c = tempActual.Elite_Card__c,//已经检查
																		Invoice__c = tempActual.Invoice__c,//已经检查
																		EntryCenter__c = tempActual.Sales_Appt_Locations_2__c, // 需要确认。//已经检查
																		Redemption_Code__c = tempActual.China_Redemption_Code__c //已经检查
																		);
			//2, 设置 refund 信息
			China_Smart_Refund__c tempRefund = actual2Refund.get(tempActual.Id);
			if(tempRefund != null)
			{   //system.debug('### : ' + tempRefund.Id + ' ### &&& : ' + tempRefund.Refund_Type_China__c);
				newStudentActual.RefundType__c = tempRefund.Refund_Type_China__c; //已经检查
				newStudentActual.RefundInvoice__c = tempRefund.Refunded_invoice__c; //已经检查
			}
			//3, add to map.
			actual2StudentActual.put(tempActual.Id, newStudentActual);
			//4, For update actual "Contract Type", account,
		}
	}
	
	private void createdStudentProducts(Actual__c tempActual, Map<Id, StudentProduct__c> actual2StudentProduct, Map<Id, StudentActual__c> actual2StudentActual)
	{
		if(tempActual != null && actual2StudentProduct != null && actual2StudentActual != null)
		{
			// 获取Product 信息。
			String productName = tempActual.China_Product_List__c;
			Id productId = productName2Id.get(productName);
			
			// Creates student product.
			StudentProduct__c newStudentProduct = new StudentProduct__c(
																			Name = productName,
																			StudentActual__c = actual2StudentActual.get(tempActual.Id).Id,
																			Product__c = productId,
																			Quantity__c = 1, // from update 2 table. set quantity = 1.
																			Price__c = tempActual.CN_Payment_Total__c,
																			StandardLength__c = tempActual.China_Product_Length__c,
																			MarketingLength__c = tempActual.Length_for_Extra_Code__c,
																			FreeLength__c = tempActual.Length_For_Promotion_Code__c,
																			Refund_Amount__c = tempActual.CN_Refund_Total__c
																			);
			// 更新 student product  refund 信息
			China_Smart_Refund__c tempRefund = actual2Refund.get(tempActual.Id);
			if(tempRefund != null)
			{
				newStudentProduct.Refund_date_China__c = tempRefund.Refund_Date_China__c;
			}	
			if(tempActual.CN_Refund_Total__c > 0 )
			{
				newStudentProduct.Refund_Quantity__c = 1; // from table 2 'If CN Refund Total >0, set as 1';
			}		
			// 添加到 student product map 
			actual2StudentProduct.put(tempActual.Id, newStudentProduct);																							
		}
	}
	
	private void updatePaymentData(Map<Id, Actual__c> actualMap, Map<Id, StudentActual__c> actual2StudentActual)
	{
		if(actualMap != null && actual2StudentActual != null)
		{
			List<PaymentData__c> paymentList = new List<PaymentData__c>();
			for(Id actualId : actual2StudentActual.keySet())
			{
				Actual__c tempActual = actualMap.get(actualId);
				if(tempActual != Null)
				{
					for(PaymentData__c payment : tempActual.China_Payment_Data__r)
					{
						payment.StudentActual__c = actual2StudentActual.get(actualId).Id;
					}
					paymentList.addAll(tempActual.China_Payment_Data__r);
				}
			}
			//System.debug('### PaymentData size:' + PaymentList.size());
			update PaymentList;
		}
	}
	
	global void finish(Database.BatchableContext BC)
	{
	
	}
	
	@isTest
	static void testActualDataTransfer()
	{
		Id accoutB2BTypeId = [select Id from RecordType where Name = 'China Smart B2B record type' and SobjectType = 'Account'].Id;
		Id actualB2CtypeId = [select Id from RecordType where Name = 'China Smart Actual Record Type' and SobjectType = 'Actual__c'].Id;
		
		Account a1 = new Account(Name = 'a1', RecordTypeId = accoutB2BTypeId);
		Account a2 = new Account(Name = 'a2');
		Account a3 = new Account(Name = 'a3');
		Account a4 = new Account(Name = 'a4');
		insert new Account[]{a1, a2, a3, a4};
		
		Contact c10 = new Contact(LastName = 'c10', AccountId = a1.Id);
		Contact c11 = new Contact(LastName = 'c11', AccountId = a1.Id);
		Contact c20 = new Contact(LastName = 'c20', AccountId = a2.Id);
		Contact c30 = new Contact(LastName = 'c30', AccountId = a3.Id);
		Contact c40 = new Contact(LastName = 'c40', AccountId = a4.Id); 
		insert new Contact[]{c10, c11, c20, c30, c40};
		
		Opportunity o1= new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name = 'o1', AccountId = a1.Id, Location__c = 'BJ CYM');
		Opportunity o2= new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name = 'o2', AccountId = a2.Id, Location__c = 'BJ DWL');
		Opportunity o3= new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name = 'o3', AccountId = a3.Id, Location__c = 'BJ SYQ');
		Opportunity o4= new Opportunity(StageName = 'Closed Won', CloseDate = Date.today(), Name = 'o4', AccountId = a4.Id, Location__c = 'GZ GYQ');
		insert new Opportunity[]{o1, o2, o3, o4};
		
		Actual__c actual1 = new Actual__c(Account__c = a1.Id, Opportunity__c = o1.Id, Contract_number__c = 'cn01', IDNumber__c = '0001', Elite_Card__c = 'EC001', Invoice__c = 'in001', China_Product_List__c = 'product1', China_Product_Length__c = '12', Length_for_Extra_Code__c = '2', Length_For_Promotion_Code__c = '3', China_Redemption_Code__c = 'RC-001', RecordTypeId = actualB2CtypeId);
		Actual__c actual2 = new Actual__c(Account__c = a2.Id, Opportunity__c = o2.Id, Contract_number__c = 'cn02', IDNumber__c = '0002', Elite_Card__c = 'EC002', Invoice__c = 'in002', China_Product_List__c = 'product2', China_Product_Length__c = '11', Length_for_Extra_Code__c = '3', Length_For_Promotion_Code__c = '2', China_Redemption_Code__c = 'RC-002', RecordTypeId = actualB2CtypeId);
		Actual__c actual3 = new Actual__c(Account__c = a3.Id, Opportunity__c = o3.Id, Contract_number__c = 'cn03', IDNumber__c = '0003', Elite_Card__c = 'EC003', Invoice__c = 'in003', China_Product_List__c = 'product3', China_Product_Length__c = '10', Length_for_Extra_Code__c = '1', Length_For_Promotion_Code__c = '1', China_Redemption_Code__c = 'RC-003', RecordTypeId = actualB2CtypeId);
		Actual__c actual4 = new Actual__c(Account__c = a4.Id, Opportunity__c = o4.Id, Contract_number__c = 'cn04', IDNumber__c = '0004', Elite_Card__c = 'EC004', Invoice__c = 'in004', China_Product_List__c = 'product4', China_Product_Length__c = '19', Length_for_Extra_Code__c = '4', Length_For_Promotion_Code__c = '4', China_Redemption_Code__c = 'RC-004', RecordTypeId = actualB2CtypeId);
		insert new Actual__c[]{actual1, actual2, actual3, actual4};
	
		PaymentData__c p10 = new PaymentData__c(Actual__c = actual1.Id, Amount__c = 3000, Pay_Type__c = 'China Smart Payment');
		PaymentData__c p20 = new PaymentData__c(Actual__c = actual2.Id, Amount__c = 3001, Pay_Type__c = 'China Smart Deposit');
		PaymentData__c p21 = new PaymentData__c(Actual__c = actual2.Id, Amount__c = 3002, Pay_Type__c = 'China Smart Payment');
		PaymentData__c p30 = new PaymentData__c(Actual__c = actual3.Id, Amount__c = 3003, Pay_Type__c = 'China Smart Payment');
		PaymentData__c p40 = new PaymentData__c(Actual__c = actual4.Id, Amount__c = 3004, Pay_Type__c = 'China Smart Payment');
		insert new PaymentData__c[]{p10, p20, p21, p30, p40};
		
		China_Smart_Refund__c refund = new China_Smart_Refund__c(Refund_Amount__c = 2000, China_Payment_Data__c = p30.Id);
		insert refund;
		
		Test.startTest();
		ActualDataTransfer batchProcessor = new ActualDataTransfer();
		batchProcessor.actualQuery = batchProcessor.actualQuery + ' and Id in (\'' + actual1.Id + '\', \'' + actual2.Id+ '\', \'' + actual3.Id + '\', \'' + actual4.Id + '\')';
		Id batchProcessId = Database.executeBatch(batchProcessor);
		Test.stopTest();

	}
}