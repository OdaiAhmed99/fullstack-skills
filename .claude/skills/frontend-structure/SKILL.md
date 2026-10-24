---
name: frontend-structure
description: How the frontend code is organized - api/ folder per backend app plus api/shared/, pages/ per app, shared components that are clean and responsive at every size, design tokens, and asking the user to generate any image. Use when adding a page, an API call, a component or an image to frontend/.
---
# Frontend structure

```
frontend/src/
  api/
    shared/              used by every app - the only place these live
      client.js          the one axios client (token, refresh on 401)
      auth.js            login (username or email), getMe, logout
      lookups.js         fetchPicker, fetchFormOptions (shared dropdown envelope)
      errors.js          handleApiError
      index.js           re-exports - import from "api/shared"
    <app>/               one folder per backend app (mirrors backend/<app>/)
      index.js           the app's calls: getOrderTable(params), assignOrder(id, body)
      <page>.js          split by page once index.js grows
  pages/
    <app>/               one folder per backend app
      <Page>Page.jsx     a screen; calls only api/<app>/ + api/shared/
      components/        pieces used by this app's pages only
  components/
    shared/              used by 2+ apps: Picker, DataTable, Modal, Button, Toast, EmptyState
  styles/tokens.css      colors, spacing, radius, font - the only source of style values
  assets/images/         only images the user generated or supplied
```

## API folders
- A call belongs to the backend app that serves it: `/api/orders/...` -> `api/orders/`. Pages never write a URL.
- Something two apps use (auth, pickers, errors, upload) goes to `api/shared/` - never copied into an app folder.
- One function per endpoint, named by what it does, returning `r.data`.
- When an app folder grows, split by page: `api/orders/table.js`, `api/orders/assign.js`, re-exported from `index.js`.

## Shared components - clean and responsive
A component moves to `components/shared/` the moment a second app needs it. Every shared component:
- [ ] Takes data through props only; no API calls inside except the data-bound ones (`Picker` uses `fetchPicker`).
- [ ] Styles only from `styles/tokens.css` variables - no literal colors, no fixed pixel widths.
- [ ] **Works at every size**: phone (< 640px), tablet (640-1024px), desktop (> 1024px). Mobile-first CSS: base styles for phones, `@media (min-width: ...)` to grow.
- [ ] Full width by default, `min-width: 0` in flex/grid, text wraps; tables scroll inside their own `overflow-x: auto` box; the page never scrolls sideways.
- [ ] Touch targets at least 44px high; visible `:focus-visible`; every input has a `<label>`.
- [ ] Light and dark through the tokens.
- [ ] One job, one file + its CSS; no dead props, no copy of another component.
- [ ] Checked at 375px, 768px and 1280px before calling it done.

## Images - ask the user
Claude never invents, draws, hot-links or uses placeholder-service images. When a screen needs one (logo, empty state, illustration, background), stop and **ask the user to generate it**, giving:
- what it shows and the mood,
- where it is used (page / component),
- size and ratio (e.g. 1200x630, 1:1 at 512x512), format (SVG for logos/icons, WebP/PNG for pictures), light/dark variants if needed.

Until it arrives, leave a clearly marked empty slot (`EmptyState` without an image) and add a row to `assets/images/README.md` with status `requested`. When the file arrives, save it in `assets/images/`, set the row to `added`, and use it with `alt` text and `max-width: 100%`.
