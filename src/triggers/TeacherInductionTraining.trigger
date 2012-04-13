trigger TeacherInductionTraining on Teacher_Induction_Training__c (before update,before insert) {
    /**
    @author: Jack Zhu
    @date: 2011-06-10
    @Last Modified By: Jack Zhu
    @function: 
    *
    *确保用户每次只能勾选一个选项,并且按照顺序提交.如果一次勾选多个选项或者不按照顺序提交,系统提示错误,并且不让保存.
    *如果保存成功,系统自动根据用户提交的步骤,将状态自动设置为S1S或者S2S等.
    *保存时间为Approval的时间
    *第一次创建时,自动将Contact填充,并且不允许用户创建多个记录.
    *&& !String.valueOf(UserInfo.getProfileId()).contains('00e40000000j8qL')
    */
    if(trigger.isBefore&trigger.isInsert)
    {
    List<Teacher_Induction_Training__c> listtit= trigger.new;
    for(Teacher_Induction_Training__c newtit: listtit)
    {
    if(newtit.Contact__c==null)
    {
      User u=[select ContactId from User where User.Id=:UserInfo.getUserId() limit 1];
      newtit.Contact__c=u.ContactId;
    }
    Integer length=[select count() from Teacher_Induction_Training__c where Teacher_Induction_Training__c.Contact__c=:newtit.Contact__c];
    if(length>0)
    {
    newtit.adderror('You can have only on Teacher Induction & Training record!');
    }
    }
    }else if(Trigger.isBefore&Trigger.isUpdate)
    {
        List<Teacher_Induction_Training__c> oldlist=trigger.old;
        List<Teacher_Induction_Training__c> newlist=trigger.new;
        
        for(Teacher_Induction_Training__c oldtit: oldlist)
        {
            for(Teacher_Induction_Training__c newtit: newlist)
            {
                if(oldtit.Id==newtit.Id)
                {
                if( newtit.S1__c ==true 
                    && oldtit.S1__c==false 
                    && newtit.S2__c ==false
                    && oldtit.S2__c ==false
                    && newtit.S3__c ==false
                    &&oldtit.S3__c ==false
                    && newtit.S4__c ==false
                    &&oldtit.S4__c==false
                    && newtit.S5__c ==false
                    &&oldtit.S5__c==false
                    && newtit.GL_PL__c ==false
                    &&oldtit.GL_PL__c ==false
                    &&newtit.S7__c ==false
                    &&oldtit.S7__c==false
                    && newtit.Quality_Assurance__c ==false
                    &&oldtit.Quality_Assurance__c ==false
                    && newtit.TL_TNS__c ==false
                    &&oldtit.TL_TNS__c ==false
                    && newtit.S10__c ==false
                    && oldtit.S10__c ==false)
                {
                    /**
                    *第一步完成,提交,保存提交时间为System.now()
                    */
                    }else if(   newtit.S1__c ==true 
                    && oldtit.S1__c==true 
                    && newtit.S2__c ==false
                    && oldtit.S2__c ==false
                    && newtit.S3__c ==false
                    &&oldtit.S3__c ==false
                    && newtit.S4__c ==false
                    &&oldtit.S4__c==false
                    && newtit.S5__c ==false
                    &&oldtit.S5__c==false
                    && newtit.GL_PL__c ==false
                    &&oldtit.GL_PL__c ==false
                    &&newtit.S7__c ==false
                    &&oldtit.S7__c==false
                    && newtit.Quality_Assurance__c ==false
                    &&oldtit.Quality_Assurance__c ==false
                    && newtit.TL_TNS__c ==false
                    &&oldtit.TL_TNS__c ==false
                    && newtit.S10__c ==false
                    && oldtit.S10__c ==false
                    && newtit.Approval_Status__c=='Approval'
                    )
                {
                    /**第一次审批通过*/
                    if(newtit.Approval_Status__c=='Approval'){
                       newtit.Approval_Status__c ='S1S';
                       if(newtit.Submit_Task_1__c==null)
                    {
                        /**如果第一次提交时间为空,更新第一次提交时间为当前时间.如果第一次提交时间不为空,则说明已经提交过了.就不再更新.*/
                        newtit.submit_Task_1__c=system.now();
                    }
                     }
                
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==false
                        && newtit.S3__c ==false
                        &&oldtit.S3__c ==false
                        && newtit.S4__c ==false
                        &&oldtit.S4__c==false
                        && newtit.S5__c ==false
                        &&oldtit.S5__c==false
                        && newtit.GL_PL__c ==false
                        &&oldtit.GL_PL__c ==false
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S1S'){
                    /**
                    *第二次提交.保存系统当前时间System.now()
                    */
                    }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==false
                        &&oldtit.S3__c ==false
                        && newtit.S4__c ==false
                        &&oldtit.S4__c==false
                        && newtit.S5__c ==false
                        &&oldtit.S5__c==false
                        && newtit.GL_PL__c ==false
                        &&oldtit.GL_PL__c ==false
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        && newtit.Approval_Status__c=='Approval'
                        )
                {
                    /**第二次审批通过*/
                    if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S2S';
                    if(newtit.Submit_Task_2__c==null){
                    newtit.submit_Task_2__c=system.now();
                    }
                    
                
                }
                }else if(newtit.S1__c ==true 
                            && oldtit.S1__c==true 
                            && newtit.S2__c ==true
                            && oldtit.S2__c ==true
                            && newtit.S3__c ==true
                            &&oldtit.S3__c ==false
                            && newtit.S4__c ==false
                            &&oldtit.S4__c==false
                            && newtit.S5__c ==false
                            &&oldtit.S5__c==false
                            && newtit.GL_PL__c ==false
                            &&oldtit.GL_PL__c ==false
                            &&newtit.S7__c ==false
                            &&oldtit.S7__c==false
                            && newtit.Quality_Assurance__c ==false
                            &&oldtit.Quality_Assurance__c ==false
                            && newtit.TL_TNS__c ==false
                            &&oldtit.TL_TNS__c ==false
                            && newtit.S10__c ==false
                            && oldtit.S10__c ==false
                            &&oldtit.Approval_Status__c=='S2S'){
                /**
                    *第3次提交.系统记录提交时间为系统当前时间
                    */
                 
                    
                }else if(newtit.S1__c ==true 
                            && oldtit.S1__c==true 
                            && newtit.S2__c ==true
                            && oldtit.S2__c ==true
                            && newtit.S3__c ==true
                            &&oldtit.S3__c ==true
                            && newtit.S4__c ==false
                            &&oldtit.S4__c==false
                            && newtit.S5__c ==false
                            &&oldtit.S5__c==false
                            && newtit.GL_PL__c ==false
                            &&oldtit.GL_PL__c ==false
                            &&newtit.S7__c ==false
                            &&oldtit.S7__c==false
                            && newtit.Quality_Assurance__c ==false
                            &&oldtit.Quality_Assurance__c ==false
                            && newtit.TL_TNS__c ==false
                            &&oldtit.TL_TNS__c ==false
                            && newtit.S10__c ==false
                            && oldtit.S10__c ==false
                            )
                {
                    /**第3次审批通过*/
                    if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S3S';
                    if(newtit.Submit_Task_3__c==null)
                    {
                    newtit.submit_Task_3__c=system.now();
                    }
                    }
                
                }else if(   newtit.S1__c ==true 
                            && oldtit.S1__c==true 
                            && newtit.S2__c ==true
                            && oldtit.S2__c ==true
                            && newtit.S3__c ==true
                            &&oldtit.S3__c ==true
                            && newtit.S4__c ==true
                            &&oldtit.S4__c==false
                            && newtit.S5__c ==false
                            &&oldtit.S5__c==false
                            && newtit.GL_PL__c ==false
                            &&oldtit.GL_PL__c ==false
                            &&newtit.S7__c ==false
                            &&oldtit.S7__c==false
                            && newtit.Quality_Assurance__c ==false
                            &&oldtit.Quality_Assurance__c ==false
                            && newtit.TL_TNS__c ==false
                            &&oldtit.TL_TNS__c ==false
                            && newtit.S10__c ==false
                            && oldtit.S10__c ==false
                            &&oldtit.Approval_Status__c=='S3S'){
                   /**
                    *第四步提交  newtit.submit_Task_4__c=system.now();
                    */
                  
                    
                }else if(   newtit.S1__c ==true 
                            && oldtit.S1__c==true 
                            && newtit.S2__c ==true
                            && oldtit.S2__c ==true
                            && newtit.S3__c ==true
                            &&oldtit.S3__c ==true
                            && newtit.S4__c ==true
                            &&oldtit.S4__c==true
                            && newtit.S5__c ==false
                            &&oldtit.S5__c==false
                            && newtit.GL_PL__c ==false
                            &&oldtit.GL_PL__c ==false
                            &&newtit.S7__c ==false
                            &&oldtit.S7__c==false
                            && newtit.Quality_Assurance__c ==false
                            &&oldtit.Quality_Assurance__c ==false
                            && newtit.TL_TNS__c ==false
                            &&oldtit.TL_TNS__c ==false
                            && newtit.S10__c ==false
                            && oldtit.S10__c ==false)
                {
                    /**第四步审批*/
                    if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S4S';
                     if(newtit.Submit_Task_4__c==null){
                    newtit.submit_Task_4__c=system.now();
                    }
                    
                    }
                
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==false
                        && newtit.GL_PL__c ==false
                        &&oldtit.GL_PL__c ==false
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S4S') {/**
                    *第五步提交newtit.submit_Task_5__c=system.now();
                    */
                    
                    
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==false
                        &&oldtit.GL_PL__c ==false
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false){
                            /**第五步审批*/
                        if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S5S';
                    if(newtit.Submit_Task_5__c==null){
                    newtit.submit_Task_5__c=system.now();
                    }
                    }
                
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==false
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S5S') {
                    /**
                    *第六步提交      newtit.submit_Task_6__c=system.now();
                    */
              
                   
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==false
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false){
                            /**第六步审批*/
                    if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S6S';
                    if(newtit.Submit_Task_6__c==null){
                    newtit.submit_Task_6__c=system.now();
                    }
                    }
                
                }else if( newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==false
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S6S') {
                    /**
                    *第七步完成,提交  newtit.submit_Task_7__c=system.now();
                    */
                    
                  
                }else if( newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==false
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false){
                            /*第七次审批*/
                if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S7S';
                    if(newtit.Submit_Task_7__c==null){
                    newtit.submit_Task_7__c=system.now();
                    }
                    }
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==false
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S7S'){
                                            /**
                    *第八步完成,提交
                    */
                    newtit.submit_Task_8__c=system.now();
                   
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==true
                        && newtit.TL_TNS__c ==false
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false){
                /**第八步审批*/
                 if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S8S';
                    if(newtit.Submit_Task_8__c==null){
                    newtit.submit_Task_8__c=system.now();
                    }
                    }
                }else if( newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==true
                        && newtit.TL_TNS__c ==true
                        &&oldtit.TL_TNS__c ==false
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S8S'){
                    /**
                    *第九步完成,提交
                    */
                    newtit.submit_Task_9__c=system.now();
                    
                    
                }else if( newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==true
                        && newtit.TL_TNS__c ==true
                        &&oldtit.TL_TNS__c ==true
                        && newtit.S10__c ==false
                        && oldtit.S10__c ==false){
                            /**第九步审批*/
                  if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S9S';
                    if(newtit.Submit_Task_9__c==null){
                    newtit.submit_Task_9__c=system.now();
                    }
                    }
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==true
                        && newtit.TL_TNS__c ==true
                        &&oldtit.TL_TNS__c ==true
                        && newtit.S10__c ==true
                        && oldtit.S10__c ==false
                        &&oldtit.Approval_Status__c=='S9S') {
                    /**
                    *第十步完成,提交
                    */
                    newtit.submit_Task_10__c=system.now();
                    
                }else if(newtit.S1__c ==true 
                        && oldtit.S1__c==true 
                        && newtit.S2__c ==true
                        && oldtit.S2__c ==true
                        && newtit.S3__c ==true
                        &&oldtit.S3__c ==true
                        && newtit.S4__c ==true
                        &&oldtit.S4__c==true
                        && newtit.S5__c ==true
                        &&oldtit.S5__c==true
                        && newtit.GL_PL__c ==true
                        &&oldtit.GL_PL__c ==true
                        &&newtit.S7__c ==true
                        &&oldtit.S7__c==true
                        && newtit.Quality_Assurance__c ==true
                        &&oldtit.Quality_Assurance__c ==true
                        && newtit.TL_TNS__c ==true
                        &&oldtit.TL_TNS__c ==true
                        && newtit.S10__c ==true
                        && oldtit.S10__c ==true){
                if(newtit.Approval_Status__c=='Approval'){
                    newtit.Approval_Status__c='S10S';
                    if(newtit.Submit_Task_10__c==null){
                    newtit.submit_Task_10__c=system.now();
                    }
                    }
                
                }else{
                    /**
                    *其它,不能保存
                    */
                    newtit.addError('You need complete your task step by step');
                }
                }
            
            }
        
        }
    }
}