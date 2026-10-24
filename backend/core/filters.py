"""Shared filtering: every table filters the same way.

- A filter param is named after the form field and takes the same id/code the form sends (?location=12&status=open).
- Empty = no filter. Unknown params are ignored.
- ?search= (alias q) searches the fields the view lists; ?ordering= only on the fields it allows.
"""
from django.db.models import Q
from rest_framework import serializers


def apply_search(queryset, request, fields):
    term = request.query_params.get("search") or request.query_params.get("q")
    if not term:
        return queryset
    query = Q()
    for field in fields:
        query |= Q(**{f"{field}__icontains": term})
    return queryset.filter(query)


def apply_ordering(queryset, request, allowed, default):
    """Only orderings the view lists - never a raw field name from the URL."""
    value = request.query_params.get("ordering", default)
    return queryset.order_by(value if value.lstrip("-") in allowed else default)


class FilterSerializer(serializers.Serializer):
    """Base for a table's filter params - validated like any input, then applied.

    Subclass it, declare optional fields named after the form fields, and map each to a lookup:

        class OrderFilter(FilterSerializer):
            location = serializers.IntegerField(required=False)
            status = serializers.ChoiceField(choices=Order.Status.choices, required=False)
            created_from = serializers.DateField(required=False)
            lookups = {"location": "location_id", "status": "status", "created_from": "created_at__date__gte"}
    """

    lookups: dict = {}

    def apply(self, queryset):
        params = {self.lookups[k]: v for k, v in self.validated_data.items() if v not in (None, "")}
        return queryset.filter(**params)


def filter_queryset(request, queryset, filter_class, search=(), ordering=(), default_ordering="-id"):
    """The one call a table view makes: validate filters, search, order."""
    f = filter_class(data=request.query_params)
    f.is_valid(raise_exception=True)  # bad filter value -> 400, not a silent empty table
    queryset = f.apply(queryset)
    queryset = apply_search(queryset, request, search)
    return apply_ordering(queryset, request, ordering, default_ordering)
