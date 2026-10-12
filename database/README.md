# Database commands

The project has nine tables. Their columns, keys, cardinalities and business rules are described in [the relational schema](../docs/relations/RELATIONAL_SCHEMA.md).

## 1. Create an account

In SQL Developer, connect as the administrator to the intended database. Open `setup/01_create_account.example.sql`, replace its placeholder password locally, then press F5. It creates FOOD_PROJECT with a USERS quota and the permissions needed for tables/sequences.

That script targets the local XE database used for this project. On a multitenant Oracle installation, create the local account in the intended pluggable database. Use an appropriate existing tablespace if USERS is unavailable.

Create a new SQL Developer connection as FOOD_PROJECT with your chosen password and the same database host, port and SID/service. Confirm:

```sql
SELECT USER FROM dual;
```

## 2. Create the nine tables

Open `ddl/01_create_tables.sql` in the FOOD_PROJECT connection and press F5.

Creation order: APP_USER, CUSTOMER, DELIVERY_PARTNER, RESTAURANT, MENU_ITEM, FOOD_ORDER, ORDER_ITEM, PAYMENT, DELIVERY.

## 3. Insert sample data and create sequences

Run `dml/02_initial_sample_data.sql`, followed by `dml/03_expanded_sample_data_and_sequences.sql`, using F5. Run each only once after its previous step succeeds.

The fixtures include a person with both roles, two restaurants, six menu items and four orders in different states. The expanded script creates the account, order and payment ID sequences used by Java.

## 4. Verify

Run `queries/01_check_tables.sql`, then `queries/02_review_queries.sql`.

Expected initial order totals: 1001 = 350, 1002 = 180, 1003 = 180 and 1004 = 160, in INR. Integrity queries should find no mixed-restaurant orders, missing order lines, users without roles or mismatched successful payments.

## Alternative initial setup

`setup/02_all_in_one_initial_setup.sql` combines the initial DDL, initial seed and initial checks. Run it instead of steps 2 and the first seed file, then run the expanded DML script. It intentionally stops under SYS/SYSTEM or if project tables exist.

None of the scripts drop existing tables. Successful Oracle DDL persists even if later statements fail, so inspect partial setup before rerunning.

## Useful read-only queries

```sql
SELECT table_name FROM user_tables ORDER BY table_name;
SELECT * FROM app_user;
SELECT * FROM menu_item;
SELECT * FROM food_order;
```

When using the existing SYSTEM connection to inspect the project, run `queries/03_view_from_system.sql`, which qualifies table names with FOOD_PROJECT.

Recorded setup logs are in `evidence/database/`. They reflect the original local run; your row counts will change as you use the application.
