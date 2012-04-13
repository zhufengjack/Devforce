global class ReassignmentUtility 
{
    static public String getOwnerName(String strOwnerId)
    {
        List<User> users = [select Id,Alias,Name,FirstName,LastName from User where Id=:strOwnerId];
        if(users != null && users.size()>0)
            return users[0].Name;
        else
            return 'N/A';
    }
    
    static public List<Opportunity> QueryMatchItems(String strTempQueryString,List<sObject> scope)
    {
        List<Opportunity> opps = new List<Opportunity>();
        Opportunity opp = null;
        try
        {
            Set<Id> accountIds = ReassignmentUtility.InitAccountIdSet(scope);
            opps = Database.query(strTempQueryString);
        }
        catch(System.DMLException e) 
        {
            system.debug('QueryMatchItem error.');
        }
        return opps;
    }
    
    static public Set<Id> InitAccountIdSet(List<sObject> scope)
    {
        Set<Id> accountIds = new Set<Id>();
        for(sObject s : scope)
        {
            Account a = (Account)s;
            accountIds.add(a.Id);
        }
        return accountIds;
    }
    
    static public List<Account> FindTranAccByOpp(List<Opportunity> validOpportunities)
    {
        Map<Id,String> accMap = new Map<Id,String>();
        Set<Id> accIds = new Set<Id>();
        List<Account> queryResult = null;
        for(Opportunity opp:validOpportunities)
        {
            if(!accMap.containsKey(opp.AccountId))
            {
                accMap.put(opp.AccountId,'1');
                accIds.add(opp.AccountId);
            }
        }
        if(accIds.size()>0)
        {
            queryResult = [select Id,OwnerId from Account where Id in:accIds];
        }
        return queryResult;
    }
    
    static public String getTargetDate(String DateStr) 
    {   //Input: dd/MM/YYYY 
        if (DateStr != null && DateStr != '')
        {        
              String[] arrDate = DateStr.split('/',0);
              if(arrDate[0].length()<2)
                    arrDate[0] = '0'+arrDate[0];
              if(arrDate[1].length()<2)
                    arrDate[1] = '0'+arrDate[1];
              DateStr = arrDate[2]+'-'+arrDate[1]+'-'+arrDate[0];//t.format('yyyy-MM-dd');
              DateStr = DateStr+'T00:00:00Z';
              //formatting complies with SOQL   
        }    
        return DateStr; 
    }
    
    static public String getTargetEndDate(String DateStr) 
    {   //Input: dd/MM/YYYY 
        if (DateStr != null && DateStr != '')
        {        
              String[] arrDate = DateStr.split('/',0);
              if(arrDate[0].length()<2)
                    arrDate[0] = '0'+arrDate[0];
              if(arrDate[1].length()<2)
                    arrDate[1] = '0'+arrDate[1];
              DateStr = arrDate[2]+'-'+arrDate[1]+'-'+arrDate[0];//t.format('yyyy-MM-dd');
              String strTempDate = DateStr;
              strTempDate += 'T23:59:59Z';
              DateStr = strTempDate;
              //formatting complies with SOQL   
        }    
        return DateStr; 
    }
    
    static public String GenerateSOQL(String stageName,String initialApptDateOpType,
    String lastModifiedDateOpType,String initialApptDate,String lastModifiedDate,
    String sinitialApptDateOpType,String slastModifiedDateOpType,String sinitialApptDate,
    String slastModifiedDate)
    {
        Map<String, String> operatorMap = new Map<String, String>{'0' => '=', '1' => '<', '2' => '>', '3' => '<=', '4' => '>='};
        String strTempSoql = '';
        strTempSoql =  'select Id,OwnerId,AccountId,StageName from Opportunity where AccountId in :accountIds';
        if(stageName != '*')
        {
            strTempSoql  += ' and StageName=\''+ stageName +'\'';
        }
        if(initialApptDate != null && initialApptDate != '')
        {
        	initialApptDateOpType = operatorMap.get(initialApptDateOpType);
            if(initialApptDateOpType == '=')
            {
                strTempSoql += ' and (Initial_Appt_Date__c >='+getTargetDate(initialApptDate)+' and Initial_Appt_Date__c<='+ getTargetEndDate(initialApptDate) +')';
            }
            else if(initialApptDateOpType == '<' || initialApptDateOpType == '>=')
            {
                strTempSoql += ' and Initial_Appt_Date__c '+initialApptDateOpType+' '+getTargetDate(initialApptDate);
            }
            else if(initialApptDateOpType == '<=' || initialApptDateOpType == '>')
            {
                strTempSoql += ' and Initial_Appt_Date__c '+initialApptDateOpType+' '+getTargetEndDate(initialApptDate);
            }
        }
        if(lastModifiedDate != null && lastModifiedDate != '')
        {
        	lastModifiedDateOpType = operatorMap.get(lastModifiedDateOpType);
            if(lastModifiedDateOpType == '=')
            {
                strTempSoql += ' and (LastModifiedDate >='+getTargetDate(lastModifiedDate)+' and LastModifiedDate<='+ getTargetEndDate(lastModifiedDate) +')';
            }
            else if(lastModifiedDateOpType == '<' || lastModifiedDateOpType == '>=')
            {
                strTempSoql += ' and LastModifiedDate '+lastModifiedDateOpType+' '+getTargetDate(lastModifiedDate);
            }
            else if(lastModifiedDateOpType == '<=' || lastModifiedDateOpType == '>')
            {
                strTempSoql += ' and LastModifiedDate '+lastModifiedDateOpType+' '+getTargetEndDate(lastModifiedDate);
            }
        }
        if(sinitialApptDate != null && sinitialApptDate != '')
        {
        	sinitialApptDateOpType = operatorMap.get(sinitialApptDateOpType);
            if(sinitialApptDateOpType == '=')
            {
                strTempSoql += ' and (Initial_Appt_Date__c >='+getTargetDate(sinitialApptDate)+' and Initial_Appt_Date__c<='+ getTargetEndDate(sinitialApptDate) +')';
            }
            else if(sinitialApptDateOpType == '<' || sinitialApptDateOpType == '>=')
            {
                strTempSoql += ' and Initial_Appt_Date__c '+sinitialApptDateOpType+' '+getTargetDate(sinitialApptDate);
            }
            else if(sinitialApptDateOpType == '<=' || sinitialApptDateOpType == '>')
            {
                strTempSoql += ' and Initial_Appt_Date__c '+sinitialApptDateOpType+' '+getTargetEndDate(sinitialApptDate);
            }
        }
        if(slastModifiedDate != null && slastModifiedDate != '')
        {
        	slastModifiedDateOpType = operatorMap.get(slastModifiedDateOpType);
            //strTempSoql += ' and slastModifiedDate '+slastModifiedDateOpType+' '+getTargetDate(slastModifiedDate);
            
            if(slastModifiedDateOpType == '=')
            {
                strTempSoql += ' and (LastModifiedDate >='+getTargetDate(slastModifiedDate)+' and LastModifiedDate<='+ getTargetEndDate(slastModifiedDate) +')';
            }
            else if(slastModifiedDateOpType == '<' || slastModifiedDateOpType == '>=')
            {
                strTempSoql += ' and LastModifiedDate '+slastModifiedDateOpType+' '+getTargetDate(slastModifiedDate);
            }
            else if(slastModifiedDateOpType == '<=' || slastModifiedDateOpType == '>')
            {
                strTempSoql += ' and LastModifiedDate '+slastModifiedDateOpType+' '+getTargetEndDate(slastModifiedDate);
            }
        }
        strTempSoql += ' and AccountId != null';
    
        return strTempSoql;
    }
    
    @isTest
    static void testReassignmentUtility()
    {
        User currentUser = [select Id, Name from User where Id = :UserInfo.getUserId()];
        System.assertEquals(currentUser.Name, ReassignmentUtility.getOwnerName(currentUser.Id));
        System.assertEquals('N/A', ReassignmentUtility.getOwnerName('acmeacme'));
        // Creates test data.
        Integer size = 10;
        String accRecordTypeId = [select Id from RecordType where Name = 'China Smart Account Record Type' and sObjectType = 'Account'].Id;
        List<Account> accounts = new List<Account>();
        for(Integer i = 0; i < size; i++)
        {
            accounts.add(new Account(RecordTypeId = accRecordTypeId, Name = 'Test_Acc_00' + i));
        }
        insert accounts;
        Date currentDate = Date.today();
        currentDate = currentDate.addYears(5);
        Datetime currentTime = Datetime.now();
        currentTime = currentTime.addYears(5);
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 0; i < size; i++)
        {
            opps.add(new Opportunity(Name = 'Test_Opp_00' + i, Email__c = 'test.' + i + '@m.com', AccountId = accounts[i].Id, Initial_Appt_Date__c = currentTime, CloseDate = currentDate, StageName = 'Set Appt', China_Sales_Type__c = 'New'));
        }
        insert opps;
        // Creates data completely.
        Set<Id> oppIds = new Set<Id>();
        for(Opportunity opp : opps)
        {
            oppIds.add(opp.Id);
        }
        opps = [select Id, AccountId from Opportunity where Id in :oppIds];
        String oppQueryString = 'select Id, Name, AccountId from Opportunity where AccountId in :accountIds';
        System.assertEquals(size, ReassignmentUtility.QueryMatchItems(oppQueryString, accounts).size());
        System.assertEquals(size, ReassignmentUtility.FindTranAccByOpp(opps).size());
        System.assertEquals('2011-01-01T00:00:00Z', ReassignmentUtility.getTargetDate('1/1/2011'));
        System.assertEquals('2011-01-01T23:59:59Z', ReassignmentUtility.getTargetEndDate('1/1/2011'));
        String stageName = 'Set Appt';
        String initialApptDateOptype = '0';
        String lastModifiedDateOpType = '0';
        String initialApptDate = '1/1/2011';
        String lastModifiedDate = '2/2/2011';
        String sinitialApptDateOpType = '0';
        String slastModifiedDateOpType = '0';
		String sinitialApptDate = '3/3/2011';
		String slastModifiedDate = '5/5/2011';
		System.assertEquals
		(
			'select Id,OwnerId,AccountId,StageName from Opportunity where AccountId in :accountIds and StageName=\'Set Appt\' and (Initial_Appt_Date__c >=2011-01-01T00:00:00Z and Initial_Appt_Date__c<=2011-01-01T23:59:59Z) and (LastModifiedDate >=2011-02-02T00:00:00Z and LastModifiedDate<=2011-02-02T23:59:59Z) and (Initial_Appt_Date__c >=2011-03-03T00:00:00Z and Initial_Appt_Date__c<=2011-03-03T23:59:59Z) and (LastModifiedDate >=2011-05-05T00:00:00Z and LastModifiedDate<=2011-05-05T23:59:59Z) and AccountId != null', 
			ReassignmentUtility.GenerateSOQL(stageName, initialApptDateOpType, lastModifiedDateOpType, initialApptDate, lastModifiedDate, sinitialApptDateOpType, slastModifiedDateOpType, sinitialApptDate, slastModifiedDate)
		);
		stageName = 'Set Appt';
		initialApptDateOptype = '1';
		lastModifiedDateOpType = '1';
		initialApptDate = '1/1/2011';
		lastModifiedDate = '2/2/2011';
		sinitialApptDateOpType = '1';
		slastModifiedDateOpType = '1';
		sinitialApptDate = '3/3/2011';
		slastModifiedDate = '5/5/2011';
		System.assertEquals
        (
            'select Id,OwnerId,AccountId,StageName from Opportunity where AccountId in :accountIds and StageName=\'Set Appt\' and Initial_Appt_Date__c < 2011-01-01T00:00:00Z and LastModifiedDate < 2011-02-02T00:00:00Z and Initial_Appt_Date__c < 2011-03-03T00:00:00Z and LastModifiedDate < 2011-05-05T00:00:00Z and AccountId != null',
            ReassignmentUtility.GenerateSOQL(stageName, initialApptDateOpType, lastModifiedDateOpType, initialApptDate, lastModifiedDate, sinitialApptDateOpType, slastModifiedDateOpType, sinitialApptDate, slastModifiedDate)
        );
		stageName = '*';
        initialApptDateOptype = '2';
        lastModifiedDateOpType = '2';
        initialApptDate = '1/1/2011';
        lastModifiedDate = '2/2/2011';
        sinitialApptDateOpType = '2';
        slastModifiedDateOpType = '2';
        sinitialApptDate = '3/3/2011';
        slastModifiedDate = '5/5/2011';
        System.assertEquals
        (
            'select Id,OwnerId,AccountId,StageName from Opportunity where AccountId in :accountIds and Initial_Appt_Date__c > 2011-01-01T23:59:59Z and LastModifiedDate > 2011-02-02T23:59:59Z and Initial_Appt_Date__c > 2011-03-03T23:59:59Z and LastModifiedDate > 2011-05-05T23:59:59Z and AccountId != null',
            ReassignmentUtility.GenerateSOQL(stageName, initialApptDateOpType, lastModifiedDateOpType, initialApptDate, lastModifiedDate, sinitialApptDateOpType, slastModifiedDateOpType, sinitialApptDate, slastModifiedDate)
        ); 
    }
}