---
name: docker-stack
description: Local stack with docker compose - backend, celery, beat, frontend, nginx, postgres, redis - and the .env. Use when running the stack, adding a service, or changing ports/env.
---
# Docker stack

```
browser -> nginx:80 -+- /                -> frontend:5173 (Vite dev server)
                     +- /api/ /admin/     -> backend:8000 (Daphne, ASGI)
                     +- /ws/              -> backend:8000 (websocket upgrade)
                     +- /static/ /media/  -> shared volumes
backend, celery, beat -> db:5432 (Postgres), redis:6379 (broker, cache, channels)
```

- Windows: `.\run.ps1` (restart-safe: stops the old stack, frees the port, builds, waits for health). `-Stop`, `-Logs`, `-Status`, `-Reset` (deletes data - ask first).
- By hand: `cp .env.example .env`, then `docker compose up --build`.
- User says "run it" or "it is stuck": always `.\run.ps1`, never leave a half-running stack.
- Services reach each other by **service name** (`db`, `redis`, `backend`), never `localhost`.
- `depends_on` with `condition: service_healthy` for db and redis.
- Only nginx publishes a port to the host (db optionally, for local tools).
- A new service: add it to compose, its env vars to `.env.example`, its route to `nginx/default.conf`, and a line here.
