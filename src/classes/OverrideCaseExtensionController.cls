public class OverrideCaseExtensionController {

    public EtownCaseInfoService.TechCheck tc {get;set;}
    public EtownCaseInfoService.QuestionWithAnswer qa {get;set;}
    public String msg {get;set;}
    private Case caseInfo;
    
    public OverrideCaseExtensionController(ApexPages.StandardController controller) {
        caseInfo = (Case)controller.getRecord();
        CaseExtensionXmlHelper helper = new CaseExtensionXmlHelper();
        Case c = [select Id,TechCheck__c,QwithA__c from Case where Id = :caseInfo.Id limit 1];
        //c.TechCheck__c = '<?xml version="1.0"?><TechCheck><Refurl><![CDATA[]]></Refurl><Server><![CDATA[]]></Server><Os><![CDATA[]]></Os><Browser><![CDATA[test>]]></Browser><ConnectionSpeed><![CDATA[]]></ConnectionSpeed><Flash><![CDATA[]]></Flash><JVM><![CDATA[]]></JVM><Aol><![CDATA[test]]></Aol><ASR><![CDATA[test<]]></ASR><PageUrl><![CDATA[]]></PageUrl><NumberTimes><![CDATA[]]></NumberTimes><TechnicalErrorTextUrl><![CDATA[jasdkf./asdfk}]]></TechnicalErrorTextUrl><TechCheck><![CDATA[]]></TechCheck></TechCheck>';
        //update c;
        if(c.TechCheck__c != null){
            tc = helper.XmlToTechCheck(c.TechCheck__c);
        }
        if(c.QwithA__c != null){
            qa = helper.XmlToQwithA(c.QwithA__c);
        }
        
    }

}