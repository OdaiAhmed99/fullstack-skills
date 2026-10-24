# fullstack-skills

A reusable template and Claude Code skill set for any project with this structure: a **Django REST** API,
a **Vite/React** frontend, **nginx** in front, **Postgres + Redis**, **Celery** and **Channels**. It runs locally with no Docker
(SQLite, no Redis); Docker is optional. The skills teach Claude one way of working: how to build an app, the shared API layer, dropdowns,
background jobs, database checks, security, and the handoff to the frontend.

## Run it (no Docker)

Needs Python 3.11+ and Node.js 20+. Uses SQLite and no Redis.

```powershell
.\run.ps1            # stops the old run, frees ports, installs what is missing, migrates, starts backend + frontend
.\run.ps1 -Stop      # stop both
.\run.ps1 -Status    # what is running
```

Open http://localhost:5173 (app), http://localhost:8000/api/docs/ (Swagger), http://localhost:8000/admin/.
Create an admin: `.venv\Scripts\python backend\manage.py createsuperuser`.

## Optional: Redis or the full Docker stack

Step-by-step in [docs/setup-docker-redis.md](docs/setup-docker-redis.md): install Docker Desktop, start Redis
(`REDIS_URL=redis://localhost:6379/0`), run a Celery worker - or run everything (Postgres, Redis, nginx) with
`.\run-docker.ps1` (`-Stop`, `-Logs`, `-Status`, `-Reset`).

## Install in Claude Code

Pick the way that fits:

**A. Start a new project from this template (recommended)**
1. Copy the whole folder (or "Use this template" on GitHub) and rename it.
2. Open a terminal in it and run `claude`.
3. Claude reads `CLAUDE.md`, sees `business.md` is unanswered, and asks you about your business before building.

**B. Add the skills to an existing project**
1. Copy `.claude/skills/` into your project's `.claude/skills/`.
2. Copy the parts of `CLAUDE.md` you want (the "How to use the skills" section and the skills table) into your project's `CLAUDE.md`.
3. Copy `business.md` to the project root.
4. Restart `claude` in that project. The skills fit as-is only if the project has the same layout (`backend/core/`, `frontend/src/api/shared/`); otherwise edit the paths in each `SKILL.md`.

**C. Use the skills in every project on your machine**
Copy each skill folder into your personal skills folder:
- Windows: `%USERPROFILE%\.claude\skills\`
- macOS/Linux: `~/.claude/skills/`

Check it worked: in Claude Code, type `/` and look for the skill names, or ask "which skills do you have?".

## Push to GitHub

Needs [Git](https://git-scm.com/) and the [GitHub CLI](https://cli.github.com/) (`gh auth login` once).

```powershell
git init
git add .
git status                      # check that .env is NOT in the list (it is in .gitignore)
git commit -m "Initial commit: fullstack-skills template"
gh repo create fullstack-skills --private --source . --push
```

Without the GitHub CLI: create an empty repo on github.com, then
`git remote add origin https://github.com/<you>/fullstack-skills.git`, `git branch -M main`, `git push -u origin main`.

To let others start projects from it: on GitHub, Settings -> General -> check **Template repository**.
Make the repo public only after checking that no secret is in the history.

## License

[MIT](LICENSE)
