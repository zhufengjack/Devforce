/*
 * Controller of component HistoryList
 */
public with sharing class HistoryListController
{
    private String sObjectName;
    private static Map<String, Schema.DescribeFieldResult> fieldDescribeMap;
    private static String UserTimeZone = [select TimeZoneSidKey from User where Id = :UserInfo.getUserId()].TimeZoneSidKey;
     
    public HistoryListController()
    {    
    }
    
    public String ObjectName
    {
        get { return sObjectName; }
        set 
        { 
            sObjectName = value; 
            describeObject(); 
        }
    }
    
    public Id ObjectId { get; set; }
    
    private void describeObject()
    {
        fieldDescribeMap = new Map<String, Schema.DescribeFieldResult>();
        Map<String, Schema.sObjectType> gd = Schema.getGlobalDescribe();
        if(gd.containsKey(ObjectName))
        {
            Map<String, Schema.SObjectField> fieldMap = gd.get(ObjectName).getDescribe().fields.getMap();
            for(String fieldName : fieldMap.keySet())
            {
                Schema.sObjectField field = fieldMap.get(fieldName);
                Schema.DescribeFieldResult fieldDescribe = field.getDescribe();
                fieldDescribeMap.put(fieldName, fieldDescribe); 
            }
        }
    }
    
    public List<HistoryInfo> Histories
    {
        get
        {
            List<HistoryInfo> result = new List<HistoryInfo>();
            List<sObject> obj = Database.query('select Id, (select CreatedById, CreatedBy.Name, CreatedDate, Field, OldValue, NewValue from Histories order by CreatedDate desc) from ' + ObjectName +' where Id=:ObjectId limit 1');
            if(obj.size() == 1)
            {
                List<sObject> historyEntries = obj[0].getSObjects('Histories');
                DateTime lastDate = null;
                if(historyEntries != null)
                {
                    for(sObject historyObj : historyEntries)
                    {
                        DateTime currentDate = (DateTime)historyObj.get('CreatedDate');
                        HistoryInfo history = new HistoryInfo(historyObj);
                        if(history.IsFound) 
                        {
                            history.OmitUser = (currentDate == lastDate);
                            result.add(history);
                            lastDate = currentDate;
                        }
                    }
                }
            }
            return result;
        }
    }
    
    public class HistoryInfo
    {
        public HistoryInfo(sObject obj)
        {
            this.Obj = obj;
            CreatedDate = (DateTime)obj.get('CreatedDate');
            CreatedDateNY = (DateTime)obj.get('CreatedDate');
            CreatedDateNY = CreatedDateNY.addHours(-5);
            
            //String UserTimeZone = [select TimeZoneSidKey from User where Id = :UserInfo.getUserId()].TimeZoneSidKey;
	        Integer OffsetHour;
	        Integer OffsetMinute;
	        String Offset = GetOffsetByTimezone(UserTimeZone);
	        
	        if (Offset != '' && Offset != null)
	        {
	        	OffsetHour = Integer.valueof(Decimal.valueof(Offset.substring(0,3)));
	        	OffsetMinute = Integer.valueof(Decimal.valueof(Offset.substring(3,6)));
	        }
	        
	        system.debug('OffsetHour ' + OffsetHour);
	        system.debug('OffsetMinute ' + OffsetMinute);
	        
	        Datetime valueDt = Datetime.valueof(CreatedDate);
	        CreatedDate = CreatedDate.addHours(OffsetHour);
	        CreatedDate = CreatedDate.addMinutes(OffsetMinute);

            Id userId = (Id)obj.get('CreatedById');
            String userName = (String)obj.getSObject('CreatedBy').get('Name');
            CreatedBy = new User(Id=userId, LastName=userName);
            string fieldName = (String)obj.get('Field');
            if(fieldName == 'Owner')
            {
                fieldName = 'ownerid';
            }
            if(fieldName != null && fieldDescribeMap != null)
            {
                if(fieldDescribeMap.containsKey(fieldName.toLowerCase()))
                {
                    Field = fieldDescribeMap.get(fieldName.toLowerCase()).getLabel();
                    OldValue = formatString(obj.get('OldValue'), fieldDescribeMap.get(fieldName.toLowerCase()).getType());
                    NewValue = formatString(obj.get('NewValue'), fieldDescribeMap.get(fieldName.toLowerCase()).getType());
                    if ((OldValue == '00G00500G005')&&(NewValue == '00G00500G005'))
                    {
                        IsFound = false;
                    }
                    else
                    {
                        IsFound = true;
                    }
                }
                else
                {
                    IsFound = false;
                }
            }
            else
            {
                IsFound = false;
            }
        }
        
        public sObject Obj { get; set; }
        public DateTime CreatedDate { get; set; }
        public DateTime CreatedDateNY { get; set; }
        public User CreatedBy { get; set; }
        public String Field { get; set; }
        public String OldValue { get; set; }
        public String NewValue { get; set; }
        public Boolean OmitUser { get; set; }
        public Boolean IsFound { get; set; }

        
        private String formatString(Object value, Schema.DisplayType fieldType)
        {
            try
            {
                if(value == null)
                {
                    return null;
                }
                if(fieldType == Schema.DisplayType.Date)
                {
                    return ((Date)value).format();
                }
                else if(fieldType == Schema.DisplayType.DateTime)
                {
                    Datetime valueDt = Datetime.valueof(value);
                    return valueDt.format('MM/dd/yyyy hh:mm:ss');
                }
                else if(fieldType == Schema.DisplayType.Reference)
                {
                    String valueString = String.valueof(value);
                    if ((ValueString.startsWith('005'))||(valueString.startsWith('00G')))
                    {                       
                        valueString = '00G00500G005';
                    }
                    
                    return valueString;
                } 
            }
            catch(Exception ex)
            {
            }
            return String.valueOf(value);
        }
    }
    
    Private static String GetOffsetByTimezone (String InTimezone)
    {
    	String Offset;
    	if 		(InTimezone == 'Pacific/Kiritimati') {Offset = '+14+00';}
    	else if (InTimezone == 'Pacific/Enderbury') {Offset = '+13+00';}
    	else if (InTimezone == 'Pacific/Tongatapu') {Offset = '+13+00';}
    	else if (InTimezone == 'Pacific/Chatham') {Offset = '+12+45';}
    	else if (InTimezone == 'Asia/Kamchatka') {Offset = '+12+00';}
    	else if (InTimezone == 'Pacific/Auckland') {Offset = '+12+00';}
    	else if (InTimezone == 'Pacific/Fiji') {Offset = '+12+00';}
    	else if (InTimezone == 'Pacific/Norfolk') {Offset = '+12+00';}
    	else if (InTimezone == 'Pacific/Guadalcanal') {Offset = '+11+00';}
    	else if (InTimezone == 'Australia/Lord_Howe') {Offset = '+10+30';}
    	else if (InTimezone == 'Australia/Brisbane') {Offset = '+10+00';}
    	else if (InTimezone == 'Australia/Sydney') {Offset = '+10+00';}
    	else if (InTimezone == 'Australia/Adelaide') {Offset = '+09+30';}
    	else if (InTimezone == 'Australia/Darwin') {Offset = '+09+30';}
    	else if (InTimezone == 'Asia/Seoul') {Offset = '+09+00';}
    	else if (InTimezone == 'Asia/Tokyo') {Offset = '+09+00';}
    	else if (InTimezone == 'Asia/Hong_Kong') {Offset = '+08+00';}
    	else if (InTimezone == 'Asia/Kuala_Lumpur') {Offset = '+0800';}
    	else if (InTimezone == 'Asia/Manila') {Offset = '+08+00';}
    	else if (InTimezone == 'Asia/Shanghai') {Offset = '+08+00';}
    	else if (InTimezone == 'Asia/Taipei') {Offset = '+08+00';}
    	else if (InTimezone == 'Australia/Perth') {Offset = '+08+00';}
    	else if (InTimezone == 'Asia/Bangkok') {Offset = '+07+00';}
    	else if (InTimezone == 'Asia/Jakarta') {Offset = '+07+00';}
    	else if (InTimezone == 'Asia/Saigon') {Offset = '+07+00';}
    	else if (InTimezone == 'Asia/Rangoon') {Offset = '+06+30';}
    	else if (InTimezone == 'Asia/Dacca') {Offset = '+06+00';}
    	else if (InTimezone == 'Asia/Yekaterinburg') {Offset = '+06+00';}
    	else if (InTimezone == 'Asia/Katmandu') {Offset = '+05+45';}
    	else if (InTimezone == 'Asia/Calcutta') {Offset = '+05+30';}
    	else if (InTimezone == 'Asia/Colombo') {Offset = '+05+30';}
    	else if (InTimezone == 'Asia/Karachi') {Offset = '+05+00';}
    	else if (InTimezone == 'Asia/Tashkent') {Offset = '+05+00';}
    	else if (InTimezone == 'Asia/Kabul') {Offset = '+04+30';}
    	else if (InTimezone == 'Asia/Dubai') {Offset = '+04+00';}
    	else if (InTimezone == 'Asia/Tbilisi') {Offset = '+04+00';}
    	else if (InTimezone == 'Europe/Moscow') {Offset = '+04+00';}
    	else if (InTimezone == 'Asia/Tehran') {Offset = '+03+30';}
    	else if (InTimezone == 'Africa/Cairo') {Offset = '+03+00';}
    	else if (InTimezone == 'Africa/Baghdad') {Offset = '+03+00';}
    	else if (InTimezone == 'Asia/Jerusalem') {Offset = '+03+00';}
    	else if (InTimezone == 'Asia/Kuwait') {Offset = '+03+00';}
    	else if (InTimezone == 'Asia/Riyadh') {Offset = '+03+00';}
    	else if (InTimezone == 'Europe/Athens') {Offset = '+03+00';}
    	else if (InTimezone == 'Europe/Bucharest') {Offset = '+03+00';}
    	else if (InTimezone == 'Europe/Helsinki') {Offset = '+03+00';}
    	else if (InTimezone == 'Europe/Istanbul') {Offset = '+03+00';}
    	else if (InTimezone == 'Europe/Minsk') {Offset = '+03+00';}
    	else if (InTimezone == 'Africa/Johannesburg') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Amsterdam') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Berlin') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Brussels') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Paris') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Prague') {Offset = '+02+00';}
    	else if (InTimezone == 'Europe/Rome') {Offset = '+02+00';}
    	else if (InTimezone == 'Africa/Algiers') {Offset = '+01+00';}
    	else if (InTimezone == 'Europe/Dublin') {Offset = '+01+00';}
    	else if (InTimezone == 'Europe/Lisbon') {Offset = '+01+00';}
    	else if (InTimezone == 'Europe/London') {Offset = '+01+00';}
    	else if (InTimezone == 'GMT') {Offset = '+00+00';}
    	else if (InTimezone == 'Atlantic/Cape_Verde') {Offset = '-01-00';}
    	else if (InTimezone == 'Atlantic/South_Georgia') {Offset = '-02-00';}
    	else if (InTimezone == 'Atlantic/St_Johns') {Offset = '-02-30';}
    	else if (InTimezone == 'America/Buenos_Aires') {Offset = '-03-00';}
    	else if (InTimezone == 'America/Halifax') {Offset = '-03-00';}
    	else if (InTimezone == 'America/Sao_Paulo') {Offset = '-03-00';}
    	else if (InTimezone == 'Atlantic/Bermuda') {Offset = '-03-00';}
    	else if (InTimezone == 'Atlantic/Bermuda') {Offset = '-03-00';}
    	else if (InTimezone == 'America/Indianapolis') {Offset = '-04-00';}
    	else if (InTimezone == 'America/New_York') {Offset = '-04-00';}
    	else if (InTimezone == 'America/Puerto_Rico') {Offset = '-04-00';}
    	else if (InTimezone == 'America/Caracas') {Offset = '-04-30';}
    	else if (InTimezone == 'America/Bogota') {Offset = '-05-00';}
    	else if (InTimezone == 'America/Chicago') {Offset = '-05-00';}
    	else if (InTimezone == 'America/Lima') {Offset = '-05-00';}
    	else if (InTimezone == 'America/Mexico_City') {Offset = '-05-00';}
    	else if (InTimezone == 'America/Panama') {Offset = '-05-00';}
    	else if (InTimezone == 'America/Denver') {Offset = '-06-00';}
    	else if (InTimezone == 'America/El_Salvador') {Offset = '-06-00';}
    	else if (InTimezone == 'America/Los_Angeles') {Offset = '-07-00';}
    	else if (InTimezone == 'America/Phoenix') {Offset = '-07-00';}
    	else if (InTimezone == 'America/Tijuana') {Offset = '-07-00';}
    	else if (InTimezone == 'America/Anchorage') {Offset = '-08-00';}
    	else if (InTimezone == 'Pacific/Honolulu') {Offset = '-10-00';}
    	else if (InTimezone == 'Pacific/Niue') {Offset = '-11-00';}
    	else if (InTimezone == 'Pacific/Pago_Pago') {Offset = '-11-00';}
    	else {Offset = '+00+00';}
    	return Offset;
    }
    
    /*@isTest
    static void testHistoryListController()
    {
        Case prj = new MProject__c(Name='acme');
        insert prj;
        prj.EstimatedHours__c = 100;
        prj.StartDate__c = Date.today();
        update prj;
        
        HistoryListController controller = new HistoryListController();
        controller.ObjectName = 'Case';
        controller.ObjectId = prj.Id;
        
        List<HistoryInfo> hs = controller.Histories;
    }
    
    @isTest
    static void testHistoryInfo()
    {
        List<MProject__History> historyObjs = [select Id, OldValue, NewValue, Field, CreatedDate, CreatedById, CreatedBy.Name From MProject__History limit 10];
        for(MProject__History historyObj : historyObjs)
        {
            HistoryInfo history = new HistoryInfo(historyObj);
        }
    }*/
}