/*
=========================================================
04. SCHEMA EXTENSIONS
=========================================================
Adds the features listed under "Future Improvements" in
the README:

    - customer roles (customer / admin)
    - product variants (size, color, etc.)
    - shopping carts
    - discounts / coupons
    - shipping tracking

Run this AFTER 01_schema.sql and 02_seed.sql.
=========================================================
*/

-- ---------------------------------------------------------
-- 1. ROLES (app-layer authorization)
-- ---------------------------------------------------------
-- A simple role column is enough for API/JWT-based
-- authorization. (Optional true Postgres DB roles + GRANTs
-- are shown separately in docs/DEPLOYMENT.md, since creating
-- login roles requires superuser access and is an
-- infrastructure concern, not a schema concern.)

ALTER TABLE customers
    ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'customer'
        CONSTRAINT customers_role_check
        CHECK (role IN ('customer', 'admin'));

-- Promote one seed customer to admin so the API/UI has
-- someone to log in as out of the box.
UPDATE customers
SET role = 'admin'
WHERE customer_id = (SELECT MIN(customer_id) FROM customers);

-- ---------------------------------------------------------
-- 2. PRODUCT VARIANTS
-- ---------------------------------------------------------
-- A product can have variants (size, color, etc). Each
-- variant has its own SKU, price adjustment, and inventory.
-- If a product has no variants, it is sold directly using
-- products.inventory_quantity as before.

CREATE TABLE product_variants (
    variant_id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    variant_name VARCHAR(100) NOT NULL,      -- e.g. 'Blue / Large'
    size VARCHAR(30),
    color VARCHAR(30),
    sku VARCHAR(60) NOT NULL UNIQUE,
    price_adjustment NUMERIC(10, 2) NOT NULL DEFAULT 0,
    inventory_quantity INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT fk_variants_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT variants_inventory_check
        CHECK (inventory_quantity >= 0)
);

CREATE INDEX idx_variants_product_id ON product_variants(product_id);

-- order_items can optionally reference a specific variant
ALTER TABLE order_items
    ADD COLUMN variant_id INTEGER
        CONSTRAINT fk_order_items_variant
        REFERENCES product_variants(variant_id)
        ON DELETE RESTRICT;

-- ---------------------------------------------------------
-- 3. SHOPPING CARTS
-- ---------------------------------------------------------

CREATE TABLE carts (
    cart_id SERIAL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_carts_customer
        FOREIGN KEY (customer_id)
        REFERENCES customers(customer_id)
        ON DELETE CASCADE,
    CONSTRAINT carts_status_check
        CHECK (status IN ('active', 'converted', 'abandoned'))
);

CREATE INDEX idx_carts_customer_id ON carts(customer_id);

CREATE TABLE cart_items (
    cart_item_id SERIAL PRIMARY KEY,
    cart_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    variant_id INTEGER,
    quantity INTEGER NOT NULL,
    added_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_cart_items_cart
        FOREIGN KEY (cart_id)
        REFERENCES carts(cart_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_product
        FOREIGN KEY (product_id)
        REFERENCES products(product_id)
        ON DELETE CASCADE,
    CONSTRAINT fk_cart_items_variant
        FOREIGN KEY (variant_id)
        REFERENCES product_variants(variant_id)
        ON DELETE CASCADE,
    CONSTRAINT cart_items_quantity_check
        CHECK (quantity > 0),
    CONSTRAINT unique_cart_product_variant
        UNIQUE (cart_id, product_id, variant_id)
);

CREATE INDEX idx_cart_items_cart_id ON cart_items(cart_id);

-- ---------------------------------------------------------
-- 4. DISCOUNTS / COUPONS
-- ---------------------------------------------------------

CREATE TABLE discounts (
    discount_id SERIAL PRIMARY KEY,
    code VARCHAR(30) NOT NULL UNIQUE,
    description VARCHAR(255),
    discount_type VARCHAR(20) NOT NULL,
    discount_value NUMERIC(10, 2) NOT NULL,
    starts_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP,
    max_uses INTEGER,
    times_used INTEGER NOT NULL DEFAULT 0,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    CONSTRAINT discounts_type_check
        CHECK (discount_type IN ('percentage', 'fixed')),
    CONSTRAINT discounts_value_check
        CHECK (discount_value > 0)
);

ALTER TABLE orders
    ADD COLUMN discount_id INTEGER
        CONSTRAINT fk_orders_discount
        REFERENCES discounts(discount_id)
        ON DELETE SET NULL,
    ADD COLUMN discount_amount NUMERIC(10, 2) NOT NULL DEFAULT 0
        CONSTRAINT orders_discount_amount_check
        CHECK (discount_amount >= 0);

-- ---------------------------------------------------------
-- 5. SHIPPING TRACKING
-- ---------------------------------------------------------

CREATE TABLE shipping_tracking (
    tracking_id SERIAL PRIMARY KEY,
    order_id INTEGER NOT NULL UNIQUE,
    carrier VARCHAR(60),
    tracking_number VARCHAR(100),
    status VARCHAR(30) NOT NULL DEFAULT 'label_created',
    shipped_at TIMESTAMP,
    estimated_delivery DATE,
    delivered_at TIMESTAMP,
    CONSTRAINT fk_tracking_order
        FOREIGN KEY (order_id)
        REFERENCES orders(order_id)
        ON DELETE CASCADE,
    CONSTRAINT tracking_status_check
        CHECK (
            status IN (
                'label_created',
                'in_transit',
                'out_for_delivery',
                'delivered',
                'exception'
            )
        )
);

/*
=========================================================
SCHEMA EXTENSIONS COMPLETE
=========================================================
*/
