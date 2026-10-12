# Verification performed on 12 October 2026

Fresh schema: FOOD_PROJECT on local Oracle XE.

- Nine CREATE TABLE statements executed successfully.
- Initial sample data and expanded sample data committed successfully.
- Before the browser demo: 4 users, 3 customers, 2 delivery partners, 2 restaurants, 6 menu items, 4 orders, 7 order lines, 4 payments and 2 deliveries.
- Read-only integrity queries returned no mixed-restaurant orders, accounts without roles, orders without items or mismatched successful payment amounts.
- 46 JDBC checks passed using the same FoodService and Phase2Test sources copied into this project. 37 checks cover operations, constraints and business rules; 9 confirm cleanup preserves each original table's row count.
- Service tests cover complete cash and online delivery workflows, rollback, unavailable items, invalid quantities, partner availability and historical price preservation.
- Java HTTP adapter compiled with installed JDK 26.0.2.1. Frontend JavaScript passed Node syntax checking.
- Live browser connected through the local adapter to FOOD_PROJECT. Created retained order 2005: two Veg Rice at ₹120 and one Juice at ₹80, fee ₹30, total ₹350. Its order history and kitchen entry displayed actual database rows.
- Desktop evidence captured at 1200 × 800 in a separate QA tab. User-facing app also displayed its narrow responsive layout in Codex.
- Browser UI actions for every later delivery transition have not been repeated on the retained order. Those transitions passed the JDBC service tests.

This verification applies to the local project. There is no hosted Oracle deployment. GitHub source hosting does not deploy the local Java server or Oracle database.
