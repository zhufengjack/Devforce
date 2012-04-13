/*
 * A generic exception class for all exceptions
 */
public class EtownException extends Exception
{
  public EtownException(String message, Integer code)
  {
      this.setMessage(message);
      this.ErrorCode = code;
  }
  
  public Integer ErrorCode { get; set; }
}