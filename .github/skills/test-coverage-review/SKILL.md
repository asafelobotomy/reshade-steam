---
name: test-coverage-review
description: Audit test coverage, identify gaps, and recommend local tests plus CI workflows
compatibility: ">=3.2"
---

# Test Coverage Review

> Skill metadata: version "1.0"; license MIT; tags [tests, coverage, ci, review, quality]; compatibility ">=3.2"; recommended tools [codebase, runCommands, githubRepo].

Review the current project's test coverage posture and recommend what to test next, what coverage tooling is missing, and which CI workflows would add the most value.

## When to use

- The user asks to "review my tests", "check test coverage", or "what tests should I add"
- The user wants help identifying untested or weakly tested code
- The user wants CI workflow recommendations for coverage and test quality

## When NOT to use

- The user already asked for a specific test file to be written
- The task is only to fix a single failing test

## Steps

1. **Discover the test stack** - Detect test runners and coverage tooling from config files, manifests, and CI workflows.

2. **Ask for coverage output when available** - If a coverage command is configured, ask the user to run it and paste the output. Copilot cannot run the command on the user's machine in chat.

3. **Fall back to static analysis when needed** - If no coverage tooling exists, scan the repository for source files, test files, and obvious gaps.

4. **Identify coverage gaps** - Classify gaps into:
   - **Zero coverage** - no corresponding tests or 0% coverage
   - **Low coverage** - weak or partial coverage, especially under 50%
   - **Missing test types** - no integration, edge-case, or error-path coverage

5. **Recommend local tests** - For each important gap, specify:
   - file or module
   - test type: unit, integration, end-to-end, property-based, or snapshot
   - priority: critical, high, medium, or low
   - a brief description of the behavior or edge case to cover

6. **Recommend CI workflows** - Suggest copy-ready GitHub Actions improvements when they are justified by the stack, such as:
   - coverage gate
   - coverage diff comments
   - nightly full suite
   - runtime matrix
   - mutation testing
   - contract or API tests

7. **Present the report** - Use this structure:

   ```markdown
   ## Test Coverage Review - <project>

   ### Current coverage snapshot
   - framework and runner
   - overall coverage if known
   - test file count and obvious untested areas

   ### Well-covered
   - files or modules that appear healthy

   ### Partially covered
   - files or modules with notable gaps

   ### Untested or near-zero
   - highest-priority missing coverage

   ### Recommended local tests
   - file | type | priority | what to cover

   ### Recommended CI workflows
   - workflow name and why it helps
   - ready-to-copy YAML when appropriate

   ### Notes
   - missing tooling
   - assumptions
   - risk areas
   ```

8. **Wait** - Do not write test files, workflow files, or coverage config until the user explicitly asks.

## Verify

- [ ] Test stack detection is tied to real repository signals
- [ ] Coverage output was requested from the user when tooling exists
- [ ] Static analysis clearly distinguishes assumptions from measured coverage
- [ ] Recommendations are prioritized by user impact and risk
- [ ] No tests or workflows were written automatically
