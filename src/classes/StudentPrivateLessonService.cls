//Generated by wsdl2apex

public class StudentPrivateLessonService {
    public class SuboutClassResponse_element {
        public efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceResult SuboutClassResult;
        private String[] SuboutClassResult_type_info = new String[]{'SuboutClassResult','EFSchools.Englishtown.TeacherTools.Client.ServiceResults.SalesForce','SuboutClassServiceResult','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'SuboutClassResult'};
    }
    public class BasicHttpBinding_ISalesForceService {
        public String endpoint_x = 'http://lolita.englishtown.com/services/axis/1.0/SalesForceService.svc';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'EFSchools.Englishtown.TeacherTools.Client.ServiceResults', 'efschoolsEnglishtownTeachertoolsClien', 'EFSchools.Englishtown.TeacherTools.Client.ServiceResults.SalesForce', 'efschoolsEnglishtownTeachertoolsClien', 'EFSchools.Englishtown.TeacherTools.Client.ServiceResults.Schedule', 'efschoolsEnglishtownTeachertoolsClien', 'EFSchools.Englishtown.TeacherTools.Client.ServiceParams', 'efschoolsEnglishtownTeachertoolsClien', 'http://tempuri.org/', 'StudentPrivateLessonService', 'http://schemas.microsoft.com/2003/10/Serialization/Arrays', 'schemasMicrosoftCom200310Serializat'};
        public efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceResult SuboutClass(efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceParams suboutParams) {
            StudentPrivateLessonService.SuboutClass_element request_x = new StudentPrivateLessonService.SuboutClass_element();
            StudentPrivateLessonService.SuboutClassResponse_element response_x;
            request_x.suboutParams = suboutParams;
            Map<String, StudentPrivateLessonService.SuboutClassResponse_element> response_map_x = new Map<String, StudentPrivateLessonService.SuboutClassResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/ISalesForceService/SuboutClass',
              'http://tempuri.org/',
              'SuboutClass',
              'http://tempuri.org/',
              'SuboutClassResponse',
              'StudentPrivateLessonService.SuboutClassResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.SuboutClassResult;
        }
        public Boolean AddBookingRefundAudit(efschoolsEnglishtownTeachertoolsClien.BookingRefundAuditParams param) {
            StudentPrivateLessonService.AddBookingRefundAudit_element request_x = new StudentPrivateLessonService.AddBookingRefundAudit_element();
            StudentPrivateLessonService.AddBookingRefundAuditResponse_element response_x;
            request_x.param = param;
            Map<String, StudentPrivateLessonService.AddBookingRefundAuditResponse_element> response_map_x = new Map<String, StudentPrivateLessonService.AddBookingRefundAuditResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/ISalesForceService/AddBookingRefundAudit',
              'http://tempuri.org/',
              'AddBookingRefundAudit',
              'http://tempuri.org/',
              'AddBookingRefundAuditResponse',
              'StudentPrivateLessonService.AddBookingRefundAuditResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.AddBookingRefundAuditResult;
        }
        public efschoolsEnglishtownTeachertoolsClien.LoadClassListServiceResult LoadPLClassList(efschoolsEnglishtownTeachertoolsClien.LoadClassListParam param) {
            StudentPrivateLessonService.LoadPLClassList_element request_x = new StudentPrivateLessonService.LoadPLClassList_element();
            StudentPrivateLessonService.LoadPLClassListResponse_element response_x;
            request_x.param = param;
            Map<String, StudentPrivateLessonService.LoadPLClassListResponse_element> response_map_x = new Map<String, StudentPrivateLessonService.LoadPLClassListResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/ISalesForceService/LoadPLClassList',
              'http://tempuri.org/',
              'LoadPLClassList',
              'http://tempuri.org/',
              'LoadPLClassListResponse',
              'StudentPrivateLessonService.LoadPLClassListResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.LoadPLClassListResult;
        }
    }
    public class SuboutClass_element {
        public efschoolsEnglishtownTeachertoolsClien.SuboutClassServiceParams suboutParams;
        private String[] suboutParams_type_info = new String[]{'suboutParams','EFSchools.Englishtown.TeacherTools.Client.ServiceParams','SuboutClassServiceParams','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'suboutParams'};
    }
    public class LoadPLClassListResponse_element {
        public efschoolsEnglishtownTeachertoolsClien.LoadClassListServiceResult LoadPLClassListResult;
        private String[] LoadPLClassListResult_type_info = new String[]{'LoadPLClassListResult','EFSchools.Englishtown.TeacherTools.Client.ServiceResults','LoadClassListServiceResult','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'LoadPLClassListResult'};
    }
    public class LoadPLClassList_element {
        public efschoolsEnglishtownTeachertoolsClien.LoadClassListParam param;
        private String[] param_type_info = new String[]{'param','EFSchools.Englishtown.TeacherTools.Client.ServiceParams','LoadClassListParam','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'param'};
    }
    public class AddBookingRefundAudit_element {
        public efschoolsEnglishtownTeachertoolsClien.BookingRefundAuditParams param;
        private String[] param_type_info = new String[]{'param','EFSchools.Englishtown.TeacherTools.Client.ServiceParams','BookingRefundAuditParams','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'param'};
    }
    public class AddBookingRefundAuditResponse_element {
        public Boolean AddBookingRefundAuditResult;
        private String[] AddBookingRefundAuditResult_type_info = new String[]{'AddBookingRefundAuditResult','http://www.w3.org/2001/XMLSchema','boolean','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'AddBookingRefundAuditResult'};
    }
}