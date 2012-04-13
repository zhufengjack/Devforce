/**
*	controller class for Tako Case History page
*	Pony Ma 2011-12-14 created
*/
public with sharing class TakoCaseHistoryController {
	private List<TakoCaseHistoryHelper.TakoCaseHistoryInfo> g_lstTakoCaseHistory=new List<TakoCaseHistoryHelper.TakoCaseHistoryInfo>();	
	private String g_contactId=null;
	private String g_contactEmail=null;
	private Integer g_pageIndex=0;
	private Integer g_recordsPerPage=5;	
	private String g_takoCaseMessage='';
	private String g_takoCaseMessageSeverity='info';
	private Boolean g_showAll=false;
		
	public TakoCaseHistoryController(ApexPages.StandardController std){												
		//page embedded in Conatct			
		if(std!=null && std.getRecord() instanceof Contact && std.getId()!=null){											
			g_contactId=std.getId();							
		}else{									
			g_contactId=ApexPages.currentPage().getParameters().get('contactId');			
		}
		
		//display all cases in page		
		String showAll=ApexPages.currentPage().getParameters().get('showAll');		
		if(showAll=='1'){
			g_showAll=true;
		}
		
		if(g_contactId!=null){
			List<Contact> lstCon=[select RecordType.DeveloperName,Email from Contact where Id=:g_contactId];
			if(lstCon.size()>0){
				g_contactEmail=lstCon[0].Email;
				String recordTypeDPName=lstCon[0].RecordType.DeveloperName;
				//auto load tako case history for Etown student contact or showAll link is clicked
				if(recordTypeDPName=='ETown_User_Contact_record_type' || g_showAll){
					loadTakoCaseHistory(g_contactEmail);	
				}else{
					g_takoCaseMessageSeverity='info';
					g_takoCaseMessage='Tako case history is not loaded yet ,please click \'Load Tako Case History\' button to load the data.';						
				}
			}			
		}							   				
	}
	
	public List<TakoCaseHistoryHelper.TakoCaseHistoryInfo> getTakoCases(){	
		if(!g_showAll){
			List<TakoCaseHistoryHelper.TakoCaseHistoryInfo> lstTakoCaseHistory=new List<TakoCaseHistoryHelper.TakoCaseHistoryInfo>(); 		
			for(Integer i=g_pageIndex*g_recordsPerPage;i<(g_pageIndex+1)*g_recordsPerPage && i<g_lstTakoCaseHistory.size();i++){
				lstTakoCaseHistory.add(g_lstTakoCaseHistory[i]);		
			}
			return lstTakoCaseHistory; 
		}	
		return g_lstTakoCaseHistory;
	}
	
	public String getTakoCaseMessage(){
		return g_takoCaseMessage;
	}
	
	public String getTakoCaseMessageSeverity(){
		return g_takoCaseMessageSeverity;	
	}
	
	public String getContactId(){
		return g_contactId;	
	}
	
	public void loadTakoCases(){
		loadTakoCaseHistory(g_contactEmail);		
	}
	
	public void prev(){
		if(g_pageIndex>0) g_pageIndex--;
	}
	
	public void next(){
		if((g_pageIndex+1)*g_recordsPerPage<g_lstTakoCaseHistory.size()) g_pageIndex++;
	}
	
	public Boolean getIsFirstPage(){
		return g_pageIndex==0;
	}
	
	public Boolean getIsLastPage(){
		return (g_pageIndex+1)*g_recordsPerPage>=g_lstTakoCaseHistory.size();
	}	
	
	private void loadTakoCaseHistory(String contactEmail){
		try{				
			if(contactEmail!=null){				
				g_lstTakoCaseHistory=TakoCaseHistoryHelper.getTakoCaseHistory(contactEmail);				
			}			
			if(g_lstTakoCaseHistory.size()==0){
				g_takoCaseMessageSeverity='info';
				g_takoCaseMessage='No Tako case history to display.';	
			}			
		}catch(Exception ex){
			//handle read time out exception
			system.debug(ex.getMessage());
			if(ex.getMessage().contains('Read timed out')){
				g_takoCaseMessageSeverity='warning';
				g_takoCaseMessage='Etown Tako case service does not response for the moment, Please try later.';	
			}else{//other call out exception					
				g_takoCaseMessageSeverity='error';
				g_takoCaseMessage='Etown Tako case service is not available now, please contact IT support or try later.';
			}					
		}		
	}
	
	@isTest	
	static void test(){
		Contact c=new Contact();
		c.FirstName='test firstname';
		c.LastName='test lastname';
		c.Email='test@abc.com';
		insert c;
		
		ApexPages.StandardController std=new ApexPages.StandardController(c);		
		TakoCaseHistoryController stub=new TakoCaseHistoryController(std);
				
		stub.getTakoCases();
		stub.getContactId();		
		stub.getIsFirstPage();
		stub.getIsLastPage();
		stub.getTakoCaseMessage();
		stub.getTakoCaseMessageSeverity();
		stub.next();
		stub.prev();
					
		ApexPages.currentPage().getParameters().put('email','test@abc.com');
		ApexPages.currentPage().getParameters().put('showAll','1');
		std=null;	
		stub=new TakoCaseHistoryController(std);
		
		stub.getTakoCases();
		stub.getContactId();
		stub.getIsFirstPage();
		stub.getIsLastPage();
		stub.getTakoCaseMessage();
		stub.getTakoCaseMessageSeverity();
		stub.next();
		stub.prev();			
	}
}