//whene created payment using pos ,get studentActual of this payment
trigger GetStudentActualTrigger on PaymentData__c (before insert) 
{
	for(PaymentData__c payment : Trigger.new)
	{
		if(payment.Card_Holder__c != null)
		{
			String cardHolderAndId = payment.Card_Holder__c.trim();
			Integer studentIdPos = cardHolderAndId.lastIndexOf(':');
			String StudentActualId ;
			String cardHolder;
			if(studentIdPos != -1)
			{
				String lastString = cardHolderAndId.substring(studentIdPos + 1, cardHolderAndId.length());
				system.debug('::::studentActualId::::' + lastString);
				if(lastString instanceof Id)
				{
					StudentActualId = lastString;
					cardHolder = cardHolderAndId.substring(0, studentIdPos);
				}
				else
				{
					cardHolder = cardHolderAndId;
				}
				payment.StudentActual__c = StudentActualId;
				payment.Card_Holder__c = cardHolder;
			}
		}
	}
}