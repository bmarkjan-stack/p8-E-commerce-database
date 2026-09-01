````markdown
# E-Commerce Database

A relational database project that models the backend data structure
of an online e-commerce store.

This project was created to demonstrate practical SQL and relational
database design concepts rather than simple CRUD queries.

---

## Project Overview

The database models the following parts of an online store:

- Customers
- Customer addresses
- Product categories
- Products
- Orders
- Order items
- Payments
- Product reviews

The database also includes analytical queries for answering
real-world business questions.

---

## Database Structure

```text
ecommerce-database/
│
├── database/
│   ├── 01_schema.sql
│   ├── 02_seed.sql
│   └── 03_queries.sql
│
├── docs/
│   └── database-design.md
│
├── .gitignore
└── README.md
````

---

## Entity Relationship Overview

```text
Customer
   │
   ├────────── Addresses
   │
   └────────── Orders
                  │
                  └────────── Order Items
                                  │
                                  └────────── Products
                                                 │
                                                 └────────── Categories

Customer
   │
   └────────── Reviews
                    │
                    └────────── Products

Order
   │
   └────────── Payment
```

---

# Features

The database demonstrates:

* Relational database design
* Primary keys
* Foreign keys
* One-to-many relationships
* Many-to-many relationships
* Normalization
* Data validation
* Constraints
* Indexing
* INNER JOIN
* LEFT JOIN
* GROUP BY
* HAVING
* Aggregate functions
* Subqueries
* Common Table Expressions
* Business analytics

---

# Database Tables

## customers

Stores customer accounts.

```text
customer_id
first_name
last_name
email
password_hash
phone
created_at
is_active
```

---

## addresses

Stores customer addresses.

```text
address_id
customer_id
address_type
address_line_1
address_line_2
city
state_province
postal_code
country
is_default
```

---

## categories

Stores product categories.

```text
category_id
category_name
description
```

---

## products

Stores products available for purchase.

```text
product_id
category_id
product_name
description
sku
price
inventory_quantity
is_active
created_at
```

---

## orders

Stores customer orders.

```text
order_id
customer_id
shipping_address_id
order_date
status
shipping_cost
```

---

## order_items

Stores the individual products included in an order.

```text
order_item_id
order_id
product_id
quantity
unit_price
```

This table resolves the many-to-many relationship between
orders and products.

---

## payments

Stores payment information.

```text
payment_id
order_id
payment_method
payment_status
amount
paid_at
transaction_reference
```

---

## reviews

Stores customer reviews.

```text
review_id
customer_id
product_id
rating
review_title
review_text
created_at
```

---

# Requirements

You will need:

* PostgreSQL
* pgAdmin 4 or another PostgreSQL client

You can also use the PostgreSQL command-line tools.

---

# Installation

## 1. Clone the repository

```bash
git clone https://github.com/bmarkjan-stack/p8-E-commerce-database.git
```

Move into the project:

```bash
cd p8-E-commerce-database
```

---

# 2. Create the database

Open PostgreSQL or pgAdmin and create a database named:

```text
ecommerce_db
```

Using `psql`:

```sql
CREATE DATABASE ecommerce_db;
```

Connect to it:

```sql
\c ecommerce_db
```

---

# 3. Create the tables

Run:

```text
database/01_schema.sql
```

This creates all tables, constraints, relationships, and indexes.

---

# 4. Insert sample data

Run:

```text
database/02_seed.sql
```

This inserts sample customers, products, orders, payments,
addresses, and reviews.

---

# 5. Run the analytical queries

Run:

```text
database/03_queries.sql
```

This contains the project's business intelligence queries.

---

# Example Queries

## Total sales by month

```sql
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS total_sales
FROM orders o
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY sales_month;
```

---

## Best-selling products

```sql
SELECT
    p.product_name,
    SUM(oi.quantity) AS units_sold
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY p.product_id, p.product_name
ORDER BY units_sold DESC;
```

---

## Highest-spending customers

```sql
SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    SUM(oi.quantity * oi.unit_price) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY total_spent DESC;
```

---

## Products never purchased

```sql
SELECT
    p.product_name
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;
```

---

## Low inventory

```sql
SELECT
    product_name,
    inventory_quantity
FROM products
WHERE inventory_quantity < 10
ORDER BY inventory_quantity ASC;
```

---

# Database Design Concepts Demonstrated

## Primary Keys

Every major table contains a primary key.

Example:

```sql
customer_id SERIAL PRIMARY KEY
```

---

## Foreign Keys

Foreign keys connect related tables.

Example:

```sql
FOREIGN KEY (customer_id)
REFERENCES customers(customer_id)
```

---

## Relationships

The database contains several relationship types.

### One-to-many

One customer can have many orders:

```text
customers 1 ────< orders
```

One category can contain many products:

```text
categories 1 ────< products
```

---

### Many-to-many

Orders and products have a many-to-many relationship.

An order can contain multiple products.

A product can appear in multiple orders.

This is resolved using:

```text
order_items
```

Resulting in:

```text
orders 1 ────< order_items >──── 1 products
```

---

# Normalization

The database separates different entities into their own tables
to minimize data duplication.

For example, category information is not repeated inside every
product record.

Instead:

```text
products
    │
    └── category_id
             │
             ▼
        categories
```

This follows relational database normalization principles.

---

# Constraints

The database uses several constraints to protect data integrity.

Examples include:

```sql
NOT NULL
UNIQUE
CHECK
PRIMARY KEY
FOREIGN KEY
```

Examples:

```sql
CHECK (price >= 0)
```

```sql
CHECK (inventory_quantity >= 0)
```

```sql
CHECK (rating BETWEEN 1 AND 5)
```

```sql
UNIQUE (customer_id, product_id)
```

---

# Indexing

Indexes were added to columns commonly used for:

* Searching
* Filtering
* Joining
* Sorting
* Reporting

Examples:

```text
idx_products_category_id
idx_products_inventory_quantity
idx_orders_customer_id
idx_orders_order_date
idx_orders_status
idx_order_items_order_id
idx_order_items_product_id
```

---

# Business Questions Answered

The database can answer questions such as:

1. How much did the store sell each month?
2. Which products sell the most?
3. Which customers spend the most money?
4. Which products have never been purchased?
5. What is the average order value?
6. Which products have low inventory?
7. Which categories generate the most revenue?
8. Which customers spend more than the average customer?
9. Which products have the highest review ratings?
10. Which payment methods are used most frequently?

---

# Future Improvements

Potential future improvements include:

* Product variants such as size and color
* Discount and coupon tables
* Shopping carts
* Wishlist functionality
* Product images
* Shipping tracking
* Multiple payments per order
* Refund records
* Customer authentication
* Database views
* Stored procedures
* Database triggers
* Automated inventory updates
* Full-text product search

---

# Technologies

* PostgreSQL
* SQL
* Relational Database Design

---

# Learning Objective

This project demonstrates that I can design and query a relational
database representing a realistic business problem.

Rather than relying on simple queries such as:

```sql
SELECT * FROM users;
```

the project focuses on relationships, data integrity, normalization,
analytics, joins, aggregation, subqueries, constraints, and indexing.

```
```
