/*
* When a contact exists under an account (record type <> 'China Smart B2B'), it is not allowed to create new contact.
*/
trigger CanNotCreateNewContactForAccount on Contact (before insert, before update) 
{
    Set<String> accountIds = new Set<String>();
    Set<String> duplicateIds = new Set<String>(); // Stores duplicate id in update and insert.
    Map<String, List<Contact>> account2Contact = new Map<String, List<Contact>>();
    
    if(trigger.isInsert)
    {
        for(Contact con : trigger.new)
        {
            if(con.AccountId != null && accountIds.contains(con.AccountId)) 
            {
                duplicateIds.add(con.AccountId);
                addToMap(con.AccountId, con, account2Contact);
            }
            else if(con.AccountId != null)
            {
                accountIds.add(con.AccountId);
                addToMap(con.AccountId, con, account2Contact);
            }
        }
    }
    if(trigger.isUpdate)
    {
        for(Contact con : trigger.new)
        {
            if(con.AccountId != trigger.oldMap.get(con.Id).AccountId && con.AccountId != null)
            {
                if(accountIds.contains(con.AccountId))
                {
                    duplicateIds.add(con.AccountId);
                    addToMap(con.AccountId, con, account2Contact);
                }
                else
                {
                    accountIds.add(con.AccountId);
                    addToMap(con.AccountId, con, account2Contact);
                }
            }
        }
    }
    
    if(accountIds.size() > 0)
    {
        List<Account> accs = [select Id, Name, (select Id from Contacts limit 1) from Account where Id in :accountIds and RecordType.Name != 'China Smart B2B record type' and RecordType.Name != 'Etown Teacher account record type'];
        for(Account acc : accs)
        {
            if(acc.Contacts.size() > 0)
            {
                for(Contact con : account2Contact.get(acc.Id))
                {
                    con.addError('Can\'t create more than one contact for account "' + acc.Name + '".');
                }
            }
            else if(duplicateIds.contains(acc.Id))
            {
                for(Contact con : account2Contact.get(acc.Id))
                {
                    con.addError('Can\'t create more than one contact for account "' + acc.Name + '".');
                }
            }
        }
    }
    
    private void addToMap(String accountId, Contact con, Map<String, List<Contact>> account2ContactMap)
    {
        if(account2ContactMap.containsKey(accountId) )
        {
            account2ContactMap.get(accountId).add(con);
        }
        else
        {
            List<Contact> contacts = new List<Contact>();
            contacts.add(con);
            account2ContactMap.put(accountId, contacts);
        }
    }
}