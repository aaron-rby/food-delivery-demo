# Food Delivery System: EER mapping and final relations

Notation: PK = primary key; FK = foreign key; UQ = unique candidate key. Names below are logical SQL-style names; no DDL is being executed in Phase 1. Entity USER is named APP_USER in the relational schema to avoid a common SQL reserved word.

## Final nine relations

```text
APP_USER(
  user_id PK,
  full_name, email UQ NOT NULL, phone
)

CUSTOMER(
  user_id PK FK -> APP_USER.user_id,
  customer_since
)

DELIVERY_PARTNER(
  user_id PK FK -> APP_USER.user_id,
  transport_mode, availability_status
)

RESTAURANT(
  restaurant_id PK,
  restaurant_name, address_line, city, postal_code, contact_phone
)

MENU_ITEM(
  item_id PK,
  restaurant_id FK -> RESTAURANT.restaurant_id,
  item_name, category, current_price, is_available
)

FOOD_ORDER(
  order_id PK,
  customer_id FK -> CUSTOMER.user_id,
  restaurant_id FK -> RESTAURANT.restaurant_id,
  ordered_at, order_status,
  dropoff_line, dropoff_city, dropoff_postal_code, delivery_fee
)

ORDER_ITEM(
  order_id PK-part FK -> FOOD_ORDER.order_id,
  item_id PK-part FK -> MENU_ITEM.item_id,
  quantity, agreed_unit_price,
  PK(order_id, item_id)
)

PAYMENT(
  payment_id PK,
  order_id UQ NOT NULL FK -> FOOD_ORDER.order_id,
  payment_method, payment_amount, payment_status, paid_at
)

DELIVERY(
  order_id PK FK -> FOOD_ORDER.order_id,
  partner_id FK -> DELIVERY_PARTNER.user_id,
  assigned_at, picked_up_at, delivered_at
)
```

All PKs are mandatory. All FKs above are mandatory within an existing row; optional payment and delivery are represented by the **absence of a row**, not by a null order reference. Core names, addresses, statuses, timestamps at creation, prices, quantities, and amount are mandatory. Phone fields can be optional. `paid_at`, `picked_up_at`, and `delivered_at` are nullable until the corresponding event. `customer_since` is mandatory in CUSTOMER.

## Relationships and participation

The min/max labels refer to how many relationship occurrences one entity instance participates in.

| Relationship | First entity participation | Second entity participation | Mapping |
|---|---|---|---|
| Customer places FoodOrder | Customer: (0,N) | FoodOrder: (1,1) | FOOD_ORDER.customer_id |
| Restaurant receives FoodOrder | Restaurant: (0,N) | FoodOrder: (1,1) | FOOD_ORDER.restaurant_id |
| Restaurant offers MenuItem | Restaurant: (0,N) | MenuItem: (1,1) | MENU_ITEM.restaurant_id |
| FoodOrder contains OrderItem | FoodOrder: (1,N) | OrderItem: (1,1) | ORDER_ITEM.order_id, part of PK |
| MenuItem appears in OrderItem | MenuItem: (0,N) | OrderItem: (1,1) | ORDER_ITEM.item_id, part of PK |
| FoodOrder has Payment | FoodOrder: (0,1) | Payment: (1,1) | PAYMENT.order_id, NOT NULL + UNIQUE |
| FoodOrder has Delivery | FoodOrder: (0,1) | Delivery: (1,1) | DELIVERY.order_id, shared PK/FK |
| DeliveryPartner handles Delivery | DeliveryPartner: (0,N) | Delivery: (1,1) | DELIVERY.partner_id |

USER -> CUSTOMER / DELIVERY_PARTNER is a **total, overlapping specialization**. Store common name/email/phone only in APP_USER. Subtype rows inherit the same identifier. A user with both roles has one APP_USER row and one row in each subtype. Total specialization means every APP_USER row must have at least one subtype row.

The updated lecture-style EER has **seven ordinary relationship diamonds**, in addition to specialization. Its M:N CONTAINS relationship connects FOOD_ORDER (1,N) and MENU_ITEM (0,N), with quantity and agreed_unit_price as relationship attributes. Mapping this diamond creates ORDER_ITEM with PK(order_id,item_id). The table above describes the **eight links after that mapping**, where CONTAINS is resolved into two links through ORDER_ITEM. Do not create a second independent M:N table.

The diagram has two pages: the full EER with attributes and an attribute reference. CUSTOMER and DELIVERY_PARTNER inherit USER attributes; DELIVERY is identified through its one-to-one link to FOOD_ORDER. Composite address attributes map to their listed component columns, while the derived amount_due attribute is calculated and omitted from stored columns. The mapping is explained in `EER_TO_RELATIONS_STEP_BY_STEP.md`; executable Oracle table definitions are supplied in `Oracle/01_create_tables.sql`.

## Attribute dictionary and later constraints

| Attribute group | Proposed type family | Rule |
|---|---|---|
| IDs | Integer/NUMBER | Unique key, positive generated values |
| Names and address lines | VARCHAR/VARCHAR2 | Nonempty; choose lengths at DDL time |
| Email | VARCHAR/VARCHAR2 | Unique, required; normalize case in application |
| Phone, postal code | VARCHAR/VARCHAR2 | Preserve leading zeroes and symbols |
| Prices, fees, amounts | DECIMAL/NUMBER with 2 decimal places | current_price and agreed_unit_price > 0; delivery_fee >= 0; payment_amount > 0 |
| Quantity | Integer/NUMBER | >= 1 and integral |
| Event times | TIMESTAMP | Creation times required; later event times optional |
| is_available | Boolean-equivalent | For Oracle lab compatibility, can use a 0/1 column with CHECK |
| transport_mode | VARCHAR/VARCHAR2 | WALK, BICYCLE, MOTORBIKE, CAR |
| availability_status | VARCHAR/VARCHAR2 | AVAILABLE, BUSY, OFFLINE |
| order_status | VARCHAR/VARCHAR2 | PLACED, ACCEPTED, PREPARING, READY, OUT_FOR_DELIVERY, DELIVERED, CANCELLED |
| payment_method | VARCHAR/VARCHAR2 | CASH, ONLINE |
| payment_status | VARCHAR/VARCHAR2 | PENDING, SUCCESS, FAILED |

Use bound parameters and the DB driver's native date/number types later. The exact type spelling depends on the selected DBMS.

## Rules that ordinary PK/FK constraints do not enforce

1. **Single restaurant per order:** both item and order FKs can be valid while their restaurants differ. Compare MENU_ITEM.restaurant_id to FOOD_ORDER.restaurant_id when inserting/updating lines. Keep item ownership fixed once referenced; do not change an order's restaurant after its lines exist. Enforce through service transactions or a DB trigger.
2. **At least one order item:** an FK from child to parent does not require a parent to have a child. Insert the order and one or more lines in one transaction; prevent deletion of the last line from a retained placed order.
3. **Total USER specialization:** separate subtype FKs do not guarantee that APP_USER has a subtype. Insert account and its role(s) in one transaction; disallow deleting its last subtype without removing the unreferenced account. Overlap needs no exclusivity constraint.
4. **Successful payment matches order amount:** compare amount against the derived total at success. Lock or otherwise protect finalized item rows and delivery fee to prevent later mismatch. No partial payments in this scope.
5. **Workflow consistency:** check valid transitions, assignment before pickup, and successful payment plus a delivery timestamp when marking delivered. Online payment success is required before dispatch; cash may be collected at delivery.
6. **Historical integrity:** forbid changing captured destination/prices after placement, and preserve referenced customers, restaurants, and menu rows. Menu availability can change without altering an old order.

## Derived values and example

Do not store `line_total`, `subtotal`, or `order_total` in the normalized base tables.

```text
line_total = quantity * agreed_unit_price
subtotal = sum of line_total for the order
amount_due = subtotal + delivery_fee
```

Example: order 1001 has item 11 (2 portions at 120.00) and item 12 (1 portion at 80.00), with fee 30.00. Its total is `2*120 + 1*80 + 30 = 350.00`. If item 11's current menu price later becomes 140.00, this order remains 350.00 because its agreed price is still 120.00.

PAYMENT.payment_amount stores the payment fact for that order, not the current menu total. At success it must equal the amount due. The total is calculated from the saved agreed prices, not MENU_ITEM.current_price.
