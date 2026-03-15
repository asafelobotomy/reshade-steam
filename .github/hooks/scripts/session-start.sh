#!/usr/bin/env bash
# purpose:  Inject project context into every new agent session
# when:     SessionStart hook — fires when a new agent session begins
# inputs:   JSON via stdin (common hook fields)
# outputs:  JSON with additionalContext for the agent
# risk:     safe
set -euo pipefail

# Gather project context
BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
NODE_VER=$(node --version 2>/dev/null || echo "n/a")
PYTHON_VER=$(python3 --version 2>/dev/null | awk '{print $2}' || echo "n/a")

# Check for project manifest
if [[ -f package.json ]]; then
  PROJECT_NAME=$(grep -m1 '"name"' package.json | sed 's/.*: *"\(.*\)".*/\1/' 2>/dev/null || echo "unknown")
  PROJECT_VER=$(grep -m1 '"version"' package.json | sed 's/.*: *"\(.*\)".*/\1/' 2>/dev/null || echo "unknown")
elif [[ -f pyproject.toml ]]; then
  PROJECT_NAME=$(grep -m1 '^name' pyproject.toml | sed 's/.*= *"\(.*\)"/\1/' 2>/dev/null || echo "unknown")
  PROJECT_VER=$(grep -m1 '^version' pyproject.toml | sed 's/.*= *"\(.*\)"/\1/' 2>/dev/null || echo "unknown")
elif [[ -f Cargo.toml ]]; then
  PROJECT_NAME=$(grep -m1 '^name' Cargo.toml | sed 's/.*= *"\(.*\)"/\1/' 2>/dev/null || echo "unknown")
  PROJECT_VER=$(grep -m1 '^version' Cargo.toml | sed 's/.*= *"\(.*\)"/\1/' 2>/dev/null || echo "unknown")
else
  PROJECT_NAME=$(basename "$PWD")
  PROJECT_VER="n/a"
fi

# Check heartbeat pulse
PULSE="unknown"
if [[ -f .copilot/workspace/HEARTBEAT.md ]]; then
  PULSE=$(grep -m1 'HEARTBEAT' .copilot/workspace/HEARTBEAT.md 2>/dev/null | head -1 || echo "unknown")
fi

# Emit context for the agent — JSON-escape to handle special characters
CONTEXT="Project: ${PROJECT_NAME} v${PROJECT_VER} | Branch: ${BRANCH} (${COMMIT}) | Node: ${NODE_VER} | Python: ${PYTHON_VER} | Heartbeat: ${PULSE}"
CONTEXT_ESC=$(printf '%s' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()), end='')" 2>/dev/null | sed 's/^"//;s/"$//' || printf '%s' "$CONTEXT")

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
