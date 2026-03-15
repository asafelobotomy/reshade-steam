---
name: issue-triage
description: Triage a GitHub issue by classifying severity, labelling waste category, proposing next action, and drafting a structured response
compatibility: ">=1.4"
---

# Issue Triage

> Skill metadata: version "1.1"; license MIT; tags [triage, issues, github, lean, kaizen, bug, feature-request]; compatibility ">=1.4"; recommended tools [codebase, githubRepo, runCommands].

Systematically triage a GitHub issue using Lean waste categories, severity classification, and structured output — producing an actionable recommendation and a ready-to-post comment.

## When to use

- The user says "triage this issue", "classify this bug", or "triage #NNN"
- A new issue has been opened and needs a first-response classification
- A batch of issues needs sorting before sprint planning

## When NOT to use

- The issue is already triaged and has labels/milestone assigned — use Review Mode instead
- The user wants a full root-cause analysis (that is a debugging task, not triage)

## Steps

1. **Read the issue** — Fetch the issue body, title, and all comments. Note the reporter, date, and any linked PRs or commits.

2. **Reproduce context** — Search the codebase for the affected file(s), function(s), or API mentioned in the issue. Read relevant code to confirm or deny the described behaviour.

3. **Classify severity** using these definitions:
   - `critical` — data loss, security vulnerability, crash in production path, or regression blocking release
   - `major` — significant functionality broken; workaround exists but is painful
   - `minor` — cosmetic, edge-case, or low-frequency impact
   - `advisory` — enhancement or improvement with no current breakage

4. **Map to waste category** (§6 Muda — use the full catalogue; most common for issues):

   | Waste code | Name | Typical issue signal |
   |-----------|------|---------------------|
   | W1 Overproduction | Duplicate feature/issue already in backlog | "This was reported in #NNN" |
   | W2 Waiting | Blocked on external dependency, PR, or decision | "Waiting on upstream fix" |
   | W5 Inventory | Stale issue; may no longer be reproducible | Reported > 6 months ago, no recent activity |
   | W6 Motion | Poor UX causing user confusion — not a code defect | "I couldn't find the button" |
   | W7 Defects | Code correctness bug | Crash, wrong output, data loss |
   | W8 Unused talent | Missing automation or documentation causing repeated effort | "We keep getting this question" |

   Codes W3, W4, W9–W16 may apply — consult §6 for the full definitions if the above don't fit.

5. **Propose next action** — choose one:
   - `fix` — assign to a sprint, link to affected file(s)
   - `investigate` — needs more information; list specific questions for the reporter
   - `close-duplicate` — link to the canonical issue
   - `close-wontfix` — explain the design decision
   - `close-stale` — the issue is no longer reproducible or relevant
   - `defer` — valid but low priority; move to backlog

6. **Draft a comment** — Write a structured GitHub comment using this template:

   ```text
   **Triage result**

   | Field | Value |
   |-------|-------|
   | Severity | [critical / major / minor / advisory] |
   | Waste category | [Wn — name] |
   | Reproducible | [yes / no / unknown — explain] |
   | Next action | [fix / investigate / close-duplicate / close-wontfix / close-stale / defer] |

   **Summary**: [one sentence describing the issue and its impact]

   **Recommended labels**: `[label1]`, `[label2]`

   [If next action is investigate]:
   > To help us investigate, please provide: [specific questions]
   ```

7. **Verify** — Confirm:
   - Severity matches the impact described in step 2
   - Waste category is justified by evidence from the codebase (not guessed)
   - The drafted comment is factual and does not speculate beyond the code read
   - No file content claimed without being read this session (§4 read-before-claiming)
