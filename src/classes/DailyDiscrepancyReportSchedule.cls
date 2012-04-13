global class DailyDiscrepancyReportSchedule implements Schedulable 
{
	public static final String FinanceUserProfileId = '00e40000000jdzW';  
    public static final String DailyDiscrepancyReportEmailTemplate = '00X90000000crtV'; //'00XO0000000LweU';
	private Set<String> schoolNameSet = new Set<String>();
	private List<List<String>> schoolNameLists = new List<List<String>>(); // Stores school name list. Each list is a group.
	
	public DailyDiscrepancyReportSchedule()
	{
		List<User> financialUsers = [select Id, Name, UserRoleId, SchoolName__c from User where ProfileId = :FinanceUserProfileId and IsActive = true];
		if(financialUsers.size() > 0)
		{
			for(User tempUser : financialUsers)
			{
				if(tempUser.SchoolName__c != null)
				{
					schoolNameSet.add(tempUser.SchoolName__c.replace('_', ' '));
				}
			}
			Integer schoolCount = schoolNameSet.size();
			Integer groupNum = 4;
			Integer groupSize = Math.ceil(schoolCount/groupNum).intValue();
			Integer listSize = 0;
			List<String> tempSchoolNames; // = new List<String>();
			for(String schoolName : schoolNameSet)
			{ 
				if(schoolNameLists.size() < groupNum)
				{
					if(listSize == 0)
					{
						tempSchoolNames = new List<String>();
						tempSchoolNames.add(schoolName);
						schoolNameLists.add(tempSchoolNames);
						listSize++;
						continue;
					}
					tempSchoolNames.add(schoolName); 
					listSize++;
					if(listSize == groupSize)
					{
						listSize = 0;
					}
				}
				else
				{
					schoolNameLists[schoolNameLists.size() - 1].add(schoolName); // Adds remain school name.
				}
			}
		}
	}
	
	global void execute(SchedulableContext sc)
	{
		if(schoolNameLists.size() > 0)
		{
			//Batch.
			for(List<String> schoolNameList : schoolNameLists)
			{
				DailyDiscrepancyReportBatch batch = new DailyDiscrepancyReportBatch();
				batch.schoolNameList = schoolNameList;
				Database.executeBatch(batch);
			}
		}
	}
	
	/*global void executeCoustomBatch()
	{
		if(schoolNameLists.size() > 0)
		{
			//Batch.
			for(List<String> schoolNameList : schoolNameLists)
			{
				DailyDiscrepancyReportBatch batch = new DailyDiscrepancyReportBatch();
				batch.schoolNameList = schoolNameList;
				Database.executeBatch(batch);
			}
		}
	}*/
	
	@isTest
	static void testDailyDiscrepancyReportSchedule()
	{
		DailyDiscrepancyReportSchedule controller = new DailyDiscrepancyReportSchedule();
	}
}