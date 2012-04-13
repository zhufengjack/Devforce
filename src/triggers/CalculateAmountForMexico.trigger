/*
*Calculate Amount For Mexico Opportunities
*Calculate Amount For EU(Fr/Ge/It/Sp/Meast/Uk) Opportunities
* Pony Ma 2012-01-30 Added support for ROLA record type
* Pony Ma 2012-02-23 refactored the class, removed record type dependancies.
*/
trigger CalculateAmountForMexico on Opportunity (before insert, before update) 
{
	/**
	@add by Jack Zhu
	@2011-10-25
	@Function:when Opportunity RecordType is Mexico,US,Brazil, this trigger will calculate amount according to first installment discount,Number of Installment and EachInstallmentAmount.	
	*/
	
	private static final Id KoreanOpportunityRecordTypeId='0123000000097eA';
		
	for(Opportunity opp : Trigger.new)
    {
        if(opp.Number_of_Installments__c != null && opp.Number_of_Installments__c != '' && opp.Each_installment_amount__c != null){
        	Integer numberOfInstallments = integer.valueof(opp.Number_of_Installments__c);
        	double eachInstallmentAmount = opp.Each_installment_amount__c.doubleValue();
        	double firstInstallmentDiscount = 0;
        	double firstInstallmentDiscountAmount=0;
        	
        	//count for amount based on either firstInstallmentDiscount or firstInstallmentAmount 
        	//BR,MX,US,ROLA use discount percentage, EU uses discount amount
        	//Only one discount field should be populated        	
        	try{
        		if(opp.First_installment_Discount__c!=null && opp.First_installment_Discount__c!=''){ 
        			firstInstallmentDiscount=Double.valueOf(opp.First_installment_Discount__c.replace('%',''))/100;
        			firstInstallmentDiscountAmount=firstInstallmentDiscount*eachInstallmentAmount;
        			system.debug(firstInstallmentDiscountAmount);
        		}else if(opp.First_Installment_Discount_Amount__c != null && opp.First_Installment_Discount_Amount__c!=0){
        			firstInstallmentDiscountAmount=opp.First_Installment_Discount_Amount__c.doubleValue();	
        		}else{
        			//sepcific for Korean, first payment is double of each installment amount        			
           			if(numberOfInstallments>1 && opp.RecordTypeId == KoreanOpportunityRecordTypeId){
           				firstInstallmentDiscountAmount=(-1) * eachInstallmentAmount;           				
           			}
        		}
        	}catch(Exception e){}
        	
        	opp.First_installment_after_discount__c = eachInstallmentAmount - firstInstallmentDiscountAmount;
        	opp.Amount = eachInstallmentAmount * numberOfInstallments - firstInstallmentDiscountAmount;	         	        	   	        	        		
        }        
    }	
}