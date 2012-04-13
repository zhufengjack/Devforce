/*
 * controller of page EtwonCaseEscalation
 */
public class EtownCaseEscaController
{
	public Boolean IsDenied{get;set;}
	public Case TargetCase {get; set; }
	public String SelectedQueueId { get; set; }
	public List<SelectOption> QueueList { get; set; }
	
	public EtownCaseEscaController()
    {
        String caseId=ApexPages.currentPage().getParameters().get('id');
        List<Case> cases = [select Id, CaseNumber, OwnerId from Case where Id=:caseId limit 1];
        if(cases.size() > 0)
        {
            TargetCase = cases[0];
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose a case')); 
            IsDenied = true;
        }
    }
    
    public PageReference init()
    {
        QueueList = getQueueList();
        return null;
    }
    
    public PageReference cancel()
    {
        return new PageReference('/' + TargetCase.Id);
    }
    
    public PageReference save()
    {
    	if(SelectedQueueId != null && SelectedQueueId != '')
        {
	    	TargetCase.OwnerId = SelectedQueueId;
	        try
	        {
	            update TargetCase;
	        }
	        catch(Exception ex)
	        {
	            ApexPages.addMessages(ex);
	        }
        }
        else
        {
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please choose a Queue to continue.'));
        } 
        PageReference Caselist= new PageReference('/500/o'); 
	    return Caselist;
    }
    
    public List<SelectOption> getQueueList()
    {
    	List<selectOption> options = new List<selectOption>();
		
		StudentCase__c SCSetting1 = StudentCase__c.getInstance('Central CR Queue');
		StudentCase__c SCSetting2 = StudentCase__c.getInstance('East CR Queue');
		
		String CentralCRQueue = SCSetting1.Id__c;
		String EastCRQueue = SCSetting2.Id__c;
		
        options.add(new selectOption(EastCRQueue, 'East CR Queue'));
        options.add(new selectOption(CentralCRQueue, 'Central CR Queue'));

      	return options;
    }
    
}