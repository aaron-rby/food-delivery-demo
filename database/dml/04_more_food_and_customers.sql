-- Additional fictional customers and dishes. Run after the expanded seed.
-- Existing names, prices and orders are preserved. Safe to run again.
SET DEFINE OFF
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
DECLARE
  account VARCHAR2(128);
BEGIN
  SELECT USER INTO account FROM dual;
  IF account IN ('SYS','SYSTEM') THEN
    RAISE_APPLICATION_ERROR(-20001,'Connect to the project schema.');
  END IF;
END;
/
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 5,'Arjun Menon','sample.customer.5@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=5);
INSERT INTO customer (user_id,customer_since) SELECT 5,SYSTIMESTAMP FROM app_user WHERE user_id=5 AND email='sample.customer.5@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=5);
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 6,'Priya Nair','sample.customer.6@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=6);
INSERT INTO customer (user_id,customer_since) SELECT 6,SYSTIMESTAMP FROM app_user WHERE user_id=6 AND email='sample.customer.6@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=6);
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 7,'Ishaan Gupta','sample.customer.7@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=7);
INSERT INTO customer (user_id,customer_since) SELECT 7,SYSTIMESTAMP FROM app_user WHERE user_id=7 AND email='sample.customer.7@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=7);
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 8,'Sara Khan','sample.customer.8@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=8);
INSERT INTO customer (user_id,customer_since) SELECT 8,SYSTIMESTAMP FROM app_user WHERE user_id=8 AND email='sample.customer.8@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=8);
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 9,'Kavya Raman','sample.customer.9@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=9);
INSERT INTO customer (user_id,customer_since) SELECT 9,SYSTIMESTAMP FROM app_user WHERE user_id=9 AND email='sample.customer.9@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=9);
INSERT INTO app_user (user_id,full_name,email,phone) SELECT 10,'Rahul Das','sample.customer.10@example.invalid',NULL FROM dual WHERE NOT EXISTS (SELECT 1 FROM app_user WHERE user_id=10);
INSERT INTO customer (user_id,customer_since) SELECT 10,SYSTIMESTAMP FROM app_user WHERE user_id=10 AND email='sample.customer.10@example.invalid' AND NOT EXISTS (SELECT 1 FROM customer WHERE user_id=10);
INSERT INTO menu_item SELECT 14,10,'Vegetable Biryani','Main Course',160,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=14);
INSERT INTO menu_item SELECT 15,10,'Dal and Rice','Main Course',110,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=15);
INSERT INTO menu_item SELECT 16,10,'Vegetable Sandwich','Snacks',90,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=16);
INSERT INTO menu_item SELECT 17,10,'Lemonade','Beverage',50,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=17);
INSERT INTO menu_item SELECT 18,10,'Chocolate Brownie','Dessert',80,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=18);
INSERT INTO menu_item SELECT 24,20,'Pongal','Breakfast',75,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=24);
INSERT INTO menu_item SELECT 25,20,'Poori and Potato Curry','Breakfast',85,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=25);
INSERT INTO menu_item SELECT 26,20,'Samosa','Snacks',35,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=26);
INSERT INTO menu_item SELECT 27,20,'Masala Tea','Beverage',30,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=27);
INSERT INTO menu_item SELECT 28,20,'Gulab Jamun','Dessert',60,1 FROM dual WHERE NOT EXISTS (SELECT 1 FROM menu_item WHERE item_id=28);
COMMIT;
SELECT COUNT(*) AS customer_count FROM customer;
SELECT COUNT(*) AS dish_count FROM menu_item;
