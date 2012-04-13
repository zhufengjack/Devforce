/*
 * controller for overrideleadconvert
 */
public class OverrideLeadConvertController
{
    private Set<String> gotoAccountProfiles = new Set<String> {
                                            'EF China Smart Booking Officer',
                                            'EF China Smart Service Supervisor',
                                            'EF China TS Telemarketing User',
                                            'EF China Telesales 800 Operator',
                                            'EF China Telesales 800 Operator Lead',
                                            'EF China NJ SSO' };

    public OverrideLeadConvertController()
    {
        LeadId = ApexPages.currentPage().getParameters().get('id');
    }

    public String LeadId { get; set; }

    public PageReference convert()
    {
        PageReference returnPage;
        Opportunity createdOpp;

        List<Lead> leads = [Select Id, OwnerId, RecordType.Name, Parent_Account__c, OppPhone__c, OppEmail__c, Partner_Ad_Channel__c, LeadSource, OppMobile__c, School_of_Interest__c, Initial_Appt_Date__c, CN_City__c, CN_Province_Name__c from Lead Where Id =:LeadId];
        if(leads.size() > 0)
        {
			Integer convertMethod;
			Lead lead = leads[0];
            Opportunity existingOpp = LeadConvertHelper.matchOppForLead(lead);
            LeadConvertConfiguration__c config = LeadConvertHelper.matchConfiguration(existingOpp);

			//List<User> users = [select Id from User where FirstName = 'TS' and LastName = 'CAAP' and IsActive = true and Id = :UserInfo.getUserId()]; //tscaap@ef.com :this user ignore all convert rule
			if(UserInfo.getFirstName() == 'TS' && UserInfo.getLastName() == 'CAAP')
			{
				convertMethod = 1;
			}
			else
			{
				convertMethod = (config.ConvertMethod__c != null) ? config.ConvertMethod__c.IntValue() : 1;
			}
            LeadConvertRule leadRule = getConvertRule(lead, existingOpp, convertMethod);
            Savepoint sp = Database.setSavepoint();
            try
            {
				TriggerContextHelper.isFired = false;
				leadRule.processConvert(); // converts lead
                createReferralInformation(lead, leadRule.CreatedAccountId);  // creates referee information
                if(config.HasReminderEvent__c)
                {
                    LeadConvertHelper.createReminderEvent(existingOpp);
                    LeadConvertHelper.sendNotificationEmail(existingOpp);
                }
                List<Opportunity> createdOpps = [select Id, Location__c, AccountId, Initial_Appt_Date__c,  Reschedule_appt_Date_Time__c, OwnerId from Opportunity where Id = :leadRule.CreatedOppId];
                if(createdOpps.size() > 0)
                {
                    createdOpp = createdOpps[0];
                    OppHandleRule oppRule = getOppHandleRule(createdOpp);
                    oppRule.handleOpp(createdOpp); // creates a new event for new opportunity
                }
                returnPage = getGotoPage(leadRule.CreatedAccountId, leadRule.CreatedOppId);
            }
            catch(Exception ex)
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Fatal, ex.getMessage()));
                if(ex.getTypeName() != 'OverrideLeadConvertController.LeadConvertCustomException')
                {
                    Database.rollback(sp);
                }
            }
        }
        return returnPage;
    }
    
    private PageReference getGotoPage(String accountId, String oppId)
    {
        PageReference returnPage = new PageReference('/001');
        String currentProfileName = [select Name from Profile where Id=:UserInfo.getProfileId() limit 1].Name;
        if((gotoAccountProfiles.contains(currentProfileName) || oppId == null) && accountId != null)
        {
            returnPage = new PageReference('/' + accountId);
        }
        else
        {
            returnPage = new PageReference('/' + oppId);
        }
        return returnPage;
    }

    private OppHandleRule getOppHandleRule(Opportunity createdOpp)
    {
        if(RemainingApptsHelper.isLeadToShowSchool(createdOpp.Location__c))
        {
            return new LeadToShowSchoolOpp();
        }
        else
        {
            return new NonLeadToShowSchoolOpp();
        }
    }

    private LeadConvertRule getConvertRule(Lead lead, Opportunity existingOpp, Integer method)
    {
        if(method == 0) //do not allow to convert
        {
            return new DoNotAllowConvert(lead, existingOpp);
        }
        else if(method == 2) //rule 2, create a new opp with account=existing account, update the owner of existing acc/contact to current user
        {
            return new LeadConvertRule2(lead, existingOpp);
        }
        else if(method == 3) //rule 3, create a new opp with account=existing account, update the owner of existing acc/contact/opps to current user
        {
            return new LeadConvertRule3(lead, existingOpp);
        }
        else if(method == 4) //rule 4, update the found opporunity
        {
            return new LeadConvertRule4(lead, existingOpp);
        }
        else if(method == 5) //rule 5
        {
            return new LeadConvertRule5(lead, existingOpp);
        }
        else // method equals 1 or other value;  rule 1, just convert the lead
        {
            return new LeadConvertRule1(lead, existingOpp);
        }
    }

    // creates referee information
    private void createReferralInformation(Lead currentLead, Id convertedAccountId)
    {
        if(currentLead != null && currentLead.Parent_Account__c != null)
        {
            Referral__c referral = new Referral__c(Referee__c = currentLead.Parent_Account__c, ReferralName__c = convertedAccountId);
            insert referral;
            update new Account(Id = convertedAccountId, ParentId = currentLead.Parent_Account__c);
        }
    }
    
    //inner class
    public abstract class OppHandleRule
    {
        public abstract void handleOpp(Opportunity opp);
    }

    public class LeadToShowSchoolOpp extends OppHandleRule
    {
        public override void handleOpp(Opportunity opp)
        {
            updateCreatedOpp(opp);
            createSaleDeomEvent(opp);
        }

        private void updateCreatedOpp(Opportunity opp)
        {
            if(opp != null)
            {
                opp.Reschedule_appt_Date_Time__c = opp.Initial_Appt_Date__c;
                try
                {
                    update opp;
                }
                catch(Exception ex)
                {
                    throw(ex);
                }
            }
        }

        private void createSaleDeomEvent(Opportunity opp)
        {
            if(opp != null)
            {
                Event event = new Event();
                event.WhatId = opp.Id;
                event.Subject =  'sales demo 1';
                event.StartDateTime = opp.Reschedule_appt_Date_Time__c;
                event.OwnerId = opp.OwnerId;
                event.DurationInMinutes = 1;
                event.Appt_Status__c = 'scheduled';
                try
                {
                    insert event;
                }
                catch(Exception ex)
                {
                    throw(ex);
                }
            }
        }
    }

    public class NonLeadToShowSchoolOpp extends OppHandleRule
    {
        public override void handleOpp(Opportunity opp) { }
    }

    public abstract class LeadConvertRule
    {
        protected Lead lead;
        protected Opportunity existingOpp;
        protected Database.Leadconvertresult lcr;

        public LeadConvertRule() { }
        public LeadConvertRule(Lead lead, Opportunity existingOpp)
        {
            this.lead = lead;
            this.existingOpp = existingOpp;
        }

        public String CreatedOppId
        {
            get
            {
                if(lcr != null && lcr.getOpportunityId() != null)
                {
                    return lcr.getOpportunityId();
                }
                else if(existingOpp != null)
                {
                    return existingOpp.Id;
                }
                return null;
            }
            set;
        }

        public String CreatedAccountId
        {
            get
            {
                if(lcr != null && lcr.getAccountId() != null)
                {
                    return lcr.getAccountId();
                }
                return null;
            }
        }

        public abstract void processConvert();

        protected void convert(Boolean isDoNotCreateAccountAndContact, Boolean isDoNotCreateOpportunity)
        {
            if(lead != null)
            {
                try
                {
                    Database.LeadConvert lc = setLeadConvertParams(isDoNotCreateAccountAndContact, isDoNotCreateOpportunity);
                    Date initialApptDate =  (lead.Initial_Appt_Date__c != null) ? lead.Initial_Appt_Date__c.date() : null;
                    checkSchoolRemainingCap(lead.School_of_Interest__c, initialApptDate);

                    Database.Leadconvertresult covertResult = Database.convertLead(lc);
                    if(covertResult.isSuccess())
                    {
                        lcr = covertResult;
                    }
                }
                catch(DmlException ex)
                {
                    throw ex;
                }
            }
        }

        protected void updateOldAccountOwner()
        {
            if(existingOpp != null && existingOpp.AccountId != null)
            {
                
	            String AccountRecordTypeId =null;
	            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
	            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
	            for(Schema.Recordtypeinfo rtinfo:RT)
	            {
	                if(rtinfo.isDefaultRecordTypeMapping()==true)
	                {
	                   AccountRecordTypeId =rtinfo.getRecordTypeId();
	                }
	            }
            	
                update new Account(Id=existingOpp.AccountId, OwnerId=lead.OwnerId,RecordTypeId=AccountRecordTypeId);
            
            } 
        }

        protected void updateOldContactOwner()
        {
        	if(existingOpp != null && existingOpp.Contact__c != null)
            {
            	String ContactRecordTypeId =null;
	            Schema.DescribeSObjectResult R = Contact.SObjectType.getDescribe();
	            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
	            for(Schema.Recordtypeinfo rtinfo:RT)
	            {
	                if(rtinfo.isDefaultRecordTypeMapping()==true)
	                {
	                   ContactRecordTypeId =rtinfo.getRecordTypeId();
	                }
	            }
                update new Contact(Id=existingOpp.Contact__c, OwnerId=lead.OwnerId,RecordTypeId=ContactRecordTypeId);
            }
        }

        protected void updateOldOppOwners()
        {
            if(existingOpp != null)
            {
                List<Opportunity> existingOpps = [select Id from Opportunity where AccountId = :existingOpp.AccountId limit 40000];
                List<Opportunity> opps = new List<Opportunity>();
                for(Opportunity opp : existingOpps)
                {
                    opp.OwnerId = lead.OwnerId;
                    opps.add(opp);
                }
                update opps;
            }
        }

        protected Database.LeadConvert setLeadConvertParams(Boolean isDoNotCreateAccountAndContact, Boolean isDoNotCreateOpportunity)
        {
            Database.LeadConvert lc = new Database.Leadconvert();
            //selects lead status value which is "Set App"
            LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted = true limit 1];
            lc.setLeadId(lead.Id);
            lc.setConvertedStatus(convertStatus.MasterLabel);
            if(isDoNotCreateAccountAndContact && existingOpp != null)
            {
                lc.setAccountId(existingOpp.AccountId);
                lc.setContactId(existingOpp.Contact__c);
            }
            if(isDoNotCreateOpportunity)
            {
                lc.setDoNotCreateOpportunity(true);
            }
            return lc;
        }

        private void checkSchoolRemainingCap(String currentSchool, Date scheduleDate)
        {
            Set<String> leadToShowProfiles = new Set<String> {
                                            'EF China Telemarketing Manager',
                                            'EF China Telemarketing User' };
            String currentProfileName = '';

            List<Profile> profiles = [select Name from Profile where Id=:UserInfo.getProfileId() limit 1];
            if(profiles.size() > 0)
            {
                currentProfileName = profiles[0].Name;
            }
            if(RemainingApptsHelper.isLeadToShowSchool(currentSchool) && (leadToShowProfiles.contains(currentProfileName)))
            {
                //isLeadToShowSchool = true;
                if(lead.Initial_Appt_Date__c != null)
                {
                    Integer remainingAppts = RemainingApptsHelper.getRemainingApptCount(currentSchool, scheduleDate);
                    if(remainingAppts <= 0)
                    {
                        throw new LeadConvertCustomException('There are no remaining appts for the school: ' + currentSchool + ' on ' + scheduleDate.format() + '.Please select another date.');
                    }
                }
                else
                {
                    throw new LeadConvertCustomException('Initial App Date: You must enter a value.');
                }
            }
        }
    }

    //do not allow to convert the lead
    public class DoNotAllowConvert extends LeadConvertRule
    {
        public DoNotAllowConvert(Lead lead, Opportunity existingOpp)
        {
            super(lead, existingOpp);
        }

        public override void processConvert()
        {
            lead.Status = 'Duplicate';
            update lead;
            throw new LeadConvertCustomException('An account has existed with the same email, mobile or phone. Account Name:<a target="_blank" href="/' + existingOpp.AccountId + '">' + existingOpp.Account.Name + '</a> Opportunity Name: <a target="_blank" href="/' + existingOpp.Id + '">' + existingOpp.Name + '</a>');
        }
    }

    //rule 1, just convert the lead
    public class LeadConvertRule1 extends LeadConvertRule
    {
        public LeadConvertRule1(Lead lead, Opportunity opp)
        {
            super(lead, opp);
        }

        public override void processConvert()
        {
            try
            {
                convert(false, false);
            }
            catch(Exception ex)
            {
                throw new LeadConvertSystemException('Error occured while converting the lead. The error message is:' + ex.getMessage());
            }
        }
    }

    //rule 2, create a new opp with account=existing account, update the owner of existing acc/contact to current user
    public class LeadConvertRule2 extends LeadConvertRule
    {
        public LeadConvertRule2(Lead lead, Opportunity existingOpp)
        {
            super(lead, existingOpp);
        }

        public override void processConvert()
        {
            try
            {
                convert(true, false);
                updateOldAccountOwner();
                updateOldContactOwner();
            }
            catch(Exception ex)
            {
                throw new LeadConvertSystemException('Error occured while converting the lead. The error message is:' + ex.getMessage());
            }
        }
    }

    //rule 3, create a new opp with account=existing account, update the owner of existing acc/contact/opps to current user
    public class LeadConvertRule3 extends LeadConvertRule
    {
        public LeadConvertRule3(Lead lead, Opportunity existingOpp)
        {
            super(lead, existingOpp);
        }

        public override void processConvert()
        {
            try
            {
                convert(true, false);
                updateOldAccountOwner();
                updateOldContactOwner();
                updateOldOppOwners();
            }
            catch(Exception ex)
            {
                throw new LeadConvertSystemException('Error occured while converting the lead. The error message is:' + ex.getMessage());
            }
        }
    }

    //rule4, update the found opporunity
    public class LeadConvertRule4 extends LeadConvertRule
    {
        public LeadConvertRule4(Lead lead, Opportunity existingOpp)
        {
            super(lead, existingOpp);
        }

        public override void processConvert()
        {
            try
            {
                convert(true, true);
                updateOldAccountOwner();
                updateOldContactOwner();
                updateExistingOpp();
            }
            catch(Exception ex)
            {
                throw new LeadConvertSystemException('Error occured while converting the lead. The error record Id: ' + ex.getDmlId(0) + '. The error message:' + ex.getMessage().replace('&quot;', '"'));
            }
        }

        private void updateExistingOpp()
        {
            update new Opportunity(Id = existingOpp.Id, Initial_Appt_Date__c = lead.Initial_Appt_Date__c, LeadSource = lead.LeadSource, Partner_Ad_Channel__c = lead.Partner_Ad_Channel__c, First_Visit__c = Date.today(), OwnerId = lead.OwnerId, CloseDate = Date.today().addMonths(3));
        }
    }

    /*
     *rule5, create a new opp
     *update existing account/contact owner to current user
     *update city and province of existing account from lead inforamtion
     *update stage of existing opp to expired
     */
    public class LeadConvertRule5 extends LeadConvertRule
    {
        public LeadConvertRule5(Lead lead, Opportunity existingOpp)
        {
            super(lead, existingOpp);
        }

        public override void processConvert()
        {
            try
            {
                convert(true, false);
                updateOldAccount();
                updateOldContactOwner();
                updateExistingOpp();
            }
            catch(Exception ex)
            {
                throw new LeadConvertSystemException('Error occured while converting the lead. The error record Id: ' + ex.getDmlId(0) + '. The error message:' + ex.getMessage().replace('&quot;', '"'));
            }
        }

        private void updateOldAccount()
        {
        		String AccountRecordTypeId =null;
	            Schema.DescribeSObjectResult R = Account.SObjectType.getDescribe();
	            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();
	            for(Schema.Recordtypeinfo rtinfo:RT)
	            {
	                if(rtinfo.isDefaultRecordTypeMapping()==true)
	                {
	                   AccountRecordTypeId =rtinfo.getRecordTypeId();
	                }
	            }
            update new Account(Id=existingOpp.AccountId, OwnerId=lead.OwnerId, CN_City__c=lead.CN_City__c, CN_Province_Name__c=lead.CN_Province_Name__c,RecordTypeId=AccountRecordTypeId);
        }

        private void updateExistingOpp()
        {
            update new Opportunity(Id=existingOpp.Id, StageName='Expired');
        }
    }

    public class LeadConvertSystemException extends Exception { }

    public class LeadConvertCustomException extends Exception { }

    @isTest
    static void testConvertRule1()
    {
        Lead otherLead = new Lead(lastName='testName', company='testCompany' );
        insert otherLead;
        Appt_Max_target__c testTarget = new Appt_Max_target__c(Max_target__c = 100, School__c = 'SH PSQ', Date__c =  DateTime.now().dateGmt());
        insert testTarget;
        PageReference testPage = new PageReference('/apex/overrideleadconvert?id=' + otherLead.Id);
        Test.setCurrentPage(testPage);
        OverrideLeadConvertController controller = new OverrideLeadConvertController();
        PageReference opptPage = controller.convert();
        //uses converted lead to test DmlException
        PageReference opptPageNull = controller.convert();
        system.assert(opptPageNull == null);

        SchoolAddress__c addresse = new SchoolAddress__c(Name = 'SH_PSQTest', Address__c = 'beijing', Code__c = 10, IsLeadToShowSchool__c = true);
        insert addresse;
        Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 5, School__c = 'SH PSQTest', Date__c = date.today());
        insert testTarget1;
        Profile p = [select Id from Profile where Name='EF China Telemarketing Manager' limit 1];
        User u = [select Id from User where profileId= :p.Id and IsActive = true limit 1];
        system.runAs(u)
        {
            Lead shanghaiLead = new Lead(lastName = 'testNameSH', company = 'testCompanySH', CN_Province_Name__c = 'cn_sh', CN_City__c = 'Shanghai', School_of_Interest__c = 'SH PSQTest', Initial_Appt_Date__c = DateTime.now());
            insert shanghaiLead;
            system.assertEquals(UserInfo.getProfileId(), p.Id);
            testPage = new PageReference('/apex/overrideleadcovert?id=' + shanghaiLead.Id);
            Test.setCurrentPage(testPage);
            controller = new OverrideLeadConvertController();
            opptPage = controller.convert();
        }
        
        Account account = new Account(Name='acme');
        insert account;
        Lead shanghaiLeadForReferral = new Lead(lastName = 'testNameSH', Parent_Account__c = account.Id, Partner_Ad_Channel__c = 'Referral', company = 'testCompanySH', CN_Province_Name__c = 'cn_sh', CN_City__c = 'Shanghai', School_of_Interest__c = 'SH PSQTest', SH_Marketing__c = 'Referral Program (推荐奖励计划)', Initial_Appt_Date__c = DateTime.now());
        insert shanghaiLeadForReferral;
        testPage = new PageReference('/apex/overrideleadcovert?id=' + shanghaiLeadForReferral.Id);
        Test.setCurrentPage(testPage);
        controller = new OverrideLeadConvertController();
        opptPage = controller.convert();
    }

    @isTest
    static void testConvertRule2()
    {
        Profile p = [select Id from Profile where Name='EF China Smart Booking Officer' limit 1];
        User u = [select Id from User where profileId= :p.Id and IsActive = true limit 1];
        LeadConvertConfiguration__c config = new LeadConvertConfiguration__c(Name='amce002', Stage__c='Close/Lost - No Show Acme',  RecordType__c='Brazil Sales Record Type', ConvertMethod__c=2, HasReminderEvent__c=true);
        insert config;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        RecordType recType = [select Id from RecordType where Name = 'Brazil Sales Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Close/Lost - No Show Acme', CloseDate=Date.today(), RecordTypeId=recType.Id, AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com');
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com', Status='Set Appt');
        insert lead;
        PageReference page = new PageReference('/apex/overrideleadconvert?id=' + lead.Id);
        Test.setCurrentPage(page);
        OverrideLeadConvertController controller = new OverrideLeadConvertController();
        PageReference opptPage = controller.convert();
    }

    @isTest
    static void testConvertRule3()
    {
        LeadConvertConfiguration__c config = new LeadConvertConfiguration__c(Name='amce003', Stage__c='Close/Lost - No Show Acme', ConvertMethod__c=3, RecordType__c='Taiwan Sales Record Type', InitialApptDate__c='>3');
        insert config;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        RecordType recType = [select Id from RecordType where Name = 'Taiwan Sales Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Close/Lost - No Show Acme', RecordTypeId=recType.Id, CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com', Initial_Appt_Date__c=Date.today().addMonths(-4));
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com');
        insert lead;
        PageReference page = new PageReference('/apex/overrideleadconvert?id=' + lead.Id);
        Test.setCurrentPage(page);
        OverrideLeadConvertController controller = new OverrideLeadConvertController();
        PageReference opptPage = controller.convert();
    }

    @isTest
    static void testConvertRule4()
    {
        LeadConvertConfiguration__c config = new LeadConvertConfiguration__c(Name='amce004', Stage__c='Set Appt Acme', ConvertMethod__c=4, RecordType__c='China Telesales Record Type', InitialApptDate__c='>6');
        insert config;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        RecordType recType = [select Id from RecordType where Name = 'China Telesales Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt Acme', RecordTypeId=recType.Id, CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com', Initial_Appt_Date__c=Date.today().addMonths(-7));
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com');
        insert lead;
        PageReference page = new PageReference('/apex/overrideleadconvert?id=' + lead.Id);
        Test.setCurrentPage(page);
        OverrideLeadConvertController controller = new OverrideLeadConvertController();
        PageReference opptPage = controller.convert();
    }

    @isTest
    static void testConvertRule5()
    {
        List<LeadConvertConfiguration__c> configs = new List<LeadConvertConfiguration__c> {
                new LeadConvertConfiguration__c(Name='amce005', isLeadToShowSchool__c=true, Stage__c='Set Appt Acme', ConvertMethod__c=5, RecordType__c='China Smart Record Type', FirstShowUp__c='<=3'),
                new LeadConvertConfiguration__c(Name='amce006', HasReminderEvent__c=true, ConvertMethod__c=5)};
        insert configs;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        SchoolAddress__c addresse = new SchoolAddress__c(Name='SH_PSQTest', Address__c='beijing', Code__c=10, IsLeadToShowSchool__c=true);
        insert addresse;
        RecordType recType = [select Id from RecordType where Name = 'China Smart Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt Acme', Location__c='SH PSQTest', RecordTypeId=recType.Id, CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com', First_Visit__c=Date.today());
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com');
        insert lead;
        PageReference page = new PageReference('/apex/overrideleadconvert?id=' + lead.Id);
        Test.setCurrentPage(page);
        OverrideLeadConvertController controller = new OverrideLeadConvertController();
        PageReference opptPage = controller.convert();
        opp.StageName = 'Closed Won';
        update opp;
        opptPage = controller.convert();
    }
}