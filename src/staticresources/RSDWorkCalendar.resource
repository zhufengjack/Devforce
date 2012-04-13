function debugInfo(msg) 
{ 
    var dataCtl = document.getElementById("debuginfo"); 
    if(msg != ""){ 
        dataCtl.style.display= ""; 
        dataCtl.innerHTML = msg+"<br>"; 
    } 
    else 
    { 
        dataCtl.style.display= "none"; 
    } 
} 

//Communication with SFDC

var deleteHolidayIds;

function generateHolidayString()
{
    var dayKeys = salesConsultantDayTable.keys();
    var resultString = "";
    for(var i=0; i < dayKeys.length; i++)
    {
        var salesDayTimeTable = salesConsultantDayTable.get(dayKeys[i]);
        var arrSalesPlanDay = dayKeys[i].split("/");
        
        if(salesDayTimeTable != null)
        {
            
            if(salesDayTimeTable == 0) //Day Off
            {
                var dayVaule = ":" + arrSalesPlanDay[2];
                resultString = resultString + dayVaule;   
            }
        }
    }
    return resultString;
}

var queryFailed = function(error) { 
    var msg = ''; 
    alert(error); 
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
    errorCtl.innerHTML = msg+"<br>"; 
}; 

function renderCalendar (calendar)
{
    dayOnString = "";
    weekEndString = "";
    salesConsultantDayTable = new HashTable();
    salesExistDataTable = new HashTable();
    weekEndDayTable = new HashTable();
    salesEnableDayArray = new Array();
    getSalesExistData(calendar);
}

function processMonthValue(mValue)
{
    if(mValue != null)
    {
        mValue = mValue - 0;
        if(mValue < 10)
        {
            mValue = "0" + mValue;
        }
        return mValue;
    }
}

function processNextMonthValue(nmValue)
{
    if(nmValue != null)
    {
        nmValue = nmValue - 0;
        if(nmValue == 12)
        {
            nmValue = "01";
        } 
        else
        {
            nmValue = nmValue + 1;
            nmValue = processMonthValue(nmValue);
        }
        return nmValue;
    }
}

function processNextYearValue(yValue, mValue)
{
    if(yValue != null)
    {
        yValue = yValue - 0;
        if(mValue == 12)
        {
            yValue = yValue + 1;
        }
        return yValue;
    }
}

var holidayQueryCallback = function(result, source)
{
    var records = result.getArray("records");
    var record;
    var dateString = '';
    if(records != null && records.length > 0)
    {
        for(var i = 0; i < records.length; i++)
        {    
            record = records[i];
            dateString = processActivityDate(record.ActivityDate);
            salesExistDataTable.put(dateString, "Day Off");
        }
    }
    renderCalendarBody(source.Calendar);
}

function processActivityDate(activityDate)
{
    if(activityDate != null)
    {
        var dates = activityDate.split("-");
        var tempYear = dates[0];
        var tempMonth = dates[1];
        var tempDay = dates[2];
        if(tempMonth.indexOf("0") == 0)
        {
            tempMonth = tempMonth.replace("0", "");
        }
        if(tempDay.indexOf("0") == 0)
        {
            tempDay = tempDay.replace("0", "");
        }
        
        var resultString = tempYear + "/" + tempMonth + "/" + tempDay;
        return resultString;
    }
}

function queryFailures(error,source) { 
    queryFailed(error);
    renderCalendarBody(source.Calendar);
}

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
        }
    } 
    
    selectEvent = new Function();
}

function updateFromSingle (sender, helper) 
{
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
    setFieldValue(sender.attachedId, sender.calendarDate);

    reUpdateRenderCalendar(sender);
}

function updateFromMultiMonth (sender, helper) 
{
    if (isNaN(helper.value)) {
        helper.value = sender.calendarDate.getUTCMonths() -1;
        return false;
    }
    sender.calendarDate.setUTCMonth(helper.value-1);
    setFieldValue(sender.attachedId, sender.calendarDate);
    reUpdateRenderCalendar(sender);
}

function updateFromMultiYear (sender, helper) {

    if (isNaN(helper.value)) {
        helper.value = sender.calendarDate.getUTCFullYear();
        return false;
    }
    sender.calendarDate.setUTCFullYear(helper.value);
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
    var nowFourteenDay = getFourteenDay();
    for(var i=0;i<salesEnableDayArray.length;i++)
    {
        objCurrentDateString = salesEnableDayArray[i];
        var dateArr =objCurrentDateString.split("/");
        var currentClickDate = new Date(dateArr[0] - 0, dateArr[1] - 1, dateArr[2] - 0);
        
        objDayStatus = salesExistDataTable.get(salesEnableDayArray[i]); 
        ctrlOnDutyId1 = objCurrentDateString+'_radio_id_on1';
        ctrlDayOfId = objCurrentDateString+'_radio_id_off';
        ctrlOnDuty1 = document.getElementById(ctrlOnDutyId1);
        ctrlDayOff = document.getElementById(ctrlDayOfId);
        if(ctrlOnDuty1 != null && ctrlDayOff != null)
        {
            if(objDayStatus != null)
            {
                if(objDayStatus == "Day Off")
                {
                    ctrlDayOff.checked = true;
                    ChangeDayColor(ctrlDayOff);
                }
                else if(objDayStatus == "On Duty")
                {
                    ctrlOnDuty1.checked = true;
                    ChangeDayColor(ctrlOnDuty1);
                }
            }
            if(currentClickDate < nowFourteenDay)
            {
                  ctrlOnDuty1.disabled = true;
                  ctrlDayOff.disabled = true;
                  ctrlDayOff.parentNode.style.backgroundColor = "#B3B3B3";
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
            var onDuty = "checked";
            
            var dayOff = "";
            if(status == "On Duty")
            {
                onDuty = "checked";
                dayOff = "";
            }
            else if(status == "Day Off")
            {
                onDuty = "";
                dayOff = "checked";
            } 
            var strCheckBoxOnDuty1  = "<input type='radio' name='"+ currentDateString +"_radio' id='"+currentDateString+"_radio_id_on1' "+ onDuty +" onclick='ChangeDayColor(this);' value='"+ currentDateString +"'>On Duty<br>";
            var strCheckBoxDayOff = "<input type='radio' name='"+ currentDateString +"_radio' id='"+currentDateString+"_radio_id_off' "+ dayOff +" onclick='ChangeDayColor(this);' value='"+ currentDateString +"'>Day Off";
            
            calHtml += "&nbsp;&nbsp;&nbsp;&nbsp;"+currentDateString+"<br>"+strCheckBoxOnDuty1+strCheckBoxDayOff;
            calHtml += "</TD>";
            dayOnString += "^"+currentDateString;
            //1-onduty,0-dayoff
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
}
function ChangeDayColor(obj)
{
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
                //on duty
                obj.parentNode.style.backgroundColor = ondutycolor;
                salesConsultantDayTable.remove(obj.value);
                salesConsultantDayTable.put(obj.value,1);
            }
 
        }
    }
}
function ChangeDayColorByCtrl(ctrl)
{
    var obj = ctrl;
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
            //on duty
            obj.parentNode.style.backgroundColor = ondutycolor;
            salesConsultantDayTable.remove(obj.value);
            salesConsultantDayTable.put(obj.value,1);
        }
    }
}
function isLessToday(objCurrentDate,calendar)
{
    var returnResult = false;
    var dt = new Date();
    var dtToday = new Date(dt.getFullYear(),dt.getMonth(),dt.getDate(),0,0,0);
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
    if(selectedMonth.toString() != parseInt(currentMonth.getUTCMonth()+1).toString())
    {
        returnResult = true;
    }
    return returnResult;
}
function changeDay(calName, vEvent)
{
 
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

var successDataPrepared = function(result){ 
    if(result[0].getBoolean("success"))
    {
        //Deletes old holiday data.
        sforce.connection.deleteIds(deleteHolidayIds);
        alert("Set holidays successfully......");
        debugInfo("");
    }
    else
    {
        alert("Set holidays falied, please reopen this page, and try again.");
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

function getFourteenDay()
{
    var today = new Date();
    var yearValue = today.getFullYear();
    var monthValue = today.getMonth();
    var dayValue = today.getDate();
    var monthDayNumber = getMonthDayNumber(yearValue, monthValue);
    var tempDay = dayValue + 14;
    var newDayValue = 0;
    var newMonthValue = 0;
    var newYearValue = 0;
    
    if((tempDay - monthDayNumber) > 0)
    {
        newDayValue = tempDay - monthDayNumber;
        newMonthValue = monthValue + 1;
        newYearValue = yearValue;
    }
    else
    {
        newDayValue = tempDay;
        newMonthValue = monthValue;
        newYearValue = yearValue;
    }
    
    if(newMonthValue > 11)
    {
        newMonthValue = newMonthValue - 12;
        newYearValue = newYearValue + 1;
    }
    
    var resultDate = new Date();
    resultDate.setDate(newDayValue);
    resultDate.setMonth(newMonthValue);
    resultDate.setFullYear(newYearValue);
    return resultDate;
}

function getMonthDayNumber(yearValue, monthValue) 
{ 
    var tempDay = new Date(yearValue, monthValue, 0); 
    return tempDay.getDate(); 
} 

function generateCurrentDateString()
{
    var currentDate = new Date();
    var yearValue = currentDate.getFullYear();
    var monthValue = currentDate.getMonth() + 1;
    var dayValue = currentDate.getDate();
    return yearValue + "/" + monthValue + "/" + dayValue;
}