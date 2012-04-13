public class ReturnToPreviousPage {

    public PageReference previousPage() {
        String retURL = ApexPages.currentPage().getParameters().get('retURL');
        return new PageReference( retURL + '?t'); 
    }


}