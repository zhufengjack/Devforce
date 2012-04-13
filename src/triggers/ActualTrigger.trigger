/*
 * copy the cn-payment-total to opp.amount, and china-product-list to opp.product
 * if elite-card changed, copy elite-card to account.elite-card
 * updated by Hobart, 2010-4-27
 *该Trigger作用与Actual之上
 *当创建和更新Actual之时触发
 *当创建Actual，或者Acutal之上的付款金额，产品名称，销售类型，关单日期，改变之时，自动根据Actual信息更新Opportunity之上的相应信息
 *当关单日期早于等于First Visit Date 时，自动将First Visit Date 设置为关单日期
 *当Actual上的Elite_card发生变化时，更新客户上的Elite Card 字段
 *@author:Update by Jack Zhu from ef
 *@time:2010-10-09
 */
trigger ActualTrigger on Actual__c (before insert,before update) 
{
    Actual__c currActual = null;
    Actual__c oldActual = null;
    currActual = Trigger.new[0];
    if(Trigger.isUpdate)
    {
        oldActual = Trigger.oldMap.get(currActual.Id);
    }
    if((currActual.RecordType.Name == 'China Actual Record Type' || currActual.RecordTypeId == '0124000000098F6'))
    {
        Id oppId = currActual.Opportunity__c;
        if(oppId != null)
        {
        	Opportunity oldopp=[select Opportunity.Id,Opportunity.First_Visit__c from Opportunity where Opportunity.Id =: oppId];
        	
            if(oldActual == null || currActual.CN_Payment_Total__c != oldActual.CN_Payment_Total__c || currActual.China_Product_List__c != oldActual.China_Product_List__c || currActual.China_Sales_Type__c != oldActual.China_Sales_Type__c || currActual.Close_date__c != oldActual.Close_date__c)
            {
            	if(oldopp.First_Visit__c>=curractual.Close_date__c)
            	{
        		   update new Opportunity(Id = oppId, Amount = currActual.CN_Payment_Total__c, product__c = currActual.China_Product_List__c, China_Sales_Type__c = currActual.China_Sales_Type__c, CloseDate = currActual.Close_date__c,First_Visit__c=currActual.Close_date__c);
        	    }else
        	    {
    	           update new Opportunity(Id = oppId, Amount = currActual.CN_Payment_Total__c, product__c = currActual.China_Product_List__c, China_Sales_Type__c = currActual.China_Sales_Type__c, CloseDate = currActual.Close_date__c);
        	    }
            	
            }
            if(oldActual != null && currActual.Elite_Card__c != oldActual.Elite_Card__c)
            {
                //When Elite card # (actual page) is inputted or edited, copy Actual Elite card # field to Student Elite card #
                if(currActual.Elite_Card__c != null && currActual.Elite_Card__c != '' && currActual.Account__c != null)
                {
                    update new Account(Id = currActual.Account__c, Elite_Card__c = currActual.Elite_Card__c);
                }
            }
        }
    }
}