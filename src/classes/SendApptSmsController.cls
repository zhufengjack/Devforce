/*
 * This class represents the controller of the SendApptSms page.
 */

public class SendApptSmsController
{
    private final String newSMSOption = 'Create new SMS';
    private String teacherFirstName = '';
    private String bu = '';
    private SMSMessageInfo smsInfo;

    private Opportunity opportunity;

    public SendApptSmsController(ApexPages.StandardController controller)
    {
        isSucceeded = false;
        List<Opportunity> opps = [select Id, Name, Mobile__c, Location__c, Reschedule_appt_Date_Time__c, Initial_Appt_Date__c, SMSSent__c, Opportunity_Number__c, OwnerId  from Opportunity where Id = :controller.getId()];
        if(opps.size() > 0)
        {
            opportunity = opps[0];
            if(opportunity.SMSSent__c == true)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'You have sent message(s) to this student before. Are you sure you want to send again?'));
            }
            bu = SchoolInfoHelper.getBU(opportunity.Location__c);
        }
    }

    public Boolean isSucceeded { get; set; }
    private Boolean isLeadToShowSchool { get; set; }

    public String getTeacherFirstName()
    {
        if(teacherFirstName == null || teacherFirstName == '')
        {
            User currentUser = [select First_Name__c from User where Id =:UserInfo.getUserId()];
            if(currentUser.First_Name__c != null)
            {
                teacherFirstName = currentUser.First_Name__c;
            }
        }
        return teacherFirstName;
    }

    public String Template
    {
    	get
    	{
    		String result = '';
    		if(TemplateNameOptions.size() == 1)
    		{
    			result = TemplateNameOptions[0].getValue();
    		}
    		else
    		{
    			result = Template;
    		}
    		return result;
    	}
    	set
    	{
    		Template = value;
    	}
    }

    public List<SelectOption> TemplateNameOptions
    {
        get
        {
        	List<SelectOption> newOptions = new List<SelectOption>();
        	if(isValidOpportunity)
        	{
        		if(bu != 'smart' || isLeadToShowSchool)
        		{
			        List<SmsTemplate__c> templates =  [select BU__c, Name, Label__c, message__c, IsActive__c, IsEditable__c from SmsTemplate__c where Label__c != null and BU__c = :bu and IsActive__c = true];
			        if(templates.size() > 1)
			        {
			        	newOptions.add(new SelectOption('--None--', '--None--'));
			        }
			        for(SmsTemplate__c template : templates)
			        {
			            if(template.BU__c == 'smart' && template.Label__c == 'Create new SMS' && !isSpecifiedProfile())
			            {} //do not add a 'Create new SMS' option in the select list if current user profile is not specified
			            else
			            {
			            	newOptions.add(new SelectOption(template.Name, template.Label__c));
			            }
			        }
        		}
        	}
            return newOptions;
        }
    }

    public PageReference RefreshSMSmessage()
    {
    	setSMSMesage();
        return null;
    }

    public SMSMessageInfo SMSMessage
    {
        get
        {
			if(smsInfo == null)
	    	{
	    		setSMSMesage();
        	}
	        return smsInfo;
        }
        set
        {
        	smsInfo = value;
        }
    }

    public void setSMSMesage()
    {
        smsInfo = new SMSMessageInfo();
        if(isValidOpportunity)
        {
            String schoolAddress = SchoolInfoHelper.getAddress(opportunity.Location__c);
            String address = (schoolAddress != null) ? schoolAddress : '';
            String msg = '';
            Datetime mergeTime = opportunity.Initial_Appt_Date__c;
            if(isLeadToShowSchool)
            {
            	mergeTime = opportunity.Reschedule_appt_Date_Time__c;
            }
            Integer month = mergeTime.month();
            Integer day = mergeTime.day();
            Integer hour = mergeTime.hour();
            Integer minute = mergeTime.minute();
            String scheduleTime = month + '月' + day + '日' + hour + '点'+ (minute > 0 ? minute + '分' : '');
            if(bu == 'smart' && !isLeadToShowSchool)
            {
            	msg =  address + '。预约时间' + scheduleTime + '。电话4006567890';
            	smsInfo = new SMSMessageInfo(msg);
            }
            else if(Template != newSMSOption && Template != null && Template != '')
            {
                SmsTemplate__c currentTemplate = SmsTemplate__c.getInstance(Template);
                if(currentTemplate != null && currentTemplate.message__c != null)
                {
                    msg = currentTemplate.message__c.replace('{Username}', getTeacherFirstName()).replace('{Time}', scheduleTime).replace('{Address}', address);
                	smsInfo = new SMSMessageInfo(msg, currentTemplate);
                }
            }
        }
    }

    public PageReference SendSMS()
    {
        if(isValidOpportunity)
        {
            String msgId;
            try
            {
            	SendSMSHelper.SmsParams params = new SendSMSHelper.SmsParams();
            	params.BusinessUnit = bu; //bu is global variable
            	params.Content = smsInfo.MessageContent;
            	params.MobileNumber = opportunity.Mobile__c;
            	params.OppNumber = opportunity.Opportunity_Number__c;
                SendSMSHelper.SMSInfo smsResult = SendSMSHelper.sendSMS(params);
                isSucceeded = smsResult.isSucceeded;
                msgId = smsResult.MsgId;
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }
            if(isSucceeded)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Info, 'The SMS has been successfully sent out.'));
                if(Template == newSMSOption)
                {
                    createTask(msgId, smsInfo.MessageContent, 'Feedback to Customer');
                }
                else
                {
                    createTask(msgId, smsInfo.MessageContent, 'Send SMS');
                }
                updateOppToSent();
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Failed to send SMS. Please try again later.'));
            }
        }
        return null;
    }

    public Boolean isValidOpportunity
    {
        get
        {
            if(opportunity == null)
            {
                return false;
            }
            if(opportunity.Mobile__c == null)
            {
                return false;
            }
            if(opportunity.Location__c == null)
            {
                return false;
            }
            if(opportunity.Location__c != null)
            {
                isLeadToShowSchool = RemainingApptsHelper.isLeadToShowSchool(opportunity.Location__c);
            }
            if(isLeadToShowSchool)
            {
                if(opportunity.Reschedule_appt_Date_Time__c == null)
                {
                    return false;
                }
            }
            else
            {
                if(opportunity.Initial_Appt_Date__c == null)
                {
                    return false;
                }
            }
            SchoolAddress__c school = SchoolInfoHelper.getSchoolAddressObject(opportunity.Location__c);
            if(school == null)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error, 'Unknown school [' + opportunity.Location__c + '], failed to send SMS.'));
                return false;
            }
            return true;
        }
    }

    private void updateOppToSent()
    {
        try
        {
            Opportunity oppToUpdate = new Opportunity(Id=opportunity.Id, SMSSent__c=true);
            update oppToUpdate;
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
    }

    private Boolean isSpecifiedProfile()
    {
        Set<String> profileSet = new Set<String>{'EF China Telemarketing User', 'EF China Telemarketing Manager', 'EF China Operator', 'EF China Operator Lead', 'System Administrator New'};
    	List<Profile> profile = [select Id, Name from Profile where Id=:UserInfo.getProfileId() limit 1];
    	if(profile.size() > 0)
    	{
    		if(profileSet.contains(profile[0].Name))
    		{
    			return true;
    		}
    	}
    	return false;
    }

    private void createTask(String msgId, String content, String subject)
    {
        Task task = new Task();
        Opportunity latestOpp = [select Id, OwnerId from Opportunity where Id = :opportunity.Id limit 1];
        task.RecordTypeId = getRecordTypeId('Send SMS', 'Task');
        task.Subject = subject;
        task.ActivityDate = date.today();
        task.Status = 'In sending';
        task.WhatId = latestOpp.Id;
        task.Description = content;
        task.OwnerId = latestOpp.OwnerId;
        task.MessageID__c = msgId;
        try
        {
            insert task;
        }
        catch(DMLException ex)
        {
            ApexPages.addMessages(ex);
        }
    }

    private Id getRecordTypeId(String name, String objName)
    {
        List<RecordType> recordType = [Select Id from RecordType where Name=:name and IsActive=true and SObjectType=:objname];
        if(recordType.size() > 0)
        {
            return recordType[0].Id;
        }
        return null;
    }

    public class SMSMessageInfo
    {
    	public SMSMessageInfo()
    	{
    		this.MessageContent = '';
    	}
    	
    	public SMSMessageInfo(String msg)
    	{
    		this.MessageContent = msg;
    	}

    	public SMSMessageInfo(String msg, SmsTemplate__c currentTemplate)
    	{
    		this.MessageContent = msg;
    		this.IsEditable = currentTemplate.IsEditable__c;
    		this.IsActive = currentTemplate.IsActive__c;
    	}

    	public String MessageContent { get; set; }
    	public Boolean IsEditable { get; set; }
    	public Boolean IsActive { get; set; }
    }


    @isTest
    static void testSendSMSController()
    {
    	List<EtownServer__c> etownServerUrls = new List<EtownServer__c>{
    		new EtownServer__c(Name = 'SMSAPIAddress', URL__c = 'http://www.test.test'),
    		new EtownServer__c(Name = 'EtownMemberInfo', URL__c = 'http://www.test.test')
    	};
    	insert etownServerUrls;
        List<SmsTemplate__c> templates = new List<SmsTemplate__c>{
        	new SmsTemplate__c(Name = 'acme', Label__c = 'acme', Message__c = 'Hello, UserName', BU__c = 'smart', IsActive__c = true),
        	new SmsTemplate__c(Name = 'Create new SMS', Label__c = 'Create new SMS', Message__c = 'Hello, UserName', BU__c = 'smart', IsActive__c = true)
        };
        insert templates;
        List<SchoolAddress__c> addresses = new List<SchoolAddress__c> {
                                            new SchoolAddress__c(Name = 'BJ_DZMTest', Address__c = 'beijing', BU__c = 'smart', Code__c = 10, IsLeadToShowSchool__c = true),
                                            new SchoolAddress__c(Name = 'BJ_DWLTest', Address__c = 'beijing', BU__c = 'smart', Code__c = 11, IsLeadToShowSchool__c = false)
                                    };
        insert addresses;
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt', CloseDate=Date.today());
        insert opp;
        ApexPages.StandardController controller = new ApexPages.StandardController(opp);
        SendApptSmsController smsController = new SendApptSmsController(controller);
        System.assertEquals(false, smsController.isValidOpportunity);

        opp.Mobile__c = '1234567890';
        opp.Location__c = 'BJ DZMTest';
        opp.SMSSent__c = true;
        opp.Reschedule_appt_Date_Time__c = DateTime.now();
        update opp;

        controller = new ApexPages.StandardController(opp);
        smsController = new SendApptSmsController(controller);
        system.assertEquals(true, smsController.isValidOpportunity);
        system.assert(smsController.getTeacherFirstName() != null);
        system.assert(smsController.TemplateNameOptions != null);
        smsController.Template = 'acme';
        system.assert(smsController.SmsMessage != null);
        smsController.SendSMS();
        smsController.updateOppToSent();

        opp.Location__c = 'BJ DWLTest';
        update opp;
        controller = new ApexPages.StandardController(opp);
        smsController = new SendApptSmsController(controller);
        system.assertEquals(true, smsController.isValidOpportunity);
        system.assert(smsController.SmsMessage != null);
        smsController.RefreshSMSmessage();
    }
}