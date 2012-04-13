/*
 * Controller of page TeacherRelatedInfo
 * Pony Ma 2012-02-17 Added a new section
 */
public class TeacherRelatedInfoController 
{
    private Contact contactRecord;
    
    public TeacherRelatedInfoController(ApexPages.StandardController controller)
    {
        contactRecord = (Contact)controller.getRecord();
        if(contactRecord.Id != null)
        {
            List<Teacher_related_information__c> teacherInfos = [select Id, Name__c, Name, Recruitment_Status__c, Available_date__c, Native_Language__c, CV_Source__c, Other_Language__c, Referred_by__c, Proficiency__c, Teaching_Field__c, More_languages__c, Years_of_teaching__c, Tertiary_qualification__c, ESL_qualification__c,Probation_Start_Date__c,
            Bank_form__c,CSA__c,Met_with_mentor__c,NDA__c,Observation_1__c,Observation_2__c,Observation_3__c,Observation_4__c,Observation_5__c,Profile_photo_uploaded__c,Profile_updated__c,Training_completed__c from Teacher_related_information__c where Name__c=:contactRecord.Id order by CreatedDate limit 1];
            if(teacherInfos.size() == 1)
            {
                TeacherInfo = teacherInfos[0];
            }
            if(TeacherInfo == null)
            {
                TeacherInfo = new Teacher_related_information__c(Name__c=contactRecord.Id);
                TeacherInfo.Recruitment_Status__c = '';
                TeacherInfo.CV_Source__c = '';
                TeacherInfo.ESL_qualification__c ='';
                TeacherInfo.Teaching_Field__c ='';
                TeacherInfo.Years_of_teaching__c ='';
                TeacherInfo.Proficiency__c ='';
                TeacherInfo.Tertiary_qualification__c ='';
                
            }
            List<Teacher_Induction_Training__c> trainingInfos = [select X1_step1__c, Date1__c, Class_time_NYT_1__c, X1_teacher_name__c, X2_step2__c, Date2__c, Class_time_NYT_2__c, X2_teacher_name__c, X3_step3__c, Date3__c, Class_time_NYT_3__c, X3_teacher_name__c, X4_step4__c, Date4__c, Class_time_NYT_4__c, X4_teacher_name__c, X5_step5__c, Date5__c, Class_time_NYT_5__c, X5_teacher_name__c from Teacher_Induction_Training__c where Contact__c=:contactRecord.Id order by CreatedDate limit 1];
            if(trainingInfos.size() == 1)
            {
                Training = trainingInfos[0];
            }
        }
    }
    
    public Teacher_Induction_Training__c Training { get; set;}
    public Teacher_related_information__c TeacherInfo { get; set; }
    public Boolean IsEditing { get; set; } // if show the specific page or not
    
    public List<TrainingInfo> Trainings
    {
        get
        {
            List<TrainingInfo> result = new List<TrainingInfo>();
            if(Training != null)
            {
	            if(Training.X1_step1__c == true)
	            {
	                result.add(new TrainingInfo(Training.X1_step1__c, Training.Date1__c, Training.Class_time_NYT_1__c, Training.X1_teacher_name__c));
	            }
	            if(Training.X2_step2__c == true)
	            {
	                result.add(new TrainingInfo(Training.X2_step2__c, Training.Date2__c, Training.Class_time_NYT_2__c, Training.X2_teacher_name__c));
	            }
	            if(Training.X3_step3__c == true)
	            {
	                result.add(new TrainingInfo(Training.X3_step3__c, Training.Date3__c, Training.Class_time_NYT_3__c, Training.X3_teacher_name__c));
	            }
	            if(Training.X4_step4__c == true)
	            {
	                result.add(new TrainingInfo(Training.X4_step4__c, Training.Date4__c, Training.Class_time_NYT_4__c, Training.X4_teacher_name__c));
	            }
	            if(Training.X5_step5__c == true)
	            {
	                result.add(new TrainingInfo(Training.X5_step5__c, Training.Date5__c, Training.Class_time_NYT_5__c, Training.X5_teacher_name__c));
	            }
            }
            return result;
            
        }
    }
       
    public PageReference save()
    {
        try
        {
            upsert TeacherInfo;
            this.IsEditing = false; 
        }
        catch(Exception ex)
        {
            ApexPages.addMessages(ex);
        }
        return null;
    }
    
    public PageReference cancel()
    {
        this.IsEditing = false;
        return null;
    }
    
    public PageReference edit()
    {
        this.IsEditing = true;
        return null;
    }
    
    public class TrainingInfo
    {
        public TrainingInfo(Boolean isChecked, Date trainingDate, String classTime, String teacherName)
        {
            this.IsChecked = isChecked;
            this.TrainingDate = trainingDate;
            this.ClassTime = classTime;
            this.TeacherName = teacherName;
        }
        
        public Boolean IsChecked { get; set; }
        public Date TrainingDate { get; set; }
        public String ClassTime { get; set; }
        public String TeacherName { get; set; }
    }
    
    @isTest
    static void testTeacherRelatedInfoController()
    {
        Contact contact = new Contact(LastName='Acme', OwnerId=UserInfo.getUserId());
        insert contact;
        Teacher_Induction_Training__c trainings = new Teacher_Induction_Training__c(Date1__c=Date.today(), Contact__c=contact.Id, X1_step1__c=true, X2_step2__c=true, X3_step3__c=true, X4_step4__c=true, X5_step5__c=true, Class_time_NYT_1__c='');
		insert trainings;
        ApexPages.StandardController controller = new ApexPages.StandardController(contact);
        TeacherRelatedInfoController triController = new TeacherRelatedInfoController(controller);   
        triController.Training = trainings;
        triController.Cancel();
        triController.Save();
        triController.edit();
        System.assert(triController.Trainings != null);
    }
}