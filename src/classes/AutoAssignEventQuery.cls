global class AutoAssignEventQuery { 
    WebService static List<Event> getEvents(String salesIds,String dateString)
    {
        String[] arrIds = salesIds.split(',',0);
        String[] arrDate = dateString.split('/',0);
            Date smReportDay = Date.newInstance(Integer.valueOf(arrDate[0]),Integer.valueOf(arrDate[1]),Integer.valueOf(arrDate[2]));
        List<Event> events = [select Id,OwnerId,WhatId,ActivityDate,
                            ActivityDateTime from 
                            Event 
                            where RecordType.name = 'CN F2F Sales Meeting' 
                            and OwnerId in:arrIds and ActivityDate = :smReportDay 
                            and Auto_Assignment__c = true];
        
        return events;
    }
    
    //@future
    WebService Static void AutoAssignQueue(String queueIds)
    {
        if(queueIds != null && queueIds != '')
        {
            String[] arrIds = queueIds.split(',',0);
            List<Auto_Assignment_Queue__c> queues = [select OwnerId,Opportunity__c,Opportunity__r.AccountId,Opportunity__r.Name,
            Event_DateTime__c,Status__c 
            from Auto_Assignment_Queue__c where Id in:arrIds and Status__c='Queue' order by CreatedDate DESC];
            String strOpportunityId  ='';
            Map<Id,Integer> mapOpportunity = new Map<Id,Integer>();
            List<String> opportunityIds = new List<String>();
            Map<Id,Integer> assignedOpportunityIds = new Map<Id,Integer>();
            Map<Id,Auto_Assignment_Queue__c> oppQueues = new Map<Id,Auto_Assignment_Queue__c>();
            for(Auto_Assignment_Queue__c queue:queues)
            {
                //业务机会名称输出
                system.debug('......业务机会名称：'+queue.Opportunity__r.Name);
                strOpportunityId = queue.Opportunity__c;
                if(!mapOpportunity.containsKey(strOpportunityId))
                {
                    mapOpportunity.put(strOpportunityId,1);
                    oppQueues.put(strOpportunityId,queue);
                    opportunityIds.add(strOpportunityId);
                }
            }
            List<China_Appt_Assignment_Report__c> reports = [select Id,Opportunity__c from China_Appt_Assignment_Report__c where Opportunity__c in:opportunityIds];
            for(China_Appt_Assignment_Report__c report:reports)
            {
                Auto_Assignment_Queue__c queue = oppQueues.get(report.Opportunity__c);
                if(queue != null)
                {
                    if(queue.Status__c != 'Assigned'){
                        queue.Status__c = 'Assigned';
                        update queue;
                    }
                }
                if(!assignedOpportunityIds.containsKey(report.Opportunity__c))
                {
                    assignedOpportunityIds.put(report.Opportunity__c,1);
                }
            }
            for(String opportunityId:opportunityIds)
            {
                if(!assignedOpportunityIds.containsKey(opportunityId))
                {
                    AutoAssignEvent(opportunityId);
                }
            }
        }
    }
    WebService Static void AutoAssignEvent(String oppId)
    {
        
        String strOpportunityOwnerId = '';
        List<Opportunity> opps = [select Location__c,
        LeadSource,AccountId,OwnerId,Initial_Appt_Date__c,CloseDate,Event_subject__c from Opportunity where Id=:oppId limit 1];
        if(opps != null && opps.size()>0)
        {
            strOpportunityOwnerId = AutoAssignOpportunity(opps[0],oppId,opps[0].Initial_Appt_Date__c);
            if(strOpportunityOwnerId != null && strOpportunityOwnerId != ''){
                List<RecordType> recordTypes = [select Id from RecordType where Name = 'CN F2F Sales Meeting'];
                //自动分配创建Event数据
                Event event = new Event();
                event.DurationInMinutes = 60;
                event.ActivityDateTime = opps[0].Initial_Appt_Date__c;
                event.ActivityDate = date.newInstance(opps[0].Initial_Appt_Date__c.year(),opps[0].Initial_Appt_Date__c.month(),opps[0].Initial_Appt_Date__c.day());
                event.OwnerId = strOpportunityOwnerId;
                event.EF_Office__c = opps[0].Location__c;
                event.Owner__c = 'Junior CC';
                event.WhatId = oppId;
                if(opps[0].Event_subject__c != null)
                {
                    event.Subject = opps[0].Event_subject__c;
                }
                else
                {
                    event.Subject = 'Sales Demo (1)';
                }
                if(recordTypes != null && recordTypes.size()>0)
                {
                    event.RecordTypeId = recordTypes[0].Id;
                }
                insert event;

                //创建自动分配报告数据
                China_Appt_Assignment_Report__c report = new China_Appt_Assignment_Report__c();
                report.Appointment_DateTime__c = event.ActivityDateTime;
                report.Appointment_Date__c = event.ActivityDate;
                report.Assignment_Time__c = DateTime.now();
                if(opps[0].LeadSource.indexOf('Online')<0)
                {
                    report.Lead_Source__c = opps[0].LeadSource;
                }
                else
                {
                    report.Lead_Source__c = 'Online';
                }
                report.Opportunity__c = oppId;
                report.Sales_Consultant__c = strOpportunityOwnerId;
                report.School__c = opps[0].Location__c;
                report.OwnerId = strOpportunityOwnerId;
                insert report;
                try
                {
                    //自动分配Update Account信息
                    Account acc = null;
                    Id accountId = opps[0].AccountId;
                    //system.debug('......Opportunity Account Id:'+String.valueOf(accountId));
                    if(accountId != null){
                        acc = [select Id,OwnerId from Account where Id=:accountId];
                        acc.OwnerId = strOpportunityOwnerId;
                        update acc;
                    }
                    //自动分配Update Opportunity Info
                    opps[0].OwnerId = strOpportunityOwnerId;
                    opps[0].CloseDate = date.newInstance(opps[0].Initial_Appt_Date__c.year(),opps[0].Initial_Appt_Date__c.month(),opps[0].Initial_Appt_Date__c.day());
                    opps[0].Auto_Assignment__c = true;
                    update opps[0];

                    //查找业务机会的分配数据是否在Queue中存在，如果存在则把这个Queue数据Update成Assigned状态
                    List<Auto_Assignment_Queue__c> Queues = [select Id,Status__c from Auto_Assignment_Queue__c where Opportunity__c =:oppId];
                    if(Queues != null && Queues.size()>0)
                    {
                        for(Auto_Assignment_Queue__c queue:Queues)
                        {
                            queue.Status__c = 'Assigned';
                            update queue;
                        }
                    }
                }
                catch (DmlException e) {
                    //event.addError(e.getMessage());
                
                }
            }
            else
            {
                CreateAutoAssignQueueData(opps[0].Initial_Appt_Date__c,opps[0].Location__c,oppId,'','Assignment Failure by webservice');
            }
        }
    
    }
    public static String AutoAssignOpportunity(Opportunity opp,String OppId,DateTime dtEventDateTime)
    {
        String strLeadSource = null;//opp.LeadSource;
        String strLocation = null;//opp.Location__c;
        system.debug('......start execute');
        String strOpportunityOwnerId = '';
        List<String> arrSalesIds = null;
        datetime assignedDateTime = dtEventDateTime;//datetime.now();
        Map<String,Double> mapTotal = new Map<String,Double>();
        Map<String,Double> mapInCall = new Map<String,Double>();
        Map<String,Double> mapOffline = new Map<String,Double>();
        Map<String,Double> mapOnline = new Map<String,Double>();
        Map<Id,String> maps = null;
        String maxAllocSalesId = '';
        List<Sales_Team_Appointment_Allocation__c> allocs = null;
        List<Sales_Monthly_Details__c> SalesIds = null;
        List<Map<String,Double>> listMapInfo = null;
        if(opp != null)
        {
            strLeadSource = opp.LeadSource;
            strLocation = opp.Location__c;
            system.debug('Location:'+strLocation +'   Event DateTime:'+dtEventDateTime);
            system.debug('Assign DateTime:'+assignedDateTime);
            //获取分配当日所有On Duty的销售
            SalesIds = getOnDutySales(strLocation,assignedDateTime);
            if(SalesIds == null)
            {
                //No calendar Data
                //system.debug('Opportunity Id:'+opp.Id+'; No calendar Data');
                //CreateAutoAssignQueueData(dtEventDateTime,strLocation,OppId,'','No Calendar');
                return null;
            }
            //system.debug('Opportunity Id:'+opp.Id);
            //system.debug('Sales On Duty Count:'+SalesIds.size());
            arrSalesIds = new List<String>();
            //arrAllSalesIds = new String[SalesIds.size()];
            if(SalesIds != null && SalesIds.size()>0)
            {
                //某学校某日所有的已分配Opportunity的总数
                Integer schoolTotalCount  = 0;
                //某学校某日所有已分配的Lead Source为Inbound Call的Opportunity总数
                Integer schoolInCallCount = 0;
                //某学校某日所有已分配的Lead Source为offline的Opportunity总数
                Integer schoolOfflineCount = 0;
                //某学校某日所有已分配的Lead Source为Online的Opportunity总数
                Integer schoolOnlineCount = 0;
                
                //某学校某日某销售所有的已分配Opportunity的总数
                Integer salesTotalCount = 0;
                //某学校某日某销售所有已分配的Lead Source为Inbound Call的Opportunity总数
                Integer salesInCallCount  = 0;
                //某学校某日某销售所有已分配的Lead Source为offline的Opportunity总数
                Integer salesOfflineCount = 0;
                //某学校某日某销售所有已分配的Lead Source为Online的Opportunity总数
                Integer salesOnlineCount  = 0;
                
                String strAlloc = ''; 
                Double dblAlloc = 0;
                Double dblTotalDayAlloc = 0;//今天所有On Duty的销售的分配比例总值
                Double dblTotalMonthAlloc = 0;
                allocs = getAllocation(strLocation,dtEventDateTime,SalesIds);
                if(allocs == null)
                {
                    //No Allocation(Ratio) Data
                    //CreateAutoAssignQueueData(dtEventDateTime,strLocation,OppId,'','No Ratio');
                    return null;
                }
 
                //获取当日Onduty并且分配比率设置不为空的所有销售数据
                SalesIds = getValidSales(allocs,SalesIds);
                maps = new Map<Id,String>();
                if(allocs != null){
                    for(Integer i=0;i<allocs.size();i++)
                    {
                        //maps.put(allocs[i].Sales_consultant__c,allocs[i].Allocation__c);
                        if(!maps.containsKey(allocs[i].Sales_consultant__c))
                        {
                            maps.put(allocs[i].Sales_consultant__c,allocs[i].Allocation__c);
                        }
                    }
                }
                for(Integer i=0;i<SalesIds.size();i++){
                    String SalesId = String.valueOf(SalesIds[i].Sales_Consultant__c);
                    strAlloc = maps.get(SalesIds[i].Sales_Consultant__c);
                    system.debug('销售:'+SalesIds[i].Sales_Consultant__r.Alias+'的分配比率：'+strAlloc);
                    if(strAlloc != 'undefined' && strAlloc != null)
                    {
                        arrSalesIds.add(SalesId);
                    }
                }
                listMapInfo = getSalesMap(allocs,SalesIds,0,strLocation,dtEventDateTime);
                mapTotal = listMapInfo.get(0);
                mapInCall = listMapInfo.get(1);
                mapOffline = listMapInfo.get(2);
                mapOnline = listMapInfo.get(3);
            }
        }
        else
        {
            //CreateAutoAssignQueueData(dtEventDateTime,strLocation,OppId,'On Duty Sales no allocation data.','Other');
            return '';
        }
        //查找销售日所有类型分配指标分配率最低的销售
        strLeadSource = strLeadSource.toLowerCase();
        SalesOpportunityAssignedInfo salesAssignInfoTotal = null;
        SalesOpportunityAssignedInfo salesAssignInfoSource = null;
        //system.debug('......mapTotal size:'+mapTotal.size());
        salesAssignInfoTotal = getMinDataInfo(mapTotal,arrSalesIds);
        
        if(strLeadSource.toLowerCase() == 'inbound call')
        {
            //查找Inbound Call分配率最低的用户
            salesAssignInfoSource = getMinDataInfo(mapInCall,arrSalesIds);  
            if(salesAssignInfoSource.RateCount == arrSalesIds.size() && salesAssignInfoSource.AssignedRate == 0)
            {
                listMapInfo = getSalesMap(allocs,SalesIds,1,strLocation,dtEventDateTime);
                mapInCall = listMapInfo.get(1);
                salesAssignInfoSource = getMinDataInfo(mapInCall,arrSalesIds);
                if(salesAssignInfoSource.RateCount == arrSalesIds.size() && salesAssignInfoSource.AssignedRate == 0)
                {
                    strOpportunityOwnerId = getMaxAllocSales(maps,SalesIds,salesAssignInfoSource);
                    if(strOpportunityOwnerId != '' && strOpportunityOwnerId != null)
                    {
                        return strOpportunityOwnerId;
                    }
                }
                else
                {
                    return salesAssignInfoSource.SalesId;
                }
            }
            else
            {
                if(salesAssignInfoSource.SalesId != null && salesAssignInfoSource.SalesId != '')
                {
                    return salesAssignInfoSource.SalesId;
                }
            }
            
        }
        if(strLeadSource.toLowerCase() == 'offline generated')
        {
            //查找offline generated分配率最低的用户
            salesAssignInfoSource = getMinDataInfo(mapOffline,arrSalesIds);
        }
        if(strLeadSource.toLowerCase().indexOf('online')>=0)
        {
            //查找online分配率最低的用户
            salesAssignInfoSource = getMinDataInfo(mapOnline,arrSalesIds);
        }
        //比较当日Opportunity分配总量的最少的销售和当前Lead Source的Opportunity的分配量最少的销售的
        //分配比率，取较小的那个值 
        system.debug('销售总的分配率的最小值：'+salesAssignInfoTotal.AssignedRate);
        system.debug('销售当前Lead Source:'+strLeadSource+'  的最小分配率:'+salesAssignInfoSource.AssignedRate);
        Double dblDailyMinRate = salesAssignInfoTotal.AssignedRate;
        Double dblMonthlyMinRate = 0;
        String strDailyMinSales = salesAssignInfoTotal.SalesId;
        String strMonthlySales = '';
        if(salesAssignInfoTotal.AssignedRate<salesAssignInfoSource.AssignedRate)
        {
            dblDailyMinRate = salesAssignInfoTotal.AssignedRate;
            strDailyMinSales = salesAssignInfoTotal.SalesId;
            strOpportunityOwnerId = salesAssignInfoTotal.SalesId;
            /*if(strLeadSource.toLowerCase() == 'inbound call')
            {
                dblDailyMinRate = salesAssignInfoSource.AssignedRate;
                strDailyMinSales = salesAssignInfoSource.SalesId;
                strOpportunityOwnerId = salesAssignInfoSource.SalesId;
            }*/
        }
        else if(salesAssignInfoTotal.AssignedRate>salesAssignInfoSource.AssignedRate)
        {
            dblDailyMinRate = salesAssignInfoSource.AssignedRate;
            strDailyMinSales = salesAssignInfoSource.SalesId;
            strOpportunityOwnerId = salesAssignInfoSource.SalesId;
        }
        else if(salesAssignInfoTotal.AssignedRate == salesAssignInfoSource.AssignedRate && salesAssignInfoTotal.AssignedRate == 0)
        {
            //总分配率和Lead Source分配率相同，且都为0时，查找当日分配比例最高的销售
            //并将Opportunity分配给该销售
            system.debug('总分配率和Lead Source分配率相同，且都为0时，查找当日分配比例最高的销售');
            system.debug('开始查找：');
            maxAllocSalesId = getMaxAllocSales(maps,SalesIds,salesAssignInfoSource);
            if(maxAllocSalesId != '' && maxAllocSalesId != null)
            {
                dblDailyMinRate = salesAssignInfoSource.AssignedRate;
                strOpportunityOwnerId = maxAllocSalesId;
                strDailyMinSales = maxAllocSalesId;
            }
            else{
                dblDailyMinRate = salesAssignInfoSource.AssignedRate;
                strDailyMinSales = salesAssignInfoSource.SalesId;
                strOpportunityOwnerId = salesAssignInfoSource.SalesId;
            }
        }
        else if(salesAssignInfoTotal.AssignedRate == salesAssignInfoSource.AssignedRate && salesAssignInfoTotal.AssignedRate != 0)
        {
            
            //总分配率和Lead Source分配率相同，且都不为0时，自动开始查找月分配率最低的销售
            //当日Opportunity分配总量的最少的销售和
            //当前Lead Source的Opportunity的分配量最少的销售的
            //的比率相同
            //如果日总分配率和日某种Lead Source的分配率一样
            //则取月总分配率较少的那个
            listMapInfo = getSalesMap(allocs,SalesIds,1,strLocation,dtEventDateTime);
            mapTotal = listMapInfo.get(0);
            mapInCall = listMapInfo.get(1);
            mapOffline = listMapInfo.get(2);
            mapOnline = listMapInfo.get(3);
            salesAssignInfoTotal = getMinDataInfo(mapTotal,arrSalesIds);
        
            if(strLeadSource.toLowerCase() == 'inbound call')
            {
                //查找Inbound Call分配率最低的用户
                salesAssignInfoSource = getMinDataInfo(mapInCall,arrSalesIds);  
                dblMonthlyMinRate = salesAssignInfoSource.AssignedRate;
                strMonthlySales = salesAssignInfoSource.SalesId;
                return strMonthlySales;
            }
            if(strLeadSource.toLowerCase() == 'offline generated')
            {
                //查找offline generated分配率最低的用户
                salesAssignInfoSource = getMinDataInfo(mapOffline,arrSalesIds);
            }
            if(strLeadSource.toLowerCase().indexOf('online')>=0)
            {
                //查找online分配率最低的用户
                salesAssignInfoSource = getMinDataInfo(mapOnline,arrSalesIds);
            }
            //如果所有销售月总分配率也相同，则取第最后一个销售
            if(salesAssignInfoTotal.AssignedRate<salesAssignInfoSource.AssignedRate)
            {
                dblMonthlyMinRate = salesAssignInfoTotal.AssignedRate;
                strMonthlySales = salesAssignInfoTotal.SalesId;
                
            }
            else if(salesAssignInfoTotal.AssignedRate>salesAssignInfoSource.AssignedRate)
            {
                dblMonthlyMinRate = salesAssignInfoSource.AssignedRate;
                strMonthlySales = salesAssignInfoSource.SalesId;
            }
            else if(salesAssignInfoTotal.AssignedRate == salesAssignInfoSource.AssignedRate)
            {
                if(salesAssignInfoTotal.AssignedRate == 0){
                    maxAllocSalesId = getMaxAllocSales(maps,SalesIds,salesAssignInfoSource);
                    if(maxAllocSalesId != '' && maxAllocSalesId != null)
                    {
                        dblMonthlyMinRate = salesAssignInfoTotal.AssignedRate;
                        strMonthlySales = maxAllocSalesId;
                    }
                    else
                    {
                        dblMonthlyMinRate = salesAssignInfoTotal.AssignedRate;
                        strMonthlySales = salesAssignInfoTotal.SalesId;
                    }
                }
                else{
                    dblMonthlyMinRate = salesAssignInfoTotal.AssignedRate;
                    strMonthlySales = salesAssignInfoTotal.SalesId;
                }
            }
            if(dblDailyMinRate>dblMonthlyMinRate)
            {
                strOpportunityOwnerId = strMonthlySales;
            }
            else
            {
                strOpportunityOwnerId = strDailyMinSales;
            }
            
        }
        if(strOpportunityOwnerId == null || strOpportunityOwnerId == '')
        {
            if(strDailyMinSales != null && strDailyMinSales != '')
            {
                strOpportunityOwnerId = strDailyMinSales;
            }
        }
        system.debug('......当日分配率最大的销售的ID:'+maxAllocSalesId);
        system.debug('......日最小分配率:'+ dblDailyMinRate +'  Sales ID:'+strDailyMinSales);
        system.debug('......月最小分配率:'+ dblMonthlyMinRate +'  Sales ID:'+strMonthlySales);
        system.debug('......New Opportunity OwnerId:'+strOpportunityOwnerId);
        return strOpportunityOwnerId;
    }
    public static String getMaxAllocSales(Map<Id,String> maps,List<Sales_Monthly_Details__c> SalesIdsParam,SalesOpportunityAssignedInfo salesInfo)
    {
        Double dblTemp = 0;
        Double dblValue = 0;
        String strSalesId = '';
        String strSalesAlias = '';
        String strAlloc = '';
        List<String> arrSalesIds = salesInfo.SalesIds;
        List<Sales_Monthly_Details__c> SalesIds = new List<Sales_Monthly_Details__c>();
        for(Sales_Monthly_Details__c salesDetail:SalesIdsParam)
        {
            for(Integer i=0;i<arrSalesIds.size();i++){
                if(String.valueOf(salesDetail.Sales_Consultant__c) == arrSalesIds[i])
                {
                    SalesIds.add(salesDetail);
                }
            }
        }
        if(maps == null || SalesIds == null){
            system.debug('分配比例数值为空或当日Onduty 销售为空');
            return strSalesId;
        }
        for(Integer i=0;i<SalesIds.size();i++){
            //求今天所有On Duty的销售的分配比例总值
            strAlloc = maps.get(SalesIds[i].Sales_Consultant__c);
            system.debug('销售'+SalesIds[i].Sales_Consultant__r.Alias+',ID:'+SalesIds[i].Sales_Consultant__c+'的分配比例:'+strAlloc);
            if(strAlloc != 'undefined' && strAlloc != null)
            {
                strAlloc = strAlloc.replace('%','');
                dblValue = Double.valueOf(strAlloc)/100;
                if(i==0)
                {
                    dblTemp = dblValue;
                    strSalesId = String.valueOf(SalesIds[i].Sales_Consultant__c);
                    strSalesAlias = SalesIds[i].Sales_Consultant__r.Alias;
                }
                else
                {
                    if(dblValue>dblTemp){
                        dblTemp = dblValue;
                        strSalesId = String.valueOf(SalesIds[i].Sales_Consultant__c);
                        strSalesAlias = SalesIds[i].Sales_Consultant__r.Alias;
                    }
                }
            }
            
        }
        system.debug('当日Ratio最高的销售:'+strSalesAlias+' ID:'+strSalesId+' Ratio值:'+String.valueOf(dblTemp));
        return strSalesId;
    }
    public static List<Map<String,Double>> getSalesMap(List<Sales_Team_Appointment_Allocation__c> allocs,List<Sales_Monthly_Details__c> SalesIds,Integer intType,String strLocation,DateTime dtEventDateTime)
    {
        List<Map<String,Double>> returnValue = new List<Map<String,Double>>();
        String strAlloc = ''; 
        Double dblAlloc = 0;
        Double dblTotalDayAlloc = 0;
        //intType = 0 Daily data
        //intType = 1 Monthly Data
        Map<Id,Integer[]> salesAssignReport = null;
        //某学校所有的已分配Opportunity的总数
        Integer schoolTotalCount  = 0;
        //某学校所有已分配的Lead Source为Inbound Call的Opportunity总数
        Integer schoolInCallCount = 0;
        //某学校所有已分配的Lead Source为offline的Opportunity总数
        Integer schoolOfflineCount = 0;
        //某学校所有已分配的Lead Source为Online的Opportunity总数
        Integer schoolOnlineCount = 0;
        
        //某学校某销售所有的已分配Opportunity的总数
        Integer salesTotalCount = 0;
        //某学校某销售所有已分配的Lead Source为Inbound Call的Opportunity总数
        Integer salesInCallCount  = 0;
        //某学校某销售所有已分配的Lead Source为offline的Opportunity总数
        Integer salesOfflineCount = 0;
        //某学校某销售所有已分配的Lead Source为Online的Opportunity总数
        Integer salesOnlineCount  = 0;
        
        if(intType == 0)
            salesAssignReport = getAssignReportBySalesDaily(strLocation,dtEventDateTime);
        else
            salesAssignReport = getAssignReportBySalesMonthly(strLocation,dtEventDateTime);
        for(Integer i=0;i<salesAssignReport.values().size();i++)
        {
            Integer[] arrSalesAssign = salesAssignReport.values()[i];
            schoolTotalCount += arrSalesAssign[0];//某日某学校已分配的总数
            schoolInCallCount += arrSalesAssign[1];//某日某学校已分配的Inbound总数
            schoolOfflineCount += arrSalesAssign[2];//某日某学校已分配的Offline总数
            schoolOnlineCount += arrSalesAssign[3];//某日某学校已分配的Online总数
        }
        
        //system.debug('...... 学校已分配所有Opp个数：'+schoolTotalCount);
        //system.debug('...... 学校已分配所有Inbound Call Opp个数：'+schoolInCallCount);
        //system.debug('...... 学校已分配所有Offline Opp个数：'+schoolOfflineCount);
        //system.debug('...... 学校已分配所有Online Opp个数：'+schoolOnlineCount);
        
        //system.debug('...... 销售Event月分配百分比参数个数：'+allocs.size());
        //初始化保存销售日分配比例设置的Map
        Map<Id,String> maps = new Map<Id,String>();
        if(allocs != null){
            for(Integer i=0;i<allocs.size();i++)
            {
                maps.put(allocs[i].Sales_consultant__c,allocs[i].Allocation__c);
            }
        }
        
        for(Integer i=0;i<SalesIds.size();i++){
            //求今天所有On Duty的销售的分配比例总值
            strAlloc = maps.get(SalesIds[i].Sales_Consultant__c);
            if(strAlloc != 'undefined' && strAlloc != null)
            {
                strAlloc = strAlloc.replace('%','');
                dblTotalDayAlloc += Double.valueOf(strAlloc)/100;
            }
            
        }
        system.debug('...... 今日On Duty分配百分比参数的和'+String.valueOf(dblTotalDayAlloc));
        Map<String,Double> mapTotal = new Map<String,Double>();
        Map<String,Double> mapInCall = new Map<String,Double>();
        Map<String,Double> mapOffline = new Map<String,Double>();
        Map<String,Double> mapOnline = new Map<String,Double>();
        for(Integer i=0;i<SalesIds.size();i++){
            
            String SalesId = String.valueOf(SalesIds[i].Sales_Consultant__c);
            system.debug('......SalesId as:'+SalesId+'  Sales Alias as:'+SalesIds[i].Sales_Consultant__r.Alias);
            strAlloc = maps.get(SalesIds[i].Sales_Consultant__c);
            if(strAlloc != 'undefined' && strAlloc != null)
            {
                dblAlloc = Double.valueOf(strAlloc.replace('%',''))/100;
                system.debug('...... 销售分配比率...'+SalesIds[i].Sales_Consultant__r.Alias+':'+strAlloc);
                
                //arrSalesIds.add(SalesId);
                Integer[] arrAssignBySales = salesAssignReport.get(SalesIds[i].Sales_Consultant__c);
                if(arrAssignBySales == null){
                    salesTotalCount = 0;
                    salesInCallCount = 0;
                    salesOfflineCount = 0;
                    salesOnlineCount = 0;
                }
                else
                {
                    //arrAssignBySales:0-Total,1-InboundCall,2-Offline,3-Online Generated
                    salesTotalCount = arrAssignBySales[0];//某日截止现在某销售所有分配量
                    //system.debug('......销售日所有分配量:'+salesTotalCount);
                    salesInCallCount = arrAssignBySales[1];//某日截止现在某销售Inbound Call分配量
                    //system.debug('......销售日所有Inbound call分配量:'+salesInCallCount);
                    salesOfflineCount = arrAssignBySales[2];//某日截止现在某销售Offline分配量
                    //system.debug('......销售日所有Offline分配量:'+salesOfflineCount);
                    salesOnlineCount = arrAssignBySales[3];//某日截止现在某销售Online分配量
                    //system.debug('......销售日所有Online call分配量:'+salesOnlineCount);
                }
                
                system.debug('......销售日分配比率(销售的日分配比率/当日所有On Duty的销售的比率总值):'+dblAlloc/dblTotalDayAlloc);
                //求销售本月截止今天为止各种类型Appointment的分配比例
                //销售日各种类型应分配量
                Double dblDayTotal = schoolTotalCount*(dblAlloc/dblTotalDayAlloc);
                //system.debug('......销售日各种类型应分配量:'+ dblDayTotal);
                //日Inbound Call应分配量
                Double dblDayInCall = schoolInCallCount*(dblAlloc/dblTotalDayAlloc);
                //system.debug('......日Inbound Call应分配量:'+ dblDayInCall);
                //日Offline应分配量
                Double dblDayOffline = schoolOfflineCount*(dblAlloc/dblTotalDayAlloc);
                //system.debug('......日Offline应分配量:'+ dblDayOffline);
                //日Online应分配量
                Double dblDayOnline = schoolOnlineCount*(dblAlloc/dblTotalDayAlloc);
                //system.debug('......日Online应分配量:'+ dblDayOnline);
                //销售日所有类型的分配指标完成率
                Double totalPerFinished = 0;
                if(dblDayTotal != 0)
                    totalPerFinished = salesTotalCount/dblDayTotal;
                //system.debug('......销售日所有类型的分配指标完成率:'+totalPerFinished);
                //日Inbound Call的分配指标完成率
                Double inCallFinished = 0;
                if(dblDayInCall != 0)
                    inCallFinished = salesInCallCount/dblDayInCall;
                //system.debug('......销售日Inbound Call的分配指标完成率:'+inCallFinished);
                //日Offline的分配指标完成率
                Double offlineFinished = 0;
                if(dblDayOffline != 0)
                    offlineFinished = salesOfflineCount/dblDayOffline;
                //system.debug('......销售日Offline的分配指标完成率:'+offlineFinished);
                //日Online的分配指标完成率
                Double onlineFinished = 0;
                if(dblDayOnline != 0)
                    onlineFinished = salesOnlineCount/dblDayOnline;
                //system.debug('......销售日Online的分配指标完成率:'+onlineFinished);
                                
                mapTotal.put(SalesId,totalPerFinished);
                mapInCall.put(SalesId,inCallFinished);
                mapOffline.put(SalesId,offlineFinished);
                mapOnline.put(SalesId,onlineFinished);
            }
        }
        returnValue.add(mapTotal);
        returnValue.add(mapInCall);
        returnValue.add(mapOffline);
        returnValue.add(mapOnline);
        return returnValue;

    }
    //maps:销售ID和当日分配某种Lead Source的Opportunity的完成比例的映射
    public static SalesOpportunityAssignedInfo getMinDataInfo(Map<String,Double> maps,List<String> arrSalesIds)
    {
        Double dblValue = 0;
        Double dblTemp = -1;
        String strSalesId = '';
        List<String> salesIds = new List<String>();
        Integer rptRateCount = 1;
        system.debug('取分配比率最小值......销售ID数量:'+String.valueOf(arrSalesIds.size()));
        for(Integer i=0;i<arrSalesIds.size();i++)
        {
            dblValue = maps.get(arrSalesIds[i]);
            system.debug('取分配比率最小值......销售ID:'+arrSalesIds[i]+' ......分配比率:'+dblValue);
            if(dblValue == null){
                continue;
            }
            if(i == 0){
                dblTemp = dblValue;
                strSalesId = arrSalesIds[i];
                salesIds.add(arrSalesIds[i]);
            }
            else{
                if(dblValue != dblTemp)
                {
                    if(dblValue<dblTemp)
                    {
                        rptRateCount = 1;
                        salesIds.clear();
                        salesIds.add(arrSalesIds[i]);
                        strSalesId = arrSalesIds[i];
                        dblTemp = dblValue;
                    }
                    else if(dblValue > dblTemp && dblTemp == -1)
                    {
                        //dblTemp = -1,仅当第一个销售的分配比率为null时才会出现
                        //并且仅出现一次
                        rptRateCount = 1;
                        salesIds.add(arrSalesIds[i]);
                        strSalesId = arrSalesIds[i];
                        dblTemp = dblValue;
                    }
                    
                }
                else
                {
                    rptRateCount++;
                    salesIds.add(arrSalesIds[i]);
                    strSalesId = arrSalesIds[i];
                }
            }
            system.debug('取分配比率最小值......销售ID:'+arrSalesIds[i]+' ......分配比率:'+dblValue);
        }
        system.debug('取分配比率最小值结果......销售ID:'+strSalesId+' ......分配比率:'+dblTemp);
        SalesOpportunityAssignedInfo salesInfo = new SalesOpportunityAssignedInfo(dblTemp,strSalesId);
        salesInfo.RateCount = rptRateCount;
        salesInfo.SalesIds = salesIds;
        return salesInfo;

    }
    
    //获取某日某学校On Duty的Sales的名单//以分配当日为时间点
    public static List<Sales_Monthly_Details__c> getOnDutySales(String strSchoolName,DateTime dtEventDateTime)
    {
        String strYear = String.valueOf(dtEventDateTime.year());
        String strMonth = String.valueOf(dtEventDateTime.month());
        String strDay = String.valueOf(dtEventDateTime.day());
        List<Sales_Monthly_Details__c> details = null;
        details = [select Sales_Consultant__c,Sales_Consultant__r.Alias from 
        Sales_Monthly_Details__c where Year__c=:strYear and 
        Month__c =:strMonth and day__c=:strDay 
        and Day_Status__c='On Duty' and 
        Sales_Monthly_Schedule_Summary__r.School__c=:strSchoolName 
        and Sales_Consultant__r.IsActive = true];
        return details;
        
    }
    //获取某月某学校的销售分配比例设置参数
    //分配比例每月设置一次,可以随时修改,每次分配以最新修改后的分配比为准
    public static List<Sales_Team_Appointment_Allocation__c> getAllocation(String strSchoolName,DateTime dtEventDateTime,List<Sales_Monthly_Details__c> listSalesIds)
    {
        String strYear = String.valueOf(dtEventDateTime.year());
        String strMonth = String.valueOf(dtEventDateTime.month());
        Set<Id> salesIds = new Set<Id>();
        for(Sales_Monthly_Details__c detail:listSalesIds)
        {
            salesIds.add(detail.Sales_Consultant__c);
        }
        List<Sales_Team_Appointment_Allocation__c> allocs = [select Allocation__c,Sales_consultant__c,
        School__c from Sales_Team_Appointment_Allocation__c where 
        Year__c =:strYear and Month__c =:strMonth and Allocation__c != 'undefined'
        and School__c =:strSchoolName and Sales_consultant__c in :salesIds order by LastModifiedDate DESC];
        return allocs;      
    }
    //获取当日On Duty并且销售分配比不为空的所有销售
    public static List<Sales_Monthly_Details__c> getValidSales(List<Sales_Team_Appointment_Allocation__c> salesAllocs,List<Sales_Monthly_Details__c> salesCalendar)
    {
        List<Sales_Monthly_Details__c> returnSalesCalendar = new List<Sales_Monthly_Details__c>();
        Map<Id,Sales_Team_Appointment_Allocation__c> mapAlloction = new Map<Id,Sales_Team_Appointment_Allocation__c>();
        Map<Id,Sales_Monthly_Details__c> mapSalesCalendar = new Map<Id,Sales_Monthly_Details__c>();
        for(Sales_Team_Appointment_Allocation__c alloc:salesAllocs)
        {
            if(!mapAlloction.containsKey(alloc.Sales_consultant__c))
            {
                mapAlloction.put(alloc.Sales_Consultant__c,alloc);
            }
        }
        for(Sales_Monthly_Details__c workCalendar:salesCalendar)
        {
            if(mapAlloction.containsKey(workCalendar.Sales_Consultant__c) && !mapSalesCalendar.containsKey(workCalendar.Sales_Consultant__c))
            {
                returnSalesCalendar.add(workCalendar);
            }
            if(!mapSalesCalendar.containsKey(workCalendar.Sales_Consultant__c))
            {
                mapSalesCalendar.put(workCalendar.Sales_Consultant__c,workCalendar);
            }
        }
        return returnSalesCalendar;
    }
    //获取某月销售所有已经分配的数据的个数
    public static Map<Id,Integer[]> getAssignReportBySalesMonthly(String strSchoolName,DateTime dtEventDateTime)
    {
        String strYear = String.valueOf(dtEventDateTime.year());
        String strMonth = String.valueOf(dtEventDateTime.month());
        Integer reportsCount = 0;//全部已分配数量
        Integer sourceInCallCount = 0;//某种Inbound Call的分配数量
        Integer sourceOffLineCount = 0;//某种OffLine的分配数量
        Integer sourceOnLineCount = 0;//某种Online的分配数量
        
        Map<Id,Integer[]> mapResult = new Map<Id,Integer[]>();
        Map<Id,Integer> mapReportsCount = new Map<Id,Integer>();
                
        Integer[] results = null;
        for(China_Appt_Assignment_Report__c assignRpt:[select Lead_Source__c,Id,Sales_Consultant__c  
        from China_Appt_Assignment_Report__c 
        where School__c=:strSchoolName 
        and Year__c =:strYear and Month__c =:strMonth order by Sales_Consultant__c])
        {
            //system.debug('当前Heap使用情况:'+Limits.getHeapSize()+' 字节.');
            //system.debug('当前语句数量:'+Limits.getScriptStatements()+'条.');
            
            //mapResult.put(assignRpt.Sales_Consultant__c,results);
            
            if(!mapReportsCount.containsKey(assignRpt.Sales_Consultant__c))
            {
                mapReportsCount.put(assignRpt.Sales_Consultant__c,1);
            }
            else
            {
                Integer intAssignCount = mapReportsCount.get(assignRpt.Sales_Consultant__c);
                intAssignCount += 1;
                mapReportsCount.remove(assignRpt.Sales_Consultant__c);
                mapReportsCount.put(assignRpt.Sales_Consultant__c,intAssignCount);
            }
            
            reportsCount = 0;
            sourceInCallCount = 0;
            sourceOnLineCount = 0;
            sourceOffLineCount = 0;
            Integer intReportCount = mapReportsCount.get(assignRpt.Sales_Consultant__c);
            if(intReportCount != null)
                reportsCount = intReportCount;
            if(assignRpt.Lead_Source__c == 'Inbound Call')
            {
                sourceInCallCount++;
            }
            if(assignRpt.Lead_Source__c == 'Online')
            {
                sourceOnLineCount++;
            }
            if(assignRpt.Lead_Source__c == 'Offline Generated')
            {
                sourceOffLineCount++;
            }
            if(!mapResult.containsKey(assignRpt.Sales_Consultant__c))
            {
                results = new Integer[4];
                
                results[0] = reportsCount;
                results[1] = sourceInCallCount;
                results[2] = sourceOffLineCount;
                results[3] = sourceOnLineCount;
                mapResult.put(assignRpt.Sales_Consultant__c,results);
            }
            else
            {
                results = mapResult.get(assignRpt.Sales_Consultant__c);
                results[0] = reportsCount;
                results[1] += sourceInCallCount;
                results[2] += sourceOffLineCount;
                results[3] += sourceOnLineCount;
                mapResult.remove(assignRpt.Sales_Consultant__c);
                mapResult.put(assignRpt.Sales_Consultant__c,results);
            }
            
            
        }
        
        return mapResult;
    }
    
    //获取某日销售所有已经分配的数据的个数
    public static Map<Id,Integer[]> getAssignReportBySalesDaily(String strSchoolName,DateTime dtEventDateTime)
    {
        String strYear = String.valueOf(dtEventDateTime.year());
        String strMonth = String.valueOf(dtEventDateTime.month());
        String strDay = String.valueOf(dtEventDateTime.day());
        Integer reportsCount = 0;//全部已分配数量
        Integer sourceInCallCount = 0;//某种Inbound Call的分配数量
        Integer sourceOffLineCount = 0;//某种OffLine的分配数量
        Integer sourceOnLineCount = 0;//某种Online的分配数量
        
        Map<Id,Integer[]> mapResult = new Map<Id,Integer[]>();
        Map<Id,Integer> mapReportsCount = new Map<Id,Integer>();
                
        Integer[] results = null;
        for(China_Appt_Assignment_Report__c assignRpt:[select Lead_Source__c,Id,Sales_Consultant__c  
        from China_Appt_Assignment_Report__c 
        where School__c=:strSchoolName 
        and Year__c =:strYear and Month__c =:strMonth and Day__c=:strDay order by Sales_Consultant__c])
        {
            //system.debug('当前Heap使用情况:'+Limits.getHeapSize()+' 字节.');
            //system.debug('当前语句数量:'+Limits.getScriptStatements()+'条.');
            
            //mapResult.put(assignRpt.Sales_Consultant__c,results);
            
            if(!mapReportsCount.containsKey(assignRpt.Sales_Consultant__c))
            {
                mapReportsCount.put(assignRpt.Sales_Consultant__c,1);
            }
            else
            {
                Integer intAssignCount = mapReportsCount.get(assignRpt.Sales_Consultant__c);
                intAssignCount += 1;
                mapReportsCount.remove(assignRpt.Sales_Consultant__c);
                mapReportsCount.put(assignRpt.Sales_Consultant__c,intAssignCount);
            }
            
            reportsCount = 0;
            sourceInCallCount = 0;
            sourceOnLineCount = 0;
            sourceOffLineCount = 0;
            Integer intReportCount = mapReportsCount.get(assignRpt.Sales_Consultant__c);
            if(intReportCount != null)
                reportsCount = intReportCount;
            if(assignRpt.Lead_Source__c == 'Inbound Call')
            {
                sourceInCallCount++;
            }
            if(assignRpt.Lead_Source__c == 'Online')
            {
                sourceOnLineCount++;
            }
            if(assignRpt.Lead_Source__c == 'Offline Generated')
            {
                sourceOffLineCount++;
            }
            if(!mapResult.containsKey(assignRpt.Sales_Consultant__c))
            {
                results = new Integer[4];
                
                results[0] = reportsCount;
                results[1] = sourceInCallCount;
                results[2] = sourceOffLineCount;
                results[3] = sourceOnLineCount;
                mapResult.put(assignRpt.Sales_Consultant__c,results);
            }
            else
            {
                results = mapResult.get(assignRpt.Sales_Consultant__c);
                results[0] = reportsCount;
                results[1] += sourceInCallCount;
                results[2] += sourceOffLineCount;
                results[3] += sourceOnLineCount;
                mapResult.remove(assignRpt.Sales_Consultant__c);
                mapResult.put(assignRpt.Sales_Consultant__c,results);
            }
            
            
        }
        
        return mapResult;
    }
    
    public static String CreateAutoAssignQueueData(DateTime eventDateTime,String strSchool,String strOppId,String strResonDes,String strReson)
    {
        String strQueueId = '';
        List<Auto_Assignment_Queue__c> Queues = [select Id from Auto_Assignment_Queue__c where 
                            Event_DateTime__c =:eventDateTime and School__c =:strSchool 
                            and Opportunity__c =:strOppId];
        if(Queues == null || Queues.size() == 0){
            Auto_Assignment_Queue__c queue = new Auto_Assignment_Queue__c();
            queue.School__c = strSchool;
            queue.Event_DateTime__c = eventDateTime;
            queue.Opportunity__c = strOppId;
            queue.Queue_Reson__c = strReson;
            queue.Queue_Reson_Description__c = strResonDes;
            queue.Status__c = 'Queue';
            
            insert queue;
            strQueueId = queue.Id;
        }
        else
        {
            strQueueId = Queues[0].Id;
        }
        return strQueueId;
    }

    static TestMethod void AutoAssignEventQuery_test(){
        //test Auto Assignment Event Query
        DateTime dt = DateTime.newInstance(2009,9,20,13,23,0);
        AutoAssignEventQuery.getEvents('wew,wewew,wewew','2009/8/16');
        Opportunity opptest0 = [select Id,LeadSource,Location__c from Opportunity limit 1];//0064000000CIZrm//0064000000BnalN
        
        AutoAssignEventQuery.AutoAssignOpportunity(opptest0,'0064000000BnalN',dt);//0064000000CIZrm//0064000000BnalN
        List<Sales_Monthly_Details__c> SalesIds = AutoAssignEventQuery.getOnDutySales('SH DNR',dt);
        List<Sales_Team_Appointment_Allocation__c> allocs = AutoAssignEventQuery.getAllocation('SH DNR',dt,SalesIds);
        Map<Id,String> maps = new Map<Id,String>();
        if(allocs != null){
            for(Integer i=0;i<allocs.size();i++)
            {
                maps.put(allocs[i].Sales_consultant__c,allocs[i].Allocation__c);
            }
        }
        SalesIds = AutoAssignEventQuery.getValidSales(allocs,SalesIds);
        Integer intType = 0;
        List<String> arrSalesIds = new List<String>();
        List<Map<String,Double>> listMapInfo = AutoAssignEventQuery.getSalesMap(allocs,SalesIds,intType,opptest0.Location__c,dt);
        
        for(Integer i=0;i<SalesIds.size();i++){
            String SalesId = String.valueOf(SalesIds[i].Sales_Consultant__c);
            String strAlloc = maps.get(SalesIds[i].Sales_Consultant__c);
            //system.debug('销售:'+SalesIds[i].Sales_Consultant__r.Alias+'的分配比率：'+strAlloc);
            if(strAlloc != 'undefined' && strAlloc != null)
            {
                arrSalesIds.add(SalesId);
            }
        }
        SalesOpportunityAssignedInfo salesAssignInfoTotal = AutoAssignEventQuery.getMinDataInfo(listMapInfo.get(0),arrSalesIds);
        
        AutoAssignEventQuery.getMaxAllocSales(maps,SalesIds,salesAssignInfoTotal);
        //AutoAssignEventQuery.getAssignReportBySalesMonthly('SH DNR',dt);
        AutoAssignEventQuery.getAssignReportBySalesDaily('SH DNR',dt);
        ///////////////////////////////////////////////////////////
        String[] strIds = new String[1];
        strIds[0] = '005400000016buJ';
        
        AutoAssignEventQuery.CreateAutoAssignQueueData(dt,'SH ZSP','0064000000BnalN','','No Calendar');

        AutoAssignEventQuery.AutoAssignQueue('a0D40000002SfNK');
        List<Opportunity> opp = [select AccountId,Initial_Appt_Date__c,LeadSource,Location__c,Id from Opportunity where id='0064000000Bkuq9'];
        List<Account> acc = [select  Id,OwnerId from Account where Id='0014000000MUaxn'];
        
        
        AutoAssignEventQuery.AutoAssignEvent('0064000000Bkuq9');//0064000000Bkuq9////0064000000BnalN
        SalesOpportunityAssignedInfo oppAssignInfo = new SalesOpportunityAssignedInfo(0,'');
        Integer intRateCount = oppAssignInfo.RateCount;
        Double dblRate = oppAssignInfo.AssignedRate;
        List<String> arrIds = oppAssignInfo.SalesIds;
        String strSalesId = oppAssignInfo.SalesId;
    }
    
}