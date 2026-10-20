# Deployment Guide

## 1. Run everything locally with Docker (fastest path)

Requires Docker Desktop.

```bash
docker compose up --build
```

This starts three containers:

| Service    | URL                          | What it is                          |
|------------|-------------------------------|--------------------------------------|
| `db`       | localhost:5432                | Postgres, auto-loaded with schema + seed + extensions |
| `api`      | http://localhost:4000/api     | Express REST API                     |
| `frontend` | http://localhost:8080         | Static dashboard/storefront/admin pages, served by nginx |

Open http://localhost:8080/dashboard.html, http://localhost:8080/storefront.html,
and http://localhost:8080/admin.html.

The Postgres container only runs the init SQL files the **first** time its data
volume is created. To reset everything: `docker compose down -v && docker compose up --build`.

## 2. Run it without Docker

```bash
# 1. Create and load the database
createdb ecommerce_db
psql ecommerce_db -f database/01_schema.sql
psql ecommerce_db -f database/02_seed.sql
psql ecommerce_db -f database/04_schema_extensions.sql
psql ecommerce_db -f database/05_views.sql
psql ecommerce_db -f database/06_functions_and_procedures.sql
psql ecommerce_db -f database/07_triggers.sql

# 2. Start the API
cd backend
cp .env.example .env   # edit DATABASE_URL / JWT_SECRET if needed
npm install
npm start

# 3. Open the frontend
# Just open frontend/dashboard.html, storefront.html or admin.html
# directly in a browser (they call http://localhost:4000/api).
```

## 3. Host a live demo (free-tier friendly)

### Database: Neon or Supabase

1. Create a free Postgres project on [Neon](https://neon.tech) or
   [Supabase](https://supabase.com).
2. Copy the connection string they give you.
3. Run the six SQL files against it, in order, using `psql "<connection string>" -f database/01_schema.sql`
   (repeat for 02, 04, 05, 06, 07 — skip 03, it's example queries only).
4. Both providers require SSL: set `DATABASE_SSL=true` in the API's environment.

### API: Render or Railway

1. Push this repo to GitHub.
2. Create a new **Web Service** on [Render](https://render.com) (or a service
   on [Railway](https://railway.app)) pointing at the `backend/` directory.
3. Build command: `npm install`. Start command: `npm start`.
4. Set environment variables: `DATABASE_URL`, `DATABASE_SSL=true`, `JWT_SECRET`,
   `JWT_EXPIRES_IN`, `CORS_ORIGIN` (your frontend's URL).

### Frontend: Vercel, Netlify, or Render static site

1. Deploy the `frontend/` folder as a static site (no build step needed —
   it's plain HTML/CSS/JS).
2. In each HTML file, the `API` constant auto-detects `localhost` for local
   dev. For a real deployment, hardcode it once you have the API's URL:
   ```js
   const API = 'https://your-api.onrender.com/api';
   ```

Once both are deployed, hand the client the frontend URL — that's the live,
clickable version of this project instead of a zip file.

## 4. Optional: true Postgres-level roles (beyond the API's JWT roles)

The `customers.role` column (added in `04_schema_extensions.sql`) is what the
API/JWT layer uses for `customer` vs `admin` authorization — that's enough for
a web app. If you also want **database-level** role separation (e.g. a
read-only reporting user for BI tools, separate from the app's write user),
a superuser can run:

```sql
-- Read-only role for dashboards/BI tools
CREATE ROLE reporting_ro LOGIN PASSWORD 'change-me';
GRANT CONNECT ON DATABASE ecommerce_db TO reporting_ro;
GRANT USAGE ON SCHEMA public TO reporting_ro;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO reporting_ro;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO reporting_ro;

-- Application role: read/write on tables, but cannot DROP/ALTER them
CREATE ROLE app_user LOGIN PASSWORD 'change-me';
GRANT CONNECT ON DATABASE ecommerce_db TO app_user;
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO app_user;
```

Most hosted providers (Neon, Supabase, RDS) don't grant `CREATE ROLE` on
their free tiers, so this step is optional — the app-layer JWT roles are the
recommended approach for this project.
