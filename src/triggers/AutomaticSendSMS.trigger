/*
 * A trigger send SMS to customer when opportunity Automatic_Action__c euqals 'Send SMS' 
 */
trigger AutomaticSendSMS on Opportunity (after update) 
{
	if(trigger.isUpdate)
	{
	   Set<String> oppIds = new Set<String>();
	   for(Opportunity opp : Trigger.New)
	   {
	       if(opp.Automatic_Action__c == 'Send SMS' && Trigger.OldMap.get(opp.Id).Automatic_Action__c != 'Send SMS' && opp.Mobile__c != null && opp.Mobile__c != '')
	       {      
	           oppIds.add(opp.Id);
	       }  
	    }
	    if(oppIds.size() > 0)
	    {
			SendSMSHelper.sendSMSForTirgger(oppIds);
	    }
	}
}