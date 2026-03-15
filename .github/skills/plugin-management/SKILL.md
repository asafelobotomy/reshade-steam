---
name: plugin-management
description: Discover, evaluate, install, test, and manage agent plugins for VS Code Copilot
compatibility: ">=3.2"
---

# Plugin Management

> Skill metadata: version "1.0"; license MIT; tags [plugins, agents, extensions, discovery, management]; compatibility ">=3.2"; recommended tools [codebase, runCommands, editFiles].

Agent plugins (VS Code 1.110+, Preview) are installable packages that bundle agents, skills, hooks, MCP servers, and slash commands. This skill covers discovering, evaluating, installing, testing, and managing plugins alongside the template's own customization files.

## When to use

- The user asks to find, list, install, or manage agent plugins
- A task would benefit from a plugin-provided agent or skill
- You need to check for conflicts between plugin-contributed and workspace-level agents or skills
- The user wants to test the template as a local plugin

## Discovery

```text
User wants a plugin
 │
 ├─ 1. CHECK INSTALLED — list installed plugins
 │     Run in Extensions view: filter @agentPlugins
 │     Or check VS Code settings for chat.plugins.paths (local dev plugins)
 │     ├─ Found  → verify it meets the need → DONE
 │     └─ Not found → ↓
 │
 ├─ 2. SEARCH — find plugins in configured marketplaces
 │     Extensions view → search @agentPlugins <keyword>
 │     Or browse chat.plugins.marketplaces URLs
 │     ├─ Found → evaluate (see Quality Gate below) → install
 │     └─ Not found → ↓
 │
 └─ 3. RECOMMEND ALTERNATIVE — no suitable plugin exists
       Consider: workspace skill (.github/skills/), MCP server, or custom tool
```

## Quality gate

Before recommending or installing a plugin, verify:

- [ ] **Publisher trust** — known publisher or verified organization
- [ ] **Maintenance** — updated within 12 months; no abandoned or archived repo
- [ ] **No credential exposure** — plugin does not require secrets beyond standard VS Code secret storage
- [ ] **Conflict check** — no naming collisions with existing workspace agents, skills, or hooks
- [ ] **Scope review** — plugin only requests the minimum capability it needs (check the contributed agent and skill metadata for unnecessary tool access)

Plugins failing two or more checks are rejected.

## Conflict resolution

When a plugin contributes an agent or skill with the same name as a workspace file:

| Conflict type | Resolution |
|--------------|------------|
| Agent name collision | Workspace agent takes priority. VS Code shows source in tooltip. |
| Skill name collision | Project skills (`.github/skills/`) override plugin skills. |
| Hook collision | Workspace hooks fire alongside plugin hooks — check for duplicate behaviour. |

Use the **Agent Debug Panel** (`Developer: Open Agent Debug Panel`) to see exactly which agents, skills, and hooks are loaded and from which source.

## Settings reference

| Setting | Purpose |
|---------|---------|
| `chat.plugins.enabled` | Enable/disable plugin discovery (boolean) |
| `chat.plugins.marketplaces` | URLs of Git repositories serving as plugin marketplaces |
| `chat.plugins.paths` | Local paths for plugin development/testing |

## Testing the template as a plugin

To preview how the template's agents, skills, hooks, and prompts appear as plugin-contributed customizations:

1. Clone the template repo (or use an existing local copy)
2. Add to VS Code settings:

   ```json
   "chat.plugins.paths": {
       "/path/to/copilot-instructions-template": true
   }
   ```

3. Reload VS Code — plugin-contributed agents appear in the Copilot dropdown
4. Verify: open the Agent Debug Panel to confirm agents, skills, and hooks are loaded
5. Check for conflicts with any workspace-level agents in `.github/agents/`

## Managing installed plugins

1. **List** — Extensions view → filter `@agentPlugins` to see all installed plugins
2. **Inspect** — select a plugin to see its contributed agents, skills, and commands
3. **Disable** — right-click → Disable to temporarily suppress a plugin
4. **Remove** — right-click → Uninstall to fully remove

## Verify

- [ ] Requested plugin was found or a suitable alternative was identified
- [ ] Quality gate was applied before installation
- [ ] No unresolved naming conflicts between plugin and workspace agents/skills
- [ ] Agent Debug Panel confirms correct loading order and source attribution
