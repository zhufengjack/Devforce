/*
 * Controller of page InductionAndTraining
 */
public class InductionAndTrainingController
{
    public InductionAndTrainingController()
    { 
    	User currentUser = [select Id, ContactId from User where Id=:UserInfo.getUserId() limit 1];
    	if(currentUser.ContactId != null)
    	{
    		generateTrainingData(currentUser);
    	}
    	else
    	{
    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only teacher is allowed to access this page.'));
    		IsTeacher = false;
    	}
    }
    
    public Teacher_Induction_Training__c Training { get; set; }
    public Boolean IsTeacher { get; set; }
    
    private void generateTrainingData(User user)
    {
    	List<Teacher_Induction_Training__c> trainings = [select X1_step1__c, Date1__c, Class_time_NYT_1__c, X1_teacher_name__c, X2_step2__c, Date2__c, Class_time_NYT_2__c, X2_teacher_name__c, X3_step3__c, Date3__c, Class_time_NYT_3__c, X3_teacher_name__c, X4_step4__c, Date4__c, Class_time_NYT_4__c, X4_teacher_name__c, X5_step5__c, Date5__c, Class_time_NYT_5__c, X5_teacher_name__c from Teacher_Induction_Training__c where Contact__c=:user.ContactId order by CreatedDate limit 1];
		if(trainings.size() == 1)
		{
			Training = trainings[0];
		}
		else
		{
			Training = new Teacher_Induction_Training__c(Contact__c = user.ContactId);
		}
		IsTeacher = true;
    }
	public PageReference save()
	{
		if(isValid())
		{
			try
			{ 
	    		upsert Training;		
	    		ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Successfully saved.'));
			} 
			catch(Exception ex)
			{
				ApexPages.addMessages(ex);
			}
		}
		return null;
	}
	
	private Boolean isValid()
	{
		Boolean isValid = true;
		if(!((Training.Date1__c != null && !IsNullOrEmpty(Training.Class_time_NYT_1__c) && !IsNullOrEmpty(Training.X1_teacher_name__c) && Training.X1_step1__c == true) || (Training.Date1__c == null && IsNullOrEmpty(Training.Class_time_NYT_1__c) && IsNullOrEmpty(Training.X1_teacher_name__c) && (Training.X1_step1__c == null || Training.X1_step1__c == false))))
		{
			if(!IsNullOrEmpty(Training.Class_time_NYT_1__c) && !IsNullOrEmpty(Training.X1_teacher_name__c) && Training.Date1__c != null && (Training.X1_step1__c == null || Training.X1_step1__c == false))
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please tick the box next to the number before you save it.'));	
			}
			else
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill all the fields in row 1 before saving.'));			
			}
		}
	
		if(!((Training.Date2__c != null && !IsNullOrEmpty(Training.Class_time_NYT_2__c) && !IsNullOrEmpty(Training.X2_teacher_name__c) && Training.X2_step2__c == true) || (Training.Date2__c == null && IsNullOrEmpty(Training.Class_time_NYT_2__c) && IsNullOrEmpty(Training.X2_teacher_name__c) && (Training.X2_step2__c == null || Training.X2_step2__c == false))))
		{
			if(!IsNullOrEmpty(Training.Class_time_NYT_2__c) && !IsNullOrEmpty(Training.X2_teacher_name__c) && Training.Date2__c != null && (Training.X2_step2__c == null || Training.X2_step2__c == false))
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please tick the box next to the number before you save it.'));	
			}
			else
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill all the fields in row 2 before saving.'));			
			}
		}
		if(!((Training.Date3__c != null && !IsNullOrEmpty(Training.Class_time_NYT_3__c) && !IsNullOrEmpty(Training.X3_teacher_name__c) && Training.X3_step3__c == true) || (Training.Date3__c == null && IsNullOrEmpty(Training.Class_time_NYT_3__c) && IsNullOrEmpty(Training.X3_teacher_name__c) && (Training.X3_step3__c == null || Training.X3_step3__c == false))))
		{
			if(!IsNullOrEmpty(Training.Class_time_NYT_3__c) && !IsNullOrEmpty(Training.X3_teacher_name__c) && Training.Date3__c != null && (Training.X3_step3__c == null || Training.X3_step3__c == false))
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please tick the box next to the number before you save it.'));	
			}
			else
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill all the fields in row 3 before saving.'));			
			}
		}
		if(!((Training.Date4__c != null && !IsNullOrEmpty(Training.Class_time_NYT_4__c) && !IsNullOrEmpty(Training.X4_teacher_name__c) && Training.X4_step4__c == true) || (Training.Date4__c == null && IsNullOrEmpty(Training.Class_time_NYT_4__c) && IsNullOrEmpty(Training.X4_teacher_name__c) && (Training.X4_step4__c == null || Training.X4_step4__c == false))))
		{
			if(!IsNullOrEmpty(Training.Class_time_NYT_4__c) && !IsNullOrEmpty(Training.X4_teacher_name__c) && Training.Date4__c != null && (Training.X4_step4__c == null || Training.X4_step4__c == false))
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please tick the box next to the number before you save it.'));	
			}
			else
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill all the fields in row 4 before saving.'));	
			}
		}
		if(!((Training.Date5__c != null && !IsNullOrEmpty(Training.Class_time_NYT_5__c) && !IsNullOrEmpty(Training.X5_teacher_name__c) && Training.X5_step5__c == true) || (Training.Date5__c == null && IsNullOrEmpty(Training.Class_time_NYT_5__c) && IsNullOrEmpty(Training.X5_teacher_name__c) && (Training.X5_step5__c == null || Training.X5_step5__c == false))))
		{
			if(!IsNullOrEmpty(Training.Class_time_NYT_5__c) && !IsNullOrEmpty(Training.X5_teacher_name__c) && Training.Date5__c != null && (Training.X5_step5__c == null || Training.X5_step5__c == false))
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please tick the box next to the number before you save it.'));	
			}
			else
			{
				isValid = false;
				ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please fill all the fields in row 5 before saving.'));
			}
		}
		return isvalid;
	}
	
	private Boolean IsNullOrEmpty(String value)
	{
		return (value == null || value == '');
	}
	
	@isTest 
	static void testInductionAndTrainingController()
	{
		Contact contact = new Contact(LastName='Acme', OwnerId=UserInfo.getUserId());
		insert contact;
		List<Teacher_Induction_Training__c> trainings = new List<Teacher_Induction_Training__c>
		{
			new Teacher_Induction_Training__c(Date1__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_1__c='', X1_Teacher_Name__c =''),
			new Teacher_Induction_Training__c(Date1__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_1__c ='00:00', X1_Teacher_Name__c='test1'),
			new Teacher_Induction_Training__c(Date2__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_2__c='', X2_Teacher_Name__c =''),
			new Teacher_Induction_Training__c(Date2__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_2__c ='00:00', X2_Teacher_Name__c='test2'),
			new Teacher_Induction_Training__c(Date3__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_3__c='', X3_Teacher_Name__c =''),
			new Teacher_Induction_Training__c(Date3__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_3__c ='00:00', X3_Teacher_Name__c='test3'),
			new Teacher_Induction_Training__c(Date4__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_4__c='', X4_Teacher_Name__c =''),
			new Teacher_Induction_Training__c(Date4__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_4__c ='00:00', X4_Teacher_Name__c='test4'),
			new Teacher_Induction_Training__c(Date5__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_5__c='', X5_Teacher_Name__c =''),
			new Teacher_Induction_Training__c(Date5__c=Date.today(), Contact__c=contact.Id, X1_step1__c=false, X2_step2__c=false, X3_step3__c=false, X4_step4__c=false, X5_step5__c=false, Class_time_NYT_5__c ='00:00', X5_Teacher_Name__c='test5')
		};
		insert trainings;
		InductionAndTrainingController controller = new InductionAndTrainingController();
		System.assert(controller.IsTeacher == false);
		controller.generateTrainingData(new User(Id=UserInfo.getUserId()));
		for(Integer i = 0; i < trainings.size(); i++)
		{
			controller.Training = trainings[i];
			controller.save();
		}
	}
}