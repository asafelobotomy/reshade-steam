# Heartbeat — reshade-steam

> Event-driven health check. Read this file at every trigger event, run all checks, update Pulse, and log to History.
> **Contract**: Follow this checklist strictly. Do not infer tasks from prior sessions.

## Pulse

`HEARTBEAT_OK` — No alerts.

## Event Triggers

Fire a heartbeat when any of these occur:

- **Session start** — always
- **Large change** — modified >5 files in a single task
- **Refactor/migration** — task tagged as refactor, migration, or restructure
- **Dependency update** — any manifest changed (package.json, Cargo.toml, requirements.txt, go.mod, etc.)
- **CI resolution** — after resolving a CI failure
- **Task completion** — after completing any user-requested task
- **Explicit** — user says "Check your heartbeat"
<!-- Add custom triggers below this line -->

## Checks

Run each check; prepend `[!]` to Pulse if any fails:

- [ ] **Dependency audit** — any outdated or security-advisory deps in TOOLS.md / manifests?
- [ ] **Test coverage delta** — did coverage drop since last session?
- [ ] **Waste scan** — any new W1–W16 waste accumulated this session? (§6)
- [ ] **MEMORY.md consolidation** — anything from this session to persist?
- [ ] **Metrics freshness** — has the metrics baseline been reviewed in the last 3 sessions?
- [ ] **Settings drift** — do §10 overrides still match the codebase?
- [ ] **Agent compatibility** — do agent files use current frontmatter schema? Any deprecated fields?
<!-- Add custom checks below this line -->

## Retrospective

After completing a task, reflect on these questions. Write insights to the indicated workspace files. Surface Q4 and Q5 to $USER directly — all other answers are silent.

1. **Approach review** — Were there any errors, corrections, or backtracking during this task? What concrete signal caused the course change? → *SOUL.md*
2. **Scope audit** — Did the task scope grow or shrink during execution? Were any user requests deferred, simplified, or left incomplete? → *MEMORY.md (Known Gotchas)*
3. **Gap analysis** — Review the original request and the delivered result. Is there any explicit requirement I did not address, or any file I modified without updating its tests or docs? → *MEMORY.md*
4. **Issue report** — Did I spot any issues to report to $USER? (e.g. security concerns, tech debt, broken assumptions, stale dependencies) → *Surface to $USER*
5. **Agent questions** — Do I have questions, suggestions, or things I misunderstood? → *Surface to $USER*
6. **User profile** — What explicit preferences, corrections, or working patterns did $USER demonstrate? (Only record directly observable signals; do not infer emotion or intent.) → *USER.md*
7. **Lessons learned** — State as concrete rules: "When [situation], do [action] instead of [what usually fails]." Only record lessons grounded in this session's events. → *MEMORY.md + SOUL.md*
8. **Correction log** — Did $USER correct, reject, or redirect anything I produced? What was my original output and what did $USER want instead? → *MEMORY.md (Recurring Error Patterns) + SOUL.md*

<!-- Add custom retrospective questions below this line -->

## Agent Notes

Agent-writable. Record observations, patterns, and items to flag on the next heartbeat.

## History

Append-only. Keep the last five entries.

| Date | Trigger | Result | Actions taken |
|------|---------|--------|---------------|
