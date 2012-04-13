/*
 * controller used to render the page "SA Task Completion Report"
 */
public class SATaskCompletionReportController
{
    private static Map<String, String> groupByName2Field; // key: Name in Page, value: Field in Task.
    private static List<User> allSAdvisor;
    private static Map<String, String> saId2Name; // key: user id, value: user.
    private Map<String, String> languageCode2Name; // key: language code, value: language name.
    private Map<String, String> countryCode2Name; // key: country code, value: country name.
    private static Map<Boolean, Integer> isTestMethod2SelectLimit = new Map<Boolean, Integer>{ true => 20, false => 50000};  // keyWord: Test.isRunningTest()
    private static List<String> callResults = new List<String>{ null, 
                                                              'Chatted but not about study',
                                                              'Disconnected',
                                                              'Hang up',
                                                              'Invalid number',
                                                              'Left company',
                                                              'No answer',
                                                              'Out of office',
                                                              'Requested call back',
                                                              'Successfully discussed study'};
    static 
    {
        groupByName2Field = new Map<String, String>{
                                        'Study Advisor' => 'OwnerId',
                                        'Language' => 'Language__c',
                                        'Country' => 'Country__c',
                                        'Corporate' => 'Corporate__c',
                                        'CallResult' => 'CallResult__c'};
        allSAdvisor =  [select Id, Name from User where (Profile.Name = 'Englishtown Study Advisor' or Profile.Name = 'Englishtown Study Advisor Manager') and IsActive = true order by Name limit :isTestMethod2SelectLimit.get(Test.isRunningTest())];
        saId2Name = new Map<String, String>();
        for(User usr : allSAdvisor)
        {
            saId2Name.put(usr.Id, usr.Name);
        }
    }
    
    public SATaskCompletionReportController()
    {       
        GroupByType = 'Result Name';
        languageCode2Name = new Map<String, String>();
        countryCode2Name = new Map<String, String>();
        DateFromTask = new Task(ActivityDate=Date.today());
        DateToTask = new Task(ActivityDate=Date.today());
        IsFirstAccess = true;
    }
    
    public List<ResultInfo> ResultInfos
    {
        get
        {
            List<ResultInfo> result = new List<ResultInfo>();
            if(!IsFirstAccess)
            {
                Map<String, Integer> sucResult = getStatisticsResult(formulateQueryString(true));
                Map<String, Integer> failResult = getStatisticsResult(formulateQueryString(false));
                result = populateResult(sucResult, failResult);
            }
            return result;
        }
    }
    
    private List<ResultInfo> populateResult(Map<String, Integer> successedResult, Map<String, Integer> failedResult)
    {
        List<ResultInfo> result = new List<ResultInfo>();
        if(GroupByType == 'Study Advisor')
        {
            for(User usr : allSAdvisor)
            {
                result.add(new ResultInfo(saId2Name.get(usr.Id), successedResult.get(usr.Id), failedResult.get(usr.Id)));
            }
        }
        else if(GroupByType == 'CallResult')
        {
            for(String str : callResults)
            {   
                if(str == null && successedResult.get(str) == null && failedResult.get(str) == null)
                {
                    continue;
                }
                else
                {
                    result.add(new ResultInfo(str, successedResult.get(str), failedResult.get(str)));
                }
            }
        }
        else
        {
            List<String> sortRes = sortByCode(successedResult.keySet(), failedResult.keySet());
            initMap(sortRes);
            if(GroupByType == 'Language')
            {
                for(String str : sortRes)
                {
                    result.add(new ResultInfo(LanguageCode2Name.get(str), successedResult.get(str), failedResult.get(str)));
                }
            }
            else if(GroupByType == 'Country')
            {
                for(String str : sortRes)
                {
                    result.add(new ResultInfo(countryCode2Name.get(str), successedResult.get(str), failedResult.get(str)));
                }
            }
            else
            {
                for(String str : sortRes)
                {
                    result.add(new ResultInfo(str, successedResult.get(str), failedResult.get(str)));
                }
            }
        }
        return result;
    }
    
    private List<String> sortByCode(Set<String> sucSet, Set<String> failSet)
    {
        List<String> result = new List<String>();
        Set<String> tempKeyContainer = new Set<String>();
        for(String str : sucSet)
        {
            tempKeyContainer.add(str);
        }
        for(String str : failSet)
        {
            tempKeyContainer.add(str);
        }
        result.addAll(tempKeyContainer);
        result.sort();
        return result;
    }
    
    private void initMap( List<String> filterCode)
    {
        if(GroupByType == 'Language')
        {
            languageCode2Name.clear();
            for(EtownLanguage__c language : [select Id, Code__c, Name from EtownLanguage__c where Code__c in :filterCode limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {
                languageCode2Name.put(language.Code__c, language.Name);
            }
        }
        if(GroupByType == 'Country')
        {
            countryCode2Name.clear();
            for(EtownCountry__c country : [select Id, Code__c, Name from EtownCountry__c where Code__c in :filterCode limit :isTestMethod2SelectLimit.get(Test.isRunningTest())])
            {
                countryCode2Name.put(country.Code__c, country.Name);
            }
        }
    }
    
    public Boolean IsFirstAccess { get; set; }
    public String GroupByType { get; set; }
    public Task DateFromTask { get; set; }
    public Task DateToTask { get; set; }
    
    public PageReference search()
    {
        IsFirstAccess = false;
        return null;
    }
    
    private String formulateQueryString(Boolean successFlag)
    {
        Integer maxLimit = Limits.getLimitQueryRows() - Limits.getQueryRows();
        maxLimit = (Test.isRunningTest() == true)? 100: maxLimit; // used to reduce the SOQL numbers in testMethod.
        String result = null;
        String filter = groupByName2Field.get(GroupByType);
        if(successFlag)
        {
            result = 'select ' + filter + ' n, count(Id) c from Task where RecordType.Name=\'Study Advise\' and Status=\'Accomplished\'  ';
        }
        else
        {
            result = 'select ' + filter + ' n, count(Id) c from Task where RecordType.Name=\'Study Advise\' and Status=\'Unaccomplished\' and Attempt__c=3  ';
        }
        result += (formulateDate(DateFromTask.ActivityDate) == '')? '': ' and ActivityDate >= ' + formulateDate(DateFromTask.ActivityDate);
        result += (formulateDate(DateToTask.ActivityDate) == '')? '': ' and ActivityDate <= ' + formulateDate(DateToTask.ActivityDate);
        result += ' and OwnerId in (';
        for(String str : saId2Name.keySet())
        {
            result += '\'' + str + '\', ';
        }
        result += '\'00000000000000000 \') group by ' + filter + ' limit ' + maxLimit;
        return result;
    }
    
    private Map<String, Integer> getStatisticsResult(String queryStr)
    {
        Map<String, Integer> result = new Map<String, Integer>();
        if(queryStr != null)
        {
            List<sObject> objList = Database.query(queryStr);
            for(sObject agResult : objList)
            {
                AggregateResult arRes = (AggregateResult)agResult;
                result.put((String)arRes.get('n'), (Integer)arRes.get('c'));    
            }
            if(GroupByType == 'Country' && result.size() > 0)  // revise the country code like 'cn_fj'/'cn_gs' to code equals to 'cn'.
            {
                Map<String, Integer> replacedResult = new Map<String, Integer>();
                replacedResult.putAll(dealWithCountry(result));
                return replacedResult;
            }
            if(GroupByType == 'Language' || GroupByType == 'Corporate')
            {
                Map<String, Integer> replacedResult = new Map<String, Integer>();
                replacedResult.putAll(dealWithLanguageOrCorporate(result));
                return replacedResult;
            }
        }
        return result;
    }
    
    private Map<String, Integer> dealWithLanguageOrCorporate(Map<String, Integer> languageOrCorporate2Count)
    {
        Map<String, Integer> result = new Map<String, Integer>();
        String lowerCode = null;
        for(String code : languageOrCorporate2Count.keySet())
        {
            if(code != null)
            {
                lowerCode = code.toLowerCase();
                result.put(lowerCode, languageOrCorporate2Count.get(code)); 
            }
            else
            {
                result.put(code, languageOrCorporate2Count.get(code));
            }
        }
        return result;
    }
    
    private Map<String, Integer> dealWithCountry(Map<String, Integer> countries2Count)
    {
        Map<String, Integer> result = new Map<String, Integer>();
        String lowerCode = null;
        for(String code : countries2Count.keySet())
        {
            if(code != null)
            {
                lowerCode = code.toLowerCase();
                if(lowerCode.length() > 2)  // code like 'cn_fj'/'cn_gs' to code equals to 'cn'.
                {
                    String revisedKey = lowerCode.subString(0, 2);
                    if(!result.keySet().contains(revisedKey))
                    {
                        result.put(revisedKey, countries2Count.get(code));
                    }
                    else
                    {
                        result.put(revisedKey, result.get(revisedKey) + countries2Count.get(code));
                    }
                }
                else
                {
                    if(!result.keySet().contains(lowerCode))
                    {
                        result.put(lowerCode, countries2Count.get(code));
                    }
                    else
                    {
                        result.put(lowerCode, result.get(lowerCode) + countries2Count.get(code));
                    }
                }
            }
            else
            {
                result.put(code, countries2Count.get(code));
            }
        }
        return result;
    }
    
    private String formulateDate(Date varDate)
    {
        String result = '';
        if(varDate != null)
        {
            String year = String.valueOf(varDate.year());
            String month = String.valueOf(varDate.month());
            String day = String.valueOf(varDate.day());
            month = (month.length() == 1)? '0' + month: month;
            day = (day.length() == 1)? '0' + day : day;
            result = year + '-' + month + '-' + day;
        }
        return result;
    }
    
    public class ResultInfo
    {
        public ResultInfo(String resName, Integer sucTaskNum, Integer failTaskNum)
        {
            this.ResultName = (resName == null)? '': resName;
            this.CompletedTaskNum = (sucTaskNum == null)? 0 : sucTaskNum;
            this.CompletedTaskNum += (failTaskNum == null)? 0 : failTaskNum;
            if(sucTaskNum == null)
            {
                this.SuccessRate = 0;
            }
            else if(failTaskNum == null && sucTaskNum != null)
            {
                this.SuccessRate = 100;
            }
            else
            {
                this.SuccessRate = Math.floor(sucTaskNum * 100.0 / (sucTaskNum + failTaskNum) * 100) / 100;
            }
        }
        
        public String ResultName { get; set; }
        public Integer CompletedTaskNum { get; set; }
        public Double SuccessRate { get; set; }
    }
    
    @isTest
    static void testSATaskCompletionReportController()
    {
        // create data.
        List<EtownCountry__c> testCountries = new List<EtownCountry__c>{
                                                    new EtownCountry__c(Code__c='xc', Name='Acme'),
                                                    new EtownCountry__c(Code__c='xn', Name='France'),
                                                    new EtownCountry__c(Code__c='xm', Name='England')};
        insert testCountries;
        List<EtownLanguage__c> testLanguages = new List<EtownLanguage__c>{
                                                    new EtownLanguage__c(Code__c='xn', Name='English'),
                                                    new EtownLanguage__c(Code__c='xr', Name='French'),
                                                    new EtownLanguage__c(Code__c='xr', Name='German')};
        insert testLanguages;
        List<EtownCorporate__c> testCorporates = new List<EtownCorporate__c>{
                                                    new EtownCorporate__c(Code__c='ac1', Name='Acme1'),
                                                    new EtownCorporate__c(Code__c='ac2', Name='Acme2'),
                                                    new EtownCorporate__c(Code__c='ac3', Name='Acme3')};
        insert testCorporates;
        List<User> testAllSA = [select Id, Name from User where (Profile.Name='EnglishTown Study Advisor' or Profile.Name='EnglishTown Study Advisor Manager') and IsActive = true order by Name];
        String recTypeId = [select Id from RecordType where Name='Study Advise' and SobjectType='Task' limit 1].Id;
        List<Task> testTasks = new List<Task>();
        for(Integer i = 0; i < testAllSA.size(); i++)
        {
            testTasks.add(new Task(OwnerId=testAllSA[i].Id, RecordTypeId=recTypeId, ActivityDate=Date.today().addDays(-10), Status='Accomplished', Language__c=testLanguages[Math.mod(i, 3)].Code__c, Country__c=testCountries[Math.mod(i, 3)].Code__c, Corporate__c=testCorporates[Math.mod(i, 3)].Code__c));
        }
        for(Integer j = 0; j < testAllSA.size(); j++)
        {
            testTasks.add(new Task(OwnerId=testAllSA[j].Id, RecordTypeId=recTypeId, ActivityDate=Date.today().addDays(-10), Status='Unaccomplished', Attempt__c=3, Language__c=testLanguages[Math.mod(j, 3)].Code__c, Country__c=testCountries[Math.mod(j, 3)].Code__c, Corporate__c=testCorporates[Math.mod(j, 3)].Code__c));
        }
        insert testTasks;
        //test logic.
        SATaskCompletionReportController controller = new SATaskCompletionReportController();
        controller.DateFromTask.ActivityDate = Date.today().addDays(-11);
        controller.DateToTask.ActivityDate = Date.today().addDays(-5);
        controller.GroupByType = 'Study Advisor';
        controller.search();
        System.assert(controller.ResultInfos != null);
        controller.GroupByType = 'Language';
        controller.search();
        System.assert(controller.ResultInfos != null);
        controller.GroupByType = 'Country';
        controller.search();
        System.assert(controller.ResultInfos != null);
    }
}