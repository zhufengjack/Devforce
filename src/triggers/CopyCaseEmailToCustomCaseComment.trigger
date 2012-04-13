/*
 * Copy case email to custom CaseComment object after sending email
 */ 
trigger CopyCaseEmailToCustomCaseComment on EmailMessage (after insert) 
{
	Set<Id> eMessageIds = new Set<Id>();
	
	for(EmailMessage eMessage : Trigger.new)
	{
		if(eMessage.ParentId != null && String.valueOf(eMessage.ParentId).startsWith('500'))
		{
			eMessageIds.add(eMessage.Id);
		}
	}
	
	CopyCaseEmailToCustomCaseComment.copyEmailData(eMessageIds);
	
}