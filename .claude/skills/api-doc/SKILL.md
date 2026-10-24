---
name: api-doc
description: Document each new or changed endpoint (OpenAPI + frontend call flow). Use before opening a PR that touches an API.
---
# API docs

For every endpoint: method + path, permission, request fields (type, required, which picker an id comes from), response example, every error code and when it happens.

- Generate OpenAPI with `drf-spectacular`: `python manage.py spectacular --file schema.yml`, then publish to your API tool (Apidog / Postman). The tool's token comes from an env var - ask the user to set it, never read it from a committed file.
- Frontend flow doc `docs/frontend-api/<app>/flow.md`: which screen calls what, in which order, and where one person's turn in a workflow ends.
