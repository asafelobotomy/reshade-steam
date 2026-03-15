#!/usr/bin/env bash
# purpose:  Log subagent completion and surface result summary
# when:     SubagentStop hook — fires after a subagent finishes
# inputs:   JSON via stdin with subagent result details
# outputs:  JSON with additionalContext summarising outcome
# risk:     safe
set -euo pipefail

INPUT=$(cat)

# Extract subagent name if available
AGENT_NAME=$(echo "$INPUT" | grep -o '"agentName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/') || AGENT_NAME="unknown"

# Build summary context
CONTEXT="Subagent ${AGENT_NAME} completed. Review results before continuing."

# JSON-escape the context
if command -v python3 >/dev/null 2>&1; then
  CONTEXT_ESC=$(printf '%s' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()), end='')" 2>/dev/null | sed 's/^"//;s/"$//' || printf '%s' "$CONTEXT")
else
  CONTEXT_ESC="$CONTEXT"
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
