-- GRIT SQL Course - Day 4: JOINs & Relationships Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- BASIC INNER JOIN EXAMPLES
-- ============================================

-- Example 1: Basic customer-order relationship
SELECT c.first_name, c.last_name, o.order_id, o.order_date, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
LIMIT 5;

-- Example 2: Products in orders
SELECT p.product_name, oi.quantity, oi.unit_price, oi.total_price
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
LIMIT 5;

-- Example 3: Order details with customer info
SELECT o.order_id, o.order_date,
       c.first_name, c.last_name, c.city,
       o.total_amount, o.order_status
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
ORDER BY o.order_date DESC
LIMIT 10;

-- ============================================
-- LEFT JOIN EXAMPLES
-- ============================================

-- Example 4: All customers, with their orders (if any)
SELECT c.first_name, c.last_name, c.customer_status,
       o.order_id, o.order_date, o.total_amount
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.last_name
LIMIT 10;

-- Example 5: Customers who haven't ordered (NULL values)
SELECT c.first_name, c.last_name, c.registration_date,
       o.order_id
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- Example 6: Product stock vs sales
SELECT p.product_name, p.stock_quantity,
       COALESCE(SUM(oi.quantity), 0) as total_sold
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.stock_quantity
ORDER BY total_sold DESC
LIMIT 10;

-- ============================================
-- MULTIPLE TABLE JOINS
-- ============================================

-- Example 7: Complete order details (3-table join)
SELECT c.first_name, c.last_name,
       o.order_id, o.order_date, o.total_amount,
       p.product_name, oi.quantity, oi.unit_price
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
ORDER BY o.order_date DESC, o.order_id
LIMIT 15;

-- Example 8: Customer order summary
SELECT c.first_name, c.last_name, c.state,
       COUNT(o.order_id) as total_orders,
       SUM(o.total_amount) as total_spent,
       AVG(o.total_amount) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.state
ORDER BY total_spent DESC NULLS LAST;

-- Example 9: Product sales performance
SELECT p.product_name, p.category, p.price,
       COUNT(oi.order_item_id) as times_ordered,
       SUM(oi.quantity) as total_quantity_sold,
       SUM(oi.total_price) as total_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category, p.price
ORDER BY total_revenue DESC NULLS LAST;

-- ============================================
-- JOINS WITH WHERE CONDITIONS
-- ============================================

-- Example 10: High-value orders from California
SELECT c.first_name, c.last_name, c.city,
       o.order_id, o.order_date, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE c.state = 'CA' AND o.total_amount > 100
ORDER BY o.total_amount DESC;

-- Example 11: Electronics sales by customer
SELECT c.first_name, c.last_name,
       p.product_name, p.category,
       oi.quantity, oi.total_price,
       o.order_date
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
INNER JOIN products p ON oi.product_id = p.product_id
WHERE p.category = 'Electronics'
ORDER BY o.order_date DESC
LIMIT 10;

-- ============================================
-- ADVANCED JOIN PATTERNS
-- ============================================

-- Example 12: Customer lifetime value analysis
SELECT c.customer_id, c.first_name, c.last_name,
       c.registration_date,
       COUNT(DISTINCT o.order_id) as order_count,
       SUM(o.total_amount) as lifetime_value,
       AVG(o.total_amount) as avg_order_value,
       MAX(o.order_date) as last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.registration_date
ORDER BY lifetime_value DESC NULLS LAST;

-- Example 13: Product performance by category
SELECT p.category,
       COUNT(DISTINCT p.product_id) as products_offered,
       COUNT(oi.order_item_id) as total_sales,
       SUM(oi.total_price) as category_revenue,
       AVG(oi.total_price) as avg_sale_price
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY category_revenue DESC NULLS LAST;

-- Example 14: Monthly sales trend
SELECT strftime('%Y-%m', o.order_date) as month,
       COUNT(o.order_id) as orders_count,
       COUNT(DISTINCT o.customer_id) as unique_customers,
       SUM(o.total_amount) as monthly_revenue,
       AVG(o.total_amount) as avg_order_value
FROM orders o
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month DESC;

-- ============================================
-- COMMON JOIN PITFALLS & SOLUTIONS
-- ============================================

-- Example 15: Avoiding duplicate rows (use DISTINCT)
SELECT DISTINCT c.first_name, c.last_name, c.city
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN order_items oi ON o.order_id = oi.order_id
WHERE oi.quantity > 1
LIMIT 10;

-- Example 16: Proper NULL handling in LEFT JOIN
SELECT c.first_name, c.last_name,
       COALESCE(SUM(o.total_amount), 0) as total_spent,
       CASE WHEN SUM(o.total_amount) IS NULL THEN 'No orders' ELSE 'Has orders' END as order_status
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: Basic INNER JOIN
SELECT c.first_name, c.last_name,
       o.order_id, o.order_date, o.total_amount, o.order_status
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
LIMIT 10;

-- Exercise 2: LEFT JOIN
SELECT c.first_name, c.last_name,
       COALESCE(SUM(o.total_amount), 0) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;

-- Exercise 3: Multiple Table JOIN
SELECT p.product_name,
       oi.quantity,
       c.first_name, c.last_name
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
INNER JOIN orders o ON oi.order_id = o.order_id
INNER JOIN customers c ON o.customer_id = c.customer_id
LIMIT 15;

-- Exercise 4: JOIN with Filtering
SELECT DISTINCT p.product_name, p.category, p.price,
       oi.quantity, oi.unit_price
FROM products p
INNER JOIN order_items oi ON p.product_id = oi.product_id
ORDER BY p.product_name;

-- Exercise 5: Customer Analysis
SELECT c.first_name, c.last_name, c.state,
       COUNT(o.order_id) as order_count,
       SUM(o.total_amount) as total_spent,
       AVG(o.total_amount) as avg_order_value
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name, c.state
ORDER BY total_spent DESC NULLS LAST;

-- Exercise 6: Sales Performance
SELECT p.category,
       COUNT(DISTINCT p.product_id) as products_count,
       COUNT(oi.order_item_id) as sales_count,
       SUM(oi.total_price) as category_revenue
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.category
ORDER BY category_revenue DESC NULLS LAST;

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed query: Customer order history without duplicates
-- The issue was an unnecessary JOIN causing duplicate rows
-- Original: JOIN with order_items was not needed for customer-order history

-- Fixed version:
SELECT c.first_name, c.last_name,
       o.order_id, o.order_date, o.total_amount
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.last_name, o.order_date DESC
LIMIT 10;

-- ============================================
-- USEFUL ADDITIONAL QUERIES
-- ============================================

-- Find customers with highest spending in each state
WITH state_max AS (
    SELECT state,
           MAX(total_spent) as max_spent
    FROM (
        SELECT c.state,
               c.customer_id,
               COALESCE(SUM(o.total_amount), 0) as total_spent
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.state, c.customer_id
    ) as customer_totals
    GROUP BY state
)
SELECT c.state, c.first_name, c.last_name,
       COALESCE(SUM(o.total_amount), 0) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
INNER JOIN state_max sm ON c.state = sm.state
GROUP BY c.state, c.customer_id, c.first_name, c.last_name, sm.max_spent
HAVING COALESCE(SUM(o.total_amount), 0) = sm.max_spent
ORDER BY c.state, total_spent DESC;

-- Product recommendation based on category performance
SELECT p1.product_name as recommended_product,
       p1.category,
       p1.price,
       cat_stats.avg_category_price,
       cat_stats.category_sales
FROM products p1
INNER JOIN (
    SELECT category,
           AVG(price) as avg_category_price,
           COUNT(oi.order_item_id) as category_sales
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY category
) as cat_stats ON p1.category = cat_stats.category
WHERE p1.price <= cat_stats.avg_category_price
ORDER BY cat_stats.category_sales DESC, p1.price DESC
LIMIT 10;
