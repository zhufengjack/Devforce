/*
 * Database helper
 */
public class DatabaseHelper
{
	public static SavePoint sp;

	public static SavePoint startDml()
	{
		if(sp == null)
		{
			sp = Database.setSavepoint();
		}
		return sp;
	}

	public static void dmlRollback()
	{
		if(sp != null)
		{
			Database.rollback(sp);
		}
	}
	
	@isTest
	static void testRollback()
	{
		DatabaseHelper.sp = DatabaseHelper.startDml();
		DatabaseHelper.dmlRollback();
	}
}