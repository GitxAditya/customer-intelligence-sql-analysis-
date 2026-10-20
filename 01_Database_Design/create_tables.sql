create database customer_intelligence_db;
use customer_intelligence_db;

CREATE TABLE customers (
    cust_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_name VARCHAR(100) NOT NULL,
    gender ENUM('Male','Female','Other'),
    dob DATE,
    email VARCHAR(100) UNIQUE,
    phone VARCHAR(15) UNIQUE,
    city VARCHAR(50),
    state VARCHAR(50),
    signup_date DATE NOT NULL,
    customer_status ENUM('Active','Inactive') DEFAULT 'Active'
);

CREATE TABLE products (
    prod_id INT AUTO_INCREMENT PRIMARY KEY,
    prod_name VARCHAR(120) NOT NULL,
    category VARCHAR(50),
    brand VARCHAR(50),
    price DECIMAL(10,2) NOT NULL,
    cost_price DECIMAL(10,2) NOT NULL,
    stock INT DEFAULT 0
);

CREATE TABLE orders(
    order_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_id INT NOT NULL,
    order_date DATE NOT NULL,
    order_status ENUM(
        'Pending',
        'Shipped',
        'Delivered',
        'Cancelled',
        'Returned'
    ) DEFAULT 'Pending',
    FOREIGN KEY(cust_id)
    REFERENCES customers(cust_id)
);

CREATE TABLE order_items(
    item_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    prod_id INT NOT NULL,
    quantity INT NOT NULL,
    selling_price DECIMAL(10,2),
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),
    FOREIGN KEY(prod_id)
    REFERENCES products(prod_id)
);

CREATE TABLE payments(
    payment_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT UNIQUE,

    payment_method ENUM(
        'UPI',
        'Credit Card',
        'Debit Card',
        'Cash',
        'Net Banking',
        'Wallet'
    ),

    payment_status ENUM(
        'Success',
        'Pending',
        'Failed',
        'Refunded'),
    amount DECIMAL(10,2),
    payment_date DATE,
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id)
);

CREATE TABLE reviews(
    review_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_id INT,
    prod_id INT,
    rating INT,
    review_text TEXT,
    review_date DATE,
    FOREIGN KEY(cust_id)
    REFERENCES customers(cust_id),
    FOREIGN KEY(prod_id)
    REFERENCES products(prod_id)
);

CREATE TABLE returns(
    return_id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT,
    prod_id INT,
    quantity INT,
    reason VARCHAR(150),
    return_date DATE,
    FOREIGN KEY(order_id)
    REFERENCES orders(order_id),
    FOREIGN KEY(prod_id)
    REFERENCES products(prod_id)
);

CREATE TABLE marketing_campaigns(
    campaign_id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_name VARCHAR(100),
    campaign_type VARCHAR(50),
    start_date DATE,
    end_date DATE,
    budget DECIMAL(12,2)
);

CREATE TABLE customer_campaigns(
    campaign_customer_id INT AUTO_INCREMENT PRIMARY KEY,
    campaign_id INT,
    cust_id INT,
    campaign_status ENUM(
        'Sent',
        'Opened',
        'Clicked',
        'Purchased'),
    FOREIGN KEY(campaign_id)
    REFERENCES marketing_campaigns(campaign_id),
    FOREIGN KEY(cust_id)
    REFERENCES customers(cust_id)
);

CREATE TABLE wishlist(
    wishlist_id INT AUTO_INCREMENT PRIMARY KEY,
    cust_id INT,
    prod_id INT,
    added_date DATE,
    FOREIGN KEY(cust_id)
    REFERENCES customers(cust_id),
    FOREIGN KEY(prod_id)
    REFERENCES products(prod_id)
);