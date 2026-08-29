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
    orders
    order_items

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

/*
=========================================================
5. ORDERS
=========================================================
Represents a customer's order.
One customer can have many orders.
*/

CREATE TABLE orders (
    order_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    shipping_address_id INTEGER,
    order_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    shipping_cost NUMERIC(10, 2) NOT NULL DEFAULT 0,

);

/*
=========================================================
6. ORDER ITEMS
=========================================================
Connects orders and products.
This creates a many-to-many relationship:

    orders <----> products

An order can contain multiple products.
A product can appear in many orders.
unit_price is stored separately from products.price
because the price at the time of purchase must be preserved.

Example:

Product price today:
    $50
Customer bought it last month:
    $40

The order should continue to show $40.
*/

CREATE TABLE order_items (
    order_item_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price NUMERIC(10, 2) NOT NULL,
);
