# Savour: the complete beginner's guide

Read sections 1–5 first to understand the idea. Then follow the example order in section 6. The later sections explain the database, code and presentation.

## 1. What does this project do?

This application connects a customer, a restaurant and a delivery person through a food order.

A customer chooses dishes. The restaurant prepares them. A delivery partner picks them up and delivers them. The database records the order, its items, payment and delivery details.

The purpose of this database project is to show that those records remain connected and consistent. For example, an order should not contain an item from the wrong restaurant or lose its original price when the menu changes.

## 2. The three things you should not confuse

| Thing | What it means in your project |
|---|---|
| Oracle Database | The software that stores your tables and runs SQL. |
| SQL Developer | A tool you use to connect to Oracle, run commands and inspect records. |
| Browser application | The interface that lets people order food and update records using buttons. |

**FOOD_PROJECT is your project database account and schema.** A schema is the collection of database objects owned by an account. Your nine tables belong to FOOD_PROJECT.

SYSTEM is an administrator account. A SQL Developer connection's display name can say “FOOD DELIVERY SYS” while its actual username remains SYSTEM. Renaming a connection does not change the account.

To check the actual account, run:

```sql
SELECT USER FROM dual;
```

Your browser app connects as FOOD_PROJECT, even if the separate SQL Developer window currently uses SYSTEM.

## 3. Who uses the application?

| Role | What the person does |
|---|---|
| Customer | Browses menus, places orders and views order history. |
| Restaurant operator | Updates menu prices/availability and moves orders through preparation. |
| Delivery partner | Picks up food and delivers it. A partner can use a bicycle, motorbike, car or walk. |
| Administrator/operator | Coordinates assignments and maintains records. |

The current app has classroom demonstration views. It does not authenticate individual restaurant operators or drivers. Anyone operating this local demonstration can switch between its sections.

### Why is Meera Shah both a customer and a driver?

A person can have more than one role. The initial sample data includes:

| user_id | Person | Customer role? | Delivery partner role? |
|---|---|---|---|
| 1 | Asha Rao | Yes | No |
| 2 | Ravi Kumar | No | Yes |
| 3 | Meera Shah | Yes | Yes |
| 4 | Dev Patel | Yes | No |

Meera has **one APP_USER record**, plus a CUSTOMER record and a DELIVERY_PARTNER record. Each uses `user_id = 3`.

When you select Meera in **Demo customer**, you place/view orders using her customer role. When you assign Meera in **Deliveries**, you use her delivery partner role.

An order's `customer_id` says who ordered it. A delivery's `partner_id` says who delivers it. Those are different facts, even when a person has both roles.

This is **overlapping specialization**. “Overlapping” means both roles are allowed. “Total specialization” means each application user must have at least one of these roles. The Java account-creation service enforces that requirement. Foreign keys alone do not force every parent user to have a subtype row.

The current service also does not prohibit someone with both roles from delivering their own order. That would require an additional business rule if you wanted it.

## 4. Understand the four front-end sections

### Restaurants

This starts the customer journey. Restaurant records and their menus come from Oracle.

1. Select the person who is ordering using **Demo customer**.
2. Search for a restaurant or dish, or choose a category.
3. Open **View menu**.
4. Read the dish description, price and availability.
5. Use **Add** and the quantity controls.
6. Check **Your cart** and open checkout.
7. Enter the destination and payment method.
8. Click **Place order**.

One order belongs to one restaurant. If you already have items in a cart, finish that cart or remove its items before choosing another restaurant. Changing the selected customer clears the cart.

Food descriptions are written display text for the fictional dishes. Prices, categories, names and availability come from MENU_ITEM. The description text does not add a new database column.

### My orders

This displays saved orders for the selected customer: order ID, restaurant, items, quantities, total, status, payment and destination. An assigned partner appears when one exists.

The progress bar follows the normal order stages. A new order appears as PLACED with a PENDING payment. Choosing “Online” at checkout does not automatically make payment successful.

### Kitchen

**Menu management** changes the current price or availability of existing dishes. Click **Save changes** to write the update to Oracle.

**Incoming orders** lets the operator accept, prepare and mark orders ready. It also offers early cancellation and simulated payment recording where allowed.

The current Kitchen screen displays orders across the sample restaurants. It is a demonstration workspace, not a restricted account for one restaurant.

### Deliveries

This displays delivery partners and orders waiting for assignment/pickup or already out for delivery.

1. Wait until the kitchen marks an order READY.
2. Choose an AVAILABLE partner.
3. Click **Assign partner**.
4. Click **Record pickup**.
5. Record successful payment if still pending.
6. Click **Mark delivered**.

Assignment makes the partner BUSY. Delivery completion makes the partner AVAILABLE again. Assignment itself leaves the order READY; pickup changes it to OUT_FOR_DELIVERY.

### The controls around those sections

| Control | Meaning |
|---|---|
| Demo customer | Choose the customer for ordering and order history. This is not login. |
| Oracle connected | The app is reading/writing your FOOD_PROJECT database. |
| Browser demo | The app uses fictional data in browser storage without writing to Oracle. |
| Refresh database | Reload the latest records. Useful after making a change in SQL Developer. |

For the course connectivity demonstration, use **Oracle connected** mode. A browser demo can illustrate the design but cannot prove JDBC connectivity.

## 5. The nine relations, explained simply

A **relation** is a table in the relational model. A **row** represents one record. An **attribute** is a column describing it.

| Table | One row represents | Key and main information |
|---|---|---|
| APP_USER | One person/account | `user_id` PK. Name, unique email and optional phone. |
| CUSTOMER | One person's customer role | `user_id` PK/FK to APP_USER. Customer start date. |
| DELIVERY_PARTNER | One person's delivery role | `user_id` PK/FK to APP_USER. Transport mode and availability. |
| RESTAURANT | One restaurant | `restaurant_id` PK. Name, address components and contact phone. |
| MENU_ITEM | One dish offered by a restaurant | `item_id` PK, `restaurant_id` FK. Name, category, price and availability. |
| FOOD_ORDER | One order | `order_id` PK. Customer/restaurant FKs, placement time, status, destination and fee. |
| ORDER_ITEM | One distinct dish within an order | Composite PK `(order_id, item_id)`. Quantity and agreed unit price. Both IDs are FKs. |
| PAYMENT | One payment record for an order | `payment_id` PK, unique `order_id` FK. Method, amount, status and payment time. |
| DELIVERY | One delivery assignment for an order | `order_id` PK/FK, `partner_id` FK. Assignment, pickup and delivery times. |

### How the tables connect

- APP_USER connects to CUSTOMER and DELIVERY_PARTNER through the shared user ID.
- One CUSTOMER can place many FOOD_ORDER records.
- One RESTAURANT can offer many MENU_ITEM records and receive many FOOD_ORDER records.
- One FOOD_ORDER has one or more ORDER_ITEM rows in a valid placed order.
- One MENU_ITEM can appear in many different orders.
- One FOOD_ORDER has at most one PAYMENT and at most one DELIVERY.
- One DELIVERY_PARTNER can handle many historical deliveries. The service prevents assigning a BUSY partner another order.

**ORDER_ITEM connects orders to menu items.** This resolves a many-to-many relationship: an order can contain several dishes, and a dish can appear in several orders.

### Why are two columns needed for ORDER_ITEM's primary key?

The pair `(order_id, item_id)` identifies a line. Item 11 can appear in many different orders, and order 1001 can contain different items. Neither column alone identifies the line.

If someone orders two portions of the same dish, store one row with `quantity = 2`. Do not add the same item twice with the same order ID.

### What does “optional payment/delivery” mean?

The schema permits an order to have no payment or delivery row yet. The current app creates its PENDING payment during checkout. It creates the DELIVERY row only when assigning a partner.

An existing payment or delivery row must reference an actual order; its order reference cannot be empty.

## 6. Follow one order through the whole system

Imagine Asha orders from Campus Kitchen:

| Item | Quantity | Agreed price | Line cost |
|---|---|---|---|
| Veg Rice | 2 | INR 120 | INR 240 |
| Juice | 1 | INR 80 | INR 80 |

Subtotal = 240 + 80 = **INR 320**. Delivery fee = **INR 30**. Total = **INR 350**.

### What gets saved at checkout?

**FOOD_ORDER:** one row containing Asha's customer ID, restaurant ID, destination, status PLACED and fee.

**ORDER_ITEM:** two rows, one for Veg Rice and one for Juice, with their quantities and captured prices.

**PAYMENT:** one row containing the chosen method, amount 350 and status PENDING. `paid_at` is empty until payment succeeds.

These rows save in one transaction. There is no delivery assignment yet.

The browser demonstration created **order 2005** with this example. That is an observed demonstration ID, not a fixed ID for all future orders.

### What happens after checkout?

| Action | Order status afterward | Other database effect |
|---|---|---|
| Place order | PLACED | Save header, lines and pending payment. |
| Accept | ACCEPTED | Update the order. |
| Start preparation | PREPARING | Update the order. |
| Mark ready | READY | Update the order. |
| Assign Ravi | READY | Insert DELIVERY; Ravi becomes BUSY. |
| Record pickup | OUT_FOR_DELIVERY | Save pickup time. |
| Record simulated payment | Unchanged | Payment becomes SUCCESS; save payment time. |
| Mark delivered | DELIVERED | Save delivery time; Ravi becomes AVAILABLE. |

Payment can succeed earlier in the workflow too. It does not itself advance the order status.

## 7. Order status and payment status are different

**Order status** describes food preparation/delivery:

```text
PLACED → ACCEPTED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED
```

An order can move to CANCELLED only from PLACED or ACCEPTED in the current service.

**Payment status** describes payment:

| Status | Meaning |
|---|---|
| PENDING | Payment has not succeeded yet. |
| SUCCESS | The demonstration records successful payment. |
| FAILED | The schema permits a failed payment record. The current interface has no button for setting this state. |

For ONLINE orders, successful payment is required before pickup. For CASH orders, pickup permits a pending payment, but delivery completion still requires successful payment matching the total.

The app records simulated payments. It does not collect money through a payment gateway. Refunds are outside scope, so cancellation is not a refund operation.

## 8. Why do we save the agreed price?

MENU_ITEM.current_price is today's menu price. ORDER_ITEM.agreed_unit_price is the price captured for a particular order.

If Veg Rice rises from INR 120 to INR 140 tomorrow, Asha's existing order still costs INR 350. Its saved agreed price remains 120.

The calculation is:

```text
line cost = quantity × agreed_unit_price
subtotal = sum of the order's line costs
amount due = subtotal + saved delivery_fee
```

The base tables do not store separate line totals, subtotals or order totals. Queries calculate them. PAYMENT.payment_amount stores the payment fact and must match the calculated amount when completing delivery.

Destination fields belong to the order so that its historical destination stays available.

## 9. Keys and constraints

| Term | Simple meaning | Project example |
|---|---|---|
| Primary key (PK) | Uniquely identifies a row; cannot be null. | APP_USER.user_id |
| Foreign key (FK) | References a row in another table. | MENU_ITEM.restaurant_id |
| Composite primary key | Several columns identify a row together. | ORDER_ITEM(order_id, item_id) |
| UNIQUE | Prevents repeated values. | APP_USER.email; PAYMENT.order_id |
| NOT NULL | Requires a value. | full_name and current_price |
| CHECK | Restricts allowed values. | Quantity must be a positive integer. |
| DEFAULT | Supplies a value when omitted from an insert. | A new order defaults to PLACED. |

The DDL also checks permitted statuses, prices, fees and timestamp consistency. A successful payment must have `paid_at`. A completed delivery must have a pickup time and cannot finish before pickup.

Phone numbers and postal codes are text because leading zeroes and symbols matter. Money uses NUMBER with two decimal places. Event times use TIMESTAMP. Menu availability uses 1 for available and 0 for unavailable.

### Which rules need Java rather than an ordinary foreign key?

A valid item FK only proves that an item exists. It does not prove that the item belongs to the order's restaurant.

The service therefore enforces rules such as one restaurant per order, at least one order item, legal status changes, account roles, available partners and payment consistency.

**Important distinction:** the provided constraints protect database rows even during direct SQL. Service-only rules apply when you use the service; an administrator's manual SQL can bypass them.

## 10. Normalization: why nine tables?

Without separate tables, every order line might repeat the customer's name/email and the restaurant's address. A changed email could then require updates in many places and leave conflicting copies.

Normalization organizes facts around what they describe:

- Customer/person details belong to APP_USER and its role tables.
- Restaurant details belong to RESTAURANT.
- Current dish details belong to MENU_ITEM.
- Order-specific quantity and agreed price belong to ORDER_ITEM.

**1NF:** each field holds an atomic value. Several ordered dishes become separate line rows rather than a comma-separated field.

**2NF:** attributes depend on the whole key. Dish names depend on item_id, so they belong to MENU_ITEM. Quantity for an order line depends on the pair `(order_id, item_id)`.

**3NF:** remove violating dependencies through other non-key attributes. An order identifies a restaurant, but the restaurant name/address belongs in RESTAURANT rather than repeating in every order.

Historical agreed prices and destinations are order-specific facts. Keeping them with the order does not duplicate the current menu price or restaurant address.

## 11. How the browser connects to Oracle

```text
Browser interface
       ↓ HTTP request
WebServer.java
       ↓ service method call
FoodService.java
       ↓ Oracle JDBC driver
Oracle Database: FOOD_PROJECT
```

The browser uses HTML for structure, CSS for appearance and JavaScript for interactions. It sends requests to the Java server running on your computer at port 8788.

WebServer.java serves the webpage and translates requests into service calls. FoodService.java validates business rules and executes SQL. JDBC is the Java Database Connectivity API that lets Java communicate with Oracle.

Oracle connection settings stay in a private local properties file. The webpage does not receive the database password.

### What happens when you click Place order?

1. The browser sends IDs, quantities, destination and payment method.
2. Java checks the cart, address, availability and restaurant ownership.
3. Java reads prices from Oracle rather than accepting a price supplied by the browser.
4. A sequence generates the order ID.
5. Java inserts the order, item rows and pending payment.
6. Java commits if all inserts succeed, or rolls back if one fails.
7. The browser retrieves current records and displays the saved order.

The browser also calculates a preview total. The server calculates the stored payment amount from database prices and sets the fee for new browser orders to INR 30.

## 12. DDL, DML and retrieval

| Term | Purpose | Example |
|---|---|---|
| DDL | Define database structures. | CREATE TABLE, CREATE SEQUENCE |
| DML | Change stored records. | INSERT, UPDATE, DELETE |
| Retrieval | Read stored records. | SELECT |

Your Phase 2 app demonstrates SELECT, INSERT and UPDATE. Complete remaining CRUD screens are Phase 3 work. Although the Java service includes account creation, the current browser adapter does not expose an account-creation screen.

CRUD means Create, Read, Update and Delete.

## 13. Transactions, commit and rollback

A transaction groups related changes into one unit.

Checkout needs an order header, its item lines and its payment record. If the last insert fails, retaining only the header would leave an incomplete order.

**COMMIT** saves all successful changes in that transaction. **ROLLBACK** cancels uncommitted changes.

The Java service turns automatic commit off and commits after a complete operation succeeds. On failure it rolls back.

Oracle table-creation commands have different commit behaviour: successful CREATE TABLE statements are not removed by rolling back later DML. That is why a partially run setup must be inspected before rerunning it.

### Why can order IDs skip numbers?

Oracle sequences generate IDs. A rolled-back test can consume a number without retaining an order. The next number need not be consecutive. Gaps are normal and do not mean records are missing.

### Why use parameterized SQL?

PreparedStatement binds entered values separately from the SQL command. For example, an entered address is data rather than part of executable SQL text. This avoids building queries by concatenating user input.

The service also locks selected rows during sensitive operations so concurrent actions do not freely change the same order or menu price while it finalizes a transaction.

## 14. Find your way around the files

| File/folder | Purpose |
|---|---|
| backend/scripts/start.cmd | Compile and launch the local application. |
| frontend/index.html | Page structure, header and checkout form. |
| frontend/style.css | Black-and-white layout and responsive styling. |
| frontend/app.js | Screens, cart controls, request handling and labelled browser demo. |
| backend/WebServer.java | Local HTTP server and browser-to-service adapter. |
| backend/FoodService.java | JDBC queries, transactions and business rules. |
| backend/tests/Phase2Test.java | Automated integration checks. |
| backend/lib/ojdbc6.jar | JDBC driver from the installed Oracle XE. |
| database/setup/02_all_in_one_initial_setup.sql | Initial nine-table creation, initial sample data and checks. |
| database/dml/03_expanded_sample_data_and_sequences.sql | Expanded sample cases and ID sequences. |
| database/queries/02_review_queries.sql | Read-only counts, totals and integrity queries. |
| database/queries/03_view_from_system.sql | Read FOOD_PROJECT tables from the administrator worksheet. |
| submission/ | Submission PPT and supporting ZIP. |

The private connection file is `backend/config/database.properties`. It is excluded from the supporting ZIP.

## 15. Run the project and inspect the database

Double-click **backend/scripts/start.cmd**. Keep its terminal open. Visit **http://127.0.0.1:8788**. If the page opens before the server is ready, refresh it.

If the server is already running, open the URL instead of launching another copy.

The current database is already initialized. Do not run its CREATE TABLE or seed scripts again.

### List the project tables while connected as SYSTEM

```sql
SELECT owner, table_name
FROM all_tables
WHERE owner = 'FOOD_PROJECT'
ORDER BY table_name;
```

### View sample users and menu items

```sql
SELECT * FROM food_project.app_user;
SELECT * FROM food_project.menu_item;
```

### See which role each person has

```sql
SELECT u.user_id, u.full_name,
       CASE WHEN c.user_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS is_customer,
       CASE WHEN p.user_id IS NOT NULL THEN 'YES' ELSE 'NO' END AS is_partner
FROM food_project.app_user u
LEFT JOIN food_project.customer c ON c.user_id = u.user_id
LEFT JOIN food_project.delivery_partner p ON p.user_id = u.user_id
ORDER BY u.user_id;
```

### Calculate saved order totals

```sql
SELECT o.order_id, o.order_status,
       SUM(i.quantity * i.agreed_unit_price) AS subtotal,
       o.delivery_fee,
       SUM(i.quantity * i.agreed_unit_price) + o.delivery_fee AS amount_due
FROM food_project.food_order o
JOIN food_project.order_item i ON i.order_id = o.order_id
GROUP BY o.order_id, o.order_status, o.delivery_fee
ORDER BY o.order_id;
```

Use **Ctrl+Enter** for one selected query and its result grid. Use **F5** for a complete script and read Script Output. When connected directly as FOOD_PROJECT, you can omit the `food_project.` prefixes.

## 16. What has actually been verified?

The fresh schema's initial setup and expanded sample data executed successfully. Before the browser demonstration there were 4 users, 3 customers, 2 partners, 2 restaurants, 6 menu items and 4 orders.

The browser demonstration added order 2005, bringing the observed snapshot to 5 orders, 9 order lines and 5 payments. These counts can change as you use the application.

**46 JDBC checks passed:** 37 behaviour/constraint checks and 9 checks confirming cleanup preserved the original row count of each table. They covered invalid carts, rollback, historical prices, constraints, partner availability and complete cash/online delivery workflows.

The browser itself demonstrated retrieval and a successful checkout into Oracle. The tests verified the complete service workflows; that does not mean every later button action was manually repeated on the retained demonstration order.

See VERIFICATION.md for the recorded scope of checks.

## 17. What belongs to Phase 2 and Phase 3?

| Phase 2 requirement | Your evidence |
|---|---|
| DDL | Nine created tables and their constraints. |
| DML sample data | Meaningful records across every table. |
| Working front end | Customer ordering, Kitchen and Deliveries views. |
| Core business logic | Validation, transactions and workflow rules in Java. |
| Initial ODBC/JDBC connection | Actual retrieval, insertion and updates using Oracle JDBC. |
| Phase 2 PPT | The deck in output/phase2, with schema and implementation evidence. |

Phase 3 can complete remaining account/restaurant CRUD screens, safe deletion workflows, broader testing, the final report and final demonstration.

Authentication, real payment gateways, coupons, refunds and GPS tracking are outside your current stated scope. Avoid claiming those features exist.

## 18. A simple presentation script

“Our Food Delivery System connects customers, restaurants and delivery partners. We implemented the nine relations from Phase 1 in Oracle and populated them with sample data.

“The browser interface lets a customer browse a restaurant, add dishes and place an order. A local Java server connects the interface to Oracle through JDBC.

“The service checks business rules and saves an order, its items and its payment in one transaction. We capture agreed prices so later menu changes do not change historical totals.

“The Kitchen and Deliveries views demonstrate preparation, partner assignment, pickup and delivery. The project uses demo role selection and simulated payments.”

Then demonstrate a small order and show its saved database records.

## 19. Questions you should be able to answer

**Why nine tables?** Each table stores a distinct kind of fact, reducing repetition while preserving relationships.

**Why APP_USER plus two role tables?** Shared profile details stay in one place. A person can have either or both roles.

**Why ORDER_ITEM?** It resolves the many-to-many relationship between orders and dishes and stores quantity/agreed price.

**Why is PAYMENT.order_id unique?** Our scope permits at most one payment record per order.

**Why does DELIVERY use order_id as its key?** Our scope permits at most one delivery row per order.

**Why store agreed_unit_price?** An old order must retain the price agreed when it was placed.

**Where is the order total stored?** It is calculated from saved order lines and delivery fee. The payment record separately stores its amount.

**What if checkout partly fails?** The service rolls back the entire checkout transaction.

**How do you prove connectivity?** Place an order in Oracle connected mode and retrieve its rows in SQL Developer.

**Is Meera a customer or driver?** Both. The order and assignment references determine which role she is using.

**Does changing Demo customer log in as that person?** No. It selects a record in this classroom prototype.

## 20. Quick troubleshooting

| What you see | What it means / what to do |
|---|---|
| ORA-20001 during setup | The script detected SYS/SYSTEM. Connect as the project owner for creation. |
| ORA-20002 during setup | Project tables already exist. Inspect them instead of rerunning setup. |
| No rows from USER_TABLES | You may be connected to the wrong account. Check SELECT USER FROM dual. |
| Browser cannot reach the app | Start the local server and keep its terminal open. |
| Address already in use in the launcher | Another server may already occupy port 8788. Try the existing app URL first. |
| Browser demo badge | Oracle was not connected. Check the local configuration/database and restart the server. |
| Order not in My orders | Check which demo customer is selected and refresh database records. |
| Cannot choose another restaurant | Remove existing cart items or complete the current order first. |
| No available partner | Existing assignments may have made partners BUSY. Inspect deliveries and complete valid workflows. |
| Pickup disabled for an online order | Record successful simulated payment first. |
| Delivery disabled | Record pickup and successful payment first. |
| Skipped order IDs | Sequences can consume values during rolled-back operations. This is normal. |

Your goal for the review is to explain what each record represents, demonstrate how the records connect, and show that the app saves valid changes to Oracle.
