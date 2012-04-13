public with sharing class SchoolAddressController {
	public String SchoolName{get;set;}
	
	public String getSchoolAddress(){
		String schoolAddress=null;
		if(SchoolName!=null){
			schoolAddress=SchoolAddress__c.getAll().get(SchoolName).Address__c;	
		}
		return schoolAddress;
	}
}