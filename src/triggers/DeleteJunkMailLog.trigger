trigger DeleteJunkMailLog on Task (after insert,after update,before update) {	
    
    if(Trigger.isAfter && (Trigger.isInsert || Trigger.isUpdate))
    {
	////////////////////////////////////////////////////////
	//Update Opportunity Last Task Field
	///////////////////////////////////////////////////////
	Task taskNew = Trigger.new[0];
        //��鵱ǰ��Ƿ���Opportunity���
        List<Opportunity> opps = [select Id,Last_Task__c,Name  
        from Opportunity where Id =:taskNew.WhatId];
        if(opps != null && opps.size()>0)
        {
	    //Update Opportunity Activity Last Modified Date
	    opps[0].Activity_Last_modified_date__c = taskNew.LastModifiedDate;
            //��ǰ������Opportunity���
            //����״̬Ϊδ���(û�б�ɾ���)
            //�����������Opportunity��ص��������񣬲��ҵ����µ�һ������
            //taskNew.addError('ww'+String.valueof(opps.size()));
            List<Task> tasks = [select Id,ActivityDate from Task where WhatId=:taskNew.WhatId  and IsDeleted = false order by ActivityDate DESC limit 1];
            if(tasks != null && tasks.size()>0)
            {
		try   {
			opps[0].Last_Task__c = tasks[0].ActivityDate;
			update opps[0];
		}
		catch(Exception e)
		{
			System.debug('Exception in DeleteJunkMailLog Trigger' + e.getMessage()); 
		}
            }
        }
	////////////////////////////////////////
	////Update Opportunity Last Task Field End
	/////////////////////////////////////////
    }
    if(Trigger.isAfter && Trigger.isInsert)
    {
	
	try   {
		Set<ID> taskIds = new Set<ID>();
		Set<ID> newTaskIds = new Set<ID>();
		for(Task task:Trigger.new)
		{
			newTaskIds.add(task.Id);
		}
		Id newTaskId = Trigger.new[0].Id;
		Id currentUserRoleId = UserInfo.getUserRoleId();
		List<UserRole> roles = [select Id,Name from UserRole where Id=:currentUserRoleId];
		String strRoleName = '';
		if(roles != null && roles.size()>0)
		{
			strRoleName = roles[0].Name;
		}
		
		if(strRoleName == 'China Operator' || 
		strRoleName == 'China Telemarketer' || 
		(strRoleName.startsWith('China Telesales') && strRoleName.contains('TM')) || 
		strRoleName.startsWith('Brazil TM') || 
		strRoleName == 'Mexico CR')
		{
			//delete emails
			for(Task task:[select Id from Task where 
				Subject Like 'EMail:%' and OwnerId=:UserInfo.getUserId() 
				and Id not in:newTaskIds
				and createddate =LAST_N_DAYS : 14 limit 90])
			{
				taskIds.add(task.Id);
			}
			System.debug('task count:'+taskIds.size());
			try   {
				for(Task[] junkMailTask:[Select id FROM Task Where Id In : taskIds and Id != :newTaskId limit 100])
				{ 
					System.debug('system will delete junkmails:'+junkMailTask.size());
					delete junkMailTask;
				}
			}
			catch(Exception e) { 
				System.debug('Exception in DeleteJunkMailLog Trigger' + e.getMessage()); 
			} 
			
		}
	}
        catch(Exception e)
	{
		System.debug('Exception in DeleteJunkMailLog Trigger' + e.getMessage()); 
	}
    }
}