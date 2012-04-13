// This trigger will calculate final price and refund amount for student actual and actual.
trigger CalculateFinalPrice on StudentProduct__c (after delete, after insert, after undelete, after update) 
{
    List<StudentProduct__c> studentProducts = (Trigger.isDelete) ? Trigger.old : Trigger.new;
    Set<String> studentActualIdSet = new Set<String>();
    Set<String> unDeleteSet = new Set<String>();
    Set<String> actualIdSet = new Set<String>();
    for(StudentProduct__c studentProduct : studentProducts)
    {
        if(studentProduct.StudentActual__c != null)
        {
            studentActualIdSet.add(studentProduct.StudentActual__c);
            unDeleteSet.add(studentProduct.StudentActual__c);
        }
    }
    
    // For StudentActual.
    List<StudentActual__c> studentActualList = new List<StudentActual__c>();
    List<AggregateResult> studentProductResults = [select StudentActual__c, SUM(Amount__c) sumAmount, SUM(Refund_Amount__c) sumRefundAmount  from StudentProduct__c where StudentActual__c in :studentActualIdSet GROUP BY StudentActual__c];
    for(AggregateResult result : studentProductResults)
    {
        studentActualList.add(new StudentActual__c(Id = (Id)result.get('StudentActual__c'), FinalPrice__c = (Decimal)result.get('sumAmount'), RefundAmount__c = (Decimal)result.get('sumRefundAmount')));
        unDeleteSet.remove((Id)result.get('StudentActual__c'));
    }
    for(String studentActualId : unDeleteSet)
    {
        studentActualList.add(new StudentActual__c(Id = studentActualId, FinalPrice__c = 0, RefundAmount__c = 0));
    }
    update studentActualList;
    
    // For actual.
    List<StudentActual__c> studentActuals = [select Id, Actual__c, FinalPrice__c from StudentActual__c where Id in :studentActualIdSet];
    for(StudentActual__c studentActual : studentActuals)
    {
        if(studentActual.Actual__c != null)
        {
            actualIdSet.add(studentActual.Actual__c);
        }
    }
    
    List<Actual__c> actualList = new List<Actual__c>();
    List<AggregateResult> studentActualResults = [select Actual__c, SUM(FinalPrice__c) sumAmount, SUM(RefundAmount__c) sumRefundAmount from StudentActual__c where Actual__c in :actualIdSet GROUP BY Actual__c ];
    for(AggregateResult result : studentActualResults)
    {
        actualList.add(new Actual__c(Id = (Id)result.get('Actual__c'), Final_Price__c = (Decimal)result.get('sumAmount'), CN_Refund_Amount__c = (Decimal)result.get('sumRefundAmount')));
    }
    update actualList;
}