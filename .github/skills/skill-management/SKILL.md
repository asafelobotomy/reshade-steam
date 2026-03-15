---
name: skill-management
description: Discover, activate, and manage agent skills following the Skill Protocol
compatibility: ">=1.4"
---

# Skill Management

> Skill metadata: version "1.0"; license MIT; tags [skills, workflow, discovery, management]; compatibility ">=1.4"; recommended tools [codebase, editFiles, fetch].

Skills are reusable markdown-based **behavioural instructions** that teach the agent *how* to perform a specific workflow. Unlike tools (§11) which are executable scripts, skills are declarative — they shape the agent's approach rather than running code.

Skills follow the [Agent Skills](https://agentskills.io) open standard. Each skill is a `SKILL.md` file with minimal YAML frontmatter (`name`, `description`) plus a markdown body that includes a `Skill metadata` note and step-by-step workflow instructions.

## When to use

- You encounter a task that might match an existing skill
- The user asks to list, search for, or manage skills
- You need to decide where a new skill should be stored

## Discovery and activation

Skills are loaded **on demand** — the agent reads a skill's `SKILL.md` only when the `description` field matches the current task context. Do not pre-load all skills.

```text
Task requires a workflow
 │
 ├─ 1. SCAN — check .github/skills/*/SKILL.md descriptions
 │     ├─ Match found  → READ the full SKILL.md, follow its instructions
 │     └─ No match     → ↓
 │
 ├─ 2. SEARCH (if enabled by skill search preference setting)
 │     ├─ Search official repos (anthropics/skills, github/awesome-copilot) THEN:
 │     │     community sources (GitHub search, awesome-agent-skills)
 │     │     ├─ Found → evaluate fit, quality-check, adapt, save locally
 │     │     └─ Not found → ↓
 │
 └─ 3. CREATE — author a new skill from scratch
       - Save to .github/skills/<kebab-name>/SKILL.md
```

## Scope hierarchy

| Priority | Location | Scope |
|----------|----------|-------|
| 1 (highest) | `.github/skills/<name>/SKILL.md` | Project — checked into version control |
| 2 | `~/.copilot/skills/<name>/SKILL.md` | Personal — shared across all projects for one user |
| 3 | Agent plugins (`@agentPlugins`) | Plugin — installed via Extensions view (VS Code 1.110+) |
| 4 | Organization-level agents | Org — published at GitHub org level for all members |

> **Agent file discovery**: Use the `chat.agentFilesLocations` VS Code setting to add custom directories for skill/agent discovery beyond the default locations.

## Subagent skill use

Subagents inherit this protocol fully. A subagent may read and follow any project or personal skill. To **create** a new skill, the subagent must flag the proposal to the parent agent, which confirms before any write to `.github/skills/`.
