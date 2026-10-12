import java.sql.*;
import java.math.BigDecimal;
import java.util.*;

/** All writes use bound values and explicit transactions. One connection per UI session. */
public class FoodService implements AutoCloseable {
    final Connection db;
    public FoodService(String url, String user, String password) throws SQLException {
        DriverManager.setLoginTimeout(8);
        db=DriverManager.getConnection(url,user,password);
        db.setAutoCommit(false);
    }
    interface Work<T> { T run() throws Exception; }
    synchronized <T> T transaction(Work<T> work) throws Exception {
        try { T value=work.run(); db.commit(); return value; }
        catch(Exception e) { db.rollback(); throw e; }
    }
    static void require(boolean ok, String message) {
        if(!ok) throw new IllegalArgumentException(message);
    }
    static String required(String value,int max,String field) {
        require(value!=null && !value.trim().isEmpty(),field+" is required.");
        value=value.trim(); require(value.length()<=max,field+" is too long."); return value;
    }
    static BigDecimal money(String value,boolean allowZero) {
        BigDecimal n=new BigDecimal(value).setScale(2,java.math.RoundingMode.UNNECESSARY);
        require(n.compareTo(BigDecimal.ZERO)>(allowZero?-1:0) && n.precision()<=10,"Enter a valid amount with at most two decimal places."); return n;
    }
    PreparedStatement statement(String sql,Object... args) throws SQLException {
        PreparedStatement p=db.prepareStatement(sql);
        for(int i=0;i<args.length;i++) p.setObject(i+1,args[i]);
        return p;
    }
    int write(String sql,Object... args) throws SQLException {
        try(PreparedStatement p=statement(sql,args)) {return p.executeUpdate();}
    }
    long nextId(String sequence) throws SQLException {
        // Sequence names are internal constants, never UI input.
        try(Statement s=db.createStatement();ResultSet r=s.executeQuery("SELECT "+sequence+".NEXTVAL FROM dual")){r.next();return r.getLong(1);}
    }
    synchronized List<String[]> query(String sql,Object... args) throws SQLException {
        try(PreparedStatement p=statement(sql,args);ResultSet r=p.executeQuery()) {
            List<String[]> rows=new ArrayList<>();
            while(r.next()){String[] row=new String[r.getMetaData().getColumnCount()];for(int i=0;i<row.length;i++)row[i]=r.getString(i+1);rows.add(row);}
            return rows;
        }
    }
    List<String[]> restaurants() throws SQLException {return query("SELECT restaurant_id,restaurant_name,city FROM restaurant ORDER BY restaurant_id");}
    List<String[]> menu(long restaurant) throws SQLException {return query("SELECT item_id,item_name,category,current_price,is_available FROM menu_item WHERE restaurant_id=? ORDER BY item_id",restaurant);}
    List<String[]> customers() throws SQLException {return query("SELECT c.user_id,u.full_name FROM customer c JOIN app_user u ON u.user_id=c.user_id ORDER BY c.user_id");}
    List<String[]> partners() throws SQLException {return query("SELECT p.user_id,u.full_name,p.availability_status FROM delivery_partner p JOIN app_user u ON u.user_id=p.user_id ORDER BY p.user_id");}
    List<String[]> orders(long customer) throws SQLException {
        return query("SELECT o.order_id,u.full_name,r.restaurant_name,o.order_status, "+
          "(SELECT SUM(i.quantity*i.agreed_unit_price) FROM order_item i WHERE i.order_id=o.order_id)+o.delivery_fee amount_due, "+
          "p.payment_method,p.payment_status,d.partner_id,TO_CHAR(d.picked_up_at,'DD-MON HH24:MI:SS'),TO_CHAR(d.delivered_at,'DD-MON HH24:MI:SS'),o.customer_id,o.dropoff_line,o.dropoff_city,o.dropoff_postal_code "+
          "FROM food_order o JOIN app_user u ON u.user_id=o.customer_id JOIN restaurant r ON r.restaurant_id=o.restaurant_id "+
          "LEFT JOIN payment p ON p.order_id=o.order_id LEFT JOIN delivery d ON d.order_id=o.order_id WHERE (?=0 OR o.customer_id=?) ORDER BY o.order_id",customer,customer);
    }
    BigDecimal total(long order) throws SQLException {
        try(PreparedStatement p=statement("SELECT SUM(i.quantity*i.agreed_unit_price)+o.delivery_fee FROM food_order o JOIN order_item i ON i.order_id=o.order_id WHERE o.order_id=? GROUP BY o.delivery_fee",order);ResultSet r=p.executeQuery()){
            require(r.next(),"Order needs at least one item.");return r.getBigDecimal(1);
        }
    }
    String lockOrder(long order) throws SQLException {
        try(PreparedStatement p=statement("SELECT order_status FROM food_order WHERE order_id=? FOR UPDATE",order);ResultSet r=p.executeQuery()){
            require(r.next(),"Order does not exist.");return r.getString(1);
        }
    }
    public long createAccount(String name,String email,String phone,boolean customer,boolean partner,String mode) throws Exception {
        final String n=required(name,100,"Name"),e=required(email,254,"Email").toLowerCase(Locale.ROOT);
        require(customer||partner,"Choose at least one role.");
        require(phone==null || phone.length()<=20,"Phone is too long.");
        require(!partner||Arrays.asList("WALK","BICYCLE","MOTORBIKE","CAR").contains(mode),"Invalid transport mode.");
        return transaction(()->{long id=nextId("app_user_seq");write("INSERT INTO app_user VALUES (?,?,?,?)",id,n,e,phone);
            if(customer)write("INSERT INTO customer VALUES (?,SYSTIMESTAMP)",id);
            if(partner)write("INSERT INTO delivery_partner VALUES (?,?,'AVAILABLE')",id,mode);return id;});
    }
    public long addRole(long user,String role,String mode) throws Exception {
        require(Arrays.asList("customer","partner").contains(role),"Invalid profile role.");
        require(!role.equals("partner")||Arrays.asList("WALK","BICYCLE","MOTORBIKE","CAR").contains(mode),"Invalid transport mode.");
        return transaction(()->{
            require(!query("SELECT user_id FROM app_user WHERE user_id=? FOR UPDATE",user).isEmpty(),"Profile not found.");
            if(role.equals("customer")&&query("SELECT user_id FROM customer WHERE user_id=?",user).isEmpty())write("INSERT INTO customer VALUES (?,SYSTIMESTAMP)",user);
            if(role.equals("partner")&&query("SELECT user_id FROM delivery_partner WHERE user_id=?",user).isEmpty())write("INSERT INTO delivery_partner VALUES (?,?,'AVAILABLE')",user,mode);
            return user;
        });
    }
    public long placeOrder(long customer,long restaurant,Map<Long,Integer> cart,String address,String city,String postal,BigDecimal fee,String method) throws Exception {
        final String a=required(address,200,"Address"),c=required(city,80,"City"),p=required(postal,12,"Postal code");
        require(!cart.isEmpty(),"Add at least one item."); require(customer>0&&restaurant>0,"Choose customer and restaurant.");
        require(fee!=null&&fee.signum()>=0&&fee.scale()<=2&&fee.precision()<=10,"Invalid delivery fee.");
        require(Arrays.asList("CASH","ONLINE").contains(method),"Invalid payment method.");
        return transaction(()->{
            LinkedHashMap<Long,BigDecimal> prices=new LinkedHashMap<>();
            // Lock in ID order so simultaneous carts do not reverse the lock order.
            for(Long id:new TreeSet<>(cart.keySet())){
                Integer qty=cart.get(id);require(qty!=null&&qty>=1,"Quantity must be a positive integer.");
                try(PreparedStatement s=statement("SELECT restaurant_id,current_price,is_available FROM menu_item WHERE item_id=? FOR UPDATE",id);ResultSet r=s.executeQuery()){
                    require(r.next(),"Item does not exist: "+id);require(r.getLong(1)==restaurant,"All items must belong to the selected restaurant.");
                    require(r.getInt(3)==1,"Item is unavailable: "+id);prices.put(id,r.getBigDecimal(2));
                }
            }
            long order=nextId("food_order_seq");
            write("INSERT INTO food_order (order_id,customer_id,restaurant_id,dropoff_line,dropoff_city,dropoff_postal_code,delivery_fee) VALUES (?,?,?,?,?,?,?)",order,customer,restaurant,a,c,p,fee);
            for(Long id:prices.keySet())write("INSERT INTO order_item VALUES (?,?,?,?)",order,id,cart.get(id),prices.get(id));
            write("INSERT INTO payment (payment_id,order_id,payment_method,payment_amount,payment_status) VALUES (?,?,?,?,'PENDING')",nextId("payment_seq"),order,method,total(order));
            return order;
        });
    }
    public void editMenu(long item,BigDecimal price,boolean available) throws Exception {
        require(price!=null&&price.signum()>0&&price.scale()<=2&&price.precision()<=10,"Price must be positive with at most two decimal places.");
        transaction(()->{require(write("UPDATE menu_item SET current_price=?,is_available=? WHERE item_id=?",price,available?1:0,item)==1,"Item does not exist.");return null;});
    }
    public void pay(long order) throws Exception {
        transaction(()->{String status=lockOrder(order);require(!Arrays.asList("CANCELLED","DELIVERED").contains(status),"Payment cannot change for a closed order.");
            require(write("UPDATE payment SET payment_amount=?,payment_status='SUCCESS',paid_at=SYSTIMESTAMP WHERE order_id=? AND payment_status<>'SUCCESS'",total(order),order)==1,"Payment already succeeded or is missing.");return null;});
    }
    static boolean transitionAllowed(String from,String to) {
        if(to.equals("CANCELLED"))return from.equals("PLACED")||from.equals("ACCEPTED");
        return (from.equals("PLACED")&&to.equals("ACCEPTED"))||(from.equals("ACCEPTED")&&to.equals("PREPARING"))||(from.equals("PREPARING")&&to.equals("READY"));
    }
    public void advance(long order,String target) throws Exception {
        transaction(()->{String from=lockOrder(order);require(transitionAllowed(from,target),"Invalid transition: "+from+" to "+target);
            write("UPDATE food_order SET order_status=? WHERE order_id=?",target,order);return null;});
    }
    public void assign(long order,long partner) throws Exception {
        transaction(()->{require(lockOrder(order).equals("READY"),"An order must be READY before assignment.");
            try(PreparedStatement p=statement("SELECT availability_status FROM delivery_partner WHERE user_id=? FOR UPDATE",partner);ResultSet r=p.executeQuery()){
                require(r.next()&&r.getString(1).equals("AVAILABLE"),"Partner must be available.");
            }
            write("INSERT INTO delivery (order_id,partner_id) VALUES (?,?)",order,partner);
            write("UPDATE delivery_partner SET availability_status='BUSY' WHERE user_id=?",partner);return null;});
    }
    public void dispatch(long order) throws Exception {
        transaction(()->{require(lockOrder(order).equals("READY"),"Only READY orders can be picked up.");
            List<String[]> payment=query("SELECT payment_method,payment_status FROM payment WHERE order_id=?",order);
            require(payment.size()==1,"Payment record is missing.");
            require(payment.get(0)[0].equals("CASH")?!payment.get(0)[1].equals("FAILED"):payment.get(0)[1].equals("SUCCESS"),"Online payment must succeed before pickup.");
            require(write("UPDATE delivery SET picked_up_at=SYSTIMESTAMP WHERE order_id=? AND picked_up_at IS NULL",order)==1,"Assign a partner before pickup.");
            write("UPDATE food_order SET order_status='OUT_FOR_DELIVERY' WHERE order_id=?",order);return null;});
    }
    public void deliver(long order) throws Exception {
        transaction(()->{require(lockOrder(order).equals("OUT_FOR_DELIVERY"),"Order must be out for delivery.");
            List<String[]> payment=query("SELECT payment_status,payment_amount FROM payment WHERE order_id=?",order);
            require(payment.size()==1&&payment.get(0)[0].equals("SUCCESS")&&new BigDecimal(payment.get(0)[1]).compareTo(total(order))==0,"Successful payment must match the order total.");
            List<String[]> d=query("SELECT partner_id FROM delivery WHERE order_id=? AND picked_up_at IS NOT NULL",order);require(d.size()==1,"Pickup record is missing.");
            write("UPDATE delivery SET delivered_at=SYSTIMESTAMP WHERE order_id=?",order);
            write("UPDATE food_order SET order_status='DELIVERED' WHERE order_id=?",order);
            write("UPDATE delivery_partner SET availability_status='AVAILABLE' WHERE user_id=?",Long.parseLong(d.get(0)[0]));return null;});
    }
    public void close() throws SQLException {db.rollback();db.close();}
}
