/**
*	Get Tako Case hisotry info by Etown web service based on student email
*	Pony Ma 2011-12-14 created
*/
public with sharing class TakoCaseHistoryHelper {
	public static List<TakoCaseHistoryInfo> getTakoCaseHistory(String email){		
		List<TakoCaseHistoryInfo> lstTakoCaseHistory=new List<TakoCaseHistoryInfo>(); 
		if(email!=null && email!=''){
			EtownTakoCaseService.CustomBinding_ITakoService stub=new EtownTakoCaseService.CustomBinding_ITakoService();
			stub.endpoint_x=EtownServer__c.getAll().get('TakoCaseHistoryService').URL__c;
			stub.timeout_x=60000;
			
			efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseHistoryInfo result;
			if(!Test.isRunningTest()){
				result=stub.LoadCaseHistory(email);	
			}else{
				//hard-code result data for test method
				result=new efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseHistoryInfo();
				result.CaseHistoryInfo=new List<efschoolsEnglishtownCustomerserviceCl.CaseHistoryInfo>();
				efschoolsEnglishtownCustomerserviceCl.CaseHistoryInfo caseHistoryData=new efschoolsEnglishtownCustomerserviceCl.CaseHistoryInfo();
				caseHistoryData.Case_id=123;
				caseHistoryData.Category='test category';
				caseHistoryData.SubCategory='test sub category';
				result.CaseHistoryInfo.add(caseHistoryData);
			}
									
			if(result!=null && result.CaseHistoryInfo!=null){				
				for(efschoolsEnglishtownCustomerserviceCl.CaseHistoryInfo tc:result.CaseHistoryInfo){
					TakoCaseHistoryInfo takoCase=new TakoCaseHistoryInfo();
					takoCase.CaseId=String.ValueOf(tc.Case_id);
					takoCase.Category=tc.Category;
					takoCase.SubCategory=tc.SubCategory;
					takoCase.Encoding=tc.Encoding;						
					lstTakoCaseHistory.add(takoCase);									
				}
			}
		}
		return lstTakoCaseHistory; 		
	}
	
	public static List<TakoCaseDetailInfo> getTakoCaseEvents(Integer caseId){
		List<TakoCaseDetailInfo> lstTakoCaseDetail=new List<TakoCaseDetailInfo>();		
		if(caseId!=null){			
			EtownTakoCaseService.CustomBinding_ITakoService stub=new EtownTakoCaseService.CustomBinding_ITakoService();
			stub.endpoint_x=EtownServer__c.getAll().get('TakoCaseHistoryService').URL__c;
			stub.timeout_x=60000;
			
			efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseDetailInfo result;
			if(!Test.isRunningTest()){
				result=stub.LoadCaseDetail(caseId);	
			}else{
				//hard-code result data for test method
				result=new efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseDetailInfo();
				result.CaseDetailInfo=new List<efschoolsEnglishtownCustomerserviceCl.CaseDetailInfo>();
				efschoolsEnglishtownCustomerserviceCl.CaseDetailInfo caseDetailData=new efschoolsEnglishtownCustomerserviceCl.CaseDetailInfo();
				caseDetailData.Event_id=1234;
				caseDetailData.Case_id=123;
				caseDetailData.Admin_id=888;
				caseDetailData.From_X='from test person';
				caseDetailData.To='to test person';
				caseDetailData.Category='test category';
				caseDetailData.SubCategory='test sub category';
				result.CaseDetailInfo.add(caseDetailData);  	
			}
			 
			
			if(result!=null && result.CaseDetailInfo!=null){
				for(efschoolsEnglishtownCustomerserviceCl.CaseDetailInfo cd:result.CaseDetailInfo){					
					TakoCaseDetailInfo takoCaseDetail=new TakoCaseDetailInfo();
					takoCaseDetail.CaseId=String.valueOf(cd.Case_id);
					takoCaseDetail.EventId=String.valueOf(cd.Event_id);
					takoCaseDetail.AdminId=String.valueOf(cd.Admin_id);
					takoCaseDetail.CreatedBy=cd.From_x;
					takoCaseDetail.CreatedDate=String.valueOf(cd.CreateDate);
					takoCaseDetail.SentTo=cd.To;
					takoCaseDetail.Comment=cd.Comments;	
					takoCaseDetail.PlainTextComment=takoCaseDetail.Comment;
					
					//looks like we don't have rich text formats from Tako case history
					//takoCaseDetail.PlainTextComment=TakoCaseEmailHandler.convertHtmlToText(takoCaseDetail.Comment);
					//don't want to display too long comment content in table
					if(takoCaseDetail.PlainTextComment!=null && takoCaseDetail.PlainTextComment.length()>130){
						takoCaseDetail.PlainTextComment=takoCaseDetail.PlainTextComment.substring(0,130) + '...';
					}
					
					//convert line breaks					
					takoCaseDetail.Comment=takoCaseDetail.Comment.replace('\n','<br/>');					
					
					takoCaseDetail.Attachments=new List<TakoCaseAttachmentInfo>();
					efschoolsEnglishtownCustomerserviceCl.ArrayOfAttachmentDetailInfo attachmentDetails=cd.AttachmentList;					
					if(attachmentDetails!=null && attachmentDetails.AttachmentDetailInfo!=null){						
						for(efschoolsEnglishtownCustomerserviceCl.AttachmentDetailInfo ad:attachmentDetails.AttachmentDetailInfo){
							TakoCaseAttachmentInfo takoCaseAttachDetail=new TakoCaseAttachmentInfo();
							takoCaseAttachDetail.AttachmentId=String.valueOf(ad.Attachment_id);
							takoCaseAttachDetail.AttachmentLabel=ad.Label;
							takoCaseAttachDetail.MIMEType=ad.MimeType;
							takoCaseAttachDetail.FileUrl=ad.FileUrl;							
							takoCaseDetail.Attachments.add(takoCaseAttachDetail); 		
						}
					}					
					lstTakoCaseDetail.add(TakoCaseDetail);					
				}				
			}		
		}
		return lstTakoCaseDetail;
	}
	
	public class TakoCaseHistoryInfo{
		public String CaseId{get;set;}
		public String Category{get;set;}
		public String SubCategory{get;set;}
		public String Encoding{get;set;}		
	}
	
	public class TakoCaseDetailInfo{
		public String CaseId{get;set;}
		public String EventId{get;set;}
		public String AdminId{get;set;}		
		public String CreatedDate{get;set;}
		public String CreatedBy{get;set;}
		public String SentTo{get;set;}
		public String PlainTextComment{get;set;}
		public String Comment{get;set;}		
		public List<TakoCaseAttachmentInfo> Attachments{get;set;}
	}
	
	public class TakoCaseAttachmentInfo{
		public String AttachmentId{get;set;}
		public String AttachmentLabel{get;set;}
		public String MIMEType{get;set;}
		public String FileUrl{get;set;}
	}	
}