-- GRIT SQL Course - Day 6: Data Manipulation Reference
-- All queries from the notebook in one place for reference

-- ============================================
-- SETUP: Connect to database (in Jupyter)
-- ============================================
-- %load_ext sql
-- %sql sqlite:///ecommerce.db

-- ============================================
-- CREATE TABLE EXAMPLES
-- ============================================

-- Example 1: Create a reviews table
CREATE TABLE product_reviews (
    review_id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    rating INTEGER CHECK(rating >= 1 AND rating <= 5),
    review_text TEXT,
    review_date DATE DEFAULT CURRENT_DATE,
    helpful_votes INTEGER DEFAULT 0,
    verified_purchase BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- Example 2: Create an inventory tracking table
CREATE TABLE inventory_log (
    log_id INTEGER PRIMARY KEY,
    product_id INTEGER NOT NULL,
    change_type TEXT CHECK(change_type IN ('restock', 'sale', 'adjustment', 'return')),
    quantity_change INTEGER NOT NULL,
    previous_stock INTEGER NOT NULL,
    new_stock INTEGER NOT NULL,
    change_reason TEXT,
    changed_by TEXT DEFAULT 'system',
    change_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- Example 3: Create a customer preferences table
CREATE TABLE customer_preferences (
    preference_id INTEGER PRIMARY KEY,
    customer_id INTEGER NOT NULL UNIQUE,
    email_marketing BOOLEAN DEFAULT TRUE,
    sms_notifications BOOLEAN DEFAULT FALSE,
    favorite_category TEXT,
    preferred_contact_time TEXT CHECK(preferred_contact_time IN ('morning', 'afternoon', 'evening')),
    loyalty_tier TEXT DEFAULT 'bronze' CHECK(loyalty_tier IN ('bronze', 'silver', 'gold', 'platinum')),
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- ============================================
-- INSERT EXAMPLES
-- ============================================

-- Example 4: Insert a product review
INSERT INTO product_reviews (product_id, customer_id, rating, review_text, verified_purchase)
VALUES (1, 1, 5, 'Amazing wireless headphones! Great sound quality and comfortable for long listening sessions.', TRUE);

-- Example 5: Insert multiple reviews at once
INSERT INTO product_reviews (product_id, customer_id, rating, review_text, verified_purchase) VALUES
(2, 2, 4, 'Good gaming mouse with RGB lighting. Could be more responsive.', TRUE),
(3, 3, 5, 'Perfect coffee maker! Brews excellent coffee every morning.', TRUE),
(4, 4, 4, 'Great running shoes. Very comfortable and good support.', TRUE),
(6, 5, 5, 'Smart watch is fantastic! Tracks everything I need and looks great.', TRUE);

-- Example 6: Insert customer preferences
INSERT INTO customer_preferences (customer_id, email_marketing, sms_notifications, favorite_category, preferred_contact_time, loyalty_tier) VALUES
(1, TRUE, FALSE, 'Electronics', 'morning', 'gold'),
(2, TRUE, TRUE, 'Sports', 'afternoon', 'silver'),
(3, FALSE, FALSE, 'Appliances', 'evening', 'bronze'),
(4, TRUE, TRUE, 'Sports', 'morning', 'silver');

-- Example 7: Insert with subquery (copy active customers to preferences)
INSERT INTO customer_preferences (customer_id, email_marketing, loyalty_tier)
SELECT customer_id, TRUE, 'bronze'
FROM customers
WHERE customer_id NOT IN (SELECT customer_id FROM customer_preferences);

-- ============================================
-- UPDATE EXAMPLES
-- ============================================

-- Example 8: Update product stock
UPDATE products
SET stock_quantity = stock_quantity + 10
WHERE product_id = 1;

-- Example 9: Update customer status based on spending
UPDATE customer_preferences
SET loyalty_tier = 'gold'
WHERE customer_id IN (
    SELECT c.customer_id
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id
    HAVING COALESCE(SUM(o.total_amount), 0) > 200
);

-- Example 10: Update multiple fields with conditions
UPDATE customer_preferences
SET sms_notifications = TRUE,
    preferred_contact_time = 'morning',
    updated_at = CURRENT_TIMESTAMP
WHERE loyalty_tier IN ('gold', 'platinum');

-- Example 11: Update based on related table data
UPDATE products
SET stock_quantity = stock_quantity - (
    SELECT COALESCE(SUM(oi.quantity), 0)
    FROM order_items oi
    WHERE oi.product_id = products.product_id
)
WHERE product_id IN (SELECT DISTINCT product_id FROM order_items);

-- ============================================
-- DELETE EXAMPLES
-- ============================================

-- Example 12: Delete old reviews (keep only recent ones)
-- First, let's see what we have
SELECT COUNT(*) as total_reviews FROM product_reviews;

-- Delete reviews older than 1 year (but we just created them, so none will be deleted)
DELETE FROM product_reviews
WHERE review_date < DATE('now', '-1 year');

SELECT COUNT(*) as remaining_reviews FROM product_reviews;

-- Example 13: Delete inactive customer preferences
DELETE FROM customer_preferences
WHERE customer_id IN (
    SELECT c.customer_id
    FROM customers c
    WHERE c.customer_status = 'inactive'
);

-- Example 14: Clean up low-rated reviews
DELETE FROM product_reviews
WHERE rating <= 2 AND helpful_votes = 0;

-- ============================================
-- ALTER TABLE EXAMPLES
-- ============================================

-- Example 15: Add a new column to products table
ALTER TABLE products ADD COLUMN discontinued BOOLEAN DEFAULT FALSE;

-- Example 16: Add discount column to product_reviews
ALTER TABLE product_reviews ADD COLUMN would_recommend BOOLEAN;

-- Example 17: Update the new columns with data
UPDATE product_reviews
SET would_recommend = CASE WHEN rating >= 4 THEN TRUE ELSE FALSE END
WHERE would_recommend IS NULL;

-- ============================================
-- COMPLEX DATA MANAGEMENT
-- ============================================

-- Example 21: Bulk update based on complex logic
UPDATE customer_preferences
SET loyalty_tier = CASE
    WHEN customer_id IN (
        SELECT c.customer_id
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id
        HAVING COALESCE(SUM(o.total_amount), 0) > 300
    ) THEN 'platinum'
    WHEN customer_id IN (
        SELECT c.customer_id
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id
        HAVING COALESCE(SUM(o.total_amount), 0) > 150
    ) THEN 'gold'
    WHEN customer_id IN (
        SELECT c.customer_id
        FROM customers c
        LEFT JOIN orders o ON c.customer_id = o.customer_id
        GROUP BY c.customer_id
        HAVING COALESCE(SUM(o.total_amount), 0) > 50
    ) THEN 'silver'
    ELSE 'bronze'
END;

-- Example 22: Create summary table from existing data
CREATE TABLE sales_summary AS
SELECT strftime('%Y-%m', o.order_date) as month,
       COUNT(o.order_id) as orders_count,
       COUNT(DISTINCT o.customer_id) as customers_count,
       SUM(o.total_amount) as total_revenue,
       AVG(o.total_amount) as avg_order_value,
       COUNT(DISTINCT oi.product_id) as products_sold
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month;

-- ============================================
-- EXERCISE SOLUTIONS
-- ============================================

-- Exercise 1: CREATE TABLE
CREATE TABLE categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE,
    description TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    active BOOLEAN DEFAULT TRUE
);

-- Exercise 2: INSERT Data
INSERT INTO categories (category_name, description) VALUES
('Electronics', 'Electronic devices and gadgets'),
('Sports', 'Sports equipment and apparel'),
('Appliances', 'Home appliances'),
('Books', 'Books and publications');

-- Exercise 3: UPDATE with JOIN
UPDATE customer_preferences
SET favorite_category = (
    SELECT p.category
    FROM orders o
    INNER JOIN order_items oi ON o.order_id = oi.order_id
    INNER JOIN products p ON oi.product_id = p.product_id
    WHERE o.customer_id = customer_preferences.customer_id
    GROUP BY p.category
    ORDER BY COUNT(*) DESC
    LIMIT 1
)
WHERE customer_id IN (SELECT customer_id FROM orders);

-- Exercise 4: Safe DELETE
DELETE FROM product_reviews
WHERE rating <= 2
  AND helpful_votes = 0
  AND review_date < DATE('now', '-30 days');

-- Exercise 5: ALTER TABLE
ALTER TABLE products ADD COLUMN return_rate DECIMAL(5,2) DEFAULT 0.00;

-- Exercise 6: Complex UPDATE
UPDATE products
SET return_rate = (
    SELECT ROUND(
        CAST(COUNT(CASE WHEN change_type = 'return' THEN 1 END) AS FLOAT) /
        NULLIF(COUNT(*), 0) * 100, 2
    )
    FROM inventory_log
    WHERE inventory_log.product_id = products.product_id
)
WHERE product_id IN (SELECT DISTINCT product_id FROM inventory_log);

-- ============================================
-- DEBUG EXERCISE SOLUTION
-- ============================================

-- Fixed UPDATE query: Mark products as discontinued for no recent sales
-- The issue was that the discontinued column might not exist yet

-- First, ensure the column exists:
-- ALTER TABLE products ADD COLUMN discontinued BOOLEAN DEFAULT FALSE;

-- Then the fixed UPDATE query:
UPDATE products
SET discontinued = TRUE
WHERE product_id NOT IN (
    SELECT DISTINCT oi.product_id
    FROM order_items oi
    INNER JOIN orders o ON oi.order_id = o.order_id
    WHERE o.order_date > DATE('now', '-90 days')
);

-- ============================================
-- USEFUL ADDITIONAL QUERIES
-- ============================================

-- Create a backup table
CREATE TABLE customers_backup AS
SELECT * FROM customers;

-- Insert data with validation
INSERT OR IGNORE INTO product_reviews (product_id, customer_id, rating, review_text)
SELECT 1, 1, 5, 'Great product!'
WHERE EXISTS (SELECT 1 FROM customers WHERE customer_id = 1)
  AND EXISTS (SELECT 1 FROM products WHERE product_id = 1);

-- Bulk update with transaction safety (conceptual)
-- In SQLite, you would wrap these in a transaction:
-- BEGIN TRANSACTION;
-- UPDATE products SET price = price * 1.1 WHERE category = 'Electronics';
-- UPDATE inventory_log SET change_reason = 'Price increase' WHERE product_id IN (SELECT product_id FROM products WHERE category = 'Electronics');
-- COMMIT;

-- Safe delete with backup
CREATE TABLE product_reviews_backup AS
SELECT * FROM product_reviews
WHERE review_date < DATE('now', '-90 days');

DELETE FROM product_reviews
WHERE review_date < DATE('now', '-90 days');

-- Create index for better performance
CREATE INDEX idx_product_category ON products(category);
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_customer_email ON customers(email);

-- Update with data validation
UPDATE products
SET price = CASE
    WHEN price < 10 THEN price * 1.2  -- 20% increase for cheap items
    WHEN price < 50 THEN price * 1.15 -- 15% increase for medium items
    ELSE price * 1.1                 -- 10% increase for expensive items
END
WHERE stock_quantity > 0;

-- Complex data cleanup
DELETE FROM customer_preferences
WHERE customer_id NOT IN (SELECT customer_id FROM customers)
   OR updated_at < DATE('now', '-365 days');

-- Create summary reports
CREATE TABLE monthly_report AS
SELECT
    strftime('%Y-%m', o.order_date) as month,
    COUNT(DISTINCT o.customer_id) as active_customers,
    COUNT(o.order_id) as total_orders,
    SUM(o.total_amount) as revenue,
    AVG(o.total_amount) as avg_order_value,
    COUNT(DISTINCT oi.product_id) as unique_products_sold
FROM orders o
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY strftime('%Y-%m', o.order_date)
ORDER BY month;
