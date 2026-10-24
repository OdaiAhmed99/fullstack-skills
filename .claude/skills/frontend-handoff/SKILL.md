---
name: frontend-handoff
description: Write the handoff the frontend builds from - one folder per backend app in docs/frontend-api/<app>/ with flow.md (call order), integrate.md (step-by-step build notes) and notes.md (gotchas, not built yet). Use when a screen or workflow is built or changed on the backend, or when the frontend asks "which API do I call when".
---
# Frontend handoff (`docs/frontend-api/`)

What the frontend team reads to build. Organized like the code: **one folder per backend app**, the same name as `backend/<app>/` and `frontend/src/api/<app>/`. Field detail (bodies, field tables, status codes) lives in the API doc (`api-doc` skill); if they disagree, the API doc wins.

## Layout
```
docs/frontend-api/
  README.md                  the contract + Layout block listing every app and page
  shared/                    what every app uses: login, pickers, errors, websocket
    flow.md
    integrate.md
  <app>/
    flow.md                  the app's screens in the order the user meets them; links to pages
    integrate.md             step-by-step build notes for the whole app
    notes.md                 gotchas, decisions, not-built-yet
    <page>/                  only when a screen is big (a workflow, many popups)
      flow.md
      integrate.md
```

## flow.md - the call order
```markdown
# <App> - <page> flow
Field detail is in the API doc ("<folder>"). This is the call sequence.
```
1. **Landing** - which call renders the page (`page/summary/`, `page/table/`), which flags gate what (`can_create`, `editable`, `actions`).
2. **Each popup / action** - lookups first (`form-options/`, pickers), then the submit call, and what gates it.
Each endpoint with its method in backticks + one line: `` `POST /api/orders/assign/{id}/` `` - assign the order.
No JSON examples, field tables or status-code lists.

**Workflow between people**: a who-hands-to-whom diagram at the top; one section per person (`## Part 1 - the creator: assign it`); each part ends with a bold line - `**The creator's part ends here.** The assignee has it (Part 2).` / `**The whole flow ends here.**`. Say that the backend decides branches and which answer field reports it.

## integrate.md - how to build it, step by step
Numbered steps a frontend developer follows, each naming the file it touches:
1. `src/api/<app>/index.js` - add these functions: `getOrderTable(params)` -> `GET /api/orders/page/table/` ...
2. `src/pages/<app>/OrdersPage.jsx` - on mount call `getOrderSummary()` + `getOrderTable()`; filters send picker ids.
3. Popup `AssignPopup` - on open `GET`, Save Draft `PATCH` (stay open), Assign `POST` (close, toast `message`, refresh).
4. Shared pieces to reuse: `<Picker path="/customers/options/locations/">` (paths are relative to `/api`), `handleApiError`.
5. Done check: every button comes from `actions`; matches flow.md.

## notes.md
Gotchas (a field that differs on read and write, a button that needs an upload first), decisions with their date, and what is **not built yet** (say so plainly so nobody waits for it).

## Wording
- Write for a frontend developer who has never seen the backend; name things as the screen does.
- Tell them what to read off the answer (`editable`, `actions`, `can_*`) - never to decide by role or status text.
- Refusals as actions: 400 keep the popup and mark fields; 403 not your turn; 409 someone moved it - close and reload.

## After writing
- Update the Layout block in `docs/frontend-api/README.md`.
- Check every named endpoint is in the API doc.
- Commit the docs with the change they describe.
