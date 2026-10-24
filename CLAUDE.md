# fullstack-skills - project template

A reusable template and skill set for any backend project that shares this structure: a **Django REST** API, a **Vite/React** dashboard, **nginx** in front, **Postgres + Redis**, **Celery** for background work, **Channels** for websockets - all run locally by `docker compose`.

## Layout

```
fullstack-skills/
  CLAUDE.md               # this file - read every session
  business.md             # the domain: study case, roles, records, rules - asked at project start
  docker-compose.yml      # db, redis, backend, celery, beat, frontend, nginx
  run.ps1                 # local run, no Docker: SQLite, no Redis (-Stop, -Status)
  run-docker.ps1          # full Docker stack: Postgres, Redis, nginx (-Stop, -Logs, -Reset, -Status)
  docs/setup-docker-redis.md  # optional: install Docker, run Redis, Celery worker - clean steps
  README.md               # run, install the skills in Claude Code, push to GitHub
  LICENSE                 # MIT
  .env.example            # copy to .env (never commit .env)
  backend/                # Django project: config/ + one folder per app
  frontend/               # Vite + React: src/api/<app>/ + src/api/shared/, pages/<app>/, components/shared/
  docs/frontend-api/      # handoff per app: <app>/flow.md, integrate.md, notes.md (frontend-handoff)
  nginx/default.conf      # reverse proxy: / -> frontend, /api /admin /ws -> backend
  .claude/skills/         # how we work (below)
```

## Run locally

No Docker needed - SQLite database, no Redis (cache in memory, Celery tasks run inline):

```powershell
.\run.ps1            # stops the old run, frees ports 8000/5173, installs what is missing, migrates, starts both
# http://localhost:5173 (app)  - API http://localhost:8000/api/docs/ - admin http://localhost:8000/admin/
.venv\Scripts\python backend\manage.py createsuperuser
```

Needs Python 3.11+ and Node.js 20+. Want Redis or the full Docker stack (Postgres + Redis + nginx)? Follow `docs/setup-docker-redis.md`, then `.\run-docker.ps1`.
## Start here: the business

**Before building anything, read [business.md](business.md).** If it still has unanswered questions (`_answer:_` lines), stop and ask the user those questions - a few at a time, in plain words - then write the answers into `business.md`. Don't guess the domain. Every app, model name, role, permission and workflow is taken from that file; when the user later changes a decision, update it there first.

## Running the app (rule for Claude)

When the user asks to run, start, restart or "it is stuck": run `.\run.ps1` (local, no Docker) - or `.\run-docker.ps1` if they use Docker - never a bare `runserver` or `docker compose up`. Both always stop the old run first, free the ports, start in the background and wait for `/api/core/health/`. If the user asks for Redis, Docker or a real Celery worker, walk them through `docs/setup-docker-redis.md` one step at a time and check each step worked before the next. Then tell the user the URLs, or - if it failed - the error from the logs it printed and the one next step. `-Stop` stops everything; `run-docker.ps1 -Reset` also deletes the Docker database (ask first).

## Read first

- **Before any form, filter or dropdown: load `shared-lookups`.** Every list has exactly one endpoint, served through `backend/core/lookups.py`.
- **Shared API layer**: every list uses `core/pagination.py`, every filter `core/filters.py`, every cache `core/cache.py`; responses carry only what the screen uses (`api-shared-layer`).
- **Serializer-first**: views validate input and shape output through serializers; business logic lives in `services/` and runs on `validated_data` (`build-app`).
- **Table rows are flat**, popups answer only their screen, buttons answer `{id, reference, status, message, next, next_by}`.
- **Permissions**: authenticated -> tenant boundary (404) -> `has_perm(perm, tenant)` -> `visible_to()` scope. Default deny.

## App registry

Every app lives in `backend/<app>/`, is in `INSTALLED_APPS`, is wired in `config/urls.py` under `/api/`, has a `tests/` package, and has a row here.

| App | URL prefix | Purpose |
| --- | --- | --- |
| `core` | `/api/core/` | Shared plumbing every app uses: `pagination.py` (one envelope), `filters.py` (`FilterSerializer`, search, ordering), `cache.py` (versioned cache + ETag), `lookups.py` (pickers, choices), health check. |
| `users` | `/api/auth/` | Custom `User` (`AUTH_USER_MODEL`, unique email + username, case-insensitive). `POST login/` takes `{login, password}` - `login` is the username **or** the email - and answers `{access, refresh, user}`; `refresh/`, `me/`. JWT via simplejwt. |

## Development cycle (`cycle-flow`)

`build-app -> db-integrity -> shared-lookups -> clean-code-review -> security-check -> api-doc -> frontend-handoff -> PR -> PR session record`

## How to use the skills

Skills live in `.claude/skills/<name>/SKILL.md`. Each one is a short rulebook for one kind of work.

- **Claude loads them by itself** when a task matches a skill's description (a dropdown -> `shared-lookups`, a slow job -> `background-jobs`). You can also ask by name: "use `build-app` to add an orders app", or type `/<skill-name>`.
- **Load before acting**: read the skill first, then follow it. If a skill has a checklist, every item is done or explicitly skipped with a reason.
- **More than one applies?** Process first, then detail: `cycle-flow` sets the order, then `build-app` / `api-shared-layer` / `shared-lookups` for the code, then the review skills.
- **Your words win**: the user's instruction > `business.md` > this file > a skill's default.

Typical requests and the skills they pull in:

| You say | Skills, in order |
|---|---|
| "Build the orders app" | `cycle-flow` -> `build-app` -> `api-shared-layer` -> `shared-lookups` -> `db-integrity` -> `clean-code-review` -> `security-check` -> `api-doc` -> `frontend-handoff` |
| "Add a filter / a dropdown to the table" | `shared-lookups` -> `api-shared-layer` |
| "Export to Excel" / "send a reminder every day" | `background-jobs` (+ `signals` if a save triggers it) |
| "Add a field" | `db-integrity` (does it already exist somewhere?) |
| "Build the orders page in React" | `frontend-structure` -> `frontend-integration`, reading `docs/frontend-api/orders/` |
| "Is this ready for a PR?" | `clean-code-review` -> `security-check` -> `api-doc` -> `frontend-handoff` |
| "Run it / add a service" | `docker-stack` |
| "Connect my app to Claude / AI" / "how do I connect?" | `mcp-connection` (asks before building anything) |

Changing a skill: edit its `SKILL.md`, keep it short, and update its row below. A rule that only one project needs belongs in `business.md` or this file, not in a skill.

## Skills

| Skill | Use it when |
|---|---|
| `cycle-flow` | starting any feature - the order of everything |
| `build-app` | app shape, view / serializer / service layers, URL layout |
| `api-shared-layer` | any list, filter, cache or serializer - shared pagination/filters/cache, clean input and output |
| `shared-lookups` | any dropdown, picker, meta, form-options |
| `background-jobs` | slow or scheduled work (Celery) |
| `signals` | a save must trigger something |
| `db-integrity` | new field/model/migration - no duplicates, constraints, connection |
| `clean-code-review` | after tests are green |
| `security-check` | before every PR, `.env`, auth, uploads |
| `api-doc` | new/changed endpoint |
| `frontend-handoff` | backend: write the screen's call sequence for the frontend |
| `frontend-integration` | frontend: build a screen on the API (client, login, pickers, popups, errors) |
| `frontend-structure` | frontend: folders (api per app + shared), responsive shared components, ask the user for images |
| `docker-stack` | running the stack, adding a service |
| `mcp-connection` | optional: give AI assistants your services through an MCP server in `mcp/` (+ optional plugin) - asks you first, and tells you how to connect |

## Testing

`docker compose exec backend python manage.py test` - plain Django `TestCase` / DRF `APITestCase`, no pytest.
