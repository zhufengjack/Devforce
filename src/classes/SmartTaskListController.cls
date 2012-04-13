/*
 *A controller of show task list in home page.
 */
public class SmartTaskListController 
{
    public List<TaskInfo> Tasks
    {
        get
        {
            List<TaskStatus> taskStatuses = [select IsClosed, MasterLabel from TaskStatus];
            List<TaskInfo> result = new List<TaskInfo>();
            List<Task> taskList = [select Id, WhatId, Subject, Comments__c, Status, Appt_Status__c from Task where OwnerId = :UserInfo.getUserId() and ActivityDate=:Date.Today()];
            Map<Id, Id> task2Opp = new Map<Id, Id>();  //key: taskId, value: oppId
            for(Task task : taskList) 
            {
                task2Opp.put(task.Id, task.WhatId);
            }
            
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();  //key: oppId, value: opp
            for(Opportunity opp : [select Id, StageName, Name, Mobile__c from Opportunity where Id in :task2Opp.values()])
            {
                oppMap.put(opp.Id, opp);
            }
            for(Task task : taskList)
            {
                    Opportunity opp = oppMap.get(task2Opp.get(task.Id));
                    if(opp != null)
                    {
                        result.add(new TaskInfo(task, opp, taskStatuses));
                    }
            }
            return result;
        }
    }
    
    public class TaskInfo
    {
        private Set<String> closedStatusList;
        private Task internalTask;
        private Opportunity internalOpp;
        private List<TaskStatus> taskStatuses;
            
        public TaskInfo(Task task, Opportunity opp, List<TaskStatus> statuses)
        {
            this.internalTask = task;
            this.internalOpp = opp;
            this.taskStatuses = statuses;
            this.TaskSubject = task.Subject;
            this.TaskComments = task.Comments__c;
            this.TaskAppStatus = task.Status;
            this.TaskId = task.Id;
            this.TaskRelatedName = opp.Name;
            this.OppStage = opp.StageName;
            this.OppId = opp.Id;
            this.Mobile = opp.Mobile__c;
        }
        
        public String TaskId { get; set; }
        public String OppId { get; set; }
        public String TaskRelatedName { get; set; }
        public String TaskSubject { get; set; }
        public String OppStage { get; set; }
        public String TaskAppStatus { get; set; }
        public String TaskComments { get; set; }
        public String Mobile { get; set; }
          
        public Boolean IsDone
        {
            get
            {
                Boolean result = false;
                Set<String> statusSet = getClosedStatus();
                result = statusSet.contains(internalTask.Status);
                if(internalTask.Status == 'Completed' && (internalTask.Comments__c == null || internalTask.Comments__c.trim() == ''))
                {
                    result = false;
                }
                return result;
            }
            set {}
        }
        
        //gets all task status that is configured to be closed
        private Set<String> getClosedStatus()
        {
            if(closedStatusList == null)
            {
                closedStatusList = new Set<String>();
                for(TaskStatus taskStatus : taskStatuses)
                {
                    if(taskStatus.IsClosed)
                    {   
                        closedStatusList.add(taskStatus.MasterLabel);
                    }
                }
            }
            return closedStatusList;
        }
    }
    
    @isTest
    static void testSmartTaskListController()
    {
        Opportunity opp = new Opportunity(Name = 'acme', StageName = 'acme', CloseDate = Date.today());
        insert opp;
        Task newTestTask = new Task(OwnerId=UserInfo.getUserId(), ActivityDate = Date.today(), WhatId = opp.Id);
        insert newTestTask;
        
        SmartTaskListController controller = new SmartTaskListController();
        System.assert(controller.Tasks.size() >= 1);
        SmartTaskListController.TaskInfo testTask = controller.Tasks[0];
        System.assertEquals(false, testTask.IsDone);
    }
}