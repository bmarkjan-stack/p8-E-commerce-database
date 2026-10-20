# Guide: Applying All 10 Improvements

This walks through wiring up every new file in this drop into your existing
`p8-E-commerce-database` project, in the order that actually works (schema
first, then API, then UI).

## 0. Merge the new files into your project

Copy these new folders/files into your existing project root, alongside your
current `database/`, `README.md`, etc.:

```
database/04_schema_extensions.sql
database/05_views.sql
database/06_functions_and_procedures.sql
database/07_triggers.sql
database/tests/pgtap_tests.sql
backend/                     (entire folder)
frontend/                    (entire folder)
docker-compose.yml
.github/workflows/ci.yml
docs/DEPLOYMENT.md
docs/IMPROVEMENTS_GUIDE.md
```

## 1–? Database changes (items 4, 5, 6)

Run the new SQL files **in order**, after your existing `01_schema.sql` and
`02_seed.sql`:

```bash
psql ecommerce_db -f database/04_schema_extensions.sql   # item 4: variants, carts, discounts, tracking, roles
psql ecommerce_db -f database/05_views.sql                # item 5: views
psql ecommerce_db -f database/06_functions_and_procedures.sql  # item 5: place_order(), etc.
psql ecommerce_db -f database/07_triggers.sql              # item 6: inventory triggers
```

Order matters: `06` calls `place_order()`, which relies on the trigger in
`07` to actually decrement stock — but `07` only needs `04`'s tables to exist,
so `06` before `07` is fine (the function is *created* either way; it just
isn't *called* until after both files have run). If you're loading everything
fresh via Docker, `docker-compose.yml` already runs all seven files in the
right numeric order automatically.

Verify it worked in pgAdmin:
```sql
SELECT * FROM dashboard_kpi_view;
SELECT place_order(1, NULL, '[{"product_id":1,"quantity":1}]'::jsonb);
```

## Item 2 — the API layer

```bash
cd backend
cp .env.example .env      # point DATABASE_URL at your ecommerce_db
npm install
npm start                 # → http://localhost:4000/api/health
```

Quick smoke test:
```bash
curl http://localhost:4000/api/health
curl http://localhost:4000/api/products
```

## Item 7 — auth and roles

Auth is handled at the API layer (see `backend/src/routes/auth.js` and
`backend/src/middleware/auth.js`), not by creating real Postgres login roles
— that's the standard approach for a web app and works on every free-tier
Postgres host. `04_schema_extensions.sql` adds `customers.role`
(`customer`/`admin`) and promotes your first seeded customer to `admin`.

Register a normal customer:
```bash
curl -X POST http://localhost:4000/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"first_name":"Jane","last_name":"Doe","email":"jane@example.com","password":"secret123"}'
```

Log in as the seeded admin (use the email from your `02_seed.sql` for
`customer_id = 1`) to get an admin token for the dashboard/admin UI.

If you also want true database-level roles (e.g. a read-only reporting
user), see the optional section at the bottom of `docs/DEPLOYMENT.md`.

## Items 1 & 3 — the dashboard, storefront, and admin UI

With the API running, just open these files in a browser:

- `frontend/dashboard.html` — charts + tables over the views from item 5
  (works with sample data even before you log in; sign in as admin for
  live numbers)
- `frontend/storefront.html` — browse products, register/sign in, add to
  cart, checkout (calls `place_order()` under the hood)
- `frontend/admin.html` — view/update order status, see low-stock products

They auto-detect `http://localhost:4000/api` when opened locally. For a
hosted deployment, see `docs/DEPLOYMENT.md` section 3.

## Item 8 — Docker

One command runs the database (auto-seeded), API, and frontend together:

```bash
docker compose up --build
```

See `docs/DEPLOYMENT.md` section 1 for the full port/service breakdown.

## Item 9 — tests & CI

**API tests** (Jest + Supertest), run against a real Postgres database:
```bash
cd backend
npm test
```

**SQL-level tests** (pgTAP), which check constraints and trigger behavior
directly in Postgres:
```bash
CREATE EXTENSION IF NOT EXISTS pgtap;  -- run once, in your test DB
psql ecommerce_test -f database/tests/pgtap_tests.sql
```

**CI**: `.github/workflows/ci.yml` runs on every push/PR — it spins up a
disposable Postgres service container, loads all the SQL files, and runs
the Jest suite. Push this repo to GitHub and it runs automatically; check
the "Actions" tab.

## Item 10 — a live demo link

Once items 1–9 work locally, follow `docs/DEPLOYMENT.md` section 3 to put
a free-tier Postgres instance (Neon/Supabase) behind a hosted API
(Render/Railway) and a hosted static frontend (Vercel/Netlify). You end up
with one URL you can hand a client, instead of a zip file and a page of
setup instructions.

## Suggested order to actually do this in

1. Database changes (SQL files) — 20–30 min
2. API layer + smoke test with `curl` — 30–45 min
3. Open the dashboard/storefront/admin pages locally — 10 min
4. Docker Compose, to make step 1–3 reproducible for anyone — 20 min
5. Tests + CI, so future changes don't silently break the above — 30–45 min
6. Deploy, once you're happy with it locally — 30–60 min depending on the host
