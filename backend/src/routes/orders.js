const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// POST /api/orders  { shipping_address_id, items: [{product_id, quantity}], payment_method }
router.post('/', requireAuth, async (req, res) => {
  const { shipping_address_id, items, payment_method, shipping_cost } = req.body;
  if (!Array.isArray(items) || items.length === 0) {
    return res.status(400).json({ error: 'items must be a non-empty array' });
  }

  try {
    // place_order() runs the insert + trigger-based inventory
    // check + payment row creation in a single DB transaction.
    const { rows } = await db.query(
      `SELECT place_order($1, $2, $3::jsonb, $4, $5) AS order_id`,
      [
        req.user.customerId,
        shipping_address_id || null,
        JSON.stringify(items),
        payment_method || 'credit_card',
        shipping_cost || 0,
      ]
    );
    const orderId = rows[0].order_id;
    const order = await db.query('SELECT * FROM orders WHERE order_id = $1', [orderId]);
    res.status(201).json(order.rows[0]);
  } catch (err) {
    // Includes "Insufficient stock" errors raised by the trigger
    res.status(400).json({ error: err.message });
  }
});

// GET /api/orders/:id  (owner or admin)
router.get('/:id', requireAuth, async (req, res) => {
  const { id } = req.params;
  const orderResult = await db.query('SELECT * FROM orders WHERE order_id = $1', [id]);
  const order = orderResult.rows[0];
  if (!order) return res.status(404).json({ error: 'Order not found' });

  if (order.customer_id !== req.user.customerId && req.user.role !== 'admin') {
    return res.status(403).json({ error: 'Not authorized to view this order' });
  }

  const items = await db.query(
    `SELECT oi.*, p.product_name FROM order_items oi
     JOIN products p ON oi.product_id = p.product_id
     WHERE oi.order_id = $1`,
    [id]
  );
  const tracking = await db.query('SELECT * FROM shipping_tracking WHERE order_id = $1', [id]);

  res.json({ ...order, items: items.rows, tracking: tracking.rows[0] || null });
});

// GET /api/orders  (admin: all orders, customer: own orders)
router.get('/', requireAuth, async (req, res) => {
  const query =
    req.user.role === 'admin'
      ? 'SELECT * FROM orders ORDER BY order_date DESC LIMIT 100'
      : 'SELECT * FROM orders WHERE customer_id = $1 ORDER BY order_date DESC';
  const params = req.user.role === 'admin' ? [] : [req.user.customerId];
  const { rows } = await db.query(query, params);
  res.json(rows);
});

// PATCH /api/orders/:id/status  (admin only)
router.patch('/:id/status', requireAuth, requireAdmin, async (req, res) => {
  const { status } = req.body;
  const { rows } = await db.query(
    `UPDATE orders SET status = $1 WHERE order_id = $2 RETURNING *`,
    [status, req.params.id]
  );
  if (rows.length === 0) return res.status(404).json({ error: 'Order not found' });
  res.json(rows[0]);
});

module.exports = router;
