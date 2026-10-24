# E-Commerce Database

A PostgreSQL database for an online store, with a REST API and browser pages built on top of it.

The schema, constraints, and business logic are the main focus. Stock levels are enforced by triggers, orders are placed by a stored function, and reports are reusable views. A small Express API and three browser pages sit on top of the database so the data can be used end to end.

![E-commerce live demo](live-demo/e-commerce-live-demo.gif)

---

## Table of Contents

- [Live Demo](#live-demo)
- [What's Included](#whats-included)
- [Quick Start with Docker](#quick-start-with-docker)
- [Setup Without Docker](#setup-without-docker)
- [Database Design](#database-design)
- [Analytics Queries](#analytics-queries)
- [Views](#views)
- [Stored Functions](#stored-functions)
- [Triggers](#triggers)
- [REST API](#rest-api)
- [Frontend Pages](#frontend-pages)
- [Testing and CI](#testing-and-ci)
- [Deployment](#deployment)
- [Project Structure](#project-structure)
- [Technologies](#technologies)
- [Future Improvements](#future-improvements)
- [License](#license)
- [Author](#author)

---

## Live Demo

![E-commerce live demo](live-demo/e-commerce-live-demo.gif)

---

## What's Included

| Part | What it does |
| --- | --- |
| `database/` | Schema, seed data, 22 analytics queries, views, stored functions, triggers, and pgTAP tests |
| `backend/` | Node.js and Express REST API with JWT authentication and admin roles |
| `frontend/` | Three browser pages: a storefront with cart and checkout, an admin console, and an analytics dashboard |
| `docker-compose.yml` | Runs PostgreSQL, the API, and the frontend together |
| `.github/workflows/ci.yml` | Runs the API tests against a PostgreSQL service on every push and pull request to `main` |

---

## Quick Start with Docker

You need Docker with Compose.

```bash
git clone https://github.com/bmarkjan-stack/p8-E-commerce-database.git
cd p8-E-commerce-database
docker compose up --build
```

| Service | Address |
| --- | --- |
| Storefront | http://localhost:8080/storefront.html |
| Admin console | http://localhost:8080/admin.html |
| Analytics dashboard | http://localhost:8080/dashboard.html |
| API | http://localhost:4000/api/health |
| PostgreSQL | `localhost:5433` (user `postgres`, password `postgres`, database `ecommerce_db`) |

The database scripts in `database/` run **only the first time** the database volume is created. To reset to a clean database, run `docker compose down -v` and then start again.

> The compose file uses development-only defaults, including the database password and the JWT secret. Change them before using this setup anywhere else.

---

## Setup Without Docker

You need PostgreSQL 16 (the version used in Docker and CI), Node.js 20, and a PostgreSQL client such as `psql` or pgAdmin.

**1. Create the database.**

```sql
CREATE DATABASE ecommerce_db;
```

**2. Load the scripts in order.** The numbered files depend on each other, so run all seven.

```bash
psql -U postgres -d ecommerce_db -f database/01_schema.sql
psql -U postgres -d ecommerce_db -f database/02_seed.sql
psql -U postgres -d ecommerce_db -f database/03_queries.sql
psql -U postgres -d ecommerce_db -f database/04_schema_extensions.sql
psql -U postgres -d ecommerce_db -f database/05_views.sql
psql -U postgres -d ecommerce_db -f database/06_functions_and_procedures.sql
psql -U postgres -d ecommerce_db -f database/07_triggers.sql
```

`03_queries.sql` contains the analytics queries as plain statements. It doesn't change the schema, so it can be run at any point after the first two files.

**3. Start the API.**

```bash
cd backend
cp .env.example .env     # then set DATABASE_URL, JWT_SECRET, and CORS_ORIGIN
npm install
npm run dev              # http://localhost:4000
```

**4. Open the frontend.** Open `frontend/storefront.html`, `admin.html`, or `dashboard.html` in a browser. They call `http://localhost:4000/api`.

---

## Database Design

### Entities

| Table | Purpose | Key columns |
| --- | --- | --- |
| `customers` | Accounts | `customer_id`, `email`, `password_hash`, `is_active`, `role` (`customer` or `admin`) |
| `addresses` | Shipping and billing addresses for a customer | `address_id`, `customer_id`, `is_default` |
| `categories` | Product categories | `category_id`, `category_name` |
| `products` | Items for sale | `product_id`, `category_id`, `sku`, `price`, `inventory_quantity`, `is_active` |
| `product_variants` | Options such as size or color, each with its own stock | `variant_id`, `product_id`, `inventory_quantity` |
| `orders` | Customer orders | `order_id`, `customer_id`, `shipping_address_id`, `status`, `shipping_cost` |
| `order_items` | Products in each order, with the price at the time of purchase | `order_item_id`, `order_id`, `product_id`, `variant_id`, `quantity`, `unit_price` |
| `payments` | Payments for an order | `payment_id`, `order_id`, `payment_method`, `payment_status`, `amount`, `transaction_reference` |
| `reviews` | Customer ratings and comments, one per customer per product | `review_id`, `customer_id`, `product_id`, `rating` (1 to 5) |
| `carts` and `cart_items` | Shopping carts | `cart_id`, `customer_id`, `variant_id`, `quantity` |
| `discounts` | Discount codes | `discount_id`, `code`, `discount_type`, `expires_at` |
| `shipping_tracking` | Tracking updates for an order | `tracking_id`, `order_id`, `carrier`, `tracking_number` |

### Relationships

```text
customers 1 ───< addresses
customers 1 ───< orders 1 ───< order_items >─── 1 products 1 ───< product_variants
customers 1 ───< reviews >─── 1 products
orders    1 ───< payments
orders    1 ───< shipping_tracking
customers 1 ───< carts 1 ───< cart_items >─── 1 product_variants
categories 1 ───< products
```

- **One-to-many:** a customer has many orders, and a category has many products.
- **Many-to-many:** orders and products are linked through `order_items`, which also stores the price charged at the time of purchase.

### Normalization

Category names are stored once in `categories`, and each product refers to them by `category_id`. Prices in `order_items` are copied at purchase time, so later price changes don't alter past orders.

### Constraints

The schema uses `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, and `CHECK` constraints. Examples:

```sql
CHECK (price >= 0)
CHECK (inventory_quantity >= 0)
CHECK (rating BETWEEN 1 AND 5)
UNIQUE (customer_id, product_id)   -- one review per customer per product
```

### Indexes

Indexes support the most common filters, joins, and sorts:

```text
idx_products_category_id          idx_orders_customer_id
idx_products_inventory_quantity   idx_orders_order_date
idx_orders_status                 idx_order_items_order_id
idx_order_items_product_id
```

`22 Database Performance` in the analytics list shows the index information.

---

## Analytics Queries

`database/03_queries.sql` contains 22 queries grouped by the questions they answer. Each one has a screenshot in `docs/screenshots/Queries/`.

| Group | Queries |
| --- | --- |
| Customer or Product | All customers; products with their categories |
| Order Reporting | Customer orders; order details; order totals; orders per customer |
| Sales Analytics | Total sales by month; average order value; best-selling products; most popular categories; products selling above the product average; monthly order count |
| Inventory Analytics | Low-inventory products; low-inventory report |
| Customer Spending | Highest-spending customers; spending above the average |
| Product Analytics | Products never purchased (with `LEFT JOIN` and with `NOT EXISTS`) |
| Review Analytics | Average rating per product; top-rated products |
| Payment Analytics | Payment method usage |
| Database Performance | Index information |

A few examples of the SQL used:

```sql
-- Total sales by month, leaving out cancelled orders
SELECT
    DATE_TRUNC('month', o.order_date)::DATE AS sales_month,
    ROUND(SUM(oi.quantity * oi.unit_price), 2) AS total_sales
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.status <> 'cancelled'
GROUP BY DATE_TRUNC('month', o.order_date)
ORDER BY sales_month;
```

```sql
-- Products that have never been purchased
SELECT p.product_name
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
WHERE oi.product_id IS NULL;
```

---

## Views

`database/05_views.sql` wraps the main reports as views, so the API and other tools can query them directly.

| View | Report |
| --- | --- |
| `monthly_sales_view` | Sales by month |
| `top_products_view` | Best-selling products |
| `top_customers_view` | Highest-spending customers |
| `unpurchased_products_view` | Products with no sales |
| `low_inventory_view` | Products running low |
| `category_revenue_view` | Revenue per category |
| `product_rating_view` | Average rating per product |
| `payment_method_summary_view` | Usage per payment method |
| `dashboard_kpi_view` | Headline numbers for the dashboard |

---

## Stored Functions

`database/06_functions_and_procedures.sql` defines three functions that hold the main business rules.

**`place_order(customer_id, shipping_address_id, items, payment_method, shipping_cost)`**
Creates an order, its items, and its payment in one call. `items` is a JSON array of products and quantities. The function rejects empty orders, unknown customers, and unavailable products. Stock is checked by the trigger described below.

**`apply_discount_code(order_id, code)`**
Applies a discount code to an order. It raises an error if the code is invalid or expired.

**`get_customer_lifetime_value(customer_id)`**
Returns the total a customer has spent.

---

## Triggers

`database/07_triggers.sql` keeps inventory correct without any application code.

- **`trg_decrement_inventory`** runs before each new order item. It locks the product or variant row, then reduces its stock. If there isn't enough stock, it raises an error such as `Insufficient stock for variant 3: requested 2, available 1`. This prevents overselling even when two orders arrive at the same time.
- **`trg_restore_inventory_on_cancel`** puts stock back when an order's status changes to `cancelled`.
- **`trg_touch_cart`** updates a cart's timestamp when its items change.

---

## REST API

The API is in `backend/src/`. Routes that need a login expect a JWT in the `Authorization: Bearer <token>` header. Admin routes also check that the user's role is `admin`.

| Method | Path | Access | Description |
| --- | --- | --- | --- |
| GET | `/api/health` | Public | Health check |
| POST | `/api/auth/register` | Public | Create a customer account |
| POST | `/api/auth/login` | Public | Log in and receive a JWT |
| GET | `/api/products` | Public | List products, filtered by `category` and `search` |
| GET | `/api/products/:id` | Public | One product, with its variants |
| POST | `/api/products` | Admin | Create a product |
| PATCH | `/api/products/:id` | Admin | Update a product |
| GET | `/api/cart` | Customer | View your cart |
| POST | `/api/cart/items` | Customer | Add an item to your cart |
| DELETE | `/api/cart/items/:cartItemId` | Customer | Remove an item from your cart |
| POST | `/api/orders` | Customer | Place an order. The request body gives `items`, `shipping_address_id`, and `payment_method`, and the route calls `place_order` |
| GET | `/api/orders` | Customer | List your orders (admins see all orders) |
| GET | `/api/orders/:id` | Owner or admin | One order with its details |
| PATCH | `/api/orders/:id/status` | Admin | Change an order's status |
| GET | `/api/sales/monthly` | Public | Monthly sales |
| GET | `/api/sales/top-products` | Public | Best-selling products |
| GET | `/api/sales/top-customers` | Public | Highest-spending customers |
| GET | `/api/sales/low-inventory` | Public | Low-stock products |
| GET | `/api/sales/category-revenue` | Public | Revenue per category |
| GET | `/api/sales/payment-methods` | Public | Payment method usage |
| GET | `/api/sales/product-ratings` | Public | Average ratings |
| GET | `/api/sales/kpis` | Public | Dashboard headline numbers |

The `/api/sales` routes read from the analytics views, so the dashboard charts and the SQL reports show the same numbers.

---

## Frontend Pages

The pages are plain HTML and JavaScript, with no build step. They call the API with `fetch`.

- **`storefront.html`** is the shop. Customers browse products, filter by category, add items to a cart, and check out. Chart.js is bundled locally in `frontend/vendor/`.
- **`admin.html`** lets an admin log in, view orders, change order status, and see low-stock products.
- **`dashboard.html`** shows four charts: sales by month, top products, category revenue, and payment methods.
- **`index.html`** links to the storefront.

---

## Testing and CI

**API tests** use Jest and Supertest. They cover the health check, product listing, authentication and protected routes, and the overselling protection in `place_order`.

```bash
cd backend
npm install
DATABASE_URL=postgresql://postgres:postgres@localhost:5432/ecommerce_test \
JWT_SECRET=test-secret npm test
```

**Database tests** are written with pgTAP in `database/tests/pgtap_tests.sql`. The file has seven tests, which check the schema, such as that the expected tables exist. Run them with a pgTAP-compatible test runner. These tests are not run by the CI workflow.

**Continuous integration.** On every push and pull request to `main`, GitHub Actions starts a PostgreSQL 16 service, loads the schema, seed data, extensions, views, functions, and triggers in order, and runs the API tests.

---

## Deployment

`docs/DEPLOYMENT.md` covers three options:

1. **Local with Docker:** `docker compose up`, as described above.
2. **Local without Docker:** the steps in [Setup Without Docker](#setup-without-docker).
3. **Hosted demo:** a database on Neon or Supabase, the API on Render or Railway, and the frontend as a static site on Vercel, Netlify, or Render.

The guide also covers optional PostgreSQL-level roles, which go beyond the `role` column used by the API.

---

## Project Structure

```text
p8-E-commerce-database/
├── backend/
│   ├── src/
│   │   ├── db.js                 # PostgreSQL connection pool
│   │   ├── server.js             # Express app and route mounting
│   │   ├── middleware/auth.js    # JWT checks and admin role check
│   │   └── routes/               # auth, products, cart, orders, sales
│   ├── tests/api.test.js
│   ├── .env.example
│   ├── Dockerfile
│   └── package.json
├── database/
│   ├── 01_schema.sql             # core tables, constraints, and indexes
│   ├── 02_seed.sql               # sample customers, products, orders, payments, reviews
│   ├── 03_queries.sql            # 22 analytics queries
│   ├── 04_schema_extensions.sql  # variants, carts, discounts, shipping tracking, roles
│   ├── 05_views.sql              # reporting views
│   ├── 06_functions_and_procedures.sql
│   ├── 07_triggers.sql           # inventory and cart triggers
│   └── tests/pgtap_tests.sql
├── docs/
│   ├── database-design.md
│   ├── DEPLOYMENT.md
│   ├── IMPROVEMENTS_GUIDE.md
│   └── screenshots/              # results of each analytics query, plus schema and seed screenshots
├── frontend/
│   ├── storefront.html
│   ├── admin.html
│   ├── dashboard.html
│   ├── index.html
│   └── vendor/chart.umd.min.js
├── live-demo/                    # demo recording used in this README
├── .github/workflows/ci.yml
├── docker-compose.yml
└── README.md
```

---

## Technologies

- **Database:** PostgreSQL 16, with PL/pgSQL functions and triggers
- **API:** Node.js, Express, `pg`, JSON Web Tokens, bcrypt, Jest, and Supertest
- **Frontend:** HTML, CSS, JavaScript, and Chart.js
- **Tooling:** Docker Compose, nginx (for the frontend container), GitHub Actions, and pgTAP

---

## Future Improvements

- Product images
- Wishlists
- Full-text product search
- Multiple payments per order (`payments.order_id` is currently unique, so each order has one payment)
- A dedicated refund table (refund status is currently stored on `payments`)

---

## License

This project is licensed under the [MIT License](LICENSE). You are free to use, copy, modify, merge, publish, distribute, and sell the code, provided the copyright and license notice are included in copies or substantial portions of it.

---

## Author

Created by [bmarkjan-stack](https://github.com/bmarkjan-stack) as a portfolio project.

- GitHub: https://github.com/bmarkjan-stack
- Repository: https://github.com/bmarkjan-stack/p8-E-commerce-database