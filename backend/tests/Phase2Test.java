import java.util.*;
import java.sql.*;
import java.math.BigDecimal;
import java.nio.file.*;

public class Phase2Test {
    static int passed=0;
    interface Test {void run() throws Exception;}
    static void check(boolean ok,String title){if(!ok)throw new AssertionError(title);System.out.println("PASS "+(++passed)+": "+title);}
    static void rejects(String title,Test action) throws Exception {try{action.run();}catch(IllegalArgumentException|SQLException e){check(true,title);return;}throw new AssertionError("Expected rejection: "+title);}
    static long count(FoodService s,String table) throws Exception {return Long.parseLong(s.query("SELECT COUNT(*) FROM "+table).get(0)[0]);}
    static Map<Long,Integer> cart(long item,int quantity){Map<Long,Integer> c=new LinkedHashMap<>();c.put(item,quantity);return c;}
    public static void main(String[] args) throws Exception {
        Properties p=new Properties();try(java.io.Reader r=Files.newBufferedReader(Paths.get(args[0]))){p.load(r);}
        try(FoodService s=new FoodService(p.getProperty("url"),p.getProperty("user"),p.getProperty("password"))){
            long user=0,partner=0,order=0,cancelOrder=0,onlineOrder=0,newRestaurant=0,newFood=0;
            BigDecimal oldPrice=new BigDecimal(s.query("SELECT current_price FROM menu_item WHERE item_id=11").get(0)[0]);
            LinkedHashMap<String,Long> before=new LinkedHashMap<>();for(String t:Arrays.asList("APP_USER","CUSTOMER","DELIVERY_PARTNER","RESTAURANT","MENU_ITEM","FOOD_ORDER","ORDER_ITEM","PAYMENT","DELIVERY"))before.put(t,count(s,t));
            try {
                check(s.restaurants().size()==2,"JDBC retrieves two restaurants");
                check(s.total(1001).compareTo(new BigDecimal("350"))==0,"Original order 1001 totals 350.00");
                check(s.query("SELECT user_id FROM customer INTERSECT SELECT user_id FROM delivery_partner").size()==1,"Sample user 3 has both roles");
                rejects("Account must have at least one role",()->s.createAccount("Test","test@example.com","",false,false,"CAR"));
                user=s.createAccount("Phase 2 test","phase2test@example.com","",true,false,"BICYCLE");
                final long uid=user;
                s.addRole(uid,"both","BICYCLE");
                s.addRole(uid,"partner","BICYCLE");
                check(s.query("SELECT user_id FROM delivery_partner WHERE user_id=?",uid).size()==1,"Adding partner role to customer is idempotent");
                rejects("Profile must exist before adding a role",()->s.addRole(999999999,"customer","WALK"));
                rejects("Unknown profile role rejected",()->s.addRole(uid,"admin","WALK"));
                rejects("Invalid partner transport rejected",()->s.addRole(uid,"partner","PLANE"));
                check(s.query("SELECT user_id FROM customer WHERE user_id=?",uid).size()==1&&s.query("SELECT user_id FROM delivery_partner WHERE user_id=?",uid).size()==1,"Account and overlapping roles commit together");
                long users=count(s,"APP_USER");
                rejects("Duplicate email rolls back account creation",()->s.createAccount("Duplicate","PHASE2TEST@EXAMPLE.COM","",true,false,"CAR"));
                check(count(s,"APP_USER")==users,"Duplicate account leaves row count unchanged");
                rejects("Empty cart rejected",()->s.placeOrder(uid,10,new HashMap<>(),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                rejects("Zero quantity rejected",()->s.placeOrder(uid,10,cart(11,0),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                rejects("Negative delivery fee rejected",()->s.placeOrder(uid,10,cart(11,1),"Gate","Chennai","600001",new BigDecimal("-1"),"CASH"));
                rejects("Unavailable item rejected",()->s.placeOrder(uid,20,cart(23,1),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                rejects("Cross-restaurant cart rejected",()->s.placeOrder(uid,10,cart(21,1),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                long orders=count(s,"FOOD_ORDER"),lines=count(s,"ORDER_ITEM"),payments=count(s,"PAYMENT");
                rejects("Invalid customer foreign key rolls back checkout",()->s.placeOrder(999999999,10,cart(11,1),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                rejects("Payment overflow rolls back the already inserted header and lines",()->s.placeOrder(uid,10,cart(11,10000000),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH"));
                check(count(s,"FOOD_ORDER")==orders&&count(s,"ORDER_ITEM")==lines&&count(s,"PAYMENT")==payments,"Failed checkout leaves no order, line or payment");
                Map<Long,Integer> multi=cart(11,2);multi.put(12L,1);
                order=s.placeOrder(uid,10,multi,"Gate","Chennai","600001",new BigDecimal("30.00"),"CASH");final long oid=order;
                check(s.total(order).compareTo(new BigDecimal("350"))==0,"Multi-item checkout captures 2 x 120 + 80 + 30 = 350");
                s.editMenu(11,new BigDecimal("140.00"),true);
                check(s.total(order).compareTo(new BigDecimal("350"))==0&&s.total(1001).compareTo(new BigDecimal("350"))==0,"Current price change preserves historical totals");
                rejects("Invalid workflow jump rejected",()->s.advance(oid,"READY"));
                rejects("Pickup without READY and assignment rejected",()->s.dispatch(oid));
                s.advance(order,"ACCEPTED");s.advance(order,"PREPARING");s.advance(order,"READY");
                rejects("Cancellation after preparation rejected",()->s.advance(oid,"CANCELLED"));
                s.assign(order,uid);
                check(s.query("SELECT availability_status FROM delivery_partner WHERE user_id=?",uid).get(0)[0].equals("BUSY"),"Assignment marks partner BUSY");
                rejects("Duplicate assignment rejected",()->s.assign(oid,uid));
                s.dispatch(order);
                check(s.query("SELECT order_status FROM food_order WHERE order_id=?",oid).get(0)[0].equals("OUT_FOR_DELIVERY"),"Cash pickup permits pending payment");
                rejects("Delivery without successful payment rejected",()->s.deliver(oid));
                s.pay(order);s.deliver(order);
                check(s.query("SELECT availability_status FROM delivery_partner WHERE user_id=?",uid).get(0)[0].equals("AVAILABLE"),"Delivery releases partner");
                check(s.query("SELECT order_id FROM delivery WHERE order_id=? AND assigned_at<=picked_up_at AND picked_up_at<=delivered_at",oid).size()==1,"Assignment, pickup and delivery timestamps ordered");
                rejects("Delivered order cannot change payment",()->s.pay(oid));
                cancelOrder=s.placeOrder(uid,20,cart(21,1),"Gate","Chennai","600001",BigDecimal.ZERO,"CASH");final long cid=cancelOrder;
                s.advance(cancelOrder,"CANCELLED");rejects("Cancelled order cannot be paid",()->s.pay(cid));
                onlineOrder=s.placeOrder(uid,20,cart(22,1),"Gate","Chennai","600001",BigDecimal.ZERO,"ONLINE");final long on=onlineOrder;
                s.advance(on,"ACCEPTED");s.advance(on,"PREPARING");s.advance(on,"READY");s.assign(on,uid);
                rejects("Online pickup waits for successful payment",()->s.dispatch(on));s.pay(on);s.dispatch(on);s.deliver(on);
                check(s.query("SELECT o.order_id FROM food_order o JOIN payment p ON p.order_id=o.order_id JOIN delivery d ON d.order_id=o.order_id WHERE o.order_id=? AND o.order_status='DELIVERED' AND p.payment_status='SUCCESS' AND d.delivered_at IS NOT NULL",on).size()==1,"Full online order workflow completes through JDBC");
                // Direct Oracle constraints, each isolated in a rollback-only transaction.
                rejects("Oracle rejects duplicate order lines",()->s.transaction(()->{s.write("INSERT INTO order_item VALUES (1001,11,1,120)");return null;}));
                rejects("Oracle rejects zero quantity",()->s.transaction(()->{s.write("UPDATE order_item SET quantity=0 WHERE order_id=1001 AND item_id=11");return null;}));
                rejects("Oracle rejects a fractional quantity",()->s.transaction(()->{s.write("UPDATE order_item SET quantity=1.5 WHERE order_id=1001 AND item_id=11");return null;}));
                rejects("Oracle rejects a missing menu foreign key",()->s.transaction(()->{s.write("INSERT INTO order_item VALUES (1001,999999,1,100)");return null;}));
                rejects("Oracle rejects success without a payment timestamp",()->s.transaction(()->{s.write("UPDATE payment SET paid_at=NULL WHERE order_id=1001");return null;}));
                rejects("Oracle rejects delivery before pickup",()->s.transaction(()->{s.write("UPDATE delivery SET delivered_at=assigned_at WHERE order_id=1001");return null;}));
                rejects("Oracle preserves referenced menu history",()->s.transaction(()->{s.write("DELETE FROM menu_item WHERE item_id=11");return null;}));
                rejects("Restaurant requires a name",()->s.createRestaurant(" ","Gate","Chennai","600001",null));
                newRestaurant=s.createRestaurant("Test Kitchen","Sample Gate","Chennai","600001",null);
                final long rid=newRestaurant;
                check(s.query("SELECT restaurant_id FROM restaurant WHERE restaurant_id=?",rid).size()==1,"New restaurant saved through JDBC");
                rejects("Food requires an existing restaurant",()->s.createFood(999999999,"Soup","Main Course",new BigDecimal("60.00"),true));
                rejects("Food requires a positive price",()->s.createFood(rid,"Soup","Main Course",BigDecimal.ZERO,true));
                newFood=s.createFood(rid,"Chef's Soup","Main Course",new BigDecimal("60.00"),false);
                check(s.query("SELECT item_id FROM menu_item WHERE item_id=? AND restaurant_id=? AND is_available=0",newFood,rid).size()==1,"New food belongs to selected restaurant and preserves availability");
            } finally {
                final long[] cleanup={order,cancelOrder,onlineOrder};final long uid=user;
                final long rid=newRestaurant,mid=newFood;
                s.transaction(()->{if(mid>0)s.write("DELETE FROM menu_item WHERE item_id=?",mid);if(rid>0)s.write("DELETE FROM restaurant WHERE restaurant_id=?",rid);return null;});
                s.transaction(()->{for(long o:cleanup)if(o>0){s.write("DELETE FROM delivery WHERE order_id=?",o);s.write("DELETE FROM payment WHERE order_id=?",o);s.write("DELETE FROM order_item WHERE order_id=?",o);s.write("DELETE FROM food_order WHERE order_id=?",o);}if(uid>0){s.write("DELETE FROM delivery_partner WHERE user_id=?",uid);s.write("DELETE FROM customer WHERE user_id=?",uid);s.write("DELETE FROM app_user WHERE user_id=?",uid);}s.write("UPDATE menu_item SET current_price=? WHERE item_id=11",oldPrice);return null;});
            }
            for(String table:before.keySet())check(count(s,table)==before.get(table),"Test cleanup preserves original "+table+" row count");
            System.out.println("RESULT: "+passed+" checks passed against Oracle XE through JDBC. Test rows removed. Sequences may have gaps.");
        }
    }
}
