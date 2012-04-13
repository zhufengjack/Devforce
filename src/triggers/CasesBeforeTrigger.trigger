trigger CasesBeforeTrigger on Case (before insert,before update) 
{
    
    
    /**
    *@auther:Jerry Hong 
    *@Date:2011-09-08
    *@function:(1): when a case was created and case recordtype is not Etown Student Case, system will assign contact field of Case automatically using the contact which email is same with current user.
    *(2): System will update case owner using current user when case status was updated
    *@function:(Chinese)(1):当Case创建的时候,如果Case 类型不是Etown Student Case,那么我们会自动为Case上的Contact字段赋值,该值为当前Case创建者.
    *(2):当Case的状态被修改的时候,自动把Case的Owner变成当前操作用户.
    */
    ////////////////////////////////////////////////////////////////////////////////////////////
    //Get Id from Customer Setting "Student Case" by Name
    StudentCase__c SCSetting01 = StudentCase__c.getInstance('Englishtown CR');
    StudentCase__c SCSetting02 = StudentCase__c.getInstance('Etown Student Case 15');
    StudentCase__c SCSetting03 = StudentCase__c.getInstance('Englishtown East Admin');
    StudentCase__c SCSetting04 = StudentCase__c.getInstance('Englishtown Central CR');
    StudentCase__c SCSetting05 = StudentCase__c.getInstance('Central CR Queue');
    StudentCase__c SCSetting06 = StudentCase__c.getInstance('East CR Queue');
    StudentCase__c SCSetting07 = StudentCase__c.getInstance('Etown Student Case 18');

    String NormalCR = SCSetting01.Id__c;
    List<StudentCase__c> NormalCRProfileIdList=[select Id__c from StudentCase__c where Type__c='CR Profile Id'];//retrive normal cr profile id
    Set<String> NormalCRProfileIds=new Set<String>();
    if(NormalCRProfileIdList.size()>0)
    {
    for(StudentCase__c studentcase:NormalCRProfileIdList)
    {
    NormalCRProfileIds.add(studentcase.Id__c);
    }
    }
    String RTid18 = SCSetting07.Id__c;  
    String RTid15 = SCSetting02.Id__c;
    String EastCrRoleId = SCSetting03.Id__c;
    String CentralCrRoleId = SCSetting04.Id__c;
    String CentralCRQueue = SCSetting05.Id__c;
    String EastCRQueue = SCSetting06.Id__c;
    integer j; //Cursor
    
    list <CaseHistory> CaseSatusHistory = new list <CaseHistory>();
    Set <Id> CaseOwnerId = new Set <Id>();
    list <User> CaseOwner = new list <User>();
    
    //Added 2011/9/14
    list <StudentCase__c> QueueList = [Select Id__c from StudentCase__c where Type__c = 'Queue'];
    set <String> CRQueue = new set <String>();
    if (QueueList.size()>0)
    {
        for (j = 0; j < QueueList.size(); j++)
        {
            CRQueue.add(QueueList[j].Id__c);
        }
    }
    //Added 2011/9/14
    /////////////////////////////////////////////////////////////////////////////////////////////
    
    
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            for(Case casenew:Trigger.new)
            {
                System.debug(casenew.CreatedById+'this is casenew created by Id');
                if(casenew.recordTypeId != RTid18 && casenew.recordTypeId != RTid15 && casenew.ContactId == null )
                {
                    String createdby=Userinfo.getUserId();
                    system.debug(createdby);
                    User usercreate=[select email from user where user.Id=:createdby];
                    String email=usercreate.Email;
                    List<Contact>contactlist=[select Id,Name from Contact where contact.Email=:email];
                    if(contactlist.size()>0)
                    {
                        Contact contact=contactlist[0];
                        casenew.ContactId=contact.id;
                    }
                    else
                    {
                        Contact newcontact=new Contact();
                        String[] emailnames=email.split('@',0);
                        String allnames=emailnames[0];
                        String[] names=allnames.split('\\.',0);
                        newcontact.Firstname=names[0];
                        newcontact.Lastname=names[1];
                        newcontact.Email=email;
                        insert newcontact;
                        casenew.ContactId=newcontact.id;
                    }
                }
            }
        }//if(Trigger.isInsert)
        
        if(Trigger.isUpdate)
        {
            /////////////////////////////////////////////////////////////////////////////////////////////
            //Added 2011/9/19
            
            //把Trigger中Case之前的状态读出来
            CaseSatusHistory = [Select CaseId, CreatedDate, OldValue 
                                from CaseHistory 
                                where CaseId IN : Trigger.oldMap.keySet() and Field='Status' 
                                order by CaseId, CreatedDate desc];
                                            
            //把Trigger中Case的New/Old Owner的Role读出来
            //CaseOwnerId.removeall();
            for (j=0;j<trigger.new.size();j++)
            {CaseOwnerId.add(trigger.new[j].OwnerId);}
            for (j=0;j<trigger.old.size();j++)
            {CaseOwnerId.add(trigger.old[j].OwnerId);}
            
            CaseOwner = [Select Id, ProfileId, UserRoleId from User where Id IN : CaseOwnerId];
            
            //把Trigger中Case的New/Old Owner的Profile读出来
                                        
            //Added 2011/9/19
            /////////////////////////////////////////////////////////////////////////////////////////////
            
            List<case> oldcases = Trigger.old;
            List<case> newcases = Trigger.new;
            for(Case oldcase : oldcases)
            {
                for(Case newcase : newcases)
                {
                    if //Auto Claim:when case status is updated and Case RecordType isn't  Etown Student Case, system need to assign case to current user
                    (
                        (oldcase.Id == newcase.Id) &&
                        (oldcase.Status != newcase.Status) &&
                        (newcase.RecordTypeId != RTid15) &&
                        (newcase.RecordTypeId != RTid18)
                    )
                    {
                        String currentuser=Userinfo.getUserId();
                        newcase.OwnerId=currentuser;
                    }
                    
                    
                    if //Update Etown Student Case Subject
                    ( 
                        (oldcase.Id == newcase.Id) && 
                        (oldcase.Category__c != newcase.Category__c) &&
                        (oldcase.Subcategory__c != newcase.Subcategory__c) && 
                        ((newcase.RecordTypeId == RTid18)||(newcase.RecordTypeId == RTid15))
                    )
                    {
                        newcase.subject = newcase.Category__c + '-' + newcase.Subcategory__c;
                    }
                    
                    
                    if  //Etown Student Case Change Owner
                    (   
                        (oldcase.Id == newcase.Id) && 
                        (oldcase.OwnerId != newcase.OwnerId) &&
                        ((newcase.RecordTypeId == RTid18)||(newcase.RecordTypeId == RTid15))
                    )
                    
                    {
                        String OwnerIdNew = newcase.OwnerId; OwnerIdNew = OwnerIdNew.substring(0,15);
                        String OwnerIdOld = oldcase.OwnerId; OwnerIdOld = OwnerIdOld.substring(0,15);
                        String OwnerRoleldOld = GetOwnerRole(OwnerIdOld); OwnerRoleldOld = OwnerRoleldOld.substring(0,15);
                        String OwnerRoleldNew = GetOwnerRole(OwnerIdNew); OwnerRoleldNew = OwnerRoleldNew.substring(0,15);
                        String OwnerProfldOld = GetOwnerProf(OwnerIdOld); OwnerProfldOld = OwnerProfldOld.substring(0,15);
                        String OwnerProfldNew = GetOwnerProf(OwnerIdNew); OwnerProfldNew = OwnerProfldNew.substring(0,15);
                        Id TempCaseId = newcase.Id;
                        String PrevStatus = GetCasePrevStatus(TempCaseId);
                         System.debug('OwnerProfldOld'+OwnerProfldOld);                       
                        //Line 1: Normal Queue --> Normal CR
                        if ((CRQueue.contains(OwnerIdOld)) && (NormalCRProfileIds.contains(OwnerProfldNew)))
                        {
                            if (newcase.Status != 'Closed')
                            {newcase.Status = 'In Progress';} 
                        }
                        
                        //Line 2: Normal CR --> Central CR Queue
                        
                        else if (NormalCRProfileIds.contains(OwnerProfldOld) && (OwnerIdNew == CentralCRQueue))
                        {newcase.Status = 'Transferred';}
                        
                        //Line 3: Normal CR --> East CR Queue
                        else if (NormalCRProfileIds.contains((OwnerProfldOld)) && (OwnerIdNew == EastCRQueue))
                        {newcase.Status = 'Transferred';}
                        
                        //Line 4: Central CR Queue --> East CR Queue: No change in Status
                        //Line 5: East CR Queue --> Central CR Queue: No change in Status
                        
                        //Line 6: Normal Queue --> Central CR Queue
                        if ((CRQueue.contains(OwnerIdOld)) && (OwnerIdNew == CentralCRQueue))
                        {newcase.Status = 'Transferred';}
                        
                        //Line 7: Normal Queue --> East CR Queue
                        if ((CRQueue.contains(OwnerIdOld)) && (OwnerIdNew == EastCRQueue))
                        {newcase.Status = 'Transferred';}
                        
                        //Line 8: Central CR Queue --> Normal CR Queue
                        if ((OwnerIdOld == CentralCRQueue) && (CRQueue.contains(OwnerIdNew)))
                        {
                            if((PrevStatus == 'New') || (PrevStatus == 'Re-opened'))
                            {newcase.Status = PrevStatus;}
                            else
                            {newcase.Status = 'New';}
                        }
                        
                        //Line 9: East CR Queue --> Normal CR Queue
                        if ((OwnerIdOld == EastCRQueue) && (CRQueue.contains(OwnerIdNew)))
                        {
                            if((PrevStatus == 'New') || (PrevStatus == 'Re-opened'))
                            {newcase.Status = PrevStatus;}
                            else
                            {newcase.Status = 'New';}
                        }
                        
                        //Line 10: Central CR Queue --> Central CR
                        if ((OwnerIdOld == CentralCRQueue) && (OwnerRoleldNew == CentralCrRoleId))
                        {newcase.Status = 'In Progress';}
                        
                        //Line 11: East CR Queue --> East CR
                        if ((OwnerIdOld == EastCRQueue) && (OwnerRoleldNew == EastCrRoleId))
                        {newcase.Status = 'In Progress';}
                        
                        //Line 12: East CR --> Normal Queue (Unclaim)                        
                        if ((String.valueof(EastCrRoleId)==String.valueof(OwnerRoleldOld)) 
                         && (CRQueue.contains(OwnerIdNew)))
                        {newcase.Status = 'Transferred Back';}
                        
                        //Line 13: Central CR --> Normal Queue (Unclaim)
                        if ((String.valueof(CentralCrRoleId)==String.valueof(OwnerRoleldOld))  
                         && (CRQueue.contains(OwnerIdNew)))
                        {newcase.Status = 'Transferred Back';}
                        
                        //Line 14 15: Normal CR --> Normal Queue 
                        //14:Inbound Email (Reopen)
                        //15:Unclaim Reassign
                        if (NormalCRProfileIds.contains(OwnerProfldOld) && 
                            (CRQueue.contains(OwnerIdNew)) &&
                            (OwnerRoleldOld != CentralCrRoleId) &&
                            (OwnerRoleldOld != EastCrRoleId))
                        {
                            if((newcase.Status == 'Closed') || (newcase.Status =='Re-opened'))
                            {
                                newcase.Status = 'Re-opened';
                            }      
                            else
                            {
                                if((PrevStatus == 'New') || (PrevStatus == 'Re-opened'))
                                {newcase.Status = PrevStatus;}
                                else
                                {newcase.Status = 'New';}
                            }
                        }
                        //Line 16: Normal CR Send a Outbound Email, Status to closed, owner not changed
 
                    } //if  //Etown Student Case Change Owner
                }
            }
        }//if(Trigger.isUpdate)
    }//if(Trigger.isBefore)

    Private String GetCasePrevStatus(Id CaseId)
    {
        integer k;
        String PrevStaus;
        PrevStaus = 'None';
        for (k=0; k<CaseSatusHistory.size(); k++)
        {
            if (CaseSatusHistory[k].CaseId == CaseId)
            {   
                PrevStaus = String.valueof(CaseSatusHistory[k].OldValue);
                break;
            }
        }
        return  PrevStaus;
    }
    
    Private String GetOwnerRole(Id OwnerId)
    {
        integer k;
        String OwnerRoleId = '000111222333444555';
        for (k=0; k<CaseOwner.size(); k++)
        {
            if (CaseOwner[k].Id == OwnerId)
            {
                OwnerRoleId = CaseOwner[k].UserRoleId;
                break;
            }
        }
        return OwnerRoleId;
    }
    
    Private String GetOwnerProf(Id OwnerId)
    {
        integer k;
        String OwnerProfId = '000111222333444555';
        for (k=0; k<CaseOwner.size(); k++)
        {
            if (CaseOwner[k].Id == OwnerId)
            {
                OwnerProfId = CaseOwner[k].ProfileId;
                break;
            }
        }
        return OwnerProfId;
    }
    
}