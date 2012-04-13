public class CaseExtensionXmlHelper
{
    public String QwithAToXml(EtownCaseInfoService.QuestionWithAnswer qa)
    {
        XmlStreamWriter w = new XmlStreamWriter();
        w.writeStartDocument(null, '1.0');
        w.writeStartElement(null, 'QwithA', null);
        
        appendElement(w,'SurfingFromHome ',qa.SurfingFromHome );
        appendElement(w,'ErrorMessage ',qa.ErrorMessage );
        appendElement(w,'AccessEVC ',qa.AccessEVC ); 
        appendElement(w,'LevelUnit ',qa.LevelUnit );
        appendElement(w,'LevelUnitPage ',qa.LevelUnitPage);
        appendElement(w,'Teacher ',qa.Teacher );
        
        w.writeEndElement();
        w.writeEndDocument();
        String result = w.getXmlString();
        w.close();
        return  result;
    }
    
    public EtownCaseInfoService.QuestionWithAnswer XmlToQwithA(String xml)
    {
        EtownCaseInfoService.QuestionWithAnswer tc = new EtownCaseInfoService.QuestionWithAnswer();
        xmldom dom = new xmldom(xml);

        tc.SurfingFromHome = getNodeValue(dom, 'SurfingFromHome');
        tc.ErrorMessage = getNodeValue(dom, 'ErrorMessage');
        tc.AccessEVC = getNodeValue(dom, 'AccessEVC'); 
        tc.LevelUnit = getNodeValue(dom, 'LevelUnit');
        tc.LevelUnitPage = getNodeValue(dom, 'LevelUnitPage');
        tc.Teacher = getNodeValue(dom, 'Teacher');

        return tc;
    }

    public String TechCheckToXml(EtownCaseInfoService.TechCheck tc)
    {
        XmlStreamWriter w = new XmlStreamWriter();
        w.writeStartDocument(null, '1.0');
        w.writeStartElement(null, 'TechCheck', null);
        
        appendElement(w,'Refurl',tc.Refurl);
        appendElement(w,'Server',tc.Server);
        appendElement(w,'Os',tc.Os); 
        appendElement(w,'Browser',tc.Browser);
        appendElement(w,'ConnectionSpeed',tc.ConnectionSpeed);
        appendElement(w,'Flash',tc.Flash);
        appendElement(w,'JVM',tc.JVM);
        appendElement(w,'Aol',tc.Aol);
        appendElement(w,'ASR',tc.ASR);
        appendElement(w,'PageUrl',tc.PageUrl);
        appendElement(w,'NumberTimes',tc.NumberTimes);
        appendElement(w,'TechnicalErrorTextUrl',tc.TechnicalErrorTextUrl);
        appendElement(w,'TechCheck1',tc.TechCheck);
        
        w.writeEndElement();
        w.writeEndDocument();
        String result = w.getXmlString();
        w.close();
        return  result;
    }
    
    public EtownCaseInfoService.TechCheck XmlToTechCheck(String xml)
    {
        EtownCaseInfoService.TechCheck tc = new EtownCaseInfoService.TechCheck();
        xmldom dom = new xmldom(xml);

        tc.Refurl = getNodeValue(dom, 'Refurl');
        tc.Server = getNodeValue(dom, 'Server');
        tc.Os = getNodeValue(dom, 'Os'); 
        tc.Browser = getNodeValue(dom, 'Browser');
        tc.ConnectionSpeed = getNodeValue(dom, 'ConnectionSpeed');
        tc.Flash = getNodeValue(dom, 'Flash');
        tc.JVM = getNodeValue(dom, 'JVM');
        tc.Aol = getNodeValue(dom, 'Aol');
        tc.ASR = getNodeValue(dom, 'ASR');
        tc.PageUrl = getNodeValue(dom, 'PageUrl');
        tc.NumberTimes = getNodeValue(dom, 'NumberTimes');
        tc.TechnicalErrorTextUrl = getNodeValue(dom, 'TechnicalErrorTextUrl');
        tc.TechCheck = getNodeValue(dom, 'TechCheck1');

        return tc;
    }
    
    private void appendElement(XmlStreamWriter w,String key,String value)
    {
        w.writeStartElement(null, key, null);
        if(value == null)
        {
            value = '';
        }
        w.writeCData(value);
        w.writeEndElement();
    }
    
    private String getNodeValue(xmldom dom, String node)
    {
        XMLDom.Element element = dom.getElementByTagName(node);
        if(element != null){
            return element.nodeValue;
        }
        return '';
    }
    static testMethod void TestGenerate()
    {
        EtownCaseInfoService.TechCheck tc = new EtownCaseInfoService.TechCheck();
        tc.Aol = 'test';
        tc.ASR = 'test<';
        tc.Browser = 'test>';
        tc.TechnicalErrorTextUrl = 'jasdkf./asdfk}';
        
        CaseExtensionXmlHelper helper = new CaseExtensionXmlHelper();
        //System.debug(helper.XmlToTechCheck(helper.TechCheckToXml(tc)));
        System.debug(helper.TechCheckToXml(tc));
        
        EtownCaseInfoService.QuestionWithAnswer qa = new EtownCaseInfoService.QuestionWithAnswer();
        
        qa.SurfingFromHome = 'test';
        qa.ErrorMessage = 'test';
        qa.AccessEVC = 'test';
        
        //System.debug(helper.XmlToQwithA(helper.QwithAToXml(qa)));
        System.debug(helper.QwithAToXml(qa));
    }
    
}