---
name: extension-review
description: Audit VS Code extensions against the current project stack and recommend keep/add/remove actions
compatibility: ">=3.2"
---

# Extension Review

> Skill metadata: version "1.0"; license MIT; tags [extensions, vscode, audit, tooling, review]; compatibility ">=3.2"; recommended tools [codebase, fetch].

Review the current project's VS Code extensions and recommend what to keep, add, or remove based on the actual stack in the repository.

## When to use

- The user asks to "review extensions", "check my extensions", or "audit VS Code extensions"
- The user wants recommended extensions for the current project
- The user wants to identify duplicate, stale, or irrelevant extensions

## When NOT to use

- The user already knows the exact extension they want to install
- The task is to edit `.vscode/extensions.json` directly without an audit first

## Steps

1. **Get the installed list** - Ask the user to run `code --list-extensions | sort` and paste the output. Copilot cannot read installed extensions directly.

2. **Read workspace recommendations** - Inspect `.vscode/extensions.json` and `.vscode/settings.json` if they exist.

3. **Detect the stack** - Scan the repository for the actual language, runtime, linter, formatter, test, and config signals that determine which extensions are relevant.

4. **Compare installed vs needed** - Build three groups:
   - **Keep** - installed and relevant
   - **Recommended additions** - not installed but clearly useful for the detected stack
   - **Consider removing** - installed but irrelevant, duplicate, deprecated, or superseded

5. **Handle unknown stacks carefully** - If the project uses a tool not covered by the built-in stack table, research the VS Code Marketplace and only recommend candidates that meet all three checks:
   - install count > 100k
   - rating >= 4.0
   - updated within the last 12 months

6. **Persist new mappings** - If an unknown stack produces a qualified extension recommendation, append the new stack-to-extension mapping to `.copilot/workspace/TOOLS.md` under `Extension registry`.

7. **Present the report** - Use this structure:

   ```markdown
   ## Extension Review - <project>

   ### Keep
   - `publisher.extension` - why it still fits

   ### Recommended additions
   - `publisher.extension` - what it provides | why needed
     Install: Ctrl+P -> `ext install publisher.extension`

   ### Consider removing
   - `publisher.extension` - duplicate / unused language / deprecated

   ### Notes
   - stack signals discovered
   - unknown stacks researched
   - extension registry updates made
   ```

8. **Wait** - Do not modify `.vscode/extensions.json` or install/uninstall anything until the user explicitly asks.

## Verify

- [ ] Installed extensions were requested from the user first
- [ ] Workspace recommendations were checked when present
- [ ] Every recommendation is tied to an actual stack signal in the repo
- [ ] Unknown-stack recommendations passed the install/rating/recency quality gate
- [ ] No extension was installed, uninstalled, or written automatically
