/*
 * This is a legacy trigger, includes 2 logic:
 * 1. set SalesApptLocation on opp according to the school of current user
 * 2. set the FistVisit date field on opp.
 */
trigger OpportunityTrigger on Opportunity (before insert, before update, before delete) {
    if(Trigger.isBefore) {
        System.System.debug('**************************0000');
        Opportunity currOpp = null;

        //****************************************************
        //Every month system will Create a Smart Report
        //*****************************************************
        if(!Trigger.isDelete) {
            currOpp = Trigger.new[0];
            //**************************************************
            //Smart choose sales appt location start
            //Created on 2008-12-11 by Storm Yang
            //**************************************************
            List<Profile> profiles = null;
            profiles  =[select Name from Profile where Id=:UserInfo.getProfileId()];
            if(profiles != null && 
               (profiles[0].Name == 'EF China Sales Lead' 
               || profiles[0].Name == 'EF China Sales User' 
               || profiles[0].Name == 'EF China Sales User New' 
               || profiles[0].Name == 'EF China Sales User Test HHR')
               ){
               String location = ComputeOpportunity.GetOpportunitySalesLocation(currOpp.OwnerId);
               if(location != '' && location != null)
               {
                   currOpp.Location__c = location;
               }
            }
            //************************************************
            //Smart choose sales appt location end///////////
            //************************************************
            
            //*****************************************************
            //BY Jimmy 01 ---- START
            if ( Trigger.isInsert ) {
                System.System.debug('****************************1');                
                if ( currOpp.First_Visit__c == null 
                        && ( currOpp.StageName == 'Close/Lost -Show-Up'
                            || currOpp.StageName == 'Closed Won'
                            || currOpp.StageName == 'Payment Pending'
                            || currOpp.StageName == 'Showed Up - Followup' )) {
                        System.System.debug('****************************2');

                    if ( profiles[0].Name == 'EF China Sales User New' 
                            || profiles[0].Name == 'EF China Telesales User'
                            || profiles[0].Name == 'EF China Finance User New'
                            || profiles[0].Name == 'EF China Smart Booking Officer'
                            || profiles[0].Name == 'EF Taiwan Telesales User'
                            || profiles[0].Name == 'EF China NJ Sales Consultant' ) {
                            System.System.debug('****************************3');
                        currOpp.First_Visit__c = System.today();
                        System.System.debug('****************************4');

                    }
                }
            }
            //BY Jimmy 01 ---- END
            //*****************************************************

            if(Trigger.isUpdate){
                //*****************************************************
                //BY Jimmy 02 ---- START
                System.System.debug('****************************5');
                if ( currOpp.First_Visit__c == null 
                        && ( Trigger.old[0].StageName == 'Set Appt'
                            || Trigger.old[0].StageName == 'Appt No Show - Rescheduled'
                            || Trigger.old[0].StageName == 'Appt No Show - Call Later'
                            || Trigger.old[0].StageName == 'Close/Lost - No Show'
                        ) 
                        && ( currOpp.StageName == 'Close/Lost -Show-Up'
                            || currOpp.StageName == 'Closed Won'
                            || currOpp.StageName == 'Payment Pending'
                            || currOpp.StageName == 'Showed Up - Followup' )) {
                        System.System.debug('****************************6');
                        System.System.debug(profiles[0].Name + ' ---------------1');
                    if ( profiles[0].Name == 'EF China Sales User New' 
                            || profiles[0].Name == 'EF China  Telesales User' 
                            || profiles[0].Name == 'EF China Finance User New'
                            || profiles[0].Name == 'EF China Smart Booking Officer'
                            || profiles[0].Name == 'EF Taiwan Telesales User'
                            || profiles[0].Name == 'EF China NJ Sales Consultant' ) {
                            System.System.debug('****************************7');
                        currOpp.First_Visit__c = System.today();
                        System.System.debug('****************************8');
                    }
                }

                //BY Jimmy 02---- END
                //*****************************************************
            }
        }
    }    
}