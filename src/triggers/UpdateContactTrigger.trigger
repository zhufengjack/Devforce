trigger UpdateContactTrigger on Account(after update){
    for(Account acc: Trigger.New){
            List<Contact> conList=[Select c.id, c.Email, c.Phone, c.MobilePhone from Contact c where c.AccountId=: acc.Id];
            if(conList.size()==1){
                conList[0].Email=acc.Email__c;
                conList[0].Phone=acc.Phone;
                conList[0].MobilePhone =acc.Mobile__c;
                update conList;
            }
    }
}