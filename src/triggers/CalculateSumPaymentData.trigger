// This trigger will calculate payment and deposit for student actual and actual.
trigger CalculateSumPaymentData on PaymentData__c (after delete, after insert, after update) 
{
    List<PaymentData__c> paymentDataList = (Trigger.isDelete) ? Trigger.old : Trigger.new;
    Set<String> studentActualIdSet = new Set<String>();
    Map<String, PaymentData__c> actual2PaymentData = new Map<String, PaymentData__c>();
    Map<String, PaymentData__c> actual2NewDepositData = new Map<String, PaymentData__c>();
    for(PaymentData__c paymentData : paymentDataList)
    {
        if(paymentData.Actual__c != null && (!actual2PaymentData.keySet().contains(paymentData.Actual__c)) )
        {
            actual2PaymentData.put(PaymentData.Actual__c, paymentData);
        }
        if(paymentData.Actual__c != null && (paymentData.Pay_Type__c == 'China Smart Deposit' || paymentData.Pay_Type__c == 'China TS Deposit'))
        {
            actual2NewDepositData.put(PaymentData.Actual__c, paymentData);
        }
        if(paymentData.StudentActual__c != null)
        {
            studentActualIdSet.add(paymentData.StudentActual__c);
        }
        if(trigger.isUpdate)
        {
            if(paymentData.Actual__c != trigger.oldMap.get(paymentData.Id).Actual__c && trigger.oldMap.get(paymentData.Id).Actual__c != null)
            {
                actual2PaymentData.put(trigger.oldMap.get(paymentData.Id).Actual__c, paymentData);
            }
            if(paymentData.StudentActual__c != trigger.oldMap.get(paymentData.Id).StudentActual__c && trigger.oldMap.get(paymentData.Id).StudentActual__c != null)
            {
                studentActualIdSet.add(trigger.oldMap.get(paymentData.Id).StudentActual__c);
            }
        }
    }
    
    // For studentActual.
    Map<Id, StudentActual__c> studentActualUpdateds = new Map<Id, StudentActual__c>();
    // For studentActual deposit.
    Set<String> remainStudentActualIds = studentActualIdSet.clone(); // Stores remain student actual id.
    List<AggregateResult> studentActualResults = [select StudentActual__c, SUM(Amount__c) sumAmount, SUM(Total_Refund_Amount__c) sumRefund from PaymentData__c where (Pay_Type__c = 'China Smart Deposit' or Pay_Type__c = 'China TS Deposit') and StudentActual__c in :studentActualIdSet GROUP BY StudentActual__c];
    for(AggregateResult result : studentActualResults)
    {
        Id studentActualId = (Id)result.get('StudentActual__c');
        studentActualUpdateds.put(studentActualId, new StudentActual__c(Id=studentActualId, CNDepositTotal__c = (Decimal)result.get('sumAmount') - (Decimal)result.get('sumRefund')));
        remainStudentActualIds.remove(studentActualId); // remove student actual id.
    }
    // Process student actual deposit that doesn't have deposit payment data.
    for(String remainId : remainStudentActualIds)
    {
        studentActualUpdateds.put(remainId, new StudentActual__c(Id = remainId, CNDepositTotal__c = 0));
    }
    
    // For studentActual Payment
    remainStudentActualIds = studentActualIdSet.clone();
    Set<String> allStudentActualIds = new Set<String>();
    Set<String> ChangeCourseAmountIds = new Set<String>();
    List<AggregateResult> studentActualPaymentResults = [select StudentActual__c, Payment_method__c, SUM(Amount__c) sumAmount from PaymentData__c where (Pay_Type__c = 'China Smart Payment' or Pay_Type__c = 'China TS Payment') and StudentActual__c in :studentActualIdSet GROUP BY ROLLUP (StudentActual__c, Payment_method__c)];
    for(AggregateResult result : studentActualPaymentResults)
    {
        Id studentActualId = (Id)result.get('StudentActual__c');
        if(studentActualId != null)
        {
            allStudentActualIds.add(studentActualId);
            remainStudentActualIds.remove(studentActualId); // remove student actual id.
            if(studentActualUpdateds.containsKey(studentActualId))
            {
                StudentActual__c sa = studentActualUpdateds.get(studentActualId);
                if(result.get('Payment_method__c') == null)
                {
                    sa.CNPaymentTotal__c = (Decimal)result.get('sumAmount');
                }
                else if(result.get('Payment_method__c') == 'CHANGE COURSE')
                { 
                    ChangeCourseAmountIds.add(studentActualId);
                    sa.Change_Course_Payment_Amount__c = (Decimal)result.get('sumAmount');
                }
            }
            else
            {
                StudentActual__c newStudentActual = new StudentActual__c(Id =studentActualId);
                if(result.get('Payment_method__c') == null)
                {
                    newStudentActual.CNPaymentTotal__c = (Decimal)result.get('sumAmount');
                }
                else if(result.get('Payment_method__c') == 'CHANGE COURSE')
                { 
                    ChangeCourseAmountIds.add(studentActualId);
                    newStudentActual.Change_Course_Payment_Amount__c = (Decimal)result.get('sumAmount');
                }
                studentActualUpdateds.put(studentActualId, newStudentActual);
            }
        }
    }
    allStudentActualIds.removeAll(ChangeCourseAmountIds);
    for(String clearAmountId : allStudentActualIds)
    {
        if(studentActualUpdateds.containsKey(clearAmountId))
        {
            studentActual__c sa = studentActualUpdateds.get(clearAmountId);
            sa.Change_Course_Payment_Amount__c = 0;
        }
        else
        {
            studentActualUpdateds.put(clearAmountId, new StudentActual__c(Id = clearAmountId, Change_Course_Payment_Amount__c = 0));
        }
    }
    for(String remainId : remainStudentActualIds)
    {
        if(studentActualUpdateds.containsKey(remainId))
        {
            studentActual__c sa = studentActualUpdateds.get(remainId);
            sa.CNPaymentTotal__c = 0;
            sa.Change_Course_Payment_Amount__c = 0;
        }
        else
        {
            studentActualUpdateds.put(remainId, new StudentActual__c(Id = remainId, CNPaymentTotal__c = 0, Change_Course_Payment_Amount__c = 0));
        }
    }
    
    // For studentActual Refund.
    remainStudentActualIds = studentActualIdSet.clone();
    Set<String> allRefundStudentActualIds = new Set<String>();
    Set<String> changeCourseRefundIds = new Set<String>();
    List<AggregateResult> chinaSmartRefundResults = [select China_Payment_Data__r.StudentActual__c studentActualId, SUM(Refund_Amount__c) refund, Refund_Payment_Method__c from China_Smart_Refund__c where (China_Payment_Data__r.Pay_Type__c = 'China Smart Payment' or China_Payment_Data__r.Pay_Type__c = 'China TS Payment') and China_Payment_Data__r.StudentActual__c in :studentActualIdSet GROUP BY ROLLUP (China_Payment_Data__r.StudentActual__c, Refund_Payment_Method__c)];
    for(AggregateResult result : chinaSmartRefundResults)
    {
        Id studentActualId = (Id)result.get('studentActualId');
        if(studentActualId != null)
        {
            allRefundStudentActualIds.add(studentActualId);
            remainStudentActualIds.remove(studentActualId);
            if(studentActualUpdateds.containsKey(studentActualId))
            {
                 StudentActual__c sa = studentActualUpdateds.get(studentActualId);
                if(result.get('Refund_Payment_Method__c') == null)
                {
                     sa.CNRefundTotal__c = (Decimal)result.get('refund');
                }
                else if(result.get('Refund_Payment_Method__c') == 'CHANGE COURSE')
                {
                    changeCourseRefundIds.add(studentActualId);
                    sa.Change_Course_Refund_Amount__c = (Decimal)result.get('refund');
                }
            }
            else
            {
                StudentActual__c newStudentActual = new StudentActual__c(Id = studentActualId);
                if(result.get('Refund_Payment_Method__c') == null)
                {
                     newStudentActual.CNRefundTotal__c = (Decimal)result.get('refund');
                }
                else if(result.get('Refund_Payment_Method__c') == 'CHANGE COURSE')
                {
                    changeCourseRefundIds.add(studentActualId);
                    newStudentActual.Change_Course_Refund_Amount__c = (Decimal)result.get('refund');
                }
                studentActualUpdateds.put(studentActualId, newStudentActual);
            }
        }
    }
    
    allRefundStudentActualIds.removeAll(changeCourseRefundIds);
    for(String clearRefundId : allRefundStudentActualIds)
    {
        if(studentActualUpdateds.containsKey(clearRefundId))
        {
            studentActual__c sa = studentActualUpdateds.get(clearRefundId);
            sa.Change_Course_Refund_Amount__c = 0;
        }
        else
        {
            studentActualUpdateds.put(clearRefundId, new StudentActual__c(Id = clearRefundId, Change_Course_Refund_Amount__c = 0));
        }   
    }
    
    for(String remainId : remainStudentActualIds)
    {
        if(studentActualUpdateds.containsKey(remainId))
        {
            studentActual__c sa = studentActualUpdateds.get(remainId);
            sa.CNRefundTotal__c = 0;
            sa.Change_Course_Refund_Amount__c = 0;
        }
        else
        {
            studentActualUpdateds.put(remainId, new StudentActual__c(Id = remainId, CNRefundTotal__c = 0, Change_Course_Refund_Amount__c = 0));
        }
    }
    try
    {
        update studentActualUpdateds.values();
    }
    catch(DmlException ex)
    {
        for(Integer i = 0; i < ex.getNumDml(); i++)
        {
            Integer failedRow = ex.getDmlIndex(i);
            String errorMessage = ex.getDmlMessage(i);
            StudentActual__c errorRecord = studentActualUpdateds.values().get(failedRow);
            errorRecord.addError(errorMessage);
            for(PaymentData__c payment : findPaymentByStudentActual(errorRecord.Id))
            {
                payment.addError(errorMessage);
            }
        }
        return;
    }
    
    // For actual.
    Map<Id, Actual__c> actualUpdateds = new Map<Id, Actual__c>();
    Set<String> remainActualIds = actual2PaymentData.keySet().clone();
    // For actual deposit.
    List<AggregateResult> actualDepositResults = [select Actual__c, SUM(Amount__c) sumAmount, SUM(Total_Refund_Amount__c) sumRefund from PaymentData__c where (Pay_Type__c = 'China Smart Deposit' or Pay_Type__c = 'China TS Deposit') and Actual__c in :actual2PaymentData.keySet() GROUP BY Actual__c];
    for(AggregateResult result : actualDepositResults)
    {
        Id actualId = (Id)result.get('Actual__c');
        remainActualIds.remove(actualId);
        Actual__c tempActual = new Actual__c(Id=actualId, CN_Deposit_Total__c = (Decimal)result.get('sumAmount') - (Decimal)result.get('sumRefund'));
        if(Trigger.isInsert)
        {
            PaymentData__c tempPayment = actual2NewDepositData.get(actualId);
            if(tempPayment != null && tempPayment.TransDatetime__c != null)
            {
                if(tempPayment.Amount__c > 0)
                {
                    tempActual.CN_Deposit_Date__c = Date.newInstance(tempPayment.TransDatetime__c.year(),tempPayment.TransDatetime__c.month(),tempPayment.TransDatetime__c.day());
                }
            }
        }
        actualUpdateds.put(actualId, tempActual);
    }
    for(String remainId : remainActualIds)
    {
        actualUpdateds.put(remainId, new Actual__c(Id = remainId, CN_Deposit_Total__c = 0));
    }
    
    // For actual Payment.
    remainActualIds = actual2PaymentData.keySet().clone();
    List<AggregateResult> actualPaymentUpdateds = [select Actual__c, SUM(Amount__c) sumAmount from PaymentData__c where (Pay_Type__c = 'China Smart Payment' or Pay_Type__c = 'China TS Payment') and Actual__c in :actual2PaymentData.keySet() GROUP BY actual__c];
    for(AggregateResult result : actualPaymentUpdateds)
    {
        Id actualId = (Id)result.get('Actual__c');
        remainActualIds.remove(actualId);
        if(actualUpdateds.containsKey(actualId))
        {
            actualUpdateds.get(actualId).CN_Payment_Total__c = (Decimal)result.get('sumAmount');
        }
        else
        {
            actualUpdateds.put(actualId, new Actual__c(Id=actualId, CN_Payment_Total__c = (Decimal)result.get('sumAmount')));
        }
    }
    for(String remainId : remainActualIds)
    {
        if(actualUpdateds.containsKey(remainId))
        {
            Actual__c ac = actualUpdateds.get(remainId);
            ac.CN_Payment_Total__c = 0;
        }
        else
        {
            actualUpdateds.put(remainId, new Actual__c(Id = remainId, CN_Payment_Total__c = 0));
        }
    }
    
    // For actual Refund.
    remainActualIds = actual2PaymentData.keySet().clone();
    List<AggregateResult> actualRefundUpdateds = [select Actual__c,SUM(Total_Refund_Amount__c) refund from PaymentData__c where (Pay_Type__c = 'China Smart Payment' or Pay_Type__c = 'China TS Payment') and actual__c in :actual2PaymentData.keySet() GROUP BY actual__c];
    for(AggregateResult result : actualRefundUpdateds)
    {
        Id actualId = (Id)result.get('Actual__c');
        remainActualIds.remove(actualId);
        if(actualUpdateds.containsKey(actualId))
        {
            actualUpdateds.get(actualId).CN_Refund_Total__c = (Decimal)result.get('refund');
        }
        else
        {
            actualUpdateds.put(actualId, new Actual__c(Id=actualId, CN_Refund_Total__c = (Decimal)result.get('refund')));
        }
    }
    for(String remainId : remainActualIds)
    {
        if(actualUpdateds.containsKey(remainId))
        {
            Actual__c ac = actualUpdateds.get(remainId);
            ac.CN_Refund_Total__c = 0;
        }
        else
        {
            actualUpdateds.put(remainId, new Actual__c(Id = remainId, CN_Refund_Total__c = 0));
        }
    }
    try
    {
        update actualUpdateds.values();
    }
    catch(DmlException ex)
    {
        for(Integer i = 0; i < ex.getNumDml(); i++)
        {
            Integer failedRow = ex.getDmlIndex(i);
            String errorMessage = ex.getDmlMessage(i);
            Actual__c errorRecord = actualUpdateds.values().get(failedRow);
            errorRecord.addError(errorMessage);
            for(PaymentData__c payment : findPaymentByActual(errorRecord.Id))
            {
                payment.addError(errorMessage);
            }
        }
    }
    
    private List<PaymentData__c> findPaymentByStudentActual(Id studentActualId)
    {
        List<PaymentData__c> result = new List<PaymentData__c>();
        for(PaymentData__c payment : Trigger.new)
        {
            if(payment.StudentActual__c == studentActualId)
            {
                result.add(payment);
            }
        }
        return result;
    }
    
    private List<PaymentData__c> findPaymentByActual(Id actualId)
    {
        List<PaymentData__c> result = new List<PaymentData__c>();
        for(PaymentData__c payment : Trigger.new)
        {
            if(payment.Actual__c == actualId)
            {
                result.add(payment);
            }
        }
        return result;
    }
}