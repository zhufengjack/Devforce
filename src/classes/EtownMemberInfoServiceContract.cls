//Generated by wsdl2apex

public class EtownMemberInfoServiceContract {
    public class UpdateMemberParams {
        public EtownMemberInfoServiceContract.ArrayOfMemberInfo Members;
        private String[] Members_type_info = new String[]{'Members','EFSchools.Englishtown.Commerce.Client.Salesforce','ArrayOfMemberInfo','1','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Members'};
    }
    public class ArrayOfMemberInfo {
        public EtownMemberInfoServiceContract.MemberInfo[] MemberInfo;
        private String[] MemberInfo_type_info = new String[]{'MemberInfo','EFSchools.Englishtown.Commerce.Client.Salesforce','MemberInfo','0','-1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'MemberInfo'};
    }
    public class PartnerInfo {
        public String PartnerCode;
        public String TrackName;
        public String BusinessUnit;
        public String ServerName;
        public String CountryCode;
        private String[] PartnerCode_type_info = new String[]{'PartnerCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] TrackName_type_info = new String[]{'TrackName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] BusinessUnit_type_info = new String[]{'BusinessUnit','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ServerName_type_info = new String[]{'ServerName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CountryCode_type_info = new String[]{'CountryCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'PartnerCode','TrackName','BusinessUnit','ServerName','CountryCode'};
    }
    public class CorporateInfo {
        public String CorporateCode;
        public String CorporateName;
        public String DivisionCode;
        public String DivisionName;
        private String[] CorporateCode_type_info = new String[]{'CorporateCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CorporateName_type_info = new String[]{'CorporateName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] DivisionCode_type_info = new String[]{'DivisionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] DivisionName_type_info = new String[]{'DivisionName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'CorporateCode','CorporateName','DivisionCode','DivisionName'};
    }
    public class UpdateMemberResult {
        public Boolean IsSucceed;
        public String ErrorCode;
        public String ErrorMessage;
        private String[] IsSucceed_type_info = new String[]{'IsSucceed','http://www.w3.org/2001/XMLSchema','boolean','1','1','false'};
        private String[] ErrorCode_type_info = new String[]{'ErrorCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] ErrorMessage_type_info = new String[]{'ErrorMessage','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'IsSucceed','ErrorCode','ErrorMessage'};
    }
    public class MemberInfo {
        public Integer Member_id;
        public String FirstName;
        public String LastName;
        public String Email;
        public String Phone;
        public String Mobile;
        public String CountryCode;
        public String Gender;
        public String LanguageCode;
        public Boolean IsSocialMember;
        public String PartnerCode;
        public String DivisionCode;
        private String[] Member_id_type_info = new String[]{'Member_id','http://www.w3.org/2001/XMLSchema','int','1','1','false'};
        private String[] FirstName_type_info = new String[]{'FirstName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] LastName_type_info = new String[]{'LastName','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Email_type_info = new String[]{'Email','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Phone_type_info = new String[]{'Phone','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Mobile_type_info = new String[]{'Mobile','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] CountryCode_type_info = new String[]{'CountryCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] Gender_type_info = new String[]{'Gender','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] LanguageCode_type_info = new String[]{'LanguageCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] IsSocialMember_type_info = new String[]{'IsSocialMember','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] PartnerCode_type_info = new String[]{'PartnerCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] DivisionCode_type_info = new String[]{'DivisionCode','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'Member_id','FirstName','LastName','Email','Phone','Mobile','CountryCode','Gender','LanguageCode','IsSocialMember','PartnerCode','DivisionCode'};
    }
    public class FullMemberInfo {
        public EtownMemberInfoServiceContract.MemberInfo MemberInfo;
        public EtownMemberInfoServiceContract.PartnerInfo PartnerInfo;
        public EtownMemberInfoServiceContract.CorporateInfo CorporateInfo;
        private String[] MemberInfo_type_info = new String[]{'MemberInfo','EFSchools.Englishtown.Commerce.Client.Salesforce','MemberInfo','0','1','true'};
        private String[] PartnerInfo_type_info = new String[]{'PartnerInfo','EFSchools.Englishtown.Commerce.Client.Salesforce','PartnerInfo','0','1','true'};
        private String[] CorporateInfo_type_info = new String[]{'CorporateInfo','EFSchools.Englishtown.Commerce.Client.Salesforce','CorporateInfo','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'EFSchools.Englishtown.Commerce.Client.Salesforce','true','false'};
        private String[] field_order_type_info = new String[]{'MemberInfo','PartnerInfo','CorporateInfo'};
    }
}