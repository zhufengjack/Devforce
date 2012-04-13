//Generated by wsdl2apex

public class EtownServiceDataContract {
    public class ActivateParams {
        public String DivisionCode;
        public String EliteCode;
        public String FreeRedemptionCode;
        public Integer FreeRedemptionQty;
        public Integer LevelQty;
        public String MainRedemptionCode;
        public Integer MainRedemptionQty;
        public Integer Member_id;
        public Integer Product_id;
        public String StartLevel;
        private String[] DivisionCode_type_info = new String[]{'DivisionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] EliteCode_type_info = new String[]{'EliteCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] FreeRedemptionCode_type_info = new String[]{'FreeRedemptionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] FreeRedemptionQty_type_info = new String[]{'FreeRedemptionQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] LevelQty_type_info = new String[]{'LevelQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] MainRedemptionCode_type_info = new String[]{'MainRedemptionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] MainRedemptionQty_type_info = new String[]{'MainRedemptionQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Product_id_type_info = new String[]{'Product_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] StartLevel_type_info = new String[]{'StartLevel','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'DivisionCode','EliteCode','FreeRedemptionCode','FreeRedemptionQty','LevelQty','MainRedemptionCode','MainRedemptionQty','Member_id','Product_id','StartLevel'};
    }
    public class MemberInfoResult {
        public String CurrentCenter;
        public String CurrentLevel;
        public String CurrentStatus;
        public String EMail;
        public String ErrorMessage;
        public String FirstName;
        public String LastName;
        public String LocalName;
        public Integer MemberId;
        public Boolean Success;
        public String Telephone;
        private String[] CurrentCenter_type_info = new String[]{'CurrentCenter','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CurrentLevel_type_info = new String[]{'CurrentLevel','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CurrentStatus_type_info = new String[]{'CurrentStatus','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] EMail_type_info = new String[]{'EMail','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] FirstName_type_info = new String[]{'FirstName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] LastName_type_info = new String[]{'LastName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] LocalName_type_info = new String[]{'LocalName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] MemberId_type_info = new String[]{'MemberId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Success_type_info = new String[]{'Success','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] Telephone_type_info = new String[]{'Telephone','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CurrentCenter','CurrentLevel','CurrentStatus','EMail','ErrorMessage','FirstName','LastName','LocalName','MemberId','Success','Telephone'};
    }
    public class ArrayOfLevelAccountInfo_CourseLevel {
        public EtownServiceDataContract.LevelAccountInfo_CourseLevel[] LevelAccountInfo_CourseLevel;
        private String[] LevelAccountInfo_CourseLevel_type_info = new String[]{'LevelAccountInfo.CourseLevel','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','LevelAccountInfo.CourseLevel','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'LevelAccountInfo_CourseLevel'};
    }
    public class RescheduleInfo {
        public DateTime OperateDate;
        public String OperateType;
        public Integer Operate_id;
        private String[] OperateDate_type_info = new String[]{'OperateDate','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
        private String[] OperateType_type_info = new String[]{'OperateType','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','RescheduleOperateType','0','1','false'};
        private String[] Operate_id_type_info = new String[]{'Operate_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'OperateDate','OperateType','Operate_id'};
    }
    public class CrossCenterBookingParams {
        public EtownServiceDataContract.ArrayOfCrossCenterBookingInfo info;
        private String[] info_type_info = new String[]{'info','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','ArrayOfCrossCenterBookingInfo','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'info'};
    }
    public class CreateAccountResult {
        public String ErrorCode;
        public String ErrorMessage;
        public Integer MemberId;
        public Long OrderId;
        public Boolean Success;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] MemberId_type_info = new String[]{'MemberId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] OrderId_type_info = new String[]{'OrderId','http://www.w3.org/2001/XMLSchema','long','0','1','false'};
        private String[] Success_type_info = new String[]{'Success','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorMessage','MemberId','OrderId','Success'};
    }
    public class ExternalAppInfo {
        public String ExternalAppCode;
        public String ExternalUserId;
        private String[] ExternalAppCode_type_info = new String[]{'ExternalAppCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ExternalUserId_type_info = new String[]{'ExternalUserId','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ExternalAppCode','ExternalUserId'};
    }
    public class TerminateProductParam {
        public String CommerceProduct;
        public EtownServiceDataContract.CrossCenterBookingParams CrossCenterBookingParam;
        public Integer MemberID;
        public String Salesforce_id;
        public String SchoolName;
        private String[] CommerceProduct_type_info = new String[]{'CommerceProduct','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','CommerceProduct','0','1','false'};
        private String[] CrossCenterBookingParam_type_info = new String[]{'CrossCenterBookingParam','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','CrossCenterBookingParams','0','1','true'};
        private String[] MemberID_type_info = new String[]{'MemberID','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Salesforce_id_type_info = new String[]{'Salesforce_id','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] SchoolName_type_info = new String[]{'SchoolName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CommerceProduct','CrossCenterBookingParam','MemberID','Salesforce_id','SchoolName'};
    }
    public class LoadStudentResult {
        public String ErrorCode;
        public String ErrorMessage;
        public Boolean IsSuccess;
        public EtownServiceDataContract.MemberInfo MemberInfo;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] MemberInfo_type_info = new String[]{'MemberInfo','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','MemberInfo','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorMessage','IsSuccess','MemberInfo'};
    }
    public class LevelAccountInfo {
        public EtownServiceDataContract.ArrayOfLevelAccountInfo_CourseLevel CourseLevelList;
        public String DivisionCode;
        public String EliteCode;
        public String FreeRedemptionCode;
        public Integer FreeRedemptionQty;
        public Boolean Inherited;
        public Integer LevelQty;
        public String MainRedemptionCode;
        public Integer MainRedemptionQty;
        public Integer MemberID;
        public Integer OfflinePackageId;
        public String StartLevel;
        private String[] CourseLevelList_type_info = new String[]{'CourseLevelList','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','ArrayOfLevelAccountInfo.CourseLevel','0','1','true'};
        private String[] DivisionCode_type_info = new String[]{'DivisionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] EliteCode_type_info = new String[]{'EliteCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] FreeRedemptionCode_type_info = new String[]{'FreeRedemptionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] FreeRedemptionQty_type_info = new String[]{'FreeRedemptionQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Inherited_type_info = new String[]{'Inherited','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] LevelQty_type_info = new String[]{'LevelQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] MainRedemptionCode_type_info = new String[]{'MainRedemptionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] MainRedemptionQty_type_info = new String[]{'MainRedemptionQty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] MemberID_type_info = new String[]{'MemberID','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] OfflinePackageId_type_info = new String[]{'OfflinePackageId','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] StartLevel_type_info = new String[]{'StartLevel','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CourseLevelList','DivisionCode','EliteCode','FreeRedemptionCode','FreeRedemptionQty','Inherited','LevelQty','MainRedemptionCode','MainRedemptionQty','MemberID','OfflinePackageId','StartLevel'};
    }
    public class MemberInfo {
        public String CurrentLevel;
        public String CurrentSchool;
        public String Email;
        public Integer Member_id;
        public String MobilePhone;
        public EtownServiceDataContract.ArrayOfRescheduleInfo RescheduleList;
        public String Status;
        private String[] CurrentLevel_type_info = new String[]{'CurrentLevel','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CurrentSchool_type_info = new String[]{'CurrentSchool','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Email_type_info = new String[]{'Email','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] MobilePhone_type_info = new String[]{'MobilePhone','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] RescheduleList_type_info = new String[]{'RescheduleList','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','ArrayOfRescheduleInfo','0','1','true'};
        private String[] Status_type_info = new String[]{'Status','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','ContactStatus','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CurrentLevel','CurrentSchool','Member_id','RescheduleList','Status'};
    }
    public class ArrayOfCrossCenterBookingInfo {
        public EtownServiceDataContract.CrossCenterBookingInfo[] CrossCenterBookingInfo;
        private String[] CrossCenterBookingInfo_type_info = new String[]{'CrossCenterBookingInfo','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','CrossCenterBookingInfo','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CrossCenterBookingInfo'};
    }
    public class SellProductToStudentResult {
        public String ErrorCode;
        public String ErrorMessage;
        public Boolean Success;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Success_type_info = new String[]{'Success','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorMessage','Success'};
    }
    public class LoadStudentParams {
        public Boolean RequireSyncReschedule;
        public String Username;
        private String[] RequireSyncReschedule_type_info = new String[]{'RequireSyncReschedule','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] Username_type_info = new String[]{'Username','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'RequireSyncReschedule','Username'};
    }
    public class ActivateResult {
        public String ErrorCode;
        public String ErrorMessage;
        public Boolean IsSuccess;
        public DateTime OrderEndDate;
        public DateTime OrderStartDate;
        public Long Order_id;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] IsSuccess_type_info = new String[]{'IsSuccess','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] OrderEndDate_type_info = new String[]{'OrderEndDate','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
        private String[] OrderStartDate_type_info = new String[]{'OrderStartDate','http://www.w3.org/2001/XMLSchema','dateTime','0','1','false'};
        private String[] Order_id_type_info = new String[]{'Order_id','http://www.w3.org/2001/XMLSchema','long','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorMessage','IsSuccess','OrderEndDate','OrderStartDate','Order_id'};
    }
    public class SellProductToStudentParam {
        public String CommerceProduct;
        public EtownServiceDataContract.CrossCenterBookingParams CrossCenterBookingParam;
        public Integer MemberID;
        public Integer Qty;
        public String Salesforce_id;
        public String SchoolName;
        private String[] CommerceProduct_type_info = new String[]{'CommerceProduct','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','CommerceProduct','0','1','false'};
        private String[] CrossCenterBookingParam_type_info = new String[]{'CrossCenterBookingParam','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','CrossCenterBookingParams','0','1','true'};
        private String[] MemberID_type_info = new String[]{'MemberID','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Qty_type_info = new String[]{'Qty','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Salesforce_id_type_info = new String[]{'Salesforce_id','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] SchoolName_type_info = new String[]{'SchoolName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CommerceProduct','CrossCenterBookingParam','MemberID','Qty','Salesforce_id','SchoolName'};
    }
    public class CrossCenterBookingInfo {
        public Integer City_id;
        public Integer Duration;
        public String SchoolCode;
        private String[] City_id_type_info = new String[]{'City_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] Duration_type_info = new String[]{'Duration','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] SchoolCode_type_info = new String[]{'SchoolCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'City_id','Duration','SchoolCode'};
    }
    public class ArrayOfRescheduleInfo {
        public EtownServiceDataContract.RescheduleInfo[] RescheduleInfo;
        private String[] RescheduleInfo_type_info = new String[]{'RescheduleInfo','http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','RescheduleInfo','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'RescheduleInfo'};
    }
    public class LevelAccountInfo_CourseLevel {
        public String CourseTypeCode;
        public String LevelCode;
        private String[] CourseTypeCode_type_info = new String[]{'CourseTypeCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] LevelCode_type_info = new String[]{'LevelCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'CourseTypeCode','LevelCode'};
    }
    public class TerminateProductResult {
        public String ErrorCode;
        public String ErrorMessage;
        public Boolean Success;
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Success_type_info = new String[]{'Success','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://schemas.datacontract.org/2004/07/EFSchools.Englishtown.Oboe.Services.DataContract.SalesForce','true','false'};
        private String[] field_order_type_info = new String[]{'ErrorCode','ErrorMessage','Success'};
    }
}