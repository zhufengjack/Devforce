// ArrayList.   
  
	function ArrayList(){   
	 this.index = -1;   
	 this.array = new Array();    
	}   
	ArrayList.prototype.add = function (obj){   
		this.index = this.index + 1;   
		this.array[eval(this.index)] = obj;   
	}   
	ArrayList.prototype.get = function (index){return this.array[eval(index)];}   
	ArrayList.prototype.size = function (){return this.index+1;}   
	ArrayList.prototype.remove = function (index){   
		var j = 0;   
		var arrThis = this.array;    
		var arrTemp = new Array();   
		for(w=0;w<arrThis.length;w++){   
			if (eval(index)!=eval(w)) {   
				arrTemp[j] = arrThis[w];       
				j++;   
			}      
		}      
		this.array = arrTemp;   
		this.index = eval(j-1);    
	}   
	    
	// HashTable Object 注意哦，T 可是大些的   
	  
	function HashTable(){   
	 this.arrValues = new ArrayList();    
	}   
	  
	function HashTable_Map(){   
		var key = null;     
		var value = null;    
	}   
	  
	HashTable.prototype.put = function (objKey,objValue){   
		var isAdd = true;   
		var arrThis = this.arrValues;      
		for(i=0;i<arrThis.size();i++){   
			var map = arrThis.get(i);   
			if (map.key==objKey){   
				map.value = objValue;   
				isAdd = false;   
			}   
		}   
		if (isAdd){   
			var Map = new HashTable_Map();   
			Map.key = objKey;   
			Map.value = objValue;   
			this.arrKeys = objKey;   
			this.arrValues.add(Map);   
		}   
	}   
	  
	HashTable.prototype.get = function (objKey){   
		var arrThis = this.arrValues;      
		for(i=0;i<arrThis.size();i++){   
			var map = arrThis.get(i);   
			if (map.key==objKey) return map.value;   
		}   
		return null;   
	}   
	  
	HashTable.prototype.keys = function (){   
		var arrKeys = new Array();   
		var arrThis = this.arrValues;      
		for(i=0;i<arrThis.size();i++){   
			var map = arrThis.get(i);   
			arrKeys[i] = map.key;   
		}   
		return arrKeys;    
	}   
	  
	HashTable.prototype.remove =  function (objKey){   
		for(i=0;i<this.arrValues.size();i++){   
			var map = this.arrValues.get(i);   
			if (objKey == map.key){   
				this.arrValues.remove(i);   
			}   
		}   
	}  
	HashTable.prototype.clear =  function (){   
		for(i=0;i<this.arrValues.size();i++){   
			this.arrValues.remove(i);   
		}   
	}  
	HashTable.prototype.size =  function (){   
		return this.arrValues.size();
		
	}  
////////////////////////////////////////////////////////////////////////////////////
function prepareConData()
{
	//alert("ok"+AddDayToTable)
	var dayKeys = salesConsultantDayTable.keys();
	//alert("Table value size:"+dayTable.size()+"  keys length:"+dayKeys.length);
	debugInfo("total create records:"+salesConsultantDayTable.size());
	//alert("0");
	/*var dayDetailsCount = 0;
	var dayKeysIndex = 0;
	for(var i=0;i<dayKeys.length;i++)
	{
		//alert("dayKeys:"+dayKeys[i]);
		dayDetailsCount = salesConsultantDayTable.size();
		dayKeysIndex = i;
		var salesDayTimeTable = salesConsultantDayTable.get(dayKeys[i]);
		var arrSalesPlanDay = dayKeys[i].split("/");
		if(salesDayTimeTable != null)
		{
			var isWeekEnd = false;
			debugInfo("prepare the "+ i.toString() +" data......");
			//var sql = "select Id from Sales_Monthly_Details__c where year__c='"+ arrSalesPlanDay[0] +"' and month__c='"+ arrSalesPlanDay[1] +"' and day__c='"+ arrSalesPlanDay[2] +"' and Sales_Consultant__c='"+ dataSalesId +"'";
			//sforce.connection.query(sql,{onSuccess : getSalesMonthDetailsExist,onFailure : queryFailed}); 
		}
	}*/
	
}
////////////////////////////////////////////////////////////////////////////////////
var selectedDay = null;
var dayTable = null;
var salesExistDataTable = null;
var salesConsultantDayTable = null;
var salesEnableDayArray = null;
var weekEndDayTable = null;
var dayOnString = "";
var weekEndString = "";
var ondutycolor = "#54d641";
var dayoffcolor = "#ff3300";
var eveningcolor = "#3399CC"
var customcolor = "#ffff00";
function Calendar (cname, id, date)
{
	this.width = 200;
	// Used to notify the calendar that it is attached to a single html field.
	this.fallback_single = 0;
	
	// Used to notify the claendar that it is attached to 3 html fields.
	this.fallback_multi = 1;
	
	// Used to notify the calendar that it is attached to both field sets.
	this.fallback_both = 2;
	
	// Read-only calendar
	this.viewOnly = false;
	
	// Allows the user to select weekends
	this.allowWeekends = true;
	
	// Allows the user to select weekdays
	this.allowWeekdays = true;
	
	// The minimum date that the user can select (inclusive)
	this.minDate = "--";
	
	// The maximum date that the user can select (exclusive)
	this.maxDate = "--";
	
	// Allow the user to scroll dates
	this.scrolling = true;
	
	// The id of this calendar
	this.name = cname;
	
	// The first day of the week in the calendar (0-Sunday, 6-Saturday)
	this.firstDayOfWeek = 0;
	
	// Fallback method
	this.fallback = this.fallback_both;
	
	// Sets the date and strips out time information
	this.calendarDate = date;
	this.calendarDate.setUTCHours(0);
	this.calendarDate.setUTCMinutes(0);
	this.calendarDate.setUTCSeconds(0);
	this.calendarDate.setUTCMilliseconds(0);
	
	// The field id that the calendar is attached to.
	// For single input, this is used "as is". for the
	// Multi-input, it is given a suffix for _day, _month
	// and _year inputs.
	this.attachedId = id;
	
	// The left and right month control icons
	this.controlLeft = "&#171;";
	this.controlRight = "&#187;";
		
	// The left and right month control icons (when disabled)
	this.controlLeftDisabled = "";
	this.controlRightDisabled = "";
	
	// The css classes for the calendar and header
	this.calendarStyle = "cal_calendar";
	this.headerStyle = "cal_header";
	this.headerCellStyle = "cal_cell";
	this.headerCellStyleLabel = "cal_labelcell";
	
	// The css classes for the rows
	this.weekStyle = "cal_week";
	this.evenWeekStyle = "cal_evenweek";
	this.oddWeekStyle = "cal_oddweek";
	
	// The css classes for the day elements
	this.dayStyle = "cal_day";
	this.disabledDayStyle = "cal_disabled";
	this.commonDayStyle = "cal_common";
	this.holidayDayStyle = "cal_holiday";
	this.eventDayStyle = "cal_event";
	this.todayDayStyle = "cal_today";
	
	// specifies the labels for this calendar
	this.dayLabels = new Array("Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat");
	this.monthLabels = new Array(
		"January", "February", "March", "April"
		, "May", "June", "July", "August"
		, "September", "October", "November", "December");
	
	// Specifies the dates of any event. The events are to be defined as arrays,
	// with element 0 being the date and element 1 being an id.
	this.eventDates = new Array();
	
	// Attach event handlers to any fallback fields.
	if (this.viewOnly == false) {
	
		setFieldValue(this.attachedId, this.calendarDate);
		
		if ((this.fallback = this.fallback_both) || (this.fallback = this.fallback_single)) {
			eval("document.getElementById(\"" + this.attachedId + "\").onchange = function () {updateFromSingle("+this.name+", this);}");
			//alert("single");
		}

		if ((this.fallback = this.fallback_both) || (this.fallback = this.fallback_multi)) {
			
			eval("document.getElementById(\"" + this.attachedId + "_day\").onchange = function () {updateFromMultiDay("+this.name+", this);}");
			eval("document.getElementById(\"" + this.attachedId + "_month\").onchange = function () {updateFromMultiMonth("+this.name+", this);}");
			eval("document.getElementById(\"" + this.attachedId + "_year\").onchange = function () {updateFromMultiYear("+this.name+", this);}");
			
			//var dateStringCtrl = document.getElementById("tester2");
			//eval("document.getElementById(\"" + this.attachedId + "\").onchange = function () {updateFromSingle("+dateStringCtrl.name+", dateStringCtrl);}");
			//alert("Multi");
		}
	} 
	
	selectEvent = new Function();
}

function updateFromSingle (sender, helper) {
	//alert("signle");
	newDate = new Date (helper.value);
	newDate.setUTCDate(newDate.getUTCDate()+1);
	sender.calendarDate = newDate;

	renderCalendar (sender);
	setFieldValue(sender.attachedId, sender.calendarDate);
}

function reUpdateRenderCalendar(sender)
{
	var helper = document.getElementById("tester2");
	newDate = new Date (helper.value);
	newDate.setUTCDate(newDate.getUTCDate()+1);
	sender.calendarDate = newDate;

	renderCalendar (sender);
}
function updateFromMultiDay (sender, helper) {

	if (isNaN(helper.value)) {
		helper.value = sender.calendarDate.getUTCDate();
		return false;
	}
	sender.calendarDate.setUTCDate(helper.value);
	//renderCalendar (sender);
	setFieldValue(sender.attachedId, sender.calendarDate);

	reUpdateRenderCalendar(sender);
}

function updateFromMultiMonth (sender, helper) {
	//alert("Multi");
	if (isNaN(helper.value)) {
		helper.value = sender.calendarDate.getUTCMonths() -1;
		return false;
	}
	sender.calendarDate.setUTCMonth(helper.value-1);
	//renderCalendar (sender);
	setFieldValue(sender.attachedId, sender.calendarDate);

	reUpdateRenderCalendar(sender);
}

function updateFromMultiYear (sender, helper) {

	if (isNaN(helper.value)) {
		helper.value = sender.calendarDate.getUTCFullYear();
		return false;
	}
	sender.calendarDate.setUTCFullYear(helper.value);
	//renderCalendar (sender);
	setFieldValue(sender.attachedId, sender.calendarDate);

	reUpdateRenderCalendar(sender);
}

function getFirstCalendarDate (calendar)
{
	return new Date (
		calendar.calendarDate.getUTCFullYear()
		, calendar.calendarDate.getUTCMonth()
		, 1
	);
}
function renderCalendarBody(calendar)
{
	calHtml1 =  ("<table id=\""+ calendar.name +"\" class=\"" + calendar.calendarStyle +"\" width='"+calendar.width+"'>");
	calHtml1 += ((calendar.scrolling)?buildHeader(calendar):buildStaticHeader(calendar));
	calHtml1 += buildCalendarTable (calendar);
	calHtml1 += ("</table>");
	
	document.getElementById("cal_" + calendar.attachedId + "_display").innerHTML = calHtml1;

	var arrDayOn = dayOnString.split("^");
	for(var i=0;i<arrDayOn.length;i++)
	{
		//alert("Keys:"+arrDayOn[i]);
		if(arrDayOn[i] != ""){
			AddDayToTable(arrDayOn[i]);
		}
	}
	var arrWeekEnd = weekEndString.split("^");
	for(var i=0;i<arrWeekEnd.length;i++)
	{
		//alert("Keys:"+arrDayOn[i]);
		if(arrDayOn[i] != ""){
			weekEndDayTable.put(arrDayOn[i],1);
		}
	}

	InitOrginalData();
}
function InitOrginalData()
{
	var objDayStatus = "";
	var objCurrentDateString = "";
	var ctrlOnDutyId1 = "";
	var ctrlOnDutyId2 = "";
	var ctrlDayOfId = "";
	var ctrlOnDuty1 = null;
	var ctrlOnDuty2 = null;
	var ctrlDayOff = null;
	for(var i=0;i<salesEnableDayArray.length;i++)
	{
		objCurrentDateString = salesEnableDayArray[i];
		objDayStatus = salesExistDataTable.get(salesEnableDayArray[i]);
		ctrlOnDutyId1 = objCurrentDateString+'_radio_id_on1';
		ctrlOnDutyId2 = objCurrentDateString+'_radio_id_on2';
		ctrlDayOfId = objCurrentDateString+'_radio_id_off';
		ctrlOnDuty1 = document.getElementById(ctrlOnDutyId1);
		ctrlOnDuty2 = document.getElementById(ctrlOnDutyId2);
		ctrlDayOff = document.getElementById(ctrlDayOfId);
		//alert("Duty:"+ctrlOnDuty+" Off:"+ctrlDayOff+"  Status:"+objDayStatus);
		if(ctrlOnDuty1 != null && ctrlDayOff != null && ctrlOnDuty2 != null)
		{
			if(objDayStatus != null)
			{
				if(objDayStatus == "Day Off")
				{
					//alert("fireEvent");
					ctrlDayOff.checked = true;
					//ctrlDayOff.fireEvent("onclick");
					ChangeDayColor(ctrlDayOff);
				}
				else if(objDayStatus == "Evening Duty")
				{
					ctrlOnDuty2.checked = true;
					//ctrlOnDuty2.fireEvent("onclick");
					ChangeDayColor(ctrlOnDuty2);
				}
				else if(objDayStatus == "Morning Duty")
				{
					ctrlOnDuty1.checked = true;
					//ctrlOnDuty1.fireEvent("onclick");
					ChangeDayColor(ctrlOnDuty1);
				}
			}
		}
	}
}

function scrollMonthBack (calendar)
{
	calendar.calendarDate.setUTCMonth(calendar.calendarDate.getUTCMonth() - 1);
	setFieldValue(calendar.attachedId, calendar.calendarDate);
	renderCalendar (calendar);
}

function selectDate (calendar, day)
{
	if (!calendar.viewOnly) {
		calendar.calendarDate.setUTCDate(day);
		setFieldValue(calendar.attachedId, calendar.calendarDate);
		//renderCalendar (calendar);
	}
}

function scrollMonthForward (calendar)
{
	calendar.calendarDate.setUTCMonth(calendar.calendarDate.getUTCMonth() + 1);
	setFieldValue(calendar.attachedId, calendar.calendarDate);
	renderCalendar (calendar);
}

function setFieldValue(fieldId, date) {
	document.getElementById(fieldId).value = date.getUTCFullYear() + "/" + (date.getUTCMonth()+1) + "/" + date.getUTCDate();
	document.getElementById(fieldId + "_year").value = date.getUTCFullYear();
	document.getElementById(fieldId + "_month").selectedIndex = date.getUTCMonth();
	document.getElementById(fieldId + "_day").value = date.getUTCDate();
}

function buildHeader (calendar)
{

	enableLeft = true;
	enableRight = true;
	
	if (calendar.minDate != "--") 
	{
		if (calendar.calendarDate.getUTCFullYear() <= calendar.minDate.getUTCFullYear())
		{
			if (calendar.calendarDate.getUTCMonth() <= calendar.minDate.getUTCMonth())
			{
				enableLeft = false;
			}
		}
	}

	if (calendar.maxDate != "--") 
	{
		if (calendar.calendarDate.getUTCFullYear() >= calendar.maxDate.getUTCFullYear())
		{
			if (calendar.calendarDate.getUTCMonth() >= calendar.maxDate.getUTCMonth())
			{
				enableRight = false;
			}
		}
	}

	calHtml2 = "";
	
	calHtml2 +=  (
		"<tr class=\""
		+ calendar.headerStyle
		+ "\">");
	calHtml2 +=  (
		"<td class=\""
		+ calendar.headerCellStyle
		+ ((enableLeft)?("\" onclick=\"scrollMonthBack(" + calendar.name + ")"):"")
		+ "\">"
		+ ((enableLeft)?calendar.controlLeft:calendar.controlLeftDisabled)
		+ "</td>");
	calHtml2 +=  (
		"<td colspan=\"5\" class=\""
		+ calendar.headerCellStyleLabel
		+ "\">"
		+ calendar.monthLabels[calendar.calendarDate.getUTCMonth()] 
		+ ", " + calendar.calendarDate.getUTCFullYear()
		+ "</td>");
	calHtml2 +=  (
		"<td class=\""
		+ calendar.headerCellStyle
		+ ((enableRight)?("\" onclick=\"scrollMonthForward(" + calendar.name + ")"):"")
		+ "\">"
		+ ((enableRight)?calendar.controlRight:calendar.controlRightDisabled)
		+ "</td>");
	
	calHtml2 += ("</tr>");
	
	calHtml2 +=  (
		"<tr class=\""
		+ calendar.headerStyle
		+ "\">")

	for (i = 0; i < 7; i++) {
		showDay = i + calendar.firstDayOfWeek;
		if (showDay > 6) showDay = showDay - 7;
		calHtml2 +=  (
			"<td class=\""
			+ calendar.headerCellStyle
			+ "\">"
			+ calendar.dayLabels[showDay]
			+ "</td>");
	}

	calHtml2 += ("</tr>");
	return calHtml2
}

function buildStaticHeader (calendar)
{
	calHtml2 = "";
	
	calHtml2 +=  (
		"<tr class=\""
		+ calendar.headerStyle
		+ "\">");
	calHtml2 +=  (
		"<td colspan=\"7\" class=\""
		+ calendar.headerCellStyleLabel
		+ "\">"
		+ calendar.monthLabels[calendar.calendarDate.getUTCMonth()] 
		+ ", " + calendar.calendarDate.getUTCFullYear()
		+ "</td>");	
	calHtml2 += ("</tr>");
	
	calHtml2 +=  (
		"<tr class=\""
		+ calendar.headerStyle
		+ "\">")

	for (i = 0; i < 7; i++) {
		showDay = i + calendar.firstDayOfWeek;
		if (showDay > 6) showDay = showDay - 7;
		calHtml2 +=  (
			"<td class=\""
			+ calendar.headerCellStyle
			+ "\">"
			+ calendar.dayLabels[showDay]
			+ "</td>");
	}

	calHtml2 += ("</tr>");
	return calHtml2
}




function RenderDayDisabled (calendar, currentDate)
{
	calHtml += ('<td class="day">');
	calHtml += ("<span class=\"" + calendar.disabledDayStyle + "\" datevalue=\""+currentDate.getUTCFullYear()+"-"+(currentDate.getUTCMonth()+1)+"-"+ currentDate.getUTCDate()  +"\">");
	calHtml += (currentDate.getUTCDate());
	calHtml += ("</span>");
	calHtml += ("</td>");
}

function RenderDayEnabled (calendar, currentDate, dayStyle)
{
	currentDayStyle = dayStyle;
	calHtml += ('<td class="day">');
	calHtml += ("<span class=\"" + dayStyle + "\" onclick=\"selectDate(" + calendar.name + ", " + currentDate.getUTCDate() + ")\" datevalue=\""+currentDate.getUTCFullYear()+"-"+(currentDate.getUTCMonth()+1)+"-"+ currentDate.getUTCDate()  +"\">");
	calHtml += (currentDate.getUTCDate());
	calHtml += ("</span>");
	calHtml += ("</td>");
}

function RenderDayEvent (calendar, currentDate, dayStyle, eventId)
{
	currentDayStyle = dayStyle;
	calHtml += ('<td class="day">');
	calHtml += ("<span class=\"" + dayStyle + "\" onclick=\"selectDate(" + calendar.name + ", " + currentDate.getUTCDate() + "); " + calendar.name + ".selectEvent('" + eventId + "')\" datevalue=\""+currentDate.getUTCFullYear()+"-"+(currentDate.getUTCMonth()+1)+"-"+ currentDate.getUTCDate()  +"\">");
	calHtml += (currentDate.getUTCDate());
	calHtml += ("</span>");
	calHtml += ("</td>");
}
function GetCurrentDayStatus(objCurrentDateString)
{
	var objDayStatus = "";
	if(salesExistDataTable != null && salesExistDataTable.size() >0){
		if(salesExistDataTable.get(objCurrentDateString) != null)
			objDayStatus = salesExistDataTable.get(objCurrentDateString);
	}
	return objDayStatus;
}
function RenderDayEmptyRecorder (calendar,currentDate,currentDateString,obj,status,statusTable)
{
	/*if(salesExistDataTable.size() >0){
		if(salesExistDataTable.get(currentDateString) != null)
			status = salesExistDataTable.get(currentDateString);
	}*/
	//var status1 = statusTable.get(currentDateString);//GetCurrentDayStatus(currentDateString);
	calHtml += ('<td class=\'background-color:#AAAACC;\'>');
	calHtml += "<Table border='1px;' bordercolor='#6699FF' width='100%' height='100%' style='padding:1px;margin:0px;border-collapse:collapse;text-align:top;'>";
	calHtml += "<TR>";
	if(isOutOfMonth(currentDate,calendar))//当前日期不在本月
	{
		calHtml += "<TD style='valign:top;background-color:#B3B3B3'>";
		calHtml += "&nbsp;&nbsp;&nbsp;&nbsp;"+currentDateString;
		calHtml += "</TD>";
	}
	else//当前日期在本月
	{
		if(!isLessToday(currentDate,calendar)){
			salesEnableDayArray.push(currentDateString);
			
			calHtml += "<TD style='valign:top;background-color:"+ ondutycolor +"' onclick='changeDay(" + calendar.name + ", event)'>";
			if(obj == true)
			{
				//is weekend
				weekEndString += "^"+currentDateString; 
			}
			else
			{
				//is work day
			}
			
			//var aaa = salesExistDataTable
			var morningDuty = "checked";
			var eveningDuty = "";
			var dayOff = "";
			if(status == "Morning Duty")
			{
				morningDuty = "checked";
				eveningDuty = "";
				dayOff = "";
			}
			else if(status == "Evening Duty")
			{
				morningDuty = "";
				eveningDuty = "checked";
				dayOff = "";
			}
			else if(status == "Day Off")
			{
				morningDuty = "";
				eveningDuty = "";
				dayOff = "checked";
			}
			var strCheckBoxOnDuty1  = "<input type='radio' name='"+ currentDateString +"_radio' id='"+currentDateString+"_radio_id_on1' "+ morningDuty +" onclick='ChangeDayColor(this);' value='"+ currentDateString +"'>Morning<br>";
			var strCheckBoxOnDuty2 = "<input type='radio' name='"+ currentDateString +"_radio' id='"+currentDateString+"_radio_id_on2' "+ eveningDuty +" onclick='ChangeDayColor(this);' value='"+ currentDateString +"'>Evening<br>";
			var strCheckBoxDayOff = "<input type='radio' name='"+ currentDateString +"_radio' id='"+currentDateString+"_radio_id_off' "+ dayOff +" onclick='ChangeDayColor(this);' value='"+ currentDateString +"'>Day Off";
			
			calHtml += "&nbsp;&nbsp;&nbsp;&nbsp;"+currentDateString+"<br>"+strCheckBoxOnDuty1+strCheckBoxOnDuty2+strCheckBoxDayOff;
			calHtml += "</TD>";
			dayOnString += "^"+currentDateString;
			//1-onduty Morning,0-dayoff, 2- onduty evening
		}
		else
		{
			calHtml += "<TD style='valign:top;background-color:#B3B3B3'>";
			calHtml += "&nbsp;&nbsp;&nbsp;&nbsp;"+currentDateString;
			calHtml += "</TD>";
		}
	}
	calHtml += "</TR>";
	calHtml += "</Table>";
	
	calHtml += ("</td>");
}
function AddDayToTable(currentDateString)
{
	salesConsultantDayTable.put(currentDateString,1);
	//alert(salesConsultantDayTable.size());
}
function ChangeDayColor(obj)
{
	//var obj = event.srcElement;
	//alert("Value:"+obj.value+"  ID:"+obj.id);
	if(obj != null)
	{

	
		if(obj.checked == true)
		{
			if(obj.id.indexOf("off")>0)
			{
			//day off
				obj.parentNode.style.backgroundColor = dayoffcolor;
				salesConsultantDayTable.remove(obj.value);
				salesConsultantDayTable.put(obj.value,0);
			}
			if(obj.id.indexOf("on1")>0)
			{
				//on duty Morning
				obj.parentNode.style.backgroundColor = ondutycolor;
				salesConsultantDayTable.remove(obj.value);
				salesConsultantDayTable.put(obj.value,1);
			}
			if(obj.id.indexOf("on2")>0)
			{
				//on duty Evening
				obj.parentNode.style.backgroundColor = eveningcolor;
				salesConsultantDayTable.remove(obj.value);
				salesConsultantDayTable.put(obj.value,2);
			}
		}
	}
}
function ChangeDayColorByCtrl(ctrl)
{
	var obj = ctrl;//event.srcElement;
	//alert(obj.value);
	if(obj.checked == true)
	{
		if(obj.id.indexOf("off")>0)
		{
			//day off
			obj.parentNode.style.backgroundColor = dayoffcolor;
			salesConsultantDayTable.remove(obj.value);
			salesConsultantDayTable.put(obj.value,0);
		}
		if(obj.id.indexOf("on")>0)
		{
			//on duty Morning
			obj.parentNode.style.backgroundColor = ondutycolor;
			salesConsultantDayTable.remove(obj.value);
			salesConsultantDayTable.put(obj.value,1);
		}
		if(obj.id.indexOf("on2")>0)
		{
			//on duty Evening
			obj.parentNode.style.backgroundColor = eveningcolor;
			salesConsultantDayTable.remove(obj.value);
			salesConsultantDayTable.put(obj.value,2);
		}
	}
}
function isLessToday(objCurrentDate,calendar)
{
	var returnResult = false;
	var dt = new Date();
	var dtToday = new Date(dt.getFullYear(),dt.getMonth(),dt.getDate(),0,0,0);
	//alert("CurrentDate:"+objCurrentDate.toLocaleString() +"  Today Date:"+dtToday.toLocaleString());
	if(objCurrentDate<=dtToday)
	{
		returnResult = true;
	}
	return returnResult;
}
function isOutOfMonth(objCurrentDate,calendar)
{
	var returnResult = false;
	var currentMonth = objCurrentDate;
	var selectedMonthObj = document.getElementById(calendar.attachedId + "_month");
	var selectedMonth = selectedMonthObj.options[selectedMonthObj.selectedIndex].value;
	//alert("objCurrentDate.getUTCMonth():"+currentMonth.getUTCMonth() +"  selected MOnth:"+selectedMonth);
	if(selectedMonth.toString() != parseInt(currentMonth.getUTCMonth()+1).toString())
	{
		returnResult = true;
	}
	return returnResult;
}
function changeDay(calName, vEvent)
{
	/*var evt = vEvent || window.event;
	var obj = evt.target || evt.srcElement;
	if(obj.tagName.toLowerCase() == "td")
	{
		
		//selectDate(calName,calDate);
		if(selectedDay != null && selectedDay != 'undefined')
		{
			//alert(selectedDay.style.backgroundColor);
			if(selectedDay.style.backgroundColor.toLowerCase() != "" && selectedDay.style.backgroundColor.toLowerCase() != ondutycolor && selectedDay.style.backgroundColor.toLowerCase() != dayoffcolor && selectedDay.style.backgroundColor.toLowerCase() != customcolor){
				selectedDay.style.backgroundColor = "#FFFFFF";
			}
		}
		selectedDay = obj;
		if(selectedDay.style.backgroundColor.toLowerCase() != ondutycolor 
				&& selectedDay.style.backgroundColor.toLowerCase() != dayoffcolor
				&& selectedDay.style.backgroundColor.toLowerCase() != customcolor){
			selectedDay.style.backgroundColor = "#C5E1EF";
		}

		//查找当前选中的日期
		var dateCell = selectedDay.parentNode.parentNode.parentNode.parentNode.cellIndex;
		var dateRow = selectedDay.parentNode.parentNode.parentNode.parentNode.parentNode.rowIndex-1;
		//alert("Name:"+calName.name);
		var calTable = document.getElementById(calName.name);
		if(calTable != null && calName != undefined)
		{
			var dateCellSelected = calTable.rows(dateRow).cells(dateCell);
			var dateValue = dateCellSelected.children(0);
			dateValue = dateValue.getAttribute("datevalue");
		}
		
	}*/
	

}

function buildCalendarTable (calendar)
{
	currentDate = getFirstCalendarDate(calendar);
	var currentDate1 = getFirstCalendarDate(calendar);
	odd = 0;
	while (currentDate.getUTCDay() != calendar.firstDayOfWeek)
	{
		currentDate.setUTCDate(currentDate.getUTCDate() - 1);
		currentDate1.setUTCDate(currentDate1.getUTCDate() - 1);
	}
	
	calHtml = "";
	do
	{
		odd += 1;

		calHtml +=  (
			"<tr class=\"" + (((odd%2)==0) ? calendar.evenWeekStyle : calendar.oddWeekStyle) + "\">")

		for (i = 0;i < 7;i++)
		{
			currentDayStyle = calendar.dayStyle;
			currentEventStyle = calendar.commonDayStyle;
			currentDateString = currentDate.getUTCFullYear() + "/" + (currentDate.getUTCMonth()+1) + "/" + currentDate.getUTCDate();

			if (currentDate < calendar.minDate) 
			{
				RenderDayDisabled (calendar, currentDate);
			} 
			else if (currentDate > calendar.maxDate) 
			{
				RenderDayDisabled (calendar, currentDate);
			} 
			else if (currentDate.getUTCMonth() != calendar.calendarDate.getUTCMonth())
			{
				RenderDayDisabled (calendar, currentDate);
			}
			else if (currentDate.getUTCDate() == calendar.calendarDate.getUTCDate())
			{
				if ((currentDate.getUTCDay() == 0) || (currentDate.getUTCDay() == 6))
				{
					if (calendar.allowWeekends == true)
					{
						RenderDayEnabled (calendar, currentDate, calendar.todayDayStyle);
					} 
					else 
					{
						RenderDayDisabled (calendar, currentDate);	
						month = calendar.calendarDate.getUTCMonth();
						calendar.calendarDate.setUTCDate(calendar.calendarDate.getUTCDate()+1);
						if (month != calendar.calendarDate.getUTCMonth())
						{
							renderCalendar(calendar);
						}
						setFieldValue(calendar.attachedId, calendar.calendarDate);
					}
				} else {
					if (calendar.allowWeekdays == true)
					{
						RenderDayEnabled (calendar, currentDate, calendar.todayDayStyle);
					} 
					else 
					{
						RenderDayDisabled (calendar, currentDate);	
						month = calendar.calendarDate.getUTCMonth();
						calendar.calendarDate.setUTCDate(calendar.calendarDate.getUTCDate()+1);
						if (month != calendar.calendarDate.getUTCMonth())
						{
							renderCalendar(calendar);
						}
						setFieldValue(calendar.attachedId, calendar.calendarDate);
					}
				}
			}
			else if ((currentDate.getUTCDay() == 0) || (currentDate.getUTCDay() == 6))
			{
				if (calendar.allowWeekends == true)
				{
				
					style = calendar.holidayDayStyle
					
					for (j=0; j < calendar.eventDates.length; j++)
					{
						if (calendar.eventDates[j][0] == currentDateString) 
						{
							style = calendar.eventDayStyle;
							RenderDayEvent (calendar, currentDate, style, calendar.eventDates[j][0]);
						}
					}
					
					if (style == calendar.holidayDayStyle)
					{
						RenderDayEnabled (calendar, currentDate, style);
					}
				} 
				else 
				{
					RenderDayDisabled (calendar, currentDate);	
				}
			} else {
				if (calendar.allowWeekdays == true)
				{
					style = calendar.commonDayStyle

					for (j=0; j < calendar.eventDates.length; j++)
					{
						if (calendar.eventDates[j][0] == currentDateString) 
						{
							style = calendar.eventDayStyle;
							RenderDayEvent (calendar, currentDate, style, calendar.eventDates[j][0]);
						}
					}

					if (style == calendar.commonDayStyle)
					{
						RenderDayEnabled (calendar, currentDate, style);
					}
				} 
				else 
				{
					RenderDayDisabled (calendar, currentDate);	
				}
			}

			currentDate.setUTCDate(currentDate.getUTCDate() + 1);	
		}
		
		calHtml += ("</tr>");

		calHtml +=  (
			"<tr height='100px;' >")
		for (i = 0;i < 7;i++)
		{
			var dayDisabled = false;
			if ((currentDate1.getUTCDay() == 0) || (currentDate1.getUTCDay() == 6))
			{
				
				dayDisabled = true;
			}
			//YYYY/MM/DD
			var currentDateStringDis = currentDate1.getUTCFullYear() + "/" + (currentDate1.getUTCMonth()+1) + "/" + currentDate1.getUTCDate();
			//alert("Date:"+currentDateStringDis);
			//var status = salesExistDataTable.get(currentDateStringDis);//"On Duty";
			//alert("Date:"+currentDateStringDis+"   Status:"+status);
			RenderDayEmptyRecorder(calendar,currentDate1,currentDateStringDis,dayDisabled,status,salesExistDataTable);
			currentDate1.setUTCDate(currentDate1.getUTCDate() + 1);	
			
		}
		calHtml += ("</tr>");

	} while (currentDate.getUTCMonth() == calendar.calendarDate.getUTCMonth());
	return calHtml;
}