-- Read-only evidence for the Phase 2 viva.
SET LINESIZE 180 PAGESIZE 100
COLUMN relation FORMAT A20
COLUMN order_status FORMAT A18
COLUMN payment_status FORMAT A14
COLUMN full_name FORMAT A20
COLUMN restaurant_name FORMAT A20
SELECT 'APP_USER' relation, COUNT(*) rows_present FROM app_user UNION ALL
SELECT 'CUSTOMER', COUNT(*) FROM customer UNION ALL
SELECT 'DELIVERY_PARTNER', COUNT(*) FROM delivery_partner UNION ALL
SELECT 'RESTAURANT', COUNT(*) FROM restaurant UNION ALL
SELECT 'MENU_ITEM', COUNT(*) FROM menu_item UNION ALL
SELECT 'FOOD_ORDER', COUNT(*) FROM food_order UNION ALL
SELECT 'ORDER_ITEM', COUNT(*) FROM order_item UNION ALL
SELECT 'PAYMENT', COUNT(*) FROM payment UNION ALL
SELECT 'DELIVERY', COUNT(*) FROM delivery;

SELECT o.order_id, o.order_status,
       SUM(i.quantity*i.agreed_unit_price) subtotal, o.delivery_fee,
       SUM(i.quantity*i.agreed_unit_price)+o.delivery_fee amount_due,
       p.payment_status
FROM food_order o JOIN order_item i ON i.order_id=o.order_id
LEFT JOIN payment p ON p.order_id=o.order_id
GROUP BY o.order_id,o.order_status,o.delivery_fee,p.payment_status
ORDER BY o.order_id;

SELECT u.user_id,u.full_name FROM app_user u
JOIN customer c ON c.user_id=u.user_id
JOIN delivery_partner p ON p.user_id=u.user_id;

-- Every query below should return zero rows.
SELECT o.order_id FROM food_order o WHERE NOT EXISTS
  (SELECT 1 FROM order_item i WHERE i.order_id=o.order_id);
SELECT i.order_id,i.item_id FROM order_item i
JOIN food_order o ON o.order_id=i.order_id
JOIN menu_item m ON m.item_id=i.item_id
WHERE o.restaurant_id<>m.restaurant_id;
SELECT u.user_id FROM app_user u WHERE NOT EXISTS
  (SELECT 1 FROM customer c WHERE c.user_id=u.user_id)
AND NOT EXISTS (SELECT 1 FROM delivery_partner p WHERE p.user_id=u.user_id);
SELECT o.order_id FROM food_order o
LEFT JOIN payment p ON p.order_id=o.order_id
LEFT JOIN delivery d ON d.order_id=o.order_id
WHERE o.order_status='DELIVERED' AND
 (NVL(p.payment_status,'MISSING')<>'SUCCESS' OR d.delivered_at IS NULL
 OR p.payment_amount<>(SELECT SUM(i.quantity*i.agreed_unit_price)+o.delivery_fee FROM order_item i WHERE i.order_id=o.order_id));
