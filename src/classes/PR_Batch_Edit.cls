public class PR_Batch_Edit
{
	private Id ActId= ApexPages.currentPage().getParameters().get('id');
	private Actual__c currentActual  = null;
	public Actual__c NewActual {get; set;}
	public List<Payment_Record__c> NewPaymentRecords {get; set;}
	public List<Payment_Record__c> OldPaymentRecords {get; set;}
	
	public PR_Batch_Edit()
    {init();}
	
	private void init()
    {
    	Boolean isValid = true;
    	Id ActId= ApexPages.currentPage().getParameters().get('id');
    	List <Actual__c> Act  = [Select a.Final_Price__c, a.Payment_Type__c, a.Discount_Amount__c from Actual__c a where Id=:ActId];
	    if(!Act.isEmpty())
	    {
	        NewActual = Act[0];
	    	//Fetch Existing Payment Record List
	    	NewPaymentRecords = new List<Payment_Record__c>();
	    	NewPaymentRecords = [select Installment__c, Amount_Due__c, Due_Date__c, Status__c, Amount_Collected__c, Collected_Date__c 
	    	from Payment_Record__c 
	    	where Actual__c=:ActId and (Due_Date__c >= Today and Status__c!='Collected') 
	    	order by Installment__c];
	        
	        OldPaymentRecords = new List<Payment_Record__c>();
	    	OldPaymentRecords = [select Installment__c, Amount_Due__c, Due_Date__c, Status__c, Amount_Collected__c, Collected_Date__c 
	    	from Payment_Record__c 
	    	where Actual__c=:ActId and (Due_Date__c < Today or Status__c='Collected') 
	    	order by Installment__c];     
	    }
    }
    
	public PageReference cancel()
	{return new PageReference('/' + ActId);}
	
	public PageReference save()
	{	
		List <Actual__c> Act  = [Select a.Final_Price__c, a.Number_of_Installments__c, a.Discount_Amount__c from Actual__c a where Id=:ActId];
        Boolean isValid1 = true;
        Boolean isValid2 = true;
        
        system.debug('Act.isEmpty: '+Act.isEmpty());
        system.debug('Old PaymentRecords Size: '+OldPaymentRecords.size());
        system.debug('New PaymentRecords Size: '+NewPaymentRecords.size());
        
        if(!Act.isEmpty() && OldPaymentRecords.size()>0 && NewPaymentRecords.size()>0)
	    {
		//Validation 1(Start)
		
		decimal InstallTotal = 0;
		
	        for(Payment_Record__c PaymentRecord : OldPaymentRecords)
	        {
	        	InstallTotal+=PaymentRecord.Amount_Due__c;
	        }

	        for(Payment_Record__c PaymentRecord : NewPaymentRecords)
	        {
	        	InstallTotal+=PaymentRecord.Amount_Due__c;
	        }

        	currentActual = Act[0];
	        system.debug('Install Total: '+InstallTotal);
			system.debug('Final Price: '+currentActual.Final_Price__c);
		
		//if(InstallTotal!=currentActual.Final_Price__c){isValid1 = False;}
		if(InstallTotal!=currentActual.Final_Price__c-currentActual.Discount_Amount__c){isValid1 = False;}
		//Validation 1(End)
		
		//Validation 2(Start)

		//Integer i= Integer.Valueof(currentActual.Number_of_Installments__c);
		Integer i=NewPaymentRecords.size();
		Integer k;
		if (i>0)
		{
	        Boolean Flag = true;
	        if (i>1)
	        {
		        for(k=0;k<i-1;k++)
		        {	
		        	if(NewPaymentRecords[k].Due_Date__c>NewPaymentRecords[k+1].Due_Date__c)
		            {
		            	system.debug('Compare in New Payment Records: '+NewPaymentRecords[k].Due_Date__c);
		            	system.debug('Compare in New Payment Records: '+NewPaymentRecords[k+1].Due_Date__c);
		            	isValid2 = false;
		            }
		        }
	        }
	        
	        Integer l=OldPaymentRecords.size();
	        if (l > 0)
	        {
		        if(OldPaymentRecords[l-1].Due_Date__c>NewPaymentRecords[0].Due_Date__c)
				{
					system.debug('Compare Old/New Payment Records: '+OldPaymentRecords[l-1].Due_Date__c);
					system.debug('Compare Old/New Payment Records: '+NewPaymentRecords[0].Due_Date__c);
					isValid2 = false;
				}
	        }    
	        system.debug('FFFFFFFFF: '+Flag);
		}
		//Validation 2(End)
	    }
		
		//Update Payment Records(Start)
		if(!isValid1)
		{
        	ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Sum of Amount Due should be equal to Final Price minus Discount Amount!'));
        	return null;
        }
		else if(!isValid2)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Installment Due Date out of order!'));
			return null;
		}
		else
		{
			update NewPaymentRecords;
			return new PageReference('/' + ActId);
		}
		//Update Payment Records(End)
	}
	
	
	public static testMethod void testMyController() 
	{
		String GermanyOppoRecordTypeId = '012400000009AxZ';
        Account acc2 = new Account(name='acme');
        insert acc2;
        Product2 product2 = new Product2(Name = 'Premium 11', Months__c = 7, EtownId__c = 'acme');
        insert product2;
        Opportunity GerOpp = new Opportunity
        (
        	AccountId=acc2.Id, 
        	Name = 'acme', 
        	Product__c = product2.Id, 
        	Amount = 300, 
        	No_of_installment_month__c = '1', 
	        First_installment_Discount__c = '50%', 
	        Referral_opportunity_number__c = 'acme', 
	        Social_Security_or_RFC__c = 'acme', 
	        First_installment_after_discount__c = 100, 
	        Each_installment_amount__c = 200, 
	        Welcome_kit_receiver__c = 'acme', 
	        Payment_Schedule__c = 'Installments-Manual-Deposit', 
	        Number_of_Installments__c = '2', 
	        Payment_Type__c = 'Cash Full Payment',  
	        StageName = 'Closed Won', 
	        CloseDate = Date.today(), 
	        RecordTypeId = GermanyOppoRecordTypeId, 
	        China_Sales_Type__c = 'New'
        );
        insert GerOpp;
		
		Actual__c TestActual = new Actual__c
		(	
			Opportunity__c = GerOpp.Id,
			Final_Price__c = GerOpp.Amount
		);
		insert TestActual;
		
		Payment_Record__c Fpr = new Payment_Record__c
		(
			Actual__c = TestActual.id,
			Due_Date__c = Date.newInstance(2010, 1, 1),
			Installment__c = '1',
			Status__c = 'Collected',
			Amount_Due__c = 100
		);
		insert Fpr;
		
		Payment_Record__c Rpr = new Payment_Record__c
		(
			Actual__c = TestActual.id,
			Due_Date__c = Date.newInstance(2022, 1, 1),
			Installment__c = '2',
			Status__c = 'Duw',
			Amount_Due__c = 100
		);
		insert Rpr;
		
		//https://c.ap1.visual.force.com/apex/PR_Batch_Edit?scontrolCaching=1&id=a0090000001HDAr
		
		PageReference GerTestpage = new PageReference('/apex/PR_Batch_Edit?scontrolCaching=1&id=' + TestActual.Id);
        test.setCurrentPage(GerTestpage);
		
		PR_Batch_Edit BE_Controller = new PR_Batch_Edit();
        BE_Controller.init();
        BE_Controller.save();
        BE_Controller.cancel();
	}
}