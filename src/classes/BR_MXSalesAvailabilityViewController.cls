public class BR_MXSalesAvailabilityViewController 
{
    public List<AppointmentDetailInfo> results {get;set;}
    public China_Appt_Assignment_Report__c Report {get;set;}
    private String profileName;
    private String roleName;
    
    public BR_MXSalesAvailabilityViewController()
    {
        User currentUser = [select Id, Name, Profile.Name, UserRole.Name from User where Id = :UserInfo.getUserId() limit 1];
        profileName = currentUser.Profile.Name;
        roleName = currentUser.UserRole.Name;
        report = new China_Appt_Assignment_Report__c();
        String school = Apexpages.currentPage().getParameters().get('school');
        String currentDate = Apexpages.currentPage().getParameters().get('date');
        if(school == 'Brazil')
        {
            results = GetAppointmentsDetails(school, currentDate, 9, 24);
        }
        else if(school == 'Mexico')
        {
            results = GetAppointmentsDetails(school, currentDate, 10, 23);
        }
    }
    
    public List<AppointmentDetailInfo> GetAppointmentsDetails(String school, String currentDate, Integer startHour, Integer size)
    {
        List<AppointmentDetailInfo> results = new List<AppointmentDetailInfo>();
        if(school != null && currentDate != null)
        {
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
            
            String schoolStr = school;
            List<China_Appt_Assignment_Report__c> items = [select Appointment_DateTime__c  from China_Appt_Assignment_Report__c where Assignment_Org__c = :schoolStr and Appointment_Date__c = :sDate];
            totalAppts = items.size();
            DateTime startTime = datetime.newInstance(integer.valueof(year), integer.valueof(month), integer.valueof(day), startHour, 0, 0);
            DateTime endTime = startTime.addMinutes(30);
            for(Integer i = 0; i < size; i++)
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

            if(!items.isEmpty())
            {           
                for(AppointmentDetailInfo result : results)
                {                                       
                    for(China_Appt_Assignment_Report__c item : items)
                    {
                        if(item.Appointment_DateTime__c >= result.StartTime && item.Appointment_DateTime__c < result.EndTime)
                        {
                            result.AppointmentsCount++;
                        }
                    }
                }
            }
            // the other rows for this list
            //remainingAppts = maxTarget - totalAppts;
            AppointmentDetailInfo remainingResult1 = new AppointmentDetailInfo(String.valueOf(size + 1), dateTime.now(), datetime.now(), totalAppts);
            remainingResult1.FormatHour = 'Total Appts:';
            results.add(remainingResult1);
        }
        return results;
    }
    
    public List<SelectOption> getSchoolList()
    {
        List<SelectOption> options = new List<SelectOption>();
        if(roleName.equals('English Town'))
        { // System admin.
            options.add(new SelectOption('Brazil', 'Brazil'));
            options.add(new SelectOption('Mexico', 'Mexico'));
        }
        else if(roleName.equals('Mexico Management'))
        { // Mexico
            options.add(new SelectOption('Mexico', 'Mexico'));
        }
        else if(roleName.equals('Europe and Americas Management'))
        { // Brazil
            options.add(new SelectOption('Brazil', 'Brazil'));
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
    static void testBR_MXSalesAvailabilityViewController()
    {
        Date currentDate = Date.today();
        String day = String.valueOf(currentDate.day());
        String month = String.valueOf(currentDate.month());
        String year = String.valueOf(currentDate.year());
        String dateStr = day + '/' + month + '/' + year;      
        Datetime currentTime = datetime.now();          
        China_Appt_Assignment_Report__c report1 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, Appointment_DateTime__c = currentTime, Assignment_Org__c = 'Brazil');
        insert report1;
        China_Appt_Assignment_Report__c report2 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, Appointment_DateTime__c = currentTime, Assignment_Org__c = 'Brazil');
        insert report2;
        PageReference page = new PageReference('/apex/BR_MXSalesAvailabilityView?school=Brazil&date=' + dateStr);
        Test.setCurrentPage(page);
        BR_MXSalesAvailabilityViewController controller = new BR_MXSalesAvailabilityViewController();
        controller.getSchoolList();
        List<AppointmentDetailInfo> results = controller.results;
        system.assert(results.size() >= 23);
    }
}