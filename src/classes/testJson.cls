public class testJson {
    public static String json = '[{"currentUserId":"00590000000YoqgAAC", "objectId":"00Q900000054zeZEAQ","isConnected":"1","unConnectedReason":"ANSWERED","callStartTime":"2012-01-10T02:10:23Z","callEndTime":"2012-01-13T03:07:42Z","duration":"310","uniqueId":"1326161422.434371"}, {"objectId":"00Q90000005SVoaEAG","currentUserId":"005400000015v9zAAA","isConnected":"1","unConnectedReason":"ANSWERED","callStartTime":"2012-01-10T02:11:46Z","callEndTime":"2012-01-13T03:07:42Z","duration":"240","uniqueId":"1326161506.434451"}]';
    public static String json1;
    public static void testJson()
    {
        List<EventParameters> deEvent = (List<EventParameters>)System.JSON.deserialize(json, List<EventParameters>.class);
        List<EventParameters> d = deEvent; 
    }
    
    public class EventParameters
    {
        public String objectId;
        public String currentUserId;
        public Integer isConnected;
        public String unConnectedReason;
        public DateTime callStartTime;
        public DateTime callEndTime;
        public String uniqueId;
        public Integer duration;
        
    }
}