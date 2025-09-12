-- GRIT SQL Course - Day 7: SQL Project Reference
-- Complete SQL analytics project with business intelligence queries

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- 1. EXECUTIVE SUMMARY DASHBOARD
-- ============================================

-- Executive Summary: Key Business Metrics
WITH business_metrics AS (
    SELECT
        COUNT(DISTINCT o.order_id) as total_orders,
        COUNT(DISTINCT o.customer_id) as total_customers,
        COUNT(DISTINCT oi.product_id) as products_sold,
        SUM(o.total_amount) as total_revenue,
        AVG(o.total_amount) as avg_order_value,
        MAX(o.order_date) as last_order_date,
        MIN(o.order_date) as first_order_date,
        ROUND(
            JULIANDAY(MAX(o.order_date)) - JULIANDAY(MIN(o.order_date))
        ) as business_days
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
),
monthly_revenue AS (
    SELECT strftime('%Y-%m', order_date) as month,
           SUM(total_amount) as monthly_rev
    FROM orders
    GROUP BY strftime('%Y-%m', order_date)
)
SELECT
    bm.total_orders,
    bm.total_customers,
    bm.products_sold,
    ROUND(bm.total_revenue, 2) as total_revenue,
    ROUND(bm.avg_order_value, 2) as avg_order_value,
    ROUND(bm.total_revenue / bm.business_days, 2) as daily_avg_revenue,
    ROUND(AVG(mr.monthly_rev), 2) as avg_monthly_revenue,
    ROUND(
        (MAX(mr.monthly_rev) - MIN(mr.monthly_rev)) / AVG(mr.monthly_rev) * 100, 1
    ) as revenue_volatility_pct
FROM business_metrics bm
CROSS JOIN monthly_revenue mr
GROUP BY bm.total_orders, bm.total_customers, bm.products_sold,
         bm.total_revenue, bm.avg_order_value, bm.daily_avg_revenue, bm.business_days;

-- ============================================
-- 2. REVENUE ANALYSIS & TRENDS
-- ============================================

-- Monthly Revenue Analysis with Growth Rates
WITH monthly_stats AS (
    SELECT strftime('%Y-%m', o.order_date) as month,
           COUNT(o.order_id) as orders_count,
           COUNT(DISTINCT o.customer_id) as customers_count,
           SUM(o.total_amount) as revenue,
           AVG(o.total_amount) as avg_order_value,
           SUM(oi.quantity) as items_sold
    FROM orders o
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    GROUP BY strftime('%Y-%m', o.order_date)
),
revenue_trends AS (
    SELECT month,
           revenue,
           LAG(revenue) OVER (ORDER BY month) as prev_month_revenue,
           ROUND(
               ((revenue - LAG(revenue) OVER (ORDER BY month)) /
                NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100, 1
           ) as growth_rate_pct
    FROM monthly_stats
)
SELECT ms.month,
       ms.orders_count,
       ms.customers_count,
       ROUND(ms.revenue, 2) as revenue,
       ROUND(ms.avg_order_value, 2) as avg_order_value,
       ms.items_sold,
       ROUND(rt.prev_month_revenue, 2) as prev_month_revenue,
       rt.growth_rate_pct || '%' as growth_rate
FROM monthly_stats ms
LEFT JOIN revenue_trends rt ON ms.month = rt.month
ORDER BY ms.month DESC;

-- Category Performance Analysis
WITH category_performance AS (
    SELECT p.category,
           COUNT(DISTINCT p.product_id) as products_offered,
           COUNT(oi.order_item_id) as items_sold,
           SUM(oi.total_price) as category_revenue,
           AVG(oi.total_price) as avg_item_price,
           COUNT(DISTINCT o.customer_id) as unique_customers,
           COUNT(oi.order_item_id) * 1.0 / COUNT(DISTINCT p.product_id) as avg_sales_per_product
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    GROUP BY p.category
),
category_rankings AS (
    SELECT category,
           category_revenue,
           RANK() OVER (ORDER BY category_revenue DESC) as revenue_rank,
           ROUND((category_revenue / SUM(category_revenue) OVER ()) * 100, 1) as revenue_pct_of_total
    FROM category_performance
)
SELECT cp.category,
       cp.products_offered,
       cp.items_sold,
       ROUND(cp.category_revenue, 2) as revenue,
       ROUND(cp.avg_item_price, 2) as avg_item_price,
       cp.unique_customers,
       ROUND(cp.avg_sales_per_product, 1) as avg_sales_per_product,
       cr.revenue_rank,
       cr.revenue_pct_of_total || '%' as pct_of_total_revenue
FROM category_performance cp
INNER JOIN category_rankings cr ON cp.category = cr.category
ORDER BY cp.category_revenue DESC;

-- ============================================
-- 3. CUSTOMER ANALYSIS & SEGMENTATION
-- ============================================

-- Customer Lifetime Value & Segmentation
WITH customer_ltv AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           c.state,
           c.registration_date,
           COUNT(o.order_id) as order_count,
           COALESCE(SUM(o.total_amount), 0) as lifetime_value,
           COALESCE(AVG(o.total_amount), 0) as avg_order_value,
           MAX(o.order_date) as last_order_date,
           ROUND(
               JULIANDAY('now') - JULIANDAY(MAX(o.order_date))
           ) as days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.state, c.registration_date
),
customer_segments AS (
    SELECT customer_name,
           lifetime_value,
           order_count,
           days_since_last_order,
           CASE
               WHEN lifetime_value >= 300 THEN 'VIP'
               WHEN lifetime_value >= 150 THEN 'High Value'
               WHEN lifetime_value >= 50 THEN 'Regular'
               WHEN order_count > 0 THEN 'New'
               ELSE 'Prospect'
           END as customer_segment,
           CASE
               WHEN days_since_last_order <= 30 THEN 'Active'
               WHEN days_since_last_order <= 90 THEN 'At Risk'
               WHEN days_since_last_order <= 180 THEN 'Lapsed'
               ELSE 'Lost'
           END as engagement_status
    FROM customer_ltv
)
SELECT cs.customer_segment,
       cs.engagement_status,
       COUNT(*) as customer_count,
       ROUND(AVG(cs.lifetime_value), 2) as avg_lifetime_value,
       ROUND(AVG(cs.order_count), 1) as avg_orders,
       ROUND(AVG(cs.days_since_last_order), 0) as avg_days_since_order,
       ROUND(SUM(cs.lifetime_value), 2) as segment_revenue
FROM customer_segments cs
GROUP BY cs.customer_segment, cs.engagement_status
ORDER BY segment_revenue DESC;

-- Top Customers Analysis
WITH top_customers AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           c.state,
           COUNT(o.order_id) as order_count,
           COALESCE(SUM(o.total_amount), 0) as total_spent,
           COALESCE(AVG(o.total_amount), 0) as avg_order_value,
           MAX(o.order_date) as last_order_date,
           GROUP_CONCAT(DISTINCT p.category) as preferred_categories
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    LEFT JOIN order_items oi ON o.order_id = oi.order_id
    LEFT JOIN products p ON oi.product_id = p.product_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.state
    HAVING total_spent > 0
    ORDER BY total_spent DESC
    LIMIT 5
)
SELECT tc.customer_name,
       tc.state,
       tc.order_count,
       ROUND(tc.total_spent, 2) as total_spent,
       ROUND(tc.avg_order_value, 2) as avg_order_value,
       tc.last_order_date,
       tc.preferred_categories,
       ROUND(tc.total_spent / SUM(tc.total_spent) OVER () * 100, 1) || '%' as pct_of_top5_revenue
FROM top_customers tc
ORDER BY tc.total_spent DESC;

-- ============================================
-- 4. PRODUCT PERFORMANCE ANALYSIS
-- ============================================

-- Product Performance Analysis
WITH product_sales AS (
    SELECT p.product_id,
           p.product_name,
           p.category,
           p.price,
           p.stock_quantity,
           COALESCE(SUM(oi.quantity), 0) as units_sold,
           COALESCE(SUM(oi.total_price), 0) as revenue,
           COALESCE(AVG(pr.rating), 0) as avg_rating,
           COUNT(pr.review_id) as review_count,
           COUNT(DISTINCT o.customer_id) as unique_buyers
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN product_reviews pr ON p.product_id = pr.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.price, p.stock_quantity
),
product_metrics AS (
    SELECT ps.*,
           CASE
               WHEN units_sold = 0 THEN 'No Sales'
               WHEN units_sold <= 2 THEN 'Slow Seller'
               WHEN units_sold <= 5 THEN 'Moderate Seller'
               ELSE 'Best Seller'
           END as performance_category,
           ROUND(revenue / NULLIF(price * units_sold, 0) * 100, 1) as discount_impact_pct,
           ROUND(units_sold * 1.0 / NULLIF(unique_buyers, 0), 2) as avg_units_per_buyer
    FROM product_sales ps
)
SELECT pm.product_name,
       pm.category,
       ROUND(pm.price, 2) as price,
       pm.units_sold,
       ROUND(pm.revenue, 2) as revenue,
       pm.stock_quantity,
       ROUND(pm.avg_rating, 1) as avg_rating,
       pm.review_count,
       pm.performance_category,
       pm.avg_units_per_buyer
FROM product_metrics pm
ORDER BY pm.revenue DESC, pm.units_sold DESC;

-- Product Recommendations
WITH product_insights AS (
    SELECT p.product_name,
           p.category,
           p.price,
           p.stock_quantity,
           COALESCE(SUM(oi.quantity), 0) as units_sold,
           COALESCE(SUM(oi.total_price), 0) as revenue,
           COALESCE(AVG(pr.rating), 0) as avg_rating,
           COUNT(pr.review_id) as review_count,
           CASE
               WHEN COALESCE(SUM(oi.quantity), 0) = 0 AND p.stock_quantity > 0 THEN 'Restock & Promote'
               WHEN COALESCE(SUM(oi.quantity), 0) <= 2 AND p.stock_quantity <= 15 THEN 'Low Stock - Reorder'
               WHEN COALESCE(AVG(pr.rating), 0) >= 4.5 THEN 'High Performer - Expand'
               WHEN COALESCE(AVG(pr.rating), 0) <= 2.5 AND COALESCE(SUM(oi.quantity), 0) > 0 THEN 'Quality Issues - Review'
               WHEN p.stock_quantity <= 10 AND COALESCE(SUM(oi.quantity), 0) > 5 THEN 'Fast Mover - Stock Up'
               ELSE 'Monitor'
           END as recommendation
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    LEFT JOIN product_reviews pr ON p.product_id = pr.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.price, p.stock_quantity
)
SELECT pi.product_name,
       pi.category,
       ROUND(pi.price, 2) as price,
       pi.stock_quantity,
       pi.units_sold,
       ROUND(pi.revenue, 2) as revenue,
       ROUND(pi.avg_rating, 1) as avg_rating,
       pi.recommendation
FROM product_insights pi
ORDER BY
    CASE pi.recommendation
        WHEN 'Restock & Promote' THEN 1
        WHEN 'Low Stock - Reorder' THEN 2
        WHEN 'High Performer - Expand' THEN 3
        WHEN 'Fast Mover - Stock Up' THEN 4
        WHEN 'Quality Issues - Review' THEN 5
        ELSE 6
    END,
    pi.revenue DESC;

-- ============================================
-- 5. SALES FORECASTING & TREND ANALYSIS
-- ============================================

-- Sales Forecasting & Seasonal Analysis
WITH monthly_patterns AS (
    SELECT strftime('%Y-%m', o.order_date) as month,
           strftime('%m', o.order_date) as month_num,
           COUNT(o.order_id) as orders,
           SUM(o.total_amount) as revenue,
           COUNT(DISTINCT o.customer_id) as customers,
           AVG(o.total_amount) as avg_order_value
    FROM orders o
    GROUP BY strftime('%Y-%m', o.order_date), strftime('%m', o.order_date)
),
seasonal_analysis AS (
    SELECT month_num,
           AVG(orders) as avg_orders_per_month,
           AVG(revenue) as avg_revenue_per_month,
           AVG(customers) as avg_customers_per_month,
           COUNT(*) as months_with_data,
           ROUND(STDEV(orders), 1) as orders_volatility,
           ROUND(STDEV(revenue), 2) as revenue_volatility
    FROM monthly_patterns
    GROUP BY month_num
),
growth_trends AS (
    SELECT mp.month,
           mp.orders,
           mp.revenue,
           LAG(mp.orders) OVER (ORDER BY mp.month) as prev_orders,
           LAG(mp.revenue) OVER (ORDER BY mp.month) as prev_revenue,
           ROUND(
               ((mp.orders - LAG(mp.orders) OVER (ORDER BY mp.month)) /
                NULLIF(LAG(mp.orders) OVER (ORDER BY mp.month), 0)) * 100, 1
           ) as orders_growth_pct
    FROM monthly_patterns mp
)
SELECT sa.month_num as month,
       ROUND(sa.avg_orders_per_month, 1) as avg_orders,
       ROUND(sa.avg_revenue_per_month, 2) as avg_revenue,
       ROUND(sa.avg_customers_per_month, 1) as avg_customers,
       sa.months_with_data,
       ROUND(sa.orders_volatility, 1) as orders_volatility,
       ROUND(sa.revenue_volatility, 2) as revenue_volatility,
       CASE
           WHEN sa.avg_revenue_per_month > (SELECT AVG(revenue) FROM monthly_patterns) THEN 'Above Average'
           ELSE 'Below Average'
       END as seasonal_performance
FROM seasonal_analysis sa
ORDER BY sa.month_num;

-- ============================================
-- 6. BUSINESS INTELLIGENCE KPIs
-- ============================================

-- Business Intelligence KPIs
WITH kpi_metrics AS (
    -- Customer Metrics
    SELECT 'Customer Metrics' as category,
           'Total Customers' as metric,
           CAST(COUNT(*) as TEXT) as value,
           'count' as unit
    FROM customers
    UNION ALL
    SELECT 'Customer Metrics' as category,
           'Active Customers' as metric,
           CAST(COUNT(*) as TEXT) as value,
           'count' as unit
    FROM customers WHERE customer_status = 'active'
    UNION ALL
    SELECT 'Customer Metrics' as category,
           'Avg Customer Lifetime Value' as metric,
           ROUND(AVG(customer_total), 2) as value,
           'currency' as unit
    FROM (
        SELECT c.customer_id, COALESCE(SUM(o.total_amount), 0) as customer_total
        FROM customers c LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id
    )

    UNION ALL
    -- Sales Metrics
    SELECT 'Sales Metrics' as category,
           'Total Revenue' as metric,
           ROUND(SUM(total_amount), 2) as value,
           'currency' as unit
    FROM orders
    UNION ALL
    SELECT 'Sales Metrics' as category,
           'Average Order Value' as metric,
           ROUND(AVG(total_amount), 2) as value,
           'currency' as unit
    FROM orders
    UNION ALL
    SELECT 'Sales Metrics' as category,
           'Total Orders' as metric,
           CAST(COUNT(*) as TEXT) as value,
           'count' as unit
    FROM orders

    UNION ALL
    -- Product Metrics
    SELECT 'Product Metrics' as category,
           'Total Products' as metric,
           CAST(COUNT(*) as TEXT) as value,
           'count' as unit
    FROM products
    UNION ALL
    SELECT 'Product Metrics' as category,
           'Products Sold' as metric,
           CAST(COUNT(DISTINCT oi.product_id) as TEXT) as value,
           'count' as unit
    FROM order_items oi
    UNION ALL
    SELECT 'Product Metrics' as category,
           'Average Product Rating' as metric,
           ROUND(AVG(rating), 1) as value,
           'rating' as unit
    FROM product_reviews
)
SELECT category,
       metric,
       value,
       unit,
       CASE
           WHEN unit = 'currency' AND CAST(REPLACE(value, '$', '') as DECIMAL) > 1000 THEN '🚀 High'
           WHEN unit = 'currency' AND CAST(REPLACE(value, '$', '') as DECIMAL) > 500 THEN '📈 Good'
           WHEN unit = 'count' AND CAST(value as INTEGER) > 20 THEN '📊 Strong'
           WHEN unit = 'rating' AND CAST(value as DECIMAL) > 4.0 THEN '⭐ Excellent'
           ELSE '🔍 Monitor'
       END as performance_indicator
FROM kpi_metrics
ORDER BY
    CASE category
        WHEN 'Sales Metrics' THEN 1
        WHEN 'Customer Metrics' THEN 2
        WHEN 'Product Metrics' THEN 3
    END,
    metric;

-- ============================================
-- 7. EXECUTIVE RECOMMENDATIONS
-- ============================================

-- Executive Recommendations Report
WITH recommendations AS (
    SELECT 'Revenue Growth' as category,
           'Focus on High-Value Categories' as recommendation,
           'Electronics and Sports categories drive 80% of revenue. Invest marketing budget here.' as rationale,
           'High' as priority,
           '$50K' as estimated_impact
    UNION ALL
    SELECT 'Customer Retention' as category,
           'Target At-Risk Customers' as recommendation,
           '45% of customers haven\\'t ordered in 90+ days. Implement re-engagement campaign.' as rationale,
           'High' as priority,
           '$25K' as estimated_impact
    UNION ALL
    SELECT 'Product Strategy' as category,
           'Expand Best-Selling Products' as recommendation,
           'Top 3 products generate 60% of revenue. Increase stock and marketing for these.' as rationale,
           'Medium' as priority,
           '$30K' as estimated_impact
    UNION ALL
    SELECT 'Inventory Management' as category,
           'Optimize Stock Levels' as recommendation,
           'Several products have low stock while others gather dust. Implement demand forecasting.' as rationale,
           'Medium' as priority,
           '$15K' as estimated_impact
    UNION ALL
    SELECT 'Customer Experience' as category,
           'Implement Loyalty Program' as recommendation,
           'Top 20% of customers drive 80% of revenue. Reward and retain high-value customers.' as rationale,
           'High' as priority,
           '$40K' as estimated_impact
    UNION ALL
    SELECT 'Marketing Strategy' as category,
           'Target Regional Preferences' as recommendation,
           'California customers prefer Electronics, Texas prefers Sports. Personalize marketing.' as rationale,
           'Low' as priority,
           '$20K' as estimated_impact
)
SELECT category,
       recommendation,
       rationale,
       priority,
       estimated_impact,
       CASE priority
           WHEN 'High' THEN '🔴 Immediate Action'
           WHEN 'Medium' THEN '🟡 Plan for Q2'
           WHEN 'Low' THEN '🟢 Monitor & Evaluate'
       END as action_timeline
FROM recommendations
ORDER BY
    CASE priority
        WHEN 'High' THEN 1
        WHEN 'Medium' THEN 2
        WHEN 'Low' THEN 3
    END,
    estimated_impact DESC;

-- ============================================
-- ADDITIONAL BUSINESS INTELLIGENCE QUERIES
-- ============================================

-- Customer Churn Analysis
WITH customer_activity AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           c.registration_date,
           MAX(o.order_date) as last_order_date,
           COUNT(o.order_id) as total_orders,
           SUM(o.total_amount) as lifetime_value,
           ROUND(JULIANDAY('now') - JULIANDAY(MAX(o.order_date)), 0) as days_since_last_order
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.first_name, c.last_name, c.registration_date
),
churn_risk AS (
    SELECT customer_name,
           total_orders,
           lifetime_value,
           days_since_last_order,
           CASE
               WHEN days_since_last_order > 180 THEN 'High Risk'
               WHEN days_since_last_order > 90 THEN 'Medium Risk'
               WHEN days_since_last_order > 30 THEN 'Low Risk'
               ELSE 'Active'
           END as churn_risk,
           CASE
               WHEN lifetime_value > 200 THEN 'High Value'
               WHEN lifetime_value > 100 THEN 'Medium Value'
               ELSE 'Low Value'
           END as customer_value
    FROM customer_activity
    WHERE total_orders > 0
)
SELECT churn_risk,
       customer_value,
       COUNT(*) as customer_count,
       ROUND(AVG(lifetime_value), 2) as avg_lifetime_value,
       ROUND(AVG(days_since_last_order), 0) as avg_days_since_order
FROM churn_risk
GROUP BY churn_risk, customer_value
ORDER BY
    CASE churn_risk
        WHEN 'High Risk' THEN 1
        WHEN 'Medium Risk' THEN 2
        WHEN 'Low Risk' THEN 3
        ELSE 4
    END,
    CASE customer_value
        WHEN 'High Value' THEN 1
        WHEN 'Medium Value' THEN 2
        ELSE 3
    END;

-- Product Cross-Sell Analysis
WITH product_pairs AS (
    SELECT o.order_id,
           p1.product_name as product_1,
           p2.product_name as product_2,
           p1.category as category_1,
           p2.category as category_2
    FROM order_items oi1
    INNER JOIN order_items oi2 ON oi1.order_id = oi2.order_id AND oi1.product_id < oi2.product_id
    INNER JOIN products p1 ON oi1.product_id = p1.product_id
    INNER JOIN products p2 ON oi2.product_id = p2.product_id
    INNER JOIN orders o ON oi1.order_id = o.order_id
),
pair_frequency AS (
    SELECT product_1,
           product_2,
           category_1,
           category_2,
           COUNT(*) as times_bought_together,
           COUNT(DISTINCT order_id) as unique_orders
    FROM product_pairs
    GROUP BY product_1, product_2, category_1, category_2
)
SELECT product_1,
       product_2,
       category_1 || ' + ' || category_2 as category_combo,
       times_bought_together,
       unique_orders,
       ROUND(times_bought_together * 1.0 / unique_orders, 2) as avg_quantity_per_order
FROM pair_frequency
ORDER BY times_bought_together DESC
LIMIT 10;

-- Geographic Performance Analysis
WITH state_performance AS (
    SELECT c.state,
           COUNT(DISTINCT c.customer_id) as total_customers,
           COUNT(DISTINCT o.customer_id) as active_customers,
           COUNT(o.order_id) as total_orders,
           SUM(o.total_amount) as total_revenue,
           AVG(o.total_amount) as avg_order_value
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.state
),
state_rankings AS (
    SELECT state,
           total_revenue,
           RANK() OVER (ORDER BY total_revenue DESC) as revenue_rank,
           ROUND(total_revenue / SUM(total_revenue) OVER () * 100, 1) as revenue_pct
    FROM state_performance
)
SELECT sp.state,
       sp.total_customers,
       sp.active_customers,
       ROUND(sp.active_customers * 100.0 / sp.total_customers, 1) || '%' as activation_rate,
       sp.total_orders,
       ROUND(sp.total_revenue, 2) as revenue,
       ROUND(sp.avg_order_value, 2) as avg_order_value,
       sr.revenue_rank,
       sr.revenue_pct || '%' as pct_of_total_revenue
FROM state_performance sp
INNER JOIN state_rankings sr ON sp.state = sr.state
ORDER BY sp.total_revenue DESC;

-- Inventory Turnover Analysis
WITH inventory_metrics AS (
    SELECT p.product_id,
           p.product_name,
           p.category,
           p.stock_quantity,
           p.price,
           COALESCE(SUM(oi.quantity), 0) as units_sold,
           COALESCE(SUM(oi.total_price), 0) as sales_value,
           ROUND(p.price * p.stock_quantity, 2) as inventory_value,
           CASE
               WHEN COALESCE(SUM(oi.quantity), 0) = 0 THEN 0
               ELSE ROUND(p.stock_quantity * 1.0 / SUM(oi.quantity), 1)
           END as months_of_inventory
    FROM products p
    LEFT JOIN order_items oi ON p.product_id = oi.product_id
    GROUP BY p.product_id, p.product_name, p.category, p.stock_quantity, p.price
)
SELECT product_name,
       category,
       stock_quantity,
       units_sold,
       ROUND(inventory_value, 2) as inventory_value,
       ROUND(sales_value, 2) as sales_value,
       months_of_inventory,
       CASE
           WHEN months_of_inventory > 12 THEN 'Overstocked'
           WHEN months_of_inventory > 6 THEN 'Well Stocked'
           WHEN months_of_inventory > 2 THEN 'Normal'
           WHEN months_of_inventory > 0 THEN 'Low Stock'
           ELSE 'Out of Stock'
       END as stock_status
FROM inventory_metrics
ORDER BY units_sold DESC, inventory_value DESC;

-- Customer Cohort Analysis (Simplified)
WITH customer_cohorts AS (
    SELECT c.customer_id,
           c.first_name || ' ' || c.last_name as customer_name,
           strftime('%Y-%m', c.registration_date) as cohort_month,
           strftime('%Y-%m', o.order_date) as order_month,
           o.total_amount,
           ROW_NUMBER() OVER (PARTITION BY c.customer_id ORDER BY o.order_date) as order_sequence
    FROM customers c
    INNER JOIN orders o ON c.customer_id = o.customer_id
),
cohort_metrics AS (
    SELECT cohort_month,
           order_month,
           COUNT(DISTINCT customer_id) as active_customers,
           SUM(total_amount) as cohort_revenue,
           AVG(total_amount) as avg_order_value
    FROM customer_cohorts
    GROUP BY cohort_month, order_month
)
SELECT cohort_month,
       order_month,
       active_customers,
       ROUND(cohort_revenue, 2) as revenue,
       ROUND(avg_order_value, 2) as avg_order_value,
       ROUND(JULIANDAY(order_month || '-01') - JULIANDAY(cohort_month || '-01'), 0) / 30 as months_since_acquisition
FROM cohort_metrics
ORDER BY cohort_month, order_month;

-- ============================================
-- EXECUTIVE DASHBOARD SUMMARY
-- ============================================

-- Complete Business Overview (One Query)
WITH business_overview AS (
    -- Revenue Metrics
    SELECT 'Revenue' as metric_type,
           'Total Revenue' as metric_name,
           ROUND(SUM(total_amount), 2) as value,
           '$' as unit
    FROM orders

    UNION ALL
    SELECT 'Revenue' as metric_type,
           'Average Order Value' as metric_name,
           ROUND(AVG(total_amount), 2) as value,
           '$' as unit
    FROM orders

    UNION ALL
    SELECT 'Revenue' as metric_type,
           'Monthly Growth Rate' as metric_name,
           ROUND(AVG(growth_rate), 2) as value,
           '%' as unit
    FROM (
        SELECT ((revenue - LAG(revenue) OVER (ORDER BY month)) / NULLIF(LAG(revenue) OVER (ORDER BY month), 0)) * 100 as growth_rate
        FROM (SELECT strftime('%Y-%m', order_date) as month, SUM(total_amount) as revenue FROM orders GROUP BY month)
    )

    UNION ALL
    -- Customer Metrics
    SELECT 'Customers' as metric_type,
           'Total Customers' as metric_name,
           CAST(COUNT(*) as REAL) as value,
           '' as unit
    FROM customers

    UNION ALL
    SELECT 'Customers' as metric_type,
           'Active Customers' as metric_name,
           CAST(COUNT(DISTINCT customer_id) as REAL) as value,
           '' as unit
    FROM orders

    UNION ALL
    SELECT 'Customers' as metric_type,
           'Customer Retention Rate' as metric_name,
           ROUND(COUNT(DISTINCT customer_id) * 100.0 / (SELECT COUNT(*) FROM customers), 1) as value,
           '%' as unit
    FROM orders

    UNION ALL
    -- Product Metrics
    SELECT 'Products' as metric_type,
           'Total Products' as metric_name,
           CAST(COUNT(*) as REAL) as value,
           '' as unit
    FROM products

    UNION ALL
    SELECT 'Products' as metric_type,
           'Products with Sales' as metric_name,
           CAST(COUNT(DISTINCT product_id) as REAL) as value,
           '' as unit
    FROM order_items

    UNION ALL
    SELECT 'Products' as metric_type,
           'Average Product Rating' as metric_name,
           ROUND(AVG(rating), 1) as value,
           '/5' as unit
    FROM product_reviews
)
SELECT metric_type,
       metric_name,
       value || unit as metric_value,
       CASE
           WHEN metric_type = 'Revenue' AND value > 1000 THEN '🟢 Excellent'
           WHEN metric_type = 'Revenue' AND value > 500 THEN '🟡 Good'
           WHEN metric_type = 'Customers' AND value > 5 THEN '🟢 Strong'
           WHEN metric_type = 'Products' AND value > 4 THEN '🟢 Good'
           ELSE '🟡 Monitor'
       END as status
FROM business_overview
ORDER BY
    CASE metric_type
        WHEN 'Revenue' THEN 1
        WHEN 'Customers' THEN 2
        WHEN 'Products' THEN 3
    END,
    metric_name;
