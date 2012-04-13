@isTest
private class TestReturnToPreviousPage{
    
    public static testMethod void testMethods() {
        ReturnToPreviousPage rtpp = new ReturnToPreviousPage();
        PageReference pr = rtpp.previousPage();
        //System.assert(true, pr.getURL().toLowerCase().contains('salesforce'));
    }

}