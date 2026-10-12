import java.util.*;
import java.nio.file.*;
public class RoleReview {
  static class RollbackService extends FoodService {
    RollbackService(Properties p)throws Exception{super(p.getProperty("url"),p.getProperty("user"),p.getProperty("password"));}
    @Override synchronized <T> T transaction(Work<T> work)throws Exception{return work.run();}
  }
  public static void main(String[] args)throws Exception {
    Properties p=new Properties();try(var r=Files.newBufferedReader(Path.of(args[0]))){p.load(r);}
    try(var s=new RollbackService(p)){
      long id=s.createAccount("Role review test","role-review-"+UUID.randomUUID()+"@example.invalid",null,false,true,"WALK");
      s.addRole(id,"both","WALK");
      boolean customer=!s.query("SELECT user_id FROM customer WHERE user_id=?",id).isEmpty();
      boolean partner=!s.query("SELECT user_id FROM delivery_partner WHERE user_id=?",id).isEmpty();
      if(!customer||!partner)throw new AssertionError("Both role regression");
      s.removeCustomer(id);
      if(s.query("SELECT user_id FROM delivery_partner WHERE user_id=?",id).isEmpty())throw new AssertionError("Partner role must survive");
      long r=s.createRestaurant("Removal test","Sample Street","Chennai","600001",null);
      long food=s.createFood(r,"Test Soup","Starter",new java.math.BigDecimal("70.00"),true);
      s.removeFood(food);
      s.createFood(r,"Test Soup","Starter",new java.math.BigDecimal("70.00"),true);
      s.removeRestaurant(r);
      if(!s.query("SELECT item_id FROM menu_item WHERE restaurant_id=?",r).isEmpty())throw new AssertionError("Restaurant menu cleanup");
      int rejected=0;
      try{s.removeFood(11);}catch(IllegalArgumentException e){rejected++;}
      try{s.removeCustomer(1);}catch(IllegalArgumentException e){rejected++;}
      try{s.removeRestaurant(10);}catch(IllegalArgumentException e){rejected++;}
      if(rejected!=3)throw new AssertionError("History protection");
      System.out.println("PASS: removals, preserved partner role, history protection and Both-role regression.");
      System.out.println("Existing partner + Both: customer="+customer+", partner="+partner+" (expected true, true)");
      s.db.rollback();
      System.out.println("All review records rolled back; no retained data changes.");
    }
  }
}
