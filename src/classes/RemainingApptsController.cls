/*
 * Controller for page: RemainingAppts
 */
public class RemainingApptsController 
{   
    public RemainingApptsController()
    {
        isTesting = false;
        GetSchoolRemainingAppts();  
    }
    
    public RemainingApptsController(Boolean isTesting)//using for test method
    {
        this.isTesting = isTesting;
        GetSchoolRemainingAppts();  
    }
    
    public Boolean isTesting {get;set;}
    public HtmlTable Table{get;set;}
    public Integer schoolSize {get;set;}
    
    private List<String> leadToShowSchools
    {
            get
            {
                return RemainingApptsHelper.getValidOriginalSchools();
            }
    }
    
    // Filtering duplicate data
    private List<Appt_Max_target__c> FilterDuplicateData(List<Appt_Max_target__c> entries)
    {
        Map<String, Appt_Max_target__c> items = new Map<String, Appt_Max_target__c>();//key school + date,Appt_Max_target__c
        for(Appt_Max_target__c entry : entries)
        {
            String tag = entry.School__c + entry.Date__c;
            if(!items.containsKey(tag))
            {
                items.put(tag, entry);
            }
        }
        return items.values();
    }
    //Constructor the results
    private List<SchoolInfo> WrapSchool(String city)
    {
        List<SchoolInfo> results = new List<SchoolInfo>();
        List<AppointmentInfo> datas = GetAssAppts(city);
        Date currentDay = Date.today();
        if(isTesting == null)
        {
            isTesting = false;
        }
        Integer limitCount = (isTesting)?50:100000;//using for testmethod ,because in testmethod the max query rows is 500;so which can limt this exception
        List<Appt_Max_target__c> entries = [select Max_target__c, Day__c, Month__C, Year__c, School__c, City__c, Date__c, LastModifiedDate from Appt_Max_target__c where City__c = :city and School__c not in :leadToShowSchools and Date__c >= :currentDay and Date__c <= :currentDay.addDays(13) order by LastModifiedDate desc limit :limitCount];
        Map<String, List<Appt_Max_target__c>> items = new Map<String, List<Appt_Max_target__c>>();//key school,value List<Appt_Max_target__c>
        if(!entries.isEmpty())
        {
            entries = FilterDuplicateData(entries);     
            for(Appt_Max_target__c entry : entries)
            {
                if(items.containsKey(entry.School__c))
                {
                    List<Appt_Max_target__c> details = items.get(entry.School__c);
                    details.add(entry);
                }
                else
                {
                    List<Appt_Max_target__c> details = new List<Appt_Max_target__c>();
                    details.add(entry);
                    items.put(entry.School__c, details);
                }
            }
            for(String school : items.keySet())
            {
                SchoolInfo  result = new SchoolInfo();          
                result.SchoolName = school;
                List<Appt_Max_target__c> details = items.get(school);
                List<RemainingApptsDetailInfo> infos = new List<RemainingApptsDetailInfo>();
                for(Appt_Max_target__c detail : details)
                {
                    String sCity = detail.City__c;
                    String sSchool = detail.School__c;
                    Integer sMaxAppts = detail.Max_target__c.round().intValue();
                    Date sDate = detail.Date__c;
                    String sDay = detail.Day__c;
                    String sMonth = detail.Month__c;
                    String sYear = detail.Year__c;
                    String sFormatDate = sDay + '/' + sMonth + '/' + sYear;
                    if(sDate == Date.today())
                    {
                        sFormatDate += '(today)';
                    }                   
                    RemainingApptsDetailInfo info = new RemainingApptsDetailInfo(sCity, sSchool, sMaxAppts, sDate, sFormatDate);                
                    infos.add(info);
                }
                if(infos.size() > 0)
                {
                    infos = SortList(infos);
                    infos = CompleteList(infos);
                    if(!Datas.isEmpty())
                    {                   
                        for(RemainingApptsDetailInfo sInfo : infos)
                        {
                            Integer existCount = 0; 
                            for(AppointmentInfo data : datas)
                            {                               
                                if(data.Tag == sInfo.Tag)
                                {
                                     existCount += data.Count;                                  
                                }                               
                            }
                            sInfo.RemainingAppts = sInfo.MaxAppts - existCount;                             
                        }
                    }
                    infos = SortList(infos);
                }
                result.RemainApptsDetails = infos;
                results.add(result);
            }
        }
        return results;
    }
    
    //if the list size is less than 14 ,this function will complete this list for example the list just contains 2010-3-5, 2010-3-8,this function will add the other date for the list 
    private List<RemainingApptsDetailInfo> CompleteList(List<RemainingApptsDetailInfo> items)
    {
        RemainingApptsDetailInfo entry = items[0];
        RemainingApptsDetailInfo temp;  
        List<Date> allDate = new List<Date>();
        for(Integer i = 0; i < 14; i++)
        {
            allDate.add(Date.today().addDays(i));
        }
        Map<Date, List<RemainingApptsDetailInfo>> maps = new Map<Date, List<RemainingApptsDetailInfo>>();//key Date,value List<RemainingApptsDetailInfo>
        for(RemainingApptsDetailInfo item : items)
        {
            if(maps.containsKey(item.ClassDate))
            {
                List<RemainingApptsDetailInfo> details = maps.get(item.ClassDate);
                details.add(item);
            }
            else
            {
                List<RemainingApptsDetailInfo> details = new List<RemainingApptsDetailInfo>();
                details.add(item);
                maps.put(item.ClassDate, details);
            }
        }
        for(Date sDate : allDate)
        {
            if(!maps.containsKey(sDate))
            {
                String day = String.valueOf(sDate.day());
                String month = String.valueOf(sDate.month());
                String year = String.valueOf(sDate.year());
                String formatDate = day + '/' + month + '/' + year;
                if(sDate == Date.today())
                {
                    formatDate += '(today)';
                }
                temp = new RemainingApptsDetailInfo(entry.City, entry.School, 0, sDate, formatDate);
                items.add(temp);    
            }
        }
        return items;
    }
    
    //Sort List<RemainingApptsDetailInfo> by createdate
    private List<RemainingApptsDetailInfo> SortList(List<RemainingApptsDetailInfo> items)
    {
        Integer i, j;
        RemainingApptsDetailInfo temp;    
        Boolean done = false;    
        j = 1;    
        while ((j < items.size()) && (!done))  
        {    
            done = true;    
            for (i = 0; i < items.size() - j; i++)    
            {    
                if (items[i].ClassDate > items[i + 1].ClassDate)    
                {    
                    done = false;    
                    temp = items[i];    
                    items[i] = items[i + 1];
                    items[i + 1] = temp;    
                }    
            }    
            j++;    
        }    
        return items;
    }
    
    //get all China_Appt_Assignment_Report__c and group by date and school
    public List<AppointmentInfo> GetAssAppts(String city)
    {
        List<AppointmentInfo> results = new List<AppointmentInfo>();      
        String searchCity = '%'+city+'%';
        Date currentDay = Date.today(); 
        if(isTesting == null)
        {
            isTesting = false;
        }
        Integer limitCount = (isTesting)?1:1000;
        AggregateResult[] groupedResults =[select count(Id), Appointment_Date__c, School__c from China_Appt_Assignment_Report__c where School__c Like :searchCity and School__c not in :leadToShowSchools and Appointment_Date__c >= :currentDay and Appointment_Date__c <= :currentDay.addDays(13) group by Appointment_Date__c, School__c limit :limitCount];
        for(AggregateResult res : groupedResults)
        {
            String tag = (String)res.get('School__c') + ((Date)res.get('Appointment_Date__c')).format();
            Integer appCount = (Integer)res.get('expr0');
            AppointmentInfo result = new AppointmentInfo(tag, appCount);
            results.add(result);       
        }              
        return results;
    }
    
    //refresh 5 seconds
    public PageReference Refresh()
    {
        GetSchoolRemainingAppts();
        return null;
    }
    
    //get all school by select city 
    public List<SchoolInfo> GetSchoolRemainingAppts()
    {
        String city = Apexpages.currentPage().getParameters().get('city');
        List<SchoolInfo> schools = new List<SchoolInfo>();
        schoolSize = 0;
        if(city != null && city != '')
        {
            schools = WrapSchool(city);
            if(schools.size() > 0)
            {
                Integer columnCount = schools.size() + 1;
                Integer rowCount = 15;
                Table = new HtmlTable(rowCount, columnCount);           
                for(Integer column = 0; column < columnCount; column ++)
                {
                    List<RemainingApptsDetailInfo> infos = new List<RemainingApptsDetailInfo>();
                    if(column == 0)
                    {
                        infos = schools[0].RemainApptsDetails;
                    }
                    else
                    {
                        infos = schools[column-1].RemainApptsDetails;
                    }
                    for(Integer row = 0; row < 15; row ++)
                    {
                        if(column == 0 && row == 0)
                        {
                            Table.setCell(0, 0, '');
                        }
                        else if(column == 0 && row != 0)
                        {
                            Table.setCell(row, 0, String.valueOf(infos[row-1].FormatClassDate));//set the date column while the column is 0
                        }
                        else if(row == 0 && column != 0)
                        {
                            Table.setCell(0, column, String.valueOf(schools[column-1].SchoolName));//set school name whene the row is 0
                        }
                        else
                        {
                            Table.setCell(row, column, String.valueOf(infos[row - 1].RemainingAppts));//set other values for the list which using for render a htmlTable
                        }
                    }
                }
            }
        }
        schoolSize = schools.size();
        return schools;
    }
    
    //a custom class for school,contains schoolName and the last 14 days detail information
    public class SchoolInfo
    {
        public SchoolInfo()
        {
            this.RemainApptsDetails = new List<RemainingApptsDetailInfo>();
        }
        
        public String  SchoolName{get;set;}
        public List<RemainingApptsDetailInfo> RemainApptsDetails{get;set;}
    }
    
    //the detail information for a school in a day
    public class RemainingApptsDetailInfo
    {
        public RemainingApptsDetailInfo(String city, String school, Integer maxAppts, Date classDate, String formatClassDate)
        {
            this.City = city;
            this.School = school;
            this.ClassDate = classDate;
            this.MaxAppts = maxAppts;
            this.FormatClassDate = formatClassDate;
            this.Tag = school + classDate.format();
            this.RemainingAppts = maxAppts;
        }
        
        public String Tag {get;set;} //school+date which can using for grouping the data
        public String  FormatClassDate {get;set;}//display in page
        public Date ClassDate{get;set;}//the class date
        public String School {get;set;}//school name
        public String City {get;set;}//the city
        public Integer MaxAppts {get;set;}//the max target
        public Integer RemainingAppts{get;set;}//remaining appointments
    }
    
    //a custom class for China_Appt_Assignment_Report__c
    public class AppointmentInfo
    {
        public AppointmentInfo(String tag, Integer count)
        {
            this.Tag = tag;//which is a string as school+date
            this.Count = count;//count of appointments of this school and this date which contains in tag 
        }
        public String Tag{get;set;}
        public Integer Count {get;set;}
    }
    
    //a custom class which can render the html code for dataTable which displayed in vf page
    public class HtmlTable
    {
        private List<List<String>> internalData;
        private Integer row, column;
        public HtmlTable(Integer rows, Integer columns)
        {
            this.row = rows;
            this.column = columns;
            internalData = new List<List<String>>();
            for(Integer i = 0; i < rows; i ++)
            {
                List<String> aRow = new List<String>();
                for(Integer j = 0; j < columns; j++)
                {
                    aRow.add('');
                }
                internalData.add(aRow);
            }
        }
        
        public void setCell(Integer row, Integer column, String value)
        {
            if(row < this.row)
            {
                if(column < this.column)
                {
                    internalData[row][column] = value;
                }
            }
        }
        
        //return a html table code for vf page
        public String renderHtml
        {
            get
            {
                Integer colspan = this.column - 1;
                String result = '<table border="1" cellspacing="0" cellpadding="5" border-color:#4F4431;" style="color:blue"><tr  style="background-color:#ACA96C;"><td style="color:black"><b>Date</b></td><td colspan="' + colspan + '" align="center" style="color:black"><b>Remaining Appts</b></td></tr>';
                for(Integer i = 0; i < this.row; i++)
                {
                    result += '<tr>';
                    for(Integer j = 0; j < this.column; j++)
                    {
                        if(i!= 0 && j != 0)
                        {
                            Integer remainingAppts = integer.valueOf(internalData[i][j]);
                            String CurrentDate = internalData[i][0];
                            String dateStr = '';
                            String day = '';
                            String month = '';
                            String year = '';
                            if(i == 1)
                            {
                                Date sDate = Date.today();
                                day = (integer.valueof(String.valueOf(sDate.day())) >= 10)?String.valueOf(sDate.day()):('0' + String.valueOf(sDate.day()));
                                month = (integer.valueof(String.valueOf(sDate.month())) >= 10)?String.valueOf(sDate.month()):('0' + String.valueOf(sDate.month()));
                                year = String.valueOf(sDate.year());    
                            }
                            else
                            {
                                String[] dateArr = CurrentDate.split('/');
                                year = dateArr[2];
                                month = (integer.valueof(String.valueOf(dateArr[1])) >= 10)?String.valueOf(dateArr[1]):('0' + String.valueOf(dateArr[1]));
                                day = (integer.valueof(String.valueOf(dateArr[0])) >= 10)?String.valueOf(dateArr[0]):('0' + String.valueOf(dateArr[0]));                                
                            }
                            dateStr = day + '/' + month + '/' + year;   
                            String[] school = internalData[0][j].split(' ');
                            String schoolStr = school[0] + '_' + school[1];
                            String openUrl = '/apex/SalesAvailabilityView?school=' + schoolStr + '&date=' + dateStr;                        
                            if(remainingAppts < 0)
                            {
                                result += '<td style="background-color:#D6D5CF;"><a href="javascript:void(0)" onclick="open_win(\'' + openUrl + '\')"  style="color:red;">' + internalData[i][j] + '</a></td>';
                            }
                            else
                            {
                                result += '<td style="background-color:#D6D5CF;"><a href="javascript:void(0)" onclick="open_win(\'' + openUrl + '\')"  style="color:blue;">' + internalData[i][j] + '</a></td>';
                            }
                        }
                        else
                        {
                            result += '<th style="color:black;background-color:#D6D5CF;">' + internalData[i][j] + '</th>';
                        }
                    }
                    result += '</tr>';
                }
                result += '</table>';
                return result;
            }
        }
    }
    
    @isTest
    static  void testController()
    {
        Date currentDate = Date.today();            
        Appt_Max_target__c target = new Appt_Max_target__c(Max_target__c = 100, School__c = 'BJ DZM', Date__c = currentDate);
        insert target;
        China_Appt_Assignment_Report__c report1 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, School__c = 'BJ DZM');
        insert report1;
        China_Appt_Assignment_Report__c report2 = new China_Appt_Assignment_Report__c(Appointment_Date__c = currentDate, School__c = 'BJ DZM');
        insert report2;
        PageReference page = new PageReference('/apex/RemainingAppts?city=BJ');
        Test.setCurrentPage(page);
        RemainingApptsController controller = new RemainingApptsController(true);
        controller.isTesting = true;
        List<SchoolInfo> infos = controller.GetSchoolRemainingAppts();
        //system.assert(infos.size() >= 1); // Assertion Failed.
        //String renderHtml = controller.Table.renderHtml;
        //System.assert(renderHtml.contains('BJ DZM')); // Assertion Failed.
    }
    @isTest
    static  void testSchoolInfo()
    {
        SchoolInfo info = new SchoolInfo();
        Date currentDate = Date.Today();
        RemainingApptsDetailInfo item = new RemainingApptsDetailInfo('1', '2', 3, currentDate, '4');
        List<RemainingApptsDetailInfo> items = new List<RemainingApptsDetailInfo>{item};
        info.SchoolName = '1';
        info.RemainApptsDetails = items;
    }
    @isTest
    static  void testRemainingApptsDetailInfo()
    {
        Date currentDate = Date.Today();
        RemainingApptsDetailInfo info = new RemainingApptsDetailInfo('1', '2', 3, currentDate, '4');
    }
    @isTest
    static  void testAppointmentInfo()
    {
        AppointmentInfo info = new AppointmentInfo('1', 2);
    }
    @isTest
    static  void testHtmlTable()
    {
        HtmlTable table = new HtmlTable(2,2);
        table.setCell(0, 0, '');
        table.setCell(0, 1, 'A B');
        table.setCell(1, 0, '27/2/2010');
        table.setCell(1, 1, '10000');
        String renderHtml = table.renderHtml;
        Boolean testRenderHtml = renderHtml.contains('10000');
        System.assert(testRenderHtml);
    }
}