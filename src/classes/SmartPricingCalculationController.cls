/*  
 * controller for SmartPricingCalculation
 */

public class SmartPricingCalculationController
{
    List<PriceData__c> allProducts;
    public List<PriceData__c> getAllProducts()
    {
        if(allProducts == null)
        {
            allProducts = [select SalesType__c, DestinationProduct__c, CurrentProduct__c, AddOnProduct__c,
                            ProductName__c,Levels__c, FreeLevels__c, FreePLs1__c, StandardMonths__c, FreeMonths__c, TotalMonths__c,
                            MKTPromotion__c, ProductPrice__c, TakenDays__c, StandardPrice__c from PriceData__c 
                            order by SalesType__c, DestinationProduct__c,CurrentProduct__c];
        }
        return allProducts;
    }
    
  @isTest
  static void testSmartPricingCalculation()
  {
    SmartPricingCalculationController controller = new SmartPricingCalculationController();
    controller.getAllProducts();
  }
}