/*
*	If the product is main product and actual is B2B actual, This trigger will copy refund date from student product to actual.
*/
trigger CopyRefundDateToActual on StudentProduct__c (after insert, after update) 
{
	Set<Id> actualIds = new Set<Id>();
	Map<Id, StudentProduct__c> actual2StudentProduct = new Map<Id, StudentProduct__c>();
	List<StudentProduct__c> studentProducts = [select Id, StudentActual__r.Actual__c, StudentActual__r.Actual__r.StudentActualCount__c, Product__r.EtownId__c, Refund_date_China__c   from StudentProduct__c where Id in :trigger.newMap.keySet()];
	for(StudentProduct__c studentProduct : studentProducts)
	{
		if(studentProduct.StudentActual__r.Actual__r.StudentActualCount__c == 1 && studentProduct.Product__r.EtownId__c != null)
		{
			actual2StudentProduct.put(studentProduct.StudentActual__r.Actual__c, studentProduct);
		}
	}
	
	if(actual2StudentProduct.size() > 0)
	{
		List<Actual__c> updateList = new List<Actual__c>();
		for(Id actualId : actual2StudentProduct.keySet())
		{
			updateList.add(new Actual__c(Id = actualId, Refund_date_China__c = actual2StudentProduct.get(actualId).Refund_date_China__c));
		}
		update updateList;
	}
}