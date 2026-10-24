---
name: build-app
description: App shape and the serializer-first API pattern (view -> serializer -> service). Use when creating an app or adding models, serializers, views, urls.
---
# Building an app (Django REST)

## Shape

```
backend/<app>/
  apps.py          # ready() imports signals
  models.py        # fields + constraints + visible_to() queryset
  serializers.py   # validation (in) and shaping (out)
  services/        # business logic - plain functions, no request object
  views/           # thin: auth -> permission -> serializer -> service -> serializer
  urls.py
  signals.py       # side effects of a save (signals skill)
  tasks.py         # Celery jobs (background-jobs skill)
  defaults.py      # seed lists
  tests/
```

New app checklist: `startapp` -> `INSTALLED_APPS` -> wire `config/urls.py` -> row in the CLAUDE.md app registry -> `tests/` package. Not done until all five.

## The three layers

| Layer | Does | Never does |
|---|---|---|
| View | auth, permission, pick serializer, call service, return Response | business rules, raw `request.data` reads |
| Serializer | field + cross-field validation, output shape | side effects beyond `create/update` |
| Service | the business decision, transactions, enqueue tasks | know about HTTP |

```python
class OrderCreateView(APIView):
    def post(self, request):
        s = OrderWriteSerializer(data=request.data, context={"request": request})
        s.is_valid(raise_exception=True)
        order = services.create_order(s.validated_data, by=request.user, tenant=request.tenant)
        return Response(OrderDetailSerializer(order).data, status=201)
```

Avoid the old pattern: `request.data.get("x")` for each field, hand-validated in the view.

## API rules

- URLs laid out by **frontend screen**: `page/summary/`, `page/table/`, `create/`, `detail/<id>/`, `form-options/`, `options/<list>/`, `export/`.
- **Table rows are flat**: strings/numbers/bools/null only. Related record -> its name; code -> its label.
- **Popups answer only their screen**, flat: `id`, `reference`, `editable`, own fields in the shape the PATCH takes (`assignee` + `assignee_name`).
- **Buttons** answer `{id, reference, status, message, next, next_by}`.
- Lists, filters, cache and serializer shape: see `api-shared-layer`.
- Status changes go through one `TRANSITIONS` table + `apply_transition()`; check the start status on the locked row (`select_for_update`) and answer 409 if wrong.
- Errors: 400 validation, 403 write denied, 404 read denied / other tenant, 409 wrong state.
- The active tenant is resolved once by middleware (`request.tenant`) - views never look it up themselves.
