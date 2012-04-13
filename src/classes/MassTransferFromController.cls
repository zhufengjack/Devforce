public class MassTransferFromController 
{
    public String SalesCenter {get; set;}
    public String StudentOwnerId {get; set;}
    public String OpportunityStageName {get; set;}
    public List<SelectOption> AllSalesCenter {get; private set;}
    public List<SelectOption> RelatedStudentOwners {get; private set;}
    public DateFilter InitialDateFilter1 {get; set;} 
    public DateFilter InitialDateFilter2 {get; set;} 
    public DateFilter LastModifiedDateFilter1 {get; set;} 
    public DateFilter LastModifiedDateFilter2 {get; set;} 
    public Boolean DisableFindStudentButton {get; set;}
    private ContextUserInfo currentUserInfo;
    private ContextUserInfo reassignUserInfo;
    
    public MassTransferFromController()
    {
        InitialDateFilter1 = new DateFilter();
        InitialDateFilter2 = new DateFilter();
        LastModifiedDateFilter1 = new DateFilter();
        LastModifiedDateFilter2 = new DateFilter();
        currentUserInfo = initialUserInfo(UserInfo.getUserId());
        AllSalesCenter = initialAllSalesCenter();
        DisableFindStudentButton = (AllSalesCenter.size() > 0)? false: true;
        RelatedStudentOwners = initialReletedStudentOwners(AllSalesCenter);
    }
    
    private ContextUserInfo initialUserInfo(String userId)
    {
        ContextUserInfo result = new ContextUserInfo();
        if(userId != null)
        {
            try
            {
                User user = [select Id, Name, UserRole.Name, UserRoleId, Email from User where Id = :userId];
                result.userName = user.Name;
                result.userId = user.Id;
                result.userEmail = user.Email;
                result.userRoleId = user.UserRoleId;
                result.userRoleName = user.UserRole.Name;
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }
        }        
        return result;
    }
    
    private List<SelectOption> initialAllSalesCenter()
    {
        List<SelectOption> salesCenters = new List<SelectOption>();
        List<MassTransferToolConfig__c> massTransferToolconfigs = [select Id, Role__c, ManagerRole__c from MassTransferToolConfig__c where ManagerRole__c = :currentUserInfo.userRoleName order by Role__c];
        for(MassTransferToolConfig__c config : massTransferToolconfigs)
        {
            salesCenters.add(new SelectOption(config.Role__c, config.Role__c));
        }
        return salesCenters;
    }
    
    private List<SelectOption> initialReletedStudentOwners(List<SelectOption> centers)
    {
        List<SelectOption> result = new List<SelectOption>();
        if(centers != null && centers.size() > 0)
        {
           result = generateUserList(centers[0].getValue());
        }
        return result;
    }
    
    private List<SelectOption> generateUserList(String roleName)
    {
        List<SelectOption> result = new List<SelectOption>();
        if(roleName != null)
        {
            List<User> users = [select Id, Name from User where IsActive = true and UserRole.Name = :roleName order by Name];
            for(User user : users)
            {
                result.add(new SelectOption(user.Id, user.Name));
            }
            DisableFindStudentButton = (result.size() > 0)? false: true;
        }
        return result;
    }
    
    public void resetRelatedSalesList()
    {
        RelatedStudentOwners = generateUserList(SalesCenter);
    }
    
    public PageReference findStudents()
    {
        PageReference toPage;
        try
        {   
            toPage = checkRunningReassignmentBatch();
            if(toPage == null)
            {
                QueryReassignmentData reassign = initialQueryReassignmentData();
                Database.executeBatch(reassign, 300);
                toPage = new PageReference('/apex/BatchProcessSubmit');
                toPage.setRedirect(true);
            }
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return toPage;
    }
    
    private QueryReassignmentData initialQueryReassignmentData()
    {
        QueryReassignmentData queryReassignment = new QueryReassignmentData();
        reassignUserInfo = initialUserInfo(StudentOwnerId);
        queryReassignment.email = currentUserInfo.userEmail;
        queryReassignment.strOperatorId = currentUserInfo.userId;
        queryReassignment.replyEmail = 'salesforce@ef.com';
        queryReassignment.ownerId = reassignUserInfo.userId;
        queryReassignment.schoolRoleId = reassignUserInfo.userRoleId;
        queryReassignment.stageName = OpportunityStageName;
        queryReassignment.initialApptDate = InitialDateFilter1.InputDate;
        queryReassignment.initialApptDateOpType = InitialDateFilter1.Operator;
        queryReassignment.sinitialApptDate = InitialDateFilter2.InputDate;
        queryReassignment.sinitialApptDateOpType = InitialDateFilter2.Operator;
        queryReassignment.lastModifiedDate = LastModifiedDateFilter1.InputDate;
        queryReassignment.lastModifiedDateOpType = LastModifiedDateFilter1.Operator;
        queryReassignment.slastModifiedDate = LastModifiedDateFilter2.InputDate;
        queryReassignment.slastModifiedDateOpType = LastModifiedDateFilter2.Operator;
        return queryReassignment;
    }
    
    private PageReference checkRunningReassignmentBatch()
    {
        PageReference toPage;
        String reassignmentClassId = [select Id, Name from ApexClass where Name = 'QueryReassignmentData'].Id;
        Integer batchCount = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing') and JobType = 'batchApex' and ApexClassId = :reassignmentClassId];
        if(batchCount > 4)
        {
            toPage = new PageReference('/apex/BatchExceedLimit');
            toPage.setRedirect(true);
            return toPage;
        }
        Integer currentUserBatchCount = [select count() from AsyncApexJob where (Status = 'Queued' or Status = 'Processing') and JobType = 'batchApex' and ApexClassId = :reassignmentClassId and CreatedById = :UserInfo.getUserId()];
        if(currentUserBatchCount > 0)
        {
            toPage = new PageReference('/apex/BatchExceedLimit?type=0');
            toPage.setRedirect(true);
            return toPage;
        }
        return null;
    }
    
    public class DateFilter
    {
        public String Operator {get; set;}
        public String InputDate {get; set;}
    }
    
    public class ContextUserInfo
    {
        public String userName;
        public String userId;
        public String userRoleName;
        public String userRoleId;
        public String userEmail;
    }
    
    public class MassTransferException extends Exception {}
    
    @isTest
    static void testMassTransferFromController()
    {
        System.debug('Test Method Started!');
        System.debug('retrieve User role name according to current user info ');
        String currentRole = [select Id, UserRole.Name from User where Id = :UserInfo.getUserId()].UserRole.Name;
        MassTransferToolConfig__c config1 = new MassTransferToolConfig__c(Name = 'MC_1 acme', Role__c = 'Test role 1', ManagerRole__c = currentRole);
        MassTransferToolConfig__c config2 = new MassTransferToolConfig__c(Name = 'MC_2 acme', Role__c = 'Test role 2', ManagerRole__c = currentRole);
        insert new List<MassTransferToolConfig__c>{config1, config2};
        MassTransferFromController controller = new MassTransferFromController();
        controller.findStudents();
        controller.SalesCenter = 'China BJ_DWL Sales Consultant';
        controller.resetRelatedSalesList();
    }
}