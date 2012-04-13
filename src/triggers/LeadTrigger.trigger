trigger LeadTrigger on Lead (before insert, before update) {
	/**
	*@lastmodified by Jack Zhu
	*@Date: 2011-10-21
	*@function:this trigger is used to set cn_Province and CN_City__c according to leads owner's role.
	*and this trigger is only applied to ChinaSmartLeadRecordType. recordtype id 0124000000099rk
	*Pony Ma 2011-11-10 Changed to process all records instead of only the first record, do not clear the province,city value if the location is not in BJ/GZ/SZ/SH
	*Pony Ma 2011-11-15 Added China Smart TM profile limitation
	*/
	if(Trigger.isBefore)
	{
		if(Trigger.isInsert)
		{							
			//only auto-populate the city/province value for china TM
			Profile userProfile=[select Id,Name from Profile where Id=:UserInfo.getProfileId()];
			if(userProfile.Name.contains('EF China Telemarketing') || userProfile.Name.contains('EF China Operator') || userProfile.Name.contains('EF China Smart OA')){
											
				List<Lead> smartLeadList=new List<Lead>();	
				Set<String> idSet=new Set<String>();		
				for(Lead l:Trigger.new){
					if(l.RecordTypeId=='0124000000099rk'){
						smartLeadList.add(l);
						idSet.add(l.OwnerId);	
					}
						
				}
				
				if(smartLeadList.size()>0){
					Map<String,String> locationMap=ComputeOpportunity.getOpportunitySalesLocations(idSet);
					for(Lead l:smartLeadList){
						String strLocation=locationMap.get(l.OwnerId);
						if(strLocation!=null){
							if(strLocation.contains('BJ'))
							{
								l.CN_Province_Name__c = 'cn_bj';
								l.CN_City__c = 'Beijing';
							}
							if(strLocation.contains('GZ'))
							{
								l.CN_Province_Name__c = 'cn_gd';
								l.CN_City__c = 'Guangzhou';
							}
							if(strLocation.contains('SZ'))
							{
								l.CN_Province_Name__c = 'cn_gd';
								l.CN_City__c = 'Shenzhen';
							}
							if(strLocation.contains('SH'))
							{
								l.CN_Province_Name__c = 'cn_sh';
								l.CN_City__c = 'Shanghai';
							}	
						}
					}	
				}
			}
			
			
			
			//Lead currLead = Trigger.new[0];
			/**
			if(currLead.RecordTypeId=='0124000000099rk')
			{				
				String strLocation  = ComputeOpportunity.GetOpportunitySalesLocation(currLead.OwnerId);
				if(strLocation != ''){
					String strProvince  = '';
					String strCity = '';
					if(strLocation.contains('BJ'))
					{
						strProvince = 'cn_bj';
						strCity = 'Beijing';
					}
					if(strLocation.contains('GZ'))
					{
						strProvince = 'cn_gd';
						strCity = 'Guangzhou';
					}
					if(strLocation.contains('SZ'))
					{
						strProvince = 'cn_gd';
						strCity = 'Shenzhen';
					}
					if(strLocation.contains('SH'))
					{
						strProvince = 'cn_sh';
						strCity = 'Shanghai';
					}
					currLead.CN_City__c = strCity;
					currLead.CN_Province_Name__c = strProvince;
				}
			
			}
			*/
			}
	}
}