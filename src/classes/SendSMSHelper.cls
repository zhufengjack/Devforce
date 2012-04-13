/*
 * a helper class invokes 21CMS API to send Sms
 */
public class SendSMSHelper
{
    private static final String uniqueId = 'u93LljRg7vW0TM1aWzPgyN1qrOiZ4o7e';

    //need to catch the exception when try to invoke this method
    public static SmsInfo sendSms(SmsParams params)
    {
        SmsInfo smsInfo = new SmsInfo();
        if(params != null)
        {
            String ApiUrl = EtownServer__c.getInstance('SMSAPIAddress').URL__c;  //http://smscenter.sinocontact.com:9000/efmt
            String encodedMessage = EncodingUtil.urlEncode(params.Content, 'GBK');
            HttpRequest req = new HttpRequest();
            Http http = new Http();
            String requestUrl = ApiUrl + '?m=' + params.MobileNumber + '&c=' + encodedMessage + '&o=' + params.OppNumber + '&bu=' + params.BusinessUnit + '&u=' + uniqueId;
            req.setEndpoint(requestUrl);
            req.setMethod('GET');
            req.setTimeout(120*1000); //2 minutes
            String result;
            if(!Test.isRunningTest())
            {
                try
                {
                    HttpResponse response = http.send(req);
                    result = response.getBody();
                }
                catch(Exception ex)
                {
                    throw ex;
                }
            }
            else
            {
                result = '12345789,0';
            }
            //result example: 12345789,0 (MsgId, status)
            String msgId = '';
            String status = '';
            if(result != null)
            {
                msgId = (result.indexOf(',') < 0) ? null : result.substring(0, result.indexOf(','));
                status = (result.indexOf(',') < 0) ? result : result.substring(result.indexOf(',') + 1);
            }
            smsInfo.isSucceeded = (status ==  '0');
            smsInfo.MsgId = msgId;
        }
        return smsInfo;
    }

    //trigger can invoke this method to send SMS and create a new task
    private static String smsMessageTemplate;
    @future (callout=true)
    public static void sendSmsForTirgger(Set<String> oppIds)
    {
        List<Task> tasks = new List<Task>();
        List<Opportunity> opps = [select Id, Mobile__c, OwnerId, Location__c, Owner.Name, Owner.MobilePhone, Opportunity_Number__c, Contact__c, Account.Name, Contact__r.LastName, Contact__r.FirstName from Opportunity where Id in :oppIds and Owner.IsActive = true];

        try
        {
        	for(Opportunity opp : opps)
	        {
	            String message = getMessage(opp);
	            SendSMSHelper.SmsParams params = new SendSMSHelper.SmsParams();
				params.BusinessUnit = SchoolInfoHelper.getBU(opp.Location__c);
				params.OppNumber = opp.Opportunity_Number__c;
				params.Content = message;
				params.MobileNumber = opp.Mobile__c;
                SmsInfo smsInfo = SendSMSHelper.sendSms(params);
                if(smsInfo.isSucceeded)
	            {
	                Task task = new Task();
	                task.RecordTypeId = getRecordTypeId('Send SMS', 'Task');
	                task.Description = message;
	                task.Subject = 'Send SMS';
	                task.Status = 'In sending';
	                task.Priority = 'Normal';
	                task.ActivityDate = Date.Today();
	                task.OwnerId = opp.OwnerId;
	                task.WhatId = opp.Id;
	                task.MessageID__c = smsInfo.MsgId;
	                task.WhoId = opp.Contact__c;
	                tasks.add(task);
	            }
            }
            insert tasks;
        }
        catch(Exception ex)
        {
        	String error = ex.getMessage() + '\r\n' + ex.getStackTraceString();
        	SendEmailHelper.sendSimpleEmail(new String[] { 'jack.zhu@ef.com', 'jair.zheng@meginfo.com' }, 'Error occureed on SendSMSHelper class', error);
        }
    }

    private static Id getRecordTypeId(String name, String objName)
    {
        List<RecordType> recordType = [Select Id from RecordType where Name =:name and IsActive=true and SObjectType = :objName];
        if(recordType.size() > 0)
        {
            return recordType[0].Id;
        }
        return null;
    }

    private static String getMessage(Opportunity opp)
    {
        if(smsMessageTemplate == null)
        {
            SmsTemplate__c template = SmsTemplate__c.getInstance('Welcome contacts to EF');
            smsMessageTemplate = (template != null) ? template.Message__c : '';
        }
        String name = (opp.AccountId == null) ? '' : opp.Account.Name ;
        if(opp.Contact__c != null)
        {
            name = ((opp.Contact__r.LastName == null) ? '' : opp.Contact__r.LastName) + ((opp.Contact__r.FirstName == null) ? '' : opp.Contact__r.FirstName);
        }
        String message = smsMessageTemplate.replace('{Name}', name);
        message = message.replace('{OwnerMobilePhone}', (opp.Owner.MobilePhone == null) ? '' : opp.Owner.MobilePhone);
        message = message.replace('{OpportunityOwner}', opp.Owner.Name);
        return message;
    }

    public Class SmsParams
    {
    	public String MobileNumber { get; set; }
    	public String Content { get; set; }
    	public String OppNumber { get; set; }
    	public String BusinessUnit
    	{
    		get;
    		set
    		{
    			if(value == null || value == '')
    			{
    				BusinessUnit = '0';
    			}
    			else
    			{
    				BusinessUnit = value;
    			}
    		}
    	}
    }

    public Class SmsInfo
    {
        public SmsInfo()
        {
            MsgId = '';
            isSucceeded = false;
        }
        public String MsgId{ get; set; }
        public Boolean isSucceeded{ get; set; }
    }

    @isTest
    static void testSendSMSHelper()
    {
    	List<EtownServer__c> etownServerUrls = new List<EtownServer__c>{
    		new EtownServer__c(Name = 'SMSAPIAddress', URL__c = 'http://www.test.test'),
    		new EtownServer__c(Name = 'EtownMemberInfo', URL__c = 'http://www.test.test')
    	};
    	insert etownServerUrls;
    	SmsTemplate__c template = new SmsTemplate__c(Name = 'Welcome contacts to EF', Label__c = 'Welcome contacts to EF', Message__c = 'Hello, UserName', BU__c = 'Smart Opportunity');
    	insert template;
        Account acc = new Account(Name='acme');
        insert acc;
        List<Opportunity> opps = new List<Opportunity>{
            new Opportunity(Name = 'acme', StageName = 'acme', CloseDate = Date.today(), Mobile__c = '123456789012', AccountId = acc.Id),
            new Opportunity(Name = 'acme', StageName = 'acme', CloseDate = Date.today(), Mobile__c = '123456789012')
            };
        insert opps;
        Set<String> oppIds = new Set<String>();
        for(Opportunity opp : opps)
        {
            oppIds.add(opp.Id);
        }
        SendSMSHelper.sendSmsForTirgger(oppIds);
    }
}