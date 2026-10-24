---
name: security-check
description: Security review - secrets/.env, auth, permissions, tenant isolation, input, uploads, headers. Use before every PR and on any auth, file or config change.
---
# Security check

## Secrets
- [ ] No secret in code or git. Everything comes from `.env` (gitignored); `.env.example` holds placeholders only.
- [ ] Prod: `DEBUG=False`, strong `SECRET_KEY`, explicit `ALLOWED_HOSTS`, `CSRF_TRUSTED_ORIGINS`, `CORS_ALLOWED_ORIGINS`.
- [ ] API tokens are read from the environment at run time - never pasted in chat or committed.
- [ ] `git log -p | grep -iE "secret|password|token"` before the first push of a new repo.

## Access
- [ ] Every view: authenticated -> **tenant boundary** (another tenant's record = 404) -> `has_perm(perm, tenant)` -> `visible_to()` scope.
- [ ] Default deny: no role/permission -> denied. Never fall back to "all rows".
- [ ] Per-record ownership checks ("only the creator edits") in the view/service, tested.

## Input & output
- [ ] All input through serializers; ORM only, no string-built SQL.
- [ ] Uploads: size + type allow-list, served by signed URL.
- [ ] Throttle login / password reset (DRF throttles).
- [ ] Errors never leak stack traces or other tenants' data.

## Transport
- [ ] JWT in httpOnly, Secure, SameSite cookies (or Authorization header); short access lifetime, rotating refresh.
- [ ] nginx: HTTPS in prod, HSTS, `X-Content-Type-Options`, `X-Frame-Options`, `client_max_body_size`.
- [ ] `pip-audit` and `npm audit` have no high findings.
