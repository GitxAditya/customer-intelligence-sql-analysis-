-- create database customer_intelligence_db;
use customer_intelligence_db;

-- Create read-only user
CREATE USER 'powerbi_reader'@'localhost' IDENTIFIED BY 'PowerBI@2024';

-- Grant only SELECT on your database
GRANT SELECT ON customer_intelligence_db.* TO 'powerbi_reader'@'localhost';

-- Use mysql_native_password (important for Power BI compatibility)
ALTER USER 'powerbi_reader'@'localhost' 
IDENTIFIED WITH mysql_native_password BY 'PowerBI@2024';

FLUSH PRIVILEGES;

-- SHOW GRANTS FOR 'powerbi_reader'@'localhost';

-- Step 1: Change auth plugin for the user
SELECT user, host, plugin FROM mysql.user WHERE user = 'powerbi_reader';