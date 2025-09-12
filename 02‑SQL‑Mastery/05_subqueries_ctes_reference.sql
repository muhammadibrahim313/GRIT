-- GRIT SQL Course - Day 5: Subqueries & CTEs Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- SCALAR SUBQUERIES
-- ============================================

-- Example 1: Find customers who spent more than average
SELECT c.first_name, c.last_name,
       COALESCE(SUM(o.total_amount), 0) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COALESCE(SUM(o.total_amount), 0) > (
    -- Subquery: Calculate average spending
    SELECT AVG(customer_total)
    FROM (
        SELECT COALESCE(SUM(o2.total_amount), 0) as customer_total
        FROM customers c2
        LEFT JOIN orders o2 ON c2.customer_id = o2.customer_id
        GROUP BY c2.customer_id
    )
)
ORDER BY total_spent DESC;

-- Example 2: Products priced above category average
SELECT p.product_name, p.category, p.price,
       ROUND(category_avg, 2) as category_avg
FROM products p
INNER JOIN (
    -- Subquery: Calculate average price per category
    SELECT category, AVG(price) as category_avg
    FROM products
    GROUP BY category
) cat_avg ON p.category = cat_avg.category
WHERE p.price > cat_avg.category_avg
ORDER BY p.category, p.price DESC;

-- ============================================
-- SUBQUERIES IN WHERE CLAUSE
-- ============================================

-- Example 3: Find products never ordered
SELECT p.product_name, p.category, p.price
FROM products p
WHERE p.product_id NOT IN (
    -- Subquery: Get all ordered product IDs
    SELECT DISTINCT product_id
    FROM order_items
)
ORDER BY p.category, p.price DESC;

-- Example 4: Customers who ordered in last 30 days
SELECT DISTINCT c.first_name, c.last_name, c.email
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_date >= (
    -- Subquery: Calculate date 30 days ago
    SELECT DATE('now', '-30 days')
)
ORDER BY c.last_name;

-- Example 5: Orders above average order value
SELECT o.order_id, c.first_name, c.last_name,
       o.order_date, o.total_amount
FROM orders o
INNER JOIN customers c ON o.customer_id = c.customer_id
WHERE o.total_amount > (
    -- Subquery: Get average order value
    SELECT AVG(total_amount) FROM orders
)
ORDER BY o.total_amount DESC;

-- ============================================
-- EXISTS AND NOT EXISTS
-- ============================================

-- Example 6: Customers who have placed orders
SELECT c.first_name, c.last_name, c.email
FROM customers c
WHERE EXISTS (
    -- Subquery: Check if customer has any orders
    SELECT 1 FROM orders o
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.last_name;

-- Example 7: Products that have been ordered
SELECT p.product_name, p.category, p.price
FROM products p
WHERE EXISTS (
    -- Subquery: Check if product appears in any order
    SELECT 1 FROM order_items oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.category, p.product_name;

-- ============================================
-- SUBQUERIES IN FROM CLAUSE
-- ============================================

-- Example 8: Customer spending summary
SELECT customer_summary.customer_name,
       customer_summary.total_orders,
       customer_summary.total_spent,
       CASE
           WHEN customer_summary.total_spent > 200 THEN 'High Value'
           WHEN customer_summary.total_spent > 100 THEN 'Medium Value'
           ELSE 'Low Value'
       END as customer_segment
FROM (
    -- Subquery: Calculate customer metrics
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           COUNT(o.order_id) as total_orders,
           COALESCE(SUM(o.total_amount), 0) as total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) customer_summary
ORDER BY customer_summary.total_spent DESC;

-- Example 9: Product sales performance
SELECT product_perf.product_name,
       product_perf.category,
       product_perf.total_sold,
       product_perf.revenue,
       CASE
           WHEN product_perf.total_sold > 10 THEN 'Best Seller'
           WHEN product_perf.total_sold > 5 THEN 'Good Seller'
           ELSE 'Slow Seller'
       END as performance
FROM (
    -- Subquery: Calculate product sales
    SELECT p.product_name, p.category,
           COALESCE(SUM(oi.quantity), 0) as total_sold,
           COALESCE(SUM(oi.total_price), 0) as revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category
) product_perf
ORDER BY product_perf.revenue DESC;

-- ============================================
-- COMMON TABLE EXPRESSIONS (CTEs)
-- ============================================

-- Example 10: Customer lifetime value with CTE
WITH customer_ltv AS (
    -- CTE: Calculate customer metrics
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           COUNT(o.order_id) as order_count,
           COALESCE(SUM(o.total_amount), 0) as lifetime_value,
           COALESCE(AVG(o.total_amount), 0) as avg_order_value,
           MAX(o.order_date) as last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
),
customer_rankings AS (
    -- CTE: Rank customers by lifetime value
    SELECT customer_name,
           lifetime_value,
           NTILE(3) OVER (ORDER BY lifetime_value DESC) as value_tier
    FROM customer_ltv
    WHERE lifetime_value > 0
)
-- Main query using CTEs
SELECT cr.customer_name,
       ROUND(cr.lifetime_value, 2) as lifetime_value,
       CASE cr.value_tier
           WHEN 1 THEN 'Platinum'
           WHEN 2 THEN 'Gold'
           WHEN 3 THEN 'Silver'
       END as customer_tier
FROM customer_rankings cr
ORDER BY cr.lifetime_value DESC;

-- Example 11: Category performance analysis
WITH category_stats AS (
    -- CTE: Calculate category metrics
    SELECT p.category,
           COUNT(DISTINCT p.product_id) as products_offered,
           COUNT(oi.order_item_id) as total_sales,
           COALESCE(SUM(oi.total_price), 0) as category_revenue,
           COALESCE(AVG(oi.total_price), 0) as avg_sale_price
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category
),
category_rankings AS (
    -- CTE: Rank categories by revenue
    SELECT category,
           category_revenue,
           RANK() OVER (ORDER BY category_revenue DESC) as revenue_rank,
           ROUND((category_revenue / SUM(category_revenue) OVER ()) * 100, 1) as revenue_pct_of_total
    FROM category_stats
)
-- Main query
SELECT cr.category,
       ROUND(cr.category_revenue, 2) as revenue,
       cr.revenue_rank,
       cr.revenue_pct_of_total || '%' as pct_of_total_revenue
FROM category_rankings cr
ORDER BY cr.category_revenue DESC;

-- ============================================
-- ADVANCED CTE PATTERNS
-- ============================================

-- Example 12: Monthly sales trend analysis
WITH monthly_sales AS (
    -- CTE: Group sales by month
    SELECT strftime('%Y-%m', o.order_date) as month,
           COUNT(o.order_id) as orders,
           SUM(o.total_amount) as revenue,
           COUNT(DISTINCT o.customer_id) as customers,
           AVG(o.total_amount) as avg_order_value
    FROM orders o
    GROUP BY strftime('%Y-%m', o.order_date)
),
sales_comparison AS (
    -- CTE: Calculate month-over-month changes
    SELECT month,
           revenue,
           LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
           ROUND(
               ((revenue - LAG(revenue) OVER (ORDER BY month)) /
                NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100, 1
           ) as growth_rate_pct
    FROM monthly_sales
)
-- Main query
SELECT sc.month,
       ROUND(sc.revenue, 2) as revenue,
       ROUND(sc.prev_month_revenue, 2) as prev_month_revenue,
       COALESCE(sc.growth_rate_pct, 0) || '%' as growth_rate
FROM sales_comparison sc
ORDER BY sc.month DESC;

-- Example 13: Customer retention analysis
WITH customer_orders AS (
    -- CTE: Get customer order history
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           o.order_id,
           o.order_date,
           o.total_amount,
           ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) as order_number
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
),
first_last_orders AS (
    -- CTE: Get first and last order dates per customer
    SELECT customer_id,
           customer_name,
           MIN(order_date) as first_order_date,
           MAX(order_date) as last_order_date,
           COUNT(*) as total_orders,
           SUM(total_amount) as lifetime_value
    FROM customer_orders
    GROUP BY customer_id, customer_name
),
customer_segments AS (
    -- CTE: Segment customers based on recency and frequency
    SELECT customer_name,
           total_orders,
           lifetime_value,
           CASE
               WHEN total_orders >= 5 THEN 'Champion'
               WHEN total_orders >= 3 THEN 'Loyal'
               WHEN total_orders >= 2 THEN 'Regular'
               WHEN total_orders >= 1 THEN 'New'
               ELSE 'Prospect'
           END as customer_type
    FROM first_last_orders
)
-- Main query
SELECT cs.customer_type,
       COUNT(*) as customer_count,
       ROUND(AVG(cs.total_orders), 1) as avg_orders,
       ROUND(AVG(cs.lifetime_value), 2) as avg_lifetime_value
FROM customer_segments cs
GROUP BY cs.customer_type
ORDER BY avg_lifetime_value DESC;

-- ============================================
-- CORRELATED SUBQUERIES
-- ============================================

-- Example 14: Products with above-average price in their category
SELECT p.product_name, p.category, p.price
FROM products p
WHERE p.price > (
    -- Correlated subquery: Average price for this product's category
    SELECT AVG(p2.price)
    FROM products p2
    WHERE p2.category = p.category
)
ORDER BY p.category, p.price DESC;

-- Example 15: Customers who spent more than their state's average
SELECT c.first_name, c.last_name, c.state,
       COALESCE(customer_spending.total_spent, 0) as customer_spent,
       ROUND(state_avg.avg_state_spending, 2) as state_average
FROM customers c
LEFT JOIN (
    SELECT customer_id, COALESCE(SUM(total_amount), 0) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_spending ON c.customer_id = customer_spending.customer_id
LEFT JOIN (
    -- Subquery: Average spending per state
    SELECT c2.state, AVG(COALESCE(customer_totals.total_spent, 0)) as avg_state_spending
    FROM customers c2
    LEFT JOIN (
        SELECT customer_id, SUM(total_amount) as total_spent
        FROM orders
        GROUP BY customer_id
    ) customer_totals ON c2.customer_id = customer_totals.customer_id
    GROUP BY c2.state
) state_avg ON c.state = state_avg.state
WHERE COALESCE(customer_spending.total_spent, 0) > COALESCE(state_avg.avg_state_spending, 0)
ORDER BY c.state, customer_spending.total_spent DESC;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: Scalar Subquery
SELECT c.first_name, c.last_name,
       COALESCE(SUM(o.total_amount), 0) as total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.first_name, c.last_name
HAVING COALESCE(SUM(o.total_amount), 0) > (
    SELECT AVG(total_amount) FROM orders
)
ORDER BY total_spent DESC;

-- Exercise 2: EXISTS Subquery
SELECT p.product_name, p.category, p.price
FROM products p
WHERE NOT EXISTS (
    SELECT 1 FROM order_items oi
    WHERE oi.product_id = p.product_id
)
ORDER BY p.category, p.price DESC;

-- Exercise 3: FROM Subquery
SELECT customer_summary.customer_name,
       customer_summary.total_orders,
       customer_summary.total_spent,
       CASE
           WHEN customer_summary.total_spent > 150 THEN 'High Value'
           WHEN customer_summary.total_spent > 75 THEN 'Medium Value'
           ELSE 'Low Value'
       END as customer_segment
FROM (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           COUNT(o.order_id) as total_orders,
           COALESCE(SUM(o.total_amount), 0) as total_spent
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name
) customer_summary
ORDER BY customer_summary.total_spent DESC;

-- Exercise 4: CTE Basic
WITH product_performance AS (
    SELECT p.category,
           COUNT(DISTINCT p.product_id) as products_count,
           COUNT(oi.order_item_id) as sales_count,
           COALESCE(SUM(oi.total_price), 0) as category_revenue
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.category
)
SELECT pp.category,
       pp.products_count,
       pp.sales_count,
       ROUND(pp.category_revenue, 2) as revenue
FROM product_performance pp
ORDER BY pp.category_revenue DESC;

-- Exercise 5: Multiple CTEs
WITH monthly_orders AS (
    SELECT strftime('%Y-%m', order_date) as month,
           COUNT(order_id) as order_count,
           SUM(total_amount) as monthly_revenue
    FROM orders
    GROUP BY strftime('%Y-%m', order_date)
),
monthly_customers AS (
    SELECT strftime('%Y-%m', o.order_date) as month,
           COUNT(DISTINCT o.customer_id) as unique_customers
    FROM orders o
    GROUP BY strftime('%Y-%m', o.order_date)
)
SELECT mo.month,
       mo.order_count,
       mc.unique_customers,
       ROUND(mo.monthly_revenue, 2) as revenue
FROM monthly_orders mo
INNER JOIN monthly_customers mc ON mo.month = mc.month
ORDER BY mo.month DESC;

-- Exercise 6: Correlated Subquery
SELECT c.first_name, c.last_name, c.state,
       COALESCE(customer_totals.total_spent, 0) as customer_spent
FROM customers c
LEFT JOIN (
    SELECT customer_id, SUM(total_amount) as total_spent
    FROM orders
    GROUP BY customer_id
) customer_totals ON c.customer_id = customer_totals.customer_id
WHERE COALESCE(customer_totals.total_spent, 0) > (
    SELECT AVG(COALESCE(ct2.total_spent, 0))
    FROM customers c2
    LEFT JOIN (
        SELECT customer_id, SUM(total_amount) as total_spent
        FROM orders
        GROUP BY customer_id
    ) ct2 ON c2.customer_id = ct2.customer_id
    WHERE c2.state = c.state
)
ORDER BY c.state, customer_totals.total_spent DESC;

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed query: Products that outsold the average sales in their category
-- The issue was missing correlation in the subquery

-- Fixed version:
SELECT p.product_name, p.category,
       COALESCE(SUM(oi.quantity), 0) as product_sales
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
GROUP BY p.product_id, p.product_name, p.category
HAVING COALESCE(SUM(oi.quantity), 0) > (
    -- Correlated subquery: Average sales for products in the same category
    SELECT AVG(COALESCE(SUM(oi2.quantity), 0))
    FROM products p2
    LEFT JOIN order_items oi2 ON p2.product_id = oi2.product_id
    WHERE p2.category = p.category
      AND p2.product_id != p.product_id  -- Exclude the current product
    GROUP BY p2.product_id
)
ORDER BY product_sales DESC;

-- ============================================
-- USEFUL ADDITIONAL QUERIES
-- ============================================

-- Find customers with no orders using CTE
WITH active_customers AS (
    SELECT customer_id
    FROM orders
    GROUP BY customer_id
)
SELECT c.first_name, c.last_name, c.registration_date
FROM customers c
LEFT JOIN active_customers ac ON c.customer_id = ac.customer_id
WHERE ac.customer_id IS NULL;

-- Complex product analysis with multiple CTEs
WITH product_metrics AS (
    SELECT p.product_id, p.product_name, p.category, p.price,
           COALESCE(SUM(oi.quantity), 0) as units_sold,
           COALESCE(SUM(oi.total_price), 0) as revenue,
           COALESCE(AVG(pr.rating), 0) as avg_rating
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN product_reviews pr ON p.product_id = pr.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.price
),
category_averages AS (
    SELECT category,
           AVG(units_sold) as avg_category_sales,
           AVG(avg_rating) as avg_category_rating
    FROM product_metrics
    GROUP BY category
)
SELECT pm.product_name,
       pm.category,
       pm.units_sold,
       ROUND(pm.revenue, 2) as revenue,
       ROUND(pm.avg_rating, 1) as rating,
       ROUND(ca.avg_category_sales, 1) as category_avg_sales,
       ROUND(ca.avg_category_rating, 1) as category_avg_rating,
       CASE
           WHEN pm.units_sold > ca.avg_category_sales AND pm.avg_rating > ca.avg_category_rating THEN 'Star Product'
           WHEN pm.units_sold > ca.avg_category_sales THEN 'Volume Leader'
           WHEN pm.avg_rating > ca.avg_category_rating THEN 'Quality Leader'
           ELSE 'Needs Attention'
       END as performance_status
FROM product_metrics pm
INNER JOIN category_averages ca ON pm.category = ca.category
ORDER BY pm.revenue DESC;

-- Recursive CTE for organizational hierarchy (conceptual example)
-- Note: SQLite supports recursive CTEs with RECURSIVE keyword
-- This is a conceptual example - would need proper table structure
/*
WITH RECURSIVE employee_hierarchy AS (
    -- Base case: Top-level employees
    SELECT employee_id, manager_id, employee_name, 1 as level
    FROM employees
    WHERE manager_id IS NULL

    UNION ALL

    -- Recursive case: Employees reporting to the above
    SELECT e.employee_id, e.manager_id, e.employee_name, eh.level + 1
    FROM employees e
    INNER JOIN employee_hierarchy eh ON e.manager_id = eh.employee_id
)
SELECT * FROM employee_hierarchy ORDER BY level, employee_name;
*/

-- Complex customer segmentation with CTEs
WITH customer_orders AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           c.state,
           COUNT(o.order_id) as order_count,
           SUM(o.total_amount) as total_spent,
           AVG(o.total_amount) as avg_order_value,
           MAX(o.order_date) as last_order_date,
           MIN(o.order_date) as first_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.state
),
customer_segments AS (
    SELECT *,
           ROUND(JULIANDAY('now') - JULIANDAY(last_order_date), 0) as days_since_last_order,
           CASE
               WHEN order_count = 0 THEN 'Prospect'
               WHEN total_spent > 300 THEN 'VIP'
               WHEN total_spent > 150 THEN 'High Value'
               WHEN total_spent > 50 THEN 'Regular'
               WHEN days_since_last_order > 180 THEN 'At Risk'
               ELSE 'Active'
           END as segment
    FROM customer_orders
)
SELECT segment,
       COUNT(*) as customer_count,
       ROUND(AVG(total_spent), 2) as avg_lifetime_value,
       ROUND(AVG(order_count), 1) as avg_orders,
       ROUND(AVG(days_since_last_order), 0) as avg_days_since_order
FROM customer_segments
GROUP BY segment
ORDER BY avg_lifetime_value DESC;
