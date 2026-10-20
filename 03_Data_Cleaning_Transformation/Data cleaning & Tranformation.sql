USE customer_intelligence_db;

-- Standardize Text
SELECT DISTINCT city
FROM customers
ORDER BY city;

SELECT DISTINCT customer_status
FROM customers;

SELECT DISTINCT order_status
FROM orders;

SELECT DISTINCT payment_status
FROM payments;

SELECT DISTINCT payment_method
FROM payments;