/**
 * controller for page: SmartShowConfirmation
 */
public class SmartShowConfirmationController 
{
    private static final String chinaSmartOppRecordTypeId = '0124000000099sY';
    private static final Id EFChinaOperatorProfileid = '00e30000000hjwF';
    private static final Id EFChinaOperatorLeadProfileid = '00e30000000hq1u';
    
    public PageReference confirmAppt()
    {
        String oppId = ApexPages.currentPage().getParameters().get('oppId');
        List<Opportunity> currentOpportunities = [select Id, Check_confirmation__c, Reschedule_appt_Date__c, Location__c, Reschedule_appt_Date_Time__c from Opportunity where Id = :oppId and RecordTypeId = :chinaSmartOppRecordTypeId limit 1];
        if(!currentOpportunities.isEmpty())
        {
            Opportunity currentOpportunity = currentOpportunities[0];           
            if(currentOpportunity.Location__c != null && currentOpportunity.Reschedule_appt_Date__c != null)
            {
                if(currentOpportunity.Check_confirmation__c == false)
                {
                		User currentUse = [select UserRole.Name from User where Id =:UserInfo.getUserId()];
	    				String currentRoleName = currentUse.UserRole.Name;
	    				Boolean isBlockedByCapping = true;
                		if((currentRoleName == 'China Operator' && userInfo.getProfileId() == EFChinaOperatorProfileid)|| (currentRoleName == 'China Operator Group Supervisor' && UserInfo.getProfileId() == EFChinaOperatorLeadProfileid))
                		{
                			isBlockedByCapping = false;
                		}   
                		else
                		{                                                      
	                    Integer remainingAppt = RemainingApptsHelper.getRemianingApptByHourly(currentOpportunity);
	                    if(remainingAppt > 0)
	                    {    
	                    		isBlockedByCapping = false;                    	                        
	                    }                   
                		}
	    				if(!isBlockedByCapping)
                		{
                			Date currentDay = date.today();
                			if(currentOpportunity.Reschedule_appt_Date__c == currentDay.addDays(1) || currentOpportunity.Reschedule_appt_Date__c == currentDay)
                			{
	                		    currentOpportunity.Check_confirmation__c = true;
	                        try
	                        {
	                            update currentOpportunity;
	                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, '<script type="text/javascript">alert(\'The opportunity have been successfully confirmed.\'); setTimeout(\'window.location="/' + oppId + '";\', 2000);</script>'));
	                        }
	                        catch(Exception ex)
	                        {
	                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Failed to update opportunity. Errors: ' + ex.getMessage()));
	                        }
                			}
                			else
                			{
                				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'You can’t confirm this appt now. Please do it one day before or on the reschedule appt date. 您目前不能操作该appt confirmation，请在Reschedule Appt date前一天或者当天再进行确认'));
                			}
                		}
                		else
                		{
                			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no remaining appts for the school: ' + currentOpportunity.Location__c + ' on ' + currentOpportunity.Reschedule_appt_Date_Time__c.date().format() + ' ' + String.valueof(currentOpportunity.Reschedule_appt_Date_Time__c.hour()) + ':00 - ' + String.valueof(currentOpportunity.Reschedule_appt_Date_Time__c.hour() + 1) + ':00' + '. Pls select another date/time.'));
                		}
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This opportunity has been confirmed.'));
                }
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Location or schedule date is empty.'));
            }
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No Opportunity specified. And please take care this button only works for china smart Opportunities.'));
        }
        return null;
    }
    
    @isTest
    static void testTsShowConfirmationController()
    {
    	Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
    	Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today(), Check_confirmation__c = false);
    	insert testOpportunity1;
    	Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
    	insert testTarget1;
    	China_Appointment_Max_target_detail__c detail = new China_Appointment_Max_target_detail__c(School__c = 'SH PSQ', Time__c = datetime.now(), Max_target__c = 10);
    	insert detail;
    	PageReference testPage = new PageReference('/SmartShowConfirmation?oppId=' + testOpportunity1.Id);
    	test.setCurrentPage(testPage);
    	SmartShowConfirmationController controller = new SmartShowConfirmationController();
    	controller.confirmAppt();
    }
}