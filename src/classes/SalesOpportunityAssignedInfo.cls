public class SalesOpportunityAssignedInfo {
	Double dblAssignedRate;
	String strSalesId;
	Integer intRateCount;
	List<String> listSalesIds;
	public SalesOpportunityAssignedInfo()
	{
		this(0,'');
		intRateCount = 0;
	}
	public SalesOpportunityAssignedInfo(Double dblRate,String strId)
	{
		dblAssignedRate = dblRate;
		strSalesId = strId;
		intRateCount = 0;
	}
	public Integer RateCount
	{
		get { return intRateCount; }
		set { intRateCount = value; }
	}
	public List<String> SalesIds
	{
		get { return listSalesIds; }
		set { listSalesIds = value; }
	}
	public Double AssignedRate{
		get { return dblAssignedRate; }
		set { dblAssignedRate = value; }
	}
	public String SalesId
	{
		get { return strSalesId; }
		set { strSalesId = value; }
	}
}