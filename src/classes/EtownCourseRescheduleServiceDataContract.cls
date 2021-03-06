//Generated by wsdl2apex

public class EtownCourseRescheduleServiceDataContract {
    public class ResumeParams {
        public Integer Member_id;
        public Integer Resume_id;
        public String ReasonCode;
        public Boolean IsResumeNow;
        public DateTime ResumeDate;
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] Resume_id_type_info = new String[]{'Resume_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] ReasonCode_type_info = new String[]{'ReasonCode','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] IsResumeNow_type_info = new String[]{'IsResumeNow','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ResumeDate_type_info = new String[]{'ResumeDate','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Member_id','Resume_id','ReasonCode','IsResumeNow','ResumeDate'};
    }
    public class ResumeResult {
        public Boolean IsSuccess;
        public String ErrorCode;
        public String ErrorMessage;
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'IsSuccess','ErrorCode','ErrorMessage'};
    }
    public class InactivateResult {
        public Boolean IsSuccess;
        public String ErrorCode;
        public String ErrorMessage;
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'IsSuccess','ErrorCode','ErrorMessage'};
    }
    public class SuspendParams {
        public Integer Member_id;
        public DateTime SuspendDate;
        public DateTime ResumeDate;
        public String ReasonCode;
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] SuspendDate_type_info = new String[]{'SuspendDate','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
        private String[] ResumeDate_type_info = new String[]{'ResumeDate','http://www.w3.org/2001/XMLSchema','dateTime','1','1','false'};
        private String[] ReasonCode_type_info = new String[]{'ReasonCode','http://www.w3.org/2001/XMLSchema','string','1','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Member_id','SuspendDate','ResumeDate','ReasonCode'};
    }
    public class CancelSuspendResult {
        public Boolean IsSuccess;
        public String ErrorCode;
        public String ErrorMessage;
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'IsSuccess','ErrorCode','ErrorMessage'};
    }
    public class CancelSuspendParams {
        public Integer Member_id;
        public Integer Suspend_Operate_id;
        public Integer Resume_Operate_id;
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] Suspend_Operate_id_type_info = new String[]{'Suspend_Operate_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] Resume_Operate_id_type_info = new String[]{'Resume_Operate_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Member_id','Suspend_Operate_id','Resume_Operate_id'};
    }
    public class SuspendResult {
        public Boolean IsSuccess;
        public String ErrorCode;
        public String ErrorMessage;
        public Integer Suspend_Operate_id;
        public Integer Resume_Operate_id;
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Suspend_Operate_id_type_info = new String[]{'Suspend_Operate_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] Resume_Operate_id_type_info = new String[]{'Resume_Operate_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'IsSuccess','ErrorCode','ErrorMessage','Suspend_Operate_id','Resume_Operate_id'};
    }
    public class InactivateParams {
        public Integer Member_id;
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Member_id'};
    }
}