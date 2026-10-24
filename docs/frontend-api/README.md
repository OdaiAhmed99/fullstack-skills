# Frontend API handoff

One folder per backend app - the same name as `backend/<app>/` and `frontend/src/api/<app>/`.
Each holds `flow.md` (the call order), `integrate.md` (step-by-step build notes) and `notes.md`
(gotchas, decisions, not built yet). Written by the backend with the `frontend-handoff` skill;
built from with `frontend-integration` and `frontend-structure`. Field detail lives in the API doc.

## Layout

```
docs/frontend-api/
  README.md
  shared/   flow.md, integrate.md   login, pickers, errors - used by every app
  users/    flow.md, integrate.md, notes.md
  core/     flow.md, integrate.md, notes.md
```
