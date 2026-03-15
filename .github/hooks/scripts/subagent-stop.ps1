# purpose:  Log subagent completion and surface result summary
# when:     SubagentStop hook — fires after a subagent finishes
# inputs:   JSON via stdin with subagent result details
# outputs:  JSON with additionalContext summarising outcome
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'

$input_json = [Console]::In.ReadToEnd()
$agentName = 'unknown'
if ($input_json -match '"agentName"\s*:\s*"([^"]*)"') {
    $agentName = $Matches[1]
}

$context = "Subagent ${agentName} completed. Review results before continuing."
$contextEscaped = $context -replace '\\', '\\\\' -replace '"', '\"'

@"
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStop",
    "additionalContext": "${contextEscaped}"
  }
}
"@
