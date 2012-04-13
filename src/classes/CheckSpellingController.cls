/*
 * To check spelling with google api
 */
public class CheckSpellingController 
{
    public String MatchedResult 
    { 
        get
        {
            String result;
            if(result == null)
            {
                String content = ApexPages.currentPage().getParameters().get('text');
                String lang = ApexPages.currentPage().getParameters().get('lang');
                String method = 'text';
                if(content == null)
                {
                    content = ApexPages.currentPage().getParameters().get('suggest');
                    method = 'suggest';
                }
                result = getGoogleMatches(EncodingUtil.urlDecode(content,'UTF-8'), lang , method);
            }
            return result;
        }
        set; 
    }
    
    private static String getGoogleMatches(String content, String lang, String method)
    {
        String result;
        String url = 'https://www.google.com';
        String path = '/tbproxy/spell?lang=' + lang + '&hl=en';
        String endPoint = url + path;
        // setup XML request
        String xml = '<?xml version="1.0" encoding="utf-8" ?>';
        xml += '<spellrequest textalreadyclipped="0" ignoredups="0" ignoredigits="1" ignoreallcaps="1">';
        xml += '<text>' + content + '</text></spellrequest>';
        Dom.Document domDoc = new Dom.Document();
        domDoc.load(xml);
        
        HttpRequest req = new HttpRequest();
        req.setMethod('POST');
        req.setTimeout(120*1000); //2 minutes
        req.setEndpoint(endPoint);
        req.setHeader('Content-Type', 'text/xml');
        req.setBodyDocument(domDoc);
        
        if(!Test.isRunningTest())
        {
            Http http = new Http();
            HttpResponse res = http.send(req);
            try
            {
                result = xmlFormatToJson(res.getBodyDocument(), method, content);
            }
            catch(Exception ex)
            {
                throw ex;
            }
        }
        else
        {
            result = '["iz","somme","badlyy"]';
        }
        
        return result;
    }
    
    //<?xml version="1.0" encoding="UTF-8"?>
    //<spellresult error="0" clipped="0" charschecked="10">
    //    <c o="0" l="4" s="1">live lobe</c>
    //    <c o="5" l="5" s="1">force    forage</c>
    //</spellresult>
    // o : The offset from the start of the text of the word
    // l : Length of misspelled word
    // s : Confidence of the suggestion
    
    private static String xmlFormatToJson(Dom.Document doc, String method, String content)
    {
        Dom.XMLNode rootXml = doc.getRootElement();
        String jsonStr = '[';
        List<String> errorWords = new List<String>();
        if(method == 'text')
        {
            List<Dom.XMLNode> wordXmls = rootXml.getChildElements();
            for(Dom.XMLNode wordXml : wordXmls)
            {
                Integer start = Integer.valueOf(wordXml.getAttributeValue('o', null));
                Integer wordLength = Integer.valueOf(wordXml.getAttributeValue('l', null));
                errorWords.add(content.subString((start == 0) ? 0 : start, start + wordLength));
            }
        }
        else
        {
             Dom.XMLNode wordXml = rootXml.getChildElement('c', null);
             if(wordXml != null)
             {
                 String suggestWords = wordXml.getText();
                 errorWords = suggestWords.split('\t');
             }
        }
        for(Integer i = 0; i < errorWords.size(); i++)
        {
            if(i == (errorWords.size() - 1)) 
            {
                jsonStr += '"' + errorWords[i].trim() + '"';
            }
            else
            {
                jsonStr += '"' + errorWords[i].trim() + '",';
            }
        }
        return jsonStr + ']';
    }
    
    @isTest
    static void testCheckSpellingController()
    {
        PageReference page =  new PageReference('/apex/checkspelling?lang=en&text=iz');
        Test.setCurrentPage(page);
        CheckSpellingController controller = new CheckSpellingController();
        System.assert(controller.MatchedResult.length() > 0);
        page = new PageReference('/apex/checkspelling?lang=en&suggest=iz');
        Test.setCurrentPage(page);
        System.assert(controller.MatchedResult.length() > 0);
        String resultXml = '<?xml version="1.0" encoding="UTF-8"?><spellresult error="0" clipped="0" charschecked="10"><c o="0" l="4" s="1">live \t lobe</c><c o="5" l="5" s="1">force  forage</c></spellresult>';
        Dom.Document domDoc = new Dom.Document();
        domDoc.load(resultXml);
        System.assertEquals(CheckSpellingController.xmlFormatToJson(domDoc, 'text', 'loev forec'), '["loev","forec"]');
        System.assertEquals(CheckSpellingController.xmlFormatToJson(domDoc, 'suggest', 'loev'), '["live","lobe"]');
    }
    
}