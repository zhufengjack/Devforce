/*
 * This is a legacy class, the only logic left in this class is to retrieve the school of current user.
 * Pony Ma 2011-11-10	Added a method to get multi-locations based on a set of ownerId
 */
public class ComputeOpportunity 
{
  public static String GetOpportunitySalesLocation(Id salesOwnerId)
  {
    List<User> users = [select SchoolName__c from user where Id=:salesOwnerId];
    if(users.size() > 0 && users[0].SchoolName__c != null)
    {
        return users[0].SchoolName__c.replace('_', ' ');
    }
    else
    {
        return '';
    }
  }
  
  public static Map<String,String> getOpportunitySalesLocations(Set<String> ownerIdSet){
  	List<User> users = [select SchoolName__c from user where Id in :ownerIdSet];
  	Map<String,String> ownerSchoolNameMap=new Map<String,String>();
  	for(User u:users){
  		String schoolName='';
  		if(u.SchoolName__c!=null){
  			schoolName=u.SchoolName__c.replace('_', ' ');
  		}
  		ownerSchoolNameMap.put(u.Id,schoolName);	
  	}
  	return ownerSchoolNameMap;
  }
  
  
  @isTest
  static void ComputeOpportunity_test()
  {
        String str = ComputeOpportunity.GetOpportunitySalesLocation(UserInfo.getUserId());
        Set<String> idSet=new Set<String>();
        idSet.add(UserInfo.getUserId());
        Map<String,String> mapLocation=ComputeOpportunity.getOpportunitySalesLocations(idSet);
  }
}