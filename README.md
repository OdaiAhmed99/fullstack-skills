# fullstack-skills

A reusable template and Claude Code skill set for any project with this structure: a **Django REST** API,
a **Vite/React** frontend, **nginx** in front, **Postgres + Redis**, **Celery** and **Channels**, all run locally by
`docker compose`. The skills teach Claude one way of working: how to build an app, the shared API layer, dropdowns,
background jobs, database checks, security, and the handoff to the frontend.

## Run it

```powershell
.\run.ps1            # stops the old stack, frees the port, builds, starts, waits until healthy
.\run.ps1 -Logs      # same, then follow the logs
.\run.ps1 -Stop      # stop everything
.\run.ps1 -Status    # what is running
.\run.ps1 -Reset     # stop and DELETE the database, then start fresh
```

First run only: `docker compose run --rm backend python manage.py makemigrations users`, then commit the migration.

Open http://localhost (app), http://localhost/api/docs/ (Swagger), http://localhost/admin/.
Create an admin: `docker compose exec backend python manage.py createsuperuser`.

On macOS/Linux, run it by hand: `cp .env.example .env && docker compose up --build`.

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
