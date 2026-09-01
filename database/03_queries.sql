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

/*
=========================================================
9. BEST-SELLING PRODUCTS
=========================================================
Ranks products by total quantity sold.
Cancelled orders are excluded.
*/

SELECT
    p.product_id,
    p.product_name,
    SUM(oi.quantity) AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS revenue
FROM products p
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY
    p.product_id,
    p.product_name
ORDER BY units_sold DESC;

/*
=========================================================
10. CUSTOMERS WITH THE HIGHEST SPENDING
=========================================================
Demonstrates:
    - Multiple JOINs
    - SUM
    - GROUP BY
    - ORDER BY
=========================================================
*/

SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name)
        AS customer_name,
    COUNT(DISTINCT o.order_id)
        AS total_orders,
    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS total_spent
FROM customers c
JOIN orders o
    ON c.customer_id = o.customer_id
JOIN order_items oi
    ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY
    c.customer_id,
    c.first_name,
    c.last_name
ORDER BY total_spent DESC;

/*
=========================================================
11. MOST POPULAR CATEGORIES
=========================================================
Ranks categories based on units sold.
*/

SELECT
    c.category_id,
    c.category_name,
    SUM(oi.quantity)
        AS units_sold,
    ROUND(
        SUM(oi.quantity * oi.unit_price),
        2
    ) AS revenue
FROM categories c
JOIN products p
    ON c.category_id = p.category_id
JOIN order_items oi
    ON p.product_id = oi.product_id
JOIN orders o
    ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY
    c.category_id,
    c.category_name
ORDER BY units_sold DESC;

/*
=========================================================
12. CUSTOMER SPENDING ABOVE THE AVERAGE
=========================================================
Demonstrates a subquery.
First calculates customer spending.
Then compares each customer's spending against
the average customer spending.
=========================================================
*/

WITH customer_spending AS (
    SELECT
        c.customer_id,
        CONCAT(
            c.first_name,
            ' ',
            c.last_name
        ) AS customer_name,
        SUM(
            oi.quantity * oi.unit_price
        ) AS total_spent
    FROM customers c
    JOIN orders o
        ON c.customer_id = o.customer_id
    JOIN order_items oi
        ON o.order_id = oi.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY
        c.customer_id,
        c.first_name,
        c.last_name
)
SELECT
    customer_id,
    customer_name,
    ROUND(total_spent, 2)
        AS total_spent
FROM customer_spending
WHERE total_spent > (
    SELECT AVG(total_spent)
    FROM customer_spending
)
ORDER BY total_spent DESC;

/*
=========================================================
13. PRODUCTS WITH SALES ABOVE THE PRODUCT AVERAGE
=========================================================
Uses a subquery to determine the average product
revenue.
=========================================================
*/

WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        SUM(
            oi.quantity * oi.unit_price
        ) AS revenue
    FROM products p
    JOIN order_items oi
        ON p.product_id = oi.product_id
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE o.status <> 'cancelled'
    GROUP BY
        p.product_id,
        p.product_name
)
SELECT
    product_id,
    product_name,
    ROUND(revenue, 2)
        AS revenue
FROM product_sales
WHERE revenue > (
    SELECT AVG(revenue)
    FROM product_sales
)
ORDER BY revenue DESC;

/*
=========================================================
14. MONTHLY ORDER COUNT
=========================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        order_date
    )::DATE AS month,
    COUNT(*) AS number_of_orders
FROM orders
WHERE status <> 'cancelled'
GROUP BY DATE_TRUNC('month', order_date)
ORDER BY month;

/*
=========================================================
15. LOW INVENTORY PRODUCTS
=========================================================
Shows products with fewer than 10 units available.
*/

SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.inventory_quantity
FROM products p
JOIN categories c
    ON p.category_id = c.category_id
WHERE p.inventory_quantity < 10
ORDER BY p.inventory_quantity ASC;

/*
=========================================================
16. LOW INVENTORY REPORT
=========================================================
A practical business report.
Products with:
    0-4 units  = Critical
    5-9 units  = Low
    10+ units  = Normal
=========================================================
*/

SELECT
    product_id,
    product_name,
    inventory_quantity,
    CASE
        WHEN inventory_quantity <= 4
            THEN 'Critical'
        WHEN inventory_quantity <= 9
            THEN 'Low'
        ELSE 'Normal'
    END AS inventory_status
FROM products
ORDER BY inventory_quantity ASC;

/*
=========================================================
17. PRODUCTS THAT HAVE NEVER BEEN PURCHASED
=========================================================
Uses LEFT JOIN.
If no matching order_items exist, the product has
never been purchased.
*/

SELECT
    p.product_id,
    p.product_name,
    p.price,
    p.inventory_quantity
FROM products p
LEFT JOIN order_items oi
    ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL
ORDER BY p.product_name;

/*
=========================================================
18. PRODUCTS THAT HAVE NEVER BEEN PURCHASED
=========================================================
Alternative solution using NOT EXISTS.
This demonstrates a subquery.
*/

SELECT
    p.product_id,
    p.product_name,
    p.price
FROM products p
WHERE NOT EXISTS (
    SELECT 1
    FROM order_items oi
    JOIN orders o
        ON oi.order_id = o.order_id
    WHERE oi.product_id = p.product_id
        AND o.status <> 'cancelled'
)
ORDER BY p.product_name;

/*
=========================================================
19. PRODUCTS WITH THEIR AVERAGE REVIEW RATING
=========================================================
LEFT JOIN is used so products without reviews are
also displayed.
*/

SELECT
    p.product_id,
    p.product_name,
    COALESCE(
        ROUND(AVG(r.rating), 2),
        0
    ) AS average_rating,
    COUNT(r.review_id)
        AS review_count
FROM products p
LEFT JOIN reviews r
    ON p.product_id = r.product_id
GROUP BY
    p.product_id,
    p.product_name
ORDER BY average_rating DESC;

/*
=========================================================
20. TOP-RATED PRODUCTS
=========================================================
Products must have at least one review.
HAVING filters groups after aggregation.
*/

SELECT
    p.product_name,
    ROUND(
        AVG(r.rating),
        2
    ) AS average_rating,
    COUNT(r.review_id)
        AS review_count
FROM products p
JOIN reviews r
    ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
HAVING AVG(r.rating) >= 4
ORDER BY average_rating DESC;

/*
=========================================================
21. PAYMENT METHOD USAGE
=========================================================
*/

SELECT
    payment_method,
    COUNT(*) AS number_of_payments,
    ROUND(
        SUM(amount),
        2
    ) AS total_payment_amount
FROM payments
WHERE payment_status = 'completed'
GROUP BY payment_method
ORDER BY total_payment_amount DESC;

/*
=========================================================
22. DATABASE INDEX INFORMATION
=========================================================
PostgreSQL-specific query that allows you to inspect
indexes created for this project.
=========================================================
*/

SELECT
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename, indexname;

/*
=========================================================
END OF QUERY COLLECTION
=========================================================
*/