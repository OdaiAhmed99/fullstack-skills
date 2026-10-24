---
name: frontend-integration
description: How the React frontend integrates with the backend - the one API client, login/JWT, pickers and form-options, table pages, popups, button answers, errors, websocket and exports. Use when building or changing any frontend screen that calls the API, or when wiring a screen from a frontend-handoff doc.
---
# Frontend integration

Build every screen from its handoff (`docs/frontend-api/<app>/flow.md` + `integrate.md`) and the API doc. The backend owns the rules; the frontend shows what the answer says.

## 1. One client
- Every call goes through `src/api/shared/client.js`. No `fetch`/`axios` elsewhere, no hard-coded host - `VITE_API_BASE_URL` is `/api` behind nginx. Folder rules: `frontend-structure` skill.
- One folder per backend app for its calls: `src/api/<app>/index.js` exporting small functions (`getOrderTable(params)`, `assignOrder(id, body)`). Screens import those, never build URLs themselves.

## 2. Login (JWT)
- `POST /api/auth/login/` with `{login, password}` - `login` is the username **or** the email, one input box.
- Save `access` + `refresh`; the client adds `Authorization: Bearer` and refreshes once on 401, then retries. Refresh fails -> clear tokens, go to login.
- On app load call `GET /api/auth/me/` to know who is logged in.
- 400 on login = one message under the form; don't say which field was wrong.

## 3. Dropdowns (shared-lookups on the frontend)
- A form's first render: **one** `GET <app>/form-options/` - it carries the first page of every picker the form uses.
- Searching / scrolling a dropdown: `fetchPicker("<list path>", {search, page})`. Same envelope everywhere: `{total_items, total_pages, current_page, next_page, previous_page, data}` - use the **one** `components/shared/Picker.jsx` and reuse it in every app.
- Edit form with a saved value: `fetchPicker(path, {ids: [savedId]})` to show its name.
- Fixed codes (status, priority) come from the API doc enum, kept in one `src/constants/<app>.js`.
- Send back the item's `id` (or `code`). Filters send the same value: `?location=12&status=open`.

## 4. Table pages
- `page/summary/` for the cards, `page/table/` for the rows (same filter params, paginated).
- Rows are flat: render values as they come; don't look anything up per row.
- The arrow on a row opens `detail/<id>/`.

## 5. Popups and buttons
- Open: `GET` the popup. Render its fields; disable everything when `editable` is false.
- Save Draft: `PATCH` - the answer is the popup again; keep it open.
- Submit / action button: `POST` - answers `{id, reference, status, message, next, next_by}`. Close the popup, toast `message`, refresh the page. **Don't open the next popup** unless the handoff doc says the same person continues.
- Which buttons to show: read `actions` / `can_*` from the answer. Never decide by role name or status text.

## 6. Errors - one handler
| Status | Do |
|---|---|
| 400 | keep the popup open; show each field's message under the field, `non_field_errors` on top |
| 401 | the client refreshes; if that fails, go to login |
| 403 | "Not allowed" toast; refresh (it is not your turn) |
| 404 | "Not found" - back to the list |
| 409 | "Someone already changed this" - close and reload |
| 5xx | generic error toast; don't retry automatically |
It is `handleApiError` in `src/api/shared/errors.js`.

## 7. Background work and live updates
- Export / long job: `POST .../export/` answers **202**; show "preparing...". The result arrives on the websocket `/ws/notifications/` (`{type, url, ...}`) - open the link.
- One websocket connection for the whole app (a context/provider), reconnect with backoff.

## 8. Done when
- [ ] Calls only through `src/api/<app>/` + `src/api/shared/`.
- [ ] Every dropdown uses the shared `<Picker>` and `form-options/`.
- [ ] Buttons and editability come from the answer, not from role checks.
- [ ] Errors go through `handleApiError`.
- [ ] Matches the handoff doc; any mismatch is reported to the backend, not worked around.
