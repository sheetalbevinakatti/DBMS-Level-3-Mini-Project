# API testing

These examples use the locally running app at `http://127.0.0.1:3000`. Start the
database and Qdrant services and the Next.js app as described in the README
before testing. The health endpoint does not require a session; all other
endpoints below do.

Run the examples in one PowerShell session so the `$session` cookie jar is
shared. `Invoke-RestMethod` throws for non-2xx responses; use the status codes
and response bodies below to check expected error cases.

## Health

Check MySQL and Qdrant readiness:

```powershell
Invoke-RestMethod -Method Get -Uri "http://127.0.0.1:3000/api/health"
```

When both services are ready, the response is HTTP `200`:

```json
{
  "mysql": "connected",
  "qdrant": "connected"
}
```

If Qdrant is missing or unavailable, the endpoint responds with HTTP `503` and
reports `"qdrant": "not configured"` or `"qdrant": "unavailable"`. A database
health-check failure also returns HTTP `503`.

