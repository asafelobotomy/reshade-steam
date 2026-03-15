#!/usr/bin/env bash
# purpose:  Inject subagent governance context when a subagent is spawned
# when:     SubagentStart hook — fires before a subagent begins work
# inputs:   JSON via stdin with subagent details
# outputs:  JSON with additionalContext reminding depth limit and protocols
# risk:     safe
set -euo pipefail

INPUT=$(cat)

# Extract subagent name if available
AGENT_NAME=$(echo "$INPUT" | grep -o '"agentName"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/') || AGENT_NAME="unknown"

# Build governance context
CONTEXT="Subagent governance: max depth 3. Inherited protocols: PDCA cycle, Tool Protocol, Skill Protocol. Agent: ${AGENT_NAME}."

# JSON-escape the context
if command -v python3 >/dev/null 2>&1; then
  CONTEXT_ESC=$(printf '%s' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()), end='')" 2>/dev/null | sed 's/^"//;s/"$//' || printf '%s' "$CONTEXT")
else
  CONTEXT_ESC="$CONTEXT"
fi

cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "${CONTEXT_ESC}"
  }
}
EOF
