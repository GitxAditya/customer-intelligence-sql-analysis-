USE customer_intelligence_db;

-- Profile all tables
SELECT 'customers' AS table_name, COUNT(*) AS row_count
FROM customers

UNION ALL

SELECT 'products', COUNT(*)
FROM products

UNION ALL

SELECT 'orders', COUNT(*)
FROM orders

UNION ALL

SELECT 'order_items', COUNT(*)
FROM order_items

UNION ALL

SELECT 'payments', COUNT(*)
FROM payments

UNION ALL

SELECT 'returns', COUNT(*)
FROM returns

UNION ALL

SELECT 'reviews', COUNT(*)
FROM reviews

UNION ALL

SELECT 'marketing_campaigns', COUNT(*)
FROM marketing_campaigns

UNION ALL

SELECT 'customer_campaigns', COUNT(*)
FROM customer_campaigns;

-- Check minimum and maximum dates
SELECT
    'customers.signup_date' AS column_name,
    MIN(signup_date) AS min_date,
    MAX(signup_date) AS max_date
FROM customers

UNION ALL

SELECT
    'orders.order_date',
    MIN(order_date),
    MAX(order_date)
FROM orders

UNION ALL

SELECT
    'payments.payment_date',
    MIN(payment_date),
    MAX(payment_date)
FROM payments

UNION ALL

SELECT
    'returns.return_date',
    MIN(return_date),
    MAX(return_date)
FROM returns

UNION ALL

SELECT
    'reviews.review_date',
    MIN(review_date),
    MAX(review_date)
FROM reviews;

-- Profile customer statuses
SELECT
    customer_status,
    COUNT(*) AS customers,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM customers),
        2
    ) AS percentage
FROM customers
GROUP BY customer_status
ORDER BY customers DESC;  

-- Profile customer statuses
SELECT
    order_status,
    COUNT(*) AS orders,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders),
        2
    ) AS percentage
FROM orders
GROUP BY order_status
ORDER BY orders DESC;

-- Profile order statuses
SELECT
    payment_status,
    COUNT(*) AS payments,
    ROUND(
        COUNT(*) * 100.0 / (SELECT COUNT(*) FROM payments),
        2
    ) AS percentage
FROM payments
GROUP BY payment_status
ORDER BY payments DESC;

SELECT
    payment_method,
    COUNT(*) AS transactions,
    SUM(amount) AS total_amount
FROM payments
GROUP BY payment_method
ORDER BY total_amount DESC;

-- Customers NULL audit
SELECT
    SUM(cust_name IS NULL) AS cust_name_nulls,
    SUM(gender IS NULL) AS gender_nulls,
    SUM(dob IS NULL) AS dob_nulls,
    SUM(email IS NULL) AS email_nulls,
    SUM(phone IS NULL) AS phone_nulls,
    SUM(city IS NULL) AS city_nulls,
    SUM(state IS NULL) AS state_nulls,
    SUM(signup_date IS NULL) AS signup_date_nulls,
    SUM(customer_status IS NULL) AS status_nulls
FROM customers;

-- Products NULL audit
SELECT
    SUM(prod_name IS NULL) AS product_name_nulls,
    SUM(category IS NULL) AS category_nulls,
    SUM(brand IS NULL) AS brand_nulls,
    SUM(price IS NULL) AS price_nulls,
    SUM(cost_price IS NULL) AS cost_price_nulls,
    SUM(stock IS NULL) AS stock_nulls
FROM products;

-- Orders and order_items NULL audit
SELECT
    SUM(cust_id IS NULL) AS customer_id_nulls,
    SUM(order_date IS NULL) AS order_date_nulls,
    SUM(order_status IS NULL) AS status_nulls
FROM orders;
  
SELECT
    SUM(order_id IS NULL) AS order_id_nulls,
    SUM(prod_id IS NULL) AS product_id_nulls,
    SUM(quantity IS NULL) AS quantity_nulls,
    SUM(selling_price IS NULL) AS selling_price_nulls
FROM order_items;

-- Payments, returns and reviews NULL audit
SELECT
    SUM(order_id IS NULL) AS order_id_nulls,
    SUM(payment_method IS NULL) AS method_nulls,
    SUM(payment_status IS NULL) AS status_nulls,
    SUM(amount IS NULL) AS amount_nulls,
    SUM(payment_date IS NULL) AS date_nulls
FROM payments;

SELECT
    SUM(order_id IS NULL) AS order_id_nulls,
    SUM(payment_method IS NULL) AS method_nulls,
    SUM(payment_status IS NULL) AS status_nulls,
    SUM(amount IS NULL) AS amount_nulls,
    SUM(payment_date IS NULL) AS date_nulls
FROM payments;

SELECT
    SUM(cust_id IS NULL) AS customer_id_nulls,
    SUM(prod_id IS NULL) AS product_id_nulls,
    SUM(rating IS NULL) AS rating_nulls,
    SUM(review_text IS NULL) AS review_text_nulls,
    SUM(review_date IS NULL) AS date_nulls
FROM reviews;

-- duplicate order item
SELECT
    order_id,
    prod_id,
    COUNT(*) AS cnt
FROM order_items
GROUP BY order_id, prod_id
HAVING COUNT(*) > 1;
