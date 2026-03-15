#!/usr/bin/env bash
# purpose:  Remind the agent to run the retrospective before stopping
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin with stop_hook_active flag
# outputs:  JSON that can block stopping if retrospective was not run
# risk:     safe
set -euo pipefail

INPUT=$(cat)

# Check if we're already in a stop-hook continuation to prevent infinite loops
STOP_HOOK_ACTIVE=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(str(data.get('stop_hook_active', False)).lower())
except Exception:
    print('false')
" 2>/dev/null || echo "false")

if [[ "$STOP_HOOK_ACTIVE" == "true" ]]; then
  # Already continuing from a previous stop hook — allow exit
  echo '{"continue": true}'
  exit 0
fi

# Check if the transcript mentions running the retrospective
TRANSCRIPT_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('transcript_path', ''))
except Exception:
    print('')
" 2>/dev/null || echo "")

RETRO_RAN="false"
if [[ -n "$TRANSCRIPT_PATH" && -f "$TRANSCRIPT_PATH" ]]; then
  # Look for evidence the retrospective was executed in this session
  if grep -qi 'retrospective\|HEARTBEAT\|Q[1-8].*SOUL\|Q[1-8].*MEMORY\|Q[1-8].*USER' "$TRANSCRIPT_PATH" 2>/dev/null; then
    RETRO_RAN="true"
  fi
fi

# Also check if HEARTBEAT.md was recently modified (within last 5 minutes)
if [[ -f .copilot/workspace/HEARTBEAT.md ]]; then
  if find .copilot/workspace/HEARTBEAT.md -mmin -5 2>/dev/null | grep -q .; then
    RETRO_RAN="true"
  fi
fi

if [[ "$RETRO_RAN" == "false" ]]; then
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "Stop",
    "decision": "block",
    "reason": "The retrospective has not been run this session. Before stopping, run the Retrospective section of HEARTBEAT.md (§8 procedure step 3) and persist insights to workspace files."
  }
}
EOF
  exit 0
fi

echo '{"continue": true}'
