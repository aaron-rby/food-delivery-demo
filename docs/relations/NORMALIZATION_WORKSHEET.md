# Food Delivery System: complete normalization to the current nine relations

The starting information covers the complete system: accounts and both roles, restaurants and menus, and orders including payments and deliveries. No entity is introduced after 3NF.

Normalization does not uniquely choose a subtype implementation. The optional customer and partner records are already part of ACCOUNT_UNF. We select their shared-key representation from the existing total, overlapping EER when converting nested records into 1NF. This is a record-mapping choice, not an invented BCNF, 4NF or 5NF violation.

## UNF to 1NF

### Complete starting information

Use three UNF record types. Accounts can exist without orders, restaurants can have empty menus, and items may never have been ordered. A single order-only input would omit those independent master records.

Notation: (group)* is a repeating collection. (group)? is an optional zero-or-one record. Every account has at least one role, and every order has at least one item.
```text
ACCOUNT_UNF(
  user_id, full_name, email, phone,
  CUSTOMER_ROLE(customer_since)?,
  PARTNER_ROLE(transport_mode, availability_status)?
)

CATALOG_UNF(
  restaurant_id, restaurant_name,
  address_line, city, postal_code, contact_phone,
  MENU_ITEMS(item_id, item_name, category,
             current_price, is_available)*
)

ORDER_FORM_UNF(
  order_id, ordered_at, order_status,
  customer_id, customer_name, customer_email,
  customer_phone, customer_since,
  restaurant_id, restaurant_name, restaurant_address_line,
  restaurant_city, restaurant_postal_code, restaurant_phone,
  dropoff_line, dropoff_city, dropoff_postal_code, delivery_fee,
  ITEMS(item_id, item_name, category, current_price,
        is_available, quantity, agreed_unit_price)*,
  PAYMENT_RECORD(payment_id, payment_method, payment_amount,
                 payment_status, paid_at)?,
  DELIVERY_RECORD(partner_id, assigned_at,
                  picked_up_at, delivered_at)?
)
```

customer_id uses the same account identifier as CUSTOMER.user_id; partner_id uses DELIVERY_PARTNER.user_id. Customer and restaurant descriptions copied into orders are deliberately redundant current master facts. dropoff fields and agreed_unit_price are separate captured order facts.

### Extract the nested groups into 1NF

1. Extract each nested collection or optional record into keyed rows.
2. Copy the enclosing key to retain its connection.
3. Choose keys using the cardinalities and retain the parent if a child group is empty.
4. Flatten composite addresses into their component columns.

| Starting record | Resulting 1NF relations | Count |
|---|---|---|
| ACCOUNT_UNF | APP_USER, CUSTOMER, DELIVERY_PARTNER | 3 |
| CATALOG_UNF | RESTAURANT, MENU_ITEM | 2 |
| ORDER_FORM_UNF | FOOD_ORDER_1, ORDER_LINE_1, PAYMENT, DELIVERY | 4 |
| Total | All nine relations are now represented | 9 |

Copy user_id to each role, restaurant_id to each catalog item, and order_id to its item/payment/delivery rows. Also copy restaurant_id into ORDER_LINE_1 as the item's owner: every item must belong to the order's selected restaurant.

The complete 1NF result is:
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

FOOD_ORDER_1(
  order_id PK, ordered_at, order_status,
  customer_id FK -> CUSTOMER.user_id,
  customer_name, customer_email, customer_phone, customer_since,
  restaurant_id FK -> RESTAURANT.restaurant_id,
  restaurant_name, restaurant_address_line,
  restaurant_city, restaurant_postal_code, restaurant_phone,
  dropoff_line, dropoff_city, dropoff_postal_code, delivery_fee
)

ORDER_LINE_1(
  order_id PK-part FK -> FOOD_ORDER_1.order_id,
  item_id PK-part FK -> MENU_ITEM.item_id,
  restaurant_id, item_name, category, current_price, is_available,
  quantity, agreed_unit_price,
  PK(order_id, item_id)
)

PAYMENT(
  payment_id PK,
  order_id UQ NOT NULL FK -> FOOD_ORDER_1.order_id,
  payment_method, payment_amount, payment_status, paid_at
)

DELIVERY(
  order_id PK FK -> FOOD_ORDER_1.order_id,
  partner_id FK -> DELIVERY_PARTNER.user_id,
  assigned_at, picked_up_at, delivered_at
)
```

FOOD_ORDER_1 has 18 attributes. ORDER_LINE_1 has nine: seven item-group attributes plus copied order_id and restaurant_id. Its key is (order_id, item_id), because repeated portions are combined in quantity.

PAYMENT.order_id is required and unique. DELIVERY.order_id alone is its shared PK/FK. Missing optional groups create no child row, rather than a null order reference. Later event timestamps can remain null.

All cells are atomic, but the order and line relations still contain redundant descriptions.

**What you can say**

"I started with three complete UNF record types. Accounts produce three relations, catalogs produce two, and orders produce four. Extracting the nested groups and copying their parent keys gives nine relations at 1NF. The order header and item lines still contain repeated descriptions."

## 1NF to 2NF

**2NF condition:** A relation is in 1NF and no non-prime attribute depends on a proper subset of a candidate key.

ORDER_LINE_1 has the composite key (order_id, item_id):
```text
item_id -> restaurant_id, item_name, category,
           current_price, is_available
(order_id, item_id) -> quantity, agreed_unit_price
```

Five menu facts depend only on item_id, which is part of the line key. The quantity and historical agreed price need the entire pair.

**Four decomposition steps**

1. Remove restaurant_id, item_name, category, current_price and is_available from the line.
2. Retain item_id as the determinant/key of those menu facts.
3. Consolidate that projection with the existing MENU_ITEM relation from CATALOG_UNF. It describes the same items, so do not create a second menu table.
4. Rename the retained line ORDER_ITEM_2. Rename the unchanged header FOOD_ORDER_2.

The changed relations are:
```text
MENU_ITEM(item_id PK,
          restaurant_id FK -> RESTAURANT.restaurant_id,
          item_name, category, current_price, is_available)

ORDER_ITEM_2(order_id PK-part/FK -> FOOD_ORDER_2.order_id,
             item_id PK-part/FK -> MENU_ITEM.item_id,
             quantity, agreed_unit_price,
             PK(order_id, item_id))
```

FOOD_ORDER_2 keeps all 18 attributes shown for FOOD_ORDER_1. APP_USER, CUSTOMER, DELIVERY_PARTNER, RESTAURANT, PAYMENT and DELIVERY keep exactly their 1NF attributes. Payment and delivery references point to the renamed order relation.

**Count remains nine.** The line reduces from nine attributes to four. MENU_ITEM already has its six required attributes. A normalization step can remove redundant columns without increasing the number of tables.

**Lossless explanation.** Joining ORDER_ITEM_2 to MENU_ITEM on item_id recovers the original legal lines, because item_id determines all separated menu facts. The cross-table rule that items match the order's restaurant still requires transaction/application/database checking.

**What you can say**

"Five item facts depend only on item_id, part of the composite line key. I removed them from the line and consolidated them with the existing MENU_ITEM. Quantity and agreed_unit_price remain because they need the whole pair. We still have nine relations."

## 2NF to 3NF

**3NF condition:** For every nontrivial FD X -> A, X is a superkey or A is prime, meaning part of a candidate key.

FOOD_ORDER_2's sole candidate key is order_id. These non-key IDs determine descriptive groups:
```text
order_id -> customer_id
customer_id -> customer_name, customer_email,
               customer_phone, customer_since

order_id -> restaurant_id
restaurant_id -> restaurant_name, restaurant_address_line,
                 restaurant_city, restaurant_postal_code,
                 restaurant_phone
```

**Four decomposition steps**

1. Remove the four customer descriptions and five restaurant descriptions.
2. Keep customer_id and restaurant_id in the order as foreign keys.
3. Consolidate the removed facts with the existing account/customer/restaurant master relations.
4. Rename FOOD_ORDER_2 to FOOD_ORDER and ORDER_ITEM_2 to ORDER_ITEM.

| Removed order attributes | Existing destination |
|---|---|
| customer_name, customer_email, customer_phone | APP_USER.full_name, APP_USER.email, APP_USER.phone |
| customer_since | CUSTOMER.customer_since |
| restaurant_name, restaurant_address_line, restaurant_city, restaurant_postal_code, restaurant_phone | RESTAURANT.restaurant_name, address_line, city, postal_code, contact_phone |

customer_id is the inherited user_id. The destination columns above contain the same facts with the indicated names. They already exist from the complete UNF conversion; no extra CUSTOMER_PROFILE table is introduced.

The reduced order is:
```text
FOOD_ORDER(order_id PK, customer_id FK -> CUSTOMER.user_id,
           restaurant_id FK -> RESTAURANT.restaurant_id,
           ordered_at, order_status, dropoff_line, dropoff_city,
           dropoff_postal_code, delivery_fee)
```

**18 - 4 customer descriptions - 5 restaurant descriptions = nine order attributes. The table count also remains nine, for a separate reason: all nine record types were already extracted at 1NF.**

The other eight relations keep their 2NF attributes; only ORDER_ITEM_2 loses its teaching suffix. The captured destination and fee remain because different orders from one customer can have different destinations and fees.

**Lossless explanation.** The retained IDs recover the removed customer descriptions through CUSTOMER plus APP_USER and the restaurant descriptions through RESTAURANT. Each separating identifier determines the whole separated description group for legal data.

**What you can say**

"Customer and restaurant descriptions depend transitively on order_id through their IDs. I removed those copies and kept the IDs as references to existing master relations. The header now has nine attributes. All nine tables came from our complete UNF, so no entity is added after 3NF."

## Final nine relations and their origin

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

| Final relation | Original UNF group | Main change |
|---|---|---|
| APP_USER | ACCOUNT_UNF shared fields | Atomic account at 1NF; its duplicate descriptions leave orders at 3NF |
| CUSTOMER | ACCOUNT_UNF.CUSTOMER_ROLE | Optional shared-key role at 1NF; duplicate customer_since leaves orders at 3NF |
| DELIVERY_PARTNER | ACCOUNT_UNF.PARTNER_ROLE | Optional shared-key role extracted at 1NF |
| RESTAURANT | CATALOG_UNF header | Atomic parent at 1NF; its duplicate descriptions leave orders at 3NF |
| MENU_ITEM | CATALOG_UNF.MENU_ITEMS | Parent owner key copied at 1NF; line menu facts consolidated at 2NF |
| FOOD_ORDER | ORDER_FORM_UNF header | 18 atomic attributes at 1NF/2NF, nine after 3NF |
| ORDER_ITEM | ORDER_FORM_UNF.ITEMS | Nine atomic attributes at 1NF, four after 2NF |
| PAYMENT | ORDER_FORM_UNF.PAYMENT_RECORD | Parent order key copied at 1NF; own PK plus unique order FK |
| DELIVERY | ORDER_FORM_UNF.DELIVERY_RECORD | Parent order key copied as shared PK/FK at 1NF |

## Checks and reconstruction

APP_USER has user_id and required unique email as candidate keys. PAYMENT has payment_id and required unique order_id as candidate keys. ORDER_ITEM uses the whole pair (order_id, item_id). Every other final relation has the single identifier stated in its definition. Under the stated FD set, every nontrivial determinant is a superkey, so the final relations satisfy 3NF and BCNF. No further 4NF/5NF split has been identified or is needed to produce these nine relations.

Do not infer postal_code -> city, name/phone uniqueness, or item_id -> agreed_unit_price. current_price is a catalog fact; agreed_unit_price is a captured order fact. amount_due is derived and omitted.

The redundant copies must agree with the master records. If actual input copies disagree, reconcile them before discarding columns. This is a teaching example over legal consistent data.

Reconstruct the three original record types separately using their parent keys and child lookups. Optional child lookups or outer joins preserve absent groups. An inner join across the whole database would incorrectly drop accounts without orders, empty catalogs, unpaid orders and unassigned orders.

Normal forms do not enforce at least one role, at least one order item, matching item/order restaurants, successful payment totals or workflow transitions. Those rules still need Phase 2 transaction/application/database logic.

**Complete passage to rehearse**

"Our complete UNF covers accounts and roles, restaurant catalogs, and orders with payments and deliveries. Extracting the nested groups gives three plus two plus four atomic relations: nine at 1NF. At 2NF, menu facts leave the order line and are consolidated with the catalog. At 3NF, customer and restaurant descriptions leave the order header and are consolidated with the master relations. The result is exactly our current nine-table schema."

Sources: RELATIONAL_SCHEMA.md, the project's EER, the supplied Review 1 requirements, and M2_6. Normalization 1-3.pptx for the repeating-group, partial-dependency and transitive-dependency method.
