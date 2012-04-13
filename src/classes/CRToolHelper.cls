public with sharing class CRToolHelper {
	
	public static List<LessonData> searchLesson(LessonSearchParam searchParam){
		
		efschoolsEnglishtownTeachertoolsClien.LoadClassListParam param=new efschoolsEnglishtownTeachertoolsClien.LoadClassListParam();						
		
		Integer classId=null;
		if(searchParam.ClassId!=null){
			try{
				classId=Integer.valueOf(searchParam.ClassId);
				param.ClassId=classId;
			}catch(Exception e){}
		}			
						
		param.SearchType=searchParam.SearchType;
		param.StartTime=searchParam.StartTime;
		param.EndTime=searchParam.EndTime;
		
		if(searchParam.UserName!=null && searchParam.UserName!=''){
			param.UserName=searchParam.UserName;
		}
		//param.ClassId=classId;
		if(searchParam.StudentEmail!=null && searchParam.StudentEmail!=''){
			param.StudentEmail=searchParam.StudentEmail;
		}
		
		if(searchParam.TeacherName!=null && searchParam.TeacherName!=''){
			param.TeacherUserName=searchParam.TeacherName;	
		}
		
		if(searchParam.Topic!=null && searchParam.Topic!=''){
			param.Topic=searchParam.Topic;	
		}
				
		StudentPrivateLessonService.BasicHttpBinding_ISalesForceService stub=new StudentPrivateLessonService.BasicHttpBinding_ISalesForceService();
		stub.endpoint_x='http://210.13.83.21:8090/services/axis/1.0/SalesForceService.svc';
		efschoolsEnglishtownTeachertoolsClien.LoadClassListServiceResult result=stub.LoadPLClassList(param);
		system.debug(result);				
		
		List<LessonData> lstLD=new List<LessonData>();
		try{
		if(result!=null && result.ClassList!=null && result.ClassList.ClassListDetail!=null){
			for(efschoolsEnglishtownTeachertoolsClien.ClassListDetail cd:result.ClassList.ClassListDetail){
				LessonData LD=new LessonData();
				LD.BookedBy=cd.BookedBy;
				LD.BookingId=cd.BookingId;
				LD.CancelDate=String.valueOf(cd.CancelDate);
				LD.CanceledBy=cd.CanceledBy;
				LD.ChargeDate=String.valueOf(cd.ChargeDate);
				LD.ClassId=cd.ClassId;
				LD.ClassStatusCode=cd.ClassStatusCode;
				LD.Company=cd.Company;
				LD.Country=cd.Country;
				LD.Email=cd.Email;
				LD.GrantUsageId=cd.GrantUsageId;
				LD.Name=cd.Name;
				LD.RefundDate=String.valueOf(cd.RefundDate);
				LD.ServiceStubTypeCode=cd.ServiceSubTypeCode;
				LD.StartTime=String.valueOf(cd.StartTime);
				LD.StudentMemberId=cd.StudentMemberId;
				LD.TeacherUserName=cd.TeacherUserName;
				LD.Topic=cd.Topic;
				LD.TopicId=cd.TopicId;
				LD.UserName=cd.UserName;
				
				lstLD.add(LD);				
			}		
		}
		}catch(Exception e){system.debug(e.getMessage());}
		
		system.debug(lstLD.size());
		return lstLD;	
			
		//return null;		
	}
	
	public static Boolean cancelClass(Integer classId,String canceledBy,String cancelReason){
		
		efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceParams param=new efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceParams();
		schemasMicrosoftCom200310Serializat.ArrayOfint classIds=new schemasMicrosoftCom200310Serializat.ArrayOfint();
		classIds.int_x=new Integer[]{classId};
		param.Class_ids=classIds;
		param.CanceledBy=canceledBy;
		param.SuboutReason=cancelReason;
		
		StudentPrivateLessonService.BasicHttpBinding_ISalesForceService stub=new StudentPrivateLessonService.BasicHttpBinding_ISalesForceService();
		stub.endpoint_x='http://210.13.83.21:8090/services/axis/1.0/SalesForceService.svc';
		
		efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceResult wsResult=stub.SuboutClass(param);		
		if(wsResult!=null && wsResult.Result!=null && wsResult.Result.SuboutClassResult!=null && wsResult.Result.SuboutClassResult.size()>0){
			return wsResult.Result.SuboutClassResult[0].Success;	
		}
		
		
		return false;	
		
		//return null;		
	}
	
	public static Boolean refundClass(Integer memberId,Integer bookingId,Integer usageId,String refundBy,String refundReason){
		
		efschoolsEnglishtownTeachertoolsClien.BookingRefundAuditParams param=new efschoolsEnglishtownTeachertoolsClien.BookingRefundAuditParams();
		param.MemberId=memberId;
		param.BookingId=bookingId;
		param.RefundBy=refundBy;
		param.RefundReason=refundReason;
		param.UsageId=usageId;
						
		StudentPrivateLessonService.BasicHttpBinding_ISalesForceService stub=new StudentPrivateLessonService.BasicHttpBinding_ISalesForceService();
		stub.endpoint_x='http://210.13.83.21:8090/services/axis/1.0/SalesForceService.svc';
		
		Boolean isSucceed=stub.AddBookingRefundAudit(param);
				
		return isSucceed;
		
		//return null;				
	}
	
	public class LessonData{
		public String BookedBy{get;set;}
		public Integer BookingId{get;set;}
		public String CancelDate{get;set;}
		public String CanceledBy{get;set;}
		public String ChargeDate{get;set;}
		public Integer ClassId{get;set;}
		public String ClassStatusCode{get;set;}
		public String Company{get;set;}
		public String Country{get;set;}
		public String Email{get;set;}
		public Integer GrantUsageId{get;set;}
		public String Name{get;set;}
		public String RefundDate{get;set;}
		public String ServiceStubTypeCode{get;set;}
		public String StartTime{get;set;}
		public Integer StudentMemberId{get;set;}
		public String TeacherUserName{get;set;}
		public String Topic{get;set;}
		public Integer TopicId{get;set;}
		public String UserName{get;set;}		
	}
	
	public class LessonSearchParam{
		public String ClassId{get;set;}
		public String Country{get;set;}
		public String SearchType{get;set;}
		public DateTime StartTime{get;set;}
		public DateTime EndTime{get;set;}
		public String StudentEmail{get;set;}
		public String TeacherName{get;set;}
		public String Topic{get;set;}
		public String UserName{get;set;}	
	}	
}