/*
 * Send email and create a new event for duplicate opp owner 
 */
trigger RemindOppOwnerOnLead on Lead(after update)
{
	for(Lead lead : trigger.new)
	{
		Lead oldLead = trigger.oldMap.get(lead.Id);
		if(oldLead.Status != 'Duplicate' && lead.Status == 'Duplicate')
		{
			Opportunity opp = LeadConvertHelper.matchOppForLead(lead);
			if(opp != null)
			{
				try
				{
					LeadConvertHelper.sendNotificationEmail(opp);
					LeadConvertHelper.createReminderEvent(opp);
				}
				catch(Exception ex) 
				{ 
					throw(ex);
				}
			}
		}
		break;
	}
}