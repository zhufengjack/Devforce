public class ManageLessonController {	
	public String LessonType{get;set;}
	public String Email{get;set;}
	public String LessonId{get;set;}
	public String MemberId{get;set;}
	public String Teacher{get;set;}
	public Date LessonDateFrom{get;set;}
	public Date LessonDateTo{get;set;}
	public String Topic{get;set;}
	public String Status{get;set;}
	public DateTime LessonDate{get;set;}
	
	public String ActionReason{get;set;}	
	public String ActionBy{get;set;}
		
	
	public String Action{get;set;}
	public String ClassId{get;set;}
	
	public PageMessage QueryMessage{get;set;}
	public PageMessage ActionMessage{get;set;}
	
	public CRToolHelper.LessonSearchParam SearchParam{get;set;}	
		
	public Contact DateTimeFieldStub{get;set;}
	public Contact DateTimeFieldStub2{get;set;}
	
	//public CRToolHelper.LessonData Lesson{get;set;}
	
	private List<CRToolHelper.LessonData> g_lstLesson=new List<CRToolHelper.LessonData>();
	private CRToolHelper.LessonData g_Lesson=null;
	
	private Integer g_pageIndex=0;
	private Integer g_recordsPerPage=10;	
	
	public ManageLessonController(){
		DateTimeFieldStub=new Contact();
		DateTimeFieldStub2=new Contact();
		
		//CancelReason='Booked wrong time, re-scheduled';
		
		DateTimeFieldStub.EmailBouncedDate=DateTime.valueOf('2011-01-01 00:00:00');
		DateTimeFieldStub2.EmailBouncedDate=DateTime.valueOf('2012-13-01 00:00:00');
		
		SearchParam=new CRToolHelper.LessonSearchParam();	
	}
	
	public List<SelectOption> getLessonTypes(){
		List<SelectOption> lstOption=new List<SelectOption>();
		lstOption.add(new SelectOption('All','--All--'));
		lstOption.add(new SelectOption('Uncancelled','Uncancelled'));
		lstOption.add(new SelectOption('Cancelled','Cancelled'));
		lstOption.add(new SelectOption('Subout','Subout'));
				
		return lstOption;
	}
	
	public void searchLesson(){
		QueryMessage=null;
		ActionMessage=null;
		
		searchParam.StartTime=DateTimeFieldStub.EmailBouncedDate;
		searchParam.EndTime=DateTimeFieldStub2.EmailBouncedDate;		
		try{
			g_pageIndex=0;
			g_lstLesson=CRToolHelper.searchLesson(searchParam);
			
			if(g_lstLesson.size()==0){
				QueryMessage=new PageMessage('No lessons are found, please check the filters.','info');	
			}
		}catch(Exception ex){
			if(ex.getMessage().contains('Read timed out')){
				QueryMessage=new PageMessage('Etown Lesson service does not response for the moment, Please try later.','error');					
			}else{//other call out exception
				QueryMessage=new PageMessage('Etown Lesson service is not available now, please contact IT support or try later.','error');									
			}	
		}	
	}
	
	
	public List<CRToolHelper.LessonData> getLessons(){		
		List<CRToolHelper.LessonData> lstLesson=new List<CRToolHelper.LessonData>(); 		
		for(Integer i=g_pageIndex*g_recordsPerPage;i<(g_pageIndex+1)*g_recordsPerPage && i<g_lstLesson.size();i++){
			lstLesson.add(g_lstLesson[i]);		
		}		
		return lstLesson;
	}
	
	public void prev(){
		if(!getIsFirstPage()) g_pageIndex--;
	}
	
	public void next(){
		if(!getIsLastPage()) g_pageIndex++;
	}
	
	public Boolean getIsFirstPage(){
		return g_pageIndex==0;
	}
	
	public Boolean getIsLastPage(){
		return (g_pageIndex+1)*g_recordsPerPage>=g_lstLesson.size();
	}
	
	public Integer getCurPageIndex(){
		return g_pageIndex+1;
	}
	
	public Integer getTotPageAmount(){	
		Integer pageAmount=g_lstLesson.size()/g_recordsPerPage;	
		return pageAmount*g_recordsPerPage==g_lstLesson.size()?pageAmount:(pageAmount +1);
	}
	
	public void loadLesson(){
		ActionMessage=null;			
		String classId=ApexPages.currentPage().getParameters().get('ClassId');
		Action=ApexPages.currentPage().getParameters().get('Action');		
		for(CRToolHelper.LessonData ld:g_lstLesson){
			if(String.valueOf(ld.ClassId)==classId){
				g_Lesson=ld;				
			}
		}							
	}
	
	public void clearAction(){
		Action=null;
		g_Lesson=null;	
	}
	
	public CRToolHelper.LessonData getLesson(){		
		return g_Lesson;
	}
	
	public List<SelectOption> getCancelReasons(){		
		List<SelectOption> lstOption=new List<SelectOption>();
		lstOption.add(new SelectOption('','--Please select cancel reason--'));
		lstOption.add(new SelectOption('Booked wrong time, re-scheduled','Booked wrong time, re-scheduled'));
		lstOption.add(new SelectOption('I can\'t teach this topic','I can\'t teach this topic'));
		lstOption.add(new SelectOption('Personal Reason','Personal Reason'));
		lstOption.add(new SelectOption('Personal technical issue','Personal technical issue'));
		lstOption.add(new SelectOption('Other','Other'));
		
		return lstOption;
	}
	
	public List<SelectOption> getCanceledBys(){
		List<SelectOption> lstOption=new List<SelectOption>();
		lstOption.add(new SelectOption('','--Please select canceled by--'));
		
		lstOption.add(new SelectOption('Admin','Admin'));
		lstOption.add(new SelectOption('Teacher','Teacher'));
		lstOption.add(new SelectOption('Student','Student'));
		
		return lstOption;	
	}
	
	public List<SelectOption> getRefundReasons(){		
		List<SelectOption> lstOption=new List<SelectOption>();
		lstOption.add(new SelectOption('','--Please select refund reason--'));
		lstOption.add(new SelectOption('Technical problem','Technical problem'));
		lstOption.add(new SelectOption('Personal issue','Personal issue'));
		lstOption.add(new SelectOption('Teacher No Show','Teacher No Show'));
		lstOption.add(new SelectOption('Other','Other'));
		
		return lstOption;
	}
	
	public List<SelectOption> getRefundBys(){
		List<SelectOption> lstOption=new List<SelectOption>();
		lstOption.add(new SelectOption('','--Please select refund by--'));
		
		lstOption.add(new SelectOption('Admin','Admin'));
		lstOption.add(new SelectOption('Teacher','Teacher'));
		lstOption.add(new SelectOption('Student','Student'));
		
		return lstOption;	
	}
	
	public Boolean getIsLessonEmpty(){
		return (g_Lesson==null);
	}
	
	public void cancelLesson(){	
		try{	
			system.debug(g_Lesson);			
			if(g_Lesson!=null && g_Lesson.ClassStatusCode=='Booked'){	
				system.debug(ActionBy);			
				system.debug(ActionReason);				
				//Boolean isSucceed=CRToolHelper.cancelClass(g_Lesson.ClassId,ActionBy,ActionReason);
				Boolean isSucceed=true;
				if(isSucceed){
					g_Lesson.ClassStatusCode='Canceled';
					g_Lesson.TeacherUserName='';
					ActionMessage=new PageMessage('Class ' + g_Lesson.ClassId + ' has been cancelled.','info');	
				}else{
					ActionMessage=new PageMessage('Class ' + g_Lesson.ClassId + ' failed to be cancelled.','error');	
				}
				g_Lesson=null;
			}
		}catch(Exception ex){
			if(ex.getMessage().contains('Read timed out')){
				ActionMessage=new PageMessage('Etown Lesson service does not response for the moment, Please try later.','error');					
			}else{//other call out exception
				ActionMessage=new PageMessage('Etown Lesson service is not available now, please contact IT support or try later.','error');									
			}		
		}
	}
	
	public void refundLesson(){	
		try{	
			system.debug(g_Lesson);
			if(g_Lesson!=null){	
				system.debug(ActionBy);			
				system.debug(ActionReason);
				Boolean isSucceed=CRToolHelper.refundClass(g_Lesson.StudentMemberId,g_Lesson.BookingId,g_Lesson.GrantUsageId,ActionBy,ActionReason);
				system.debug(isSucceed);
				if(isSucceed){					
					ActionMessage=new PageMessage('Class ' + g_Lesson.ClassId + ' has been refunded.','info');
				}else{
					ActionMessage=new PageMessage('Class ' + g_Lesson.ClassId + ' failed to be refunded.','error');	
				}
				g_Lesson=null;
			}
		}catch(Exception ex){
			system.debug(ex.getMessage());
			if(ex.getMessage().contains('Read timed out')){
				ActionMessage=new PageMessage('Etown Lesson service does not response for the moment, Please try later.','error');					
			}else{//other call out exception
				ActionMessage=new PageMessage('Etown Lesson service is not available now, please contact IT support or try later.','error');									
			}	
		}
	}
	
	public class PageMessage{
		public String Summary{get;set;}
		public String Severity{get;set;}
		public PageMessage(String pSummary,String pSeverity){
			Summary=pSummary;
			Severity=pSeverity;
		}		
	}
	
}