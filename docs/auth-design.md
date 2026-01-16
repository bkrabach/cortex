# Cortex Multi-User Authentication & Authorization Design

**Status:** Design Phase
**Date:** 2026-01-15

---

## Current Security Gaps

**CRITICAL:** The server currently has:
- ❌ No authentication on any endpoints
- ❌ No user accounts or identity
- ❌ No data isolation (all notifications in one DB)
- ❌ Anyone on network can access web UI, inject notifications, read data

**This must be fixed before any production use.**

---

## Design Principles

1. **Simple but secure** - JWT for web, API keys for devices
2. **Per-user isolation** - Separate data directories, DB tables, sessions
3. **Minimal friction** - Easy device onboarding, remember me, SSO-ready
4. **Admin-friendly** - Simple user management, audit logs
5. **Future-proof** - OAuth2 ready, multi-tenant capable

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PUBLIC ENDPOINTS                      │
├─────────────────────────────────────────────────────────┤
│  POST /auth/register  (admin-only or disabled)          │
│  POST /auth/login     (returns JWT + refresh token)     │
│  POST /auth/refresh   (get new JWT)                     │
│  POST /auth/logout                                      │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼ JWT validation middleware
┌─────────────────────────────────────────────────────────┐
│                  AUTHENTICATED ENDPOINTS                 │
├─────────────────────────────────────────────────────────┤
│  WebSocket /chat/cortex         (JWT in query param)    │
│  WebSocket /ws/device/{id}      (API key in header)     │
│  POST /notifications/ingest     (API key required)      │
│  GET  /notifications/*          (user's data only)      │
│  GET  /health                   (public - no auth)      │
└─────────────────────────────────────────────────────────┘
                           │
                           ▼ Authorization layer
┌─────────────────────────────────────────────────────────┐
│                   PER-USER RESOURCES                     │
├─────────────────────────────────────────────────────────┤
│  ~/.amplifier-server/users/{user_id}/                   │
│    ├── config/attention-rules.md                        │
│    ├── notifications.db                                 │
│    └── sessions/{session_id}/events.jsonl               │
└─────────────────────────────────────────────────────────┘
```

---

## Authentication Mechanisms

### Web UI (Human Users)

**Flow:**
1. User visits `http://server:8420/` → Redirect to `/login`
2. Login form → `POST /auth/login` with username/password
3. Server validates, returns JWT (15 min expiry) + refresh token (30 days)
4. Client stores JWT in memory, refresh token in localStorage
5. All WebSocket/API calls include JWT in header or query param
6. On JWT expiry, auto-refresh using refresh token

**Tokens:**
```python
{
  "access_token": "eyJ...",  # JWT, 15 min expiry
  "refresh_token": "refresh_abc123...",  # 30 days
  "token_type": "Bearer",
  "expires_in": 900
}
```

**JWT Payload:**
```json
{
  "sub": "user_id_123",
  "username": "alice",
  "role": "user",
  "exp": 1234567890
}
```

### Device Clients (Daemons)

**Flow:**
1. Admin creates user account via web UI
2. Admin generates API key for user: `cortex_user123_abc...xyz`
3. API key stored in device client config: `~/.config/cortex/client.yaml`
4. Client includes API key in HTTP header: `X-API-Key: cortex_user123_...`
5. Server maps API key → user_id for data isolation

**API Key Format:**
```
cortex_{user_id}_{random_48_chars}

Example: cortex_alice_a1b2c3d4e5f6...
```

---

## User Model

```python
class User:
    id: str               # UUID
    username: str         # Unique, alphanumeric
    email: str | None     # Optional, for recovery
    password_hash: str    # bcrypt
    role: UserRole        # admin | user
    created_at: datetime
    last_login: datetime | None
    is_active: bool       # For soft-delete
    
class APIKey:
    id: str               # UUID
    user_id: str          # Foreign key to User
    key_hash: str         # SHA256 of full key
    prefix: str           # First 8 chars for display
    name: str             # "Windows Desktop", "Android Phone"
    created_at: datetime
    last_used: datetime | None
    expires_at: datetime | None
    is_active: bool
    
class RefreshToken:
    id: str               # UUID
    user_id: str
    token_hash: str       # SHA256
    created_at: datetime
    expires_at: datetime
    revoked: bool
```

---

## Data Isolation

### Per-User Directory Structure

```
~/.amplifier-server/
├── users/
│   ├── {user_id_1}/
│   │   ├── config/
│   │   │   └── attention-rules.md
│   │   ├── notifications.db
│   │   └── sessions/
│   │       └── {session_id}/
│   │           └── events.jsonl
│   ├── {user_id_2}/
│   │   ├── config/
│   │   ├── notifications.db
│   │   └── sessions/
│   └── ...
└── system/
    ├── users.db          # User accounts, API keys, tokens
    └── audit.log         # Admin actions
```

### Database Isolation

**Option A: Separate SQLite per user** (Recommended for simplicity)
- Each user has `users/{user_id}/notifications.db`
- No cross-user queries possible
- Easy backup/restore per user

**Option B: Single DB with user_id column**
- All notifications in one DB with `user_id` column
- Row-level security via WHERE clauses
- Easier for admin analytics

**Recommendation:** Option A for now, migrate to Option B if we need cross-user analytics.

---

## Security Implementation

### Password Security

```python
import bcrypt

# On registration/password change
password_hash = bcrypt.hashpw(password.encode(), bcrypt.gensalt(rounds=12))

# On login
if bcrypt.checkpw(password.encode(), stored_hash):
    # Valid
```

### JWT Generation

```python
import jwt
from datetime import datetime, timedelta

def create_access_token(user_id: str, username: str, role: str) -> str:
    payload = {
        "sub": user_id,
        "username": username,
        "role": role,
        "exp": datetime.utcnow() + timedelta(minutes=15),
        "iat": datetime.utcnow(),
    }
    return jwt.encode(payload, SECRET_KEY, algorithm="HS256")
```

### API Key Generation

```python
import secrets
import hashlib

def generate_api_key(user_id: str) -> tuple[str, str]:
    """Returns (full_key, key_hash)"""
    random_part = secrets.token_urlsafe(36)  # 48 chars
    full_key = f"cortex_{user_id}_{random_part}"
    key_hash = hashlib.sha256(full_key.encode()).hexdigest()
    return full_key, key_hash
```

---

## API Endpoints

### Authentication

```
POST /auth/register
  Body: {username, password, email?}
  Returns: {user_id, username}
  Auth: Admin JWT (or disabled for first user)

POST /auth/login
  Body: {username, password}
  Returns: {access_token, refresh_token, expires_in}
  
POST /auth/refresh
  Body: {refresh_token}
  Returns: {access_token, expires_in}
  
POST /auth/logout
  Body: {refresh_token}
  Returns: {success}
  Effect: Revokes refresh token
```

### User Management (Admin Only)

```
GET  /users              # List all users
POST /users              # Create user (alias for /auth/register)
GET  /users/{id}         # Get user details
PUT  /users/{id}         # Update user
DELETE /users/{id}       # Soft-delete user

GET  /users/{id}/api-keys        # List user's API keys
POST /users/{id}/api-keys        # Generate new API key
DELETE /users/{id}/api-keys/{id} # Revoke API key
```

### Protected Resources

All existing endpoints get middleware:
```python
@require_auth  # JWT or API key
async def get_notifications(user: User, ...):
    # Only access user's data
    notifications = db.get_notifications(user.id, ...)
```

---

## Middleware Implementation

### JWT Validation

```python
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials

security = HTTPBearer()

async def get_current_user(
    credentials: HTTPAuthorizationCredentials = Depends(security)
) -> User:
    """Extract and validate JWT, return User object."""
    token = credentials.credentials
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user = await get_user_by_id(payload["sub"])
        if not user or not user.is_active:
            raise HTTPException(status_code=401, detail="Invalid user")
        return user
    except jwt.ExpiredSignatureError:
        raise HTTPException(status_code=401, detail="Token expired")
    except jwt.InvalidTokenError:
        raise HTTPException(status_code=401, detail="Invalid token")
```

### API Key Validation

```python
async def get_user_from_api_key(
    api_key: str = Header(None, alias="X-API-Key")
) -> User:
    """Validate API key and return User."""
    if not api_key:
        raise HTTPException(status_code=401, detail="API key required")
    
    # Hash the key and look it up
    key_hash = hashlib.sha256(api_key.encode()).hexdigest()
    api_key_obj = await get_api_key_by_hash(key_hash)
    
    if not api_key_obj or not api_key_obj.is_active:
        raise HTTPException(status_code=401, detail="Invalid API key")
    
    if api_key_obj.expires_at and api_key_obj.expires_at < datetime.utcnow():
        raise HTTPException(status_code=401, detail="API key expired")
    
    # Update last_used
    await update_api_key_last_used(api_key_obj.id)
    
    user = await get_user_by_id(api_key_obj.user_id)
    if not user or not user.is_active:
        raise HTTPException(status_code=401, detail="User inactive")
    
    return user
```

### Combined Auth (JWT or API Key)

```python
async def require_auth(
    jwt_user: User | None = Depends(get_current_user),
    api_user: User | None = Depends(get_user_from_api_key),
) -> User:
    """Accept either JWT or API key."""
    user = jwt_user or api_user
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required")
    return user
```

---

## WebSocket Authentication

### Chat WebSocket (Web UI)

```python
@router.websocket("/chat/cortex")
async def chat_cortex_core(websocket: WebSocket, token: str = Query(...)):
    """JWT in query parameter for WebSocket."""
    try:
        # Validate JWT from query param
        payload = jwt.decode(token, SECRET_KEY, algorithms=["HS256"])
        user = await get_user_by_id(payload["sub"])
        if not user:
            await websocket.close(code=1008)  # Policy violation
            return
        
        await websocket.accept()
        # ... rest of chat logic with user context
```

### Device WebSocket (Clients)

```python
@router.websocket("/ws/device/{device_id}")
async def device_websocket(
    websocket: WebSocket,
    device_id: str,
    api_key: str = Header(..., alias="X-API-Key")
):
    """API key in header for device connections."""
    # Validate API key
    user = await get_user_from_api_key(api_key)
    
    await websocket.accept()
    # ... device logic with user context
```

---

## Bootstrap & First User

### Initial Setup Flow

1. **Server first start:** No users exist
2. **Bootstrap mode:** `/auth/register` is open (no auth required)
3. **First user:** Created as admin
4. **Lock down:** After first user, registration requires admin JWT

```python
async def is_bootstrap_mode() -> bool:
    """Check if this is first-time setup."""
    user_count = await db.count_users()
    return user_count == 0

@app.post("/auth/register")
async def register(
    data: RegisterRequest,
    admin: User | None = Depends(get_current_admin_or_none)
):
    """Register new user. Open during bootstrap, admin-only after."""
    if not await is_bootstrap_mode() and not admin:
        raise HTTPException(403, "Admin access required")
    
    # Create user...
```

---

## Migration Strategy

### Phase 1: Add Auth (Non-Breaking)

1. Add user table, auth endpoints
2. Create default "admin" user on startup if none exists
3. All endpoints work without auth (warn in logs)
4. Add `--require-auth` flag to enable enforcement

### Phase 2: Data Migration

1. Move existing data to `users/admin/`
2. Partition notification DB by user_id

### Phase 3: Enforce Auth

1. Remove `--require-auth` flag, always enforce
2. Return 401 on unauthenticated requests

---

## Configuration

```yaml
# ~/.amplifier-server/config/server.yaml
security:
  jwt_secret: "CHANGE_ME_GENERATE_RANDOM"  # 32+ char random string
  jwt_expiry_minutes: 15
  refresh_token_days: 30
  require_https: false  # true for production
  
  # Bootstrap
  allow_registration: false  # true only during bootstrap
  
  # Rate limiting
  max_login_attempts: 5
  lockout_duration_minutes: 15

admin:
  # First user (created automatically on bootstrap)
  username: "admin"
  # Password set via CLI: amplifier-server init-admin
```

---

## Device Client Changes

### Current (No Auth)

```python
client = AttentionFirewallClient(
    server="http://spark-1:8420",
    device_id="ALIENWARE-R13",
)
```

### With Auth

```python
client = AttentionFirewallClient(
    server="http://spark-1:8420",
    device_id="ALIENWARE-R13",
    api_key="cortex_alice_abc123..."  # From config file
)
```

**Config file:** `~/.config/cortex/client.yaml`
```yaml
server: http://spark-1:8420
device_id: ALIENWARE-R13
api_key: cortex_alice_abc123...  # Generated by admin
```

---

## Admin Interface

### Web UI Pages

```
/admin/users        # User list, create, disable
/admin/api-keys     # API key management
/admin/audit        # Audit log viewer
/admin/settings     # Server configuration
```

### CLI Commands

```bash
# Bootstrap first admin
amplifier-server init-admin --username admin --password <password>

# User management
amplifier-server users list
amplifier-server users create --username alice --password <password>
amplifier-server users disable --username alice

# API key management
amplifier-server api-keys generate --user alice --name "Windows Desktop"
amplifier-server api-keys list --user alice
amplifier-server api-keys revoke --key-id <id>
```

---

## Security Checklist

### Before Production

- [ ] Change JWT secret from default
- [ ] Enforce HTTPS (or document risk for local network)
- [ ] Rate limit login endpoint (5 attempts, 15 min lockout)
- [ ] Audit logging for auth events
- [ ] Password requirements (min 12 chars)
- [ ] API key rotation policy
- [ ] Session timeout configuration
- [ ] CORS properly configured
- [ ] SQL injection review (use parameterized queries)
- [ ] XSS prevention (escape output)

### Ongoing

- [ ] Monitor failed auth attempts
- [ ] Rotate JWT secret periodically
- [ ] Expire unused API keys
- [ ] Review audit logs weekly

---

## Implementation Plan

### Week 1: Core Auth

- [ ] User model and database schema
- [ ] Password hashing (bcrypt)
- [ ] JWT generation/validation
- [ ] Login/register endpoints
- [ ] Auth middleware

### Week 2: Data Isolation

- [ ] Per-user directory structure
- [ ] Migrate notification store to per-user DBs
- [ ] Update all data access to filter by user_id
- [ ] Session isolation (user's Cortex Core only)

### Week 3: Device Auth

- [ ] API key model and generation
- [ ] Device client auth header
- [ ] WebSocket authentication
- [ ] Device onboarding flow

### Week 4: Admin Tools

- [ ] Admin web UI (user management)
- [ ] CLI commands for user/key management
- [ ] Audit logging
- [ ] Bootstrap wizard

---

## Open Questions

1. **OAuth2/SSO:** Support Microsoft/Google login? (Future phase)
2. **MFA:** Add 2FA/TOTP? (Probably overkill for personal use)
3. **Family accounts:** Should family members have separate accounts or share one?
4. **Guest access:** Read-only access for demo purposes?
5. **Device trust:** Should devices be approved before first use?

---

## Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| Forgotten admin password | Lockout | CLI password reset command |
| Stolen API key | Unauthorized access | Revoke via web UI, audit logs |
| JWT secret leak | Session hijacking | Rotate secret, invalidate all tokens |
| XSS in web UI | Session theft | CSP headers, escape all output |
| SQL injection | Data breach | Use parameterized queries, ORM |
| Weak passwords | Brute force | Enforce min 12 chars, rate limit |

---

## Next Steps

1. Review this design with user
2. Implement auth models and database
3. Add login/register endpoints
4. Add middleware to existing endpoints
5. Update device client for API keys
6. Build admin UI
7. Test end-to-end auth flow
8. Migrate existing data to admin user
