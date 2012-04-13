/**
 *schedule for updating status of collection history,When a collection record was created 45 days and collection status = “in Collection”, SF changes status to “To be sent to agency”.
*/
global class CollectedCollectionHistoryStatusSchedule implements Schedulable
{
    global void execute(SchedulableContext ctx)
    {  
        List<Collection_Process__c> histories = [select Id, Collection_status__c from Collection_Process__c where Collection_status__c = 'In collection' and CreatedDate < :date.today().addDays(-45)];     
        if(!histories.isEmpty())
        {
            for(Collection_Process__c history : histories)
            {
                history.Collection_status__c = 'To be sent to Agency';
            }
            update histories;
        }
    }
    
    @istest
    static void testSchedule()
    {
    		String BrazilTypeId = '0124000000099WD';
    		Id brazilActualTypeId = '0124000000098gR';
    		Date currentDay = Date.today().addDays(-5);
    		Account company = new Account(Name = 'Virtual company');
        insert company;
        Actual__c actual = new Actual__c(account__c = company.Id, Payment_Schedule__c ='Installments-Automatic', RecordTypeId = brazilActualTypeId);
        insert actual;
        Payment_Record__c payment = new Payment_Record__c(Actual__c = actual.Id, Amount_Due__c = 1000, Collection_staff__c = UserInfo.getUserId(), Due_Date__c = currentDay, Status__c = 'Due', RecordTypeId = BrazilTypeId);
        insert payment;
    		payment.Failed_date__c = currentDay;
    		update payment;
    		Collection_Process__c collectionProcess = new Collection_Process__c(Collection_status__c = 'In collection', PaymentRecord__c = payment.Id);
    		insert collectionProcess;
    		collectionProcess.Collection_status__c = 'In Negotiation';
    		update collectionProcess;
    		CollectedCollectionHistoryStatusSchedule schedulable = new CollectedCollectionHistoryStatusSchedule();
        SchedulableContext ctx;
        schedulable.execute(ctx);
    }
}