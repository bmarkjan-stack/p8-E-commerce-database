const express = require('express');
const db = require('../db');
const { requireAuth, requireAdmin } = require('../middleware/auth');

const router = express.Router();

// GET /api/products?category=1&search=phone
router.get('/', async (req, res) => {
  const { category, search } = req.query;
  const conditions = ['p.is_active = TRUE'];
  const params = [];

  if (category) {
    params.push(category);
    conditions.push(`p.category_id = $${params.length}`);
  }
  if (search) {
    params.push(`%${search}%`);
    conditions.push(`p.product_name ILIKE $${params.length}`);
  }

  const { rows } = await db.query(
    `SELECT p.product_id, p.product_name, p.description, p.sku, p.price,
            p.inventory_quantity, c.category_name
     FROM products p
     JOIN categories c ON p.category_id = c.category_id
     WHERE ${conditions.join(' AND ')}
     ORDER BY p.product_name`,
    params
  );
  res.json(rows);
});

// GET /api/products/:id  (includes variants + review summary)
router.get('/:id', async (req, res) => {
  const { id } = req.params;
  const productResult = await db.query(
    `SELECT p.*, c.category_name FROM products p
     JOIN categories c ON p.category_id = c.category_id
     WHERE p.product_id = $1`,
    [id]
  );
  if (productResult.rows.length === 0) {
    return res.status(404).json({ error: 'Product not found' });
  }

  const [variants, rating] = await Promise.all([
    db.query('SELECT * FROM product_variants WHERE product_id = $1 AND is_active = TRUE', [id]),
    db.query(
      `SELECT ROUND(AVG(rating), 2) AS average_rating, COUNT(*) AS review_count
       FROM reviews WHERE product_id = $1`,
      [id]
    ),
  ]);

  res.json({
    ...productResult.rows[0],
    variants: variants.rows,
    average_rating: rating.rows[0].average_rating,
    review_count: rating.rows[0].review_count,
  });
});

// POST /api/products  (admin only)
router.post('/', requireAuth, requireAdmin, async (req, res) => {
  const { category_id, product_name, description, sku, price, inventory_quantity } = req.body;
  try {
    const { rows } = await db.query(
      `INSERT INTO products (category_id, product_name, description, sku, price, inventory_quantity)
       VALUES ($1, $2, $3, $4, $5, $6) RETURNING *`,
      [category_id, product_name, description, sku, price, inventory_quantity || 0]
    );
    res.status(201).json(rows[0]);
  } catch (err) {
    console.error(err);
    res.status(400).json({ error: err.message });
  }
});

// PATCH /api/products/:id  (admin only)
router.patch('/:id', requireAuth, requireAdmin, async (req, res) => {
  const { id } = req.params;
  const fields = ['product_name', 'description', 'price', 'inventory_quantity', 'is_active'];
  const updates = [];
  const params = [];

  fields.forEach((field) => {
    if (req.body[field] !== undefined) {
      params.push(req.body[field]);
      updates.push(`${field} = $${params.length}`);
    }
  });

  if (updates.length === 0) {
    return res.status(400).json({ error: 'No valid fields to update' });
  }

  params.push(id);
  const { rows } = await db.query(
    `UPDATE products SET ${updates.join(', ')} WHERE product_id = $${params.length} RETURNING *`,
    params
  );
  if (rows.length === 0) return res.status(404).json({ error: 'Product not found' });
  res.json(rows[0]);
});

module.exports = router;
