-- For another computer only. Run as the administrator in the intended database.
-- Replace the password locally before executing. Never submit a real password.
CREATE USER food_project
IDENTIFIED BY "REPLACE_WITH_YOUR_OWN_PASSWORD"
DEFAULT TABLESPACE users
QUOTA 20M ON users;
GRANT CREATE SESSION, CREATE TABLE, CREATE SEQUENCE TO food_project;
