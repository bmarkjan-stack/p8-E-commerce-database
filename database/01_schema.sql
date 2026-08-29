/*
=========================================================
E-COMMERCE DATABASE
=========================================================

Database: PostgreSQL

Purpose:
    Defines the database structure for an online store.

Main entities:
    customers
    addresses
    categories
    products

The database demonstrates:
    - Primary keys
    - Foreign keys
    - One-to-many relationships
    - Many-to-many relationships through order_items
    - Constraints
    - Indexes
    - Normalized relational design
=========================================================
*/


/*
=========================================================
1. CUSTOMERS
=========================================================
Stores customer account information.
*/

CREATE TABLE customers (
    customer_id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(30),
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
);


/*
=========================================================
2. ADDRESSES
=========================================================
A customer can have multiple addresses.

Examples:
    - Home
    - Work
    - Billing
    - Shipping
*/

CREATE TABLE addresses (
    address_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    address_type VARCHAR(20) NOT NULL,
    address_line_1 VARCHAR(150) NOT NULL,
    address_line_2 VARCHAR(150),
    city VARCHAR(100) NOT NULL,
    state_province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN NOT NULL DEFAULT FALSE,
);

/*
=========================================================
3. CATEGORIES
=========================================================
Stores product categories.

Example:
    Electronics
    Clothing
    Home & Kitchen
*/

CREATE TABLE categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(100) NOT NULL UNIQUE,
    description TEXT
);


/*
=========================================================
4. PRODUCTS
=========================================================
Stores products available in the store.

Each product belongs to one category.
*/

CREATE TABLE products (
    product_id SERIAL PRIMARY KEY,
    category_id INTEGER NOT NULL,
    product_name VARCHAR(150) NOT NULL,
    description TEXT,
    sku VARCHAR(50) NOT NULL UNIQUE,
    price NUMERIC(10, 2) NOT NULL,
    inventory_quantity INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
);
