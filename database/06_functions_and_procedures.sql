/*
=========================================================
06. FUNCTIONS & STORED PROCEDURES
=========================================================
Run this AFTER 04_schema_extensions.sql (and ideally
07_triggers.sql, since place_order() relies on the
inventory-decrementing trigger on order_items).
=========================================================
*/

-- ---------------------------------------------------------
-- place_order()
-- ---------------------------------------------------------
-- Places a full order in a single transaction:
--   1. Validates the customer exists.
--   2. Creates the order row.
--   3. Inserts one order_item per line in p_items.
--   4. Inventory is decremented automatically by the
--      trg_decrement_inventory trigger (see 07_triggers.sql),
--      which also blocks overselling.
--   5. Creates a matching 'pending' payment row.
--
-- p_items format (JSONB array):
--   '[{"product_id": 1, "quantity": 2}, {"product_id": 4, "quantity": 1}]'
--
-- Returns the new order_id.
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION place_order(
    p_customer_id INTEGER,
    p_shipping_address_id INTEGER,
    p_items JSONB,
    p_payment_method VARCHAR DEFAULT 'credit_card',
    p_shipping_cost NUMERIC DEFAULT 0
)
RETURNS INTEGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_order_id INTEGER;
    v_item JSONB;
    v_product_id INTEGER;
    v_quantity INTEGER;
    v_unit_price NUMERIC(10, 2);
    v_order_total NUMERIC(10, 2) := 0;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM customers WHERE customer_id = p_customer_id) THEN
        RAISE EXCEPTION 'Customer % does not exist', p_customer_id;
    END IF;

    IF jsonb_array_length(p_items) = 0 THEN
        RAISE EXCEPTION 'Cannot place an order with no items';
    END IF;

    INSERT INTO orders (customer_id, shipping_address_id, status, shipping_cost)
    VALUES (p_customer_id, p_shipping_address_id, 'pending', p_shipping_cost)
    RETURNING order_id INTO v_order_id;

    FOR v_item IN SELECT * FROM jsonb_array_elements(p_items)
    LOOP
        v_product_id := (v_item ->> 'product_id')::INTEGER;
        v_quantity   := (v_item ->> 'quantity')::INTEGER;

        SELECT price INTO v_unit_price
        FROM products
        WHERE product_id = v_product_id AND is_active = TRUE;

        IF v_unit_price IS NULL THEN
            RAISE EXCEPTION 'Product % is not available', v_product_id;
        END IF;

        -- Insert triggers trg_decrement_inventory, which will
        -- raise an exception (rolling back the whole order) if
        -- there isn't enough stock.
        INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES (v_order_id, v_product_id, v_quantity, v_unit_price);

        v_order_total := v_order_total + (v_unit_price * v_quantity);
    END LOOP;

    INSERT INTO payments (order_id, payment_method, payment_status, amount)
    VALUES (v_order_id, p_payment_method, 'pending', v_order_total + p_shipping_cost);

    RETURN v_order_id;
END;
$$;

-- ---------------------------------------------------------
-- get_customer_lifetime_value(customer_id)
-- ---------------------------------------------------------
-- Returns total lifetime spend for a customer across all
-- non-cancelled orders. Used by the API's customer detail
-- endpoint and by top_customers_view-style reporting for a
-- single customer on demand.
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION get_customer_lifetime_value(p_customer_id INTEGER)
RETURNS NUMERIC
LANGUAGE sql
STABLE
AS $$
    SELECT COALESCE(ROUND(SUM(oi.quantity * oi.unit_price), 2), 0)
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.customer_id = p_customer_id
      AND o.status <> 'cancelled';
$$;

-- ---------------------------------------------------------
-- apply_discount_code(order_id, code)
-- ---------------------------------------------------------
-- Validates a discount code (active, not expired, uses left)
-- and applies it to an existing order, updating
-- orders.discount_id / discount_amount and payments.amount.
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION apply_discount_code(
    p_order_id INTEGER,
    p_code VARCHAR
)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_discount discounts%ROWTYPE;
    v_subtotal NUMERIC(10, 2);
    v_discount_amount NUMERIC(10, 2);
BEGIN
    SELECT * INTO v_discount
    FROM discounts
    WHERE code = p_code
      AND is_active = TRUE
      AND starts_at <= CURRENT_TIMESTAMP
      AND (expires_at IS NULL OR expires_at >= CURRENT_TIMESTAMP)
      AND (max_uses IS NULL OR times_used < max_uses);

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Discount code % is invalid or expired', p_code;
    END IF;

    SELECT SUM(quantity * unit_price) INTO v_subtotal
    FROM order_items
    WHERE order_id = p_order_id;

    v_discount_amount := CASE v_discount.discount_type
        WHEN 'percentage' THEN ROUND(v_subtotal * v_discount.discount_value / 100.0, 2)
        ELSE LEAST(v_discount.discount_value, v_subtotal)
    END;

    UPDATE orders
    SET discount_id = v_discount.discount_id,
        discount_amount = v_discount_amount
    WHERE order_id = p_order_id;

    UPDATE discounts
    SET times_used = times_used + 1
    WHERE discount_id = v_discount.discount_id;

    UPDATE payments
    SET amount = amount - v_discount_amount
    WHERE order_id = p_order_id;

    RETURN v_discount_amount;
END;
$$;

/*
=========================================================
FUNCTIONS & PROCEDURES COMPLETE
=========================================================
*/
