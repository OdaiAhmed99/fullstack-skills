---
name: cycle-flow
description: The ordered development cycle from "build this" to "PR open and recorded". Use when starting any feature, endpoint or app.
---
# Development cycle

```
build-app → db-integrity → shared-lookups check → clean-code-review
          → security-check → api-doc → frontend-handoff → open PR → PR session record
```

1. **build-app** + **api-shared-layer** - model, serializer, service, view, url (serializer-first); lists, filters and cache through `core/`; clean input/output.
2. **db-integrity** - no duplicate fields/tables, constraints in the DB, migrations reviewed.
3. **shared-lookups** - every dropdown comes from the one shared layer; nothing copied.
4. **clean-code-review** - `/code-review` on the diff; remove duplication.
5. **security-check** - secrets, permissions, tenant scope, input validation.
6. **api-doc** - every new/changed endpoint documented.
7. **frontend-handoff** - the screen's call sequence in `docs/frontend-api/` for the frontend to build from.
8. Open the PR, then write `docs/pr-sessions/pr-<n>.md` (what changed, how each step went).

Skip a stage only *explicitly* ("no api-doc: Celery-only change"), never silently.
Later stages depend on earlier ones being settled - you cannot usefully review or document code that is not built and tested.
