/*
*   This class for auto assignment logic. It is a base class.
*/
public abstract class AutoAssignmentBase 
{ 
    public String autoAssignEvent(Opportunity currentOpportunity)
    {	System.debug('Debug Information In method autoAssignEvent()' + currentOpportunity.Id);
    	String assignUserId = null;
        if(currentOpportunity != null)
        {
            // Get auto assignment user id.
            assignUserId = autoAssignUser(currentOpportunity);system.debug('@@@@@@ HT_ assignUserId' + assignUserId);
            if(assignUserId != null)
            {
            	// Judgment whether this opportunity had been auto assigned.
            	List<China_Appt_Assignment_Report__c> reports = [select Id from China_Appt_Assignment_Report__c where Opportunity__c = :currentOpportunity.Id];
	 			if(reports.size() > 0)
	 			{
	 				throw new OpportunityAssignedException('Opportunity "'+currentOpportunity.Name+'" had been auto assigned.');
	 			}
                // Assigns Account and opportunity.
                assignAccountAndOpportunity(assignUserId, currentOpportunity);
                // Assigns event and report.
                createEventAndReport(assignUserId, currentOpportunity);
            }
        }
        return assignUserId;
    }
    
     // Processes outbound, ts, brazil
    public String handleAssignment(Map<String, Double> userToAllocation, Datetime assignDatetime, Set<String> allUserIds)
    {
        String resultId;
        if(userToAllocation != null && assignDatetime != null && allUserIds != null)
        {
            //1. 计算所有人的完成率(日/月)
            List<SaleAssignInfo> salesFinishedRates = calculateFinishedRate(userToAllocation, allUserIds, assignDatetime);
            //2. 找出日完成率最小的人
             List<SaleAssignInfo> minDailyFinishedRates = getMinDailyFinishedRates(salesFinishedRates);
            //3. 如果日完成率最小的人是一个,则直接分配给他
            if(minDailyFinishedRates.size() == 1)
            {	System.debug('Debug Information#最小完成率是一人');
                resultId = minDailyFinishedRates.get(0).userId;
            }
            else if(minDailyFinishedRates.size() > 1)
            { // 如果多个人日最小完成率相同。
                if(minDailyFinishedRates[0].dailyFinishedRate == 0)
                { 
                    //4. 如果日最小完成率=0,则按分配比最大的人分配
                    resultId = assignWithAllocation(minDailyFinishedRates);
                }
                else
                { 
                    //5. 如果日最小完成率>0, 则取月最小完成率
                    List<SaleAssignInfo> minMonthlyRates = getMinMonthlyFinishedRates(minDailyFinishedRates);
                    if(minMonthlyRates.size() == 1)
                    {
                        //6. 如果月最小完成率为一人,则分配给他
                        resultId = minMonthlyRates[0].userId;
                    }
                    else if(minMonthlyRates.size() > 1)
                    {
                        //7. 月最小完成率最小为多人,按分配比最大的人分配
                        resultId = assignWithAllocation(minMonthlyRates);
                    }
                }
            }
        }
        return resultId;
    }
    
    // Processes inbound and other status. This method can be overwrite future.
    public virtual String handleAssignmentExtension(Map<String, Double> userToAllocation, Datetime assignDatetime, Set<String> allUserIds)
    {
        String resultId = null;
        if(userToAllocation != null && assignDatetime != null && allUserIds != null)
        {
            //1. 获取完成率(日/月)
            List<SaleAssignInfo> saleFinishedRates =  calculateFinishedRate(userToAllocation, allUserIds, assignDatetime);
            //2. 取日最小完成率的人
            List<SaleAssignInfo> minDailyFinishedRates = getMinDailyFinishedRates(saleFinishedRates);
            if(minDailyFinishedRates.size() == 1)
            {
                //3. 如果日最小完成率为一个人,则直接分配给他
                resultId = minDailyFinishedRates.get(0).userId;
            }
            else if(minDailyFinishedRates.size() > 1)
            {
                if(minDailyFinishedRates[0].dailyFinishedRate == 0)
                {   // 如果多个人日最小完成率相同
                    //4. 如果日最小完成率是多个人,且完成率=0, 则取月最小完成率
                    List<SaleAssignInfo> minMonthlyFinishedRates = getMinMonthlyFinishedRates(minDailyFinishedRates);
                    if(minMonthlyFinishedRates.size() == 1)
                    {
                        //5. 如果月最小完成率是一个人,则直接分配给他
                        resultId = minMonthlyFinishedRates[0].userId;
                    }
                    else if(minMonthlyFinishedRates.size() > 1)
                    {
                        //6. 如果月最小完成率是多人,则按分配比最大的人分配
                        resultId = assignWithAllocation(minMonthlyFinishedRates);
                    }
                }
                else
                { //7. 如果最小日完成率是多人且完成率>0,则随机分配
                    resultId = getRandomUserId(minDailyFinishedRates);
                }
            }
        } 
        return resultId;
    }
    
    private void assignAccountAndOpportunity(String userId, Opportunity currentOpportunity)
    {
        if(userId != null)
        {
            if(currentOpportunity.AccountId != null)
            {
                Account relatedAccount = new Account(Id = currentOpportunity.AccountId, OwnerId = userId);
                update relatedAccount;
            }
            currentOpportunity.Auto_Assignment__c = true;
            currentOpportunity.OwnerId = userId;
            if(currentOpportunity.Initial_Appt_Date__c != null)
            {
                currentOpportunity.CloseDate = Date.newInstance(currentOpportunity.Initial_Appt_Date__c.year(), currentOpportunity.Initial_Appt_Date__c.month(), currentOpportunity.Initial_Appt_Date__c.day());
            }
            update currentOpportunity;
        }
    }

    // 获取日最小完成率.
    private List<SaleAssignInfo> getMinDailyFinishedRates(List<SaleAssignInfo> saleFinishedRates)
    {
        List<SaleAssignInfo> resultList = new List<SaleAssignInfo>();
        if(saleFinishedRates != null && saleFinishedRates.size() > 0)
        {
            Double tempRate = saleFinishedRates[0].dailyFinishedRate;
            for(SaleAssignInfo tempInfo : saleFinishedRates)
            {
                if(tempInfo.dailyFinishedRate < tempRate)
                {
                    resultList.clear();
                    tempRate = tempInfo.dailyFinishedRate;
                    resultList.add(tempInfo);
                }
                else if(tempInfo.dailyFinishedRate == tempRate)
                {
                    resultList.add(tempInfo);
                }
            }
        }
        return resultList;
    }
    
    // 获取月最小完成率.
    private List<SaleAssignInfo> getMinMonthlyFinishedRates(List<SaleAssignInfo> saleFinishedRates)
    {
        List<SaleAssignInfo> resultList = new List<SaleAssignInfo>();
        if(saleFinishedRates != null && saleFinishedRates.size() > 0)
        {	
            Double tempRate = saleFinishedRates[0].monthlyFinishedRate;
            for(SaleAssignInfo tempInfo : saleFinishedRates)
            {  
                if(tempInfo.monthlyFinishedRate < tempRate)
                {
                	resultList.clear();
                    tempRate = tempInfo.monthlyFinishedRate;
                    resultList.add(tempInfo);
                }
                else if(tempInfo.monthlyFinishedRate == tempRate)
                { 
                    resultList.add(tempInfo);
                }
            }
        }
        return resultList;
    }
    
    // 按 allocation 分配. 分配给分配比率最大的人
    private String assignWithAllocation(List<SaleAssignInfo> saleFinishedRates)
    {
        String resultId;
        if(saleFinishedRates != null && saleFinishedRates.size() > 0)
        {	
        	List<SaleAssignInfo> maxAllocations = new List<SaleAssignInfo>(); // Stores SaleAssignInfo for max allocations.
            Double maxAllocation = 0;
            for(SaleAssignInfo tempInfo : saleFinishedRates)
            {
                if(tempInfo.allocationRate > maxAllocation)
                {
                    maxAllocation = tempInfo.allocationRate;
                    maxAllocations.clear();
                    maxAllocations.add(tempInfo);
                }
                else if(tempInfo.allocationRate == maxAllocation)
                {
                    maxAllocations.add(tempInfo);
                }
            }
            resultId = getRandomUserId(maxAllocations);
        }
        return resultId;
    }
    
    // 得到 最大Id.
    private String getRandomUserId(List<SaleAssignInfo> saleFinishedRates)
    {
        String resultId;
        if(saleFinishedRates != null && saleFinishedRates.size() > 0)
        {
        	Integer resultIndex = generateRandomNumber(saleFinishedRates.size());
        	resultId = saleFinishedRates[resultIndex].userId;
        }
        return resultId;
    }   

	// Calculate random unmber.
	private Integer generateRandomNumber(Integer maxCount)
	{
		if(maxCount != null)
		{
			Double randomNumber = Math.random() * maxCount;
			randomNumber = Math.floor(randomNumber);
			return randomNumber.intValue();
		}
		return null;
	}
	
    // Calculate user finished rate
    private List<SaleAssignInfo> calculateFinishedRate(Map<String, Double> userToAllocation, Set<String> allUserIds, Datetime assignDatetime)
    {
        if(userToAllocation != null && assignDatetime != null && allUserIds != null)
        {
            List<SaleAssignInfo> resultList = new List<SaleAssignInfo>();
            Map<String, CountInfo> salesCountMap = new Map<String, CountInfo>(); 
            List<Integer> totalReportCounts = calculateReportCount(salesCountMap, assignDatetime, userToAllocation.keySet(), allUserIds);
            if(totalReportCounts != null)
            {
                Integer dailyCount = totalReportCounts[0]; 
                Integer monthlyCount = totalReportCounts[1]; 

                Map<String, Double> idealRateMap = calculateAllocationRate(userToAllocation);
                // Calculate finished rate.
                for(String userId : userToAllocation.keySet())
                {
                    Double tempAllocationRate = userToAllocation.get(userId);
                    SaleAssignInfo newAssignInfo = new SaleAssignInfo(userId, tempAllocationRate); // Stores assignment information.
                    
                    if(salesCountMap.containsKey(userId))
                    {
                        CountInfo tempCountInfo = salesCountMap.get(userId); // SalesCountInfo 中存储了销售当天当月的实际分配量。
                        // 销售 当天当月应分配量。
                        Double allocationRate = idealRateMap.get(userId); 
                        Double saleDailyAllocableCount = dailyCount * allocationRate; 
                        Double saleMonthlyAllocableCount = monthlyCount * allocationRate; 
                        // 分配率 = 实际分配量 / 应分配量。
                        newAssignInfo.dailyFinishedRate = (saleDailyAllocableCount != 0) ? tempCountInfo.dailyCount / saleDailyAllocableCount : 0; 
                        newAssignInfo.monthlyFinishedRate = (saleMonthlyAllocableCount != 0) ? tempCountInfo.monthlyCount / saleMonthlyAllocableCount : 0;
                    	System.debug('Debug Information#当前销售Id:' + newAssignInfo.userId + '#设定分配比例:' + newAssignInfo.allocationRate + '#当日已分配:' + tempCountInfo.dailyCount + '#当月已分配:' + tempCountInfo.monthlyCount + '#日应分配:' + saleDailyAllocableCount + '#月应分配:' + saleMonthlyAllocableCount);
                    	System.debug('Debug Information#日完成率:' + newAssignInfo.dailyFinishedRate + '#月完成率:' + newAssignInfo.monthlyFinishedRate);
                    }
                    resultList.add(newAssignInfo);
                }
            } 
            return resultList;
        }
        return null;
    } 
    
    // Calculate the sum of allocation. When total allocation is 0, a exception will happen.
    private Map<String, Double> calculateAllocationRate(Map<String, Double> userToAllocation)
    { // 计算应分配率
        Double totalAllocation = 0;
        if(userToAllocation != null)
        {
            for(Double allocation : userToAllocation.values())
            {
                totalAllocation += allocation;  
            }
        }
        System.debug('Debug Information#总分配比率:' + totalAllocation);
        Map<String, Double> resultMap = new Map<String, Double>();
        for(String userId : userToAllocation.keySet())
        {
            resultMap.put(userId, userToAllocation.get(userId)/totalAllocation);
        }
        return resultMap;
    }

	// Calculate sale's daily and monthly assignments.
    public virtual void calculateReportCountForOndutySale(Map<String, CountInfo> salesCountMap, Set<String> ondutyUserIds, China_Appt_Assignment_Report__c assignReport, String day)
    {
        if(salesCountMap != null && ondutyUserIds != null && assignReport != null)
        {
            if(ondutyUserIds.contains(assignReport.Sales_Consultant__c))
            {
                if(salesCountMap.containsKey(assignReport.Sales_Consultant__c))
                { // If the sales data has been exit in map.
                    CountInfo tempCountInfo = salesCountMap.get(assignReport.Sales_Consultant__c);
                    tempCountInfo.monthlyCount++;
                    if(assignReport.Day__c == day)
                    {
                        tempCountInfo.dailyCount++;
                    }
                }
                else
                {
                    countInfo newCountInfo = new CountInfo();
                    newCountInfo.userId = assignReport.Sales_Consultant__c;
                    newCountInfo.monthlyCount++;
                    if(assignReport.Day__c == day)
                    {
                        newCountInfo.dailyCount++;
                    }
                    salesCountMap.put(assignReport.Sales_Consultant__c, newCountInfo);
                }
            }
        }
    }
    
    // Get all sales that on duty and allocation is not equal null.
    //returns a map with key: user id, value: allocation percentage
    public virtual Map<String, Double> getUserAllocation(Set<String> userIds, Datetime assignDatetime)
    {
        if(userIds != null && assignDatetime != null)
        {   // Select on duty users.
            String strYear = String.valueOf(assignDatetime.year());
            String strMonth = String.valueOf(assignDatetime.month());
            String strDay = String.valueOf(assignDatetime.day());
            List<Sales_Monthly_Details__c> salesMonthlyDetails  = [select Sales_Consultant__c, Sales_Consultant__r.Alias from Sales_Monthly_Details__c where Year__c=:strYear and Month__c =:strMonth and day__c=:strDay and Day_Status__c='On Duty' and Sales_Consultant__c in :userIds];
            Set<String> ondutyUserIds = new Set<String>(); 
            for(Sales_Monthly_Details__c detail : salesMonthlyDetails)
            {
                ondutyUserIds.add(detail.Sales_Consultant__c);
            } 
            // Select current month allocation(on duty sales).
            Map<String, Double> resultMap = new Map<String, Double>();
            List<Sales_Team_Appointment_Allocation__c> currentMonthAllocations = [select Allocation__c, Sales_consultant__c, School__c from Sales_Team_Appointment_Allocation__c where Year__c =:strYear and Month__c =:strMonth and Allocation__c != 'undefined' and Sales_consultant__c in :ondutyUserIds order by LastModifiedDate DESC];
            for(Sales_Team_Appointment_Allocation__c allocation : currentMonthAllocations)
            {
                if(allocation.Allocation__c != null && allocation.Allocation__c != 'undefined')
                {
                    String tempAllocation = allocation.Allocation__c.replace('%','');
                    resultMap.put(allocation.Sales_consultant__c, Double.valueOf(tempAllocation)/100);
                }
            } 
            return resultMap;
        }
        return null;
    }

    // Create a queue.
    public void createQueue(Opportunity opp, String schoolName, String reason)
    {
    	if(opp != null)
    	{
			DateTime eventDateTime = opp.Initial_Appt_Date__c; //String schoolName = opp.Location__c;
			String oppId = opp.Id;
			List<Auto_Assignment_Queue__c> assignmentQueues = [select Id from Auto_Assignment_Queue__c where Event_DateTime__c =:eventDateTime and School__c =:schoolName and Opportunity__c =:oppId];
			if(assignmentQueues.size() == 0)
			{
				Auto_Assignment_Queue__c newQueue = new Auto_Assignment_Queue__c();
				newQueue.School__c = schoolName;
				newQueue.Event_DateTime__c = eventDateTime;
				newQueue.Opportunity__c = oppId;
				newQueue.Queue_Reson__c = reason;
				newQueue.Status__c = 'Queue';
				insert newQueue;
			}
    	}
    }
    
    // Changes queue status.
    public void changeQueueStatus(String oppId)
    {
    	if(oppId != null)
    	{
    		List<Auto_Assignment_Queue__c> oldQueues = [select Id, Status__c from Auto_Assignment_Queue__c where Opportunity__c =:oppId];
    		for(Auto_Assignment_Queue__c queue : oldQueues)
    		{
    			queue.Status__c = 'Assigned'; 
    		}
    		update oldQueues;
    	}
    }

	abstract List<Integer> calculateReportCount(Map<String, CountInfo> salesCountMap, Datetime assignDatetime, Set<String> ondutyUserIds, Set<String> allUserIds);
	
    // Gets all user in current location.
    abstract  set<String> getCurrentUserGroup(Opportunity currentOpportunity);
    
    abstract void createEventAndReport(String userId, Opportunity tempOpportunity);

    abstract String autoAssignUser(Opportunity tempOpportunity);

	public class NoSaleUserException extends Exception {}
	
	public class OpportunityAssignedException extends Exception{}
	
    public class SaleAssignInfo
    {
        public String userId;
        public Double dailyFinishedRate = 0;
        public Double monthlyFinishedRate = 0;
        public Double allocationRate = 0;
        
        public SaleAssignInfo(String idValue, Double allocValue)
        {
            userId = idValue;
            allocationRate = allocValue;
        }
    }
    
    public class CountInfo
    {
        public String userId = null;
        public Integer dailyCount = 0;
        public Integer monthlyCount = 0;
    }

}