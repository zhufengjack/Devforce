trigger ContactSyncWithMember on Contact (after update) {
    Set<ID> updateContactIds = new Set<ID>();
    Contact oldContact;
    for(Contact newContact : Trigger.new)
    {
        oldContact = Trigger.oldMap.get(newContact.Id);
        if (newContact.EtownSyncCount__c == null
            || newContact.EtownSyncCount__c == 0
            || newContact.EtownSyncCount__c <= oldContact.EtownSyncCount__c)
        {
            updateContactIds.add(newContact.Id);
        }
    }
    if (updateContactIds.size() > 0)
    {
        //Aync call EnglishTown service
        EtownMemberInfoServiceHelper.updateMembersAsync(updateContactIds);
    }
}