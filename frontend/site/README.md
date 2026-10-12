# Savour DELIVERY

## Java and Oracle behind this website

The shared backend is written in **Java**, using **JDBC** to connect to **Oracle**:

```text
This browser website → HTTPS tunnel → WebServer.java → FoodService.java → JDBC → Oracle
```

- **WebServer.java:** serves the interface and handles GET/POST `/api` requests, JSON responses and the configured GitHub Pages origin.
- **FoodService.java:** uses prepared SQL statements, validation, transactions, commit/rollback and locks. It handles users/roles, restaurants, food, checkout, preparation, partner assignment, payment, delivery and protected removals.
- **Phase2Test.java:** exercises Oracle constraints and complete ordering/delivery workflows. Additional rollback-only tests cover the Both-role regression and safe removals.

The Java code needs JDK 17+ and an Oracle JDBC driver. It runs on the project computer; GitHub Pages hosts only this browser frontend. The complete Java source, Oracle setup and run commands are in the [full project repository](https://github.com/aaron-rby/savour-delivery#java-backend). All visitors can now inspect the complete project source.

## Relational schema — nine tables

The project's normalization worksheet demonstrates 3NF/BCNF under its stated functional dependencies. Keys and CHECK constraints are enforced in Oracle; cross-table workflow rules are enforced in Java transactions.

| Table | Primary key | Foreign keys | Main rule |
|---|---|---|---|
| APP_USER | user_id | — | Unique normalized email |
| CUSTOMER | user_id | APP_USER | Customer subtype, shared ID |
| DELIVERY_PARTNER | user_id | APP_USER | Partner subtype; allowed transport/availability values |
| RESTAURANT | restaurant_id | — | Required name and address details |
| MENU_ITEM | item_id | RESTAURANT | Positive price; availability 0/1 |
| FOOD_ORDER | order_id | CUSTOMER, RESTAURANT | Allowed status; nonnegative fee |
| ORDER_ITEM | (order_id, item_id) | FOOD_ORDER, MENU_ITEM | Positive integer quantity and captured price |
| PAYMENT | payment_id | Unique order_id → FOOD_ORDER | Positive amount; success requires timestamp |
| DELIVERY | order_id | FOOD_ORDER, DELIVERY_PARTNER | One delivery per order; ordered event timestamps |

Customer and Partner roles overlap: Both uses one APP_USER and two subtype rows. Admin is the external demonstration operator. Order totals are derived from captured line prices plus the delivery fee. Referenced order/delivery history is protected during removal. No reviews, ratings or identity columns are claimed in this model.

A public, black-and-white browser demo for a Database Systems course project.

Choose Customer, Partners or Admin in the header. Customers browse restaurants and see their own orders. Partners see only their assigned deliveries. Admin manages menus, preparation and partner assignment. Meera Shah has both customer and delivery partner roles.

Customer view has an **Add customer** button; Partners view has **Add delivery partner**. The form lets you select Customer, Delivery partner or Both, create a named person, or add roles to an existing person. Both uses one ID across the two roles. IDs identify people even when names match. This is a demonstration role selector without login, so it does not enforce access permissions.

**Shared demonstration:** `backend-config.js` points to a temporary HTTPS tunnel to the local Java/Oracle backend. Visitors share database records while the computer, Oracle, Java server and tunnel are running. Views refresh every five seconds when no form is being edited. There is no login: roles are demonstration filters, not permissions. Use fictional information and simulated payments only.

When the shared server is offline, saving is disabled and the UI retries every five seconds. Existing browser-only orders are not automatically uploaded. Clearing the API URL restores the separate localStorage demo. A restarted Quick Tunnel receives a new URL; update backend-config.js and publish it.

The Java/JDBC/Oracle project and this website are in the same public repository; this folder contains the hosted website assets.

## Run locally

```powershell
python -m http.server 8790 --bind 127.0.0.1 --directory frontend/site
```

Open http://127.0.0.1:8790. There are no frontend build dependencies.

## Demonstration

Admin's **Menu management** has a restaurant dropdown. Select a restaurant to edit only its dishes. **Add food** creates a named dish with a category, price and availability. **Add restaurant** collects its name, address, city, postal code and optional phone, then selects it so you can add food. Existing visitors receive six extra fictional customers and ten extra dishes without losing saved orders or edited prices.

1. Choose Asha Rao and Campus Kitchen.
2. Add two Veg Rice and one Juice. The total is INR 350 including the delivery fee.
3. Enter a fictional destination and place the order.
4. Choose Admin and mark the new order accepted, preparing, then ready.
5. In Admin, assign an available partner.
6. Choose Partners, select that partner, record pickup and simulated payment, then mark delivered.

Online orders require simulated successful payment before pickup. Delivery completion requires successful payment. You can inspect historical prices by changing a current menu price after placing an order.
