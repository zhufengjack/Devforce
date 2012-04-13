//初始化Update_contact_information类，并从URL中取得参数
public class Update_contact_information{
    private  String oppId;
    private Opportunity opp=new Opportunity();
    public Update_contact_information(ApexPages.StandardController controller) {
        oppId=controller.getId();
    }

  private string  conId='';

     //声明一个con对象并设置读写属性             
  public contact con=new contact();
  public contact getcon() {
               return con;
  }
  
  public void setCon(Contact con){
  this .con = con;
  }
   //保存时候调用的方法 
  public void save(){
             Opportunity opp=[Select id, Contact__c from Opportunity where id=:oppId];
              contact ConFinal=[Select C.Id,c.email, c.mobilephone, c.phone
              from contact c
              where c.Id = :opp.Contact__c];
              
              conFinal.email = con.Email;
              conFinal.mobilephone = con.mobilephone;
              conFinal.phone = con.phone;
              update conFinal;
              }
              }