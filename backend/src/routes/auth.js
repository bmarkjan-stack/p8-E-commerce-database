const express = require('express');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../db');

const router = express.Router();

function signToken(customer) {
  return jwt.sign(
    { customerId: customer.customer_id, role: customer.role, email: customer.email },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '8h' }
  );
}

// POST /api/auth/register
router.post('/register', async (req, res) => {
  const { first_name, last_name, email, password } = req.body;
  if (!first_name || !last_name || !email || !password) {
    return res.status(400).json({ error: 'first_name, last_name, email, password are required' });
  }

  try {
    const passwordHash = await bcrypt.hash(password, 10);
    const { rows } = await db.query(
      `INSERT INTO customers (first_name, last_name, email, password_hash)
       VALUES ($1, $2, LOWER($3), $4)
       RETURNING customer_id, first_name, last_name, email, role`,
      [first_name, last_name, email, passwordHash]
    );
    const customer = rows[0];
    return res.status(201).json({ token: signToken(customer), customer });
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ error: 'Email already registered' });
    }
    console.error(err);
    return res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/auth/login
router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'email and password are required' });
  }

  try {
    const { rows } = await db.query(
      `SELECT customer_id, first_name, last_name, email, password_hash, role
       FROM customers WHERE email = LOWER($1) AND is_active = TRUE`,
      [email]
    );
    const customer = rows[0];
    if (!customer) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    const valid = await bcrypt.compare(password, customer.password_hash);
    if (!valid) {
      return res.status(401).json({ error: 'Invalid credentials' });
    }

    delete customer.password_hash;
    return res.json({ token: signToken(customer), customer });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: 'Login failed' });
  }
});

module.exports = router;
