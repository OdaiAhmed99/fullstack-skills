---
name: shared-lookups
description: The one layer for every dropdown, picker, meta and form-options endpoint, shared between apps. Read BEFORE building any form, filter or dropdown.
---
# Shared lookups (dropdown logic)

All lists go through `backend/core/lookups.py`. Never build a second copy of a list inside an app.

| Kind | Where | Example |
|---|---|---|
| **Fixed code list** (status, severity) | model `choices`; no API; frontend keeps the enum from the API doc | `risk_level` |
| **Growable list** (customers, locations, members) | a **picker** endpoint `options/<list>/` | `/api/customers/options/locations/` |
| **Org list** (editable per tenant) | model in the owning app, FK to Tenant, seeded from `defaults.py` | `OrderType` |
| **A form's first load** | one `form-options/` = `first_page()` of each picker it uses, cached | `/api/orders/form-options/` |

## Rules
0. **One place per list.** If it exists, call it. Shared lists used by several apps live in `core`.
1. A `meta/` holds only fixed codes and rules - never a list users can add to.
2. Pickers support `?search=`, `?ids=1,2`, `?page=`, `?page_size=` (max 100) and answer the envelope
   `{total_items, total_pages, current_page, next_page, previous_page, data}` with an ETag (304).
3. Item shapes come from `core/lookups.py`: `record {id, name}`, `choice {code, label}`, `member {id, name, role}`.
4. The write serializer's queryset is the same rows the picker shows (picker and validation agree).
5. Rows go through the model's `visible_to(user, tenant)`.
6. Filters send the form's value: `?location=12&status=open`.

## Checklist for a new dropdown
- [ ] No shared API already serves it.
- [ ] Fixed -> `choices`. Growable -> picker via `picker()`.
- [ ] Added to the form's `form-options/`.
- [ ] Tests: shape, search, ids, gate, other tenant never appears.
