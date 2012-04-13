/**
*	Pony Ma	2012-02-13	Added contactId not null validation before calling AutoAssignmentLogic method 
*   Pony Ma	2012-02-13	Updated the logic to calculate the response time
*/
trigger ETownCaseComment on ETownCaseComment__c (after insert, before insert, after update) 
{
    String CaseCommentType;
    Id CaseId;
    String CaseCommentBoby;
    Datetime ResponseStartTime;
    Datetime ResponseEndTime;
    Datetime ReplyStartTime;
    Datetime ReplyEndTime;
    Datetime LatestOutboundTime;
    integer OutCommentsNumber;
    integer InCommentsNumber;
    boolean CaseCommentIsDraft;
    
    list <ETownCaseComment__c> ETCaseCommentsOut;
    list <ETownCaseComment__c> ETCaseCommentsIn;
    ETownCaseComment__c ETCaseCommentOut;
    Case CaseTemp;
    
    for(Integer i = 0; i < Trigger.new.size(); i++) 
    {
        
        CaseCommentType = trigger.new[i].Type__c;
        CaseCommentIsDraft = trigger.new[i].IsDraft__c;
        CaseId = trigger.new[i].Case__c;
        CaseCommentBoby = trigger.new[i].CommentBody__c;
        
        //Check Case RecordType
        CaseTemp = [Select RecordTypeId, FromStudent__c, CreatedDate, ClaimByCR__c from Case where Id =:CaseId limit 1];
        String CaseRT = CaseTemp.RecordTypeId;
        decimal CaseFS = CaseTemp.FromStudent__c;
        datetime CaseCD = CaseTemp.CreatedDate;
        datetime CaseCC = CaseTemp.ClaimByCR__c;
            
        StudentCase__c SCSetting = StudentCase__c.getInstance('Etown Student Case 18');
        String RTid = SCSetting.Id__c;
                
        if ((trigger.isAfter)&&(CaseRT == RTid))
        {
            
            if ((CaseCommentType == 'Inbound') && (CaseCommentIsDraft == false))
            {
                Database.DMLOptions dmo = new Database.DMLOptions();
                dmo.assignmentRuleHeader.useDefaultRule = false;
                                                
                CaseTemp = [Select status, ContactId from Case where Id =:CaseId limit 1 for update];
                CaseTemp.Status = 'Re-opened';
                //AutoAssignmentLogic requires a contact id
                if(CaseTemp.ContactId!=null){
                	String Assignee = AutoAssignmentLogic.assignCase2(CaseId);
                	system.debug(Assignee + '    Assignee');
                	CaseTemp.OwnerId = Assignee;
                }
                CaseTemp.setOptions(dmo);
                update CaseTemp;
            }
                        
            //else 
            else if ((CaseCommentType == 'Outbound') && (CaseCommentIsDraft == false))
            {
                if ((CaseCommentBoby != 'Auto Notification on Transfer') && (CaseCommentBoby != 'Phone_Case_Closed'))
                {
                    CaseTemp = [Select Status from Case where Id =: CaseId limit 1 for update];
                
                    CaseTemp.Status = 'Closed';
                    
                    CaseTemp.OwnerId = trigger.new[i].CreatedById;
                            
                    update CaseTemp;
                }   
            }
            
            else if ((CaseCommentType == 'Internally') && (CaseCommentIsDraft == false))
            {
                CaseTemp = [Select Status from Case where Id =: CaseId limit 1 for update];
                CaseTemp.OwnerId = trigger.new[i].CreatedById;
                update CaseTemp;
            }
        }
        
        
        if ((trigger.isbefore) && (CaseRT == RTid))
        {
            
            if (CaseCommentType == 'Outbound')
            {
                 List<ETownCaseComment__c> ETCaseCommentslists = [Select CreatedDate,type__c from ETownCaseComment__c where Case__c =:CaseId order by CreatedDate desc];
                 Boolean flag=false;//this variable is depiciting whether last comments is inbound,internal or not. if yes, flag is true. if not,flag is false
                 Datetime latestInboundTime=CaseCD;
                 if(ETCaseCommentslists.size()>0)
                 {
                  Integer index=0;
                  for(index=0;index<ETCaseCommentsLists.size();index++){
                  	if(ETCaseCommentsLists[index].type__c=='Internally'){
                  		 continue;
                  	}else if(ETCaseCommentsLists[index].type__c=='Inbound'){
                  		flag=true;
                  		latestInboundTime=ETCaseCommentsLists[index].CreatedDate;
                  		break;	
                  	}else if(ETCaseCommentsLists[index].type__c=='Outbound'){
                  		flag=false;
                  		break;	
                  	}                  		
                  }  
                  if(index==ETCaseCommentsLists.size()) flag=true;                                  
                 }
                //Calculate Response Time for each OCC (Start)
                if (CaseFS == 0&&ETCaseCommentslists.size()==0)
                {
                    ResponseStartTime = CaseCD;
                    ResponseEndTime = system.now();
                    trigger.new[i].ResponseTime__c = DiffinHour (ResponseStartTime, ResponseEndTime);
                    Decimal ResponseTime = DiffinHour (ResponseStartTime, ResponseEndTime);
                    String SLA;
                    if (ResponseTime <= 24)      {SLA = 'Within 24 Hours';}
                    else if (ResponseTime <= 48) {SLA = 'Within 48 Hours';}
                    else if (ResponseTime <= 72) {SLA = 'Within 72 Hours';}
                    else{SLA = 'More than 72 Hours';}
                    trigger.new[0].ResponseSLA__c = SLA;
                          //Calculate Reply Time for each OCC (Start)
                    ReplyStartTime = CaseCC;
                    if (ReplyStartTime == null)
                    {
                        ReplyStartTime = system.now();
                    }
                    ReplyEndTime = system.now();
                    trigger.new[i].ReplyTime__c = DiffinHour (ReplyStartTime, ReplyEndTime);
                    //Calculate Reply Time for each OCC (End)
               
                }
                else if(flag==true)
                {
                    //ResponseStartTime = GetCaseLatestInbound(CaseId);
                    ResponseStartTime=latestInboundTime;
                    ResponseEndTime = system.now();
                    trigger.new[i].ResponseTime__c = DiffinHour (ResponseStartTime, ResponseEndTime);
                    Decimal ResponseTime = DiffinHour (ResponseStartTime, ResponseEndTime);
                    String SLA;
                    if (ResponseTime <= 24)      {SLA = 'Within 24 Hours';}
                    else if (ResponseTime <= 48) {SLA = 'Within 48 Hours';}
                    else if (ResponseTime <= 72) {SLA = 'Within 72 Hours';}
                    else{SLA = 'More than 72 Hours';}
                    trigger.new[0].ResponseSLA__c = SLA;
                              //Calculate Reply Time for each OCC (Start)
                    ReplyStartTime = CaseCC;
                    if (ReplyStartTime == null)
                    {
                        ReplyStartTime = system.now();
                    }
                    ReplyEndTime = system.now();
                    trigger.new[i].ReplyTime__c = DiffinHour (ReplyStartTime, ReplyEndTime);
                    //Calculate Reply Time for each OCC (End)
               
                }
                //Calculate Response Time for each OCC (End)    
               
              
            
            }
            
            else if (CaseCommentType == 'Inbound')
            {
                //Update Repeat
                ETCaseCommentsOut = [Select Id, Repeated__c from ETownCaseComment__c where Type__c = 'Outbound' and Case__c =:CaseId order by CreatedDate desc];
                if (ETCaseCommentsOut.size()>0)
                {
                    ETCaseCommentsOut[0].Repeated__c = true;
                    update ETCaseCommentsOut[0];
                }
            }
        }
        
    }
    
    
    private decimal DiffinHour (Datetime FromDatetime, Datetime ToDatetime)
      {
            Decimal Dec;
            
            Long FromTime = FromDatetime.getTime();
            Long ToTime = ToDatetime.getTime();
                        
            Double Duration = ToTime - FromTime;
            
            Dec = Decimal.valueOf(Duration/3600000);
                        
            return Dec;
      }
    
    
    private datetime GetCaseLatestInbound(Id InputCaseId)
    {
        datetime LatestInbound;
        list <ETownCaseComment__c> ETCaseCommentsTemp;
        
        ETCaseCommentsTemp = [Select CreatedDate from ETownCaseComment__c where ETownCaseComment__c.Type__c ='Inbound' and Case__c =:InputCaseId order by CreatedDate desc];
        
        if (ETCaseCommentsTemp.size()>0)
        {
            LatestInbound = ETCaseCommentsTemp[0].CreatedDate;
        }
        else{LatestInbound = system.now();}
        
        return LatestInbound;
    }
    
}