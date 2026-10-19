const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// Every route here is admin-only: it's business intelligence data.
router.use(requireAuth, requireAdmin);

router.get('/monthly', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM monthly_sales_view');
  res.json(rows);
});

router.get('/top-products', async (req, res) => {
  const limit = Number(req.query.limit) || 10;
  const { rows } = await db.query('SELECT * FROM top_products_view LIMIT $1', [limit]);
  res.json(rows);
});

router.get('/top-customers', async (req, res) => {
  const limit = Number(req.query.limit) || 10;
  const { rows } = await db.query('SELECT * FROM top_customers_view LIMIT $1', [limit]);
  res.json(rows);
});

router.get('/low-inventory', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM low_inventory_view');
  res.json(rows);
});

router.get('/category-revenue', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM category_revenue_view');
  res.json(rows);
});

router.get('/payment-methods', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM payment_method_summary_view');
  res.json(rows);
});

router.get('/product-ratings', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM product_rating_view');
  res.json(rows);
});

router.get('/kpis', async (_req, res) => {
  const { rows } = await db.query('SELECT * FROM dashboard_kpi_view');
  res.json(rows[0]);
});

module.exports = router;
