/*
 * Controller of the page SATaskThisMonthReport
 */
public with sharing class SATaskThisMonthReportController 
{
    public List<RowInfo> Rows
    {
        get
        {
            List<RowInfo> result = new List<RowInfo>();
            result.add(new RowInfo('Overdue Tasks', OverdueTaskCount));
            result.add(new RowInfo('Closed Tasks', ClosedTaskCount));
            result.add(new RowInfo('On-hold Tasks', OnHoldTaskCount));
            return result;
        }
    }
    
    private Integer OverdueTaskCount
    {
        get
        {
            return [select count() from Task where OwnerId=:UserInfo.getUserId() and ActivityDate=THIS_MONTH and ActivityDate<:Date.today() and IsClosed=false and RecordType.Name='Study Advise'];
        }
    }
    
    private Integer ClosedTaskCount
    {
        get
        {
            return [select count() from Task where OwnerId=:UserInfo.getUserId() and ActivityDate=THIS_MONTH and IsClosed=true and RecordType.Name='Study Advise'];
        }
    }
    
    private Integer OnHoldTaskCount
    {
        get
        {
            return [select count() from Task where OwnerId=:UserInfo.getUserId() and ActivityDate=THIS_MONTH and Status='On-Hold' and RecordType.Name='Study Advise'];
        }
    }

    public class RowInfo
    {
        public RowInfo(String name, Integer taskCount)
        {
            this.Name = name;
            this.TaskCount = taskCount;
        }
        
        public String Name { get; set; }
        public Integer TaskCount { get; set; }
    }
    
    @isTest
    static void testSATaskThisMonthReportController()
    {
        SATaskThisMonthReportController controller = new SATaskThisMonthReportController();
        List<RowInfo> rows = controller.Rows;
    }
    
}