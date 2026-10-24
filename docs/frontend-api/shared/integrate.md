# Shared - integrate

1. Import from `src/api/shared` only: `api`, `fetchPicker`, `fetchFormOptions`, `login`, `getMe`, `logout`, `handleApiError`.
2. Dropdown: `<Picker id="location" path="/customers/options/locations/" initialItems={formOptions.locations} value={...} onChange={...} />` from `components/shared/Picker.jsx`.
3. Never copy one of these into an app folder - extend it here.
