/*
=========================================================
05. VIEWS
=========================================================
Wraps the analytical queries from 03_queries.sql as views
so the API layer (and pgAdmin) can query them directly
instead of repeating the SQL everywhere.

Run this AFTER 01_schema.sql, 02_seed.sql and
04_schema_extensions.sql.
=========================================================
*/

-- ---------------------------------------------------------
-- Monthly sales
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW monthly_sales_view AS
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_sales,
    COUNT(DISTINCT o.order_id) AS order_count
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY sales_month;

-- ---------------------------------------------------------
-- Best-selling products
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW top_products_view AS
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    SUM(oi.quantity) AS units_sold,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM products p
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
JOIN categories c ON p.category_id = c.category_id
WHERE o.status <> 'cancelled'
GROUP BY p.product_id, p.product_name, c.category_name
ORDER BY units_sold DESC;

-- ---------------------------------------------------------
-- Highest-spending customers
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW top_customers_view AS
SELECT
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    c.email,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_spent,
    COUNT(DISTINCT o.order_id) AS order_count
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY c.customer_id, c.first_name, c.last_name, c.email
ORDER BY total_spent DESC;

-- ---------------------------------------------------------
-- Products never purchased
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW unpurchased_products_view AS
SELECT p.product_id, p.product_name, p.sku
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;

-- ---------------------------------------------------------
-- Low inventory
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW low_inventory_view AS
SELECT product_id, product_name, sku, inventory_quantity
FROM products
WHERE inventory_quantity < 10 AND is_active = TRUE
ORDER BY inventory_quantity ASC;

-- ---------------------------------------------------------
-- Revenue by category
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW category_revenue_view AS
SELECT
    cat.category_id,
    cat.category_name,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
FROM categories cat
JOIN products p ON cat.category_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
WHERE o.status <> 'cancelled'
GROUP BY cat.category_id, cat.category_name
ORDER BY revenue DESC;

-- ---------------------------------------------------------
-- Average product rating
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW product_rating_view AS
SELECT
    p.product_id,
    p.product_name,
    ROUND(AVG(r.rating), 2) AS average_rating,
    COUNT(r.review_id) AS review_count
FROM products p
JOIN reviews r ON p.product_id = r.product_id
GROUP BY p.product_id, p.product_name
ORDER BY average_rating DESC;

-- ---------------------------------------------------------
-- Payment method breakdown
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW payment_method_summary_view AS
SELECT
    payment_method,
    COUNT(*) AS payment_count,
    ROUND(SUM(amount), 2) AS total_amount
FROM payments
WHERE payment_status = 'completed'
GROUP BY payment_method
ORDER BY payment_count DESC;

-- ---------------------------------------------------------
-- Dashboard summary (single-row KPI view)
-- ---------------------------------------------------------
CREATE OR REPLACE VIEW dashboard_kpi_view AS
SELECT
    (SELECT ROUND(SUM(oi.quantity * oi.unit_price), 2)
     FROM order_items oi
     JOIN orders o ON oi.order_id = o.order_id
     WHERE o.status <> 'cancelled') AS total_revenue,
    (SELECT COUNT(*) FROM orders WHERE status <> 'cancelled') AS total_orders,
    (SELECT COUNT(*) FROM customers WHERE is_active = TRUE) AS active_customers,
    (SELECT COUNT(*) FROM products WHERE inventory_quantity < 10) AS low_stock_count;

/*
=========================================================
VIEWS COMPLETE
=========================================================
*/
