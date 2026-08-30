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
