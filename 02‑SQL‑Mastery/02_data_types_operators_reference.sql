-- GRIT SQL Course - Day 2: Data Types & Operators Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- DATA TYPES EXAMPLES
-- ============================================

-- See table structures to understand data types
.schema customers
.schema products
.schema orders

-- ============================================
-- TEXT DATA TYPE EXAMPLES
-- ============================================

-- Example 1: Basic text filtering
SELECT first_name, last_name, city
FROM customers
WHERE city = 'New York';

-- Example 2: Text is case-sensitive (won't find anything)
SELECT first_name, last_name, city
FROM customers
WHERE city = 'new york';

-- Example 3: Find products with 'Smart' in the name
SELECT product_name, price
FROM products
WHERE product_name LIKE '%Smart%';

-- ============================================
-- NUMBER DATA TYPE EXAMPLES
-- ============================================

-- Example 4: Find products cheaper than $50
SELECT product_name, price
FROM products
WHERE price < 50
ORDER BY price DESC;

-- Example 5: Find products in a price range
SELECT product_name, price
FROM products
WHERE price BETWEEN 50 AND 150
ORDER BY price;

-- Example 6: Find products with low stock
SELECT product_name, stock_quantity
FROM products
WHERE stock_quantity <= 20
ORDER BY stock_quantity;

-- ============================================
-- COMPARISON OPERATORS
-- ============================================

-- Example 7: Equal (=) - exact match
SELECT product_name, category
FROM products
WHERE category = 'Electronics';

-- Example 8: Not equal (!= or <>)
SELECT product_name, category
FROM products
WHERE category != 'Electronics';

-- Example 9: Greater than (>) and less than or equal (<=)
SELECT product_name, price
FROM products
WHERE price > 100 AND price <= 200;

-- ============================================
-- LOGICAL OPERATORS
-- ============================================

-- Example 10: AND - both conditions must be true
SELECT product_name, category, price
FROM products
WHERE category = 'Electronics' AND price < 100;

-- Example 11: OR - either condition can be true
SELECT product_name, category, price
FROM products
WHERE category = 'Electronics' OR category = 'Sports';

-- Example 12: NOT - reverse the condition
SELECT product_name, category
FROM products
WHERE NOT category = 'Electronics';

-- ============================================
-- PATTERN MATCHING WITH LIKE
-- ============================================

-- Example 13: Names starting with 'J'
SELECT first_name, last_name
FROM customers
WHERE first_name LIKE 'J%';

-- Example 14: Names ending with 'n'
SELECT first_name, last_name
FROM customers
WHERE last_name LIKE '%n';

-- Example 15: Names containing 'ar'
SELECT first_name, last_name
FROM customers
WHERE first_name LIKE '%ar%';

-- Example 16: Product names with exactly 5 characters followed by space
SELECT product_name
FROM products
WHERE product_name LIKE '_____ %';

-- ============================================
-- IN OPERATOR EXAMPLES
-- ============================================

-- Example 17: Find customers from specific states
SELECT first_name, last_name, state
FROM customers
WHERE state IN ('CA', 'TX', 'NY');

-- Example 18: Find specific product categories
SELECT product_name, category, price
FROM products
WHERE category IN ('Electronics', 'Appliances')
ORDER BY category, price;

-- ============================================
-- NULL HANDLING
-- ============================================

-- Example 19: Find customers without phone numbers
SELECT first_name, last_name, phone
FROM customers
WHERE phone IS NULL;

-- Example 20: Find customers with phone numbers
SELECT first_name, last_name, phone
FROM customers
WHERE phone IS NOT NULL
LIMIT 5;

-- ============================================
-- COMPLEX FILTERING
-- ============================================

-- Example 21: Complex filter - Electronics OR Sports, under $100, in stock
SELECT product_name, category, price, stock_quantity
FROM products
WHERE (category = 'Electronics' OR category = 'Sports')
  AND price < 100
  AND stock_quantity > 0
ORDER BY price DESC;

-- Example 22: Customers from CA or NY with phone numbers
SELECT first_name, last_name, city, state, phone
FROM customers
WHERE state IN ('CA', 'NY')
  AND phone IS NOT NULL
ORDER BY state, last_name;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: Text Filtering - Last names starting with 'M'
SELECT first_name, last_name
FROM customers
WHERE last_name LIKE 'M%';

-- Exercise 2: Number Ranges - Products $25 to $75
SELECT product_name, price
FROM products
WHERE price BETWEEN 25 AND 75
ORDER BY price;

-- Exercise 3: Multiple Categories - Books or Sports
SELECT product_name, category
FROM products
WHERE category IN ('Books', 'Sports');

-- Exercise 4: Logical Operators - CA customers with phones
SELECT first_name, last_name, state, phone
FROM customers
WHERE state = 'CA' AND phone IS NOT NULL;

-- Exercise 5: Pattern Matching - Products with 'Wireless'
SELECT product_name, category
FROM products
WHERE product_name LIKE '%Wireless%';

-- Exercise 6: Complex Filter
SELECT product_name, category, price, stock_quantity
FROM products
WHERE (category = 'Electronics' OR price > 150)
  AND stock_quantity > 10
ORDER BY price DESC;

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed query: Products under $50 in Electronics or Sports
-- The issue was operator precedence - AND has higher precedence than OR
-- Original (wrong): category = 'Electronics' OR category = 'Sports' AND price < 50
-- This was interpreted as: category = 'Electronics' OR (category = 'Sports' AND price < 50)

-- Fixed version with parentheses:
SELECT product_name, category, price
FROM products
WHERE (category = 'Electronics' OR category = 'Sports') AND price < 50
ORDER BY price;

-- ============================================
-- USEFUL QUERIES FOR PRACTICE
-- ============================================

-- Show all data types in our tables
PRAGMA table_info(customers);
PRAGMA table_info(products);
PRAGMA table_info(orders);
PRAGMA table_info(order_items);

-- Sample data from each table
SELECT * FROM customers LIMIT 3;
SELECT * FROM products LIMIT 3;
SELECT * FROM orders LIMIT 3;
SELECT * FROM order_items LIMIT 3;

-- Count NULL values in each column
SELECT
    COUNT(*) as total_customers,
    COUNT(phone) as with_phone,
    COUNT(*) - COUNT(phone) as missing_phone
FROM customers;

-- Find unique values in categorical columns
SELECT DISTINCT category FROM products ORDER BY category;
SELECT DISTINCT state FROM customers ORDER BY state;
SELECT DISTINCT order_status FROM orders ORDER BY order_status;
