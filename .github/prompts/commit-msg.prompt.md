---
description: Write a Conventional Commits message from staged changes
argument-hint: Leave blank to auto-detect from staged changes
agent: agent
tools: [runCommands]
---

# Write Commit Message

Inspect the staged changes (`git diff --cached`) and write a commit message following the Conventional Commits specification.

1. Determine the change type: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`.
2. Identify scope from the primary directory or module affected.
3. Write a subject line: `<type>(<scope>): <imperative summary>` (max 72 characters).
4. If the change is non-trivial, add a body explaining *why* the change was made.
5. If the change closes an issue, add a footer: `Closes #<number>`.

Present the message for user approval before committing. Do not commit automatically.
