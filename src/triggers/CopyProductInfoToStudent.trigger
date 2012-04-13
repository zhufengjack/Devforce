trigger CopyProductInfoToStudent on StudentProduct__c (after insert, after update) 
{
    Map<String, StudentProduct__c> studentProductMap = new Map<String, StudentProduct__c>();
    List<StudentProduct__c> studentProductList = [select Id, StudentActual__r.Student__c from StudentProduct__c where Id in :Trigger.newMap.keySet() and Product__r.ETownId__c != null];
    for(StudentProduct__c studentProduct : studentProductList)
    {
        studentProductMap.put(studentProduct.StudentActual__r.Student__c, studentProduct);
    }
    List<Contact> studentList = [select Id, Product__c from Contact where Id in :studentProductMap.keySet()];
    StudentProduct__c tempStudentProduct;
    for(Contact student : studentList)
    {
        tempStudentProduct = studentProductMap.get(student.Id);
        if(tempStudentProduct != null)
        {
            student.Product__c = tempStudentProduct.Id;
        }
    }
    update studentList;
}