# Front end

The interface uses plain HTML, CSS and JavaScript. No npm install or framework build is needed.

| File | Purpose |
|---|---|
| index.html | Header, navigation, page container and checkout dialog. |
| style.css | Black-and-white design and responsive layout. |
| app.js | Restaurant/menu screens, cart, order history, operator controls and API requests. |

## Run with Oracle

From the repository root, compile and start the Java server using [the connectivity commands](../docs/connectivity/README.md). Open http://127.0.0.1:8788.

```powershell
javac -d build backend/FoodService.java backend/WebServer.java
java -cp "build;backend/lib/ojdbc6.jar" WebServer backend/config/database.properties
```

## Preview only

If you have Python, you can preview the layout using:

```powershell
python -m http.server 8790 --bind 127.0.0.1 --directory frontend
```

Open http://127.0.0.1:8790. This uses the labelled browser demo and does not connect to Oracle. Browser demo records use localStorage.

## Syntax check

With Node installed:

```powershell
node --check frontend/app.js
```

## Sections

- Restaurants: search, choose a restaurant, read dish descriptions, build a cart and checkout.
- My orders: inspect the selected customer's saved orders.
- Kitchen: edit menu prices/availability and advance preparation.
- Deliveries: assign available partners, record pickup/payment and finish delivery.

Customer selection changes the ordering identity and clears the cart. The server validates prices and business rules again before writing to Oracle.
