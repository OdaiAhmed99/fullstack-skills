---
name: api-shared-layer
description: The shared structure every app's API uses - pagination (core/pagination.py), filters (core/filters.py), cache (core/cache.py) and clean input/output serializers with no extra fields. Use when building any list/table, filter, cached read, or any serializer.
---
# Shared API layer

Every app answers lists, filters and cached reads the **same way**, through `backend/core/`. Never write an app's own paginator, filter parser or cache helper.

| Need | Use | File |
|---|---|---|
| A paginated list | `StandardPagination` (DRF default) or `paginate(request, qs, serialize)` | `core/pagination.py` |
| Table filters | a `FilterSerializer` subclass + `filter_queryset(...)` | `core/filters.py` |
| Search / ordering | `?search=` over listed fields, `?ordering=` only from an allow-list | `core/filters.py` |
| Dropdown | `picker()` - same envelope + ETag | `core/lookups.py` |
| Hot, rarely-changing read | `cached(namespace, parts, build)` + `bump(namespace)` on write | `core/cache.py` |
| 304 for unchanged bodies | `etag_response(request, data)` | `core/cache.py` |

## Pagination - one envelope
`{total_items, total_pages, current_page, next_page, previous_page, data}` for tables and pickers. `?page=`, `?page_size=` (default 20, max 100). Never return a bare array for a list that can grow.

## Filters - validated like input
```python
class OrderFilter(FilterSerializer):
    location = serializers.IntegerField(required=False)
    status = serializers.ChoiceField(choices=Order.Status.choices, required=False)
    created_from = serializers.DateField(required=False)
    lookups = {"location": "location_id", "status": "status", "created_from": "created_at__date__gte"}

class OrderTableView(APIView):
    def get(self, request):
        qs = Order.objects.visible_to(request.user, request.tenant).select_related("location")
        qs = filter_queryset(request, qs, OrderFilter, search=("reference", "title"),
                             ordering=("created_at", "reference"), default_ordering="-created_at")
        return paginate(request, qs, lambda rows: OrderRowSerializer(rows, many=True).data)
```
- Param name = the form field; value = what the form sends (id or code). Empty = no filter.
- A bad value is a 400, never a silent empty table.
- Filters run **after** `visible_to()` - a filter can only narrow what the user may see.
- `page/summary/` takes the same filter class, so cards and table always agree.

## Cache - only when it pays
- Cache: `form-options/`, pickers, summary cards, meta. Don't cache: record detail, popups, anything per-user unless the user/tenant is in `parts`.
- Key = namespace + version + parts (`cached("orders:summary", [tenant.id, filters], build)`).
- Every write that changes the result calls `bump("orders:summary")` - in the service, after commit. No TTL-only correctness.
- Pickers and form-options also answer an ETag (`etag_response`), so an unchanged list costs a 304.
- Measure first: add a cache when a read is hot or slow, not by default.

## Clean input
- One **write serializer** per form: only the fields the form sends. Never `fields = "__all__"`.
- `read_only_fields` for anything the server decides (`status`, `reference`, `created_by`, timestamps) - a client can't set them even by sending them.
- Related ids use a queryset already scoped to the tenant (`PrimaryKeyRelatedField(queryset=...)` built in `__init__` from `request.tenant`) - the same rows the picker shows.
- Unknown input fields are ignored; required ones are explicit.

## Clean output - nothing the screen doesn't use
- A serializer **per screen shape**: `RowSerializer` (table), `DetailSerializer` (detail page), `PopupSerializer` (popup GET/PATCH), plus the button answer `{id, reference, status, message, next, next_by}`.
- List every field explicitly. Before adding one, ask: does the screen show it or send it back? If not, it doesn't go in.
- Rows are flat: related record -> its name (`location = CharField(source="location.name")`), code -> its label. No nested objects, no `_code` next to a label.
- No internal fields: no password hashes, internal flags, other tenants' ids, raw foreign keys the screen doesn't use, `created_by` emails unless shown.
- Dates as ISO strings; empty as `null`, not `""`.
- Every queryset behind a serializer has the `select_related`/`prefetch_related` its fields need (check with `assertNumQueries`).

## Checklist
- [ ] List answers the standard envelope.
- [ ] Filters through a `FilterSerializer`, after `visible_to()`.
- [ ] No `__all__`; server-decided fields read-only.
- [ ] Each response field is used by the screen.
- [ ] Cached reads have a `bump()` on every write that changes them.
