public class MassTransfer_ToController 
{
    String schoolRoleId = '';
    String ownerId = ''; 
    String totalAccs = '';
    String totalOpps = '';
    String strSummaryId = '';
    public String ccNames1 {get; set;}
    public String ccNames2 {get; set;}
    public String ccNames3 {get; set;}
    public String ccNames4 {get; set;}
    public String ccNames5 {get; set;}
    public String ccNames6 {get; set;}
    
    public String cc1Number {get; set;}
    public String cc2Number {get; set;}
    public String cc3Number {get; set;}
    public String cc4Number {get; set;}
    public String cc5Number {get; set;}
    public String cc6Number {get; set;}
    
    public MassTransfer_ToController()
    {
        strSummaryId = System.currentPageReference().getParameters().get('summaryid');
        List<Reassign_Request_Summary__c> summaries = [select Id, School_Role_Id__c, Orginal_OwnerId__c, Total_Account__c, Opportunity_Count__c from Reassign_Request_Summary__c where Id = :strSummaryId];
        if(summaries.size() > 0)
        {   
            schoolRoleId = summaries[0].School_Role_Id__c;
            ownerId = summaries[0].Orginal_OwnerId__c;
            totalAccs = (summaries[0].Total_Account__c != null)? String.valueOf(summaries[0].Total_Account__c.intValue()): '0';
            totalOpps = (summaries[0].Opportunity_Count__c != null)? summaries[0].Opportunity_Count__c: '0';
            strSummaryId = summaries[0].Id;
        }
    }
    
    public String getSchoolRoleName()
    {
        String strTempSchoolName = '';
        List<UserRole> userRoles = [select Id,Name from UserRole where Id=:schoolRoleId];
        if(userRoles != null && userRoles.size()>0)
        {
            strTempSchoolName = userRoles[0].Name;
        }
        else
        {
            strTempSchoolName = 'N/A';
        }
        return strTempSchoolName;
    }
    
    public String getOwnerName()
    {
        List<User> users = [select Id,Alias,Name,FirstName,LastName from User where Id=:ownerId];
        if(users != null && users.size()>0)
        {
            return users[0].Name;
        }
        else
        {
            return 'N/A';
        }
    }
    
    public String getTotalAccount()
    {
        return totalAccs;
    }
    
    public String getTotalOpportunity()
    {
        return totalOpps;   
    }
    
    public PageReference DoAction()
    {
        PageReference messagePage = ApplyTransferSetting();
        if(messagePage != null)
        {
                return messagePage; 
        }
        PageReference toPage = new PageReference('/apex/BatchProcessSubmit');
        toPage.setRedirect(true);
        return toPage;
    }
    
    public PageReference ApplyTransferSetting()
    {
        totalAccs = totalAccs.replace(',','');
        List<String> mapKeySet = new List<String>();
        Integer intTotalTransfer = 0;
        Map<Id,Integer> mapTransfer = new Map<Id,Integer>();
        
        if(ccNames1 != '' && ccNames1  != null){
            mapTransfer.put(ccNames1,integer.valueOf(cc1Number));
            intTotalTransfer += integer.valueOf(cc1Number);
            mapKeySet.add(ccNames1);
        }
        if(!mapTransfer.containsKey(ccNames2) && ccNames2 != '' && ccNames2 != null)
        {
            mapTransfer.put(ccNames2,integer.valueOf(cc2Number));
            intTotalTransfer += integer.valueOf(cc2Number);
            mapKeySet.add(ccNames2);
        }
        if(!mapTransfer.containsKey(ccNames3) && ccNames3 != '' && ccNames3 != null)
        {
            mapTransfer.put(ccNames3,integer.valueOf(cc3Number));
            intTotalTransfer += integer.valueOf(cc3Number);
            mapKeySet.add(ccNames3);
        } 
        if(!mapTransfer.containsKey(ccNames4) && ccNames4 != '' && ccNames4 != null)
        {
            mapTransfer.put(ccNames4,integer.valueOf(cc4Number));
            intTotalTransfer += integer.valueOf(cc4Number);
            mapKeySet.add(ccNames4);
        }
        if(!mapTransfer.containsKey(ccNames5) && ccNames5 != '' && ccNames5 != null)
        {
            mapTransfer.put(ccNames5,integer.valueOf(cc5Number));
            intTotalTransfer += integer.valueOf(cc5Number);
            mapKeySet.add(ccNames5);
        }
        if(!mapTransfer.containsKey(ccNames6) && ccNames6 != '' && ccNames6 != null)
        {
            mapTransfer.put(ccNames6,integer.valueOf(cc6Number));
            intTotalTransfer += integer.valueOf(cc6Number);
            mapKeySet.add(ccNames6);
        }
        PageReference resultPage = checkCurrentBatchCount();
        if(resultPage != null)
        {   
                resultPage.setRedirect(true);
                return resultPage;
        }
        OwnerReassignment ownerReassign = new OwnerReassignment();
        ownerReassign.query = '';
        ownerReassign.fromUserId = ownerId;
        ownerReassign.strObjectType = 'Account'; 
        ownerReassign.toUserIds = mapKeySet;
        ownerReassign.mapUserTransAmount = mapTransfer;
        ownerReassign.summaryId = strSummaryId;
        ownerReassign.totalAccsCount = intTotalTransfer;
        ownerReassign.strSchoolRoleName = getSchoolRoleName();
        ID batchprocessid = Database.executeBatch(ownerReassign, 300);
        return null;
    } 
    
    public List<SelectOption> getCcNamesList() 
    {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','---please select---'));
        if(schoolRoleId != null && schoolRoleId != '')
        {
            List<User> users = [select Id,Alias,Name,FirstName,LastName from User where UserRoleId=:schoolRoleId and Id != :ownerId and IsActive=true];
            if(users != null && users.size()>0)
            {
                for(User user:users)
                {
                    options.add(new SelectOption(user.Id,user.Name));
                }
            }
        }
        return options; 
    }
    
    private PageReference checkCurrentBatchCount()
    {
        PageReference errorPage;
        String OwnerReassignmentClassId = [select Id, Name from ApexClass where Name = 'OwnerReassignment'].Id;
        Integer allBatchCount = [select count() from AsyncApexJob where (Status='Queued' or Status='Processing') and JobType='batchApex' and ApexClassId = :OwnerReassignmentClassId]; //(ApexClassID='01pO00000008UUe' or ApexClassID='01p40000000TORo')];
        Integer currentUserBatchCount = [select count() from AsyncApexJob where (Status='Queued' or Status='Processing') and JobType='batchApex' and ApexClassId = :OwnerReassignmentClassId and CreatedById = :UserInfo.getUserId()];
        if(allBatchCount > 4)
        {
            errorPage = new PageReference('/apex/BatchExceedLimit');
        }
        else if(currentUserBatchCount > 0)
        {
            errorPage = new PageReference('/apex/BatchExceedLimit?type=0');
        }
        return errorPage;
    }

    @isTest
    static void testMassTransfer_ToController()
    {
        //Mass Transfer to page
        String schoolRoleName = 'China BJ_DWL Sales Consultant';
        UserRole schoolRole = [select Id, Name from UserRole where Name = :schoolRoleName];
        Reassign_Request_Summary__c summary = new Reassign_Request_Summary__c();
        summary.OwnerId = UserInfo.getUserId();
        summary.Status__c = 'Completed';
        summary.Orginal_Owner_Name__c = UserInfo.getUserName();
        summary.Orginal_OwnerId__c = UserInfo.getUserId();
        summary.School_Role_Id__c = schoolRole.Id;
        summary.Opportunity_Count__c = '9';
        insert summary;
        List<Reassign_Request__c> requests = new List<Reassign_Request__c>();
        for(Integer i = 0; i < 10; i++)
        {
            Reassign_Request__c request = new Reassign_Request__c();
            request.Orginal_OwnerId__c = UserInfo.getUserId();
            request.Data_Type__c = 'Account';
            request.Reassign_Request_Summary__c = summary.Id;
            requests.add(request);
        }
        insert requests;
        PageReference currentTestPage = new PageReference('/apex/MassTransfer_ToPage');
        Map<String, String> pageParameterMap = currentTestPage.getParameters();
        pageParameterMap.put('summaryid', summary.Id);
        Test.setCurrentPage(currentTestPage);
        MassTransfer_ToController controller = new MassTransfer_ToController();
        controller.getSchoolRoleName();
        controller.getOwnerName();
        System.assertEquals('10', controller.getTotalAccount());
        System.assertEquals('9', controller.getTotalOpportunity());
        controller.getCcNamesList();
        List<User> userList = [select Id, Name from User where UserRole.Name like 'China ______ Sales Consultant' limit 6];
        if(userList.size() == 6)
        {
            controller.ccNames1 = userList[0].Id;
            controller.cc1Number = '2';
            controller.ccNames2 = userList[1].Id;
            controller.cc2Number = '3';
            controller.ccNames3 = userList[2].Id;
            controller.cc3Number = '4';
            controller.ccNames4 = userList[3].Id;
            controller.cc4Number = '5';
            controller.ccNames5 = userList[4].Id;
            controller.cc5Number = '6';
            controller.ccNames6 = userList[5].Id;
            controller.cc6Number = '7';
            controller.DoAction();
        }
        else
        {
            String ownerId = UserInfo.getUserId();
            controller.ccNames1 = ownerId;
            controller.cc1Number = '2';
            controller.ccNames2 = ownerId;
            controller.cc2Number = '3';
            controller.ccNames3 = ownerId;
            controller.cc3Number = '4';
            controller.ccNames4 = ownerId;
            controller.cc4Number = '5';
            controller.ccNames5 = ownerId;
            controller.cc5Number = '6';
            controller.ccNames6 = ownerId;
            controller.cc6Number = '7';
            controller.DoAction();
        }
    }
}