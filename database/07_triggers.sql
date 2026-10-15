/*
=========================================================
07. TRIGGERS
=========================================================
Run this AFTER 04_schema_extensions.sql.
=========================================================
*/

-- ---------------------------------------------------------
-- 1. Decrement inventory when an order_item is inserted,
--    and block the insert entirely if there isn't enough
--    stock (prevents overselling at the database level,
--    regardless of which app/client is writing to the DB).
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_decrement_inventory()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_available INTEGER;
BEGIN
    IF NEW.variant_id IS NOT NULL THEN
        SELECT inventory_quantity INTO v_available
        FROM product_variants
        WHERE variant_id = NEW.variant_id
        FOR UPDATE;

        IF v_available IS NULL THEN
            RAISE EXCEPTION 'Variant % does not exist', NEW.variant_id;
        END IF;

        IF v_available < NEW.quantity THEN
            RAISE EXCEPTION
                'Insufficient stock for variant %: requested %, available %',
                NEW.variant_id, NEW.quantity, v_available;
        END IF;

        UPDATE product_variants
        SET inventory_quantity = inventory_quantity - NEW.quantity
        WHERE variant_id = NEW.variant_id;
    ELSE
        SELECT inventory_quantity INTO v_available
        FROM products
        WHERE product_id = NEW.product_id
        FOR UPDATE;

        IF v_available IS NULL THEN
            RAISE EXCEPTION 'Product % does not exist', NEW.product_id;
        END IF;

        IF v_available < NEW.quantity THEN
            RAISE EXCEPTION
                'Insufficient stock for product %: requested %, available %',
                NEW.product_id, NEW.quantity, v_available;
        END IF;

        UPDATE products
        SET inventory_quantity = inventory_quantity - NEW.quantity
        WHERE product_id = NEW.product_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_decrement_inventory
    BEFORE INSERT ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_decrement_inventory();

-- ---------------------------------------------------------
-- 2. Restore inventory automatically when an order is
--    cancelled (status changes to 'cancelled').
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_restore_inventory_on_cancel()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'cancelled' AND OLD.status <> 'cancelled' THEN
        UPDATE products p
        SET inventory_quantity = p.inventory_quantity + oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.order_id
          AND oi.product_id = p.product_id
          AND oi.variant_id IS NULL;

        UPDATE product_variants v
        SET inventory_quantity = v.inventory_quantity + oi.quantity
        FROM order_items oi
        WHERE oi.order_id = NEW.order_id
          AND oi.variant_id = v.variant_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_restore_inventory_on_cancel
    AFTER UPDATE OF status ON orders
    FOR EACH ROW
    EXECUTE FUNCTION fn_restore_inventory_on_cancel();

-- ---------------------------------------------------------
-- 3. Keep carts.updated_at current whenever cart_items
--    change.
-- ---------------------------------------------------------

CREATE OR REPLACE FUNCTION fn_touch_cart()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE carts
    SET updated_at = CURRENT_TIMESTAMP
    WHERE cart_id = COALESCE(NEW.cart_id, OLD.cart_id);
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_touch_cart
    AFTER INSERT OR UPDATE OR DELETE ON cart_items
    FOR EACH ROW
    EXECUTE FUNCTION fn_touch_cart();

/*
=========================================================
TRIGGERS COMPLETE
=========================================================
*/
