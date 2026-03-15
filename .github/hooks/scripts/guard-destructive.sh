#!/usr/bin/env bash
# purpose:  Block dangerous terminal commands before execution
# when:     PreToolUse hook — fires before the agent invokes any tool
# inputs:   JSON via stdin with tool_name and tool_input
# outputs:  JSON with permissionDecision (allow/deny/ask)
# risk:     safe
#
# This hook is complementary to VS Code's built-in terminal auto-approval
# (github.copilot.chat.agent.terminal.allowList / denyList). This hook runs
# at the PreToolUse level (before command dispatch); auto-approval runs at
# the terminal level (after dispatch, before execution). Use both for
# defense-in-depth.
set -euo pipefail

# JSON-escape a string for safe embedding in heredoc JSON output
json_escape() {
  printf '%s' "$1" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()), end='')" 2>/dev/null | sed 's/^"//;s/"$//' || printf '%s' "$1"
}

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | grep -o '"tool_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"\(.*\)"/\1/') || TOOL_NAME=""

# Only guard terminal/command tools
if [[ "$TOOL_NAME" != *"terminal"* && "$TOOL_NAME" != *"command"* && "$TOOL_NAME" != *"bash"* && "$TOOL_NAME" != *"shell"* ]]; then
  echo '{"continue": true}'
  exit 0
fi

# python3 is required to parse tool_input JSON reliably.
# Without it, TOOL_INPUT would be empty and all patterns would pass unchecked.
if ! command -v python3 >/dev/null 2>&1; then
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "python3 not found — guard-destructive hook cannot parse command. Falling back to manual confirmation."
  }
}
EOF
  exit 0
fi

TOOL_INPUT=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    ti = data.get('tool_input', {})
    print(ti.get('command', ti.get('input', '')))
except Exception:
    print('')
" 2>/dev/null || echo "")

# Blocked patterns — dangerous commands that should never auto-execute
BLOCKED_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.([[:space:]]|$)'
  'DROP TABLE'
  'DROP DATABASE'
  'TRUNCATE TABLE'
  'DELETE FROM .* WHERE 1'
  'mkfs\.'
  'dd if=.* of=/dev/'
  ':(){:|:&};:'
  'chmod -R 777 /'
  'curl .* | sh'
  'wget .* | sh'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$TOOL_INPUT" | grep -qiE "$pattern"; then
    PATTERN_ESC=$(json_escape "$pattern")
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "Blocked by security hook: matched destructive pattern '${PATTERN_ESC}'"
  }
}
EOF
    exit 0
  fi
done

# Caution patterns — require user confirmation
CAUTION_PATTERNS=(
  'rm -rf'
  'rm -r '
  'DROP '
  'DELETE FROM'
  'git push.*--force'
  'git reset --hard'
  'git clean -fd'
  'npm publish'
  'cargo publish'
  'pip install --'
)

for pattern in "${CAUTION_PATTERNS[@]}"; do
  if echo "$TOOL_INPUT" | grep -qiE "$pattern"; then
    PATTERN_ESC=$(json_escape "$pattern")
    COMMAND_ESC=$(json_escape "$(echo "$TOOL_INPUT" | head -c 200)")
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "ask",
    "permissionDecisionReason": "Potentially destructive command detected: matches '${PATTERN_ESC}'. Requires user confirmation.",
    "additionalContext": "The command '${COMMAND_ESC}' matched a caution pattern. Verify this is intended before proceeding."
  }
}
EOF
    exit 0
  fi
done

# Safe — allow execution
echo '{"continue": true}'
