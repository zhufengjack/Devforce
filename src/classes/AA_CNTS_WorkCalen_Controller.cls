public with sharing class AA_CNTS_WorkCalen_Controller {
	public String strSalesGroupId = '';
	
	public String getSalesGroupId()
    {
        return strSalesGroupId;
    }
    public void setSalesGroupId(String salesGroupId)
    {
        strSalesGroupId = salesGroupId;
    }
    
	public List<SelectOption> getSalesGroupList(){
        List<SelectOption> options = QuerySalesGroupList();
        return options;
    }
    public List<SelectOption> getSalesList(){
        List<SelectOption> options = new List<SelectOption>();
        if(strSalesGroupId != '' && strSalesGroupId != null)
        {
        	List<User> users = QueryGroupUsers(strSalesGroupId);
        	for(User user:users)
        	{
        		options.add(new SelectOption(user.Id,user.Name));
        	}
        }
        else
        {
        	options.add(new SelectOption('','---please select a Sales---'));
        }
        
        return options;
    }
    public List<User> QueryGroupUsers(String groupId)
    {
    	List<User> users = new List<User>();
    	List<User> tempUsers = [select Id,Name from User where UserRoleId=:groupId and IsActive=true];
    	users.addAll(tempUsers);
    	return users;
    }
    private List<SelectOption> QuerySalesGroupList()
    {
    	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','---please select a group---'));
        
        List<UserRole> salesGroups = QueryRootSalesGroup();
        if(salesGroups == null) return options;
        for(UserRole groupRole:salesGroups)
        {
        	options.add(new SelectOption(groupRole.Id,groupRole.Name));
        }
        return options;
    }
    
    private List<UserRole> QueryRootSalesGroup()
    {
    	String profileName;
    	String userRoleName;
    	List<UserRole> salesGroups = new List<UserRole>();
    	List<User> currentUsers = [select Id, UserRole.Name, Profile.Name from User where Id = :UserInfo.getUserId() limit 1];
    	try
    	{
    		profileName = currentUsers[0].Profile.Name;
    		userRoleName = currentUsers[0].UserRole.Name;

	    	if(profileName != null && userRoleName != null)
	    	{
	    		List<UserRole> allSaleGroups = [Select u.Name, u.Id From UserRole u where u.Name like 'China Telesales%CC%' order by u.Name];
	    		for(UserRole saleGroup : allSaleGroups)
	    		{
	    			if(profileName.contains('System Administrator') || profileName.contains('System administrator') || (userRoleName == 'China Telesales Shanghai Director' && (saleGroup.Name.contains('Shanghai') || saleGroup.Name.contains('NJ_XJK'))) || (userRoleName == 'China Telesales Guangzhou Director' && saleGroup.Name.contains('Guangzhou')) || (userRoleName == 'China Telesales NJ_XJK Sales Director' && saleGroup.Name.contains('NJ_XJK')) )
	    			{
	    				salesGroups.add(saleGroup);
	    			}
	    		}
	    	}
    	}
    	catch(Exception ex){}

    	return salesGroups;
    }
    
    static TestMethod void AA_CNTS_WorkCalen_Controller_test(){
    	AA_CNTS_WorkCalen_Controller aCtrl = new AA_CNTS_WorkCalen_Controller();
    	List<UserRole> groups = aCtrl.QueryRootSalesGroup();
    	aCtrl.setSalesGroupId(groups[0].Id);
    	aCtrl.QueryGroupUsers(groups[0].Id);
    	aCtrl.getSalesGroupList();
    	aCtrl.getSalesList();
    	aCtrl.QuerySalesGroupList();
    }
}