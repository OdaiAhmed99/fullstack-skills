"""One pagination envelope for every list in every app - tables and pickers alike.

{total_items, total_pages, current_page, next_page, previous_page, data}
"""
from rest_framework.pagination import PageNumberPagination
from rest_framework.response import Response


class StandardPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = "page_size"
    max_page_size = 100

    def get_paginated_response(self, data):
        page = self.page
        return Response(
            {
                "total_items": page.paginator.count,
                "total_pages": page.paginator.num_pages,
                "current_page": page.number,
                "next_page": page.next_page_number() if page.has_next() else None,
                "previous_page": page.previous_page_number() if page.has_previous() else None,
                "data": data,
            }
        )


def paginate(request, queryset, serialize):
    """For APIViews: paginate a queryset and answer the standard envelope.

    `serialize` turns the page's rows into a list (a serializer's `.data`, or a shape function).
    """
    paginator = StandardPagination()
    rows = paginator.paginate_queryset(queryset, request)
    return paginator.get_paginated_response(serialize(rows))
