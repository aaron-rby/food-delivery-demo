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
WHENEVER SQLERROR CONTINUE NONE
