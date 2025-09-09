#!/usr/bin/env python3
"""
GRIT SQL Course - Sample Database Creator

Creates a realistic e-commerce database for SQL learning exercises.
Includes customers, products, orders, and order_items tables.
"""

import sqlite3
import random
from datetime import datetime, timedelta
import os

def create_sample_database():
    """Create and populate the sample e-commerce database"""

    # Remove existing database if it exists
    if os.path.exists('ecommerce.db'):
        os.remove('ecommerce.db')

    conn = sqlite3.connect('ecommerce.db')
    cursor = conn.cursor()

    # Create tables
    print("Creating database tables...")

    # Customers table
    cursor.execute('''
        CREATE TABLE customers (
            customer_id INTEGER PRIMARY KEY,
            first_name TEXT NOT NULL,
            last_name TEXT NOT NULL,
            email TEXT UNIQUE NOT NULL,
            phone TEXT,
            address TEXT,
            city TEXT,
            state TEXT,
            zip_code TEXT,
            registration_date DATE,
            customer_status TEXT CHECK(customer_status IN ('active', 'inactive')) DEFAULT 'active'
        )
    ''')

    # Products table
    cursor.execute('''
        CREATE TABLE products (
            product_id INTEGER PRIMARY KEY,
            product_name TEXT NOT NULL,
            category TEXT NOT NULL,
            price DECIMAL(10,2) NOT NULL,
            cost DECIMAL(10,2) NOT NULL,
            stock_quantity INTEGER DEFAULT 0,
            description TEXT,
            brand TEXT,
            created_date DATE
        )
    ''')

    # Orders table
    cursor.execute('''
        CREATE TABLE orders (
            order_id INTEGER PRIMARY KEY,
            customer_id INTEGER NOT NULL,
            order_date DATE NOT NULL,
            total_amount DECIMAL(10,2) NOT NULL,
            order_status TEXT CHECK(order_status IN ('pending', 'processing', 'shipped', 'delivered', 'cancelled')) DEFAULT 'pending',
            shipping_address TEXT,
            payment_method TEXT,
            FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
        )
    ''')

    # Order items table
    cursor.execute('''
        CREATE TABLE order_items (
            order_item_id INTEGER PRIMARY KEY,
            order_id INTEGER NOT NULL,
            product_id INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            unit_price DECIMAL(10,2) NOT NULL,
            total_price DECIMAL(10,2) NOT NULL,
            FOREIGN KEY (order_id) REFERENCES orders(order_id),
            FOREIGN KEY (product_id) REFERENCES products(product_id)
        )
    ''')

    # Sample data
    print("Inserting sample data...")

    # Customers data
    customers_data = [
        (1, 'John', 'Smith', 'john.smith@email.com', '555-0101', '123 Main St', 'New York', 'NY', '10001', '2023-01-15', 'active'),
        (2, 'Sarah', 'Johnson', 'sarah.j@email.com', '555-0102', '456 Oak Ave', 'Los Angeles', 'CA', '90210', '2023-02-20', 'active'),
        (3, 'Michael', 'Brown', 'm.brown@email.com', '555-0103', '789 Pine Rd', 'Chicago', 'IL', '60601', '2023-03-10', 'active'),
        (4, 'Emily', 'Davis', 'emily.d@email.com', '555-0104', '321 Elm St', 'Houston', 'TX', '77001', '2023-04-05', 'active'),
        (5, 'David', 'Wilson', 'd.wilson@email.com', '555-0105', '654 Maple Dr', 'Phoenix', 'AZ', '85001', '2023-05-12', 'active'),
        (6, 'Lisa', 'Garcia', 'lisa.g@email.com', '555-0106', '987 Cedar Ln', 'Philadelphia', 'PA', '19101', '2023-06-18', 'active'),
        (7, 'Robert', 'Miller', 'r.miller@email.com', '555-0107', '147 Birch St', 'San Antonio', 'TX', '78201', '2023-07-22', 'inactive'),
        (8, 'Jennifer', 'Martinez', 'j.martinez@email.com', '555-0108', '258 Spruce Ave', 'San Diego', 'CA', '92101', '2023-08-30', 'active'),
        (9, 'James', 'Anderson', 'james.a@email.com', '555-0109', '369 Willow Rd', 'Dallas', 'TX', '75201', '2023-09-14', 'active'),
        (10, 'Maria', 'Taylor', 'maria.t@email.com', '555-0110', '741 Poplar St', 'San Jose', 'CA', '95101', '2023-10-08', 'active'),
    ]

    cursor.executemany('INSERT INTO customers VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)', customers_data)

    # Products data
    products_data = [
        (1, 'Wireless Bluetooth Headphones', 'Electronics', 99.99, 60.00, 50, 'High-quality wireless headphones with noise cancellation', 'TechSound', '2023-01-01'),
        (2, 'Gaming Mouse', 'Electronics', 49.99, 25.00, 30, 'Precision gaming mouse with RGB lighting', 'GamePro', '2023-01-01'),
        (3, 'Coffee Maker', 'Appliances', 79.99, 45.00, 20, '12-cup programmable coffee maker', 'BrewMaster', '2023-01-01'),
        (4, 'Running Shoes', 'Sports', 129.99, 70.00, 40, 'Lightweight running shoes with cushioning', 'SpeedRun', '2023-01-01'),
        (5, 'Yoga Mat', 'Sports', 39.99, 18.00, 35, 'Non-slip yoga mat with carrying strap', 'ZenFit', '2023-01-01'),
        (6, 'Smart Watch', 'Electronics', 299.99, 150.00, 15, 'Fitness tracking smartwatch with heart rate monitor', 'FitTech', '2023-01-01'),
        (7, 'Blender', 'Appliances', 89.99, 50.00, 25, 'High-speed blender for smoothies and soups', 'KitchenPro', '2023-01-01'),
        (8, 'Novel - "The Data Scientist"', 'Books', 24.99, 12.00, 60, 'Fiction novel about a data scientist', 'BookPub', '2023-01-01'),
        (9, 'Wireless Keyboard', 'Electronics', 69.99, 35.00, 45, 'Mechanical wireless keyboard', 'TypeMaster', '2023-01-01'),
        (10, 'Dumbbells Set', 'Sports', 199.99, 100.00, 10, 'Adjustable dumbbells 5-50 lbs', 'FitGear', '2023-01-01'),
    ]

    cursor.executemany('INSERT INTO products VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)', products_data)

    # Generate orders and order items
    print("Generating orders and order items...")

    order_statuses = ['pending', 'processing', 'shipped', 'delivered', 'cancelled']
    payment_methods = ['Credit Card', 'PayPal', 'Debit Card', 'Bank Transfer']

    # Create 50 sample orders
    for order_id in range(1, 51):
        customer_id = random.randint(1, 10)
        days_ago = random.randint(0, 180)  # Orders from last 6 months
        order_date = (datetime.now() - timedelta(days=days_ago)).strftime('%Y-%m-%d')

        # Random order status with delivered being most common
        status_weights = [0.1, 0.15, 0.25, 0.45, 0.05]  # pending, processing, shipped, delivered, cancelled
        order_status = random.choices(order_statuses, weights=status_weights)[0]

        payment_method = random.choice(payment_methods)

        # Get customer address
        cursor.execute('SELECT address, city, state, zip_code FROM customers WHERE customer_id = ?', (customer_id,))
        customer_addr = cursor.fetchone()
        shipping_address = f"{customer_addr[0]}, {customer_addr[1]}, {customer_addr[2]} {customer_addr[3]}"

        cursor.execute('INSERT INTO orders VALUES (?, ?, ?, ?, ?, ?, ?)',
                      (order_id, customer_id, order_date, 0, order_status, shipping_address, payment_method))

        # Add 1-5 random items to this order
        num_items = random.randint(1, 5)
        total_amount = 0

        for item_num in range(num_items):
            product_id = random.randint(1, 10)
            quantity = random.randint(1, 3)

            # Get product price
            cursor.execute('SELECT price FROM products WHERE product_id = ?', (product_id,))
            unit_price = cursor.fetchone()[0]

            total_price = unit_price * quantity
            total_amount += total_price

            cursor.execute('INSERT INTO order_items VALUES (?, ?, ?, ?, ?, ?)',
                          (order_id * 10 + item_num + 1, order_id, product_id, quantity, unit_price, total_price))

        # Update order total
        cursor.execute('UPDATE orders SET total_amount = ? WHERE order_id = ?', (total_amount, order_id))

    conn.commit()
    conn.close()

    print("✅ Sample database created successfully!")
    print("📊 Database contains:")
    print("   - 10 customers")
    print("   - 10 products")
    print("   - 50 orders")
    print("   - ~150 order items")
    print("\n📁 File: ecommerce.db")

if __name__ == "__main__":
    create_sample_database()
