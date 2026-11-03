# PatentPath — invention and patent discovery

PatentPath helps researchers compare a technology idea with an invention and patent collection. It combines relational records and constraints in MySQL with semantic similarity search in Qdrant. The app turns a free-text description into a local sentence embedding, retrieves nearby invention records, and stores each search and its patent matches for later analysis.

This project goes beyond CRUD through semantic search, patent/application tracking, role-restricted editing, full-text SQL search, application-status history, relational reports, and recorded search analysis.

## Technology choices

- **MySQL 8.4:** users, inventions, inventors, applications, patents, and auditable search records have structured relationships and integrity constraints.
- **Qdrant:** stores 384-dimensional invention vectors for nearest-neighbor retrieval.
- **Embedding model:** `Xenova/all-MiniLM-L6-v2`, run locally with Transformers.js; mean pooling and L2 normalization.
- **Similarity:** cosine distance in Qdrant. Search text is not sent to an external embedding API.
- **Next.js:** web UI and API routes, with server-side database access.

See [the ER diagram](diagrams/er-diagram.png) and [the relational schema diagram](diagrams/Relational_schema.png).

## Prerequisites

- Node.js 20.9 or newer and npm.
- Docker Desktop with Docker Compose, or separately managed MySQL 8.0+ and Qdrant services.
- An internet connection for the first npm install and first local embedding-model download.

## Run locally (Windows PowerShell)

From the repository root:

```powershell
Copy-Item .env.example frontend/.env.local
```

Edit `frontend/.env.local`. Set separate strong local values for `MYSQL_ROOT_PASSWORD` and `MYSQL_PASSWORD`; set `MYSQL_SETUP_PASSWORD` to the same value as `MYSQL_ROOT_PASSWORD`. `SESSION_SECRET` must be at least 32 bytes. Keep this file private; it is ignored by Git.

Start the local database services:

```powershell
docker compose --env-file frontend/.env.local up -d
```

Install dependencies and apply the schema, routines, triggers, and sample data:

```powershell
Set-Location frontend
npm install
npm run db:setup
npm run db:index-vectors
npm run dev
```

Open <http://127.0.0.1:3000>. The scripts create a separate `patentpath_assignment` database, leaving any existing `patentpath` database untouched. `db:setup` uses `MYSQL_SETUP_USER` and `MYSQL_SETUP_PASSWORD` (the local root account) to create the assignment database and objects; the application itself connects using the less-privileged `MYSQL_USER` and `MYSQL_PASSWORD`.

The first vector indexing command downloads the embedding model and may take a little time. Re-run `npm run db:index-vectors` after importing or changing invention data outside the app. Inventions created through the admin UI are indexed automatically.

## Demo sign-in

Seeded local-only accounts:

| Role | Email | Password |
|---|---|---|
| Researcher | `aarav@example.com` | `PatentPathDemo123!` |
| Researcher | `meera@example.com` | `PatentPathDemo123!` |
| Admin | `admin@example.com` | `AdminDemo123!` |

These are demonstration credentials only. Change or remove the accounts and rotate all secrets before exposing any deployment to a network.

## SQL demonstrations

The runnable SQL sources are in [`database/`](database/):

- `schema.sql`: database and ten related tables; keys, constraints, full-text and ordinary indexes; a title-column widening with `ALTER`, `CREATE VIEW`, and a safely scoped create/alter/drop demonstration table.
- `seed.sql`: repeatable sample records with scrypt password hashes.
- `queries.sql`: SELECT, JOIN, GROUP BY, HAVING, ORDER BY, aggregates, full-text search, nested and correlated subqueries, transactional INSERT/UPDATE/DELETE demonstrations, and a stored-function call. Demo changes are rolled back.
- `procedures.sql`: validated application-status update procedure, category summary, and patent-count function.
- `triggers.sql`: application-status audit history on insert and status changes.

Run all SQL through the project runner after configuring MySQL:

```powershell
npm run db:setup
```

For the example queries, use a MySQL client connected to `patentpath_assignment` and execute `database/queries.sql`. Its test DML sections are wrapped in transactions and end with `ROLLBACK`.

## Verification

```powershell
npx tsc --noEmit
npm run build
npm audit
```

Check database and vector service readiness at <http://127.0.0.1:3000/api/health>. `mysql` and `qdrant` must both report `connected` before semantic search can run.

## Repository

GitHub: <https://github.com/sheetalbevinakatti/DBMS-Level-3-Mini-Project>
