/*
 *a public class for override convert lead 
 */
public class LeadConvertHelper 
{
    public static Opportunity matchOppForLead(Lead lead)
    {
        Opportunity matchedOpp;
        if(lead != null)
        {
            if(lead.RecordType.Name == 'China Smart Lead Record Type')
            {
                matchedOpp = matchSmartDuplicateOpp(lead);
            }
            else
            {
                List<Opportunity> opps = [select Id, OwnerId, Name, Mobile__c, Initial_Appt_Date__c, Reschedule_appt_Date__c, First_Visit__c, StageName, RecordType.Name, Location__c, Contact__c, AccountId, Account.Name, Account.OwnerId from Opportunity where StageName != 'Expired' and ((Email__c != null and Email__c = :lead.OppEmail__c) or (Mobile__c != null and Mobile__c = :lead.OppMobile__c) or (Phone2__c != null and Phone2__c = :lead.OppPhone__c)) order by LastModifiedDate desc limit 1];
                if(matchedOpp == null && opps.size() > 0)
                {
                    matchedOpp = opps[0];
                }
            }
        }
        return matchedOpp;
    }

    //called by UltraSearchController
    public static Integer getConvertMethod(String leadId)
    {
        Integer convertMethod = -1;
        List<Lead> leads = [Select Id, OppEmail__c, Partner_Ad_Channel__c, RecordTypeId, RecordType.Name, LeadSource, OppMobile__c, OppPhone__c, School_of_Interest__c, Initial_Appt_Date__c from Lead Where Id =:leadId];
        if(leads.size() > 0)
        {
            Lead lead = leads[0];
            Opportunity existingOpp = matchOppForLead(lead);
            LeadConvertConfiguration__c config = matchConfiguration(existingOpp);
            convertMethod = (config.ConvertMethod__c != null) ? config.ConvertMethod__c.IntValue() : 1;
        }
        return convertMethod;
    } 

    public static LeadConvertConfiguration__c matchConfiguration(Opportunity opp)
    {
        LeadConvertConfiguration__c matchedConfig = new LeadConvertConfiguration__c();
        if(opp != null)
        {
            String oppStage = opp.StageName;
            String oppRecordType = opp.RecordType.Name;
			Date initialApptDate = (opp.Initial_Appt_Date__c != null) ? opp.Initial_Appt_Date__c.date() : null;
            List<LeadConvertConfiguration__c> configs = [select Id, RecordType__c, ConvertMethod__c, FirstShowUp__c, RescheduleApptDate__c, InitialApptDate__c, isLeadToShowSchool__c, HasReminderEvent__c from  LeadConvertConfiguration__c where (Stage__c != null and Stage__c = :oppStage) and (RecordType__c != null and RecordType__c = :oppRecordType) order by Priority__c desc, LastModifiedDate desc];
            if(configs.size() > 0)
            {
                Boolean isLeadToShow = RemainingApptsHelper.isLeadToShowSchool(opp.Location__c);
                for(LeadConvertConfiguration__c config : configs)
                {
                   if(!isBooleanMatched(isLeadToShow, config.IsLeadToShowSchool__c))
                    {
                        continue;
                    }
                   if(config.FirstShowUp__c != null && config.RescheduleApptDate__c != null)
                    {
                     if(isDateMatched(opp.First_Visit__c, config.FirstShowUp__c) && isDateMatched(opp.Reschedule_appt_Date__c, config.RescheduleApptDate__c))
                       {
							matchedConfig = config;
                            break;
                           }
                           else{continue;}
                     }else if(config.FirstShowUp__c!=null&config.InitialApptDate__c!=null)
                             {
                              if(isDateMatched(opp.First_Visit__c, config.FirstShowUp__c) && isDateMatched(initialApptDate, config.InitialApptDate__c))
                                {
											matchedConfig = config;
	                               			break;
                                 }else{continue;}
                               }
                    else
                                  {
                                         if(!isDateMatched(opp.First_Visit__c, config.FirstShowUp__c))
                           {
                               continue;
                           }
                           if(!isDateMatched(opp.Reschedule_appt_Date__c, config.RescheduleApptDate__c))
                           {
                               continue;
                           }      
                           if(!isDateMatched(initialApptDate, config.InitialApptDate__c))
                           {
                               continue;
                           }
                                  }             
                    matchedConfig = config;
                    break;
}
            }
            else
            {
                configs = [select Id, RecordType__c, ConvertMethod__c, FirstShowUp__c, InitialApptDate__c, RescheduleApptDate__c, isLeadToShowSchool__c, HasReminderEvent__c from  LeadConvertConfiguration__c where (Stage__c != null and Stage__c = :oppStage) and (RecordType__c = null and RecordType__c != :oppRecordType) order by LastModifiedDate desc limit 1];
                if(configs.size() > 0)
                {
                    matchedConfig = configs[0];
                }
            }
        }
        return matchedConfig;
    }

    private static Boolean isBooleanMatched(Boolean source, Boolean target)
    {
        return (target == null || source == target);
    }
	
    private static Boolean isDateMatched(Date dateOnOpp, String compareLogic)
    {
    	if(compareLogic == null || compareLogic == '')
    	{
            return true;
    	}
    	else
    	{
            if(dateOnOpp == null)
            {
                return false;
            }
            Pattern p = Pattern.compile('([<>=]+)\\s*(\\d+)');
            Matcher m = p.matcher(compareLogic);
            if(m.matches() && m.groupCount() == 2)
            {
                String op = m.group(1);
                Integer num = Integer.valueOf(m.group(2));
                if(op == '=')
                {
                    return (Date.today() == dateOnOpp.addMonths(num));
                }
                else if(op == '<=')
                {
                    return (Date.today() <= dateOnOpp.addMonths(num));
                }
                else if(op == '>=')
                {
                    return (Date.today() >= dateOnOpp.addMonths(num));
                }
                else if(op == '<')
                {
                    return (Date.today() < dateOnOpp.addMonths(num));
                }
                else if(op == '>')
                {
                    return (Date.today() > dateOnOpp.addMonths(num));
                }
            }
    	}
        return false;
    }
    
    private static Opportunity matchSmartDuplicateOpp(Lead lead)
    {
        Opportunity matchedOpp;
        List<Opportunity> smartOpps = [select Id, Name, OwnerId, Mobile__c, Initial_Appt_Date__c, First_Visit__c, Reschedule_appt_Date__c, StageName, RecordType.Name, Location__c, Contact__c, AccountId, Account.Name, Account.OwnerId from Opportunity where StageName != 'Expired' and ((Mobile__c != null and Mobile__c = :lead.OppMobile__c) or (Phone2__c != null and Phone2__c = :lead.OppPhone__c)) order by LastModifiedDate desc];
        for(Opportunity opp : smartOpps)
        {
            if(opp.Mobile__c == lead.OppMobile__c)
            {
                matchedOpp = opp;
                break;
            }
        }
        if(matchedOpp == null && smartOpps.size() > 0)
        {
            matchedOpp = smartOpps[0];
        }
        return matchedOpp;
    }

    public static void createReminderEvent(Opportunity opp)
    {
        if(opp != null && opp.AccountId != null && opp.Account.OwnerId != null)
        {
            Event event = new Event();
            event.Subject = 'customer registered again';
            event.StartDateTime = getSharpTime();
            event.ReminderDateTime = getSharpTime();
            event.WhatId = opp.AccountId;
            event.DurationInMinutes = 1;
            event.Appt_Status__c = 'scheduled';
            event.IsReminderSet = true;

            User user = [select Id, IsActive, ManagerId from User where Id = :opp.Account.OwnerId];
            if(!user.IsActive && user.ManagerId != null)
            {
                event.OwnerId = user.ManagerId ;
            }
            else
            {
                event.OwnerId = user.Id;
            }
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

    private static Datetime getSharpTime()
    {
        Datetime nowTime = Datetime.now();
        Datetime sharpTime = nowTime.addSeconds(-nowTime.second());
        sharpTime = sharpTime.addMinutes(-nowTime.minute());
        sharpTime = sharpTime.addHours(2);
        return sharpTime;
    }

    public static void sendNotificationEmail(Opportunity opp)
    {
        if(opp != null && opp.AccountId != null && opp.Account.OwnerId != null)
        {
            String templateDPName;
            String address;
            User user = [select Id, Email, ManagerId,  Manager.Email, IsActive from User where Id = :opp.Account.OwnerId];
            if(user.IsActive && user.Email != null)
            {
                address = user.Email;
                templateDPName = 'notify_sales_if_a_student_registers_again';
            }
            else
            {
                if(user.ManagerId != null && user.Manager.Email != null)
                {
                    address = user.Manager.Email;
                    templateDPName = 'notify_sales_manager_if_a_sales_is_inactive';
                }
            }
            sendEmail(address, templateDPName, opp.Id);
        }
    }

    private static void sendEmail(String emailAddress, String templateDPName, Id oppId)
    {
        if(emailAddress != null && templateDPName != null)
        {
            Contact tempContact = new Contact(LastName='TempContact', Email=emailAddress);
            insert tempContact;
            List<EmailTemplate> templates =[select Id from EmailTemplate where DeveloperName = :templateDPName];
            if(templates.size() > 0)
            {
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setSaveAsActivity(false);
                mail.setSenderDisplayName('Salesforce Team');
                mail.setTargetObjectId(tempContact.Id);
                mail.setWhatId(oppId);
                mail.setTemplateId(templates[0].Id);
                try
                {
                    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });    
                    delete tempContact;
                }
                catch(Exception ex)
                {
                    delete tempContact;
                    throw(ex);
                }
            }
        }
    }

    @isTest
    static void testReminderMethod()  //contains createReminderEvnent and sendNoticicaiontEmail
    {
        User user = [select Id from User where IsActive = true and ManagerId != null limit 1];
        Account account = new Account(Name='acme', OwnerId = user.Id);
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        Opportunity opp = new Opportunity(Name='acme', Email__c='acme123456@acme.com.com.com', StageName='Close Won', CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id);
        insert opp;
        opp = [select Id, OwnerId, Mobile__c, Initial_Appt_Date__c, First_Visit__c, StageName, RecordType.Name, Location__c, Contact__c, AccountId, Account.OwnerId from Opportunity where Id =:opp.Id];
        LeadConvertHelper.createReminderEvent(opp);
        LeadConvertHelper.sendNotificationEmail(opp);
    }

    @isTest
    static void testMatchOppForLead()
    {
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        Opportunity opp = new Opportunity(Name='acme', Email__c='acme12345@acme.com.com.com', StageName='Close/Lost - No Show', CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id);
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', OppEmail__c='acme12345@acme.com.com.com');
        insert lead;
        System.assertEquals(opp.Id, LeadConvertHelper.matchOppForLead(lead).Id);

        RecordType recType = [select Id from RecordType where Name='China Smart Lead Record Type' and SobjectType='Lead'];
        lead.RecordTypeId = recType.Id;
        lead.OppMobile__c = '19912345678';
        update lead;
        lead = [select RecordType.Name, OppPhone__c, OppMobile__c from Lead where Id =:lead.Id];
        System.assertEquals(null, LeadConvertHelper.matchOppForLead(lead));

        opp.Mobile__c = '19912345678';
        update opp;
        System.assertEquals(opp.Id, LeadConvertHelper.matchOppForLead(lead).Id);
    } 

    @isTest
    static void testGetConvertMethod()
    {
        LeadConvertConfiguration__c config = new LeadConvertConfiguration__c(Name='amce004', Stage__c='Set Appt', ConvertMethod__c=4, RecordType__c='China Telesales Record Type', InitialApptDate__c='>6');
        insert config;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        RecordType recType = [select Id from RecordType where Name = 'China Telesales Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt', RecordTypeId=recType.Id, CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com', Initial_Appt_Date__c=Date.today().addMonths(-7));
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', OppEmail__c='acme@acme.com');
        insert lead;
        System.assertEquals(LeadConvertHelper.getConvertMethod(lead.Id), 4);
    }

    @isTest
    static void testIsDateInSpeicifiedMonth()
    {
        String comparedLogic = '= 1';
        Date dateOnOpp = Date.today().addMonths(-1);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));

        comparedLogic = '<= 1';
        dateOnOpp = Date.today().addMonths(-1);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));
        dateOnOpp = Date.today().addMonths(1);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));

        comparedLogic = '>= 1';
        dateOnOpp = Date.today().addMonths(-1);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));
        dateOnOpp = Date.today().addMonths(-2);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));

        comparedLogic = '< 1';
        dateOnOpp = Date.today().addMonths(2);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));

        comparedLogic = '> 1';
        dateOnOpp = Date.today().addMonths(-2);
        System.assert(LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));

        comparedLogic = '> ';
        dateOnOpp = Date.today().addMonths(-2);
        System.assert(!LeadConvertHelper.isDateMatched(dateOnOpp, comparedLogic));
    }

    @isTest
    static void testMatchConfiguration()
    {
        List<LeadConvertConfiguration__c> configs = new List<LeadConvertConfiguration__c> {
                new LeadConvertConfiguration__c(Name='amce001', isLeadToShowSchool__c=true, Stage__c='Set Appt Test', ConvertMethod__c=5, RecordType__c='China Smart Record Type', FirstShowUp__c='<=3'),
                new LeadConvertConfiguration__c(Name='amce002', isLeadToShowSchool__c=true, Stage__c='Set Appt Test', ConvertMethod__c=5, RecordType__c='China Smart Record Type', RescheduleApptDate__c='<=3'),
                new LeadConvertConfiguration__c(Name='amce003',  HasReminderEvent__c=true, ConvertMethod__c=5)};
        insert configs;
        Account account = new Account(Name='acme');
        insert account;
        Contact contact = new Contact(LastName='acme', AccountId=account.Id);
        insert contact;
        SchoolAddress__c addresse = new SchoolAddress__c(Name='SH_PSQTest', Address__c='beijing', Code__c=10, IsLeadToShowSchool__c=true);
        insert addresse;
        RecordType recType = [select Id from RecordType where Name = 'China Smart Record Type' and SobjectType='Opportunity'];
        Opportunity opp = new Opportunity(Name='acme', StageName='Set Appt Test', Location__c='SH PSQTest', CloseDate=Date.today(), AccountId=account.Id, Contact__c=contact.Id, Email__c='acme@acme.com', First_Visit__c=Date.today());
        insert opp;
        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com');
        insert lead;
        System.assertNotEquals(LeadConvertHelper.matchConfiguration(opp), null);

        opp.RecordTypeId = recType.Id;
        update opp;
        opp = [select Id, RecordType.Name, StageName, Location__c, Initial_Appt_Date__c, Reschedule_appt_Date__c, First_Visit__c from Opportunity where Id = :opp.Id];
        System.assertNotEquals(LeadConvertHelper.matchConfiguration(opp), null);

        opp.First_Visit__c = null;
        opp.Reschedule_appt_Date_Time__c = Date.today();
        update opp;
        opp = [select Id, RecordType.Name, StageName, Location__c, First_Visit__c, Initial_Appt_Date__c, Reschedule_appt_Date__c from Opportunity where Id = :opp.Id];
        System.assertNotEquals(LeadConvertHelper.matchConfiguration(opp), null);
    }
}