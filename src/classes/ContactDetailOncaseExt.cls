/**
*	Extension controller for ContactDetailOnCase page, used to display some contact info on Case detail page in serviceforce.
*	Change Log:
*	Pony Ma	2011-11-17 Created
*/
public with sharing class ContactDetailOncaseExt {
	private Integer gPageIndex=0;	
	private final Integer RECORDS_PER_PAGE=10;
	
	public Contact CaseContact{get;set;}
		
	public Integer getPageIndex(){
		return gPageIndex;
	}
			
	public ContactDetailOnCaseExt(ApexPages.StandardController std){		
		if(std.getRecord() instanceof Case){
			Case c=[select ContactId from case where id=:std.getId()];			
			if(c.ContactId!=null){
				CaseContact=[select Name,Owner.Name,Phone,EtownMemberId__c,CorporateCode__c,PartnerCode__c,DivisionCode__c,MobilePhone,Email,(select CaseNumber,Subject,Owner.Name,Status from Cases) from Contact where Id=:c.ContactId];
			}	
		}	
	}
	
	public List<Case> getContactCases(){
		List<Case> lstCase=new List<Case>();
		if(CaseContact!=null && CaseContact.Cases!=null){				
			for(Integer i=0;i<CaseContact.Cases.size();i++){
				if(i>=gPageIndex*RECORDS_PER_PAGE && i<(gPageIndex+1)*RECORDS_PER_PAGE){
					lstCase.add(CaseContact.Cases[i]);
				}	
			}
		}
		return lstCase;
	}
	
	public Integer getPageCount(){
		Integer pageCount=0;
		if(CaseContact!=null && CaseContact.Cases!=null){
			Integer totalRecordSize=CaseContact.Cases.size();
			pageCount=totalRecordSize/RECORDS_PER_PAGE;
			pageCount=(pageCount*RECORDS_PER_PAGE==totalRecordSize)?pageCount:(pageCount+1);		
		}		
		return pageCount;		
	}
	
	public void prev(){
		if(gPageIndex>0){
			gPageIndex--;
		}		
	}
	
	public void next(){
		if(gPageIndex<getPageCount()-1){
			gPageIndex++;
		}		
	}
	
	public Boolean getIsFirstPage(){
		return gPageIndex==0;
	}
	
	public Boolean getIsLastPage(){
		return gPageIndex==(getPageCount()-1);
	}
	
	@istest
	static void testContactDetailOncaseExt(){
		Contact con=new Contact();
		con.FirstName='testfirstname';
		con.LastName='testlastname';
		insert con;
		Case c=new Case();
		c.Subject='a test case';
		c.ContactId=con.Id;
		insert c;
		
		ApexPages.Standardcontroller sc=new ApexPages.Standardcontroller(c);		
		ContactDetailOncaseExt teststub=new ContactDetailOncaseExt(sc);
		
		List<Case> lstCase=teststub.getContactCases();
		system.assertEquals(lstCase.size(),1);			
		system.assertEquals(teststub.getPageCount(),1);
		
		teststub.prev();
		system.assertEquals(teststub.getPageIndex(),0);
		
		teststub.next();
		system.assertEquals(teststub.getPageIndex(),0);
		
		system.assertEquals(teststub.getIsFirstPage(),true);
		system.assertEquals(teststub.getIsLastPage(),true);			
	}
}