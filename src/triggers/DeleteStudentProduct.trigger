/*
*	Before delete student actuals, This trigger will delete all related student products.
*   At this time, The final price and refund amount on related actual will be reCalculate.
*/
trigger DeleteStudentProduct on StudentActual__c (before delete) 
{
	List<StudentProduct__c> products = [select Id from StudentProduct__c where StudentActual__c in :Trigger.oldMap.keySet()];
	delete products;
}