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
    payments
    reviews


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
    CONSTRAINT customers_email_lowercase
        CHECK (email = LOWER(email))
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
    CONSTRAINT fk_addresses_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    CONSTRAINT addresses_type_check
        CHECK (address_type IN ('billing', 'shipping'))
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
    CONSTRAINT fk_products_category
        FOREIGN KEY (category_id)
        REFERENCES categories(category_id)
        ON DELETE RESTRICT,
    CONSTRAINT products_price_check
        CHECK (price >= 0),
    CONSTRAINT products_inventory_check
        CHECK (inventory_quantity >= 0)
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
    CONSTRAINT fk_orders_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE RESTRICT,
    CONSTRAINT fk_orders_shipping_address
        FOREIGN KEY (shipping_address_id)
        REFERENCES addresses(address_id)
        ON DELETE SET NULL,
    CONSTRAINT orders_status_check
        CHECK (
            status IN (
                'pending',
                'processing',
                'shipped',
                'delivered',
                'cancelled'
            )
        ),
    CONSTRAINT orders_shipping_cost_check
        CHECK (shipping_cost >= 0)
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
    CONSTRAINT fk_order_items_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_order_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE RESTRICT,
    CONSTRAINT order_items_quantity_check
        CHECK (quantity > 0),
    CONSTRAINT order_items_unit_price_check
        CHECK (unit_price >= 0),
    CONSTRAINT unique_order_product
        UNIQUE (order_id, product_id)
);

/*
=========================================================
7. PAYMENTS
=========================================================
Stores payment information for orders.
One order can have one payment in this simplified
e-commerce system.
*/

CREATE TABLE payments (
    payment_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE,
    payment_method VARCHAR(30) NOT NULL,
    payment_status VARCHAR(20) NOT NULL DEFAULT 'pending',
    amount NUMERIC(10, 2) NOT NULL,
    paid_at TIMESTAMP,
    transaction_reference VARCHAR(100) UNIQUE,
    CONSTRAINT fk_payments_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT payments_method_check
        CHECK (
            payment_method IN (
                'credit_card',
                'debit_card',
                'paypal',
                'bank_transfer',
                'cash_on_delivery'
            )
        ),
    CONSTRAINT payments_status_check
        CHECK (
            payment_status IN (
                'pending',
                'completed',
                'failed',
                'refunded'
            )
        ),
    CONSTRAINT payments_amount_check
        CHECK (amount >= 0)
);

/*
=========================================================
8. REVIEWS
=========================================================
Customers can review products.
A customer can review a product only once.
*/

CREATE TABLE reviews (
    review_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    rating INTEGER NOT NULL,
    review_title VARCHAR(150),
    review_text TEXT,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_reviews_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_reviews_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT reviews_rating_check
        CHECK (rating BETWEEN 1 AND 5),
    CONSTRAINT unique_customer_product_review
        UNIQUE (customer_id, product_id)
);

/*
=========================================================
INDEXES
=========================================================
Indexes improve query performance when searching,
filtering, joining, or sorting by commonly used columns.
=========================================================
*/

/*
Customer lookup by email.
*/
CREATE INDEX idx_customers_email
    ON customers(email);

/*
Find addresses belonging to a customer.
*/
CREATE INDEX idx_addresses_customer_id
    ON addresses(customer_id);

/*
Find products by category.
*/
CREATE INDEX idx_products_category_id
    ON products(category_id);

/*
Find low-stock products efficiently.
*/
CREATE INDEX idx_products_inventory_quantity
    ON products(inventory_quantity);

/*
Find orders belonging to a customer.
*/
CREATE INDEX idx_orders_customer_id
    ON orders(customer_id);

/*
Find orders by date.

Useful for:
    - monthly sales
    - sales reports
    - revenue analytics
*/
CREATE INDEX idx_orders_order_date
    ON orders(order_date);

/*
Find orders by status.
*/
CREATE INDEX idx_orders_status
    ON orders(status);

/*
Find order items belonging to an order.
*/
CREATE INDEX idx_order_items_order_id
    ON order_items(order_id);

/*
Find all orders containing a product.
*/
CREATE INDEX idx_order_items_product_id
    ON order_items(product_id);

/*
Find reviews for a product.
*/
CREATE INDEX idx_reviews_product_id
    ON reviews(product_id);

/*
Find reviews written by a customer.
*/
CREATE INDEX idx_reviews_customer_id
    ON reviews(customer_id);

/*
=========================================================
SCHEMA COMPLETE
=========================================================
*/
