public class MassDelCR {
    
    public static void del()
    {
        for(Integer i = 0; i< 2; i ++)
        {
           List<CourseReschedule__c> crs = [select Id from CourseReschedule__c limit 3500];
           delete crs;
        }
    }
}