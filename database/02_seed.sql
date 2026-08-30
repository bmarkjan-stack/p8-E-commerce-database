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

/*
=========================================================
5. ORDERS
=========================================================
I intentionally use different dates and statuses so
the analytical queries produce meaningful results.
=========================================================
*/

INSERT INTO orders
    (
        customer_id,
        shipping_address_id,
        order_date,
        status,
        shipping_cost
    )
VALUES
    (
        1,
        1,
        '2026-01-10 10:30:00',
        'delivered',
        8.00
    ),
    (
        2,
        2,
        '2026-01-15 14:20:00',
        'delivered',
        10.00
    ),
    (
        3,
        3,
        '2026-02-05 09:15:00',
        'delivered',
        7.50
    ),
    (
        1,
        1,
        '2026-02-20 16:45:00',
        'delivered',
        8.00
    ),
    (
        4,
        4,
        '2026-03-03 11:00:00',
        'shipped',
        9.00
    ),
    (
        5,
        5,
        '2026-03-18 13:25:00',
        'delivered',
        7.00
    ),
    (
        2,
        2,
        '2026-04-02 15:10:00',
        'delivered',
        10.00
    ),
    (
        6,
        6,
        '2026-04-25 12:40:00',
        'processing',
        8.50
    ),
    (
        3,
        3,
        '2026-05-08 17:30:00',
        'delivered',
        7.50
    ),
    (
        4,
        4,
        '2026-05-21 10:00:00',
        'cancelled',
        9.00
    ),
    (
        5,
        5,
        '2026-06-11 14:00:00',
        'delivered',
        7.00
    ),
    (
        6,
        6,
        '2026-06-25 18:10:00',
        'delivered',
        8.50
    );

/*
=========================================================
6. ORDER ITEMS
=========================================================
*/

INSERT INTO order_items
    (
        order_id,
        product_id,
        quantity,
        unit_price
    )
VALUES
    /* Order 1 */
    (1, 1, 2, 89.99),
    (1, 4, 1, 24.99),
    /* Order 2 */
    (2, 6, 1, 59.99),
    (2, 8, 2, 34.99),
    /* Order 3 */
    (3, 2, 1, 74.99),
    (3, 3, 2, 39.99),
    /* Order 4 */
    (4, 5, 1, 79.99),
    (4, 9, 1, 39.99),
    /* Order 5 */
    (5, 10, 2, 29.99),
    (5, 11, 1, 99.99),
    /* Order 6 */
    (6, 1, 1, 89.99),
    (6, 7, 1, 44.99),
    /* Order 7 */
    (7, 4, 3, 24.99),
    (7, 6, 1, 59.99),
    /* Order 8 */
    (8, 3, 1, 39.99),
    (8, 12, 2, 34.99),
    /* Order 9 */
    (9, 2, 2, 74.99),
    (9, 8, 1, 34.99),
    /* Order 10 - cancelled */
    (10, 11, 1, 99.99),
    /* Order 11 */
    (11, 5, 1, 79.99),
    (11, 10, 1, 29.99),
    /* Order 12 */
    (12, 1, 1, 89.99),
    (12, 12, 1, 34.99);

/*
=========================================================
7. PAYMENTS
=========================================================
*/

INSERT INTO payments
    (
        order_id,
        payment_method,
        payment_status,
        amount,
        paid_at,
        transaction_reference
    )
VALUES
    (
        1,
        'credit_card',
        'completed',
        212.97,
        '2026-01-10 10:32:00',
        'TXN-0001'
    ),
    (
        2,
        'paypal',
        'completed',
        139.98,
        '2026-01-15 14:22:00',
        'TXN-0002'
    ),
    (
        3,
        'credit_card',
        'completed',
        162.47,
        '2026-02-05 09:17:00',
        'TXN-0003'
    ),
    (
        4,
        'debit_card',
        'completed',
        127.98,
        '2026-02-20 16:47:00',
        'TXN-0004'
    ),
    (
        5,
        'credit_card',
        'completed',
        168.97,
        '2026-03-03 11:02:00',
        'TXN-0005'
    ),
    (
        6,
        'paypal',
        'completed',
        141.98,
        '2026-03-18 13:27:00',
        'TXN-0006'
    ),
    (
        7,
        'credit_card',
        'completed',
        134.96,
        '2026-04-02 15:12:00',
        'TXN-0007'
    ),
    (
        8,
        'debit_card',
        'completed',
        109.97,
        '2026-04-25 12:42:00',
        'TXN-0008'
    ),
    (
        9,
        'credit_card',
        'completed',
        184.97,
        '2026-05-08 17:32:00',
        'TXN-0009'
    ),
    (
        10,
        'credit_card',
        'refunded',
        108.99,
        '2026-05-21 10:02:00',
        'TXN-0010'
    ),
    (
        11,
        'paypal',
        'completed',
        116.98,
        '2026-06-11 14:02:00',
        'TXN-0011'
    ),
    (
        12,
        'credit_card',
        'completed',
        133.49,
        '2026-06-25 18:12:00',
        'TXN-0012'
    );

/*
=========================================================
8. REVIEWS
=========================================================
*/

INSERT INTO reviews
    (
        customer_id,
        product_id,
        rating,
        review_title,
        review_text
    )
VALUES
    (
        1,
        1,
        5,
        'Excellent headphones',
        'Great sound quality and comfortable to wear.'
    ),
    (
        2,
        6,
        4,
        'Good coffee maker',
        'Works well and is easy to use.'
    ),
    (
        3,
        2,
        5,
        'Great keyboard',
        'Very comfortable for programming.'
    ),
    (
        4,
        10,
        4,
        'Good yoga mat',
        'Provides good grip during workouts.'
    ),
    (
        5,
        5,
        5,
        'Great jacket',
        'Good quality denim and fits well.'
    ),
    (
        6,
        12,
        4,
        'Useful kettle',
        'Boils water quickly.'
    );

/*
=========================================================
SEED DATA COMPLETE
=========================================================
*/
