# Bootstrap Record — reshade-steam

This workspace was scaffolded on **2026-03-15** using the [copilot-instructions-template](https://github.com/asafelobotomy/copilot-instructions-template).

## Initial stack

- Language: Bash
- Runtime: Bash 5.3
- Package manager: N/A (pure shell scripts)
- Test framework: Custom shell test runner

## What was created

- `.github/copilot-instructions.md` — instructions populated from template
- `.github/agents/setup.agent.md` — model-pinned Setup agent (Claude Sonnet 4.6)
- `.github/agents/coding.agent.md` — model-pinned Coding agent (GPT-5.3-Codex)
- `.github/agents/review.agent.md` — model-pinned Review agent (GPT-5.4)
- `.github/agents/fast.agent.md` — model-pinned Fast agent (Claude Haiku 4.5)
- `.github/agents/update.agent.md` — model-pinned Update agent (Claude Sonnet 4.6)
- `.github/agents/doctor.agent.md` — model-pinned Doctor agent (Claude Sonnet 4.6)
- `.github/skills/` — reusable agent skill library (§12)
- `.github/hooks/` — agent lifecycle hooks (§8)
- `.github/instructions/` — path-specific instruction files
- `.github/prompts/` — prompt files for common workflows
- `.vscode/mcp.json` — MCP server configuration
- `.vscode/settings.json` — VS Code settings for Copilot features
- `.copilot/workspace/` — all eight identity files

Note: This file stays unchanged after setup as the origin record.
