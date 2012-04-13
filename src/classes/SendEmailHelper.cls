/**
 * a helper class for sending email with specified condition
*/
public class SendEmailHelper 
{
    private Messaging.SingleEmailMessage mail;
    
    public SendEmailHelper(String subject, String[] ccAddresses, String body, String senderDisplayName, String replayTo)
    {
        initMail(subject, ccAddresses, body, senderDisplayName, replayTo);
    }
    //gets mail by specified user
    public Messaging.SingleEmailMessage getMailByProfile(String emailAddress)
    {
        mail.setToAddresses(new String[]{emailAddress});
        return mail;
    }
    
    //gets mail by specified profile Id 
    public List<Messaging.SingleEmailMessage> getMailsByProfile(Id profileId)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<User> users = [select Email from User where ProfileId =:profileId and IsActive = true];
        for(User user : users)
        {
            mail.setToAddresses(new String[]{user.Email});
            mails.add(mail);
        }
        return mails;
    }
    
    //gets mail by specified role Id    
    public List<Messaging.SingleEmailMessage> getMailByRole(Id roleId)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<User> users = [select Email from User where UserRoleId = :roleId and IsActive = true];
        for(User user : users)
        {
            mail.setToAddresses(new String[]{user.Email});
            mails.add(mail);
        }
        return mails;
    }
    
    //gets mail by specified profile Id and role Id
    public List<Messaging.SingleEmailMessage> getMailByProfileAndRole(Id profileId, Id roleId)
    {
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        List<User> users = [select Email from User where ProfileId =:profileId and UserRoleId = :roleId and IsActive = true];
        for(User user : users)
        {
            mail.setToAddresses(new String[]{user.Email});
            mails.add(mail);
        }
        return mails;
    }
    
    public static void sendExceptionEmail(String toAddress, String subject, String body)
    {
        if(isSandbox())
        {
            toAddress = 'exception@meginfo.com';
            subject = 'EF sandbox exception: ' + subject;
        }
        sendSimpleEmail(new String[] {toAddress}, subject, body);
    }
    
    //sends an email with plaintext body to the specified addresses.
    public static void sendSimpleEmail(String[] toAddresses, String subject, String body)
    {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();    
        mail.setToAddresses(toAddresses);     
        mail.setSaveAsActivity(false);
        mail.setSubject(subject);
        mail.setPlaintextBody(body);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
    }
    
    //gets mail with specified fields such as subject, emailAddress⋯⋯
    private void initMail(String mailSubject, String[] mailCcAddresses, String mailBody, String mailSenderDisplayName, String mailReplayTo)
    {
        mail.setCcAddresses(mailCcAddresses);
        mail.setHtmlBody(mailBody);
        mail.setSubject(mailSubject);
        mail.setSenderDisplayName(mailSenderDisplayName);
        mail.setReplyTo(mailReplayTo);
    }
    
    private static Boolean isSandbox()
    {
        String currentHost = URL.getSalesforcebaseURL().getHost();
        return (Pattern.matches('.*\\.(cs[\\d]+|tapp0)\\..*', currentHost));
    }
}