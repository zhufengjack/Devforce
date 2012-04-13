/*
 * controller for pageStudentShowUp
 */
public class StudentShowUpExtension 
{
    private Opportunity mostRecentOpp;
    private Account record;
    public StudentShowUpExtension(ApexPages.StandardController controller) 
    {
        String accountId = controller.getId();
        if(accountId != null)
        {
            record = (Account)controller.getRecord();
            List<Opportunity> opps = [select Id, StageName from Opportunity where AccountId=:accountId order by CreatedDate desc limit 1];
            if(opps.size() > 0)
            {
                mostRecentOpp = opps[0];
            }
        }
    }

    public String CurrentUserRole
    {
        get
        {
            for(User user : [select Id, UserRole.Name from User where Id=:UserInfo.getUserId()])
            {
                String roleName = user.UserRole.Name;
                //user the first 12 characters for the school name, e.g.: China BJ CYM is the starting of a role
                if(roleName != null && roleName.length() > 13)
                {
                    return roleName.substring(0, 13);
                }
                return roleName;
            }
            return '';
        }
    }
    public String AccountOwnerRole
    {
        get
        {
            for(User user : [select Id, UserRole.Name from User where Id=:record.OwnerId])
            {
                if(user.UserRole == null)
                {
                    return '';
                }
                if(user.UserRole.Name.length() > 13)
                {
                    return user.UserRole.Name.substring(0, 13);
                }
                return user.UserRole.Name;
            }
            return '';
        }
    }
    public PageReference showUp()
    {
        if(mostRecentOpp == null)
        {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Student has no opportunity.'));
            return null;
        }
        else if(mostRecentOpp.StageName != 'Set Appt' && mostRecentOpp.StageName != 'Appt No Show - Rescheduled' && mostRecentOpp.StageName != 'Appt No Show - Call Later' && mostRecentOpp.StageName != 'Close/Lost - No Show')
        {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '该学员已经来过学校了，请不要重复点击Show up.<br/>The stage is already show-up and you can not change.'));
            return null;
        }
        else
        {
            if(AccountOwnerRole == CurrentUserRole)
            {
                mostRecentOpp.StageName = 'Showed Up - Followup';
                try
                {
                    update mostRecentOpp;
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully showed up.<script type="text/javascript">alert("Student showed up.");window.location="/'+record.Id+'";</script>'));
                    return null;
                }
                catch(Exception ex)
                {
                    Apexpages.addMessages(ex);
                    return null;
                }
            }
            else
            {
                String schoolName =  (AccountOwnerRole != '')? AccountOwnerRole : '别的';
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '这是'+schoolName +'学校的学员，你不能进行操作。<br/>The student is assigned (booked) for another center. You can not change stage.'));
                return null;
            }
        }
        return new PageReference('/' + record.Id);
    }
    
    @isTest
    static void testStudentShowUpExtension()
    {
        Account acc = new Account(Name='acme');
        insert acc;
        acc = [select Id, Name, OwnerId from Account where Id=:acc.Id limit 1];
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt', CloseDate=Date.today(), AccountId=acc.Id);
        insert opp;
        ApexPages.StandardController controller = new ApexPages.StandardController(acc);
        StudentShowUpExtension extension = new StudentShowUpExtension(controller);
        extension.showUp();
        
        opp = [select Id, StageName from Opportunity where Id=:opp.Id limit 1];
        System.assertEquals('Showed Up - Followup', opp.StageName);
    }
}