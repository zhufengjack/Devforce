/**
 *controller for page: SmartDailyCapping
*/
public class SmartDailyCappingController 
{
	private String city = ApexPages.currentPage().getParameters().get('city');
	
    public SmartDailyCappingController()
    {
        isTesting = false;
        initHtmlTable(); 
    }
    
    public SmartDailyCappingController(Boolean isTesting)//using for test method
    {
        this.isTesting = isTesting;
        initHtmlTable();
    }
    
    public Boolean isTesting {get; set;}
    public HtmlTable Table {get; set;}
    public Integer schoolSize {get; set;}
    
     //if the list size is less than 14 ,this function will complete this list for example the list just contains 2010-3-5, 2010-3-8,this function will add the other date for the list 
    private List<RemainingApptsHelper.ApptDetailInfo2> CompleteList2(List<RemainingApptsHelper.ApptDetailInfo2> items, Integer days)
    {
        map<Date, RemainingApptsHelper.ApptDetailInfo2> dateApptMap = new map<Date, RemainingApptsHelper.ApptDetailInfo2>();
        for(RemainingApptsHelper.ApptDetailInfo2 item : items)
        {
            dateApptMap.put(item.ScheduleDate, item);
        }
        for(Integer i = 0; i <= days; i++)
        {
            if(dateApptMap.get(Date.today().addDays(i)) == null)
            {
                items.add(new RemainingApptsHelper.ApptDetailInfo2(items[0].SchoolName, Date.today().addDays(i), 0, 0));
            }
        }
        return SortList2(items);
    }
    
    //Sort List<RemainingApptsHelper.ApptDetailInfo2> by ScheduleDate
    private List<RemainingApptsHelper.ApptDetailInfo2> SortList2(List<RemainingApptsHelper.ApptDetailInfo2> items)
    {
        Integer i, j;
        RemainingApptsHelper.ApptDetailInfo2 temp;    
        Boolean done = false;    
        j = 1;    
        while ((j < items.size()) && (!done))  
        {    
            done = true;    
            for (i = 0; i < items.size() - j; i++)    
            {    
                if (items[i].ScheduleDate > items[i + 1].ScheduleDate)    
                {    
                    done = false;    
                    temp = items[i];    
                    items[i] = items[i + 1];
                    items[i + 1] = temp;    
                }    
            }    
            j++;    
        }    
        return items;
    }
    
    //refresh 5 seconds
    public PageReference Refresh()
    {
        initHtmlTable();
        return null;
    }
    
    private void initHtmlTable()
    {
        schoolSize = 0;
        List<RemainingApptsHelper.ApptDetailInfo2> apptDetails = new List<RemainingApptsHelper.ApptDetailInfo2>();
        map<String, List<RemainingApptsHelper.ApptDetailInfo2>> schoolApptMap = new map<String, List<RemainingApptsHelper.ApptDetailInfo2>>();
        	if(city != null && city != '')
    		{   
    			if(!istesting)
    			{     
    	    			apptDetails = RemainingApptsHelper.getApptDetailsByCity(city, 13);
    			}
    			else
    			{
    				apptDetails = RemainingApptsHelper.getApptDetailsByCityForTest(city);
    			}
    		}
        schoolApptMap = RemainingApptsHelper.getSchoolApptDetailsMap(apptDetails);
        if(!schoolApptMap.keyset().isEmpty())
        {
            Integer columnCount = schoolApptMap.values().size() + 1;
            schoolSize = schoolApptMap.values().size();
            Integer rowCount = 15;
            Table = new HtmlTable(rowCount, columnCount); 
            for(Integer column = 0; column < columnCount; column ++)
            {
                List<RemainingApptsHelper.ApptDetailInfo2> details = new List<RemainingApptsHelper.ApptDetailInfo2>();
                if(column == 0)
                {
                    details = CompleteList2(schoolApptMap.values()[0], 13);
                }
                else
                {
                    details = CompleteList2(schoolApptMap.values()[column - 1], 13);
                }
                for(Integer row = 0; row < 15; row ++)
                {
                    if(column == 0 && row == 0)
                    {
                        Table.setCell(0, 0, '');
                    }
                    else if(column == 0 && row != 0)
                    {
                        if(row == 1)
                        {
                            Table.setCell(row, 0, details[0].ScheduleDate.format() + '(today)');
                        }
                        else
                        {
                            Table.setCell(row, 0, details[row-1].ScheduleDate.format());//set the date column while the column is 0
                        }
                    }
                    else if(row == 0 && column != 0)
                    {
                        Table.setCell(0, column, details[0].SchoolName);//set school name whene the row is 0
                    }
                    else
                    {
                        Table.setCell(row, column, String.valueof(details[row-1].RemainingApptCount));//set other values for the list which using for render a htmlTable
                    }
                }
            }
        }
    }
    
    //a custom class which can render the html code for dataTable which displayed in vf page
    public class HtmlTable
    {
        private List<List<String>> internalData;
        private Integer row, column;
        public HtmlTable(Integer rows, Integer columns)
        {
            this.row = rows;
            this.column = columns;
            internalData = new List<List<String>>();
            for(Integer i = 0; i < rows; i ++)
            {
                List<String> aRow = new List<String>();
                for(Integer j = 0; j < columns; j++)
                {
                    aRow.add('');
                }
                internalData.add(aRow);
            }
        }
        
        public void setCell(Integer row, Integer column, String value)
        {
            if(row < this.row)
            {
                if(column < this.column)
                {
                    internalData[row][column] = value;
                }
            }
        }
        
        //return a html table code for vf page
        public String renderHtml
        {
            get
            {
                Integer colspan = this.column - 1;
                String result = '<table border="1" cellspacing="0" cellpadding="5" border-color:#4F4431;" style="color:blue"><tr  style="background-color:#ACA96C;"><td style="color:black"><b>Date</b></td><td colspan="' + colspan + '" align="center" style="color:black"><b>Remaining Appts</b></td></tr>';
                for(Integer i = 0; i < this.row; i++)
                {
                    result += '<tr>';
                    for(Integer j = 0; j < this.column; j++)
                    {
                        if(i!= 0 && j != 0)
                        {
                            Integer remainingAppts = integer.valueOf(internalData[i][j]);
                            String CurrentDate = internalData[i][0];
                            String dateStr = '';
                            String day = '';
                            String month = '';
                            String year = '';
                            if(i == 1)
                            {
                                Date sDate = Date.today();
                                day = (integer.valueof(String.valueOf(sDate.day())) >= 10)?String.valueOf(sDate.day()):('0' + String.valueOf(sDate.day()));
                                month = (integer.valueof(String.valueOf(sDate.month())) >= 10)?String.valueOf(sDate.month()):('0' + String.valueOf(sDate.month()));
                                year = String.valueOf(sDate.year());    
                            }
                            else
                            {
                                String[] dateArr = CurrentDate.split('/');
                                if(dateArr != null && dateArr.size() == 3)
                                {
                                  year = dateArr[2];
                                  month = String.valueOf(dateArr[1]);
                                  day = String.valueOf(dateArr[0]); 
                                }                               
                            }
                            dateStr = day + '/' + month + '/' + year;   
                            String[] school = internalData[0][j].split(' ');
                            String schoolStr = school[0] + ' ' + school[1];
                            String openUrl = '/apex/SmartHourlyCapping?school=' + schoolStr + '&date=' + dateStr;                        
                            if(remainingAppts < 0)
                            {
                                result += '<td style="background-color:#D6D5CF;"><a href="javascript:void(0)" onclick="open_win(\'' + openUrl + '\')"  style="color:red;">' + internalData[i][j] + '</a></td>';
                            }
                            else
                            {
                                result += '<td style="background-color:#D6D5CF;"><a href="javascript:void(0)" onclick="open_win(\'' + openUrl + '\')"  style="color:blue;">' + internalData[i][j] + '</a></td>';
                            }
                        }
                        else
                        {
                            result += '<th style="color:black;background-color:#D6D5CF;">' + internalData[i][j] + '</th>';
                        }
                    }
                    result += '</tr>';
                }
                result += '</table>';
                return result;
            }
        }
    }
    
    @isTest
    static  void testController()
    {
        Id chinaSmartOpportunityRecordTypeId = '0124000000099sY';
        List<Opportunity> testOpportunites = new List<Opportunity>();
        Opportunity testOpportunity1 = new Opportunity(name = 'acme', location__c = 'SH PSQ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
        testOpportunites.add(testOpportunity1);
        Opportunity testOpportunity2 = new Opportunity(name = 'acme', location__c = 'SH LJZ', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, CloseDate = date.today());
        testOpportunites.add(testOpportunity2);
        Opportunity testOpportunity3 = new Opportunity(name = 'acme', location__c = 'SH BBB', Reschedule_appt_Date_time__c = datetime.now(), StageName = 'Set Appt', RecordTypeId = chinaSmartOpportunityRecordTypeId, Check_confirmation__c = true, CloseDate = date.today());
        testOpportunites.add(testOpportunity3);
        insert testOpportunites;
        List<Appt_Max_target__c> testTargets = new List<Appt_Max_target__c>();
        Appt_Max_target__c testTarget1 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH PSQ', Date__c = date.today());
        testTargets.add(testTarget1);
        Appt_Max_target__c testTarget2 = new Appt_Max_target__c(Max_target__c = 1, School__c = 'SH LJZ', Date__c = date.today());
        testTargets.add(testTarget2);
        Appt_Max_target__c testTarget3 = new Appt_Max_target__c(Max_target__c = 2, School__c = 'SH BBB', Date__c = date.today());
        testTargets.add(testTarget3);
        insert testTargets;
        PageReference testPage = new PageReference('/apex/SmartDailCapping?city=SH');
        test.setCurrentPage(testPage);
	    SmartDailyCappingController controller = new SmartDailyCappingController(true);
	    String renderHtml = controller.Table.renderHtml;
	    System.assert(renderHtml.contains('SH LJZ'));
    }
}