/*
=========================================================
pgTAP TESTS
=========================================================
Requires the pgtap extension:
    CREATE EXTENSION IF NOT EXISTS pgtap;

Run with:
    pg_prove -d ecommerce_test database/tests/pgtap_tests.sql
or:
    psql ecommerce_test -f database/tests/pgtap_tests.sql
=========================================================
*/

BEGIN;
SELECT plan(7);

-- 1. Core tables exist
SELECT has_table('customers');
SELECT has_table('product_variants');
SELECT has_table('carts');
SELECT has_table('discounts');
SELECT has_table('shipping_tracking');

-- 2. Price constraint rejects negative prices
SELECT throws_ok(
    $$INSERT INTO products (category_id, product_name, sku, price)
      VALUES (1, 'Bad Product', 'BAD-SKU-1', -10)$$,
    23514,
    NULL,
    'products.price CHECK rejects a negative price'
);

-- 3. Overselling trigger blocks an order_item that exceeds stock
SELECT throws_ok(
    $$INSERT INTO order_items (order_id, product_id, quantity, unit_price)
      SELECT o.order_id, p.product_id, 999999, p.price
      FROM orders o, products p
      LIMIT 1$$,
    'P0001',
    NULL,
    'trg_decrement_inventory blocks an order_item that exceeds available stock'
);

SELECT * FROM finish();
ROLLBACK;
