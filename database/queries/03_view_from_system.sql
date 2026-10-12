-- Read-only inspection from the current SYSTEM worksheet.
SELECT owner AS project_schema,table_name FROM all_tables WHERE owner='FOOD_PROJECT' ORDER BY table_name;
SELECT * FROM food_project.app_user;
SELECT * FROM food_project.customer;
SELECT * FROM food_project.delivery_partner;
SELECT * FROM food_project.restaurant;
SELECT * FROM food_project.menu_item;
SELECT * FROM food_project.food_order;
SELECT * FROM food_project.order_item;
SELECT * FROM food_project.payment;
SELECT * FROM food_project.delivery;
SELECT o.order_id,o.order_status,SUM(i.quantity*i.agreed_unit_price) AS subtotal,
       o.delivery_fee,SUM(i.quantity*i.agreed_unit_price)+o.delivery_fee AS amount_due
FROM food_project.food_order o JOIN food_project.order_item i ON i.order_id=o.order_id
GROUP BY o.order_id,o.order_status,o.delivery_fee ORDER BY o.order_id;
