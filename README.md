# PatentPath

PatentPath is an invention and patent discovery application. Researchers can
compare a technology idea with stored inventions using semantic search, while
administrators manage the invention catalog.

## Features

- Semantic invention search with locally generated embeddings.
- Invention, patent, and application records backed by relational data.
- Role-based authentication and invention management.
- Search history and application-status auditing.

## Technology

Next.js · MySQL 8.4 · Qdrant · Transformers.js (`Xenova/all-MiniLM-L6-v2`)

See the [ER diagram](diagrams/er-diagram.png) and
[relational schema](diagrams/Relational_schema.png).

## Run locally

Requirements: Node.js 20.9+, npm, and Docker Compose (or separately managed
MySQL and Qdrant services).

From the repository root, configure the local environment:

```powershell
Copy-Item .env.example frontend/.env.local
```

Set the database passwords and a `SESSION_SECRET` of at least 32 bytes in
`frontend/.env.local`. Then start the services and app:

```powershell
docker compose --env-file frontend/.env.local up -d
Set-Location frontend
npm install
npm run db:setup
npm run db:index-vectors
npm run dev
```

Open <http://127.0.0.1:3000>. The initial vector-indexing step downloads the
embedding model. Re-run it after importing or changing invention records
outside the application.

