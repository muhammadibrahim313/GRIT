-- GRIT SQL Course - Day 3: Aggregation & Grouping Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- BASIC AGGREGATION EXAMPLES
-- ============================================

-- Example 1: Count total customers
SELECT COUNT(*) as total_customers
FROM customers;

-- Example 2: Count customers with phone numbers
SELECT COUNT(phone) as customers_with_phone
FROM customers;

-- Example 3: Count products by category
SELECT category, COUNT(*) as product_count
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- Example 4: Total value of all products
SELECT SUM(price) as total_inventory_value
FROM products;

-- Example 5: Average product price
SELECT AVG(price) as average_price
FROM products;

-- Example 6: Most expensive and cheapest products
SELECT MAX(price) as highest_price, MIN(price) as lowest_price
FROM products;

-- ============================================
-- GROUP BY WITH SINGLE AGGREGATION
-- ============================================

-- Example 7: Average price by category
SELECT category, AVG(price) as avg_price
FROM products
GROUP BY category
ORDER BY avg_price DESC;

-- Example 8: Total stock by category
SELECT category, SUM(stock_quantity) as total_stock
FROM products
GROUP BY category
ORDER BY total_stock DESC;

-- Example 9: Customer count by state
SELECT state, COUNT(*) as customer_count
FROM customers
GROUP BY state
ORDER BY customer_count DESC;

-- ============================================
-- MULTIPLE AGGREGATIONS PER GROUP
-- ============================================

-- Example 10: Product statistics by category
SELECT category,
       COUNT(*) as product_count,
       AVG(price) as avg_price,
       MIN(price) as min_price,
       MAX(price) as max_price
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- Example 11: Order statistics by status
SELECT order_status,
       COUNT(*) as order_count,
       AVG(total_amount) as avg_order_value,
       SUM(total_amount) as total_value
FROM orders
GROUP BY order_status
ORDER BY total_value DESC;

-- ============================================
-- HAVING CLAUSE EXAMPLES
-- ============================================

-- Example 12: Categories with high average prices
SELECT category, AVG(price) as avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 100
ORDER BY avg_price DESC;

-- Example 13: States with many customers
SELECT state, COUNT(*) as customer_count
FROM customers
GROUP BY state
HAVING COUNT(*) >= 2
ORDER BY customer_count DESC;

-- Example 14: Categories with expensive products and good stock
SELECT category,
       COUNT(*) as product_count,
       AVG(price) as avg_price,
       SUM(stock_quantity) as total_stock
FROM products
GROUP BY category
HAVING AVG(price) > 50 AND SUM(stock_quantity) > 20
ORDER BY avg_price DESC;

-- ============================================
-- COMBINING WHERE AND HAVING
-- ============================================

-- Example 15: Popular states with active customers only
SELECT state, COUNT(*) as active_customers
FROM customers
WHERE customer_status = 'active'
GROUP BY state
HAVING COUNT(*) >= 2
ORDER BY active_customers DESC;

-- Example 16: High-value orders by status (exclude cheap orders)
SELECT order_status,
       COUNT(*) as order_count,
       AVG(total_amount) as avg_value
FROM orders
WHERE total_amount > 50
GROUP BY order_status
HAVING COUNT(*) > 2
ORDER BY avg_value DESC;

-- ============================================
-- BUSINESS INTELLIGENCE REPORTS
-- ============================================

-- Example 17: Product Category Performance Report
SELECT category,
       COUNT(*) as products_offered,
       SUM(stock_quantity) as total_stock,
       AVG(price) as avg_selling_price,
       MIN(price) as lowest_price,
       MAX(price) as highest_price
FROM products
GROUP BY category
ORDER BY total_stock DESC;

-- Example 18: Customer Demographics by State
SELECT state,
       COUNT(*) as total_customers,
       COUNT(phone) as with_phone,
       ROUND(AVG(CASE WHEN phone IS NOT NULL THEN 1 ELSE 0 END) * 100, 1) as phone_pct
FROM customers
GROUP BY state
ORDER BY total_customers DESC;

-- Example 19: Order Status Summary
SELECT order_status,
       COUNT(*) as order_count,
       SUM(total_amount) as total_revenue,
       AVG(total_amount) as avg_order_value,
       MIN(total_amount) as smallest_order,
       MAX(total_amount) as largest_order
FROM orders
GROUP BY order_status
ORDER BY total_revenue DESC;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: Basic Counting
SELECT COUNT(*) as total_orders
FROM orders;

-- Exercise 2: Group By Category
SELECT category, COUNT(*) as product_count
FROM products
GROUP BY category
ORDER BY product_count DESC;

-- Exercise 3: Price Statistics
SELECT AVG(price) as avg_price,
       MIN(price) as min_price,
       MAX(price) as max_price
FROM products;

-- Exercise 4: Using HAVING
SELECT category, COUNT(*) as product_count
FROM products
GROUP BY category
HAVING COUNT(*) > 2
ORDER BY product_count DESC;

-- Exercise 5: Combined WHERE and HAVING
SELECT state, COUNT(*) as active_count
FROM customers
WHERE customer_status = 'active'
GROUP BY state
HAVING COUNT(*) >= 2
ORDER BY active_count DESC;

-- Exercise 6: Business Report
SELECT order_status,
       COUNT(*) as order_count,
       SUM(total_amount) as total_revenue,
       AVG(total_amount) as avg_order_value
FROM orders
GROUP BY order_status
ORDER BY total_revenue DESC;

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed query: Categories with average price over $100
-- The issue was using WHERE with aggregate function
-- WHERE filters rows BEFORE aggregation
-- HAVING filters groups AFTER aggregation

-- Fixed version:
SELECT category, AVG(price) as avg_price
FROM products
GROUP BY category
HAVING AVG(price) > 100
ORDER BY avg_price DESC;

-- ============================================
-- ADDITIONAL USEFUL QUERIES
-- ============================================

-- Top-selling categories by revenue
SELECT category,
       SUM(price * stock_quantity) as potential_revenue
FROM products
GROUP BY category
ORDER BY potential_revenue DESC;

-- Customer order frequency analysis
SELECT
    CASE
        WHEN order_count = 0 THEN 'No orders'
        WHEN order_count = 1 THEN 'One order'
        WHEN order_count <= 3 THEN '2-3 orders'
        ELSE '4+ orders'
    END as order_frequency,
    COUNT(*) as customers
FROM (
    SELECT c.customer_id,
           COUNT(o.order_id) as order_count
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
) as customer_orders
GROUP BY
    CASE
        WHEN order_count = 0 THEN 'No orders'
        WHEN order_count = 1 THEN 'One order'
        WHEN order_count <= 3 THEN '2-3 orders'
        ELSE '4+ orders'
    END
ORDER BY customers DESC;
