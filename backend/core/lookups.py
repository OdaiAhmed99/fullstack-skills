"""The one layer every dropdown answers through (shared-lookups skill).

Apps never build their own list endpoint: they pass a queryset and a shape to picker().
Paging, search and the envelope are the same as every table (core.pagination, core.filters).
"""
from .cache import etag_response
from .filters import apply_search
from .pagination import StandardPagination


# --- item shapes: `id` is always what the form sends back ---
def record(obj):
    return {"id": obj.pk, "name": str(obj)}


def choice(code, label):
    return {"code": code, "label": str(label)}


def choices(model_choices):
    return [choice(code, label) for code, label in model_choices]


def flat_choice(instance, field):
    """A table row shows only the label of a fixed code."""
    return getattr(instance, f"get_{field}_display")()


# --- the picker ---
def picker(request, rows, shape=record, search=("name",)):
    rows = apply_search(rows, request, search)
    if ids := request.query_params.get("ids"):
        rows = rows.filter(pk__in=[i for i in ids.split(",") if i.isdigit()])
    paginator = StandardPagination()
    page = paginator.paginate_queryset(rows, request)
    body = paginator.get_paginated_response([shape(obj) for obj in page]).data
    return etag_response(request, body)


def first_page(rows, shape=record, size=20):
    """What a form-options/ endpoint embeds for each picker it uses."""
    return [shape(obj) for obj in rows[:size]]
