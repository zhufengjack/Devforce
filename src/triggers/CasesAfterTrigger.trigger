trigger CasesAfterTrigger on Case (after update)
{
    List<case> oldcases = Trigger.old;
    List<case> newcases = Trigger.new;
    Boolean isChanged = false;
    
    
    for(Case oldcase : oldcases)
    {
        for(Case newcase : newcases)
        {
            if (
                (oldcase.Id == newcase.Id) && 
                (newcase.Status != oldcase.Status)
                )
            {
                isChanged =true; 
                break;
            }
        }
    }
    
    if((Trigger.isUpdate) && (isChanged == true))
    {
        StudentCase__c SCSettingA = StudentCase__c.getInstance('Etown Student Case 15');
        StudentCase__c SCSettingB = StudentCase__c.getInstance('Etown Student Case 18');
        StudentCase__c SCSettingC = StudentCase__c.getInstance('Central CR Queue');
        StudentCase__c SCSettingD = StudentCase__c.getInstance('East CR Queue');
        
        String RTid18 = SCSettingB.Id__c;   
        String RTid15 = SCSettingA.Id__c;
        String CentralCRQueue = SCSettingC.Id__c;
        String EastCRQueue = SCSettingD.Id__c;
        
        for(Case oldcase : oldcases)
            {
                for(Case newcase : newcases)
                {
                    String TiggerRTId = newcase.RecordTypeId;
                    String OwnerIdNew = newcase.OwnerId; OwnerIdNew = OwnerIdNew.substring(0,15);
                    String OwnerIdOld = oldcase.OwnerId; OwnerIdOld = OwnerIdOld.substring(0,15);
                        
                    if  //Transfer Rate Reporting
                    (
                        (oldcase.Id == newcase.Id) && 
                        (newcase.Status == 'Closed') &&
                        (newcase.Status != oldcase.Status) &&
                        (newcase.Origin == 'Phone Case')&& 
                        ((TiggerRTId == RTid18)||(TiggerRTId == RTid15))
                    )
                    {
                    	Integer  totalcomments=[select count() from ETownCaseComment__c where ETownCaseComment__c.Case__c=:newcase.Id];
                    	if(totalcomments==0){
                    	system.debug(' I am Here !');
                        ETownCaseComment__c CaseCommentTemp = new ETownCaseComment__c();
                        CaseCommentTemp.Case__c = newcase.Id;
                        CaseCommentTemp.CommentBody__c = 'Phone_Case_Closed';
                        CaseCommentTemp.PlainTextBody__c = 'Phone_Case_Closed';
                        CaseCommentTemp.Type__c = 'Outbound';
                        CaseCommentTemp.Transferred__c = false;
                        insert CaseCommentTemp;
                    	}
                    	
                        
                    }   //Transfer Rate Reporting
                    
                    
                    if  //When a Case is transferred from a Normal CR to Central/East CR Queue
                    (
                        (oldcase.Id == newcase.Id) && 
                        ((OwnerIdNew == CentralCRQueue)||(OwnerIdNew == EastCRQueue))&&   
                        (newcase.Status == 'Transferred') &&
                        ((TiggerRTId == RTid18)||(TiggerRTId == RTid15))
                    )
                    {
                        ETownCaseComment__c CaseCommentTemp = new ETownCaseComment__c();
                        CaseCommentTemp.Case__c = newcase.Id;
                        CaseCommentTemp.CommentBody__c = 'Auto Notification on Transfer';
                        CaseCommentTemp.PlainTextBody__c = 'Auto Notification on Transfer';
                        CaseCommentTemp.Type__c = 'Outbound';
                        CaseCommentTemp.Transferred__c = true;
                        insert CaseCommentTemp;
                    }   //When a Case is transferred from a Normal CR to Central/East CR Queue
                }
            }
    }
      
      
}