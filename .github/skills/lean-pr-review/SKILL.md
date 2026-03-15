---
name: lean-pr-review
description: Review a pull request using Lean waste categories and structured severity ratings
compatibility: ">=1.4"
---

# Lean PR Review

> Skill metadata: version "1.1"; license MIT; tags [review, pull-request, lean, kaizen, code-review]; compatibility ">=1.4"; recommended tools [codebase, githubRepo].

Perform a structured pull request review using §2 Review Mode conventions and §6 waste categories.

## When to use

- The user asks to "review this PR", "review these changes", or "check my diff"
- The Review agent hands off a PR-scoped review task
- A pull request needs a quality gate before merge

## When NOT to use

- The user wants a full architectural review (use Review Mode directly with the full codebase)
- The changes are a single-line typo fix (overkill — just approve)

## Steps

1. **Get the diff** — Read the PR diff or the set of changed files. If working locally, use `git diff main...HEAD` or the equivalent for the target branch.

2. **Scan each changed file** — For every file in the diff, read the full file (not just the diff hunk) to understand context.

3. **Classify each finding** — For every issue found, record:

   ```text
   [severity] | [file:line] | [waste category] | [description]
   ```

4. **Check test coverage** — Verify that new or changed behaviour has corresponding tests. Flag untested paths as `major | W7 Defects`.

5. **Check for baseline breaches** — Compare against §3 baselines.

6. **Produce the report** — Format as structured markdown with Summary, Findings, and Verdict sections.

7. **Wait** — Do not apply fixes. Present the report and wait for the user to decide what to address.

## Verify

- [ ] Every finding has all four fields: severity, file:line, waste category, description
- [ ] Critical findings are genuinely blocking (not inflated)
- [ ] Test coverage was checked for all new behaviour
- [ ] Baseline breaches are flagged
- [ ] Report ends with a clear verdict
