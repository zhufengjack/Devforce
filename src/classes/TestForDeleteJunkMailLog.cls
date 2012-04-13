public class TestForDeleteJunkMailLog {
    static testMethod void DeleteJunkMailLog() {

          //insert a task into Task table 

          //you can specify a special user account as a the test OwnerId, just add the criteria after where statement

          User cnUser = [Select Id From User Where IsActive=True and email='jenny.chen@ef.com' limit 1];

          ID idUser = cnUser.Id;

          Task objTask1 = new Task(subject='EMail1:TestMail',OwnerId=idUser);

          insert objTask1;

          //if this record is insert into database,it should be true

          System.assert(true);

          //check wether the record is only the lastest one

          System.assert([Select count() From Task t where ownerid =: idUser and subject = 'EMail1:TestMail']==1);   

    }

}