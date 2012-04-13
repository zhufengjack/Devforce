/**
*	controller class for Tako Case detail page
*	Pony Ma 2011-12-14 created
*/
public with sharing class TakoCaseDetailController {	
	private List<TakoCaseHistoryHelper.TakoCaseDetailInfo> g_lstTakoCaseDetail=new List<TakoCaseHistoryHelper.TakoCaseDetailInfo>(); 
	private Integer g_takoCaseId=0;
	private TakoCaseHistoryHelper.TakoCaseDetailInfo g_takoCaseDetail=null;
	
	private String g_takoCaseMessage=null;
	private String g_takoCaseMessageSeverity='info';
		
	public TakoCaseDetailController(){
		try{
			String takoCaseId=ApexPages.currentPage().getParameters().get('takoCaseId');
			String eventId=ApexPages.currentPage().getParameters().get('eventId');		
			try{
				if(takoCaseId!=null && takoCaseId!=''){
					g_takoCaseId=Integer.valueOf(takoCaseId);
				}
			}catch(Exception ex){}
			
			g_lstTakoCaseDetail=TakoCaseHistoryHelper.getTakoCaseEvents(g_takoCaseId);
			//even id matched?
			for(TakoCaseHistoryHelper.TakoCaseDetailInfo caseDetail:g_lstTakoCaseDetail){
				if(caseDetail.EventId==eventId){
					g_takoCaseDetail=caseDetail;	
				}	
			}
			//if event id not specified, show first event detail
			if(g_takoCaseDetail==null && g_lstTakoCaseDetail.size()>0) g_takoCaseDetail=g_lstTakoCaseDetail[0];	
			
			if(g_lstTakoCaseDetail.size()==0){
				g_takoCaseMessageSeverity='info';
				g_takoCaseMessage='No Tako case detail to display.';	
			}
			
		}catch(Exception ex){
			if(ex.getMessage().contains('Read timed out')){
				g_takoCaseMessageSeverity='warning';
				g_takoCaseMessage='Etown Tako case service does not response for the moment, Please try later.';
			}else{
				g_takoCaseMessageSeverity='error';
				g_takoCaseMessage='Etown Tako case service is not available now. Please contact IT support or try later.';	
			}							
		}	
	}
	
	public String getTakoCaseId(){
		return String.valueOf(g_takoCaseId);
	}
			
	public List<TakoCaseHistoryHelper.TakoCaseDetailInfo> getTakoCaseDetails(){
		return g_lstTakoCaseDetail; 
	} 
	
	public TakoCaseHistoryHelper.TakoCaseDetailInfo getTakoCaseSelected(){
		return g_takoCaseDetail;
	}	
	
	public String getTakoCaseMessage(){
		return g_takoCaseMessage;
	}
	
	public String getTakoCaseMessageSeverity(){
		return g_takoCaseMessageSeverity;	
	}
	
	@isTest
	static void test(){
		ApexPages.currentPage().getParameters().put('takoCaseId','123');
		ApexPages.currentPage().getParameters().put('eventId','1234');		
		TakoCaseDetailController stub=new TakoCaseDetailController();
		
		stub.getTakoCaseDetails();
		stub.getTakoCaseId();
		stub.getTakoCaseMessage();
		stub.getTakoCaseMessageSeverity();
		stub.getTakoCaseSelected();		
	}
}