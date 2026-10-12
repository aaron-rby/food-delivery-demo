# Food Delivery System: EER to relational schema, step by step

Use the first page of `Food_Delivery_EER.drawio`, **1 Full EER with attributes**. It now includes attributes and relationships on the same canvas. This guide follows your M2_2 ER-to-relational mapping lecture and M2_3 EER specialization lecture.

**Mapping and normalization are separate operations.** Mapping converts the EER's entities, attributes, and relationships into relations. Normalization then checks those relations against their functional dependencies. Here the mapped schema already satisfies 3NF under the stated rules; the separate normalization worksheet demonstrates the reasoning.

Notation: PK = primary key; FK = foreign key; UQ = UNIQUE and NOT NULL when used as a candidate key. A key containing two attributes is composite. One conceptual entity need not correspond to one final table: specialization and M:N relationship mapping also create relations.

## Step 1: Convert the ordinary entities and simple attributes

Start with the entity rectangles that have independent identifiers. Put their simple stored attributes into relations. The identifier becomes the PK. USER is named APP_USER for SQL.

```text
APP_USER(user_id PK, full_name, email UQ, phone)
RESTAURANT(restaurant_id PK, restaurant_name, contact_phone)
MENU_ITEM(item_id PK, item_name, category, current_price, is_available)
FOOD_ORDER(order_id PK, ordered_at, order_status, delivery_fee)
PAYMENT(payment_id PK, payment_method, payment_amount, payment_status, paid_at)
```

These are intermediate definitions: address columns and relationship FKs are added in later steps. Email is an alternate candidate key, not a second primary key. A phone number is one optional string; we have not assumed a multivalued phone collection.

## Step 2: Flatten composite attributes; omit derived stored columns

RESTAURANT.address has components address_line, city, and postal_code. Store those components; do not also create an extra address column with the same information.

FOOD_ORDER.dropoff_address has components dropoff_line, dropoff_city, and dropoff_postal_code. Store these on the order because they record its destination at placement.

```text
RESTAURANT += address_line, city, postal_code
FOOD_ORDER += dropoff_line, dropoff_city, dropoff_postal_code
```

The dashed amount_due oval is derived:

```text
amount_due = SUM(quantity * agreed_unit_price) + delivery_fee
```

It becomes a query calculation, not a base-table column. PAYMENT.payment_amount is different: it records the actual payment fact and remains stored.

## Step 3: Map total, overlapping specialization

USER is the superclass. CUSTOMER and DELIVERY_PARTNER are subclasses. Use one superclass relation and one relation per subclass; this preserves overlap without duplicating common details.

```text
APP_USER(user_id PK, full_name, email UQ, phone)
CUSTOMER(user_id PK/FK -> APP_USER.user_id, customer_since)
DELIVERY_PARTNER(user_id PK/FK -> APP_USER.user_id,
                 transport_mode, availability_status)
```

Do not generate a separate ID for each subtype. A user with both roles has the same user_id in all three tables.

Example:

| Table | Illustrative row |
|---|---|
| APP_USER | (1, Asha Rao, asha@example.com, 9000000001) |
| CUSTOMER | (1, 2026-10-04 10:00:00) |
| DELIVERY_PARTNER | (1, MOTORBIKE, AVAILABLE) |

This is valid because the specialization is overlapping. Total specialization means every APP_USER must belong to at least one subtype; the two FKs alone cannot enforce that requirement. Account creation must insert the account and at least one role in the same transaction.

## Step 4: Map the 1:N relationships

Rule: copy the PK from the one side into the relation on the many side as an FK. A minimum of zero on the parent side does not make the child's FK nullable when each child must have exactly one parent.

| EER relationship | One side | Many side | Result |
|---|---|---|---|
| Customer PLACES FoodOrder | CUSTOMER | FOOD_ORDER | Add customer_id -> CUSTOMER.user_id |
| Restaurant RECEIVES FoodOrder | RESTAURANT | FOOD_ORDER | Add restaurant_id -> RESTAURANT.restaurant_id |
| Restaurant OFFERS MenuItem | RESTAURANT | MENU_ITEM | Add restaurant_id -> RESTAURANT.restaurant_id |
| DeliveryPartner HANDLES Delivery | DELIVERY_PARTNER | DELIVERY | Add partner_id -> DELIVERY_PARTNER.user_id when DELIVERY is created in step 6 |

Now:

```text
MENU_ITEM(item_id PK, restaurant_id FK, item_name, category,
          current_price, is_available)

FOOD_ORDER(order_id PK, customer_id FK, restaurant_id FK,
           ordered_at, order_status, dropoff_line, dropoff_city,
           dropoff_postal_code, delivery_fee)
```

Both FKs in FOOD_ORDER and the restaurant FK in MENU_ITEM are NOT NULL. A customer or restaurant can exist with no orders, but every existing order still references one of each.

## Step 5: Map the M:N CONTAINS relationship

An order contains many menu items; a menu item can appear in many orders. The CONTAINS diamond has quantity and agreed_unit_price attributes. Neither belongs only to FOOD_ORDER or only to MENU_ITEM.

Create a new relation containing both participating keys and the relationship attributes:

```text
ORDER_ITEM(
  order_id FK -> FOOD_ORDER.order_id,
  item_id FK -> MENU_ITEM.item_id,
  quantity,
  agreed_unit_price,
  PK(order_id,item_id)
)
```

One item appears only once in an order. Multiple portions are stored as quantity. Therefore the pair is a valid minimal key; there is no need for an extra line ID under this assumption.

For order 1001, rows `(1001,11,2,120.00)` and `(1001,12,1,80.00)` mean two portions of item 11 and one portion of item 12. A third row with `(1001,11)` would violate the PK: update the quantity instead.

`current_price` remains in MENU_ITEM. `agreed_unit_price` is captured per order-item pair so later menu price changes do not change historical totals.

## Step 6: Map the two 1:1 relationships

### FoodOrder HAS PAYMENT

An order has zero or one payment record; each payment belongs to exactly one order. PAYMENT already has payment_id as its PK.

```text
PAYMENT(payment_id PK,
        order_id FK -> FOOD_ORDER.order_id UQ NOT NULL,
        payment_method, payment_amount, payment_status, paid_at)
```

UNIQUE(order_id) is essential. Without it, the FK would allow many payments for the same order. Optional payment is represented by no PAYMENT row; an existing payment cannot have a null order_id. payment_id and order_id are both candidate keys of PAYMENT.

This scope stores one current payment record, not a history of retries, partial payments, or refunds.

### FoodOrder HAS DELIVERY

An order has zero or one delivery record; each delivery belongs to exactly one order. DELIVERY has no independent delivery_id. Use the order's key as a shared PK/FK:

```text
DELIVERY(order_id PK/FK -> FOOD_ORDER.order_id,
         partner_id FK -> DELIVERY_PARTNER.user_id,
         assigned_at, picked_up_at, delivered_at)
```

The PK makes a second delivery for the same order impossible. partner_id is NOT NULL once the delivery row exists. Before assignment, no delivery row exists. A partner can handle multiple orders, so partner_id is not unique.

The main diagram labels DELIVERY's identifier as `order_id [via Order]` to show that its identity comes from this relationship. No artificial delivery ID or partial key was introduced.

## Step 7: Collect the final nine relations

| # | Relation and attributes | Primary key | Foreign keys / other keys |
|---:|---|---|---|
| 1 | APP_USER(user_id, full_name, email, phone) | user_id | email: UQ, NOT NULL |
| 2 | CUSTOMER(user_id, customer_since) | user_id | user_id -> APP_USER |
| 3 | DELIVERY_PARTNER(user_id, transport_mode, availability_status) | user_id | user_id -> APP_USER |
| 4 | RESTAURANT(restaurant_id, restaurant_name, address_line, city, postal_code, contact_phone) | restaurant_id | None |
| 5 | MENU_ITEM(item_id, restaurant_id, item_name, category, current_price, is_available) | item_id | restaurant_id -> RESTAURANT |
| 6 | FOOD_ORDER(order_id, customer_id, restaurant_id, ordered_at, order_status, dropoff_line, dropoff_city, dropoff_postal_code, delivery_fee) | order_id | customer_id -> CUSTOMER; restaurant_id -> RESTAURANT |
| 7 | ORDER_ITEM(order_id, item_id, quantity, agreed_unit_price) | (order_id,item_id) | order_id -> FOOD_ORDER; item_id -> MENU_ITEM |
| 8 | PAYMENT(payment_id, order_id, payment_method, payment_amount, payment_status, paid_at) | payment_id | order_id -> FOOD_ORDER; order_id: UQ, NOT NULL |
| 9 | DELIVERY(order_id, partner_id, assigned_at, picked_up_at, delivered_at) | order_id | order_id -> FOOD_ORDER; partner_id -> DELIVERY_PARTNER |

Why eight entity rectangles but nine tables? CONTAINS is a relationship in the conceptual model and becomes the additional ORDER_ITEM table in the relational model. The subtype rectangles become their own tables too; they are already included among the eight entities.

## Step 8: Check normalization after mapping

For each relation, identify all candidate keys and FDs. Refer to `NORMALIZATION_WORKSHEET.md` for the full worked 1NF -> 2NF -> 3NF example.

- 1NF: every stored column is a single value; composite addresses become their component columns; item lists become ORDER_ITEM rows.
- 2NF: in ORDER_ITEM, both quantity and agreed_unit_price depend on the whole pair. Item descriptions/current price are in MENU_ITEM, not repeated on ORDER_ITEM.
- 3NF: names, phone numbers, and restaurant descriptions stay in their own relations. FOOD_ORDER stores references and facts about that order, not copies of profile descriptions.

Do not remove agreed_unit_price as redundant: a historical agreed price and the current menu price are different facts. Do not move the captured destination into the customer profile: it is a fact about a particular order.

## Step 9: Use Oracle when you are ready to implement

`Oracle/01_create_tables.sql` creates the nine final relations in dependency order. `02_sample_data.sql` provides one complete delivered order. `03_check_tables.sql` lists tables, constraints, and the calculated total.

The scripts intentionally use explicit numeric IDs, so they do not depend on Oracle identity-column support. No database connection was available to execute them here. Run them in your own Oracle schema and check the output. SQL table creation is the Phase 2 implementation step; the EER and this mapping are your Phase 1 design evidence.

Ordinary PK/FK/CHECK constraints do not enforce every cross-table rule. Your later service code or database procedures must ensure total USER specialization, at least one line per placed order, items from the selected restaurant only, a successful payment matching the total, and valid workflow transitions. The supplied DDL does not claim to enforce these rules by itself.
