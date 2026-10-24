# Shared - flow

Calls every app uses. Field detail is in the API doc.

1. **Every request** goes through `src/api/shared/client.js`; it adds the token and refreshes once on a 401.
2. **Dropdowns**: a form's first load is its app's `form-options/`; searching calls the picker path with `?search=`; an edit form shows a saved value with `?ids=`.
3. **Errors**: every call's failure goes to `handleApiError` (400 mark fields, 403 not your turn, 409 reload).
4. **Live results**: one websocket `/ws/notifications/` for the whole app.
