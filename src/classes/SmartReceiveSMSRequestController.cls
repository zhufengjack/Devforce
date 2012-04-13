/*
 * controller for SmartReceiveSMSDR and SmartReceiveSMSMO
 */
public class SmartReceiveSMSRequestController
{
    public String Status { get; set; }   //0 is success, 1 is fail
    
    //process the receiving MO
    // MO means user replay
    // Example of the response:
    // 234567890,0 (MsgID, status)
    public PageReference handleMO()
    {
        Status = '1';
        Set<String> specialProfiles = new Set<String>{ 'EF China Sales User New', 'EF China Sales User New LTC', 'EF China Sales Manager new'};
        Set<String> userRoleSet = new Set<String>{'China Operator Group Supervisor', 'China Operator', 'China Telemarketing Group Lead', 'China BJ Telemarketing Leader', 
                                                                                        'China BJ Telemarketing User', 'China GZ Telemarketing Leader', 'China GZ Telemarketing User', 'China SH Telemarketing Leader', 
                                                                                        'China SH Telemarketing User', 'China SZ Telemarketing Leader', 'China SZ Telemarketing User', 'China Telemarketer'};
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String mobileNum = params.get('m');
        String content = params.get('c');
        String oppNum = params.get('o');
        List<Task> tasks  = new List<Task>();
        List<Opportunity> opps = [select Id, Mobile__c, OwnerId, Owner.UserRoleId, Owner.ProfileId, Opportunity_Number__c from Opportunity where Opportunity_Number__c=:oppNum and Opportunity_Number__c!=null];
        if(content != null)
        {
            content = EncodingUtil.urlDecode(content, 'UTF-8');
        } 
        if(mobileNum != null)
        {
            if(mobileNum.length() > 11)
            {
                mobileNum = mobileNum.substring(mobileNum.length() - 11, mobileNum.length());
            }
        }
        if(opps.size() > 0)
        {
            Opportunity opp = opps[0];
            if(opp.Mobile__c == mobileNum)
            {
                //if Opportunity owner role not equal special ones, new task will assigned to a special group:Smart TM Management
                UserRole role = new UserRole();
                Profile profile =new Profile();
                List<UserRole> roles = [select Id, Name from UserRole where Id= :opp.Owner.UserRoleId];
                List<Profile> profiles = [select Id, Name from Profile where Id= :opp.Owner.ProfileId];
                if(roles.size() > 0)
                {
                    role = roles[0];
                }
                if(profiles.size() > 0)
                {
                    profile = profiles[0];
                }
                if(userRoleSet.contains(role.Name) || specialProfiles.contains(profile.Name)) 
                {
                    Task taskForOwner = new Task();
                    taskForOwner = setTaskDefaultValue(taskForOwner, opp, content);
                    taskForOwner.OwnerId = opp.OwnerId;
                    tasks.add(taskForOwner);
                }
                else
                {
                    List<Group> groups = [select Id from Group where Name='Smart TM Management' limit 1];
                    if(groups.size() > 0)
                    {
                        Set<Id> userIds = queryGroupMember(groups[0].Id);
                        for(Id userId : userIds)
                        {
                            Task taskForEachMember = new Task();
                            taskForEachMember = setTaskDefaultValue(taskForEachMember, opp, content);
                            taskForEachMember.OwnerId =  userId;
                            tasks.add(taskForEachMember);
                        }
                    }
                }
                
                try
                {
                    insert tasks;
                }
                catch(DMLException ex)
                {
                    sendErrorMsg(ex.getMessage());
                }
                Status = '0';
            }
            else
            {
                sendErrorMsg('Received moblie number not equal the orginal, please manully check it.  Opportunity Number:' + opp.Opportunity_Number__c + ', Received Moblie:' + mobileNum + ',SMS Content: ' + content);
            }
        }
        return null;
    }
    
    private Task setTaskDefaultValue(Task task, Opportunity opp, String content)
    {
        task.RecordTypeId = queryRecordTypeId('Send SMS', 'Task');
        task.Subject = 'Customer\'s feedback ';
        task.ActivityDate = date.today();
        task.Status = 'Waiting for Check';
        task.ReminderDateTime = datetime.now();
        task.IsReminderSet = true;
        task.Priority = 'High';
        task.WhatId = opp.Id;
        task.Description = content;
        return task;
    }
    
    private Set<Id> queryGroupMember(String groupId)
    {
        Set<Id> result = new Set<Id>();
        List<GroupMember> groupMemberList = [Select UserOrGroupId from GroupMember Where GroupId =:groupId];
        if(groupMemberList.size() > 0)
        {           
            for(GroupMember groupMemberInfo : groupMemberList )
            {
                String userOrGroupId = groupMemberInfo.UserOrGroupId;
                if(userOrGroupId.startsWith('005'))
                {
                    //is a user
                    result.add(userOrGroupId);
                }
                else if(userOrGroupId.startswith('00G'))
                {
                    //is a group
                    result.addAll(queryGroupMember(userOrGroupId));
                }
            }
        }
        return result;
    }
    
     private Id queryRecordTypeId(String name, String objName)
    {
        List<RecordType> recordType = [Select Id from RecordType where Name=:name and IsActive=true and SObjectType=:objname];
        if(recordType.size() > 0)
        {
            return recordType[0].Id;
        } 
        return null;
    }
    
    //process the receiving the DR(deliver report) from SP SMS GATEWAY
    //<?xml version="1.0" ?>
    //<mt-deliver-report>
    //  <message>
    //      <MsgID>110187922048401</MsgID>
    //      <DestinationAddr>136xxxxxxx </DestinationAddr>
    //      <status>0</status>
    //  </message>
    //</mt-deliver-report>
    public PageReference handleDR()
    {
        String msgId;
        String destinationAddr;
        String deliveredStatus;
        Map<String, String> statusMap = new Map<String, String>
        {   
            '0' => 'SUCCESS', 
            '1' => 'UNKNOWN ERROR', 
            '200' => 'EXPIRED', 
            '202' => 'UNDELIV', 
            '204' => 'REJECTD', 
            '205' => 'SUBSCRIPTION NOT EXIST', 
            '206' => 'USER MOBILE IS STOPPED SERVICE'
        };
        Status = '<mt-deliver-response><status>1</status></mt-deliver-response>';
        Map<String, String> params = ApexPages.currentPage().getParameters();
        String xmlString = params.get('xml');
        Dom.Document doc = new Dom.Document();
        try
        {
            doc.load(xmlString);
            Dom.XMLNode rootXml = doc.getRootElement();
            Dom.XMLNode messageXml = rootXml.getChildElement('message', null);
            msgId = messageXml.getChildElement('MsgID', null).getText();
            destinationAddr = messageXml.getChildElement('DestinationAddr', null).getText();
            deliveredStatus = messageXml.getChildElement('status', null).getText();
        }
        catch(Exception ex)
        {
            sendErrorMsg(ex.getMessage() + xmlString);
        }
        
        List<Task> tasks = [select Id, MessageID__c from Task where MessageID__c=:msgId and MessageID__c!=null];
        if(tasks.size() > 0)
        {
            Task task = new Task();
            task = tasks[0];
            task.Status = statusMap.get(deliveredStatus);
            if(task.Status != null && task.Status != '')
            {
                try
                {
                    update task;
                }
                catch(DMLException ex)
                {
                    sendErrorMsg(ex.getMessage());
                }
                Status = '<mt-deliver-response><status>0</status></mt-deliver-response>';
            }
        }
        return null;
    }
    
    private void sendErrorMsg(String msg)
    {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(new String[] {'Smart-management@ef.com'});
        email.setSubject('English Town Send SMS Error Notification');
        email.setPlainTextBody(msg);
        email.setSaveAsActivity(false);
        Messaging.sendEmail(new Messaging.Email[] {email});
    }
    
    @isTest
    static void testHandleMO()
    {
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt', CloseDate=Date.today(), Mobile__c = '12345678901', Location__c = 'BJ DZM');
        insert opp;
        List<Opportunity> opps = [select Id, Mobile__c, OwnerId, Owner.UserRoleId, Opportunity_Number__c from Opportunity where Id=:opp.Id];
        PageReference valibMOPage = new PageReference('/apex/smartreceivesmsmo?m=+8612345678901&c=testcontent&o=' + opps[0].Opportunity_Number__c);
        Test.setCurrentPage(valibMOPage);
        SmartReceiveSMSRequestController controller = new SmartReceiveSMSRequestController();
        controller.handleMO();
        List<Group> groups = [select Id from Group where Name='Smart TM Management' limit 1];
        Set<Id> userIds = controller.queryGroupMember(groups[0].Id);
        List<Task> tasks = [select Id, Status, Description from Task where WhatId=:opp.Id];
        system.assertEquals('Waiting for Check', tasks[0].Status);
        system.assertEquals('testcontent', tasks[0].Description);
        system.assertEquals('0', controller.Status);
        
        List<UserRole> roles = [select Id, Name from UserRole where Name='China Operator'];
        opp.OwnerId = [select Id from User where UserRoleId=:roles[0].Id limit 1].Id;
        update opp;
        Test.setCurrentPage(valibMOPage);
        controller.handleMO();
        List<Task> tasks2 = [select Id, Status, Description from Task where WhatId=:opp.Id and OwnerId=:opp.OwnerId];
        system.assertEquals(1, tasks2.size());
        system.assertEquals('0', controller.Status);
        
        PageReference invalibMOPage = new PageReference('/apex/smartreceivesmsmo?m=45678901&c=testcontent&o=' + opps[0].Opportunity_Number__c); // wrong mobilbe number 
        Test.setCurrentPage(invalibMOPage);
        controller.handleMO();
        system.assertEquals('1', controller.Status);
    }
    
    @isTest
    static void testHandleDR()
    {
        Task task = new Task(Subject='Send SMS', Status='in sending', MessageID__c='1300352691696');
        insert task;
        PageReference DRPage = new PageReference('/apex/SmartReceiveSMSDR?' +
                                                                                                'xml=<?xml version="1.0" ?><mt-deliver-report><message><MsgID>1300352691696</MsgID>' +
                                                                                                '<DestinationAddr>136xxxxxxx </DestinationAddr><status>0</status></message></mt-deliver-report>');
        Test.setCurrentPage(DRPage);
        SmartReceiveSMSRequestController controller = new SmartReceiveSMSRequestController();
        controller.handleDR();
        List<Task> tasks = [select Id, Status from Task where MessageID__c='1300352691696'];
        system.assertEquals('<mt-deliver-response><status>0</status></mt-deliver-response>', controller.Status);
        system.assertEquals(tasks[0].Status, 'SUCCESS');
    }
}