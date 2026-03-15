---
name: mcp-management
description: Configure and manage Model Context Protocol servers for external tool access
compatibility: ">=1.4"
---

# MCP Management

> Skill metadata: version "1.0"; license MIT; tags [mcp, servers, configuration, integration]; compatibility ">=1.4"; recommended tools [codebase, editFiles, fetch].

MCP enables Copilot to invoke external servers that provide tools, resources, and prompts beyond built-in capabilities. Configuration lives in `.vscode/mcp.json`.

## When to use

- The user asks to configure, add, list, or check MCP servers
- You need to determine which MCP servers are available
- A task would benefit from an external tool not yet configured

## Server tiers

| Tier | Default servers | When to enable | Configuration |
|------|----------------|-----------------|---------------|
| Always-on | filesystem, git | Every project — core development tools | Enabled by default in `.vscode/mcp.json` |
| Credentials-required | github, fetch | When external API access is needed | Requires `${input:github-token}` or `${env:GITHUB_PERSONAL_ACCESS_TOKEN}` (GitHub) |

## Available servers

| Server | Tier | Command | Purpose |
|--------|------|---------|--------|
| `@modelcontextprotocol/server-filesystem` | Always-on | `npx` | File operations beyond the workspace |
| `mcp-server-git` | Always-on | **`uvx`** (Python — not on npm) | Git history, diffs, and branch operations |
| `@modelcontextprotocol/server-github` | Credentials | `npx` | GitHub API — issues, PRs, repos, actions |
| `mcp-server-fetch` | Credentials | **`uvx`** (Python — not on npm) | HTTP fetch for web content and APIs |

> **Removed (v3.2.0):** `@modelcontextprotocol/server-memory` — replaced by VS Code's built-in memory tool (`/memories/`), which provides persistent storage with three scopes: user (cross-workspace), session (conversation), and repository.

## Adding a new server

Before adding any MCP server:

1. Check if a built-in tool or existing MCP server already covers the need
2. Verify the server package exists in the MCP registry (`github.com/modelcontextprotocol/servers`)
3. Check for `npx` vs `uvx` runtime requirement
4. Add to `.vscode/mcp.json` with appropriate tier classification
5. For credentials-required servers, use `${input:}` or `${env:}` variable syntax — never hardcode secrets

## Subagent MCP use

Subagents inherit access to all configured MCP servers. A subagent may invoke any server already in `.vscode/mcp.json`. To **add** a new server, the subagent must flag the proposal to the parent agent, which confirms before modifying `.vscode/mcp.json`.
