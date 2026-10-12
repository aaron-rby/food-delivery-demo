import com.sun.net.httpserver.*;
import java.net.*;
import java.nio.file.*;
import java.nio.charset.StandardCharsets;
import java.io.*;
import java.util.*;
import java.math.BigDecimal;

/** Loopback-only browser adapter for the existing Oracle JDBC service. */
public class WebServer {
  static FoodService service;
  static Path root;
  static String token=UUID.randomUUID().toString();
  static String quote(String s) {
    if(s==null)return "null";
    return "\""+s.replace("\\","\\\\").replace("\"","\\\"").replace("\n","\\n").replace("\r","\\r").replace("\t","\\t")+"\"";
  }
  static String rows(List<String[]> rows) {
    StringJoiner out=new StringJoiner(",","[","]");
    for(String[] row:rows){StringJoiner a=new StringJoiner(",","[","]");for(String v:row)a.add(quote(v));out.add(a.toString());}return out.toString();
  }
  static void reply(HttpExchange x,int status,String body,String type)throws IOException {
    byte[] bytes=body.getBytes(StandardCharsets.UTF_8);x.getResponseHeaders().set("Content-Type",type);x.getResponseHeaders().set("Cache-Control","no-store");x.getResponseHeaders().set("X-Content-Type-Options","nosniff");x.sendResponseHeaders(status,bytes.length);try(OutputStream o=x.getResponseBody()){o.write(bytes);}
  }
  static Map<String,String> form(HttpExchange x)throws IOException {
    byte[] data=x.getRequestBody().readNBytes(65537);if(data.length>65536)throw new IllegalArgumentException("Request too large.");
    Map<String,String> p=new HashMap<>();for(String pair:new String(data,StandardCharsets.UTF_8).split("&")){String[] kv=pair.split("=",2);p.put(URLDecoder.decode(kv[0],"UTF-8"),kv.length>1?URLDecoder.decode(kv[1],"UTF-8"):"");}return p;
  }
  static long id(Map<String,String> p,String key){return Long.parseLong(p.get(key));}
  static synchronized void api(HttpExchange x)throws IOException {
    try {
      if(!x.getRequestMethod().equals("GET")&&!x.getRequestMethod().equals("POST")){reply(x,405,"{}","application/json");return;}
      String host=x.getRequestHeaders().getFirst("Host");if(!"127.0.0.1:8788".equals(host)&&!"localhost:8788".equals(host)){reply(x,403,"{}","application/json");return;}
      if(service==null){reply(x,503,"{\"error\":\"Oracle connection is unavailable. Check the private connection properties, then restart the server.\"}","application/json");return;}
      if(x.getRequestMethod().equals("GET")) {
        String state="{\"mode\":\"oracle\",\"token\":"+quote(token)+",\"restaurants\":"+rows(service.restaurants())+",\"customers\":"+rows(service.customers())+",\"partners\":"+rows(service.partners())+",\"orders\":"+rows(service.orders(0))+",\"menu\":"+rows(service.query("SELECT item_id,item_name,category,current_price,is_available,restaurant_id FROM menu_item ORDER BY item_id"))+",\"lines\":"+rows(service.query("SELECT order_id,item_id,quantity,agreed_unit_price FROM order_item ORDER BY order_id,item_id"))+"}";
        service.db.rollback();reply(x,200,state,"application/json; charset=utf-8");return;
      }
      if(!token.equals(x.getRequestHeaders().getFirst("X-Session-Token"))){reply(x,403,"{\"error\":\"Refresh the page before making changes.\"}","application/json");return;}
      Map<String,String> p=form(x);String action=p.get("action");String result="";
      if("profile".equals(action)) {
        String role=p.get("role");FoodService.require(Arrays.asList("customer","partner").contains(role),"Invalid profile role.");
        String existing=p.getOrDefault("existing","");
        long user=existing.isEmpty()?service.createAccount(p.get("name"),"demo-"+UUID.randomUUID()+"@example.invalid",null,role.equals("customer"),role.equals("partner"),p.get("transport")):service.addRole(Long.parseLong(existing),role,p.get("transport"));
        result=Long.toString(user);
      } else if("place".equals(action)) {
        Map<Long,Integer> cart=new LinkedHashMap<>();for(String line:p.getOrDefault("cart","").split(","))if(!line.isEmpty()){String[] parts=line.split(":");cart.put(Long.parseLong(parts[0]),Integer.parseInt(parts[1]));}
        long order=service.placeOrder(id(p,"customer"),id(p,"restaurant"),cart,p.get("address"),p.get("city"),p.get("postal"),new BigDecimal("30.00"),p.get("method"));result=Long.toString(order);
      } else if("menu".equals(action))service.editMenu(id(p,"item"),FoodService.money(p.get("price"),false),"1".equals(p.get("available")));
      else if("advance".equals(action))service.advance(id(p,"order"),p.get("target"));
      else if("pay".equals(action))service.pay(id(p,"order"));
      else if("assign".equals(action))service.assign(id(p,"order"),id(p,"partner"));
      else if("pickup".equals(action))service.dispatch(id(p,"order"));
      else if("deliver".equals(action))service.deliver(id(p,"order"));
      else throw new IllegalArgumentException("Unknown action.");
      reply(x,200,"{\"ok\":true,\"result\":"+quote(result)+"}","application/json");
    } catch(Exception e){String message=e instanceof java.sql.SQLException?"Database operation failed. Check your connection and required records.":e.getMessage();reply(x,400,"{\"error\":"+quote(message)+"}","application/json");}
  }
  public static void main(String[] args)throws Exception {
    root=Paths.get("frontend").toAbsolutePath().normalize();
    if(args.length>0&&Files.isRegularFile(Paths.get(args[0]))) {
      Properties p=new Properties();try(InputStream in=Files.newInputStream(Paths.get(args[0]))){p.load(in);}
      try{service=new FoodService(p.getProperty("url",p.getProperty("jdbc.url")),p.getProperty("user",p.getProperty("username")),p.getProperty("password"));System.out.println("Oracle JDBC connected.");}catch(Exception e){System.out.println("Oracle connection unavailable; preview still available.");}
    }
    HttpServer server=HttpServer.create(new InetSocketAddress("127.0.0.1",8788),0);server.createContext("/api",WebServer::api);
    server.createContext("/",x->{
      if(!x.getRequestMethod().equals("GET")){reply(x,405,"Method not allowed","text/plain");return;}
      String request=x.getRequestURI().getPath();Path file=root.resolve(request.equals("/")?"index.html":request.substring(1)).normalize();
      if(!file.startsWith(root)||!Files.isRegularFile(file)){reply(x,404,"Not found","text/plain");return;}
      String type=file.toString().endsWith(".css")?"text/css":file.toString().endsWith(".js")?"text/javascript":"text/html";reply(x,200,Files.readString(file),type+"; charset=utf-8");
    });server.start();Runtime.getRuntime().addShutdownHook(new Thread(()->{server.stop(0);try{if(service!=null)service.close();}catch(Exception ignored){}}));
    System.out.println("Local: http://127.0.0.1:8788");
  }
}
