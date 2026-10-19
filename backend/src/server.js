require('dotenv').config();
const express = require('express');
const cors = require('cors');

const authRoutes = require('./routes/auth');
const productRoutes = require('./routes/products');
const orderRoutes = require('./routes/orders');
const cartRoutes = require('./routes/cart');
const salesRoutes = require('./routes/sales');

const app = express();

const allowedOrigins = (process.env.CORS_ORIGIN || '').split(',').map((s) => s.trim());
app.use(cors({ origin: allowedOrigins.length ? allowedOrigins : true }));
app.use(express.json());

app.get('/api/health', (_req, res) => res.json({ status: 'ok' }));

app.use('/api/auth', authRoutes);
app.use('/api/products', productRoutes);
app.use('/api/orders', orderRoutes);
app.use('/api/cart', cartRoutes);
app.use('/api/sales', salesRoutes);

// 404 handler
app.use((req, res) => res.status(404).json({ error: `No route for ${req.method} ${req.path}` }));

// Central error handler
app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: 'Internal server error' });
});

const PORT = process.env.PORT || 4000;
if (require.main === module) {
  app.listen(PORT, () => console.log(`API listening on port ${PORT}`));
}

module.exports = app;
