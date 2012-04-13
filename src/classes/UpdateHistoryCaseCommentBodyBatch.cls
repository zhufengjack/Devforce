global class UpdateHistoryCaseCommentBodyBatch implements Database.Batchable<sObject>
{
	Datetime previousVersionDeployDate = Datetime.newInstance(2011, 9, 14, 17, 0, 0);
	public String queryString = 'select Id, PlainTextBody__c, CommentBody__c from ETownCaseComment__c where CreatedDate >:previousVersionDeployDate and Type__c != \'Inbound\'';
	
    global Database.QueryLocator start(Database.BatchableContext bc)
    {
    	Date currentDay = Date.today();
    	return Database.getQueryLocator(queryString); 
    }
    
    global void execute(Database.BatchableContext BC, List<ETownCaseComment__c> comments)
    {
		List<ETownCaseComment__c> updatedComments = new List<ETownCaseComment__c>();
		String updatedIds = '';
		for(ETownCaseComment__c c : comments)
		{
		    if(c.PlainTextBody__c == null && c.CommentBody__c != null)
		    {
		        c.PlainTextBody__c = convertHtmlToText(c.CommentBody__c);
		        updatedIds += c.Id + '\n';
		        updatedComments.add(c);
		    }
		}
		try
		{
		    update updatedComments;
		    //SendEmailHelper.sendSimpleEmail(new String[] { 'jair.zheng@meginfo.com' }, 'update old case comment', updatedIds); 
		    generateDocument('update old case comment', updatedIds);
		}
		catch(Exception ex)
		{
		    throw(ex);
		}
	}
	
	private void generateDocument(String documentName, String documentBody)
    {
        if(documentBody != null)
        {
            Folder publicFolder = [select Id, Name from Folder where Name = 'Public'];
            Document doc = new Document(Name = documentName , FolderId = publicFolder.Id);
            String result = '';
            Datetime nowTime = Datetime.now();
            String dateString = nowTime.format();
            String GMTDateString = nowTime.dateGMT() + ' ' + nowTime.timeGmt();
            result = result + '\r\nDatetime: ' + dateString + ' Datetime(GMT): ' + GMTDateString + '\r\n';
            result = result + documentBody;
            doc.Body = Blob.valueOf(result);
            insert doc;
        }
    }
	
	global void finish(Database.BatchableContext BC)
    {
    	
    }
    
    public  String convertHtmlToText(String htmlBody)
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
        result = result.replaceAll('•', ' * ');        
        result = result.replaceAll('‹', '<');
        result = result.replaceAll('›', '>');
        result = result.replaceAll('™', '(tm)');
        result = result.replaceAll('⁄', '/');
        result = result.replaceAll('<', '<');
        result = result.replaceAll('>', '>');
        result = result.replaceAll('©', '(c)');    
        result = result.replaceAll('®', '(r)');
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
    
	@isTest
	static void testUpdateHistoryCaseCommentBodyBatch()
	{
		Account account = new Account(Name = 'acme');
        insert account;
        Contact contact = new Contact(LastName='acme', Email='acme@acme.com', AccountId = account.Id);
        insert contact;
        Id studentRecordTypeId = [select Id from RecordType where Name = 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
        Case caseInfo = new Case(ContactId=contact.Id, Category__c='Others', Subcategory__c='Login', Status='New', Description='test', Origin='Email', RecordTypeId=studentRecordTypeId);
        insert caseInfo;
        List<ETownCaseComment__c> comments = new List<ETownCaseComment__c>{
                                                    new ETownCaseComment__c(Case__c=caseInfo.Id, CommentBody__c='acme1', Type__c='Outbound', IsDraft__c=true, HasSolutionMerged__c = true),
                                                    new ETownCaseComment__c(Case__c=caseInfo.Id, CommentBody__c='acme3', Type__c='Outbound', IsDraft__c=false)};
        insert comments;
		Test.startTest();
        UpdateHistoryCaseCommentBodyBatch batch = new UpdateHistoryCaseCommentBodyBatch();
        batch.queryString = 'select Id, PlainTextBody__c, CommentBody__c from ETownCaseComment__c where Case__c = \'' + caseInfo.Id +'\'';
        Database.executeBatch(batch);
        Test.stopTest();    
	}
}