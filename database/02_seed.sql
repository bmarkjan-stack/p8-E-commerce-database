/*
=========================================================
E-COMMERCE DATABASE - SAMPLE DATA
=========================================================
Run this AFTER 01_schema.sql.
The data represents a small online store.
=========================================================
*/

/*
=========================================================
1. CUSTOMERS
=========================================================
*/

INSERT INTO customers
    (first_name, last_name, email, password_hash, phone)
VALUES
    ('John', 'Carter', 'john.carter@example.com', 'hash_john_123', '+1-555-1001'),
    ('Maria', 'Santos', 'maria.santos@example.com', 'hash_maria_456', '+1-555-1002'),
    ('David', 'Lee', 'david.lee@example.com', 'hash_david_789', '+1-555-1003'),
    ('Sarah', 'Wilson', 'sarah.wilson@example.com', 'hash_sarah_321', '+1-555-1004'),
    ('James', 'Brown', 'james.brown@example.com', 'hash_james_654', '+1-555-1005'),
    ('Emily', 'Davis', 'emily.davis@example.com', 'hash_emily_987', '+1-555-1006');

/*
=========================================================
2. ADDRESSES
=========================================================
*/

INSERT INTO addresses
    (
        customer_id,
        address_type,
        address_line_1,
        city,
        state_province,
        postal_code,
        country,
        is_default
    )
VALUES
    (
        1,
        'shipping',
        '123 Main Street',
        'Los Angeles',
        'California',
        '90001',
        'USA',
        TRUE
    ),
    (
        2,
        'shipping',
        '45 Sunset Avenue',
        'Manila',
        'Metro Manila',
        '1000',
        'Philippines',
        TRUE
    ),
    (
        3,
        'shipping',
        '78 Oak Road',
        'Seattle',
        'Washington',
        '98101',
        'USA',
        TRUE
    ),
    (
        4,
        'shipping',
        '91 Lake Street',
        'Chicago',
        'Illinois',
        '60601',
        'USA',
        TRUE
    ),
    (
        5,
        'shipping',
        '56 Pine Avenue',
        'Austin',
        'Texas',
        '73301',
        'USA',
        TRUE
    ),
    (
        6,
        'shipping',
        '12 Garden Road',
        'Boston',
        'Massachusetts',
        '02101',
        'USA',
        TRUE
    );

/*
=========================================================
3. CATEGORIES
=========================================================
*/

INSERT INTO categories
    (category_name, description)
VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Clothing', 'Clothing and apparel'),
    ('Home & Kitchen', 'Products for home and kitchen'),
    ('Books', 'Physical books and educational materials'),
    ('Sports', 'Sports and fitness equipment');

/*
=========================================================
4. PRODUCTS
=========================================================
*/

INSERT INTO products
    (
        category_id,
        product_name,
        description,
        sku,
        price,
        inventory_quantity
    )
VALUES
    (
        1,
        'Wireless Headphones',
        'Noise-cancelling wireless headphones',
        'ELEC-001',
        89.99,
        25
    ),
    (
        1,
        'Mechanical Keyboard',
        'RGB mechanical keyboard for computers',
        'ELEC-002',
        74.99,
        8
    ),
    (
        1,
        'USB-C Hub',
        'Multi-port USB-C adapter',
        'ELEC-003',
        39.99,
        3
    ),
    (
        2,
        'Classic T-Shirt',
        'Cotton casual t-shirt',
        'CLTH-001',
        24.99,
        50
    ),
    (
        2,
        'Denim Jacket',
        'Classic blue denim jacket',
        'CLTH-002',
        79.99,
        12
    ),
    (
        3,
        'Coffee Maker',
        'Automatic drip coffee maker',
        'HOME-001',
        59.99,
        15
    ),
    (
        3,
        'Stainless Steel Pan',
        '12-inch stainless steel frying pan',
        'HOME-002',
        44.99,
        6
    ),
    (
        4,
        'SQL Fundamentals',
        'Introduction to relational databases',
        'BOOK-001',
        34.99,
        20
    ),
    (
        4,
        'Python Programming',
        'Beginner Python programming guide',
        'BOOK-002',
        39.99,
        18
    ),
    (
        5,
        'Yoga Mat',
        'Non-slip exercise and yoga mat',
        'SPRT-001',
        29.99,
        2
    ),
    (
        5,
        'Dumbbell Set',
        'Adjustable dumbbell exercise set',
        'SPRT-002',
        99.99,
        5
    ),
    (
        3,
        'Electric Kettle',
        'Fast-boiling electric kettle',
        'HOME-003',
        34.99,
        10
    );

