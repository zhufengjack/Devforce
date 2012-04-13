/**
 *controller for page: SmartHourlyCapping
*/
public class SmartHourlyCappingController 
{
    public SmartHourlyCappingController()
    {
        TempReport = new China_Appt_Assignment_Report__c();
        Results = GetAppointmentsDetails();
    }
    
    public List<AppointmentDetailInfo> Results { get; set; }
    public China_Appt_Assignment_Report__c TempReport { get; set; }
        
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
            List<String> dateArr = currentDate.trim().split('/');
            if(dateArr.size() == 3)
            {
                String year = dateArr[2].trim();
                String month = dateArr[1].trim();
                String day = dateArr[0].trim();
                String formateDate = day + '/' + month + '/' + year;
                Date scheduleDate = null;
                try
                {
                    scheduleDate = date.parse(formateDate);
                }
                Catch(Exception ex)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid date:' + formateDate));
                } 
                if(scheduleDate != null)
                {
                    map<Integer, Integer> hourlyCountMap = RemainingApptsHelper.getHourlyCountMap(school, scheduleDate);
                    map<Integer, Integer> hourlyTotalMap = RemainingApptsHelper.getHourlyTotalMap(school, scheduleDate); 
                    Integer totalAppt = 0;
                    Integer usedAppt = 0;
                    Integer remainAppt = 0;
                    for(Integer i = 0; i < 12; i++)
                    {
                        AppointmentDetailInfo result = new AppointmentDetailInfo(String.valueof(i+1), (i + 9), (i + 10), 0, 0);
                        if(hourlyCountMap.get((i + 9)) != null)
                        {
                            result.AppointmentsCount = hourlyCountMap.get((i + 9));
                        }
                        if(hourlyTotalMap.get((i + 9)) != null)
                        {
                            result.SubTotalCount = hourlyTotalMap.get((i + 9));
                        }
                        result.RemianingCount = result.SubTotalCount - result.AppointmentsCount;
                        results.add(result);
                        usedAppt += result.AppointmentsCount;
                        totalAppt += result.SubTotalCount;
                        remainAppt += result.RemianingCount;
                    }
                    AppointmentDetailInfo usedApptRow = new AppointmentDetailInfo('13', 0, 0, 0, usedAppt);
                    usedApptRow.FormatTime = 'Total Used Appts:';
                    results.add(usedApptRow);
                    AppointmentDetailInfo totalApptRow = new AppointmentDetailInfo('14', 0, 0, 0, totalAppt);
                    totalApptRow.FormatTime = 'Total Availabilities:';
                    results.add(totalApptRow);
                    AppointmentDetailInfo remianingApptRow = new AppointmentDetailInfo('15', 0, 0, 0, remainAppt);
                    remianingApptRow.FormatTime = 'Total Remaining:';
                    results.add(remianingApptRow);
                } 
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid date'));
                }  
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Invalid date'));
            }
        }
        return results;
    }
    
    // a custom class for appointment detail
    public class AppointmentDetailInfo
    {
        public AppointmentDetailInfo(String snumber, Integer startHour, Integer endHour, Integer apptCount, Integer subTotal)
        {
            this.SNumber = snumber;
            this.AppointmentsCount = apptCount;
            this.StartHour = startHour;
            this.EndHour = endHour;
            this.SubTotalCount = subTotal;
            this.RemianingCount = subTotal - apptCount;
            this.FormatTime = String.valueof(startHour) + ':00 - ' + String.valueof(endHour) + ':00';
        }
        public String SNumber { get; set; }
        public String FormatTime { get; set; }
        public Integer AppointmentsCount { get; set; }
        public Integer StartHour { get; set; }
        public Integer EndHour { get; set; }
        public Integer SubTotalCount { get; set; }
        public Integer RemianingCount { get; set; }
    }
    
	@isTest
    static void testController()
    {       
        Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
    	Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today(), Check_confirmation__c = false);
    	insert testOpportunity1;
    	Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
    	insert testTarget1;
    	China_Appointment_Max_target_detail__c detail = new China_Appointment_Max_target_detail__c(School__c = 'SH PSQ', Time__c = datetime.now(), Max_target__c = 10);
    	insert detail;
    	PageReference testPage = new PageReference('/SmartHourlyCapping?school=SH PSQ&date=' + datetime.now().format('dd/MM/yyyy'));
    	test.setCurrentPage(testPage);
    	SmartHourlyCappingController controller = new SmartHourlyCappingController();
    	system.assert(controller.Results.size() >= 0);
    }
}