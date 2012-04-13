trigger OpptunityOwnerChangSynActual on Opportunity (after update) {
	/**
	*The function of this trigger is update the field named Opportunity owner in  Acutal when Opportunity owner is changed
	*cn(当业务机会所有人发生变化时，业务机会下的Actual中的Opportunity Owner也进行相应的修改)
	*/
	//这个trigger造成SOQL>201, 暂时注释掉了, by Kevin 2010.12.6
	/*if(Trigger.isAfter)
	{
		if(Trigger.isUpdate)
		{
			Map<String,String> OldOppmap=new Map<String,String>();
			Map<String,String> newOppmap=new Map<String,String>();
			for(Opportunity opp:Trigger.new)
			{
				if(opp.OwnerId!=trigger.oldMap.get(opp.Id).OwnerId)
				{
					List<Actual__c> listactual=[select Actual__c.Id,Actual__c.Opportunity_owner__c from Actual__c where Actual__c.Opportunity__c =:opp.Id];
					if(listactual.size()>0)
					{
						for(Actual__c actual:listactual)
						{
						actual.Opportunity_owner__c=opp.OwnerId;
						}
						update listactual;
					}
				}
				
			}
		}
	}*/

}