/* 
 * A controller for Override Case View page
 * Change Log:
 * Pony Ma 2011-11-07 Do not display email template for internal comment
 */ 
public class OverrideCaseViewController 
{
    private String caseId;
    private Case caseInfo;
    private String emailSubject;
    private String emailContent;
    private String commentId;
    private Boolean isENTemplate;
    private Set<String> relatedSolutions;
    private ETownCaseComment__c commentInfo;
    private Boolean isUploadFile = false;
    private Boolean isExistedSolution = false;
    private final String orgEmailAddress = 'customer.relation@ef.com';
    
    
    public OverrideCaseViewController(ApexPages.StandardController stdController)
    {
        caseId = stdController.getId();
        List<ETownCaseComment__c> comments = [select Id, UseENTemplate__c from ETownCaseComment__c where Case__c != null and Case__c = :caseId and Type__c = 'Outbound' order by LastModifiedDate desc];
        isENTemplate = (comments.size() > 0)? comments[0].UseENTemplate__c : false;
        isENTemplate = (ApexPages.currentPage().getParameters().get('lanEN') != null)? Boolean.valueOf(ApexPages.currentPage().getParameters().get('lanEN')): isENTemplate;
        List<Case> cases = [select Id, CaseNumber, LanguageCode__c, Business_Unit__c, Contact.BU__c, Contact.PreferredLanguage__c, RecordType.Name from Case  where Id = :caseId and ContactId != null];
        if(cases.size() > 0)
        {
            caseInfo = cases[0];
        }
        Attach = new Attachment();
        SortKey = 'CreatedDate';
        IsDesc = true;
    }
    
    public String SortKey { get; set; }
    public Boolean IsDesc { get; set; }
    public String DeletedFileId { get; set; }
    public Boolean IsShowReplayPanel { get; set; }
    public Boolean IsENEmailTemplate { get; set; }
    public Attachment Attach { get; set; }
    
    
    public ETownCaseComment__c Comment
    {
        get
        {
            if(caseInfo != null && commentInfo == null)
            {
                commentInfo = getInitCaseComment();
                IsShowReplayPanel = commentInfo.IsDraft__c;
            }
            return commentInfo;
        }
        set;
    }
    
    public List<Attachment> Attachments
    { 
        get
        {
            List<Attachment> result = new List<Attachment>();
            if(Comment != null && Comment.Id != null)
            {
                result = [select Id, Name from Attachment where ParentId = :Comment.Id];
            }
            return result;
        }
    }
    
    public List<ETownCaseComment__c> CaseComments 
    {
        get
        {
            List<ETownCaseComment__c> orderComment;
            if(caseId != null && SortKey != null)
            {
                String queryStr = 'select Id, Name, Type__c, PlainTextBody__c, LastModifiedDate, CreatedById, CreatedDate, (select Id from Attachments) from ETownCaseComment__c where Case__c != null and Case__c = \'' + caseId + '\' and IsDraft__c = false order by ' + SortKey + ((IsDesc == true) ? ' desc' : ' asc');
                List<sObject> s = Database.query(queryStr);
                orderComment = (List<ETownCaseComment__c>)s;
            }
            return  orderComment;
        }
    }
    
    //redirect user to standard new case page if record type of case is not ETown User Case
    public PageReference redirect()
    {
        if(caseId == null)
        {
           return new PageReference('/500/o');
        }
        else if(caseInfo == null || caseInfo.RecordType.Name != 'ETown Student Case')
        {
            return new PageReference('/' + caseId + '?nooverride=1');
        }
        return null;
    }
    
    public PageReference redirectToFindSolution()
    {
        isExistedSolution = true;
        isUploadFile = false;
        Comment.IsDraft__c = true;
        saveCaseComment();
        return new PageReference('/ui/solution/SolutionSearchCasesPage?caseid=' + caseId + '&t=4&search=&cid=000000000000000&srchbtn=Find+Solution');
    }
    
    public PageReference uploadFile()
    {
        isUploadFile = true;
        Comment.IsDraft__c = true;
        Comment.HasSolutionMerged__c = false;
        if(saveCommentAndUploadedFile())
        {
            isUploadFile = false;
            IsShowReplayPanel = true;
            PageReference page = new PageReference('/apex/overridecaseview?id=' + caseId);
            page.setRedirect(true);
            return page;
        }
        isUploadFile = false;
        return null;
    }
    
    public PageReference saveInternalCase()
    {
        Comment.IsDraft__c = false;
        Comment.Type__c = 'Internally';
        Comment.UseENTemplate__c = false;
        if(saveCaseComment())
        {
            PageReference page = new PageReference('/apex/overridecaseview?replied=true&id=' + caseId);
            page.setRedirect(true);
            return page;
        }
        return null;
    }
    
    public PageReference refreshEmailTemplate()
    {        
        
        PageReference page = new PageReference('/apex/overridecaseview?replied=true&id=' + caseId + '&lanEN=' + IsENEmailTemplate);
        page.setRedirect(true);
        return page;
    }
    
    public PageReference sendEmail()
    {
        Boolean isSucceed = false;
        SavePoint sp = DataBase.setSavepoint();
        isUploadFile = false;
        Comment.IsDraft__c = false;
        Comment.Type__c = 'Outbound';
        Comment.HasSolutionMerged__c = isExistedSolution;
        if(saveCaseComment() && verifyContactInfo())
        {
            isSucceed = getSendingEmailStatus();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please check the contact information.'));
        }
        if(isSucceed)
        {
            PageReference page = new PageReference('/apex/overridecaseview?replied=true&id=' + caseId);
            page.setRedirect(true);
            return page;
        }
        Database.rollback(sp);
        return null;
    }
    
   	/**
   	*	template content for outbound mail
   	*/ 
    public String EmailTemplateContent{
    	get{
    		return getCaseCommentBody();	
    	}
    	set;
    }
    
    private ETownCaseComment__c getInitCaseComment()
    {
        ETownCaseComment__c result = new ETownCaseComment__c();
        List<ETownCaseComment__c> comments = [select Id, Type__c, IsDraft__c, PlainTextBody__c, CommentBody__c, UseENTemplate__c, HasSolutionMerged__c from ETownCaseComment__c where Case__c != null and Case__c = :caseId and IsDraft__c = true limit 1];
        if(comments.size() > 0)
        {
            result = comments[0];
            isExistedSolution = comments[0].HasSolutionMerged__c;
            if(isExistedSolution)
            {
                result.CommentBody__c = getCaseCommentBody();
            }
            else
            {
                String emailTemplateName = getEmailTemplateName(caseInfo.Business_Unit__c, ((isENTemplate)? 'en' : caseInfo.LanguageCode__c), isENTemplate);
                List<EmailTemplate> templates = [select Id, Subject from EmailTemplate where IsActive = true and Name = :emailTemplateName order by LastModifiedDate desc limit 1];
                emailSubject = (templates.size() > 0)? templates[0].Subject : '';
                emailSubject = emailSubject.replace('{!Case.CaseNumber}', caseInfo.CaseNumber);
            }
        }
        else
        {
            result.Type__c = 'Outbound';
            result.IsDraft__c = false;
            result.CommentBody__c = getCaseCommentBody();
        }
        result.UseENTemplate__c = isENTemplate;
        return result;
    }
    
    private static String getEmailTemplateName(String bu, String language, Boolean useEnTemplate)
    {
        String result;
        String replacedLanguage = (useEnTemplate)? 'en' : language;
        String nullConfig;
        List<TakoCaseEmailTemplateConfig__c> configs = [select Name, BU__c, TemplateName__c from TakoCaseEmailTemplateConfig__c where LanguageCode__c = :replacedLanguage];
        for(TakoCaseEmailTemplateConfig__c config : configs )
        {
            if(config.BU__c == bu)
            {
                result = config.TemplateName__c;
                break;
            }
            if(config.BU__c == null)
            {
                nullConfig = config.TemplateName__c;
            }
        }
        if(configs.size() > 0 && result == null)
        {
            result = nullConfig;
        }
        
        if(result == null)
        {
           
            List<TakoCaseEmailTemplateConfig__c> defaultConfigs = [select Id, BU__c, TemplateName__c from TakoCaseEmailTemplateConfig__c where LanguageCode__c = null];
            for(TakoCaseEmailTemplateConfig__c config : defaultConfigs)
            {
                if(config.BU__c == bu)
                {
                    result = config.TemplateName__c;
                    break;
                }
                if(config.BU__c == null)
                {
                    nullConfig = config.TemplateName__c;
                }
            }
            if(defaultConfigs.size() > 0 && result == null)
            {
                result = nullConfig;
            }
        }
        return result;
    }
    
    private String replaceMergedFields(String strBody)
    {
        String result = strBody;
        String firstName = '{!Contact.FirstName}';
        String caseNumber = '{!Case.CaseNumber}';
        String solutionDescription = '{!Case.Solution_Description}';
        String solutionAttachment = '{!Case.Solution_Attachments}';
        String latestCaseComment = '{!Case.LatestCaseComment__c}';
        String ownerFullName = '{!Case.OwnerFullName}';
        String ownerFirstName = '{!Case.OwnerFirstName}';
        String ownerLastName = '{!Case.OwnerLastName}';
        List<Case> cases = [select Id, CaseNumber, ContactId, Contact.Name, Contact.FirstName, OwnerId, Owner.Name, Owner.FirstName, Owner.LastName, (select SolutionId from CaseSolutions) from Case where Id =:caseId and ContactId != null];
        if(cases != null)
        {
            result = result.replace(firstName, (cases[0].Contact.FirstName != null) ? cases[0].Contact.FirstName : '');
            result = result.replace(ownerFullName, (cases[0].Owner.Name != null) ? cases[0].Owner.Name : '');
            result = result.replace(ownerFirstName, (cases[0].Owner.FirstName != null) ? cases[0].Owner.FirstName : '');
            result = result.replace(ownerLastName, (cases[0].Owner.LastName != null) ? cases[0].Owner.LastName : '');
            emailSubject = emailSubject.replace(caseNumber, cases[0].CaseNumber);
            result = result.replace(latestCaseComment, '');
            if(cases[0].CaseSolutions != null && cases[0].CaseSolutions.size() > 0)
            {
                isExistedSolution = true;
                String description = '';
                relatedSolutions = new Set<String>();
                for(Integer i = 0; i < cases[0].CaseSolutions.size(); i++)
                {
                    relatedSolutions.add(cases[0].CaseSolutions[i].SolutionId);
                }
                for(Solution solution : [select Id, SolutionNote from Solution where Id in :relatedSolutions order by SolutionName])
                {
                    description += solution.SolutionNote + '<br/><br/>';
                }
                result = result.replace(solutionDescription, description);
                result = result.replace(solutionAttachment, '');
            }
            else
            {
                result = result.replace(solutionDescription, '');
                result = result.replace(solutionAttachment, '');
            }
        }
        return result;
    }
    
    private String getCaseCommentBody()
    {
        String result = '';
        String language = (isENTemplate) ? 'en' : caseInfo.LanguageCode__c;
        String emailTemplateName = getEmailTemplateName(caseInfo.Business_Unit__c, language, isENTemplate);
        List<EmailTemplate> templates = [select Id, Subject, Body, HtmlValue from EmailTemplate where IsActive = true and Name = :emailTemplateName order by LastModifiedDate desc limit 1];
        if(templates.size() > 0)
        {
            emailSubject = templates[0].Subject;
            result = replaceMergedFields(templates[0].HtmlValue);
        }
        return result;
    }
    
    private List<Messaging.EmailFileAttachment> addAttachments(String caseCommentId)
    {
        List<Messaging.Emailfileattachment> result = new List<Messaging.Emailfileattachment>();
        if(isExistedSolution && relatedSolutions != null)
        {
            result.addAll(addSolutionAttachment(relatedSolutions));
        }
        result.addAll(addUploadedFileAttachment(caseCommentId));
        return result;
    }
    
    private List<Messaging.EmailFileAttachment> addUploadedFileAttachment(String caseCommentId)
    {
        List<Messaging.EmailFileAttachment> result = new List<Messaging.EmailFileAttachment>();
        for(Attachment att : [select Id, Name, Body from Attachment where ParentId = :caseCommentId])
        {
            Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
            emailAtt.setFileName(att.Name);
            emailAtt.setBody(att.Body);
            result.add(emailAtt);
        }
        return result;
    }
    
    private List<Messaging.EmailFileAttachment> addSolutionAttachment(Set<String> solutions)
    {
        List<Messaging.EmailFileAttachment> result = new List<Messaging.EmailFileAttachment>();
        for(Attachment att : [select Id, Name, Body from Attachment where ParentId in :solutions])
        {
            Messaging.EmailFileAttachment emailAtt = new Messaging.Emailfileattachment();
            emailAtt.setFileName(att.Name);
            emailAtt.setBody(att.Body);
            result.add(emailAtt);
        }
        return result;
    }
    
    private Boolean saveCommentAndUploadedFile()
    {
        Boolean result = false;
        if(saveCaseComment() && saveUploadedFile())
        {
            result = true;
        }
        return result;
    }
    
    private Boolean saveCaseComment()
    {
        Boolean result = false;
        try
        {
            if(Comment.Id == null)
            {
                Comment.Case__c = caseId;
            }
            if(isUploadFile)
            {
                Comment.HasSolutionMerged__c = false;
            }
            else if(!isUploadFile && isExistedSolution)
            {
                Comment.HasSolutionMerged__c = true;
            }
            else
            {}
            Comment.PlainTextBody__c = TakoCaseEmailHandler.convertHtmlToText(Comment.CommentBody__c);
            upsert Comment;
            commentId = Comment.Id;
            emailContent = Comment.CommentBody__c;
            commentInfo = null;
            result = true;
        }
        catch(DMLException ex)
        {
            ApexPages.addMessages(ex);
        }
        return result;
    }
    
    private Boolean saveUploadedFile()
    {
        Boolean result = false;
        if(Attach.Id == null && Attach.Body != null && Comment.Id != null)
        {
            Attach.ParentId = Comment.Id;
            try
            {
                insert Attach;
                result = true;
            }
            catch(DMLException ex)
            {
                ApexPages.addMessages(ex);
            }
        }
        return result;
    }
    
    private Boolean getSendingEmailStatus()
    {
        Boolean result = false;
        List<OrgWideEmailAddress> orgEmails = [select Id from OrgWideEmailAddress where Address = :orgEmailAddress limit 1];
        if(orgEmails.size() > 0)
        {
            try
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String emailAddress = [select Id, Email from Contact where Id = :caseInfo.ContactId limit 1].Email;
                String[] toAddresses = new String[]{ emailAddress };
                mail.setToAddresses(toAddresses);
                mail.setOrgWideEmailAddressId(orgEmails[0].Id);
                mail.setSubject(emailSubject);
                mail.setHtmlBody(emailContent);
                mail.setFileAttachments(addAttachments(commentId));
                mail.setSaveAsActivity(false);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                result = true;
            }
            catch(Exception ex)
            {
                ApexPages.addMessages(ex);
            }
        }
        return result;
    }
    
    private Boolean verifyContactInfo()
    {
        Boolean result = false;
        Contact contact = [select Id, Email, EmailBouncedReason from Contact where Id = :caseInfo.ContactId];
        if(contact.EmailBouncedReason != null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Invalid email address, please check the email of contact.'));
        }
        else if(contact.Email == null)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, 'Email address missed, please check the email of contact.'));
        }
        else
        {
            result = true;
        }
        return result;
    }
    
    @isTest
    static void testOverrideCaseViewController()
    {
        Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName='acme', Email='acme@acme.com', AccountId = account.Id);
        insert contact;
        Id studentRecordTypeId = [select Id from RecordType where Name = 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
        Case caseInfo = new Case(ContactId=contact.Id, Category__c='Others', Subcategory__c='Login', Status='New', Description='test', Origin='Email', RecordTypeId=studentRecordTypeId);
        insert caseInfo;
        List<ETownCaseComment__c> comments = new List<ETownCaseComment__c>{
                                                    new ETownCaseComment__c(Case__c=caseInfo.Id, PlainTextBody__c='acme1', Type__c='Outbound', IsDraft__c=true, HasSolutionMerged__c = true),
                                                    new ETownCaseComment__c(Case__c=caseInfo.Id, PlainTextBody__c='acme3', Type__c='Outbound', IsDraft__c=false)};
        insert comments;
        Solution solutionInfo = new Solution(Status='Status', SolutionName='Acme', SolutionNote='Acme');
        insert solutionInfo;
        Blob body = EncodingUtil.base64Decode('acme');
        List<Attachment> attachments = new List<Attachment>{
                                                new Attachment(Name='acme1', Description='acme1', Body=body, ParentId=comments[0].Id),
                                                new Attachment(Name='acme2', Description='acme2', Body=body, ParentId=solutionInfo.Id)};
        insert attachments;
        CaseSolution caseRelatedSolution = new CaseSolution(CaseId=caseInfo.Id, SolutionId=solutionInfo.Id);
        insert caseRelatedSolution;
        
        ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(caseInfo);
        OverrideCaseViewController controller = new OverrideCaseViewController(stdController);
        
        System.assert(controller.Comment != null);
        System.assert(controller.Attachments != null);
        System.assert(controller.CaseComments != null);
        controller.redirect();
        controller.uploadFile();
        controller.redirectToFindSolution();
        controller.refreshEmailTemplate();
        controller.saveInternalCase();
        controller.sendEmail();
        
    }
    
    @isTest
    static void testEmailTemplate()
    {
        List<TakoCaseEmailTemplateConfig__c> configs = new List<TakoCaseEmailTemplateConfig__c>{
                                                                new TakoCaseEmailTemplateConfig__c(Name='ruleAcme1', BU__c='LLS', TemplateName__c='EmailTemplate1', LanguageCode__c='en'),
                                                                new TakoCaseEmailTemplateConfig__c(Name='ruleAcme2', BU__c='LLS', TemplateName__c='EmailTemplate2'),
                                                                new TakoCaseEmailTemplateConfig__c(Name='ruleAcme3', TemplateName__c='EmailTemplate3')};
        insert configs;
        System.assert(OverrideCaseViewController.getEmailTemplateName('LLS', 'en', true) != null);
        System.assert(OverrideCaseViewController.getEmailTemplateName('LLS', 'en', false) != null);
        System.assert(OverrideCaseViewController.getEmailTemplateName(null, null, false) != null);
        
    }
}