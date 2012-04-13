trigger EventTrigger on Event (after update,after insert) 
{
	if(Trigger.isAfter)   
	{     
		try       
		{          
			Event eventNew = Trigger.new[0];        
			//检查当前活动是否与Opportunity相关       
			List<Opportunity> opps = [select Id,Activity_Last_modified_date__c   from Opportunity where Id =:eventNew.WhatId];         
			if(opps != null && opps.size()>0)         
			{             
			//Update Opportunity Activity Last Modified Date            
			opps[0].Activity_Last_modified_date__c = eventNew.LastModifiedDate;      
			update opps[0];          
			}      
		}       
		catch(Exception e)     
		{                    
		}         
	}
}