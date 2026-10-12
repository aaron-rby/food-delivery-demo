# Show and explain Phase 2

## 1. Tables and constraints

In SQL Developer, the existing connection still uses SYSTEM. For read-only inspection from that connection, use schema-qualified names such as `SELECT * FROM food_project.app_user;` or open `database/queries/03_view_from_system.sql`. To develop directly as the project owner, create a SQL Developer connection with username FOOD_PROJECT and the credentials in your private properties file. Use the same host/port/SID as the working local XE connection and the Default role.

Explain: APP_USER stores common account data. CUSTOMER and DELIVERY_PARTNER inherit the user ID. RESTAURANT owns MENU_ITEM. FOOD_ORDER points to its customer and restaurant. ORDER_ITEM resolves the many-to-many order/menu relationship with a composite key. PAYMENT permits at most one payment per order using UNIQUE(order_id). DELIVERY uses the order ID as its primary and foreign key.

## 2. Sample data

Show menu availability, two restaurants and orders with different states. User 3 has both customer and partner roles. Order 1001 totals 2 × 120 + 80 + 30 = 350. Order totals use saved agreed prices, not the current menu price.

## 3. Customer flow

Open http://127.0.0.1:8788 and confirm Oracle connected. Select a demo customer, choose Campus Kitchen, add two Veg Rice and one Juice, and check the total of ₹350. Enter a fictional destination and place the order. My orders should show its generated ID, items, total, payment method/status and destination. Refresh to prove persistence.

## 4. Operator workflow

Open Kitchen, find the demonstration order and mark ACCEPTED, PREPARING, then READY. In Deliveries, choose an available partner and assign. Record pickup. Cash orders can be picked up while payment is pending, but successful payment is required before delivery completion. Record simulated payment, then mark delivered. The partner returns to AVAILABLE.

Online orders require simulated successful payment before pickup. Cancellation is allowed only from PLACED or ACCEPTED. Closed orders cannot change payment.

## 5. Business rules

Show the unavailable Dosa button. Explain that the Java service checks availability again when saving, rather than trusting only the browser. It also rejects empty carts, nonpositive quantities and mixed-restaurant items. Menu price edits affect future orders while agreed_unit_price preserves old totals.

## 6. Connectivity

Explain the request path: browser, Java HTTP adapter, FoodService, Oracle JDBC driver, FOOD_PROJECT schema. The browser never receives the Oracle password. PreparedStatement binds SQL values. The service commits all order rows together or rolls back on failure.

## Phase 3

Add remaining account/restaurant CRUD interfaces and any required safe deletion flows, extend tests and documentation, and prepare the final report. Authentication and real payment processing are outside the current stated scope.
