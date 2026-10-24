"""Shared cache layer (Redis). Use it only where a read is hot and its data changes rarely:
form-options, pickers, summary cards, meta. Never cache per-record detail or anything permission-shaped
without the user/tenant in the key.

Invalidation is by version: every key carries its namespace's version; a write bumps the version,
so all old keys die at once - no key scanning.
"""
import hashlib
import json

from django.core.cache import cache
from rest_framework.response import Response

DEFAULT_TTL = 300  # seconds


def _version(namespace):
    return cache.get_or_set(f"v:{namespace}", 1, None)


def bump(namespace):
    """Call after a write that changes what `namespace` returns (e.g. from a service or signal)."""
    try:
        cache.incr(f"v:{namespace}")
    except ValueError:
        cache.set(f"v:{namespace}", 2, None)


def make_key(namespace, *parts):
    raw = json.dumps(parts, sort_keys=True, default=str)
    return f"{namespace}:{_version(namespace)}:{hashlib.md5(raw.encode()).hexdigest()}"


def cached(namespace, parts, build, ttl=DEFAULT_TTL):
    """Return the cached value, or build() it and store it."""
    key = make_key(namespace, *parts)
    value = cache.get(key)
    if value is None:
        value = build()
        cache.set(key, value, ttl)
    return value


def etag_response(request, data):
    """Answer 304 when the client already has this exact body."""
    tag = '"' + hashlib.md5(json.dumps(data, sort_keys=True, default=str).encode()).hexdigest() + '"'
    if request.headers.get("If-None-Match") == tag:
        return Response(status=304, headers={"ETag": tag})
    return Response(data, headers={"ETag": tag})
