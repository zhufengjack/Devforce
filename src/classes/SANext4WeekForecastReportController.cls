/*
 * class used to generate the report for next 4-week forecast and contains the encoding algorithm for use with Google chartAPI.
 */
public class SANext4WeekForecastReportController
{
    private static List<User> allAdvisorUsers;
    private Date initialDate;
    
    static
    {
        allAdvisorUsers = [select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive=true order by Name];
    }
    
    public SANext4WeekForecastReportController()
    {
        IsChartShow = false;
        initialDate = Date.today();
        generate();
    }
    
    public String DataSet{ get; set; }
    public String ChartURL{ get; set; }
    public Boolean IsChartShow { get; set; }
    public Integer DataWeek1 { get; set; }
    public Integer DataWeek2 { get; set; }
    public Integer DataWeek3 { get; set; }
    public Integer DataWeek4 { get; set; }
    public String DateWeek1 { get; set; }
    public String DateWeek2 { get; set; }
    public String DateWeek3 { get; set; }
    public String DateWeek4 { get; set; }
    public String SAdvisor { get; set; }
    
    public List<SelectOption> SAItems
    {
        get
        {
            List<SelectOption> result = new List<SelectOption>();
            result.add(new SelectOption('', 'All SA'));
            for(User usr : allAdvisorUsers)
            {
                result.add(new SelectOption(usr.Id, usr.Name));
            }
            return result;
        }
    }
    
    public PageReference generate()
    {
        Set<String> userId = new Set<String>();
        if(SAdvisor == null || SAdvisor == '')
        {
            for(User user : allAdvisorUsers)
            {
                userId.add(user.Id);
            }
        }
        else
        {
            userId.add(SAdvisor);
        }
        init(userId);
        createChart();
        IsChartShow = true;
        return null;
    }
    
    private void createChart()
    {    
        String mappedValue = 'chd=t:';
        if(DataSet != null && DataSet != '')
        {
            mappedValue += DataSet;
        }        
        List<Integer> numList = new List<Integer>{DataWeek1, DataWeek2, DataWeek3, DataWeek4};
        Integer max = getProperValue(numList);
        Integer div = 10;
        if( max <= 50)
        {
            div = 5;
        }
        ChartURL = 'https://chart.googleapis.com/chart?chs=400x300&amp;cht=bvs&amp;chxt=x,y&amp;chxl=0:|week1|week2|week3|week4&amp;chxp=0,50,150,250,350&amp;chbh=30,10,10';        
        ChartURL += '&amp;chds=0,' + max + '&amp;chxr=0,0,400|1,0,' + max + ',' + max/div + '&amp;' + mappedValue;        
    }
    
    private void init(Set<String> userId)
    {       
        Date startDate = initialDate;
        Date endDate = startDate.addDays(7);
        DataWeek1 = getTaskNum(userId, startDate, endDate);
        DateWeek1 = getFormatDate(1, startDate, endDate);
        startDate = endDate;
        endDate = endDate.addDays(7);
        DataWeek2 = getTaskNum(userId, startDate, endDate);
        DateWeek2 = getFormatDate(2, startDate, endDate);
        startDate = endDate;
        endDate = endDate.addDays(7);
        DataWeek3 = getTaskNum(userId, startDate, endDate);
        DateWeek3 = getFormatDate(3, startDate, endDate);
        startDate = endDate;
        endDate = endDate.addDays(7);
        DataWeek4 = getTaskNum(userId, startDate, endDate);
        DateWeek4 = getFormatDate(4, startDate, endDate);
        DataSet = DataWeek1 + ',' + DataWeek2 + ',' + DataWeek3 + ',' + DataWeek4;
    }
    
    private String getFormatDate(Integer index, Date startDate, Date endDate)
    {       
        String result = 'Week' + index + ' (' + startDate.month() + '/' + startDate.addDays(1).day() + ' - ' + endDate.month() + '/' + endDate.day() + ')';
        return result;
    }
    
    private Integer getProperValue(List<Integer> numList)
    {
        Integer result = 0;
        for(Integer i=0; i<numList.size(); i++)
        {
            if(numList[i] > result)
            {
                result = numList[i];
            }
        }
        if(result <= 50)
        {
            if(Math.mod(result*12, 50) != 0)
            {
                result = (Math.round(result*1.2/5)+1)*5;
            }
            else
            {
                result = Math.round(result*1.2/5)*5;
            }
        }
        else
        {
            result = Math.round(result*1.2/10)*10;  
        }
        return result;
    }
    
    private Integer getTaskNum(Set<String> userId, Date startDate, Date endDate)
    {
        AggregateResult[] groupedResult = [select count(Id) c from Task where OwnerId in :userId and ActivityDate <= :endDate and  ActivityDate > :startDate and RecordType.Name = 'Study Advise' and Status = 'Open'];
        if(groupedResult.size() < 1)
        {
            return 0;
        }
        else
        {
            return (Integer)groupedResult[0].get('c');
        }
    }
    
    @isTest
    static void testSANext4WeekForecastReportController()
    {
        //create data.
        Set<User> userList = new Set<User>();
        List<Task> tasks = new List<Task>();
        Date initialTestDate = Date.today().addYears(10);
        String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType = 'Task' limit 1].Id;
        for( User usr :[select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive = true order by Name limit 5])
        {
            userList.add(usr);
            tasks.add(new Task(OwnerId = usr.Id, RecordTypeId = recTypeId, ActivityDate = initialTestDate.addDays(1), Status = 'Open', Subject = 'Test'));
            tasks.add(new Task(OwnerId = usr.Id, RecordTypeId = recTypeId, ActivityDate = initialTestDate.addDays(8), Status = 'Open', Subject = 'Test'));
            tasks.add(new Task(OwnerId = usr.Id, RecordTypeId = recTypeId, ActivityDate = initialTestDate.addDays(15), Status = 'Open', Subject = 'Test'));
            tasks.add(new Task(OwnerId = usr.Id, RecordTypeId = recTypeId, ActivityDate = initialTestDate.addDays(22), Status = 'Open', Subject = 'Test'));
        }
        insert tasks;
        //test logic.
        SANext4WeekForecastReportController controller = new SANext4WeekForecastReportController();
        controller.initialDate = Date.today().addYears(10);
        controller.generate();
        System.assert(controller.SAItems != null);
    }
}