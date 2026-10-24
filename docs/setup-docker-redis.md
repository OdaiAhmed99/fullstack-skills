# Docker and Redis - optional setup

You do **not** need these to run the app: `.\run.ps1` uses SQLite and runs background tasks inline.
Install them when you want the real thing: Redis for the cache, websockets across processes and a real
Celery worker, or the full Docker stack (Postgres + Redis + nginx).

## Option 1 - Redis only, app still local

1. **Install Docker Desktop**
   - Download: https://www.docker.com/products/docker-desktop/
   - Run the installer, keep "Use WSL 2" ticked, restart Windows if it asks.
   - Open Docker Desktop once and wait until it says "Engine running".
   - Check in PowerShell: `docker --version`

2. **Start Redis**
   ```powershell
   docker run -d --name redis -p 6379:6379 --restart unless-stopped redis:7-alpine
   docker exec redis redis-cli ping      # answers PONG
   ```

3. **Point the app at it** - in `.env`:
   ```
   REDIS_URL=redis://localhost:6379/0
   ```

4. **Restart the app**: `.\run.ps1`

5. **Run a Celery worker** (only now are tasks really in the background), in a second terminal:
   ```powershell
   cd backend
   ..\.venv\Scripts\celery -A config worker -l info -P solo
   ```
   `-P solo` is needed on Windows. Scheduled jobs too? A third terminal:
   `..\.venv\Scripts\celery -A config beat -l info --scheduler django_celery_beat.schedulers:DatabaseScheduler`

Stop Redis: `docker stop redis` · start it again: `docker start redis` · remove it: `docker rm -f redis`.
Back to no Redis: empty `REDIS_URL=` in `.env` and run `.\run.ps1`.

## Option 2 - the full Docker stack

Postgres, Redis, backend, Celery worker + beat, frontend and nginx, all in containers.

1. Install Docker Desktop (step 1 above).
2. Stop the local run so ports are free: `.\run.ps1 -Stop` (and `docker rm -f redis` if you started Option 1).
3. Start everything:
   ```powershell
   .\run-docker.ps1
   ```
4. Open http://localhost. Stop: `.\run-docker.ps1 -Stop`.

The Docker stack has its own Postgres database - data from the local SQLite file is not copied over.

## When something goes wrong

| You see | Do |
|---|---|
| `docker: command not found` | Docker Desktop is not installed or not open - open it and wait for "Engine running" |
| `port is already allocated` (6379) | another Redis is running: `docker ps`, then `docker rm -f <name>` |
| `Error 10061 connecting to localhost:6379` | Redis is not running: `docker start redis` |
| Tasks never finish with Redis on | no worker is running - start step 5 |
| WSL 2 error on install | run `wsl --install` in an admin PowerShell, restart, install Docker again |
