public class ThorSendEmailServiceHelper 
{
    public static ThorSendEmailServiceStub.BasicHttpBinding_ISendMailServcie service = new ThorSendEmailServiceStub.BasicHttpBinding_ISendMailServcie();
    
    static
    {
        service.timeout_x = 60 * 1000 * 2;
    }
    
    public ThorSendEmailServiceHelper(){}
    
    // We use this method in "Study Advisor" task edit page. 
    public EmailServiceResult sendEmail(String toAddress, String fromAddress, String emailSubject, String emailBody, Boolean isHtmlBody)
    {
        EmailServiceResult result = new EmailServiceResult();
        ThorSendEmailServiceDataContract.SendMailResult serviceResult;
        ThorSendEmailServiceDataContract.SendMailParams sendMailParams = new ThorSendEmailServiceDataContract.SendMailParams();
        sendMailParams.MailFrom = fromAddress;
        sendMailParams.MailTo = toAddress;
        sendMailParams.MailSubject = emailSubject;
        sendMailParams.MailBody = emailBody;
        sendMailParams.SubjectEncoding='UTF8';
        sendMailParams.BodyEncoding='UTF8';
        sendMailParams.IsBodyHtml = isHtmlBody;
        try
        {  
            serviceResult = service.SendMail(sendMailParams);
            result.isSuccess = serviceResult.IsSuccess;
            result.errorCode = serviceResult.errorCode;
        }
        catch(Exception ex)
        {
            result.isSuccess = false;
            result.errorMessage = ex.getMessage();
        }
        return result;
    }
    
    public static List<EmailServiceResult> sendEmail(List<ThorEmailMessage> emails)
    {
        List<EmailServiceResult> results = new List<EmailServiceResult>();
        if(emails != null && emails.size() > 0)
        {
            for(ThorEmailMessage email : emails)
            {
                EmailServiceResult result = processSendEmailRequest(email);
                results.add(result);
            }
        }
        return results;
    }
    
    private static EmailServiceResult processSendEmailRequest(ThorEmailMessage email)
    {
        EmailServiceResult result = new EmailServiceResult();
        ThorSendEmailServiceDataContract.SendMailResult serviceResult;
        ThorSendEmailServiceDataContract.SendMailParams sendMailParams = new ThorSendEmailServiceDataContract.SendMailParams();
        initialSendMailParams(sendMailParams, email);
        try
        { 
            serviceResult = service.SendMail(sendMailParams);
            result.isSuccess = serviceResult.IsSuccess;
            result.errorCode = serviceResult.errorCode;
        }
        catch(Exception ex)
        {
            result.isSuccess = false;
            result.errorMessage = ex.getMessage();
        }
        return result;
    }
    
    private static void initialSendMailParams(ThorSendEmailServiceDataContract.SendMailParams sendMailParams, ThorEmailMessage email)
    {
        if(sendMailParams != null)
        {
            sendMailParams.MailFrom = email.replyTo;   //fromAddress;
            sendMailParams.MailTo = email.toAddresses; //toAddress;
            sendMailParams.MailSubject = email.subject; //emailSubject;
            sendMailParams.MailBody = (email.isHtmlBody == true)? email.htmlBody: email.plainTextbody;
            sendMailParams.SubjectEncoding= email.SubjectEncoding; //'UTF8';
            sendMailParams.BodyEncoding= email.BodyEncoding; //'UTF8';
            sendMailParams.IsBodyHtml = email.isHtmlBody; //isHtmlBody;
        }
    }
    
    public class ThorEmailMessage 
    {
        public String toAddresses = '';
        public String ccAddresses = '';
        public String bccAddresses = '';
        public String replyTo;
        public String senderDisplayName;
        public String subject;
        public String htmlBody;
        public String plainTextbody;
        public String SubjectEncoding = 'UTF8';
        public String BodyEncoding = 'UTF8';
        public Boolean isHtmlBody = true;
        public List<ThorEmailFileAttachment> fileAttachments;
        
        public void setToAddresses(List<String> toAddrs)
        {
            toAddresses = formatEmailAddresses(toAddrs);
        }
        
        public void setCcAddresses(List<String> ccAddrs)
        {
            ccAddresses = formatEmailAddresses(ccAddrs);
        }
        
        public void setBccAddresses(List<String> bccAddrs)
        {
            bccAddresses = formatEmailAddresses(bccAddrs);
        }
        
        public void setSenderDisplayName(String displayName)
        {
            senderDisplayName = displayName;
        }
        
        public void setReplyTo(String replyToEmail)
        {
            replyTo = replyToEmail;
        }
        
        public void setSubject(String subjectValue)
        {
            subject = subjectValue;
        }
        
        public void setHtmlBody(String bodyValue)
        {
            htmlBody = bodyValue;
        }
        
        public void setPlainTextBody(String bodyValue)
        {
            plainTextbody = bodyValue;
        }
        
        public void setFileAttachments(List<ThorEmailFileAttachment> emailFileAttachments)
        {
            fileAttachments = emailFileAttachments;
        }
        
        private String formatEmailAddresses(List<String> addresses)
        {
            String result = '';
            if(addresses != null && addresses.size() > 0)
            {
                Integer addressesSize = addresses.size();
                Integer lastAddressIndex = addressesSize - 1;
                for(Integer i = 0; i < addressesSize; i++)
                {
                    result = result + addresses[i];
                    if(i < lastAddressIndex)
                    {
                        result = result + ';';
                    }
                }
            }
            return result;
        }
    }
    
    public class ThorEmailFileAttachment
    {
        // To do ....
    }
    
    public class EmailServiceResult 
    {
        public Boolean isSuccess;
        public String errorCode;
        public String errorMessage;
    }
    
    @isTest
    static void testThorSendEmailServiceHelper()
    {
        ThorSendEmailServiceHelper helper = new ThorSendEmailServiceHelper();
        String toAddress = 'test1@m.com';
        String fromAddress = 'test2@m.com';
        String emailSubject = 'Email subject';
        String emailBody = 'This is a test email....';
        Boolean isHtmlBody = true;
        helper.sendEmail(toAddress, fromAddress, emailSubject, emailBody, isHtmlBody);
        ThorSendEmailServiceHelper.ThorEmailMessage email = new ThorSendEmailServiceHelper.ThorEmailMessage();
        email.setToAddresses(new List<String>{'test.ef@ef.com', 'test2.ef@ef.com'});
        email.setCcAddresses(new List<String>{'cc@ef.com', 'cc2@ef.com'});
        email.setBccAddresses(new List<String>{'bcc@ef.com', 'bcc2@ef.com'});
        email.setReplyTo('replyto@test.com');
        email.setSubject('Test Thor Email');
        email.setHtmlBody('<html></html>');
        email.setPlainTextBody('plain text body!');
        email.setSenderDisplayName('Test display name');
        email.setFileAttachments(new List<ThorEmailFileAttachment>{});
        ThorSendEmailServiceHelper.sendEmail(new List<ThorSendEmailServiceHelper.ThorEmailMessage>{email});
    }
}