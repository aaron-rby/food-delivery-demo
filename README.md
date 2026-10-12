# Savour DELIVERY

**BACSE202 · Database Systems · Phase 2**

A food-delivery project using **Java, JDBC, Oracle SQL and HTML/CSS/JavaScript**.

**[Open the website](https://aaron-rby.github.io/savour-delivery/)** · [Project guide](docs/COMPLETE_PROJECT_GUIDE.md) · [Database setup](database/README.md)

## Features

- **Customer:** browse restaurants, read food descriptions, build a cart, place orders and view personal order history.
- **Partners:** view assigned deliveries, record pickup, simulated payment and completion.
- **Admin:** manage menus using a restaurant dropdown, add restaurants and dishes, prepare orders and assign partners. Red × buttons remove unused customers, partners, restaurants and food; order/delivery history stays protected.
- **Add user:** choose Customer, Delivery partner or Both. Both roles share one user ID.

The website now uses a shared Java/Oracle backend through a temporary HTTPS tunnel. Your computer, Oracle, Java server and tunnel must stay running. Views refresh every five seconds when no form is being edited. The site retries an offline backend and disables saving until reconnection. Previous browser-only orders are not imported.

**Classroom demo:** no login or enforced role permissions; anyone can choose Admin. Use fictional information. Payments are simulated. The complete project source and public website are now in this single public repository.

## Folder structure

```text
backend/     Java source, tests, run scripts, example config and driver instructions
database/    Oracle DDL, sample data and review queries
docs/        Guides, relations/EER, normalization, evidence and Phase 2 PPT
frontend/    Local interface; site/ contains the hosted public website
BACSE202_Course_Project_Overview.pdf
Food-Delivery-System.pdf
README.md
```

## Java backend

| File | Responsibility |
|---|---|
| [WebServer.java](backend/WebServer.java) | Uses the JDK HTTP server to serve the frontend and expose GET/POST `/api`. Parses form requests and returns JSON. Allows the configured GitHub Pages origin to access the shared API. |
| [FoodService.java](backend/FoodService.java) | Opens Oracle with `DriverManager.getConnection`, binds SQL values with `PreparedStatement`, validates operations, and commits or rolls back transactions. |
| [Phase2Test.java](backend/tests/Phase2Test.java) | Checks Oracle constraints, accounts/roles, checkout, historical prices, preparation, payment, assignment and delivery; removes its temporary records. |

```text
Browser → WebServer.java → FoodService.java → JDBC → Oracle FOOD_PROJECT
```

Java handles profile creation, restaurant/dish creation, menu updates, checkout, preparation, partner assignment, pickup, simulated payment, completion and protected removals. Checkout captures agreed prices and saves the order, lines and pending payment in one transaction. Row locks protect workflow updates. Oracle credentials stay on the server.

The implementation uses standard JDK libraries and JDBC, with no Java framework. The current server serializes API operations through one Oracle connection. For a larger shared service, connection pooling and separate request transactions would be a later improvement.

### Compile and run Java

Requires **JDK 17+**, Oracle Database and a compatible Oracle JDBC driver. Run these commands from the repository root:

1. Follow [database setup](database/README.md) in your project schema, not SYS/SYSTEM.
2. Put the JDBC driver at `backend/lib/ojdbc6.jar`.
3. Copy the example configuration and fill in your own local credentials:

```powershell
Copy-Item backend/config/database.example.properties backend/config/database.properties
New-Item -ItemType Directory -Force build
javac -d build backend/FoodService.java backend/WebServer.java backend/tests/Phase2Test.java
java -cp "build;backend/lib/ojdbc6.jar" WebServer backend/config/database.properties
```

Open **http://127.0.0.1:8788** and check the Oracle connection badge. The Windows shortcut is `backend/scripts/start.cmd`. Real configuration and JARs are ignored by Git.

```powershell
java -cp "build;backend/lib/ojdbc6.jar" Phase2Test backend/config/database.properties
node --check frontend/app.js
```

The hosted files are in `frontend/site/`. GitHub Actions publishes that folder automatically. Update `frontend/site/backend-config.js` when the HTTPS tunnel URL changes.

[JDBC details](docs/connectivity/README.md) · [Shared-backend/tunnel commands](docs/connectivity/SHARED_BACKEND.md)

## Relational schema — 9 normalized tables

The normalization worksheet demonstrates **3NF and BCNF under the documented functional dependencies**. Oracle enforces keys and CHECK constraints; Java transactions enforce the cross-table business rules.

| Table | Primary key | Foreign keys | Notable database constraints |
|---|---|---|---|
| `APP_USER` | `user_id` | — | Required name; unique, lowercase email; optional phone |
| `CUSTOMER` | `user_id` | `user_id` → `APP_USER` | Shared user ID; required `customer_since` |
| `DELIVERY_PARTNER` | `user_id` | `user_id` → `APP_USER` | Transport: WALK/BICYCLE/MOTORBIKE/CAR; status: AVAILABLE/BUSY/OFFLINE |
| `RESTAURANT` | `restaurant_id` | — | Required name, address, city and postal code; optional phone |
| `MENU_ITEM` | `item_id` | `restaurant_id` → `RESTAURANT` | Positive current price; availability 0/1 |
| `FOOD_ORDER` | `order_id` | `customer_id` → `CUSTOMER`; `restaurant_id` → `RESTAURANT` | Allowed statuses; nonnegative delivery fee; required destination and order time |
| `ORDER_ITEM` | (`order_id`, `item_id`) | `order_id` → `FOOD_ORDER`; `item_id` → `MENU_ITEM` | Positive integer quantity; positive captured price; one row per dish/order |
| `PAYMENT` | `payment_id` | Unique `order_id` → `FOOD_ORDER` | CASH/ONLINE; positive amount; PENDING/SUCCESS/FAILED; success requires timestamp |
| `DELIVERY` | `order_id` | `order_id` → `FOOD_ORDER`; `partner_id` → `DELIVERY_PARTNER` | One delivery/order; pickup ≥ assignment; completion requires pickup and ordered timestamps |

Customer and Delivery Partner are a **total, overlapping specialization** of APP_USER. Every application-created user has at least one role. Admin is an external classroom operator, rather than a stored third subtype. This schema has no reviews or rating fields.

Users, orders and payments use Oracle sequences. Restaurant/food creation currently allocates IDs using table locks; these are not identity columns.

### Key relational invariants

- Every dish in an order belongs to its selected restaurant.
- Checkout creates an order, at least one line and pending payment atomically.
- Captured `agreed_unit_price` preserves old order totals after menu edits.
- Total is derived: `SUM(quantity × agreed_unit_price) + delivery_fee`.
- Workflow: PLACED → ACCEPTED → PREPARING → READY → OUT_FOR_DELIVERY → DELIVERED. Cancellation is allowed while PLACED or ACCEPTED.
- Only an available partner can take a ready order. Assignment marks them busy; completion releases them.
- Online payment must succeed before pickup; delivery completion requires successful payment matching the total.
- Removing one user role keeps their other role. Referenced order/delivery history is protected.

Java enforces these cross-table rules; direct SQL must also respect them. [Relations and keys](docs/relations/RELATIONAL_SCHEMA.md) · [EER diagram](docs/relations/Food_Delivery_EER.drawio) · [Normalization](docs/relations/NORMALIZATION_WORKSHEET.md)

## Database commands

Follow `database/README.md` and run the DDL and seed scripts in order. After the expanded seed, run `database/dml/04_more_food_and_customers.sql` for six additional customers and ten dishes. Do not rerun initial creation scripts against an initialized schema.

## Verification and submission

The service suite previously passed 55 Oracle checks. Additional rollback-only tests verified the corrected existing-partner → Both case and protected removals. HTTPS tests verified concurrent profile creation, distinct IDs and visibility to independent clients; disposable verification profiles were removed. GitHub Actions compiles Java and checks JavaScript syntax; it does not run Oracle integration tests.

[Demonstration](docs/DEMONSTRATION_GUIDE.md) · [Verification history](docs/VERIFICATION.md) · [Phase 2 PPT](docs/submission/Food_Delivery_System_Phase2.pptx)

Original presentation/screenshots predate the newest interface and should be refreshed before final submission. Authentication, real payments, refunds and GPS tracking remain outside the current scope.

## Preserved project contents

Both previous repositories and their Git histories were merged without dropping source files. [Preservation record](docs/repository/CONSOLIDATION.md) · [File manifest and hashes](docs/repository/MERGE_MANIFEST.json) · [Hosted website source](frontend/site/)
