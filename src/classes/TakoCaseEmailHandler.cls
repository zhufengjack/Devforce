/*
 * An email handler, converts incoming email into EtownCaseComment object
 * Pony Ma 2012-02-07 Fixed a test method issue - Case is not related to a contact
 */
global class TakoCaseEmailHandler implements Messaging.InboundEmailHandler 
{ 
    private Static final Boolean ForwardEverything = false;
     private static final String CaseNotExist = 'Dear EF customer,\r\nThank you for your email.\r\n\r\nWe are sorry that we cannot find your case because the original email subject that we sent is changed.\r\nPlease reply the email that you received from us not to change its subject if you still have a question.\r\n\r\nPlease do not reply to this email.\r\n\r\nBest regards,\r\nThe Customer Relation Team';
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope)
    { 
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        if(ForwardEverything)
        {
            Messaging.SingleEmailMessage forwardingMail = new Messaging.SingleEmailMessage();
            forwardingMail.setToAddresses(new String[] { 'kevin.chong@meginfo.com' });
            forwardingMail.setSubject(email.subject);
            forwardingMail.setPlainTextBody(email.plainTextBody);
            forwardingMail.setHtmlBody(email.htmlBody);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { forwardingMail });
        }
        try  
        {
            String[] caseNumbers = parseCaseNumber(email.subject);
            Case theCase = findCaseByNumbers(caseNumbers);
            if(theCase == null)
            {  
                result.success = false;
                result.message = CaseNotExist; 
            }
            else
            {
                if(!isDuplicateEmail(theCase, email))
                {
                    EtownCaseComment__c comment = createCaseComment(theCase, email);
                    addAttachmentsToComment(comment, email);
                    result.success = true;
                } 
                else
                {
                    result.success = true;
                }
            }
        }
        catch(Exception ex)
        {  
            result.success = false;
            result.message = 'An error ocurred when processing the email, the error message is ->' + ex.getMessage();
        }
        return result;
    }  

    private static Case findCaseByNumbers(String[] caseNumbers)
    {
        Case[] cases = [select Id from Case where CaseNumber in :caseNumbers limit 1];
        if(cases.size() > 0)
        {
            return cases[0];
        }
        else
        {
            return null;
        }
    }
    
    //extract the id between the last pair of brackets
    private static String[] parseCaseNumber(String subject)
    {
        List<String> result = new List<String>();
        Pattern subjectPattern = Pattern.compile('\\[(\\d+)\\]');
        Matcher subjectMatcher = subjectPattern.matcher(subject);
        while(subjectMatcher.find())
        {
            if(subjectMatcher.groupCount() > 0)
            {
                String value = subjectMatcher.group(1);
                if(value != '' && value != null)
                {
                    result.add(value);
                }
            }
        }
        return result;
    }
  
    //add attachment to the specified case
    private static void addAttachmentsToComment(EtownCaseComment__c comment, Messaging.InboundEmail email)
    {
        List<Attachment> attachments = new List<Attachment>();
        Id commentId = comment.Id;
        
        if(email.BinaryAttachments != null)
        {
            //add BinaryAttachment to the object
            for(Messaging.InboundEmail.BinaryAttachment ba : email.BinaryAttachments)
            {
                Attachment ac = new Attachment(Body = ba.Body, ParentId = commentId, Name = ba.fileName);  
                attachments.add(ac);    
            }
        }
        if(email.TextAttachments!=null)
        {
            //add TextAreaAttachment to the case object
            for(Messaging.InboundEmail.TextAttachment taa : email.TextAttachments)
            {
                Attachment ac = new Attachment(Body=Blob.valueOf(taa.Body), ParentId=commentId, Name=taa.fileName);          
                attachments.add(ac);
            }
        }
        if(attachments.size() > 0)
        {
            insert attachments;
            
        }
    }
   
    // A method used to convert email's html body to text body
    // salesforce use "/n" to replace line breaks
    public static String convertHtmlToText(String htmlBody)
    {
        String result;
        // Replace line breaks with space
        // because browsers inserts space
        result = htmlBody.replaceAll('\r', ' ');
        result = result.replaceAll('\n', ' ');
        // Remove step-formatting
        result = result.replaceAll('\t', '');
        // Remove repeating spaces because browsers ignore them
        result = result.replaceAll('( )+', ' '); 
        // remove the header
        result = result.replaceAll('<( )*head([^>])*>', '<head>');
        result = result.replaceAll('(<( )*(/)( )*head( )*>)', '</head>');
        result = result.replaceAll('<(<head>).*(</head>)', '');
        // remove all scripts (prepare first by clearing attributes)
        result = result.replaceAll('<( )*script([^>])*>', '<script>');
        result = result.replaceAll('(<( )*(/)( )*script( )*>)', '</script>');
        result = result.replaceAll('(<script>).*(</script>)', '');
        // remove all styles (prepare first by clearing attributes)
        result = result.replaceAll('<( )*style([^>])*>', '<style>');
        result = result.replaceAll('(<( )*(/)( )*style( )*>)', '</style>');       
        result = result.replaceAll('(<style>).*(</style>)', '');
        // insert tabs in spaces of <td> tags
        result = result.replaceAll('<( )*td([^>])*>', '\t');
        // insert line breaks in places of <BR> and <LI> tags
        result = result.replaceAll('<( )*br([^>])*>', '\n');
        result = result.replaceAll('<( )*li( )*>', '\n');
        // insert line paragraphs (double line breaks) in place
        // if <P>, <DIV> and <TR> tags
        result = result.replaceAll('<( )*div([^>])*>', '\n\n');
        result = result.replaceAll('<( )*tr([^>])*>', '\n\n');    
        result = result.replaceAll('<( )*p([^>])*>', '\n\n');
        // Remove remaining tags like <a>, links, images,
        // comments etc - anything that's enclosed inside < >
        result = result.replaceAll('<[^>]*>', '');
        // replace special characters:
        result = result.replaceAll(' ', ' ');
        result = result.replaceAll('&bull;', ' * ');        
        result = result.replaceAll('&lsaquo;', '<');
        result = result.replaceAll('&rsaquo;', '>');
        result = result.replaceAll('&trade;', '(tm)');
        result = result.replaceAll('&frasl;', '/');
        result = result.replaceAll('&lt;', '<');
        result = result.replaceAll('&gt;', '>');
        result = result.replaceAll('&copy;', '(c)');    
        result = result.replaceAll('&reg;', '(r)');
        result = result.replaceAll('&apos;', '\'');
        result = result.replaceAll('&#39;', '\'');
        result = result.replaceAll('&quot;', '"');
        // Remove all others. More can be added, see
        // http://hotwired.lycos.com/webmonkey/reference/special_characters/
        result = result.replaceAll('&(.{2,6});', '');
        // make line breaking consistent
        result = result.replaceAll('\r', '\n');
        // Remove extra line breaks and tabs:
        // replace over 2 breaks with 2 and over 4 tabs with 4.
        // Prepare first to remove any whitespaces in between
        // the escaped characters and remove redundant tabs in between line breaks
        result = result.replaceAll('(\n)( )+(\n)', '\n\n');    
        result = result.replaceAll('(\t)( )+(\t)', '\t\t');
        result = result.replaceAll('(\t)( )+(\n)', '\t\n');
        result = result.replaceAll('(\n)( )+(\t)', '\n\t');   
        // Remove redundant tabs
        result = result.replaceAll('(\n)(\t)+(\n)', '\n\n');
        // Remove multiple tabs following a line break with just one tab
        result = result.replaceAll('(\n)(\t)+','\n\t');  
        // Initial replacement target string for line breaks
        String breaks = '\n\n\n';
        // Initial replacement target string for tabs
        String tabs = '\t\t\t\t\t';
        for(Integer index = 0; index < result.Length(); index++)
        {
            result = result.replaceAll(breaks, '\n\n');
            result = result.replaceAll(tabs, '\t\t\t\t');
            breaks = breaks + '\n';
            tabs = tabs + '\t';
        }
        // That's it.
        return result;
    }
        
    //add a comment to case
    private static EtownCaseComment__c createCaseComment(Case theCase, Messaging.InboundEmail email)
    {
        String caseId = theCase.Id;
        String emailMessage = '';
        String htmlBody = (email.htmlBody != null && email.htmlBody != '') ? email.htmlBody : email.plainTextBody;
        String textBody = (email.plainTextBody != null && email.plainTextBody != '') ? email.plainTextBody : convertHtmlToText(email.htmlBody);
        EtownCaseComment__c comment = new EtownCaseComment__c();
        if(textBody != null && textBody != '' &&  textBody.trim().length() > 0)
        {
            String[] emailLines = textBody.split('(\r\n)|\r|\n');
            for(Integer i = 0; i < emailLines.size(); i++)
            {
                if(emailLines[i].contains('customer.relation@ef.com'))             
                {
                    break;
                } 
                else
                {
                    emailMessage += emailLines[i] + '\n';
                }
            } 
            if(emailMessage == '' || emailMessage == null || emailMessage.trim().length() == 0)  
            {
                emailMessage = textBody;
            }
        }
        comment = new EtownCaseComment__c(Case__c=caseId, CommentBody__c= htmlBody, PlainTextBody__c = emailMessage, Type__c='Inbound');
        insert comment;
        return comment;
    }
  
    private static Boolean isDuplicateEmail(Case theCase, Messaging.InboundEmail email)
    {
        String body = (email.htmlBody != null && email.htmlBody != '') ? email.htmlBody : email.plainTextBody;
        List<EtownCaseComment__c > comments = [select Id, CommentBody__c from EtownCaseComment__c where Case__c=:theCase.Id and Type__c='Inbound' order by CreatedDate desc limit 1];
        if(comments.size() > 0)
        {
            return (comments[0].CommentBody__c == body);
        }
        else
        {
            return false;
        }
    }
    
    @isTest 
    static void testParseCaseNumber()
    {
        System.assertEquals(2, parseCaseNumber('test[20102015][4]').size());
    }
    
    @isTest
    static void testFindCaseByNumber()
    {
        Case tempCase = [select Id, CaseNumber from Case limit 1];
        System.assert(findCaseByNumbers(new List<String> {tempCase.CaseNumber}) != null);
    }
    
    @isTest
    static void testIsDuplicateEmail()
    {
        Account a =new Account(Name='testacc');
        insert a;
        Contact c=new Contact(FirstName='aa',LastName='bb');
        c.AccountId=a.Id;
        insert c;
        Case testCase = new Case(Subject='acme');
        testCase.ContactId=c.Id;
        insert testCase;
        EtownCaseComment__c comment = new EtownCaseComment__c(Case__c=testCase.Id, Type__c='Inbound', CommentBody__c='acme');
        insert comment;
        Messaging.Inboundemail testEmail = new Messaging.Inboundemail();
        testEmail.subject = 'acme subject';
        testEmail.plainTextBody = 'acme';
        System.assertEquals(true, isDuplicateEmail(testCase, testEmail));
    }
    
    @isTest 
    static void testConvertHtmlToText()
    {
        String htmlBody = '<div>Test <img id ="1"> </img></div>';
        convertHtmlToText(htmlBody);
    }
    
    @isTest
    static void testInsertCaseComment()
    {
        Account a =new Account(Name='testacc');
        insert a;
        Contact c=new Contact(FirstName='aa',LastName='bb');
        c.AccountId=a.Id;
        insert c;
        Case testCase = new Case(Subject='acme');
        testCase.ContactId=c.Id;
        insert testCase;
        Messaging.Inboundemail testEmail = new Messaging.Inboundemail();
        testEmail.subject = 'acme subject';
        testEmail.plainTextBody = 'acme';
        System.assert(createCaseComment(testCase, testEmail) != null);
    }
    
    @isTest
    static void testTakoCaseEmailHandler()
    {
        Account a =new Account(Name='testacc');
        insert a;
        Contact c=new Contact(FirstName='aa',LastName='bb');
        c.AccountId=a.Id;
        insert c;
        Case testCase = new Case(Subject='acme');
        testCase.ContactId=c.Id;
        insert testCase;
        
        testCase = [select Id, CaseNumber from Case where Id=:testCase.Id limit 1];
        
        Messaging.Inboundemail testEmail = new Messaging.Inboundemail();
        testEmail.subject = 'acme subject [' + testCase.CaseNumber + '][test]';
        testEmail.plainTextBody = 'acme';
        List<Messaging.Inboundemail.Binaryattachment> bAttachments = new List<Messaging.Inboundemail.Binaryattachment>();
        List<Messaging.Inboundemail.Textattachment> tAttachments = new List<Messaging.Inboundemail.Textattachment>();
        Messaging.Inboundemail.Binaryattachment bAttachment = new Messaging.Inboundemail.Binaryattachment();
        bAttachment.body = Blob.valueOf('acme');
        bAttachment.fileName = 'binary attachment';
        bAttachments.add(bAttachment);
        testEmail.binaryAttachments = bAttachments;
        Messaging.Inboundemail.Textattachment tAttachment = new Messaging.Inboundemail.Textattachment();
        tAttachment.body = 'acme';
        tAttachment.fileName = 'text attachment';
        tAttachments.add(tAttachment);
        testEmail.textAttachments = tAttachments;
        
        TakoCaseEmailHandler handler = new TakoCaseEmailHandler();
        handler.handleInboundEmail(testEmail, null);
        
        testCase = [select Id, CaseNumber, (select Id from EtownCaseComments__r) from Case where Id=:testCase.Id limit 1];
        System.assertEquals(1, testCase.EtownCaseComments__r.size());
    }
}