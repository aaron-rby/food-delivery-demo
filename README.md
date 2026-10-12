# Savour

The Add user form offers Customer, Delivery partner or Both. Both stores one APP_USER linked to CUSTOMER and DELIVERY_PARTNER, preserving the overlapping EER specialization. Transport is required for delivery roles.

Admin menu management now filters dishes using a restaurant dropdown. Use **Add restaurant** to create a restaurant and **Add food** to populate its menu. Both actions use JDBC transactions in the local app. Run `database/dml/04_more_food_and_customers.sql` after the expanded seed for six extra fictional customers and ten dishes; it preserves existing rows when run again.

The header selects Customer, Partners or Admin. Customer view contains browsing and personal orders; Partners contains only the selected partner's assignments; Admin handles menus, preparation and assignment. Customer and Partners views have buttons to add named profiles or add that role to an existing person. Oracle stores profiles in APP_USER and the matching subtype table. The role selector is a demonstration without authentication; it does not enforce access permissions.

BACSE202 Database Systems course project. A simple black-and-white browser application backed by Java and Oracle JDBC.

## Shareable browser demo

[Open the public demo](https://aaron-rby.github.io/food-delivery-demo/)

Friends can try the interface without installing Java or Oracle. This separate public demo uses fictional records saved only in each visitor's browser. It has no shared database or real payments. This full project repository remains private.

Customers browse restaurants, add dishes and place orders. Kitchen and delivery views demonstrate menu updates, preparation, partner assignment, pickup and delivery. The nine-table schema follows the Phase 1 relational design.

## Project structure

```text
frontend/             HTML, CSS and JavaScript
backend/              WebServer.java and FoodService.java
tests/                Oracle integration checks
relations/            Relational schema, normalization and EER diagram
database/
  setup/              Project account and initial setup scripts
  ddl/                CREATE TABLE commands
  dml/                Sample INSERT commands and ID sequences
  queries/            SELECT commands and integrity checks
connectivity/         JDBC setup, compile, run and test commands
config/               Example connection settings (no real password)
scripts/              Windows build, start and test commands
docs/                 Beginner guide, demonstration guide and verification
evidence/             Database logs and browser screenshots
submission/           Phase 2 PowerPoint
lib/                  Instructions for adding your local Oracle driver
```

## Read this first

- [Complete beginner's guide](docs/COMPLETE_PROJECT_GUIDE.md)
- [All relations and keys](relations/RELATIONAL_SCHEMA.md)
- [Database setup commands](database/README.md)
- [JDBC connectivity and application commands](connectivity/README.md)
- [Front-end structure and commands](frontend/README.md)
- [Review demonstration](docs/DEMONSTRATION_GUIDE.md)

## Requirements

JDK 17 or newer, Oracle Database with a project account, and an Oracle JDBC driver suitable for your database/JDK. The recorded local verification used Oracle XE 11.2, JDK 26.0.2.1 and the locally installed ojdbc6.jar.

## Run locally

1. Clone this repository and open its root directory.
2. Create your project account and database tables using [database/README.md](database/README.md). Use an empty project schema. Do not rerun creation/seed scripts in an initialized schema.
3. Copy your Oracle JDBC driver to `lib/ojdbc6.jar`. It is intentionally not committed.
4. Copy `config/database.example.properties` to `config/database.properties` and enter your own connection settings.
5. Run `scripts/start.cmd`, then open http://127.0.0.1:8788.

```powershell
Copy-Item config/database.example.properties config/database.properties
# Edit config/database.properties locally before starting.
scripts/build.cmd
scripts/start.cmd
```

The `Oracle connected` badge confirms live database mode. `Browser demo` uses sample browser storage and does not prove JDBC connectivity.

## Build and test

```powershell
javac -d build backend/FoodService.java backend/WebServer.java tests/Phase2Test.java
node --check frontend/app.js
java -cp "build;lib/ojdbc6.jar" Phase2Test config/database.properties
```

Node is optional for the JavaScript syntax check; it is not needed to run the app. The backend compiles using standard JDK libraries. The JDBC driver is required at runtime.

The recorded service verification passed 46 checks, including 9 cleanup checks. Tests use temporary records and restore original row counts. Sequence gaps after rollback are normal. See [verification](docs/VERIFICATION.md) for scope and evidence.

## Scope

The interface uses demo customer selection and operator views, with simulated payment recording. It does not provide authenticated customer/driver accounts, real payment processing, refunds, coupons or GPS tracking. Remaining CRUD screens and broader final documentation are Phase 3 work.

GitHub stores this project's source and setup instructions. The Java backend and Oracle database run locally; this repository is not a hosted live Oracle service. Real passwords and local configuration are excluded.

The code reuses the Java service and tests from the earlier local course-project implementation. The active browser layout was rebuilt as requested with black-and-white styling and written food descriptions.
