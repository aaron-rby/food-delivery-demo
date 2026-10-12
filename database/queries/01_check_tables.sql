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
