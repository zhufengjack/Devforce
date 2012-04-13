/*
 * To be called by CopyCaseEmailToCustomCaseComment trigger
 */
public class CopyCaseEmailToCustomCaseComment 
{
	@future
	public static void copyEmailData(Set<Id> eMessageIds)
	{
		Map<Id, ETownCaseComment__c> eMessageId2Comment = new Map<Id, ETownCaseComment__c>();
		Map<Id, List<Attachment>> eMessageId2Attachments = new Map<Id, List<Attachment>>();
		List<ETownCaseComment__c> caseComments = new List<ETownCaseComment__c>();
		List<Attachment> createdAttachments = new List<Attachment>();
		
		List<EmailMessage> eMessages = [select Id, ParentId, HtmlBody from EmailMessage where Id in :eMessageIds];
		
		for(EmailMessage eMessage : eMessages)
		{
			List<Attachment> tempAttachs = new List<Attachment>();
			for(Attachment attach : [select Id, OwnerId, Name, Description, ContentType, Body, ParentId from Attachment where ParentId in :eMessageIds])
			{
				if(attach.ParentId == eMessage.Id)
				{
					tempAttachs.add(attach);
				}
			}
			eMessageId2Attachments.put(eMessage.Id, tempAttachs);
		}
		
		for(EmailMessage eMessage : eMessages)
		{
			ETownCaseComment__c caseComment = new ETownCaseComment__c();
			caseComment.Type__c = 'OutBound';
			caseComment.Case__c = eMessage.ParentId;
			caseComment.CommentBody__c = (eMessage.HtmlBody != null) ? eMessage.HtmlBody.replace('<style>p{margin-top:0px; margin-bottom:0px;}</style>', '') : eMessage.HtmlBody;
			
			eMessageId2Comment.put(eMessage.Id, caseComment);
			caseComments.add(caseComment);
		}
		
		try
		{
			insert caseComments;
		}
		catch(Exception ex)
		{
			throw(ex);
		}
		
		for(EmailMessage eMessage : eMessages)
		{
			List<Attachment> oneEmailAttachs = eMessageId2Attachments.get(eMessage.Id);
			ETownCaseComment__c comment = eMessageId2Comment.get(eMessage.Id);
			for(Attachment oneEmailAttach : oneEmailattachs)
			{
				Attachment ac = oneEmailAttach.clone(false, true); 
				ac.ParentId = comment.Id;
				createdAttachments.add(ac);
			}
		}		
		
		try
		{
			insert createdAttachments;
		}
		catch(Exception ex)
		{
			throw(ex);
		}
	}
	
	@isTest
	static void testCopyEmailData()
	{
		Contact contact = new Contact(LastName='acme', Email='acme@acme.com');
		insert contact;
		Id recordTypeId = [select Id from RecordType where Name = 'ETown Student Case' and SObjectType = 'Case' limit 1].Id;
		Case caseInfo = new Case(Category__c = 'Others', Subcategory__c = 'Login', Status = 'New', Description = 'test', Origin = 'Email', RecordTypeId = recordTypeId, ContactId = contact.Id);
		insert caseInfo;
		List<EmailMessage> emails = new List<EmailMessage>{
															  new EmailMessage(Subject = 'acme', FromAddress = 'acme@acme.com', ParentId = caseInfo.Id, HtmlBody = 'acme'),
															  new EmailMessage(Subject = 'acme', FromAddress = 'acme@amce.com', ParentId = caseInfo.Id)
															};
		insert emails;
		Blob body = EncodingUtil.base64Decode('acme');
		Attachment attachment = new Attachment(Name = 'acme', Description = 'acme', Body = body, ParentId = emails[0].Id);
		insert attachment;
		Set<Id> Ids = new Set<Id>{ emails[0].Id, emails[1].Id};
		CopyCaseEmailToCustomCaseComment.copyEmailData(Ids);
	}
}