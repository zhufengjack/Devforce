/*
 * for Brazil actuals, if actual status is updated to 'Waiting for T&C', creates the coach event
 */
trigger createCoachEvent on Actual__c (after update)
{/*
    String BrazilActualRecordTypeId = '0124000000098gR';
    String BrazilPhoneCoachRoleId = '00E40000000rS0g'; 
    String CoachingCallRecordTypeId = '0124000000097tt';
    List<Event> events = new List<Event>();
    
    for(Actual__c actual : Trigger.new)
    {
        Actual__c oldActual = Trigger.oldMap.get(actual.Id);
        if(actual.RecordTypeId == BrazilActualRecordTypeId && actual.Status__c == 'Waiting for T&C' && oldActual.Status__c != 'Waiting for T&C')
        {           
            Event coachEvent = new Event();
            coachEvent.RecordTypeId = CoachingCallRecordTypeId;
            coachEvent.WhatId = actual.Id;
            coachEvent.Subject = 'Introductory coaching call';
            coachEvent.ActivityDate = actual.CreatedDate.addDays(7).date();
            coachEvent.ActivityDateTime = DateTime.newInstance(coachEvent.ActivityDate.year(), coachEvent.ActivityDate.month(), coachEvent.ActivityDate.day(), 7, 0, 0);
            coachEvent.DurationInMinutes = 60; 
            events.add(coachEvent);            
        }
    }
    if(!events.isEmpty())
    {
        List<User> users = [select Id from User where UserRoleId = :BrazilPhoneCoachRoleId and isActive = true order by CreatedDate];
        if(!users.isEmpty())
        {
            Map<Id, Integer> userIndexMap = new Map<Id, Integer>(); //key: userId, value: index
            Map<Integer, Id> userIndexMap2 = new Map<Integer, Id>(); //key: index, value: userid
            
            for(Integer i = 0; i < users.size(); i++)
            {
                userIndexMap.put(users[i].Id, i);
                userIndexMap2.put(i, users[i].Id);
            }
            //sets the event owner with Round Robin algorithm
            List<Event> lastEvents = [select OwnerId from Event where RecordTypeId=:CoachingCallRecordTypeId and OwnerId in :users order by CreatedDate desc limit 1];
            Integer userIndex = users.size() - 1;
            if(!lastEvents.isEmpty())
            { 
                userIndex = userIndexMap.get(lastEvents[0].OwnerId);
                if(userIndex == null)
                {
                	userIndex = users.size() - 1;
                }
                if(userIndex == users.size() - 1)
                {
                    events[0].OwnerId = users[0].Id;
                }
                else
                {                   
                    events[0].OwnerId = users[userIndex + 1].Id;
                }
            }
            else
            {
                events[0].OwnerId = users[0].Id;
            }
            Integer currentRobinIndex = userIndex + 2;
            if(events.size() > 1)
            {
                for(Integer eventIndex = 1; eventIndex < events.size(); eventIndex++)
                {
                    if(currentRobinIndex >= users.size())
                    {
                        currentRobinIndex = 0;
                    }
                    Id currentUserId = userIndexMap2.get(currentRobinIndex);
                    events[eventIndex].OwnerId = currentUserId;
                    currentRobinIndex++;
                }
            }
            insert events;
        }
    }*/
}