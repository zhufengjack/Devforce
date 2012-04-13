trigger ContactTrigger on Contact (before insert, before update, before delete) {
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
        List<Contact> newcontact=Trigger.new;
        for(Contact con:newcontact)
        {
            if(con.Email!=null&&con.Email!='')
            {
             if(con.Email.contains('ef.com'))
            {
                List<Contact> oldcontactlist=[select Contact.LastName,Contact.Email from Contact where Contact.Email=:con.Email];
                if(oldcontactlist.size()>0)
                {
                    con.addError('This contact has existed!Please search the email to find the contact');
                
                }
            }
            }
           
        }
        }
    }
}