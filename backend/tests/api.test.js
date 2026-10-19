/**
 * Integration tests for the API.
 *
 * These run against a real Postgres database (schema + seed +
 * extensions loaded), pointed to by DATABASE_URL. The CI workflow
 * (.github/workflows/ci.yml) spins up a disposable Postgres service
 * and loads all six database/*.sql files before running this suite.
 *
 * Run locally with:
 *   createdb ecommerce_test
 *   psql ecommerce_test -f ../database/01_schema.sql
 *   psql ecommerce_test -f ../database/02_seed.sql
 *   psql ecommerce_test -f ../database/04_schema_extensions.sql
 *   psql ecommerce_test -f ../database/05_views.sql
 *   psql ecommerce_test -f ../database/06_functions_and_procedures.sql
 *   psql ecommerce_test -f ../database/07_triggers.sql
 *   DATABASE_URL=postgresql://localhost/ecommerce_test npm test
 */

const request = require('supertest');
const app = require('../src/server');

describe('GET /api/health', () => {
  it('returns ok', async () => {
    const res = await request(app).get('/api/health');
    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
  });
});

describe('GET /api/products', () => {
  it('returns a list of active products', async () => {
    const res = await request(app).get('/api/products');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body.length).toBeGreaterThan(0);
    expect(res.body[0]).toHaveProperty('product_name');
  });

  it('filters by search term', async () => {
    const res = await request(app).get('/api/products?search=Headphones');
    expect(res.status).toBe(200);
    expect(res.body.every((p) => /headphones/i.test(p.product_name))).toBe(true);
  });
});

describe('auth + protected routes', () => {
  const email = `test_${Date.now()}@example.com`;
  let token;

  it('registers a new customer', async () => {
    const res = await request(app).post('/api/auth/register').send({
      first_name: 'Test',
      last_name: 'User',
      email,
      password: 'password123',
    });
    expect(res.status).toBe(201);
    expect(res.body.token).toBeDefined();
    token = res.body.token;
  });

  it('rejects order placement without a token', async () => {
    const res = await request(app).post('/api/orders').send({ items: [] });
    expect(res.status).toBe(401);
  });

  it('rejects sales analytics for a non-admin token', async () => {
    const res = await request(app)
      .get('/api/sales/kpis')
      .set('Authorization', `Bearer ${token}`);
    expect(res.status).toBe(403);
  });

  it('rejects an order with an empty items array', async () => {
    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [] });
    expect(res.status).toBe(400);
  });
});

describe('place_order overselling protection', () => {
  it('rejects an order that exceeds available inventory', async () => {
    const email = `oversell_${Date.now()}@example.com`;
    const register = await request(app).post('/api/auth/register').send({
      first_name: 'Over',
      last_name: 'Seller',
      email,
      password: 'password123',
    });
    const token = register.body.token;

    const products = await request(app).get('/api/products');
    const product = products.body[0];

    const res = await request(app)
      .post('/api/orders')
      .set('Authorization', `Bearer ${token}`)
      .send({ items: [{ product_id: product.product_id, quantity: 999999 }] });

    expect(res.status).toBe(400);
    expect(res.body.error).toMatch(/insufficient stock/i);
  });
});
