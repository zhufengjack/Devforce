public class MassTransferFromTsController 
{
  	String ownerName = '';
    String ownerOpType = '';
    String stageName = '';
    String stageOpType = ''; 

    String initialApptDateOpType1 = '';
    String lastModifiedDateOpType1 = '';
    String initialApptDate1 = '';
    String lastModifiedDate1 = '';

    String initialApptDateOpType2 = '';
    String lastModifiedDateOpType2 = '';
    String initialApptDate2 = '';
    String lastModifiedDate2 = ''; 

    String SchoolRoleId = '';
    String strSchoolName = '';
    List<SelectOption> ownerLists = null;
    
    Boolean haveAuthority = false;

    public String getSchoolName()
    {
        return strSchoolName;
    }
    public void setSchoolName(String schoolName)
    {
        strSchoolName = schoolName;
    }
    public String getLastModifiedDate1() {
        return lastModifiedDate1;
    }
    public void setLastModifiedDate1(String strLastModifiedDate) {
        this.lastModifiedDate1 = strLastModifiedDate;
    }
    
    public String getInitialApptDate1() {
        return initialApptDate1;
    }
    public void setInitialApptDate1(String strInitialApptDate) {
        this.initialApptDate1 = strInitialApptDate;
    }

    public String getLastModifiedDate2() {
        return lastModifiedDate2;
    }
    public void setLastModifiedDate2(String strLastModifiedDate) {
        this.lastModifiedDate2 = strLastModifiedDate;
    }
    
    public String getInitialApptDate2() {
        return initialApptDate2;
    }
    public void setInitialApptDate2(String strInitialApptDate) {
        this.initialApptDate2 = strInitialApptDate;
    }
    
    public String getInitialApptDateOpType1() {
        return initialApptDateOpType1;
    }
    public void setInitialApptDateOpType1(String strInitialApptDateOpType) {
        this.initialApptDateOpType1 = strInitialApptDateOpType;
    }
    public String getLastModifiedDateOpType1() {
        return lastModifiedDateOpType1;
    }
    public void setLastModifiedDateOpType1(String strLastModifiedDateOpType) {
        this.lastModifiedDateOpType1 = strLastModifiedDateOpType;
    }

    public String getInitialApptDateOpType2() {
        return initialApptDateOpType2;
    }
    public void setInitialApptDateOpType2(String strInitialApptDateOpType) {
        this.initialApptDateOpType2 = strInitialApptDateOpType;
    }
    public String getLastModifiedDateOpType2() {
        return lastModifiedDateOpType2;
    }
    public void setLastModifiedDateOpType2(String strLastModifiedDateOpType) {
        this.lastModifiedDateOpType2 = strLastModifiedDateOpType;
    }
    
    public String getAccOwner() {
        return ownerName;
    }
    public void setAccOwner(String strOwnerName) {
        this.ownerName = strOwnerName;
    }
    public String getAccStage()
    {
        return stageName;
    }
    public void setAccStage(String strAccStage)
    {
        this.stageName = strAccStage;
    }
    public void setOwnerOpType(String strOwnerOpType)
    {
        this.ownerOpType = strOwnerOpType;
    }
    
    public String getOwnerOpType()
    {
        return ownerOpType;
    }
    public void setStageOpType(String strStageOpType)
    {
        this.stageOpType = strStageOpType;
    }
    
    public String getStageOpType()
    {
        return stageOpType; 
    }
    public MassTransferFromTsController()
    {
        List<User> users = [select Id, Name, Profile.Name, UserRole.Name, UserRoleId from User where Id = :UserInfo.getUserId() and Id != null limit 1 ];
        String userRoleName = '';
        String userProfileName = '';
		if(users.size() > 0)
		{
			userRoleName = users[0].UserRole.Name;
			userProfileName = users[0].Profile.Name;
		}
		if(userRoleName == 'China Telesales Director' || (userProfileName != null && userProfileName.toLowerCase().contains('system administrator new')))
		{
			haveAuthority = true;
		}
    }
   
    public List<SelectOption> getOwnerList() {
        List<SelectOption> options = new List<SelectOption>();
		
		List<UserRole> roles = [select Id, Name from UserRole where Name = :strSchoolName limit 1];
		if(roles.size() > 0)
		{
			SchoolRoleId = roles[0].Id;
		}
		
        if(strSchoolName != '' && strSchoolName != null)
        {
        	List<User> userList = [select Id, Name from User where UserRole.Name = :strSchoolName and IsActive = true Order by Name];
        	for(User tempUser : userList)
        	{
        		options.add(new SelectOption(tempUser.Id, tempUser.Name));
        	}
        }
        return options;
    }
    
    public List<SelectOption> getStageList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('*','All Stage')); 
        options.add(new SelectOption('Set Appt','Set Appt')); 
        options.add(new SelectOption('Showed Up - Followup','Showed Up - Followup')); 
        options.add(new SelectOption('Appt No Show - Rescheduled','Appt No Show - Rescheduled')); 
        options.add(new SelectOption('Appt No Show - Call Later','Appt No Show - Call Later')); 
        options.add(new SelectOption('Payment Pending','Payment Pending')); 
        options.add(new SelectOption('Closed Won','Closed Won')); 
        options.add(new SelectOption('Close/Lost -Show-Up','Close/Lost -Show-Up')); 
        options.add(new SelectOption('Close/Lost - No Show','Close/Lost - No Show')); 
        options.add(new SelectOption('Refunded','Refunded'));  
        return options;
    }
    
    public List<SelectOption> getSchoolList()
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--------Select a group--------'));

        if(haveAuthority)
        {
        	List<UserRole> roleList = [select Id, Name from UserRole where Name like 'China Telesales % CC%' order by Name];
        	if(roleList.size() > 0)
        	{
        		for(UserRole role : roleList)
        		{
        			options.add(new SelectOption(role.Name, role.Name));
        		}
        	}
        }	
        return options;
    }
    
    public PageReference DoAction()
    {
		PageReference toPage = null;
		OwnerReassignUtility ownerUtility = new OwnerReassignUtility();
        Integer intProcessCount = ownerUtility.UserBatchCount();
        Integer currentProcessCount = ownerUtility.getCurrentUserBatchCount();
		if(intProcessCount >4)
		{
			toPage = new PageReference('/apex/BatchExceedLimit');
			toPage.setRedirect(true);
			return toPage;
		}
		if(currentProcessCount > 0)
		{
			toPage = new PageReference('/apex/BatchExceedLimit?type=0');
			toPage.setRedirect(true);
			return toPage;
		}
		QueryReassignmentData reassign = new QueryReassignmentData();
		reassign.query='';
		reassign.ownerId = ownerName;
		reassign.schoolRoleId =  SchoolRoleId;
		reassign.stageName = stageName;
		reassign.strOperatorId = UserInfo.getUserId();
		
		reassign.initialApptDateOpType = initialApptDateOpType1;
		reassign.lastModifiedDateOpType =  lastModifiedDateOpType1;
		reassign.initialApptDate = initialApptDate1;
		reassign.lastModifiedDate = lastModifiedDate1;
		
		reassign.sinitialApptDateOpType = initialApptDateOpType2;
		reassign.slastModifiedDateOpType = lastModifiedDateOpType2;
		reassign.sinitialApptDate = initialApptDate2;
		reassign.slastModifiedDate = lastModifiedDate2;
		
		try
	    {
			ID batchprocessid = Database.executeBatch(reassign);
			
			toPage = new PageReference('/apex/BatchProcessSubmit');
			toPage.setRedirect(true);
			return toPage;
		}
		catch(System.DMLException e)
		{
	    	ApexPages.addMessages(e);
		}
		return toPage;	
	}
	    
	static TestMethod void testMassTransferFromTsController()
	{ 
        User u = [SELECT Id FROM User WHERE ProfileId = '00e40000000j2k8' AND IsActive = true LIMIT 1];
        System.runAS(u) 
        {	
            Test.setCurrentPageReference(new Pagereference('Page.MassTransfer_FromPage'));    
		    MassTransferFromTsController tranFrom = new MassTransferFromTsController();
        }
		MassTransferFromTsController tranFrom = new MassTransferFromTsController();
		tranFrom.getSchoolName();
		tranFrom.setSchoolName('China Telesales Guangzhou CC (A)');
		tranFrom.getLastModifiedDate1();
		tranFrom.setLastModifiedDate1('09/08/2009');
		tranFrom.getInitialApptDate1();
		tranFrom.setInitialApptDate1('09/08/2009');
		tranFrom.getLastModifiedDate2();
		tranFrom.setLastModifiedDate2('09/09/2009');
		tranFrom.getInitialApptDate2();
		tranFrom.setInitialApptDate2('09/09/2009');
		tranFrom.getInitialApptDateOpType1();
		tranFrom.setInitialApptDateOpType1('>');
		tranFrom.getLastModifiedDateOpType1();
		tranFrom.setLastModifiedDateOpType1('>');
		tranFrom.getInitialApptDateOpType2();
		tranFrom.setInitialApptDateOpType2('<');
		tranFrom.getLastModifiedDateOpType2();
		tranFrom.setLastModifiedDateOpType2('<');
		tranFrom.getAccOwner();
		tranFrom.setAccOwner('123');
		tranFrom.getAccStage();
		tranFrom.setAccStage('Set Appt');
		tranFrom.setOwnerOpType('=');
		tranFrom.getOwnerOpType();
		tranFrom.setStageOpType('=');
		tranFrom.getStageOpType();
		tranFrom.getStageList();
		tranFrom.getSchoolList();
		PageReference pr = tranFrom.DoAction();
		System.assert(true, pr.getURL().toLowerCase().contains('salesforce'));
    }
}