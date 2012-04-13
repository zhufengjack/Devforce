/*
 * this controller used to show report "SAOverdueTaskReport".
 */
public class SAOverdueTaskReportController
{
    private static Date currentDay = Date.today();
    private static List<User> allSAdvisor;
    private static Map<Date,String> overdueDate2Days = new Map<Date, String>{
                                                currentDay.addDays(-1) => '1', 
                                                currentDay.addDays(-2) => '2',
                                                currentDay.addDays(-3) => '3',
                                                currentDay.addDays(-4) => '4',
                                                currentDay.addDays(-5) => '5',
                                                currentDay.addDays(-6) => '6',
                                                currentDay.addDays(-7) => '7',
                                                currentDay.addDays(-8) => '8',
                                                currentDay.addDays(-9) => '9',
                                                currentDay.addDays(-10) => '10 and 10+'};
    private static List<Date> dates;
    private static Map<Boolean, Integer> isTestMethod2SelectLimit = new Map<Boolean, Integer>{ true => 20, false => 50000};  // keyWord: Test.isRunningTest()
    private Map<String, Integer> saId2TaskNum; // key: saId, value: task number.
    private Map<Date, Integer> overdueDate2TaskNum;
    
    static 
    {
         allSAdvisor = [select Id, Name from User where (Profile.Name='EnglishTown Study Advisor' or Profile.Name='EnglishTown Study Advisor Manager') and IsActive=true order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())];
         dates = new List<Date>();
         for(Integer i = 0; i < 10; i++)
         {
            dates.add(currentDay.addDays(-(i+1)));
         }
    }
    
    public SAOverdueTaskReportController()
    {
        IsTaskBySA = true;
        saId2TaskNum = new Map<String, Integer>();
        overdueDate2TaskNum = new Map<Date, Integer>();
        OverdueSATasks = new List<TaskInfo>();
        OverdueDaysTasks = new List<TaskInfo>();
        generate();
    }
    
    private void initSAPart()
    {
        for(AggregateResult ar : [select count(Id) c, OwnerId id from Task where ActivityDate < :Date.today() and RecordType.Name='Study Advise' and IsClosed=false and OwnerId in :allSAdvisor group by OwnerId limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
        {
            saId2TaskNum.put((String)ar.get('id'), (Integer)ar.get('c'));
        }
        for(User usr : allSAdvisor)
        {
            OverdueSATasks.add(new TaskInfo(usr.Name, saId2TaskNum.get(usr.Id), true));
        }
    }
    
    private void initDaysPart()
    {
        for(AggregateResult ar : [select count(Id) c, ActivityDate d from Task where ActivityDate < :Date.today() and RecordType.Name='Study Advise' and IsClosed=false and OwnerId in :allSAdvisor group by ActivityDate limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
        {
            if((Date)ar.get('d') <= currentDay.addDays(-10))
            {
                if(!overdueDate2TaskNum.keySet().contains(currentDay.addDays(-10)))
                {
                    overdueDate2TaskNum.put(currentDay.addDays(-10), (Integer)ar.get('c'));
                }
                else
                {
                    overdueDate2TaskNum.put(currentDay.addDays(-10), overdueDate2TaskNum.get(currentDay.addDays(-10)) + (Integer)ar.get('c'));
                }
            }
            else
            {
                overdueDate2TaskNum.put((Date)ar.get('d'), (Integer)ar.get('c'));
            }
        }
        for(Date d : dates)
        {
            OverdueDaysTasks.add(new TaskInfo(overdueDate2Days.get(d), overdueDate2TaskNum.get(d), false));
        }
    }
    
    public Boolean IsTaskBySA { get; set; }
    public List<TaskInfo> OverdueSATasks { get; set; }
    public List<TaskInfo> OverdueDaysTasks { get; set; }
    
    public Integer SATaskCount 
    {
        get
        {
            Integer result = 0;
            for(TaskInfo ti : OverdueSATasks)
            {
                if(ti.TaskNum != null )
                {
                    result += ti.TaskNum;
                }
            }
            return result;
        }
    }
    
    public Integer OverdueDaysTaskCount
    {
        get
        {
            Integer result = 0;
            for(TaskInfo ti : OverdueDaysTasks)
            {
                if(ti.TaskNum != null)
                {
                    result += ti.TaskNum;
                }
            }
            return result;
        }
    }
    
    public PageReference generate()
    {
        saId2TaskNum.clear();
    	OverdueSATasks.clear();
    	overdueDate2TaskNum.clear();
    	OverdueDaysTasks.clear();
        if(IsTaskBySA)
        {
            initSAPart();
        }
        else
        {
            initDaysPart();
        }
        return null;
    }
    
    public Class TaskInfo
    {        
        public TaskInfo(String saNameOrOverdueDays, Integer taskNum, Boolean isSAType)
        {
            if(isSAType)
            {       
                this.SAName = saNameOrOverdueDays;
                this.TaskNum = (taskNum == null)? 0: taskNum;
            }
            else
            {
                this.OverdueDays = saNameOrOverdueDays;
                this.TaskNum = (taskNum == null)? 0: taskNum;
            }
        }  
        
        public String SAName { get; set; }
        public String OverdueDays { get; set; } 
        public Integer TaskNum { get; set; }
    }

    
    @isTest
    static void testSAOverdueTaskReportController()
    {
        // create data.
        List<User> testAllSA = [select Id, Name from User where (Profile.Name='EnglishTown Study Advisor' or Profile.Name='EnglishTown Study Advisor Manager') and IsActive=true order by Name limit 100];
        String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType='Task' limit 1].Id;
        List<Task> testTasks = new List<Task>();
        for(Integer i = 0; i < testAllSA.size(); i++)
        {
            testTasks.add(new Task(OwnerId=testAllSA[i].Id, RecordTypeId=recTypeId, Status='Open', ActivityDate=Date.today().addDays(-(i+1))));
        }
        insert testTasks;
        // test logic.
        SAOverdueTaskReportController controller = new SAOverdueTaskReportController();
        controller.IsTaskBySA = true;
        controller.generate();
        System.assert(controller.OverdueSATasks != null);
        System.assert(controller.SATaskCount != null);
        controller.IsTaskBySA = false;
        controller.generate();
        System.assert(controller.OverdueDaysTasks != null);
        System.assert(controller.OverdueDaysTaskCount != null);
    }
}