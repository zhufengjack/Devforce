/*
 * A controller for Contact Lookup page
 */
public with sharing class ContactLookupController
{
    private String key;
    
    public String QueryKey
    {
        get
        {
            return QueryKey;
        }
        set
        {
            QueryKey = value;
            key = formatQueryKey(value);
        }
    }
    
    public List<Contact> Contacts
    {
        get
        {
        	List<Contact> contacts = new List<Contact>();
            if(Contacts == null)
            {
                Contacts = new List<Contact>();
            }
            else
            {
                Contacts.clear();
            }
            if(key != '' && key != null)
        	{
        		contacts = [select Id, Name, Account.Name, Phone, Email, Owner.Name from Contact where Name like :key or Email like :key order by Name limit 1000];
        	}
            return contacts;
        }
        private set;
    }
    
    //Formats the queryKey to SOQL query key
    private static String formatQueryKey(String key)
    {
        if(key == null || key == '')
        {
            key = '';
        }
        else
        {
            if(key.contains('*'))
            {
                key = key.replace('*', '%');
            }
            key = '%' + key + '%';
        }
        return key;
    }
    
    public void search()
    { }
    
    @isTest
    static void testContactLookup()
    {
    	List<Account> accounts = new List<Account>();
    	for(Integer i = 0; i< 10; i++)
    	{
    		Account acc = new Account(Name='acme');
    		accounts.add(acc);
    	}
    	insert accounts;
    	List<Contact> contacts = new List<Contact>();
    	for(Integer i = 0; i < 10; i++)
 		{
 			Contact contact = new Contact(LastName='acme', AccountId=accounts[i].Id);
 			contacts.add(contact);
 		}   
 		insert contacts;
    	ContactLookupController controller = new ContactLookupController();
    	String temp;
    	controller.QueryKey = temp;
    	controller.QueryKey = 'ac*';
    	controller.search();
    	System.assert(controller.QueryKey != null);
    	System.assert(controller.Contacts.size() > 10);
    }
}