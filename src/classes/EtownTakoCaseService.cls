//Generated by wsdl2apex

public class EtownTakoCaseService {
    public class LoadCaseHistory_element {
        public String email;
        private String[] email_type_info = new String[]{'email','http://www.w3.org/2001/XMLSchema','string','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'email'};
    }
    public class LoadCaseDetailResponse_element {
        public efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseDetailInfo LoadCaseDetailResult;
        private String[] LoadCaseDetailResult_type_info = new String[]{'LoadCaseDetailResult','EFSchools.Englishtown.CustomerService.Client','ArrayOfCaseDetailInfo','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'LoadCaseDetailResult'};
    }
    public class LoadCaseDetail_element {
        public Integer case_id;
        private String[] case_id_type_info = new String[]{'case_id','http://www.w3.org/2001/XMLSchema','int','0','1','false'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'case_id'};
    }
    public class LoadCaseHistoryResponse_element {
        public efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseHistoryInfo LoadCaseHistoryResult;
        private String[] LoadCaseHistoryResult_type_info = new String[]{'LoadCaseHistoryResult','EFSchools.Englishtown.CustomerService.Client','ArrayOfCaseHistoryInfo','0','1','true'};
        private String[] apex_schema_type_info = new String[]{'http://tempuri.org/','true','false'};
        private String[] field_order_type_info = new String[]{'LoadCaseHistoryResult'};
    }
    public class CustomBinding_ITakoService {
        public String endpoint_x = 'http://cns-etuat-3.ef.com/services/customerservice/1.0/TakoService.svc';
        public Map<String,String> inputHttpHeaders_x;
        public Map<String,String> outputHttpHeaders_x;
        public String clientCertName_x;
        public String clientCert_x;
        public String clientCertPasswd_x;
        public Integer timeout_x;
        private String[] ns_map_type_info = new String[]{'http://schemas.microsoft.com/2003/10/Serialization/', 'schemasMicrosoftCom200310Serializat', 'EFSchools.Englishtown.CustomerService.Client', 'efschoolsEnglishtownCustomerserviceCl', 'http://tempuri.org/', 'EtownTakoCaseService'};
        public efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseDetailInfo LoadCaseDetail(Integer case_id) {
            EtownTakoCaseService.LoadCaseDetail_element request_x = new EtownTakoCaseService.LoadCaseDetail_element();
            EtownTakoCaseService.LoadCaseDetailResponse_element response_x;
            request_x.case_id = case_id;
            Map<String, EtownTakoCaseService.LoadCaseDetailResponse_element> response_map_x = new Map<String, EtownTakoCaseService.LoadCaseDetailResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/ITakoService/LoadCaseDetail',
              'http://tempuri.org/',
              'LoadCaseDetail',
              'http://tempuri.org/',
              'LoadCaseDetailResponse',
              'EtownTakoCaseService.LoadCaseDetailResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.LoadCaseDetailResult;
        }
        public efschoolsEnglishtownCustomerserviceCl.ArrayOfCaseHistoryInfo LoadCaseHistory(String email) {
            EtownTakoCaseService.LoadCaseHistory_element request_x = new EtownTakoCaseService.LoadCaseHistory_element();
            EtownTakoCaseService.LoadCaseHistoryResponse_element response_x;
            request_x.email = email;
            Map<String, EtownTakoCaseService.LoadCaseHistoryResponse_element> response_map_x = new Map<String, EtownTakoCaseService.LoadCaseHistoryResponse_element>();
            response_map_x.put('response_x', response_x);
            WebServiceCallout.invoke(
              this,
              request_x,
              response_map_x,
              new String[]{endpoint_x,
              'http://tempuri.org/ITakoService/LoadCaseHistory',
              'http://tempuri.org/',
              'LoadCaseHistory',
              'http://tempuri.org/',
              'LoadCaseHistoryResponse',
              'EtownTakoCaseService.LoadCaseHistoryResponse_element'}
            );
            response_x = response_map_x.get('response_x');
            return response_x.LoadCaseHistoryResult;
        }
    }
}