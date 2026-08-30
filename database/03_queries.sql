/*
=========================================================
E-COMMERCE DATABASE - ANALYTICAL QUERIES
=========================================================
This file demonstrates:
    - SELECT
    - JOIN
    - LEFT JOIN
    - GROUP BY
    - ORDER BY
    - HAVING
    - Aggregate functions
    - CASE
    - Subqueries
    - Common Table Expressions
    - Date functions
    - Filtering
=========================================================
*/

/*
=========================================================
1. VIEW ALL CUSTOMERS
=========================================================
Basic SELECT demonstrating customer information.
*/

SELECT
    customer_id,
    first_name,
    last_name,
    email,
    created_at
FROM customers
ORDER BY customer_id;

/*
=========================================================
2. VIEW PRODUCTS WITH THEIR CATEGORIES
=========================================================
Demonstrates an INNER JOIN.
*/

SELECT
    p.product_id,
    p.product_name,
    p.sku,
    p.price,
    p.inventory_quantity,
    c.category_name
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
ORDER BY c.category_name, p.product_name;

/*
=========================================================
3. VIEW CUSTOMER ORDERS
=========================================================
Demonstrates joining customers and orders.
*/

SELECT
    o.order_id,
    o.order_date,
    o.status,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
ORDER BY o.order_date;

/*
=========================================================
4. ORDER DETAILS
=========================================================
Shows:
    Customer
    Order
    Product
    Quantity
    Unit Price
    Line Total
=========================================================
*/

SELECT
    o.order_id,
    CONCAT(c.first_name, ' ', c.last_name)
        AS customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    oi.quantity * oi.unit_price
        AS line_total
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
JOIN products p
    ON oi.product_id = p.product_id
ORDER BY o.order_id;

/*
=========================================================
5. TOTAL SALES BY MONTH
=========================================================
Cancelled orders are excluded.
This demonstrates:
    - DATE_TRUNC
    - SUM
    - GROUP BY
    - JOIN
=========================================================
*/

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

/*
=========================================================
6. AVERAGE ORDER VALUE
=========================================================
Calculates the average merchandise value of completed
orders.
Cancelled orders are excluded.
*/

SELECT
    ROUND(
        AVG(order_total),
        2
    ) AS average_order_value
FROM (
    SELECT
        o.order_id,
        SUM(
            oi.quantity * oi.unit_price
        ) AS order_total
    FROM orders o
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY o.order_id
) order_totals;

/*
=========================================================
7. ORDER TOTALS
=========================================================
Calculates the merchandise total, shipping cost,
and final total for each order.
=========================================================
*/

SELECT
    o.order_id,
    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS customer_name,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        ),
        2
    ) AS merchandise_total,
    o.shipping_cost,
    ROUND(
        SUM(
            oi.quantity * oi.unit_price
        ) + o.shipping_cost,
        2
    ) AS order_total,
    o.status
FROM orders o
JOIN customers c
    ON o.customer_id = c.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
GROUP BY
    o.order_id,
    c.first_name,
    c.last_name,
    o.shipping_cost,
    o.status
ORDER BY o.order_id;

/*
=========================================================
8. NUMBER OF ORDERS PER CUSTOMER
=========================================================
LEFT JOIN allows customers with zero orders to appear.
=========================================================
*/

SELECT
    c.customer_id,
    CONCAT(
        c.first_name,
        ' ',
        c.last_name
    ) AS customer_name,
    COUNT(o.order_id)
        AS order_count
FROM customers c
LEFT JOIN orders o
    ON c.customer_id = o.customer_id
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY order_count DESC;