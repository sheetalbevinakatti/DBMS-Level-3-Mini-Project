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

