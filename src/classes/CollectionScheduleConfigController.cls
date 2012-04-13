/**
 *controller for page CollectionScheduleConfig
*/
public class CollectionScheduleConfigController 
{
	Id currentUserProfileId = UserInfo.getProfileId();
    String action = ApexPages.currentPage().getParameters().get('action');  
    
	private static final Id BrazilCountryManagerProfileId = '00e30000000hnba';
	private static final Id MexicoCountryManagerProfileId = '00e40000000i262';
	private static final Id EuropeAndAmericasManagerProfileId = '00e40000000i20J';
		
	public CollectionScheduleConfigController() 
	{
		initConfig();
	}
	
	public Boolean EditMode { get; set;}
	public CollectionScheduleConfig__c Config {get; set;}	
	public String ConfigurationName {get; set;} 
	
	public String Phone1 { get; set; }
	public String Phone2 { get; set; }
	public String Phone3 { get; set; }
	public String Phone4 { get; set; }
	public String Phone5 { get; set; }
	
	public String Email1 { get; set; }
	public String Email2 { get; set; }
	public String Email3 { get; set; }
	public String Email4 { get; set; }
	public String Email5 { get; set; }
	
	public String SMS1 { get; set; }
	public String SMS2 { get; set; }
	public String SMS3 { get; set; }
	public String SMS4 { get; set; }
	public String SMS5 { get; set; }
	
	
	private void initConfig()
	{
		EditMode = false;
		String region;
		String soql = 'select Id, Name, First_Date_Of_Email_Task__c, First_Date_Of_Phone_Task__c, First_Date_Of_SMS_Task__c, Second_Date_Of_Email_Task__c, Second_Date_Of_Phone_Task__c, Second_Date_Of_SMS_Task__c, Third_Date_Of_Email_Task__c, Third_Date_Of_Phone_Task__c, Third_Date_Of_SMS_Task__c, Fourth_Date_Of_Email_Task__c, Fourth_Date_Of_Phone_Task__c, Fourth_Date_Of_SMS_Task__c, Fifth_Date_Of_Email_Task__c, Fifth_Date_Of_Phone_Task__c, Fifth_Date_Of_SMS_Task__c, Region__c from CollectionScheduleConfig__c';
		if(currentUserProfileId == MexicoCountryManagerProfileId)
		{
			region = 'MexicoCountry';
			soql += ' where Region__c = \'MexicoCountry\' limit 1';
		}
		else if(currentUserProfileId == BrazilCountryManagerProfileId || currentUserProfileId == EuropeAndAmericasManagerProfileId)
		{
			region = 'BrazilOrEuropeOrAmerica';
			soql += ' where Region__c = \'BrazilOrEuropeOrAmerica\' limit 1';
		}
		//just for test
		else
		{
			region = 'AdminForTest';
			soql += ' where Region__c = \'AdminForTest\' limit 1';
		}
		List<CollectionScheduleConfig__c> configs = database.query(soql);
		if(!configs.isEmpty())
		{
			Config = configs[0];
			Phone1 = (Config.First_Date_Of_Phone_Task__c != null)?(String.valueof(Config.First_Date_Of_Phone_Task__c.intvalue())):'';
			Phone2 = (Config.Second_Date_Of_Phone_Task__c != null)?(String.valueof(Config.Second_Date_Of_Phone_Task__c .intvalue())):'';
			Phone3 = (Config.Third_Date_Of_Phone_Task__c != null)?(String.valueof(Config.Third_Date_Of_Phone_Task__c .intvalue())):'';
			Phone4 = (Config.Fourth_Date_Of_Phone_Task__c != null)?(String.valueof(Config.Fourth_Date_Of_Phone_Task__c .intvalue())):'';
			Phone5 = (Config.Fifth_Date_Of_Phone_Task__c != null)?(String.valueof(Config.Fifth_Date_Of_Phone_Task__c .intvalue())):'';
			Email1 = (Config.First_Date_Of_Email_Task__c != null)?(String.valueof(Config.First_Date_Of_Email_Task__c .intvalue())):'';
			Email2 = (Config.Second_Date_Of_Email_Task__c != null)?(String.valueof(Config.Second_Date_Of_Email_Task__c .intvalue())):'';
			Email3 = (Config.Third_Date_Of_Email_Task__c != null)?(String.valueof(Config.Third_Date_Of_Email_Task__c .intvalue())):'';
			Email4 = (Config.Fourth_Date_Of_Email_Task__c != null)?(String.valueof(Config.Fourth_Date_Of_Email_Task__c .intvalue())):'';
			Email5 = (Config.Fifth_Date_Of_Email_Task__c != null)?(String.valueof(Config.Fifth_Date_Of_Email_Task__c .intvalue())):'';
			SMS1 = (Config.First_Date_Of_SMS_Task__c != null)?(String.valueof(Config.First_Date_Of_SMS_Task__c .intvalue())):'';
			SMS2 = (Config.Second_Date_Of_SMS_Task__c != null)?(String.valueof(Config.Second_Date_Of_SMS_Task__c .intvalue())):'';
			SMS3 = (Config.Third_Date_Of_SMS_Task__c != null)?(String.valueof(Config.Third_Date_Of_SMS_Task__c .intvalue())):'';
			SMS4 = (Config.Fourth_Date_Of_SMS_Task__c != null)?(String.valueof(Config.Fourth_Date_Of_SMS_Task__c .intvalue())):'';
			SMS5 = (Config.Fifth_Date_Of_SMS_Task__c != null)?(String.valueof(Config.Fifth_Date_Of_SMS_Task__c .intvalue())):'';
			ConfigurationName = Config.Name;
			if(action == 'edit')
			{
				EditMode = true;
			}
		}
		else
		{
			Config = new CollectionScheduleConfig__c(Region__c = region);
			EditMode = true;
		}
	}
	
	public PageReference Save()
	{
		try
		{	
			if(Phone1 != null && Phone1 != '')
			{
				Config.First_Date_Of_Phone_Task__c = decimal.valueof(Phone1);
			}
			else
			{
				Config.First_Date_Of_Phone_Task__c  = null;
			}
			if(Phone2 != null && Phone2 != '')
			{
				Config.Second_Date_Of_Phone_Task__c = decimal.valueof(Phone2);
			}
			else
			{
				Config.Second_Date_Of_Phone_Task__c = null;
			}
			if(Phone3 != null && Phone3 != '')
			{
				Config.Third_Date_Of_Phone_Task__c = decimal.valueof(Phone3);
			}
			else
			{
				Config.Third_Date_Of_Phone_Task__c = null;
			}
			if(Phone4 != null && Phone4 != '')
			{
				Config.Fourth_Date_Of_Phone_Task__c = decimal.valueof(Phone4);
			}
			else
			{
				Config.Fourth_Date_Of_Phone_Task__c = null;
			}
			if(Phone5 != null && Phone5 != '')
			{
				Config.Fifth_Date_Of_Phone_Task__c = decimal.valueof(Phone5);
			}
			else
			{
				Config.Fifth_Date_Of_Phone_Task__c = null;
			}
			if(Email1 != null && Email1 != '')
			{
				Config.First_Date_Of_Email_Task__c =  decimal.valueof(Email1);
			}
			else
			{
				Config.First_Date_Of_Email_Task__c = null;
			}
			if(Email2 != null && Email2 != '')
			{
				Config.Second_Date_Of_Email_Task__c = decimal.valueof(Email2);
			}
			else
			{
				Config.Second_Date_Of_Email_Task__c = null;
			}
			if(Email3 != null && Email3 != '')
			{
				Config.Third_Date_Of_Email_Task__c = decimal.valueof(Email3);
			}
			else
			{
				Config.Third_Date_Of_Email_Task__c = null;
			}
			if(Email4 != null && Email4 != '')
			{
				Config.Fourth_Date_Of_Email_Task__c = decimal.valueof(Email4);
			}
			else
			{
				Config.Fourth_Date_Of_Email_Task__c = null;
			}
			if(Email5 != null && Email5 != '')
			{
				Config.Fifth_Date_Of_Email_Task__c = decimal.valueof(Email5);
			}
			else
			{
				Config.Fifth_Date_Of_Email_Task__c = null;
			}
			if(SMS1 != null && SMS1 != '')
			{
				Config.First_Date_Of_SMS_Task__c = decimal.valueof(SMS1);
			}
			else
			{
				Config.First_Date_Of_SMS_Task__c = null;
			}
			if(SMS2 != null && SMS2 != '')
			{
				Config.Second_Date_Of_SMS_Task__c = decimal.valueof(SMS2);
			}
			else
			{
				Config.Second_Date_Of_SMS_Task__c = null;
			}
			if(SMS3 != null && SMS3 != '')
			{
				Config.Third_Date_Of_SMS_Task__c = decimal.valueof(SMS3);
			}
			else
			{
				Config.Third_Date_Of_SMS_Task__c = null;
			}
			if(SMS4 != null && SMS4 != '')
			{
				Config.Fourth_Date_Of_SMS_Task__c = decimal.valueof(SMS4);
			}
			else
			{
				Config.Fourth_Date_Of_SMS_Task__c = null;
			}
			if(SMS5 != null && SMS5 != '')
			{
				Config.Fifth_Date_Of_SMS_Task__c = decimal.valueof(SMS5);
			}
			else
			{
				Config.Fifth_Date_Of_SMS_Task__c = null;
			}
			Config.Name = ConfigurationName;
			upsert Config;
			PageReference currentPage = new PageReference('/apex/CollectionScheduleConfig');
	        currentPage.setRedirect(true);
	        return currentpage;
		}
		catch(Exception ex)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'Failure:' + ex.getMessage()));
		}
		return null;
	}
	
	public PageReference Edit()
	{
		PageReference currentPage = new PageReference('/apex/CollectionScheduleConfig?action=edit');
        currentPage.setRedirect(true);
        return currentpage;
	}
	
	public PageReference Cancel()
	{
		PageReference currentPage = new PageReference('/apex/CollectionScheduleConfig');
        currentPage.setRedirect(true);
        return currentpage;
	}
	
	@istest
	static void testController()
	{
		CollectionScheduleConfigController controller = new CollectionScheduleConfigController();
		controller.Save();
		controller.Cancel();
		controller.Edit();
	}
}