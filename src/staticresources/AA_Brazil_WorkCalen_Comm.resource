function getLocalDate(){ 
var dt = new Date(); 
var sdt = dt.getUTCFullYear()+"-"+(parseInt(dt.getMonth(),10)+1)+"-"+dt.getDate(); 
if(parseInt(dt.getHours(),10)>12) { 
sdt += " 下午"+(parseInt(dt.getHours(),10)-12)+":"+dt.getMinutes(); 
} 
else { 
sdt += " 上午"+dt.getHours()+":"+dt.getMinutes(); 
} 
return sdt; 
} 
function getThisMonthFirstDate(){ 
var dt = new Date(); 
var sdt = dt.getUTCFullYear()+"-"+(parseInt(dt.getMonth(),10)+1)+"-"+"1"; 
if(parseInt(dt.getHours(),10)>12) { 
sdt += " 下午"+(parseInt(dt.getHours(),10)-12)+":"+dt.getMinutes(); 
} 
else { 
sdt += " 上午"+dt.getHours()+":"+dt.getMinutes(); 
} 
return sdt; 
} 
function getSpecialDate(intyear,intmonth,intday){ 
var dt = new Date(); 
//var sdt = intyear+"-"+(parseInt(intmonth,10)+1)+"-"+intday; 
var sdt = intyear+"-"+parseInt(intmonth,10)+"-"+intday; 
sdt += " 上午"+"0"+":"+"0"; 
return sdt; 
} 
function getSpecialDateTime(intyear,intmonth,intday){ 
var dt = new Date(); 
var sdt = intyear+"-"+(parseInt(intmonth,10)+1)+"-"+intday; 
if(parseInt(dt.getHours(),10)>12) { 
sdt += " 下午"+(parseInt(dt.getHours(),10)-12)+":"+dt.getMinutes(); 
} 
else { 
sdt += " 上午"+dt.getHours()+":"+dt.getMinutes(); 
} 
return sdt; 
} 

function toGMTDate(strDate) 
{ 
var reg = new RegExp(/(\d{4})-(\d{1,2})-(\d{1,2})\s{0,2}(上午|下午)(\d{1,2}):(\d{1,2})/); 
var r = strDate.match(reg); 

if(r && r.length>6) { 
if(r[4]=="下午" && r[5]!="12") { 
r[5] = parseInt(r[5],10)+12; 
} 
if(r[4]=="上午" && r[5]=="12") { 
r[5] = parseInt(r[5],10)-12; 
} 
return new Date(r[1],r[2]-1,r[3],r[5],r[6],0); 
} 
else { 
return new Date(); 
} 
} 

function ExecuteQuery(querySql) 
{ 
	var querySta = querySql; 
	var queryResult = sforce.connection.query(querySta); 
	var records = queryResult.getArray("records"); 
	return records; 

}

var blExecute = true;
var dataYear = null;
var dataMonth = null;
var dataDay = null;
var dataSchool = null;
var dataManagerId = null;
var dataSalesId = null;
var dataSalesAmount = 0;
var dataSummaryId = null;
var deleteDetailIds = null;
var dayDetailsCount = 0;
var dayKeysIndex = -1;
var dealDetailsCount = 0
var arrCreateData = null;

function StartSaveSalesData(year,month,day,strSchoolName,managerId,salesId,salesAmount)
{
	deleteDetailIds = new Array();
	arrCreateData = new Array();
	var btnSaveObj = document.getElementById("btnGenerate");
	btnSaveObj.disabled = true;
	
	dayDetailsCount = 0;
	dayKeysIndex = -1;
	dealDetailsCount = 0;
	blExecute = true;
	dataYear = year;
	dataMonth = month;
	dataDay = day;
	dataSchool = strSchoolName;
	dataManagerId = managerId;
	dataSalesId = salesId;
	dataSalesAmount = salesAmount;
	dataSummaryId = null;
	//alert(dataSchool);
	//return;
	//首先查找当年当月的学校下是否已创建销售工作计划总览数据
	var sql = "select Id,Date__c,manager__c,year__c,month__c from Sales_Month_Summary__c"; 
	sql += " where year__c='"+ year +"' and month__c='"+ month +"' and School__c='"+ strSchoolName +"' and SummaryOrg__c='"+summaryOrg+"'";
	sforce.connection.query(sql,{onSuccess : getSalesMonthSummaryFinished,onFailure : queryFailed}); 
}

var getSalesMonthSummaryFinished = function(result){ 
	var records = result.getArray("records"); 
	var record; 
	debugInfo("Start check school month plan summary......"); 
	if(records == null || typeof(records)=='undefined' || records.length ==0)
	{
		debugInfo("Start create school month plan summary......"); 
		//当月数据尚未创建，首先创建销售总览数据
		var summaryData = new sforce.SObject("Sales_Month_Summary__c"); 
		summaryData.Date__c = toGMTDate(getSpecialDate(dataYear,dataMonth,1)); 
		summaryData.manager__c = dataManagerId;
		summaryData.School__c = dataSchool;
		summaryData.Sales_Amount__c = dataSalesAmount;
		summaryData.SummaryOrg__c = summaryOrg;
		var result = sforce.connection.create([summaryData]);
		 
		if (result[0].getBoolean("success")) {
			dataSummaryId = result[0].id;
			//alert("Summary Id:"+dataSummaryId);
		}
		else
		{
			alert("create summary data failed......");
			return;
		}
	}
	else
	{
		record = records[0];
		dataSummaryId = record.Id;
		
	}
	debugInfo("Start create sales consultant month plan detail......"); 
	CreateSalesConsultantData();
	/*if(dayTable != null)
	{
		CreateSalesConsultantData();
	}
	else
	{
		alert("There is no data to save......");
		return;
	}*/
}; 

function CreateSalesConsultantData()
{
	var dayKeys = salesConsultantDayTable.keys();
	//alert("Table value size:"+dayTable.size()+"  keys length:"+dayKeys.length);
	debugInfo("total create records:"+salesConsultantDayTable.size());
	//alert("0");
	dayDetailsCount = salesConsultantDayTable.size();
	for(var i=0;i<dayKeys.length;i++)
	{
		//alert("dayKeys:"+dayKeys[i]);
		
		dayKeysIndex = i;
		var salesDayTimeTable = salesConsultantDayTable.get(dayKeys[i]);
		var arrSalesPlanDay = dayKeys[i].split("/");
		if(salesDayTimeTable != null)
		{
			var isWeekEnd = false;
			debugInfo("prepare "+ i.toString() +" data......");
			var sql = "select Id from Sales_Monthly_Details__c where year__c='"+ arrSalesPlanDay[0] +"' and month__c='"+ arrSalesPlanDay[1] +"' and day__c='"+ arrSalesPlanDay[2] +"' and Sales_Consultant__c='"+ dataSalesId +"'";
			sforce.connection.query(sql,{onSuccess : getSalesMonthDetailsExist,onFailure : queryFailed}); 
		}
	}
	
}
var getSalesMonthDetailsExist = function(result){ 
	var records = result.getArray("records"); 
	var record; 
	
	if(records != null && typeof(records) != 'undefined' && records.length >0)
	{
		//准备要删除的数据
		
		record = records[0];
		deleteDetailIds.push(record.Id);
		debugInfo("delete exist data id: "+record.Id+"......");
	}
	dealDetailsCount++;
	if(dealDetailsCount == dayDetailsCount){
		//准备新生成的数据
		var dayKeys = salesConsultantDayTable.keys();
		arrCreateData = new Array();
		for(var i=0;i<dayKeys.length;i++)
		{
			var salesDayTimeTable = salesConsultantDayTable.get(dayKeys[i]);
			var arrSalesPlanDay = dayKeys[i].split("/");
			
			if(salesDayTimeTable != null)
			{
				var isWeekEnd = false;
				if(weekEndDayTable.get(dayKeys[i]) != null)
				{
					isWeekEnd = true;
				}
				var dayDetailsData = new sforce.SObject("Sales_Monthly_Details__c"); 
				dayDetailsData.Date__c = toGMTDate(getSpecialDate(arrSalesPlanDay[0],arrSalesPlanDay[1],arrSalesPlanDay[2])); 
				dayDetailsData.Sales_Consultant__c = dataSalesId;
				dayDetailsData.Sales_Monthly_Schedule_Summary__c = dataSummaryId;
				
				//alert("Prepare time details......");
				debugInfo("prepare monthly details data......");
				
				if(salesDayTimeTable == 1)//On Duty Morning
				{
					dayDetailsData.Day_Status__c = "Morning Duty";
				}
				else if(salesDayTimeTable == 2)//On Duty Evening
				{
					dayDetailsData.Day_Status__c = "Evening Duty";
				}
				else if(salesDayTimeTable == 0)//Day Off
				{	
					dayDetailsData.Day_Status__c = "Day Off";
				}
				arrCreateData.push(dayDetailsData);
				
			}//if(salesDayTimeTable != null)

		}//for(var i=0;i<dayKeys.length;i++)
		//////////////////////////////////////////////////////////////
		//alert(arrCreateData.length);
		debugInfo("All data had been push to array......wait for create it");
		if(arrCreateData != null && arrCreateData.length>0){
			sforce.connection.create(arrCreateData,{onSuccess : successDataPrepared, onFailure : queryFailed});
		}
		else
		{
			alert("No data saved on your calendar.");
		}
	}
	
};
var successDataPrepared = function(result){
	if (result[0].getBoolean("success")) { 
		for(var i = 0;i < deleteDetailIds.length; i++)
		{
			var detailsId = deleteDetailIds[i];
			sforce.connection.deleteIds([detailsId]);
		}
		if(dataSummaryId != null && dataSummaryId != ""){
			var summaryData = new sforce.SObject("Sales_Month_Summary__c"); 
			summaryData.Id = dataSummaryId; 
			summaryData.Send_Email_Notify__c = true;
			summaryData.Last_Modified_Sales__c = dataSalesId;
			sforce.connection.update([summaryData]);
		}

		alert("Create data successfully......"); 
		debugInfo("");
		var btnSaveObj = document.getElementById("btnGenerate");
		btnSaveObj.disabled = false;

	} 
	else
	{
		alert("Save data falied, please reopen this page, and try again.");
		queryFailed(result[0]);
	}
}
var queryFailed = function(error) { 
	var msg = ''; 
	//alert(error); 
	if(typeof(error)=='object') { 
		for(e in error) { 
			msg += e+": "+error[e]+" | "; 
		} 
	} 
	else { 
		msg = error; 
	} 
	var errorCtl = document.getElementById("errorinfo"); 
	errorCtl.style.display= ""; 
	errorCtl.innerHTML += msg+"<br>" ; 
};