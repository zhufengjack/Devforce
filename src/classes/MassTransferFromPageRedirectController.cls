public class MassTransferFromPageRedirectController 
{	
	public MassTransferFromPageRedirectController()
	{

	}
	
	public PageReference setPageRedirect()
	{
		List<User> users = [select Id, Name, Profile.Name, UserRole.Name from User Where Id = :UserInfo.getUserId()];
		if(users.size() > 0)
		{
			String roleName = users[0].UserRole.Name;
			String profileName = users[0].Profile.Name;
			roleName = roleName.toLowerCase();
			profileName = profileName.toLowerCase();
			PageReference transferFromPage;
			if(roleName.contains('sales manager') && roleName.contains('china'))
			{
				transferFromPage = Page.MassTransferFromPageSmart;
			}
			else if(roleName.contains('europe and americas management'))
			{
				transferFromPage = Page.MassTransferFromPageBrazil;
			}
			else if(roleName.contains('china telesales director'))
			{
				transferFromPage = Page.MassTransferFromPageCNTS;
			}
			else if(profileName.contains('system administrator new'))
			{
				transferFromPage = Page.MassTransferFromPageSmart;
			}
			else
			{
				return null;
			}
			transferFromPage.setRedirect(true);	
			return transferFromPage;
		}
		return null;
	}
	
	@isTest
	static void testMassTransferFromPageRedirectController()
	{
	
	}
}