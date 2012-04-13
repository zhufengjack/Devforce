/*
 *A WebService class, called by CCMS(call center)
 */
global class CCMSCallService
{
    private static Id recordTypeId;
    private static String[] EventResults;
    public enum SobjectName { Opportunity, Lead }

    webservice static String[] createCallActivity(String JSONContent)
    {
        EventParameters eventParameter = new EventParameters();
        EventResults = new String[] {'1', 'SUCCEED'};
        initRecordTypeId();
        List<EventParameters> eventsParams = new List<EventParameters>();
        try
        {
            eventsParams = (List<EventParameters>)System.JSON.deserialize(JSONContent, List<EventParameters>.class);
        }
        catch(Exception ex)
        {
            EventResults[0] = '0';
            EventResults[1] = 'The format of JSON is incorrect. Error message : ' + ex.getMessage();
        }
        if(eventsParams.size() > 0)
        {
            EventResults[0] = '1';
            EventResults[1] = '';
            Integer successCount = 0;
            List<Event> insertingEvents = getInsertingEvents(eventsParams);
            if(insertingEvents.size() > 0)
            {
                Database.SaveResult[] results = Database.insert(insertingEvents, false); //insert insertingEvents;
                for(Integer i = 0; i < results.size(); i++)
                {
                    if(!results[i].isSuccess())
                    {
                        Database.Error error = results[i].getErrors()[0];
                        String errorUniqueId = insertingEvents[i].UniqueId__c;
                        EventResults[1] += 'Unique Id :' + errorUniqueId + ' , Faild information: ' +  String.valueOf(error) + '.\r\n';
                    }
                    else
                    {
                        successCount++;
                    }
                }
                EventResults[1] += 'You have succeeded in inserting ' + successCount + ' records.';
            }
        }
        return EventResults;
    }

    private static Map<Id, Id> getObjectIdsHaveConverted(Set<Id> objectIds)   //key:Lead Id, value: opp Id
    {
        Map<Id, Id> result = new Map<Id, Id>();
        if(objectIds.size() > 0)
        {
            for(Lead lead : [select Id, ConvertedOpportunityId from Lead where IsConverted = true and  ConvertedOpportunityId != null and Id in : objectIds])
            {
                result.put(lead.Id, lead.ConvertedOpportunityId);
            }
        }
        return result;
    }

    private static Set<String> getExistenceUniqueIds(Set<String> uniqueCallIds)
    {
        Set<String> result = new Set<String>();
        if(uniqueCallIds.size() > 0)
        {
            for(Event event : [select Id, UniqueId__c from Event where UniqueId__c in :uniqueCallIds])
            {
                result.add(event.UniqueId__c);
            }
        }
        return result;
    }

    private static void initRecordTypeId()
    {
        List<RecordType> recordTypes = [select Id from RecordType where Name = 'Call' and SobjectType = 'Event' limit 1];
        if(recordTypes.size() > 0)
        {
            recordTypeId = recordTypes[0].Id;
        }
    }

    private static List<Event> getInsertingEvents(List<EventParameters> eventsParams)
    {
        List<Event> result = new List<Event>();
        Set<Id> objectIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> leadIds = new Set<Id>();
        Set<String> uniqueIds = new Set<String>();
        Boolean isHaveNullUniqueId = getAllIds(eventsParams, objectIds, oppIds, leadIds, uniqueIds);
        if(!isHaveNullUniqueId)
        {
            Map<Id, Id> leadIdToConvertedOppId = getObjectIdsHaveConverted(objectIds);
            Map<Id, Integer> oppIdToMaxIndex = getOppIdToMaxIndex(oppIds, 'Opp Call %');
            Set<Id> convertedOppIds = new Set<Id>();
            convertedOppIds.addAll(leadIdToConvertedOppId.values());
            Map<Id, Integer> generatedOppIdToMaxIndex = getOppIdToMaxIndex(convertedOppIds, 'Leads Call %');
            Map<Id, Integer> leadIdToMaxIndex = getLeadIdToMaxIndex(leadIds);
            Set<String> existenceUniqueIds = getExistenceUniqueIds(uniqueIds);
            for(EventParameters params : eventsParams)
            {
                if(!existenceUniqueIds.contains(params.uniqueId))
                {
                    String subject = '';
                    Integer index = 1;
                    Id whatId = null;
                    Id whoId = null;
                    if(params.objectId instanceOf Id)
                    {
                        if(params.currentUserId instanceOf Id)
                        {
                            if(oppIds.contains(params.objectId))
                            {
                                whatId = params.objectId;
                                index = getLastIndex(oppIdToMaxIndex, whatId);
                                subject = 'Opp Call ' + index;
                            }
                            else
                            {
                                if(leadIdToConvertedOppId.containsKey(params.objectId))
                                {
                                    whatId = leadIdToConvertedOppId.get(params.objectId);
                                    index = getLastIndex(generatedOppIdToMaxIndex, whatId);
                                }
                                else
                                {
                                    whoId = params.objectId;
                                    index = getLastIndex(leadIdToMaxIndex, whoId);
                                }
                                subject = 'Leads Call ' + index;
                            }
                            result.add(createEvent(subject, params, whatId, whoId));
                        }
                        else
                        {
                            EventResults[1] += 'Unique Id :' + params.uniqueId + ' , Faild information, Invalid UserId :' + params.currentUserId +  '.\r\n';
                        }
                    }
                    else
                    {
                        EventResults[1] += 'Unique Id :' + params.uniqueId + ' , Faild information, Invalid objectId :' + params.objectId +  '.\r\n';
                    }
                }
            }
        }
        return result;
    }

    private static Integer getLastIndex(Map<Id, Integer> idToLastIndexMap, Id objectId)
    {
        Integer lastIndex = 1;
        if(idToLastIndexMap != null && objectId != null)
        {
            if(idToLastIndexMap.containsKey(objectId))
            {
                lastIndex = idToLastIndexMap.get(objectId) + 1;
                idToLastIndexMap.remove(objectId);
                idToLastIndexMap.put(objectId, lastIndex);
            }
            else
            {
                idToLastIndexMap.put(objectId, lastIndex);
            }
            idToLastIndexMap.put(objectId, lastIndex);
        }
        return lastIndex;
    }

    private static Event createEvent(String subject, EventParameters params, Id whatId, Id whoId)
    {
        Event event = new Event();
        if(params != null)
        {
            event.WhoId = whoId;
            event.WhatId = whatId;
            event.Subject = subject;
            event.OwnerId = params.currentUserId;
            event.RecordTypeId = recordTypeId;
            event.ActivityDate = Date.today();
            event.UniqueId__c = params.uniqueId;
            event.StartDateTime = params.callStartTime;
            event.CallDuration__c = params.duration;
            event.DurationInMinutes = (params.duration != null) ? (Integer.valueOf(params.duration/60) + 1) : 0;
            if(params.isConnected  == 1)
            {
                event.CallStatus__c = 'SUCCEED';
            }
            else
            {
                event.CallStatus__c = params.unConnectedReason;
            }
        }
        return event;
    }

    private static Boolean getAllIds(List<EventParameters> eventsParams, Set<Id> objectIds, Set<Id> oppIds, Set<Id> leadIds, Set<String> uniqueIds)
    {
        Boolean result = false;
        for(EventParameters param : eventsParams)
        {
            if(param.objectId instanceOf Id)
            {
                objectIds.add(param.objectId);
                SobjectName objectName = checkoutObjectIsOppOrLead(param.objectId);
                if(objectName == SobjectName.Opportunity)
                {
                    oppIds.add(param.objectId);
                }
                else
                {
                    leadIds.add(param.objectId);
                }
            }
            if(param.uniqueId == '' || param.uniqueId == null)
            {
                result = true;
                EventResults[0] = '0';
                EventResults[1] += 'JOSN has null uniqueId, please check and send again.';
            }
            else
            {
                uniqueIds.add(param.uniqueId);
            }
        }
        return result;
    }

    //gets all opps' max subject last index and generated leads' max subject last index
    private static Map<Id, Integer> getOppIdToMaxIndex(Set<Id> oppIds, String subject)
    {
        Map<Id, Integer> result = new Map<Id, Integer>();
        List<Opportunity> opps = [select Id, (select Id, Subject, WhatId, WhoId from Events where Subject like 'Leads Call %' and UniqueId__c != '' and RecordTypeId = :recordTypeId order by CreatedDate desc, Subject desc limit 1) from Opportunity where Id in : oppIds];
        for(Opportunity opp : opps)
        {
            if(opp.Events.size() > 0)
            {
                Integer lastIndex = 1;
                if(opp.Events[0].Subject.lastIndexOf(' ') != -1)
                {
                    lastIndex =  Integer.valueof(opp.Events[0].Subject.substring(opp.Events[0].Subject.lastIndexOf(' ') + 1));
                }
                result.put(opp.Id, lastIndex);
            }
        }
        return result;
    }

    //gets all leads' max subject last index
    private static Map<Id, Integer> getLeadIdToMaxIndex(Set<Id> leadIds)
    {
        Map<Id, Integer> result = new Map<Id, Integer>();
        List<Lead> leads = [select Id, (select Id, Subject, WhatId, WhoId from Events where Subject like 'Leads Call %' and UniqueId__c != '' and RecordTypeId = :recordTypeId order by CreatedDate desc, Subject desc limit 1) from Lead where Id in : leadIds];
        for(Lead lead : leads)
        {
            if(lead.Events.size() > 0)
            {
                Integer lastIndex = 1;
                if(lead.Events[0].Subject.lastIndexOf(' ') != -1)
                {
                    lastIndex =  Integer.valueof(lead.Events[0].Subject.substring(lead.Events[0].Subject.lastIndexOf(' ') + 1));
                }
                result.put(lead.Id, lastIndex);
            }
        }
        return result;
    }

    private static SobjectName checkoutObjectIsOppOrLead(String objectId)
    {
        SobjectName result = SobjectName.Lead;
        String subObjectId = objectId.substring(0, 3);
        if(subObjectId == '006')
        {
            result = SobjectName.Opportunity;
        }
        return result;
    }

    public class EventParameters
    {
        public String objectId;
        public String currentUserId;
        public Integer isConnected;
        public String unConnectedReason;
        public DateTime callStartTime;
        public DateTime callEndTime;
        public Integer duration;
        public String uniqueId;
    }

    @isTest
    static void testCCMSCallService()
    {
        Id testRecordTypeId = null;
        List<RecordType> testRecordTypes = [select Id from RecordType where Name = 'Call' and SobjectType = 'Event' limit 1];
        if(testRecordTypes.size() > 0)
        {
            testRecordTypeId = testRecordTypes[0].Id;
        }
        User user = [select Id from User where IsActive = true and ProfileId='00e90000000UVtx'limit 1];
        Opportunity opp = new Opportunity(Location__c = 'B2B BJ', Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
        insert opp;
        Event event = new Event();
        event.Subject = 'Opp Call 1';
        event.OwnerId = user.Id;
        event.RecordTypeId = testRecordTypeId;
        event.WhatId = opp.Id;
        event.DurationInMinutes = 1;
        event.ActivityDate = Date.today();
        event.ActivityDateTime = DateTime.now();
        event.UniqueId__c = '123456789';

        Event event3 = new Event();
        event3.Subject = 'Opp Call 2';
        event3.OwnerId = user.Id;
        event3.RecordTypeId = testRecordTypeId;
        event3.WhatId = opp.Id;
        event3.DurationInMinutes = 1;
        event3.ActivityDate = Date.today();
        event3.ActivityDateTime = DateTime.now();
        event3.UniqueId__c = '1234567893333';

        Lead lead = new Lead(lastName='testName', company='testCompany', Email='acme@acme.com');
        insert lead;
        Event event2 = new Event();
        event2.Subject = 'Leads Call 1';
        event2.OwnerId = user.Id;
        event2.RecordTypeId = testRecordTypeId;
        event2.WhoId = lead.Id;
        event2.DurationInMinutes = 1;
        event2.ActivityDate = Date.today();
        event2.ActivityDateTime = DateTime.now();
        event2.UniqueId__c = '12345678900';

        Lead lead1 = new Lead(lastName='testName1', company='testCompany1', Email='acme@im.com');
        insert lead1;
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(lead1.Id);
        LeadStatus convertStatus = [select Id, MasterLabel from LeadStatus WHERE IsConverted = true limit 1];
        lc.setConvertedStatus(convertStatus.MasterLabel);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        System.assert(lcr.isSuccess());
        Event event5 = new Event();
        event5.Subject = 'opp Call 3';
        event5.OwnerId = user.Id;
        event5.RecordTypeId = testRecordTypeId;
        event5.WhatId = lcr.getOpportunityId();
        event5.DurationInMinutes = 1;
        event5.ActivityDate = Date.today();
        event5.ActivityDateTime = DateTime.now();
        event5.UniqueId__c = '1234567890231';

        Event event4 = new Event();
        event4.Subject = 'Leads Call 3';
        event4.OwnerId = user.Id;
        event4.RecordTypeId = testRecordTypeId;
        event4.WhoId = lead.Id;
        event4.DurationInMinutes = 1;
        event4.ActivityDate = Date.today();
        event4.ActivityDateTime = DateTime.now();
        event4.UniqueId__c = '123456789002222';
        insert new List<Event>{event, event2, event3, event4, event5};

        String serviceInfo = '[{"objectId":"'+ opp.Id +'","currentUserId":"'+ user.Id +'","isConnected":"0","unConnectedReason":"busy","callStartTime":"2012-01-10T02:15:11Z","callEndTime":"2012-01-13T03:07:42Z","duration":"255","uniqueId":"137565650.911156566"},{"objectId":"'+ lead1.Id +'","currentUserId":"'+ user.Id +'","isConnected":"0","unConnectedReason":"busy","callStartTime":"2012-01-10T02:15:11Z","callEndTime":"2012-01-13T03:07:42Z","duration":"255","uniqueId":"137650.911156566"},{"objectId":"'+ lead.Id +'","currentUserId":"'+ user.Id +'","isConnected":"0","unConnectedReason":"ANSWERED","callStartTime":"2012-01-10T02:20:48Z","callEndTime":"2012-01-13T03:07:42Z","duration":"304","uniqueId":"1207.599"}]';
        String[] results = CCMSCallService.createCallActivity(serviceInfo);
        String[] results2 = CCMSCallService.createCallActivity('[{"objectId":"00590000000a4bVAAQ","currentUserId":"005400000017Jtj","isConnected":"0","unConnectedReason":"busy","callStartTime":"2012-01-10T02:15:11Z","callEndTime":"2012-01-13T03:07:42Z","duration":"255","uniqueId":"1370.911166"},{"objectId":"00QO000ty9HMAQ","currentUserId":"00590000000a4bVAAQ","isConnected":"0","unConnectedReason":"busy","callStartTime":"2012-01-10T02:11:46Z","callEndTime":"2012-01-13T03:07:42Z","duration":"240","uniqueId":"1306.41"}]"');
    }

}