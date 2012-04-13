/*
* Helper class for Elite Card projects
*/
public class EliteCardHelper 
{   
   private static Map<String, Integer> schoolNameToUpdatedMaxSequence = new Map<String, Integer>();
   private static Map<Id, String> contactToSchoolName = new Map<Id, String>();
   private static Map<Id, String> contactToEliteCard = new Map<Id, String>();
   private static Integer isExistedEliteCardRunCount = 0;
   
   public static void generateEliteCardNumber(Set<Id> studentActualIds)
   {
       if(studentActualIds.size() > 0)
       {
           Map<Id, StudentActual__c> contactsToStudentActuals = new Map<Id, StudentActual__c>();
           Map<Id, StudentActual__c> existedContactsToStudentActuals = new Map<Id, StudentActual__c>();
           List<StudentActual__c> updatingStudentActual = new List<StudentActual__c>();
           List<StudentActual__c> studentActuals = [select Id, EntryCenter__c, Student__c, Actual__r.Sales_Appt_Locations_2__c, EliteCard__c, Student__r.Status__c, Student__r.EtownUsername__c, Student__r.EliteCard__c, Student__r.IsNewEliteCard__c, Student__r.RecordType.Name from StudentActual__c where Id in :studentActualIds and EntryCenter__c != null and Student__c != null and Actual__c != null];
           for(StudentActual__c studentActual : studentActuals)
           {
               howToUpdateEliteCard(studentActual, contactsToStudentActuals, existedContactsToStudentActuals);
           } 
           if(contactsToStudentActuals.size() > 0)
           {    
               mapEliteCardToContact(contactsToStudentActuals);
           }  
           if(existedContactsToStudentActuals.size() > 0)
           {
               updatingStudentActual.addAll(copyEliteCardToStudentActual(existedContactsToStudentActuals));
           }
           if(contactToEliteCard.size() > 0 || existedContactsToStudentActuals.size() > 0)
           {      
               try
               {
                   updateRelatedObject(contactsToStudentActuals, updatingStudentActual);
               }
               catch(Exception ex)
               {
                   throw ex;
               }
           }
       }
   }
   
   private static void updateRelatedObject(Map<Id, StudentActual__c> contacts2StudentActuals, List<StudentActual__c> studentActuals)
   {
       List<Contact> contacts = new List<Contact>();
       isExistedNewEliteCards();
       for(Id contactId : contactToEliteCard.keySet())
       {
           String newEliteCardNo = contactToEliteCard.get(contactId);
           if(newEliteCardNo.subString(3) == 'Z9999')
           {
               throw new EliteCardException('Can\'t generate legitimate Elite Card, this school has reached max number of people!');
           }
           Contact contact = new Contact(Id = contactId, IsNewEliteCard__c = true);
           contacts.add(contact);
           StudentActual__c newStudentActual = contacts2StudentActuals.get(contactId);
           newStudentActual.EliteCard__c = newEliteCardNo;
           studentActuals.add(newStudentActual);
       }
       List<SchoolAddress__c> updatingCustomSettings = updateCustomSettingMaxSequence();
       update contacts;
       update studentActuals;
       update updatingCustomSettings;
   }
   
   private static void mapEliteCardToContact(Map<Id, StudentActual__c> contacts2StudentActuals)
   {
       Map<Id, String> eliteCardFirstThreeCharacters = generateEliteCardFirstThreeCharacters(contacts2StudentActuals);
       Map<Id, String> eliteCardLastFiveCharacters = generateEliteCardLastFiveCharacters(contacts2StudentActuals);
       for(Id contactId : contacts2StudentActuals.keySet())
       {
           String newEliteCardNo = eliteCardFirstThreeCharacters.get(contactId) + eliteCardLastFiveCharacters.get(contactId);
           if(eliteCardLastFiveCharacters.get(contactId) == 'Z9999')
           {
               throw new EliteCardException('Can\'t generate legitimate Elite Card, this school has reached max number of people!');
           }
           contactToEliteCard.put(contactId, newEliteCardNo);
       }
   }
   
   private static void howToUpdateEliteCard(StudentActual__c studentActual, Map<Id, StudentActual__c> contacts2StudentActuals, Map<Id, StudentActual__c> existedContacts2StudentActuals)
   {
       String status = '';
       if(studentActual != null)
       {
           if(!isB2BContact(studentActual.Actual__r.Sales_Appt_Locations_2__c))
           {
               if(notNullAndEmpty(studentActual.Student__r.EtownUsername__c))
               {
                   status = getCurrentContactStatusFromEtown(studentActual.Student__r.EtownUsername__c);
                   if(status == 'Active' || status == 'Suspended')
                   {
                       List<Contact> contacts = [select Id, (select Id, EliteCard__c from Student_Actuals__r where CourseActivationDate__c != null 
                                           order by CourseActivationDate__c desc nulls last, OrderStartDate__c desc nulls last, LastModifiedDate desc nulls last limit 1)
                                           from Contact where Id = :studentActual.Student__c];
                       if(contacts[0].Student_Actuals__r.size() == 0)
                       {
                           status = 'Inactive';
                       }
                   }
               }
           }
           else   
           {
               status = studentActual.Student__r.Status__c;
           }
           if((status == '' || status == null || status == 'Inactive' || status == 'Expired') && !studentActual.Student__r.IsNewEliteCard__c)
           {
               contacts2StudentActuals.put(studentActual.Student__c, studentActual);
           }
           else if(status == 'Active' || status == 'Suspended' || studentActual.Student__r.IsNewEliteCard__c == true)
           {
               existedContacts2StudentActuals.put(studentActual.Student__c, studentActual);
           } 
       }          
   }
   
   //get the existed elite card in Map<contactId. NewEliteCard>       
   private static void isExistedNewEliteCards()
   {
       if(isExistedEliteCardRunCount < 6)
       {
           Set<String> existedContactToEliteCard = getExistedStudentActuals();
           Map<Id, String> existedContactToNewEliteCard = new Map<Id, String>();
           for(Id contactId : contactToEliteCard.keySet())
           {
               String eliteCard = contactToEliteCard.get(contactId);
               if(existedContactToEliteCard.contains(eliteCard))
               {
                   existedContactToNewEliteCard.put(contactId, eliteCard);
               }
           }
           if(existedContactToNewEliteCard.size() > 0)   
           {
               isExistedEliteCardRunCount++;
               getNewContactToEliteCard(existedContactToNewEliteCard);
           }
       }
       else
       {
           throw new EliteCardException('You have a serious problem on adding products, Please contact to admin!');
       }
   }
   
   //get new contact to elite card map
   private static void getNewContactToEliteCard(Map<Id, String> existedContactToEliteCard)
   {
       for(Id contactId : existedContactToEliteCard.keySet())
       {
           String schoolName = contactToSchoolName.get(ContactId);
           Integer maxSequence = schoolNameToUpdatedMaxSequence.get(schoolName) + 1;
           schoolNameToUpdatedMaxSequence.remove(schoolName);
           String firstThreeChars = contactToEliteCard.get(contactId).substring(0, 3);
           String lastFiveChars = fromatEliteCardLastFiveCharacters(maxSequence);
           contactToEliteCard.remove(contactId);
           schoolNameToUpdatedMaxSequence.put(schoolName, maxSequence);
           contactToEliteCard.put(contactId, firstThreeChars + lastFiveChars);
       }
       isExistedNewEliteCards();    
   }
   
   // gets existed Elite card on StudentActual 
   public static Set<String> getExistedStudentActuals()
   {
       Set<String> result = new Set<String>();
       List<StudentActual__c> studentActuals = [select Id, EliteCard__c, Student__c from StudentActual__c where EliteCard__c in :contactToEliteCard.values()];
       for(StudentActual__c studentActual : studentActuals)
       {
           result.add(studentActual.EliteCard__c); 
       }
       return result;
   }

   private static List<SchoolAddress__c> updateCustomSettingMaxSequence()
   {
       List<SchoolAddress__c> result = new List<SchoolAddress__c>();
       List<SchoolAddress__c> schools = [select Name, MaxSequence__c from SchoolAddress__c where Name in :schoolNameToUpdatedMaxSequence.keySet()];
       for(SchoolAddress__c school : schools)
       {
           school.MaxSequence__c = schoolNameToUpdatedMaxSequence.get(school.Name);
           result.add(school);
       }    
       return result;
   }   
   
   private static Boolean isB2BContact(String salesAppLocation)
   {
       Boolean result = false;
       if(notNullAndEmpty(salesAppLocation) && salesAppLocation.contains('B2B'))
       {
           result = true;   
       }
       return result;
   }
   
// gets the The first three characters from elite card, (city and school code or city code from B2C or B2B contact)
   private static Map<Id, String> generateEliteCardFirstThreeCharacters(Map<Id, StudentActual__c> contantToStudentActual)
   {
       String eliteCardFirstThreeCharacters = '';
       Map<Id, String> result = new Map<Id, String>();
       for(Id contactId : contantToStudentActual.keySet())
       {
           String stuentStudyCenter = contantToStudentActual.get(contactId).EntryCenter__c;
           String salesAppLocation = contantToStudentActual.get(contactId).Actual__r.Sales_Appt_Locations_2__c;
           if(salesAppLocation == null || salesAppLocation == '' || salesAppLocation == '0')
           {
               throw new EliteCardException('Invalid Actual, please check the sales app location of the Actual.');
           }
           if(notNullAndEmpty(stuentStudyCenter))
           {
               String city = '';
               if(!isB2BContact(salesAppLocation)) // B2C
               {
                   if(!stuentStudyCenter.contains('B2B'))
                   {
                       city = stuentStudyCenter.subString(0, 2);
                       String school = stuentStudyCenter.subString(3);
                       String queryString = city + '_' + school;
                       // B2C only one query
                       List<SchoolAddress__c> schools = [select SchoolCode__c from SchoolAddress__c where Name = :queryString];
                       if(!schools.isEmpty())
                       {
                           eliteCardFirstThreeCharacters = city + schools[0].SchoolCode__c;
                       }
                       contactToSchoolName.put(contactId, queryString); // contact to school name
                   }
                   else
                   {
                       throw new EliteCardException('Please check the entry center!');
                   }
               }
               else  // B2B
               {
                   city = salesAppLocation.subString(salesAppLocation.length() - 2);
                   eliteCardFirstThreeCharacters = 'B' + city;
                   contactToSchoolName.put(contactId, city + '_All');
               }
               result.put(contactId, eliteCardFirstThreeCharacters);
           }
       }
       return result;
   }
   
   //get the the last five characters from EliteCard return a map, key:contactId value: new EliteCare No
   private static Map<Id, String> generateEliteCardLastFiveCharacters(Map<Id, StudentActual__c> contantToStudentActual)
   {   
       Map<Id, String> result = new Map<Id, String>(); // key:contactId , value:the last five chars
       Map<String, Integer> oldSchoolNameToMaxSequence = new Map<String, Integer>();
       Map<String, Integer> schoolNameToCurrentMaxSequence = new Map<String, Integer>(); 
       List<SchoolAddress__c> schools = new List<SchoolAddress__c>();
       try
       {
           schools = [select Name, MaxSequence__c from SchoolAddress__c where Name in :contactToSchoolName.values() for update];
       }
       catch(Exception ex)
       {
           throw new EliteCardException('The server is busy now, please try again later!');
       }
       for(SchoolAddress__c school : schools)
       { 
           oldSchoolNameToMaxSequence.put(school.Name, Integer.valueOf(school.MaxSequence__c));
       }
       for(Id contactId : contactToSchoolName.keySet())
       {
           String schoolName = contactToSchoolName.get(contactId);
           Integer currentMaxSequence = 0;
           if(schoolNameToCurrentMaxSequence.containsKey(schoolName))             
           {
               currentMaxSequence = schoolNameToCurrentMaxSequence.get(schoolName) + 1;
               schoolNameToCurrentMaxSequence.remove(schoolName);
           }
           else if(oldSchoolNameToMaxSequence.containsKey(schoolName))
           {
                currentMaxSequence = oldSchoolNameToMaxSequence.get(schoolName) + 1;
           }
           else
           {
               throw new EliteCardException('Invalid school name, please check it.');
           }
           String lastFiveCharacters = fromatEliteCardLastFiveCharacters(currentMaxSequence);
           result.put(contactId, lastFiveCharacters);
           schoolNameToCurrentMaxSequence.put(schoolName, currentMaxSequence);
           contactToSchoolName.put(contactId, schoolName);
       }
       schoolNameToUpdatedMaxSequence.putAll(schoolNameToCurrentMaxSequence);
       return result;
   }

   private static String fromatEliteCardLastFiveCharacters(Integer sequence)
   {
       String theLastFiveCharacters = '';  
       if(sequence != null)
       {
           Integer remainder = math.mod(sequence, 9999);
           Integer index = sequence / 9999;
           if(index < 26)
           {
                theLastFiveCharacters = getNextCharacter(index) + getFormatSequence(remainder);
           }
           else
           {
                throw new EliteCardException('Can\'t generate legitimate Elite Card, this school has reached max number of people!');
           }
       }
       return theLastFiveCharacters;
   }
    
   //gets contact status from eTown
   public static String getCurrentContactStatusFromEtown(String etownUserName)
   {
       String currentStatus;
       if(notNullAndEmpty(etownUserName))
       {
           EtownCourseService.EtownLoadStudentParams params = new EtownCourseService.EtownLoadStudentParams();
           params.Username = etownUserName;
           params.RequireSyncReschedule = true;
           EtownCourseService.EtownLoadStudentResult result;
           try
           { 
               result = EtownCourseService.loadStudentInEtown(params);
           }
           catch(Exception ex)
           {
               throw(ex);
           }
           if(result != null && result.MemberInfo != null && result.IsSuccess)
           {
               EtownCourseService.EtownMemberInfo memberInfo = result.MemberInfo;
               currentStatus = memberInfo.Status;
           }
           else
           {
               throw new EliteCardException('Etown status error. Error Message:' + result.ErrorMessage);
           }
       }
       return currentStatus;
   }

   // gets the next last character form elite card. current:XXXA9999->A, next:XXXB0001->B
   public static String getNextCharacter(Integer index)
   {
       String nextCharacter = '';
       String queryString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
       nextCharacter = queryString.subString(index, index + 1);
       return nextCharacter;
   }
   
   // gets the format sequence like 5 -> 0005
   private static String getFormatSequence(Integer sequence)  
   {
       String newSequence = '';
       if(sequence != null)
       {
           newSequence = String.valueOf(sequence).trim();
           Integer size = 4 - newSequence.length();
           for(Integer i = 0; i < size; i++)
           {
               newSequence = '0' + newSequence;
           }
       }
       return newSequence;
   }
     
   //value can not be null and empty
   public static Boolean notNullAndEmpty(String value)
   {
        return (value != null && value != '');
   }
   
   
   private static List<StudentActual__c> copyEliteCardToStudentActual(Map<Id, StudentActual__c> contactIdToStudentActual)
   {
       List<StudentActual__c> studentActuals = new List<StudentActual__c>();
       Set<Id> studentIds = new Set<Id>();
       Set<Id> lastStudentActualIds = new Set<Id>();
       Map<Id, StudentActual__c> lastActivedStudentActual = new Map<Id, StudentActual__c>();
       Map<Id, StudentActual__c> lastStudentActual = new Map<Id, StudentActual__c>();
       Map<Id, StudentActual__c> currentActivedStudentActual = new Map<Id, StudentActual__c>();
       Map<Id, StudentActual__c> currentInActivedStudentActual = new Map<Id, StudentActual__c>();
       for(Id contactId : contactIdToStudentActual.keySet())
       {
           StudentActual__c studentActual = contactIdToStudentActual.get(contactId);
           if(studentActual.Student__r.IsNewEliteCard__c)
           {
               lastStudentActualIds.add(studentActual.Student__c);
               currentInActivedStudentActual.put(studentActual.Student__c, studentActual);
           }      
           else
           {   
               studentIds.add(studentActual.Student__c);
               currentActivedStudentActual.put(studentActual.Student__c, studentActual);
           }
       }
       lastActivedStudentActual = getLastActiveStudentActuals(studentIds);
       for(Id contactId : currentActivedStudentActual.keySet())
       {
           StudentActual__c studentActual = currentActivedStudentActual.get(contactId);
           if(lastActivedStudentActual.containsKey(contactId))
           {
               studentActual.EliteCard__c = lastActivedStudentActual.get(contactId).EliteCard__c;
               studentActuals.add(studentActual);
           }
           else
           {
               throw new EliteCardException('Can\'t generate legitimate Elite Card number, this student has no activated course!');
           }
       }
       lastStudentActual = getLastStudentActuals(lastStudentActualIds);
       for(Id contactId : currentInActivedStudentActual.keySet())
       {
           StudentActual__c studentActual = currentInActivedStudentActual.get(contactId);
           studentActual.EliteCard__c = lastStudentActual.get(contactId).EliteCard__c;
           studentActuals.add(studentActual);
       }
       return studentActuals;
   }
       
   // gets the last active studentActual 
   private static Map<Id, StudentActual__c> getLastActiveStudentActuals(Set<Id> studentIds)
   {
       Map<Id, StudentActual__c> theLastActiveStudentActuals = new Map<Id, StudentActual__c>();
       List<Contact> contacts = [select Id, (select Id, EliteCard__c from Student_Actuals__r where CourseActivationDate__c != null 
                                           order by CourseActivationDate__c desc nulls last, OrderStartDate__c desc nulls last, LastModifiedDate desc nulls last limit 1)
                                           from Contact where Id in :studentIds];
       for(Contact contact : contacts)
       {
           if(contact.Student_Actuals__r.size() > 0)
           {
               theLastActiveStudentActuals.put(contact.Id, contact.Student_Actuals__r[0]);
           }
       }
       return theLastActiveStudentActuals;
   }
   
    // gets the last studentActual by new rule  
   private static Map<Id, StudentActual__c> getLastStudentActuals(Set<Id> studentIds)
   {
       Map<Id, StudentActual__c> result = new Map<Id, StudentActual__c>();
       List<Contact> contacts = [select Id, (select Id, EliteCard__c from Student_Actuals__r order by LastModifiedDate limit 1)
                                           from Contact where Id in :studentIds];
       for(Contact contact : contacts)
       {
           if(contact.Student_Actuals__r.size() > 0)
           {
               result.put(contact.Id, contact.Student_Actuals__r[0]);
           }
       }
       return result;
   }
   
   public class EliteCardException Extends Exception {}

   @isTest
   static void testB2CInactiveContactEliteCard()
   {
       Opportunity opp = new Opportunity(Location__c = 'BJ DWL', Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
       insert opp;
       Contact con = new Contact(LastNAme = 'acme', Status__c = 'Inactive');
       insert con;
       Actual__c actual = new Actual__c(Close_Date__c = Date.today(), Opportunity__c = opp.Id);
       insert actual;
       StudentActual__c sa = new StudentActual__c(Student__c = con.Id, Actual__c = actual.Id, EntryCenter__c = 'BJ DWL', CourseActivationDate__c = Date.today());
       insert sa;
       Set<Id> studentActualId = new Set<Id>();            
       studentActualId.add(sa.Id);      
       EliteCardHelper.generateEliteCardNumber(studentActualId); 
   }
   
   @isTest  
   static void testB2CActiveContactEliteCard()                      
   {
       Opportunity opp = new Opportunity(Location__c = 'BJ DWL', Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
       insert opp;
       Contact con = new Contact(LastNAme = 'acme', EtownUserName__c = 'testNameEf');
       insert con;
       Actual__c actual = new Actual__c(Close_Date__c = Date.today(), Opportunity__c = opp.Id);
       insert actual;
       StudentActual__c sa = new StudentActual__c(Student__c = con.Id, Actual__c = actual.Id, EntryCenter__c = 'BJ DWL', CourseActivationDate__c = Date.today());
       insert sa;
       Set<Id> studentActualId = new Set<Id>();            
       studentActualId.add(sa.Id);      
       EliteCardHelper.generateEliteCardNumber(studentActualId);
   }
   
   @isTest  
   static void testB2BInactiveContactEliteCard()                      
   {
       Opportunity opp = new Opportunity(Location__c = 'BJ DWL', Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
       insert opp;
       List<Contact> contacts = new List<Contact>();
       for(Integer i = 0; i < 10; i++)
       {
           Contact con = new Contact(LastName = 'EF' + i, Status__c= 'Inactive');
           contacts.add(con);
       }
       insert contacts;
       Actual__c actual = new Actual__c(Close_Date__c = Date.today(), Opportunity__c = opp.Id);
       insert actual;
       List<StudentActual__c> studentActuals = new List<StudentActual__c>();
       for(Integer i = 0; i < 10; i++)
       {
           StudentActual__c sa = new StudentActual__c(Student__c = contacts[i].Id, Actual__c = actual.Id, EntryCenter__c = 'BJ DWLTest',CourseActivationDate__c = Date.today());
           studentActuals.add(sa);
       }
       insert studentActuals;
       SchoolAddress__c schoolAddress = new SchoolAddress__c(MaxSequence__c = 0, Name = 'BJ_DWLTest', SchoolCode__c = '1');
       insert schoolAddress;
       Set<Id> studentActualIds = new Set<Id>();
       for(StudentActual__c sa : studentActuals)
       {
           studentActualIds.add(sa.Id);
       }                
       EliteCardHelper.generateEliteCardNumber(studentActualIds);
   }
   
   @isTest  
   static void testB2BActiveContactEliteCard()                      
   {
       Opportunity opp = new Opportunity(Location__c = 'B2B BJ', Name = 'test Opp', StageName = 'set Appt', CloseDate = Date.today());
       insert opp;
       Contact con = new Contact(LastNAme = 'acme', EtownUserName__c = 'testNameEf');
       insert con;
       Actual__c actual = new Actual__c(Close_Date__c = Date.today(), Opportunity__c = opp.Id);
       insert actual;
       StudentActual__c sa = new StudentActual__c(Student__c = con.Id, Actual__c = actual.Id, EntryCenter__c = 'B2B BJ');
       insert sa;
       Set<Id> studentActualIds = new Set<Id>();            
       studentActualIds.add(sa.Id);      
       EliteCardHelper.generateEliteCardNumber(studentActualIds);
   }
}