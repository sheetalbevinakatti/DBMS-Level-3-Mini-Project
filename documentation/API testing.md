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

## Authentication

Create a web session and retain its cookie for subsequent requests:

```powershell
$baseUrl = "http://127.0.0.1:3000"
$session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
$loginBody = @{ email = "admin@example.com"; password = "AdminDemo123!" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/login" `
  -ContentType "application/json" -Body $loginBody -WebSession $session
```

Use the seeded admin credentials from the README, or substitute another local
seed account. A successful login returns the user object and sets the
`patentpath_session` cookie. Check the current signed-in user:

```powershell
Invoke-RestMethod -Method Get -Uri "$baseUrl/api/auth/me" -WebSession $session
```

Sign out and clear the session cookie:

```powershell
Invoke-RestMethod -Method Post -Uri "$baseUrl/api/auth/logout" -WebSession $session
```

Expected behavior:

| Request | Expected result |
|---|---|
| `POST /api/auth/login` with valid credentials | `200`, user object, session cookie |
| `POST /api/auth/login` with invalid credentials | `401`, `{"error":"Email or password is incorrect."}` |
| `GET /api/auth/me` without a valid session | `401` |
| `GET /api/auth/me` with a valid session | `200`, current user object |
| `POST /api/auth/logout` | `200`, `{"ok":true}`, cookie cleared |

## Inventions

With the session from the authentication example, list the invention catalog:

```powershell
Invoke-RestMethod -Method Get -Uri "$baseUrl/api/inventions" -WebSession $session
```

This requires any signed-in user and returns an `inventions` array. Create an
invention using an administrator session:

```powershell
$inventionBody = @{
  title = "Low-power water quality sensor"
  abstract = "A sensor that monitors water quality using low-power components."
  description = "Example record created while testing the API."
  category = "Environmental monitoring"
} | ConvertTo-Json
$created = Invoke-RestMethod -Method Post -Uri "$baseUrl/api/inventions" `
  -ContentType "application/json" -Body $inventionBody -WebSession $session
$created
```

The create request returns HTTP `201` and an `invention_id`. Save that ID for
the update and delete examples. The `title` must be 3–200 characters and
`category` 2–100 characters. `abstract` and `description` are optional and have
maximum lengths of 5,000 and 10,000 characters, respectively.

Update the record (PATCH requires all four fields in the request body):

```powershell
$inventionId = $created.invention_id
$updatedBody = @{
  title = "Low-power water quality sensor v2"
  abstract = "Updated example abstract."
  description = "Updated example record."
  category = "Environmental monitoring"
} | ConvertTo-Json
Invoke-RestMethod -Method Patch -Uri "$baseUrl/api/inventions/$inventionId" `
  -ContentType "application/json" -Body $updatedBody -WebSession $session
```

Delete the example record when finished:

```powershell
Invoke-RestMethod -Method Delete -Uri "$baseUrl/api/inventions/$inventionId" `
  -WebSession $session
```

`POST`, `PATCH`, and `DELETE` require an admin session; a regular signed-in
user receives HTTP `403`, and a request without a session receives HTTP `401`.
Invalid fields or IDs return HTTP `400`; a missing record returns HTTP `404`.
Deleting an invention referenced by patent records returns HTTP `409`. Create
and update also index the invention in Qdrant, so they can return HTTP `503` if
vector indexing fails even though the database change was saved.

## Semantic search

With any signed-in user session, submit a query containing 3–1,000 characters:

```powershell
$searchBody = @{ query = "low power water quality monitoring" } | ConvertTo-Json
Invoke-RestMethod -Method Post -Uri "$baseUrl/api/search" `
  -ContentType "application/json" -Body $searchBody -WebSession $session
```

The response contains a `searchId` and up to 10 matching invention records in
`results`, ordered by similarity. Each result includes a `similarity` score.
Searches and their analyses are recorded in the database. A missing session
returns HTTP `401`; an invalid or too-short query returns HTTP `400`. Ensure
both MySQL and Qdrant are ready before testing semantic search.
