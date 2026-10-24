# Users - integrate

1. `src/api/shared/auth.js` already has `login(loginValue, password)`, `getMe()`, `logout()` - auth is shared, so there is no `api/users/` folder until users get their own screens (profile, invite).
2. `src/pages/users/LoginPage.jsx` - a form with `login` and `password` inputs (labels, 44px height, full width on phones). On submit call `login()`; on success go to the home page; on 400 show the one message above the form.
3. App root - on mount call `getMe()`; on failure show the login page.
4. Logout button - `logout()` then go to the login page.
5. Done check: one input accepts username or email; no message says which part was wrong.
