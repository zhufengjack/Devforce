/*
 * EtownMemberInfo webservice function
 */
public class EtownMemberInfoServiceHelper 
{
    private static EtownMemberInfoServiceStub.BasicHttpBinding_ISalesforceService stub;
    private static final String ServiceUsername = 'SFService';
    private static final String ServicePassword = '12@c03f@3t0wn';
    
    public static FullMemberInfo getMemberInfoByIdFromEtown(Decimal memberId)
    {
    	if(!Test.isRunningTest())
    	{
	        if(stub == null)
	        {
	            loginEtownService();
	        }
	        if(memberId != null)
	        {
		        Integer memberIntId = memberId.intValue();
		        EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo = stub.GetFullMemberInfoById(memberIntId);
		        if(fullmemberInfo != null)
		    	{
		    		 return new FullMemberInfo(fullMemberInfo);
		    	}
	        }
    	}
    	else
    	{
    		if(memberId != null)
    		{
    			return new FullMemberInfo(fillFullMeberInfoForTesting());
    		}
    	}
        return null;
    }
    
    public static FullMemberInfo getMemberInfoByEmaiFromEtown(String email)
    {
    	if(!Test.isRunningTest())
    	{
	        if(stub == null)
	        {
	            loginEtownService();
	        }
	        if(email != null)
	        {
		        EtownMemberInfoServiceContract.FullMemberInfo fullmemberInfo = stub.GetFullMemberInfoByEmail(email);
		        if(fullmemberInfo != null)
		        {
		        	return new FullMemberInfo(fullmemberInfo);
		        }
	        }
    	}
    	else
    	{
    		if(email != null)
    		{
    			return new FullMemberInfo(fillFullMeberInfoForTesting());
    		}
    	}
        return null;
    }
    
    @future(callout=true)
    public static void markMemberAsSalesforceMember(Decimal memberId)
    {
    	if(!Test.isRunningTest())
    	{
	        if(stub == null)
	        {
	            loginEtownService();
	        }
	        if(memberId != null)
	        {
		        Integer memberIntId = memberId.intValue();
		        stub.MarkMemberAsSalesforceMember(memberIntId);
	        }
    	}
    }
    
    @future(callout=true)
    public static void updateMembersAsync(Set<ID> contactIds)
    {
    	if(contactIds.size() > 0)
    	{   
	        List<EtownMemberInfoServiceContract.MemberInfo> members = new List<EtownMemberInfoServiceContract.MemberInfo>();
	        
	        for (Contact contact : [select
					  Id
	        		, EtownMemberId__c
	        		, FirstName
	        		, LastName
	        		, Email
	        		, Phone
	        		, MobilePhone
	        		, CountryCode__c
	        		, Salutation
	        		, PreferredLanguage__c
	        		, IsSocial__c
	        		, PartnerCode__c
	        		, DivisionCode__c
	        		from Contact where Id IN :contactIds and EtownMemberId__c != null])
	        {
	        	EtownMemberInfoServiceContract.MemberInfo member = new EtownMemberInfoServiceContract.MemberInfo();
	        	member.Member_id = contact.EtownMemberId__c.intValue();
	        	member.FirstName = contact.FirstName;
	        	member.LastName = contact.LastName;
	        	member.Email = contact.Email;
	        	member.Phone = contact.Phone;
	        	member.Mobile = contact.MobilePhone;
	        	member.CountryCode = contact.CountryCode__c;
	        	member.Gender = contact.Salutation == 'Mr.' ? 'M' : (contact.Salutation == 'Ms.' ? 'F' : 'U');
	        	member.LanguageCode = contact.PreferredLanguage__c;
	        	member.IsSocialMember = contact.IsSocial__c;
	        	member.PartnerCode = contact.PartnerCode__c;
	        	member.DivisionCode =contact.DivisionCode__c;
	        	members.add(member);
	        }
	        EtownMemberInfoServiceContract.UpdateMemberParams param = new EtownMemberInfoServiceContract.UpdateMemberParams();
	        EtownMemberInfoServiceContract.ArrayOfMemberInfo memberArray = new EtownMemberInfoServiceContract.ArrayOfMemberInfo();
	        memberArray.MemberInfo = members;
	        param.Members = memberArray;
	        
	        if(stub == null)
	        {
	            loginEtownService();
	        }
	        stub.UpdateMembers(param);
    	}
    }
    
    private static void loginEtownService()
    {
        stub = new EtownMemberInfoServiceStub.BasicHttpBinding_ISalesforceService();
        stub.timeout_x = 120*1000;   //2 minutes
        EtownMemberInfoServiceToken.UsernameToken_element token = new EtownMemberInfoServiceToken.UsernameToken_element();
        token.Username = ServiceUsername;
        token.Password = ServicePassword;
        EtownMemberInfoServiceToken.Security_element security = new EtownMemberInfoServiceToken.Security_element();
        security.UsernameToken = token;
        stub.Security = security;
    } 
    
    public class FullMemberInfo
    {
        public FullMemberInfo(EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo)
        {
            if(fullMemberInfo != null)
            {
                memberInfo = new MemberInfo(fullMemberInfo.MemberInfo);
                corporateInfo = new CorporateInfo(fullMemberInfo.corporateInfo);
                PartnerInfo = new PartnerInfo(fullMemberInfo.partnerInfo);
            }
        }
        
        public MemberInfo memberInfo { get; set; }
        public CorporateInfo corporateInfo { get; set; }
        public PartnerInfo partnerInfo { get; set; }
    }
   
    public class MemberInfo
    {
    	public MemberInfo()
    	{
    	}
    	
        public MemberInfo(EtownMemberInfoServiceContract.MemberInfo memberInfo)
        {
            if(memberInfo != null)
            {
                MemberId = memberInfo.Member_id;
                FirstName = memberInfo.FirstName;
                LastName = memberInfo.LastName;
                Email = memberInfo.Email;
                Mobile = memberInfo.Mobile;
                Phone = memberInfo.Phone;
                CountryCode = memberInfo.CountryCode;
                Gender = memberInfo.Gender;
                LanguageCode = memberInfo.LanguageCode;
                IsSocialMember = memberInfo.IsSocialMember;
                PartnerCode = memberInfo.PartnerCode;
                DivisionCode = memberInfo.DivisionCode;
            }
        }
        
        public Integer MemberId { get; set; }
        public String FirstName { get; set; }
        public String LastName { get; set; }
        public String Email { get; set; }
        public String Phone { get; set; }
        public String Mobile { get; set; }
        public String CountryCode { get; set; }
        public String Gender { get; set; }
        public String LanguageCode { get; set; }
        public Boolean IsSocialMember { get; set; }
        public String PartnerCode { get; set; }
        public String DivisionCode { get; set; }
    }
    
    public class CorporateInfo
    {
    	public CorporateInfo()
    	{    		
    	}
    	
        public CorporateInfo(EtownMemberInfoServiceContract.CorporateInfo corporateInfo)
        {
            if(corporateInfo != null)
            {
                CorporateCode = corporateInfo.CorporateCode;
                CorporateName = corporateInfo.CorporateName;
                DivisionCode = corporateInfo.DivisionCode;
                DivisionName = corporateInfo.DivisionName;
            }
        }
        
        public String CorporateCode { get; set; } 
        public String CorporateName { get; set; }
        public String DivisionCode { get; set; }
        public String DivisionName { get; set; }
    }
    
    public class PartnerInfo
    {
    	public PartnerInfo()
    	{    		
    	}
    	
        public PartnerInfo(EtownMemberInfoServiceContract.PartnerInfo partnerInfo)
        {
            if(partnerInfo != null)
            {
                PartnerCode = partnerInfo.PartnerCode;
                TrackName = partnerInfo.TrackName;
                BusinessUnit = partnerInfo.BusinessUnit;
                ServerName = partnerInfo.ServerName;
                CountryCode = partnerInfo.CountryCode;
            }
        }
        
        public String PartnerCode { get; set; }
        public String TrackName { get; set; }
        public String BusinessUnit { get; set; }
        public String ServerName { get; set; }
        public String CountryCode { get; set; }
    }
    
    private static EtownMemberInfoServiceContract.FullMemberInfo fillFullMeberInfoForTesting()
    {
    	 EtownMemberInfoServiceContract.FullMemberInfo fullMemberInfo = new  EtownMemberInfoServiceContract.FullMemberInfo();
    	 fullMemberInfo.MemberInfo = new EtownMemberInfoServiceContract.MemberInfo();
    	 fullMemberInfo.CorporateInfo = new EtownMemberInfoServiceContract.CorporateInfo();
    	 fullMemberInfo.PartnerInfo = new EtownMemberInfoServiceContract.PartnerInfo();
    	 fullMemberInfo.MemberInfo.CountryCode = 'cc';
    	 fullMemberInfo.MemberInfo.DivisionCode = 'dc';
    	 fullMemberInfo.MemberInfo.Email = 'acme@acme.com';
    	 fullMemberInfo.MemberInfo.FirstName = 'acme';
    	 fullMemberInfo.MemberInfo.Gender = 'M';
    	 fullMemberInfo.MemberInfo.IsSocialMember = true;
    	 fullMemberInfo.MemberInfo.LanguageCode = 'lc';
    	 fullMemberInfo.MemberInfo.LastName = 'acme';
    	 fullMemberInfo.MemberInfo.Member_id = 111222333;
    	 fullMemberInfo.MemberInfo.Mobile = '11112345678';
    	 fullMemberInfo.MemberInfo.PartnerCode = 'pc';
    	 fullMemberInfo.MemberInfo.Phone = '1111234';
    	 fullMemberInfo.CorporateInfo.CorporateCode = 'cc';
    	 fullMemberInfo.CorporateInfo.CorporateName = 'acme';
    	 fullMemberInfo.CorporateInfo.DivisionCode = 'dv';
    	 fullMemberInfo.CorporateInfo.DivisionName = 'acme';
    	 fullMemberInfo.PartnerInfo.BusinessUnit = 'bu';
    	 fullMemberInfo.PartnerInfo.CountryCode = 'cc';
    	 fullMemberInfo.PartnerInfo.ServerName = 'sn';
    	 fullMemberInfo.PartnerInfo.PartnerCode = 'pc';
    	 fullMemberInfo.PartnerInfo.TrackName = 'tn';
    	 return fullMemberInfo;
    }
    
    @isTest
    static void testEtownMemberInfoServiceHelper()
    {
    	EtownMemberInfoServiceHelper.getMemberInfoByEmaiFromEtown('acme@acme.com');
    	EtownMemberInfoServiceHelper.getMemberInfoByIdFromEtown(123123123);
    	EtownMemberInfoServiceHelper.markMemberAsSalesforceMember(123123123);
    	EtownMemberInfoServiceHelper.loginEtownService();
    }
}