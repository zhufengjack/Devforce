public class BR_MXWorkCalenController 
{
    public String strSalesGroupId = '';

    public String getSalesGroupId()
    {
        return strSalesGroupId;
    }
    
    public void setSalesGroupId(String salesGroupId)
    {
        strSalesGroupId = salesGroupId;
    }
    
    public List<SelectOption> getSalesGroupList()
    {
        List<SelectOption> options = new List<SelectOption>();  
        options.add(new SelectOption('','---please select a group---'));
        User currentUser = [select Id, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId()];
        String profileName = currentUser.Profile.Name;
        String roleName = currentUser.UserRole.Name;
        if(roleName.equals('English Town'))
        {   // System administrator.
                List<UserRole> salesRoles = [select Id, Name from UserRole where (Name like 'Brazil Sales Group%' and (not name like '%lead%')) or Name = 'US TP Sales' or (Name like 'Mexico TP Sales Group%' and (not Name like '%lead%')) order by Name];
                for(UserRole role : salesRoles)
                {
                    options.add(new SelectOption(role.Id, role.Name));
                }
        }
        else if(roleName.equals('Mexico Management'))
        {   // Mexico.
                List<UserRole> mexicoSalesRoles = [select Id, Name from UserRole where Name = 'US TP Sales' or (Name like 'Mexico TP Sales Group%' and (not Name like '%lead%'))];
                for(UserRole role : mexicoSalesRoles)
                {
                    options.add(new SelectOption(role.Id, role.Name));
                }
        }
        else if(roleName.equals('Europe and Americas Management'))
        {   // Brazil.
                List<UserRole> brazilSalesRoles = [select Id, Name from UserRole where Name like 'Brazil Sales Group%' and (not name like '%lead%')];
                for(UserRole role : brazilSalesRoles)
                {
                    options.add(new SelectOption(role.Id, role.Name));
                }
        }
        return options;
    }
    
    public List<SelectOption> getSalesList()
    {
        List<SelectOption> options = new List<SelectOption>();
        if(strSalesGroupId != '' && strSalesGroupId != null)
        {
                List<User> users = [select Id,Name from User where UserRoleId=:strSalesGroupId and IsActive=true]; 
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
    
    @isTest
    static void testBR_MXWorkCalenController()
    {
            User testETownUser = [select Id from User where UserRole.Name = 'Englishtown' and IsActive = true limit 1];
            System.runAs(testETownUser)
            {
                BR_MXWorkCalenController controller = new BR_MXWorkCalenController();
                List<SelectOption> options = controller.getSalesGroupList();
                if(options.size() > 1)
                {
                    controller.setSalesGroupId(options[1].getValue());
                }
                controller.getSalesList();
                controller.getSalesGroupId();
                controller.setSalesGroupId('test');
            }
            User testMexicoUser = [select Id from User where UserRole.Name = 'Mexico Management' and IsActive = true limit 1];
            System.runAs(testMexicoUser)
            {
                BR_MXWorkCalenController controller = new BR_MXWorkCalenController();
                controller.getSalesGroupList();
                controller.getSalesList();
            }
            User testEuropeUser = [select Id from User where UserRole.Name = 'Europe and Americas Management' and IsActive = true limit 1];
            System.runAs(testEuropeUser)
            {
                BR_MXWorkCalenController controller = new BR_MXWorkCalenController();
                controller.getSalesGroupList();
            }
    }
}