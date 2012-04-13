/*
 * Controller for page: SalesAvailabilityView
 */
public class SalesAvailabilityViewController 
{
	public SalesAvailabilityViewController()
	{
		report = new China_Appt_Assignment_Report__c();
		results = GetAppointmentsDetails();
	}
	
	public List<AppointmentDetailInfo> results {get;set;}
	public China_Appt_Assignment_Report__c Report {get;set;}
	public String SalesSchool {get; set;}
	
	public List<AppointmentDetailInfo> GetAppointmentsDetails()
	{
		List<AppointmentDetailInfo> results = new List<AppointmentDetailInfo>();
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
			//Date sDate = date.parse(formateDate);
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
			String schoolStr = schools[0] + ' ' + schools[1];
			List<Appt_Max_target__c> entries = [select Max_target__c, Day__c, Month__C, Year__c, School__c, City__c, Date__c from Appt_Max_target__c where  School__c = :schoolStr and Date__c = :sDate order by LastModifiedDate desc  limit 1];
			if(!entries.isEmpty())
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
				AppointmentDetailInfo result = new AppointmentDetailInfo(sNumber, startTime.addMinutes(30*i), endtime.addMinutes(i*30), 0);
				results.add(result);
			}
			system.debug(results);
			if(!items.isEmpty())
			{
				Integer time20Count = 0;				
				for(AppointmentDetailInfo result : results)
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
			AppointmentDetailInfo remainingResult1 = new AppointmentDetailInfo('21', dateTime.now(), datetime.now(), totalAppts);
			remainingResult1.FormatHour = 'Total Appts:';
			results.add(remainingResult1);
			AppointmentDetailInfo remainingResult2 = new AppointmentDetailInfo('22', dateTime.now(), datetime.now(), maxTarget);
			remainingResult2.FormatHour = 'Total Availabilities:';
			results.add(remainingResult2);
			AppointmentDetailInfo remainingResult3 = new AppointmentDetailInfo('23', dateTime.now(), datetime.now(), remainingAppts);
			remainingResult3.FormatHour = 'Remaining:';
			results.add(remainingResult3);
		}
		return results;
	}
	
	public List<SelectOption> getSchoolList()
	{
		List<SelectOption> options = new List<SelectOption>();
		options.add(new SelectOption('','-School-'));
		List<UserRole> roles = [select Id, Name from UserRole where Name like 'China ______ Sales Consultant' order by Name];
		if(roles.size() > 0)
		{
			for(UserRole role : roles)
	        {
	            String schoolValue = role.Name.subString(6, 12);
	            String schoolName = schoolValue.replace('_', ' ');
	            options.add(new SelectOption(schoolValue, schoolName));
	        }
		}
		
	    return options;
	}
	
	// a custom class for appointment detail
	public class AppointmentDetailInfo
	{
		public AppointmentDetailInfo(String snumber, Datetime startTime, Datetime endTime, Integer apptCount)
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
    	PageReference page = new PageReference('/apex/SalesAvailabilityView?school=BJ_DZM&date=' + dateStr);
    	Test.setCurrentPage(page);
		SalesAvailabilityViewController controller = new SalesAvailabilityViewController();
		List<AppointmentDetailInfo> results = controller.results;
		system.assert(results.size() >= 23);
	}
	@isTest
    static  void AppointmentDetailInfo()
    {
    	Datetime currentTime = datetime.now();
    	AppointmentDetailInfo info = new AppointmentDetailInfo('1', currentTime, currentTime, 2);
    }
}