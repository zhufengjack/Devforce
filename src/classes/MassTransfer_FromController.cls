public class MassTransfer_FromController {
    String ownerName = '';
    String ownerOpType = '';
    String stageName = '';
    String stageOpType = ''; 

    String initialApptDateOpType1 = '';
    String lastModifiedDateOpType1 = '';
    String initialApptDate1 = '';
    String lastModifiedDate1 = '';

    String initialApptDateOpType2 = '';
    String lastModifiedDateOpType2 = '';
    String initialApptDate2 = '';
    String lastModifiedDate2 = '';

    String SchoolRoleId = '';
    String strSchoolName = 'SH_PSQ';
    Boolean blSchoolReadOnly = false;
    List<SelectOption> ownerLists = null;
    public Boolean getSchoolReadOnly()
    {
        return blSchoolReadOnly;
    }
    public String getUserProfileId()
    {
        return '';//UserInfo.getProfileId().substring(0,15)+'China '+strSchoolName+' ' +'Sales Consultant';
    }
    
    public String getSchoolName()
    {
        return strSchoolName;
    }
    public void setSchoolName(String schoolName)
    {
        strSchoolName = schoolName;
    }
    public String getLastModifiedDate1() {
        return lastModifiedDate1;
    }
    public void setLastModifiedDate1(String strLastModifiedDate) {
        this.lastModifiedDate1 = strLastModifiedDate;
    }
    
    public String getInitialApptDate1() {
        return initialApptDate1;
    }
    public void setInitialApptDate1(String strInitialApptDate) {
        this.initialApptDate1 = strInitialApptDate;
    }

    public String getLastModifiedDate2() {
        return lastModifiedDate2;
    }
    public void setLastModifiedDate2(String strLastModifiedDate) {
        this.lastModifiedDate2 = strLastModifiedDate;
    }
    
    public String getInitialApptDate2() {
        return initialApptDate2;
    }
    public void setInitialApptDate2(String strInitialApptDate) {
        this.initialApptDate2 = strInitialApptDate;
    }
    
    public String getInitialApptDateOpType1() {
        return initialApptDateOpType1;
    }
    public void setInitialApptDateOpType1(String strInitialApptDateOpType) {
        this.initialApptDateOpType1 = strInitialApptDateOpType;
    }
    public String getLastModifiedDateOpType1() {
        return lastModifiedDateOpType1;
    }
    public void setLastModifiedDateOpType1(String strLastModifiedDateOpType) {
        this.lastModifiedDateOpType1 = strLastModifiedDateOpType;
    }

    public String getInitialApptDateOpType2() {
        return initialApptDateOpType2;
    }
    public void setInitialApptDateOpType2(String strInitialApptDateOpType) {
        this.initialApptDateOpType2 = strInitialApptDateOpType;
    }
    public String getLastModifiedDateOpType2() {
        return lastModifiedDateOpType2;
    }
    public void setLastModifiedDateOpType2(String strLastModifiedDateOpType) {
        this.lastModifiedDateOpType2 = strLastModifiedDateOpType;
    }
    
    public String getAccOwner() {
        return ownerName;
    }
    public void setAccOwner(String strOwnerName) {
        this.ownerName = strOwnerName;
    }
    public String getAccStage()
    {
        return stageName;
    }
    public void setAccStage(String strAccStage)
    {
        this.stageName = strAccStage;
    }
    public void setOwnerOpType(String strOwnerOpType)
    {
        this.ownerOpType = strOwnerOpType;
    }
    
    public String getOwnerOpType()
    {
        return ownerOpType;
    }
    public void setStageOpType(String strStageOpType)
    {
        this.stageOpType = strStageOpType;
    }
    
    public String getStageOpType()
    {
        return stageOpType; 
    }
    public MassTransfer_FromController()
    {
        String strSchoolParam = System.currentPageReference().getParameters().get('schoolParam'); 
        strSchoolName = 'SH_PSQ';
        String strProfileId = UserInfo.getProfileId();
        String strUserId = UserInfo.getUserId();//'005400000015iKZ';//
        String strRoleId = UserInfo.getUserRoleId();//'00E40000000rPXy';//
        String strUserRoleName = ''; 
        string strSchoolRoleId = '';
        if(strProfileId.substring(0,15) == '00e40000000j2k8' || strProfileId.substring(0,15) == '00e30000000hkOY')//A School Manager Profile
        {
            //Get Manager School Name
            List<UserRole> userRoles = [select Id,Name from UserRole where Id=:strRoleId];
            if(userRoles != null && userRoles.size()>0)
            {
                strUserRoleName = userRoles[0].Name;
                //get School Name
                String[] arrRoleName = strUserRoleName.split(' ',0);
                if(arrRoleName.size() > 2)
                {
                    strSchoolName = arrRoleName[1];
                    String strTempRoleName = arrRoleName[0]+' '+strSchoolName+' ' +'Sales Consultant'; 
                    userRoles = [select Id,Name from UserRole where Name=:strTempRoleName];
                    if(userRoles.size() > 0)
                    {
                        strSchoolRoleId = userRoles[0].Id;
                        SchoolRoleId = strSchoolRoleId;
                    }
                }
                // Get School Consultant
            }
        }
        else
        {
            strSchoolName = strSchoolParam; 
            if(strSchoolName == '' || strSchoolName == null)
            {
                strSchoolName = 'SH_PSQ';
            } 
            String strTempRoleName = 'China '+strSchoolName+' ' +'Sales Consultant';
            List<UserRole> userRoles = [select Id,Name from UserRole where Name=:strTempRoleName];
            if(userRoles != null && userRoles.size()>0){
                strSchoolRoleId = userRoles[0].Id;
                SchoolRoleId = strSchoolRoleId;
            }
        }
        
    }
   
    public List<SelectOption> getOwnerList() {
        List<SelectOption> options = new List<SelectOption>();
        
        if(strSchoolName != '' && strSchoolName != null)
        {
             String strTempRoleName = 'China '+strSchoolName+' ' +'Sales Consultant';
             List<UserRole> userRoles = [select Id,Name from UserRole where Name=:strTempRoleName];
             SchoolRoleId = userRoles[0].Id;
        }
        if(SchoolRoleId != '')
        {
            List<User> users = [select Id,Alias,Name,FirstName,LastName from User where UserRoleId=:SchoolRoleId and IsActive=true limit 100];
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
    
    public List<SelectOption> getStageList() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('*','All Stage')); 
        options.add(new SelectOption('Set Appt','Set Appt')); 
        options.add(new SelectOption('Showed Up - Followup','Showed Up - Followup')); 
        options.add(new SelectOption('Appt No Show - Rescheduled','Appt No Show - Rescheduled')); 
        options.add(new SelectOption('Appt No Show - Call Later','Appt No Show - Call Later')); 
        options.add(new SelectOption('Payment Pending','Payment Pending')); 
        options.add(new SelectOption('Closed Won','Closed Won')); 
        options.add(new SelectOption('Close/Lost -Show-Up','Close/Lost -Show-Up')); 
        options.add(new SelectOption('Close/Lost - No Show','Close/Lost - No Show')); 
        options.add(new SelectOption('Refunded','Refunded'));  
        return options;
    }
    
    public List<SelectOption> getSchoolList(){
        List<SelectOption> options = new List<SelectOption>();
        String strAdminProfileId = '00e40000000j8qL';//00540000001MuFS - tech // 00e40000000j8qL
        if(UserInfo.getProfileId().substring(0,15) == strAdminProfileId)
        {
            blSchoolReadOnly = false;
            options.add(new SelectOption('','---please select a school---'));
            List<UserRole> roles = [select Id, Name from UserRole where Name like 'China ______ Sales Consultant' order by Name];
            if(roles.size() > 0)
            {
                for(UserRole role : roles)
                {
                    String schoolValue = role.Name.subString(6, 12);
                    String schoolName = schoolValue.replace('_', ' ');
                    options.add(new SelectOption(schoolValue, schoolName));
                }
            }
        } 
        else
        {
            blSchoolReadOnly = true;
            options.add(new SelectOption(strSchoolName,strSchoolName.replace('_',' ')));
        }
        return options;
    }
    public PageReference DoAction()
    {
        PageReference toPage = null;
        OwnerReassignUtility ownerUtility = new OwnerReassignUtility();
        Integer intProcessCount = ownerUtility.UserBatchCount();
        Integer currentProcessCount = ownerUtility.getCurrentUserBatchCount();
        if(intProcessCount >4)
        {
            toPage = new PageReference('/apex/BatchExceedLimit');
            toPage.setRedirect(true);
            return toPage;
        }
        if(currentProcessCount > 0)
        {
            toPage = new PageReference('/apex/BatchExceedLimit?type=0');
            toPage.setRedirect(true);
            return toPage;
        }
        String strUserEmail = '';
        List<User> users = [select email from User where Id=:UserInfo.getUserId()];
        if(users != null)
        {
            strUserEmail = users[0].email;
        }   
        QueryReassignmentData reassign = new QueryReassignmentData();
        reassign.query='';
        reassign.email = strUserEmail;
        reassign.replyEmail = 'salesforce@ef.com';
        reassign.ownerId = ownerName;
        reassign.schoolRoleId =  SchoolRoleId;//psq School Manager
        reassign.stageName = stageName;
        reassign.strOperatorId = UserInfo.getUserId();
        
        reassign.initialApptDateOpType = initialApptDateOpType1;
        reassign.lastModifiedDateOpType =  lastModifiedDateOpType1;
        reassign.initialApptDate = initialApptDate1;
        reassign.lastModifiedDate = lastModifiedDate1;
        
        reassign.sinitialApptDateOpType = initialApptDateOpType2;
        reassign.slastModifiedDateOpType = lastModifiedDateOpType2;
        reassign.sinitialApptDate = initialApptDate2;
        reassign.slastModifiedDate = lastModifiedDate2;
        
        try
        {
            ID batchprocessid = Database.executeBatch(reassign);
            
            toPage = new PageReference('/apex/BatchProcessSubmit');
            toPage.setRedirect(true);
            return toPage;
        }
        catch(System.DMLException e)
        {
            ApexPages.addMessages(e);
        }
        return toPage;  
    }
        
    static TestMethod void MassTransfer_FromController_test()
    {
        //Test for Mass Transfer Tool Controller
        //Mass Transfer from Page
        //Profile profile = [SELECT Id FROM Profile WHERE Id = '00e40000000j2k8' LIMIT 1]; 
        User u = [SELECT Id FROM User WHERE ProfileId = '00e40000000j2k8' AND IsActive = true LIMIT 1];
        System.runAS(u) 
        {   
            Test.setCurrentPageReference(new Pagereference('Page.MassTransfer_FromPage'));    
            MassTransfer_FromController tranFrom = new MassTransfer_FromController();
        }
        MassTransfer_FromController tranFrom = new MassTransfer_FromController();
        tranFrom.getSchoolReadOnly(); 
        tranFrom.getUserProfileId();
        tranFrom.getSchoolName();
        tranFrom.setSchoolName('SH_PSQ');
        tranFrom.getLastModifiedDate1();
        tranFrom.setLastModifiedDate1('09/08/2009');
        tranFrom.getInitialApptDate1();
        tranFrom.setInitialApptDate1('09/08/2009');
        tranFrom.getLastModifiedDate2();
        tranFrom.setLastModifiedDate2('09/09/2009');
        tranFrom.getInitialApptDate2();
        tranFrom.setInitialApptDate2('09/09/2009');
        tranFrom.getInitialApptDateOpType1();
        tranFrom.setInitialApptDateOpType1('>');
        tranFrom.getLastModifiedDateOpType1();
        tranFrom.setLastModifiedDateOpType1('>');
        tranFrom.getInitialApptDateOpType2();
        tranFrom.setInitialApptDateOpType2('<');
        tranFrom.getLastModifiedDateOpType2();
        tranFrom.setLastModifiedDateOpType2('<');
        tranFrom.getAccOwner();
        tranFrom.setAccOwner('123');
        tranFrom.getAccStage();
        tranFrom.setAccStage('Set Appt');
        tranFrom.setOwnerOpType('=');
        tranFrom.getOwnerOpType();
        tranFrom.setStageOpType('=');
        tranFrom.getStageOpType();
        //tranFrom.getOwnerList();
        tranFrom.getStageList();
        tranFrom.getSchoolList();
        PageReference pr = tranFrom.DoAction();
        System.assert(true, pr.getURL().toLowerCase().contains('salesforce'));
    }
}