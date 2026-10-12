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
