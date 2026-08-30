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
