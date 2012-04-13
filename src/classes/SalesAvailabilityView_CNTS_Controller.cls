public class SalesAvailabilityView_CNTS_Controller {
	public SalesAvailabilityView_CNTS_Controller()
	{
		report = new China_Appt_Assignment_Report__c();
		results = GetAppointmentsDetails();
	}
	
	public List<AppointmentDetailInfoNew> results {get;set;}
	public China_Appt_Assignment_Report__c Report {get;set;}
	
	public List<AppointmentDetailInfoNew> GetAppointmentsDetails()
	{
		List<AppointmentDetailInfoNew> results = new List<AppointmentDetailInfoNew>();
		String school = Apexpages.currentPage().getParameters().get('school');
		String currentDate = Apexpages.currentPage().getParameters().get('date');
		if(school != null && currentDate != null)
		{
			Integer maxTarget = 0;
			Integer totalAppts = 0;
			Integer remainingAppts = 0;
			String[] dateArr = currentDate.trim().split('/');
			String year = dateArr[2].trim();
			String month = dateArr[1].trim();
			String day = dateArr[0].trim();
			String formateDate = day + '/' + month + '/' + year;
			Date sDate;
			try
			{
				sDate = date.parse(formateDate);
			}
			Catch(Exception ex)
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid date:' + formateDate));
				return results;
			}
			String[] schools = school.split('_');
			String schoolStr = school;//schools[0] + ' ' + schools[1];
			List<Appt_Max_target__c> entries = [select Max_target__c, Day__c, Month__C, Year__c, School__c, City__c, Date__c from Appt_Max_target__c where  School__c = :schoolStr and Date__c = :sDate order by LastModifiedDate desc  limit 1];
			if(entries != null && !entries.isEmpty())
			{
				maxTarget = entries[0].Max_target__c.round().intValue();
			}
			List<China_Appt_Assignment_Report__c> items = [select Appointment_DateTime__c  from China_Appt_Assignment_Report__c where School__c = :schoolStr and Appointment_Date__c = :sDate];
			totalAppts = items.size();
			DateTime startTime = datetime.newInstance(integer.valueof(year), integer.valueof(month), integer.valueof(day), 10, 0, 0);
			DateTime endTime = startTime.addMinutes(30);
			for(Integer i = 0; i < 20; i++)
			{
				String sNumber = '';
				if(i < 9)
				{
					sNUmber = '0' + String.valueof(i+1);
				}
				else
				{
					sNUmber = String.valueof(i+1);
				}
				AppointmentDetailInfoNew result = new AppointmentDetailInfoNew(sNumber, startTime.addMinutes(30*i), endtime.addMinutes(i*30), 0);
				results.add(result);
			}
			system.debug(results);
			if(!items.isEmpty())
			{
				Integer time20Count = 0;				
				for(AppointmentDetailInfoNew result : results)
				{										
					for(China_Appt_Assignment_Report__c item : items)
					{
						if(item.Appointment_DateTime__c >= result.StartTime && item.Appointment_DateTime__c < result.EndTime)
						{
							result.AppointmentsCount++;
						}
						else if(item.Appointment_DateTime__c == datetime.newInstance(integer.valueof(year), integer.valueof(month), integer.valueof(day), 20, 0, 0) && result.EndTime == datetime.newInstance(integer.valueof(year), integer.valueof(month), integer.valueof(day), 20, 0, 0))
						{
							time20COunt ++;
						}
					}
				}
				results[19].AppointmentsCount += time20COunt;
			}
			// the other rows for this list
			remainingAppts = maxTarget - totalAppts;
			AppointmentDetailInfoNew remainingResult1 = new AppointmentDetailInfoNew('21', dateTime.now(), datetime.now(), totalAppts);
			remainingResult1.FormatHour = 'Total Appts:';
			results.add(remainingResult1);
			AppointmentDetailInfoNew remainingResult2 = new AppointmentDetailInfoNew('22', dateTime.now(), datetime.now(), maxTarget);
			remainingResult2.FormatHour = 'Total Availabilities:';
			results.add(remainingResult2);
			AppointmentDetailInfoNew remainingResult3 = new AppointmentDetailInfoNew('23', dateTime.now(), datetime.now(), remainingAppts);
			remainingResult3.FormatHour = 'Remaining:';
			results.add(remainingResult3);
		}
		return results;
	}
	
	public List<SelectOption> getSchoolList()
    {
    	List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','---please select a group---'));
        
        List<UserRole> salesGroups = QueryRootSalesGroup();
        if(salesGroups == null) return options;
        for(UserRole groupRole:salesGroups)
        {
        	//options.add(new SelectOption(groupRole.Id,groupRole.Name));
        	options.add(new SelectOption(groupRole.Name,groupRole.Name));
        }
        return options;
    }
    
    private List<UserRole> QueryRootSalesGroup()
    {
    	List<UserRole> salesGroups = [Select u.Name, u.Id From UserRole u 
    	where u.Name like 'China Telesales%CC%' order by u.Name];
    	
    	return salesGroups;
    }
	// a custom class for appointment detail
	public class AppointmentDetailInfoNew
	{
		public AppointmentDetailInfoNew(String snumber, Datetime startTime, Datetime endTime, Integer apptCount)
		{
			this.SNumber = snumber;
			this.AppointmentsCount = apptCount;
			this.StartTime = startTime;
			this.EndTime = endTime;
			Integer startHour = startTime.hour();
			Integer startMinute = startTime.minute();			
			Integer endHour = endTime.hour();
			Integer endMinute = endTime.minute();
			this.FormatHour = String.valueof(startHour) + ':' + ((startMinute != 0)?String.valueof(startMinute):'00') + '-' +  String.valueof(endHour) + ':' + ((endMinute != 0)?String.valueof(endMinute):'00');
		}
		public String SNumber {get;set;}
		public String FormatHour {get;set;}
		public Integer AppointmentsCount {get;set;}
		public Datetime StartTime {get;set;}
		public Datetime EndTime {get;set;}
	}
	
	@isTest
	static void testController()
	{
		Date currentDate = Date.today();
		String day = String.valueOf(currentDate.day());
		String month = String.valueOf(currentDate.month());
		String year = String.valueOf(currentDate.year());
		String dateStr = day + '/' + month + '/' + year;	  
		Datetime currentTime = datetime.now();    		
    	Appt_Max_target__c target = new Appt_Max_target__c(Max_target__c = 100, School__c = 'BJ DZM', Date__c = currentDate);
    	insert target;
    	China_Appt_Assignment_Report__c report1 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, Appointment_DateTime__c = currentTime, School__c = 'BJ DZM');
    	insert report1;
    	China_Appt_Assignment_Report__c report2 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, Appointment_DateTime__c = currentTime, School__c = 'BJ DZM');
    	insert report2;
    	PageReference page = new PageReference('/apex/SalesAvailabilityView_CNTS?school=BJ_DZM&date=' + dateStr);
    	Test.setCurrentPage(page);
		SalesAvailabilityView_CNTS_Controller controller = new SalesAvailabilityView_CNTS_Controller();
		controller.getSchoolList();
		List<AppointmentDetailInfoNew> results = controller.results;
		system.assert(results.size() >= 23);
	}
	@isTest
    static  void AppointmentDetailInfo()
    {
    	Datetime currentTime = datetime.now();
    	AppointmentDetailInfoNew info = new AppointmentDetailInfoNew('1', currentTime, currentTime, 2);
    }
}