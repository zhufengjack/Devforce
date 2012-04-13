public class ChinaTSUtility 
{
    private static final String chinaTsSecurityKey = '#SF_HARDCODE_HASH_STR*';

    public static Boolean validateSecuriteKey(List<String> parameters, String verificationCode)
    {   
        if(parameters != null && parameters.size() > 0 && verificationCode != null)
        {
            String digestString = getChinaTsSecurityToken(parameters); 
            if(verificationCode.equals(digestString))
            {
                return true;
            }
            else
            {
                return false;
            }
        }
        return false;
    }
     
    public static String getChinaTsSecurityToken(List<String> params)
    {
        if(params != null)
        {
            String plainText = '';
            params.add(chinaTsSecurityKey);
            params.sort();
            for(String param : params)
            {
                plainText += param + ':';
            }
            plainText += '3t0wn_H@sh';  
            Blob encryptedText = Crypto.generateDigest('MD5', Blob.valueOf(plainText));
            return EncodingUtil.convertToHex(encryptedText);
        }
        return null;
    }
    
    // This method for generate utc token.
    public static String generateUtcTokenDate()
    {
        // M/dd/yyyy H:mm:ss tt
        Datetime currentTime = Datetime.now();
        Integer year = currentTime.yearGmt();
        Integer month = currentTime.monthGmt();
        Integer day = currentTime.dayGmt();
        Integer hour = currentTime.hourGmt();
        Integer minute = currentTime.minuteGmt();
        Integer second = currentTime.secondGmt();
        String tt = (hour >= 12) ? 'pm' : 'am';
        return month + '/' + day + '/' + year + ' ' + hour + ':' + formatDateString(minute) + ':' + formatDateString(second) + ' ' + tt;
    }
    
    // Format date string.
    private static String formatDateString(Integer value)
    {
        String result = '';
        if(value != null)
        {
            result = String.valueOf(value);
            if(result.length() < 2)
            {
                result = '0' + result;
            }
        }
        return result;
    }
    
    public static void checkAndCreateNewContact(Opportunity opp, String memberId)
    {   
        if(opp != null && opp.AccountId != null)
        {
            List<Account> accounts = [select Id, Name, (select Id from Contacts limit 1) from Account where Id = :opp.AccountId];
            if(accounts.size() > 0)
            {   
                if(accounts[0].Contacts.size() == 0)
                {
                    createNewContactForStudent(opp, accounts[0].Name, memberId);
                }
            }
        }
    }
    
    private static void createNewContactForStudent(Opportunity opp, String accountName, String memberId)
    {
        if(opp != null && accountName != null)
        {
            Contact newContact = new Contact(AccountId = opp.AccountId, phone = opp.Phone2__c, MobilePhone = opp.Mobile__c, Email = opp.Email__c);
            newContact.LastName = (accountName.length() > 80) ? accountName.substring(0, 80) : accountName;
            if(memberId != null && memberId != '')
            {
                newContact.EtownMemberId__c = Integer.valueOf(memberId);
            }
            insert newContact;
        }
    }
    
    @isTest
    static void testChinaTSUtility()
    {
        ChinaTSUtility.validateSecuriteKey(new List<String>{'test1', 'test2', 'test3'}, ChinaTSUtility.getChinaTsSecurityToken(new List<String>{'test1', 'test2', 'test3'}));
        ChinaTSUtility.generateUtcTokenDate();
        Account testAccount = new Account(Name = 'test account', First_Name__c = 'First Name', Last_Name__c = 'Last Name', phone = '3214567890', Mobile__c = '1234567890');
        insert testAccount;
        Opportunity opp = new Opportunity(Name = 'acme', StageName = 'set App', Email__c = 'test@testForTs.com', Phone2__c = '13426093522', Mobile__c = '3322123', CloseDate = System.today(), China_Sales_Type__c = 'New', AccountId = testAccount.Id);
        insert opp;
        String testMemberId = '99999929';
        List<Opportunity> testOpps = [select Id, Name, Mobile__c, Phone2__c, Email__c, AccountId, product__c, China_Sales_Type__c from Opportunity where Id = :opp.Id];
        ChinaTSUtility.checkAndCreateNewContact(opp, testMemberId);
    }
}