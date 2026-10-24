---
name: mcp-connection
description: Expose the project's own services to AI assistants (Claude Code, Claude Desktop, other MCP clients) through an MCP server in mcp/ at the project root, optionally packaged as a Claude Code plugin, and tell the user how to connect. Use when the user asks to connect the app to AI, "give my services to Claude", build an MCP server or plugin, or asks how to connect to it. Always ask before building.
---
# MCP connection

An MCP server lets an AI assistant call the app's services as **tools** ("list open orders", "assign order 12"). It is **optional**: build nothing until the user says yes.

## 1. Ask first - never build without a yes
When the user mentions AI access, MCP or a plugin, ask (with AskUserQuestion when available):
1. **Do you want an MCP server for this project?** (yes / not now)
2. **Which services should the AI have?** List the apps from the CLAUDE.md registry and let them pick. Start read-only; writes only on request.
3. **Who connects?** Only you locally (stdio), or a team / remote clients (HTTP behind nginx).
4. **Package it as a Claude Code plugin too?** (optional - only useful to share with others)

Write the answers into `business.md` -> Decisions (dated). If the answer is "not now", stop.

## 2. Where it lives
```
mcp/                       at the project root, next to backend/ and frontend/
  server.py                the MCP server: registers tools, nothing else
  tools/
    <app>.py               one file per backend app - mirrors backend/<app>/
  client.py                the one HTTP client to the backend API (base URL + token)
  requirements.txt         mcp (official Python SDK), httpx
  Dockerfile               only if it runs as a compose service
  README.md                what each tool does + how to connect
```

## 3. Clean service rules
- **Tools call the backend's HTTP API**, never the database or Django models directly. Permissions, tenant scope, validation and the response shape stay in one place - the backend.
- **One tool = one existing endpoint**, named by what it does: `list_orders(status, location, page)`, `get_order(id)`, `assign_order(id, assignee)`. No tool that does what no endpoint does; add the endpoint first (`build-app`).
- **Auth**: the server uses a token from the environment (`APP_API_TOKEN`, a dedicated service user with only the permissions the tools need). Never a token in code or in `.mcp.json`.
- **Inputs typed and described** (each tool's docstring and parameter descriptions are what the AI reads). Validate before calling the API.
- **Outputs small**: return the API's flat answer, trimmed to what helps the AI; lists keep the pagination envelope so the AI can ask for the next page.
- **Errors as plain messages**: map 400/403/404/409 to one readable sentence ("Order 12 was already assigned - reload it"), never a stack trace.
- **Writes are explicit**: a write tool's description says what it changes. Destructive tools (delete, cancel) only if the user asked for them.
- Same app split as everywhere: `mcp/tools/<app>.py`, shared helpers in `client.py`.

```python
# mcp/server.py
from mcp.server.fastmcp import FastMCP
from tools import orders

mcp = FastMCP("app-services")
orders.register(mcp)

if __name__ == "__main__":
    mcp.run()          # stdio; use transport="streamable-http" for remote

# mcp/tools/orders.py
from client import api

def register(mcp):
    @mcp.tool()
    async def list_orders(status: str | None = None, page: int = 1) -> dict:
        """List orders the service user may see. status: open | closed."""
        return await api.get("/orders/page/table/", params={"status": status, "page": page})
```

## 4. Optional: a Claude Code plugin
Only when the user said yes to question 4. A plugin bundles the MCP server config (and, if wanted, this repo's skills) so others install it in one step:
```
plugin/
  .claude-plugin/plugin.json      name, version, description
  .mcp.json                        the server entry (command + env var names, no values)
  skills/                          optional: copies of .claude/skills/ to share
```
Tell the user how to install it: add the repo as a marketplace or install from the path with `/plugin`, then restart Claude Code.

## 5. When the user asks how to connect
Give the exact steps for their client:

**Claude Code (local, stdio)**
```bash
claude mcp add app-services --env APP_API_URL=http://localhost/api --env APP_API_TOKEN=<token> -- python mcp/server.py
claude mcp list            # check it is connected
```
Or a project-shared `.mcp.json` at the root (commit it; values come from each person's environment):
```json
{ "mcpServers": { "app-services": {
    "command": "python", "args": ["mcp/server.py"],
    "env": { "APP_API_URL": "${APP_API_URL}", "APP_API_TOKEN": "${APP_API_TOKEN}" } } } }
```

**Remote (HTTP behind nginx)**: run with `transport="streamable-http"`, add an nginx `location /mcp/`, protect it with the token, then `claude mcp add --transport http app-services https://<host>/mcp/`.

**Claude Desktop**: Settings -> Developer -> Edit config, add the same server entry, restart the app.

Then: how to get the token (create the service user and its token in the admin), and one test prompt ("list my open orders").

## 6. Done when
- [ ] The user said yes (and to the plugin, if one was built).
- [ ] Every tool maps to an existing endpoint and respects its permissions.
- [ ] No token in code or committed files; `.env.example` lists `APP_API_URL`, `APP_API_TOKEN`.
- [ ] `mcp/README.md` lists each tool and the connect steps.
- [ ] Connected once with `claude mcp list` showing it healthy.
- [ ] CLAUDE.md registry has an `mcp` row.
