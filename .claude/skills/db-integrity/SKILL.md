---
name: db-integrity
description: Database checks - no duplicate fields or tables, constraints, indexes, migrations, connection setup. Use when adding/changing a model or migration.
---
# Database integrity

## No duplicates
- Before adding a field, search the models: does another model already hold this fact? Store it **once**; read it through a relation or a property.
- Before adding a model for a list (types, categories), check the shared-lookups table - one list, one table.
- No `<x>_code` next to `<x>`, no `name` copied from a related row - unless it is a deliberate frozen snapshot (comment why).
- A legacy duplicate field gets `# legacy - do not use in new code` and a removal plan.

Quick check: `grep -rn "<field_name> = models" backend/` before adding.

## Constraints in the database, not only in Python
- `UniqueConstraint` (incl. conditional), `CheckConstraint`; `on_delete` chosen on purpose (`PROTECT` for references, `CASCADE` only for owned children).
- Index every field used to filter or order a table page.
- `select_related` / `prefetch_related` on every list; prove it with `assertNumQueries`.

## Migrations
- One concern per migration. Data migrations have a reverse (or `RunPython.noop` with a comment).
- CI: `python manage.py makemigrations --check --dry-run`.

## Connection
- Local: SQLite when `POSTGRES_HOST` is empty - keep code database-neutral (no Postgres-only lookups without a fallback). Docker/prod: Postgres from env vars (`POSTGRES_*`), `CONN_MAX_AGE=60`, `CONN_HEALTH_CHECKS=True`.
- In Docker the host is the service name (`db`), never `localhost`. The backend waits for the db healthcheck.
