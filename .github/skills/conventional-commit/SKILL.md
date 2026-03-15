---
name: conventional-commit
description: Write a commit message following the Conventional Commits specification with scope and body
compatibility: ">=1.4"
---

# Conventional Commit

> Skill metadata: version "1.1"; license MIT; tags [git, commit, conventional-commits, changelog, versioning]; compatibility ">=1.4"; recommended tools [codebase, runCommands].

Write a well-structured commit message following the [Conventional Commits](https://www.conventionalcommits.org/) specification.

## When to use

- The user asks to "write a commit message" or "commit these changes"
- Changes are staged and ready to commit
- The user wants consistent, parseable commit history

## When NOT to use

- The user has their own commit message format documented in §10
- The project uses a different commit convention (check §4 and §10 first)

## Steps

1. **Read the staged changes** — Run `git diff --cached --stat` and `git diff --cached`.

2. **Determine the type** — Choose: feat, fix, docs, style, refactor, perf, test, build, ci, chore.

3. **Determine the scope** — Identify the primary area affected. Omit if spanning many areas.

4. **Write the subject line** — Format: `<type>(<scope>): <imperative summary>` (max 72 chars).

5. **Write the body** (if non-trivial) — Explain what and why, wrap at 72 chars.

6. **Add breaking change footer** (if applicable).

7. **Present the message** — Show for user review.

8. **Wait for approval** — Do not run `git commit` until approved.

9. **Execute** — Once approved, run git commit and confirm with `git log --oneline -1`.

## Verify

- [ ] Type is one of the standard Conventional Commits types
- [ ] Subject line is imperative mood, ≤ 72 characters, no trailing period
- [ ] Body explains what and why (if present)
- [ ] Breaking changes have both `!` marker and `BREAKING CHANGE:` footer
- [ ] The message accurately describes all staged changes
