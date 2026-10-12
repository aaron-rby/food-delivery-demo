-- FOOD DELIVERY SYSTEM: one-file Oracle setup
-- Open this file in SQL Developer and use Run Script (F5).
-- Use an EMPTY project schema, not SYS or SYSTEM.
-- This file never drops tables and must be run only once.
-- Oracle CREATE TABLE commits independently; successful DDL survives rollback.
-- IDs are explicit for learning; sequences can be added when building the app.
-- Relations: APP_USER, CUSTOMER, DELIVERY_PARTNER, RESTAURANT, MENU_ITEM,
-- FOOD_ORDER, ORDER_ITEM, PAYMENT, DELIVERY.

SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

SELECT USER AS connected_account FROM dual;

DECLARE
    existing_count NUMBER;
BEGIN
    IF USER IN ('SYS','SYSTEM') THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Connect to your own project schema before running this script.');
    END IF;
    SELECT COUNT(*) INTO existing_count
    FROM user_tables
    WHERE table_name IN (
        'APP_USER','CUSTOMER','DELIVERY_PARTNER','RESTAURANT','MENU_ITEM',
        'FOOD_ORDER','ORDER_ITEM','PAYMENT','DELIVERY'
    );
    IF existing_count > 0 THEN
        RAISE_APPLICATION_ERROR(-20002,
            'Project tables already exist. Use a fresh project schema or inspect existing tables; do not rerun setup.');
    END IF;
END;
/

PROMPT STEP 1: Create all nine tables
-- Food Delivery System: final nine relations, Oracle DDL.
-- Run once in your own project schema, in the order below.
-- IDs are assigned explicitly; identity columns/sequences are not required.
-- Existing tables are not dropped. No sample data is inserted here.

CREATE TABLE app_user (
    user_id NUMBER(10,0) CONSTRAINT pk_app_user PRIMARY KEY,
    full_name VARCHAR2(100 CHAR) NOT NULL,
    email VARCHAR2(254 CHAR) NOT NULL,
    phone VARCHAR2(20 CHAR),
    CONSTRAINT uq_app_user_email UNIQUE (email),
    CONSTRAINT ck_app_user_id CHECK (user_id > 0),
    CONSTRAINT ck_app_user_name CHECK (TRIM(full_name) IS NOT NULL),
    CONSTRAINT ck_app_user_email CHECK (
        TRIM(email) IS NOT NULL AND email = LOWER(TRIM(email))
    )
);

CREATE TABLE customer (
    user_id NUMBER(10,0) CONSTRAINT pk_customer PRIMARY KEY,
    customer_since TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    CONSTRAINT fk_customer_user FOREIGN KEY (user_id)
        REFERENCES app_user (user_id)
);

CREATE TABLE delivery_partner (
    user_id NUMBER(10,0) CONSTRAINT pk_delivery_partner PRIMARY KEY,
    transport_mode VARCHAR2(12 CHAR) NOT NULL,
    availability_status VARCHAR2(12 CHAR) DEFAULT 'AVAILABLE' NOT NULL,
    CONSTRAINT fk_partner_user FOREIGN KEY (user_id)
        REFERENCES app_user (user_id),
    CONSTRAINT ck_partner_transport CHECK (
        transport_mode IN ('WALK','BICYCLE','MOTORBIKE','CAR')
    ),
    CONSTRAINT ck_partner_availability CHECK (
        availability_status IN ('AVAILABLE','BUSY','OFFLINE')
    )
);

CREATE TABLE restaurant (
    restaurant_id NUMBER(10,0) CONSTRAINT pk_restaurant PRIMARY KEY,
    restaurant_name VARCHAR2(120 CHAR) NOT NULL,
    address_line VARCHAR2(200 CHAR) NOT NULL,
    city VARCHAR2(80 CHAR) NOT NULL,
    postal_code VARCHAR2(12 CHAR) NOT NULL,
    contact_phone VARCHAR2(20 CHAR),
    CONSTRAINT ck_restaurant_id CHECK (restaurant_id > 0),
    CONSTRAINT ck_restaurant_name CHECK (TRIM(restaurant_name) IS NOT NULL)
);

CREATE TABLE menu_item (
    item_id NUMBER(10,0) CONSTRAINT pk_menu_item PRIMARY KEY,
    restaurant_id NUMBER(10,0) NOT NULL,
    item_name VARCHAR2(120 CHAR) NOT NULL,
    category VARCHAR2(60 CHAR) NOT NULL,
    current_price NUMBER(10,2) NOT NULL,
    is_available NUMBER(1,0) DEFAULT 1 NOT NULL,
    CONSTRAINT fk_menu_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurant (restaurant_id),
    CONSTRAINT ck_menu_item_id CHECK (item_id > 0),
    CONSTRAINT ck_menu_price CHECK (current_price > 0),
    CONSTRAINT ck_menu_available CHECK (is_available IN (0,1))
);

CREATE TABLE food_order (
    order_id NUMBER(10,0) CONSTRAINT pk_food_order PRIMARY KEY,
    customer_id NUMBER(10,0) NOT NULL,
    restaurant_id NUMBER(10,0) NOT NULL,
    ordered_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    order_status VARCHAR2(20 CHAR) DEFAULT 'PLACED' NOT NULL,
    dropoff_line VARCHAR2(200 CHAR) NOT NULL,
    dropoff_city VARCHAR2(80 CHAR) NOT NULL,
    dropoff_postal_code VARCHAR2(12 CHAR) NOT NULL,
    delivery_fee NUMBER(10,2) DEFAULT 0 NOT NULL,
    CONSTRAINT fk_order_customer FOREIGN KEY (customer_id)
        REFERENCES customer (user_id),
    CONSTRAINT fk_order_restaurant FOREIGN KEY (restaurant_id)
        REFERENCES restaurant (restaurant_id),
    CONSTRAINT ck_food_order_id CHECK (order_id > 0),
    CONSTRAINT ck_order_fee CHECK (delivery_fee >= 0),
    CONSTRAINT ck_order_status CHECK (order_status IN (
        'PLACED','ACCEPTED','PREPARING','READY',
        'OUT_FOR_DELIVERY','DELIVERED','CANCELLED'
    ))
);

CREATE TABLE order_item (
    order_id NUMBER(10,0) NOT NULL,
    item_id NUMBER(10,0) NOT NULL,
    quantity NUMBER NOT NULL,
    agreed_unit_price NUMBER(10,2) NOT NULL,
    CONSTRAINT pk_order_item PRIMARY KEY (order_id,item_id),
    CONSTRAINT fk_line_order FOREIGN KEY (order_id)
        REFERENCES food_order (order_id),
    CONSTRAINT fk_line_item FOREIGN KEY (item_id)
        REFERENCES menu_item (item_id),
    CONSTRAINT ck_line_quantity CHECK (
        quantity >= 1 AND quantity = TRUNC(quantity)
    ),
    CONSTRAINT ck_line_price CHECK (agreed_unit_price > 0)
);

CREATE TABLE payment (
    payment_id NUMBER(10,0) CONSTRAINT pk_payment PRIMARY KEY,
    order_id NUMBER(10,0) NOT NULL,
    payment_method VARCHAR2(10 CHAR) NOT NULL,
    payment_amount NUMBER(10,2) NOT NULL,
    payment_status VARCHAR2(10 CHAR) DEFAULT 'PENDING' NOT NULL,
    paid_at TIMESTAMP,
    CONSTRAINT uq_payment_order UNIQUE (order_id),
    CONSTRAINT fk_payment_order FOREIGN KEY (order_id)
        REFERENCES food_order (order_id),
    CONSTRAINT ck_payment_id CHECK (payment_id > 0),
    CONSTRAINT ck_payment_method CHECK (payment_method IN ('CASH','ONLINE')),
    CONSTRAINT ck_payment_amount CHECK (payment_amount > 0),
    CONSTRAINT ck_payment_status CHECK (
        payment_status IN ('PENDING','SUCCESS','FAILED')
    ),
    CONSTRAINT ck_payment_time CHECK (
        (payment_status = 'SUCCESS' AND paid_at IS NOT NULL)
        OR (payment_status IN ('PENDING','FAILED') AND paid_at IS NULL)
    )
);

CREATE TABLE delivery (
    order_id NUMBER(10,0) CONSTRAINT pk_delivery PRIMARY KEY,
    partner_id NUMBER(10,0) NOT NULL,
    assigned_at TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
    picked_up_at TIMESTAMP,
    delivered_at TIMESTAMP,
    CONSTRAINT fk_delivery_order FOREIGN KEY (order_id)
        REFERENCES food_order (order_id),
    CONSTRAINT fk_delivery_partner FOREIGN KEY (partner_id)
        REFERENCES delivery_partner (user_id),
    CONSTRAINT ck_delivery_pickup CHECK (
        picked_up_at IS NULL OR picked_up_at >= assigned_at
    ),
    CONSTRAINT ck_delivery_completion CHECK (
        delivered_at IS NULL
        OR (picked_up_at IS NOT NULL AND delivered_at >= picked_up_at)
    )
);

-- Cross-table workflow rules are documented in the schema/mapping guides.
-- Do not infer that these DDL constraints alone enforce those rules.

PROMPT STEP 2: Insert fictional sample data
-- Run after 01_create_tables.sql. Fictional data, one delivered order.
-- Run once: repeating this file produces duplicate-key errors.
-- In SQL*Plus/SQL Developer script mode, stop and roll back on DML failure.
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

INSERT INTO app_user (user_id,full_name,email,phone)
VALUES (1,'Asha Rao','asha@example.com','9000000001');
INSERT INTO app_user (user_id,full_name,email,phone)
VALUES (2,'Ravi Kumar','ravi@example.com','9000000002');

INSERT INTO customer (user_id,customer_since)
VALUES (1,TIMESTAMP '2026-10-04 10:00:00');
INSERT INTO delivery_partner (user_id,transport_mode,availability_status)
VALUES (2,'MOTORBIKE','AVAILABLE');

INSERT INTO restaurant
    (restaurant_id,restaurant_name,address_line,city,postal_code,contact_phone)
VALUES (10,'Campus Kitchen','12 College Road','Chennai','600001','9000000010');

INSERT INTO menu_item
    (item_id,restaurant_id,item_name,category,current_price,is_available)
VALUES (11,10,'Veg Rice','Main Course',120,1);
INSERT INTO menu_item
    (item_id,restaurant_id,item_name,category,current_price,is_available)
VALUES (12,10,'Juice','Beverage',80,1);

INSERT INTO food_order
    (order_id,customer_id,restaurant_id,ordered_at,order_status,
     dropoff_line,dropoff_city,dropoff_postal_code,delivery_fee)
VALUES (1001,1,10,TIMESTAMP '2026-10-04 12:00:00','DELIVERED',
        'Hostel Gate 2','Chennai','600001',30);

INSERT INTO order_item (order_id,item_id,quantity,agreed_unit_price)
VALUES (1001,11,2,120);
INSERT INTO order_item (order_id,item_id,quantity,agreed_unit_price)
VALUES (1001,12,1,80);

INSERT INTO payment
    (payment_id,order_id,payment_method,payment_amount,payment_status,paid_at)
VALUES (5001,1001,'ONLINE',350,'SUCCESS',TIMESTAMP '2026-10-04 12:01:00');

INSERT INTO delivery (order_id,partner_id,assigned_at,picked_up_at,delivered_at)
VALUES (1001,2,TIMESTAMP '2026-10-04 12:10:00',
        TIMESTAMP '2026-10-04 12:25:00',TIMESTAMP '2026-10-04 12:45:00');

COMMIT;


PROMPT STEP 3: Verify tables, constraints and totals
-- Run after table creation; the result should list all nine tables.
SELECT table_name
FROM user_tables
WHERE table_name IN (
    'APP_USER','CUSTOMER','DELIVERY_PARTNER','RESTAURANT','MENU_ITEM',
    'FOOD_ORDER','ORDER_ITEM','PAYMENT','DELIVERY'
)
ORDER BY table_name;

-- P = primary key; R = foreign key; U = unique; C = check/NOT NULL.
SELECT table_name,constraint_name,constraint_type,status
FROM user_constraints
WHERE table_name IN (
    'APP_USER','CUSTOMER','DELIVERY_PARTNER','RESTAURANT','MENU_ITEM',
    'FOOD_ORDER','ORDER_ITEM','PAYMENT','DELIVERY'
)
ORDER BY table_name,constraint_type,constraint_name;

-- After sample insertion, order 1001 should show subtotal 320, amount_due 350.
SELECT o.order_id,o.order_status,
       SUM(oi.quantity * oi.agreed_unit_price) AS subtotal,
       o.delivery_fee,
       SUM(oi.quantity * oi.agreed_unit_price) + o.delivery_fee AS amount_due
FROM food_order o
JOIN order_item oi ON oi.order_id = o.order_id
GROUP BY o.order_id,o.order_status,o.delivery_fee
ORDER BY o.order_id;

-- For the sample order, payment_status = SUCCESS and payment_amount = 350.
SELECT o.order_id,u.full_name,r.restaurant_name,
       p.payment_status,p.payment_amount,d.delivered_at
FROM food_order o
JOIN customer c ON c.user_id = o.customer_id
JOIN app_user u ON u.user_id = c.user_id
JOIN restaurant r ON r.restaurant_id = o.restaurant_id
LEFT JOIN payment p ON p.order_id = o.order_id
LEFT JOIN delivery d ON d.order_id = o.order_id
ORDER BY o.order_id;

PROMPT STEP 4: Inspect inserted rows
SELECT * FROM app_user;
SELECT * FROM customer;
SELECT * FROM delivery_partner;
SELECT * FROM restaurant;
SELECT * FROM menu_item;
SELECT * FROM food_order;
SELECT * FROM order_item;
SELECT * FROM payment;
SELECT * FROM delivery;

PROMPT Setup complete. Expected: nine tables; order 1001 subtotal 320, total 350.
WHENEVER SQLERROR CONTINUE NONE
