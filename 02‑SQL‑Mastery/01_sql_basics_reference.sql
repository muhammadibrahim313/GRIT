-- GRIT SQL Course - Day 1: SQL Basics Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- EXAMPLE QUERIES
-- ============================================

-- Example 1: See all customers (limited to 5)
SELECT * FROM customers LIMIT 5;

-- Example 2: See specific columns only
SELECT first_name, last_name, email FROM customers LIMIT 5;

-- Example 3: Count total customers
SELECT COUNT(*) as total_customers FROM customers;

-- Example 4: Find customers from California
SELECT first_name, last_name, city, state
FROM customers
WHERE state = 'CA';

-- Example 5: Find expensive products (over $50)
SELECT product_name, category, price
FROM products
WHERE price > 50
ORDER BY price DESC;

-- Example 6: Find active customers
SELECT first_name, last_name, customer_status
FROM customers
WHERE customer_status = 'active';

-- Example 7: Sort products by price (lowest first)
SELECT product_name, price
FROM products
ORDER BY price ASC
LIMIT 5;

-- Example 8: Sort customers by registration date (newest first)
SELECT first_name, last_name, registration_date
FROM customers
ORDER BY registration_date DESC
LIMIT 5;

-- Example 9: Electronics products under $100, sorted by price
SELECT product_name, category, price
FROM products
WHERE category = 'Electronics' AND price < 100
ORDER BY price DESC;

-- Example 10: Recent orders with customer details (JOIN preview)
SELECT o.order_id, c.first_name, c.last_name, o.order_date, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 10;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: Basic SELECT - Show all products
SELECT product_name, price FROM products;

-- Exercise 2: Simple Filtering - Customers from Texas
SELECT first_name, last_name, city, state
FROM customers
WHERE state = 'TX';

-- Exercise 3: Price Filtering - Products under $50
SELECT product_name, price
FROM products
WHERE price < 50
ORDER BY price ASC;

-- Exercise 4: Sports Category - Sports products by price
SELECT product_name, category, price
FROM products
WHERE category = 'Sports'
ORDER BY price DESC;

-- Exercise 5: Customer Search - Names starting with J or M
SELECT first_name, last_name
FROM customers
WHERE first_name LIKE 'J%' OR first_name LIKE 'M%';

-- Exercise 6: Recent Registrations - 3 newest customers
SELECT first_name, last_name, registration_date
FROM customers
ORDER BY registration_date DESC
LIMIT 3;

-- ============================================
-- USEFUL QUERIES FOR EXPLORATION
-- ============================================

-- See table structure
.schema customers
.schema products
.schema orders
.schema order_items

-- Count records in each table
SELECT 'customers' as table_name, COUNT(*) as count FROM customers
UNION ALL
SELECT 'products' as table_name, COUNT(*) as count FROM products
UNION ALL
SELECT 'orders' as table_name, COUNT(*) as count FROM orders
UNION ALL
SELECT 'order_items' as table_name, COUNT(*) as count FROM order_items;

-- Sample of each table
SELECT * FROM customers LIMIT 3;
SELECT * FROM products LIMIT 3;
SELECT * FROM orders LIMIT 3;
SELECT * FROM order_items LIMIT 3;

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed query: Show products over $100
SELECT product_name, price
FROM products
WHERE price > 100  -- Fixed: was missing FROM clause
ORDER BY price DESC;
