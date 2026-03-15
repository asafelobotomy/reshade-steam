#!/usr/bin/env bash
# purpose:  Save critical workspace context before conversation compaction
# when:     PreCompact hook — fires when context is about to be truncated
# inputs:   JSON via stdin with trigger field
# outputs:  JSON with additionalContext summarising saved state
# risk:     safe
set -euo pipefail

# Read workspace files and create a compact summary to survive compaction
SUMMARY=""

# Heartbeat pulse
if [[ -f .copilot/workspace/HEARTBEAT.md ]]; then
  PULSE=$(grep -m1 'HEARTBEAT' .copilot/workspace/HEARTBEAT.md 2>/dev/null || echo "unknown")
  SUMMARY="${SUMMARY}Heartbeat: ${PULSE}. "
fi

# Recent MEMORY.md entries
if [[ -f .copilot/workspace/MEMORY.md ]]; then
  RECENT_MEMORY=$(tail -20 .copilot/workspace/MEMORY.md 2>/dev/null | head -c 500 || echo "")
  if [[ -n "$RECENT_MEMORY" ]]; then
    SUMMARY="${SUMMARY}Recent memory: ${RECENT_MEMORY}. "
  fi
fi

# Current SOUL.md heuristics
if [[ -f .copilot/workspace/SOUL.md ]]; then
  HEURISTICS=$(grep -A1 'heuristic\|principle\|rule\|pattern' .copilot/workspace/SOUL.md 2>/dev/null | head -c 300 || echo "")
  if [[ -n "$HEURISTICS" ]]; then
    SUMMARY="${SUMMARY}Key heuristics: ${HEURISTICS}. "
  fi
fi

# Git status snapshot
GIT_STATUS=$(git status --porcelain 2>/dev/null | head -10 || echo "")
if [[ -n "$GIT_STATUS" ]]; then
  MODIFIED_COUNT=$(echo "$GIT_STATUS" | wc -l | tr -d ' ')
  SUMMARY="${SUMMARY}Git: ${MODIFIED_COUNT} modified files. "
fi

# Truncate to a safe length
SUMMARY=$(echo "$SUMMARY" | head -c 2000)

if [[ -n "$SUMMARY" ]]; then
  # Escape for JSON
  SUMMARY_ESCAPED=$(echo "$SUMMARY" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read().strip()))" 2>/dev/null | sed 's/^"//;s/"$//')

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreCompact",
    "additionalContext": "Pre-compaction workspace snapshot: ${SUMMARY_ESCAPED}"
  }
}
EOF
else
  echo '{"continue": true}'
fi
