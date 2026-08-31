````markdown
# Database Design

## Overview

The E-Commerce Database models the core data required by an
online shopping platform.

The database allows the application to manage:

- Customers
- Customer addresses
- Product categories
- Products
- Orders
- Order items
- Payments
- Product reviews

The design focuses on relational database concepts rather than
simply storing data in a collection of unrelated tables.

---

# Entity Relationships

The main relationships are:

```text
CUSTOMERS
    │
    │ 1
    │
    │
    └──────────< ORDERS
                    │
                    │ 1
                    │
                    └──────────< ORDER_ITEMS >────────── PRODUCTS
                                                          │
                                                          │
                                                          │
                                                          └────────── CATEGORIES


CUSTOMERS
    │
    └──────────< ADDRESSES


CUSTOMERS
    │
    └──────────< REVIEWS >────────── PRODUCTS


ORDERS
    │
    └────────── PAYMENTS
````

---

# Tables

## customers

Stores customer account information.

Important fields:

* `customer_id`
* `first_name`
* `last_name`
* `email`
* `password_hash`
* `phone`
* `created_at`
* `is_active`

Primary key:

```text
customer_id
```

---

## addresses

Stores customer addresses.

A customer can have multiple addresses.

Relationship:

```text
customers 1 ────< addresses
```

The `customer_id` foreign key connects an address to its customer.

---

## categories

Stores product categories.

Examples:

* Electronics
* Clothing
* Home & Kitchen
* Books
* Sports

Relationship:

```text
categories 1 ────< products
```

---

## products

Stores products available for purchase.

Important fields:

* `product_id`
* `category_id`
* `product_name`
* `sku`
* `price`
* `inventory_quantity`

The `category_id` column references `categories`.

---

## orders

Represents a customer's purchase.

Important fields:

* `order_id`
* `customer_id`
* `shipping_address_id`
* `order_date`
* `status`
* `shipping_cost`

Relationship:

```text
customers 1 ────< orders
```

---

## order_items

Represents individual products inside an order.

This table is particularly important because it resolves the
many-to-many relationship between orders and products.

Without `order_items`:

```text
orders >────< products
```

With `order_items`:

```text
orders 1 ────< order_items >──── 1 products
```

An order can contain many products.

A product can appear in many orders.

---

# Why `unit_price` Exists in `order_items`

The `products` table contains the current product price.

However, the price of a product can change.

For example:

```text
January:
Wireless Headphones = $79.99

March:
Wireless Headphones = $89.99
```

If a customer purchased the headphones in January,
the order should continue to show `$79.99`.

Therefore, `order_items.unit_price` stores the price at
the time of purchase.

This is an important real-world database design decision.

---

# payments

Stores payment information for orders.

Fields include:

* Payment method
* Payment status
* Payment amount
* Transaction reference
* Payment timestamp

Relationship:

```text
orders 1 ──── 1 payments
```

The `order_id` column is unique, enforcing one payment record
per order in this simplified system.

---

# reviews

Stores customer product reviews.

A customer can review many products.

A product can receive many reviews.

Therefore:

```text
customers >────< reviews >────< products
```

The constraint:

```sql
UNIQUE (customer_id, product_id)
```

prevents the same customer from reviewing the same product
multiple times.

---

# Primary Keys

Every major entity has a primary key.

Examples:

```text
customers.customer_id
products.product_id
categories.category_id
orders.order_id
order_items.order_item_id
payments.payment_id
reviews.review_id
addresses.address_id
```

Primary keys uniquely identify individual records.

---

# Foreign Keys

Foreign keys enforce relationships between tables.

Examples:

```text
addresses.customer_id
products.category_id
orders.customer_id
orders.shipping_address_id
order_items.order_id
order_items.product_id
payments.order_id
reviews.customer_id
reviews.product_id
```

This prevents invalid relationships from being inserted.

---

# Constraints

The database uses several types of constraints.

## NOT NULL

Used for required information.

Example:

```sql
product_name VARCHAR(150) NOT NULL
```

---

## UNIQUE

Prevents duplicate values.

Examples:

```sql
email UNIQUE
sku UNIQUE
```

---

## CHECK

Ensures values follow business rules.

Example:

```sql
CHECK (price >= 0)
```

Another example:

```sql
CHECK (rating BETWEEN 1 AND 5)
```

---

## FOREIGN KEY

Maintains referential integrity.

Example:

```sql
FOREIGN KEY (category_id)
REFERENCES categories(category_id)
```

---

# Normalization

The database separates different types of information into
different tables.

For example, customer information is stored in:

```text
customers
```

while addresses are stored in:

```text
addresses
```

Products are stored separately from categories:

```text
products
categories
```

Orders and their individual products are separated into:

```text
orders
order_items
```

This reduces unnecessary duplication.

The design generally follows the principles of:

* First Normal Form (1NF)
* Second Normal Form (2NF)
* Third Normal Form (3NF)

---

# Indexing

Indexes are created for frequently queried columns.

Examples:

```sql
idx_products_category_id
idx_products_inventory_quantity
idx_orders_customer_id
idx_orders_order_date
idx_orders_status
idx_order_items_order_id
idx_order_items_product_id
```

Indexes can improve performance when the database searches,
joins, filters, or sorts using those columns.

---

# Business Queries

The database demonstrates practical business questions.

## Total sales by month

Determines how much merchandise revenue was generated each month.

---

## Best-selling products

Ranks products according to the number of units sold.

---

## Highest-spending customers

Determines which customers have generated the most revenue.

---

## Products never purchased

Identifies products that have never appeared in a valid order.

---

## Average order value

Calculates the average merchandise value of an order.

---

## Low inventory

Identifies products that need to be restocked.

---

## Popular categories

Ranks categories according to units sold and revenue.

---

# Technologies

* PostgreSQL
* SQL
* Relational Database Design

---

# Learning Objectives

This project demonstrates practical understanding of:

* Database design
* Relational modeling
* Primary keys
* Foreign keys
* One-to-many relationships
* Many-to-many relationships
* Normalization
* Data integrity
* Constraints
* Indexing
* JOINs
* Aggregations
* Subqueries
* Common Table Expressions
* Business analytics using SQL

```
```
