const express = require('express');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');

const router = express.Router();

async function getOrCreateActiveCart(customerId) {
  const existing = await db.query(
    `SELECT * FROM carts WHERE customer_id = $1 AND status = 'active' LIMIT 1`,
    [customerId]
  );
  if (existing.rows[0]) return existing.rows[0];

  const created = await db.query(
    `INSERT INTO carts (customer_id, status) VALUES ($1, 'active') RETURNING *`,
    [customerId]
  );
  return created.rows[0];
}

// GET /api/cart  - the logged-in customer's active cart
router.get('/', requireAuth, async (req, res) => {
  const cart = await getOrCreateActiveCart(req.user.customerId);
  const items = await db.query(
    `SELECT ci.*, p.product_name, p.price
     FROM cart_items ci
     JOIN products p ON ci.product_id = p.product_id
     WHERE ci.cart_id = $1`,
    [cart.cart_id]
  );
  res.json({ ...cart, items: items.rows });
});

// POST /api/cart/items  { product_id, quantity, variant_id? }
//
// Does a manual check-then-insert/update instead of an ON CONFLICT
// upsert, because Postgres treats NULL <> NULL in unique constraints:
// two cart_items rows with the same (cart_id, product_id) and a NULL
// variant_id would NOT collide on the unique_cart_product_variant
// constraint, so a plain ON CONFLICT upsert would silently create
// duplicate rows for products with no variant. IS NOT DISTINCT FROM
// treats NULL as a normal comparable value, so this lookup works
// whether variant_id is set or not.
router.post('/items', requireAuth, async (req, res) => {
  const { product_id, quantity, variant_id } = req.body;
  const qty = quantity || 1;
  const variantId = variant_id || null;
  const cart = await getOrCreateActiveCart(req.user.customerId);

  const existing = await db.query(
    `SELECT * FROM cart_items
     WHERE cart_id = $1 AND product_id = $2 AND variant_id IS NOT DISTINCT FROM $3`,
    [cart.cart_id, product_id, variantId]
  );

  let result;
  if (existing.rows[0]) {
    result = await db.query(
      `UPDATE cart_items SET quantity = quantity + $1 WHERE cart_item_id = $2 RETURNING *`,
      [qty, existing.rows[0].cart_item_id]
    );
  } else {
    result = await db.query(
      `INSERT INTO cart_items (cart_id, product_id, variant_id, quantity)
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [cart.cart_id, product_id, variantId, qty]
    );
  }
  res.status(201).json(result.rows[0]);
});

// DELETE /api/cart/items/:cartItemId
router.delete('/items/:cartItemId', requireAuth, async (req, res) => {
  await db.query(
    `DELETE FROM cart_items ci USING carts c
     WHERE ci.cart_id = c.cart_id
       AND ci.cart_item_id = $1
       AND c.customer_id = $2`,
    [req.params.cartItemId, req.user.customerId]
  );
  res.status(204).send();
});

module.exports = router;
