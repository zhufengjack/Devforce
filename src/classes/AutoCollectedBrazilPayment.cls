/*
 * for Brazil Payment records,  if payment schedule is installment automatic, change status to “collected” on the due date. We will also update “amount collected” to “due amount 
 */
global class AutoCollectedBrazilPayment implements Schedulable
{
	global void execute(SchedulableContext ctx)
	{
		String BrazilRecordTypeId = '0124000000099WD';
		String MexicoRecordTypeId = '0124000000099IG';
		List<Payment_Record__c> records = [select Id, Amount_Due__c, Due_Date__c, Amount_Collected__c, Collected_Date__c, Status__c from Payment_Record__c where Status__c = 'Due' and Actual__r.Payment_Schedule__c ='Installments-Automatic' and (RecordTypeId = :BrazilRecordTypeId or RecordTypeId = :MexicoRecordTypeId) and Due_Date__c <= :date.today().addDays(-1)];
		List<Payment_Record__c> toBeProcessRecords = new List<Payment_Record__c>();
		if(!records.isEmpty())
		{
			for(Payment_Record__c record : records)
			{
				record.Status__c = 'Collected';
				record.Amount_Collected__c = record.Amount_Due__c;
				record.Collected_Date__c = date.today();
				toBeProcessRecords.add(record);
			}
		}
		if(!toBeProcessRecords.isEmpty())
		{
			try
			{
				update toBeProcessRecords;
			}
			catch(exception ex)
			{
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(new String[]{'david.lee@meginfo.com', 'kevin.chong@meginfo.com'});
                mail.setPlainTextBody(ex.getMessage());
                mail.setSubject('Exception for auto collect brazil payment records schedule');
                mail.setSenderDisplayName('ETown');
                mail.setReplyTo('no-reply@Englishtown.com');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[]{mail});
			}
		}
	}
	@isTest
	static void testSchedulable()
	{
		String BrazilTypeId = '0124000000099WD';
		Date currentDay = date.today().addDays(-1);
		Account company = new Account(Name = 'Virtual company');
        insert company;
        Actual__c actual = new Actual__c(account__c = company.Id, Payment_Schedule__c ='Installments-Automatic');
        insert actual;
        Payment_Record__c payment = new Payment_Record__c(Actual__c = actual.Id, Amount_Due__c = 1000, Due_Date__c = currentDay, Status__c = 'Due', RecordTypeId = BrazilTypeId);
        insert payment;
        AutoCollectedBrazilPayment schedulable = new AutoCollectedBrazilPayment();
        SchedulableContext ctx;
        schedulable.execute(ctx);
	}
}