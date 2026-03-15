# purpose:  Inject subagent governance context when a subagent is spawned
# when:     SubagentStart hook — fires before a subagent begins work
# inputs:   JSON via stdin with subagent details
# outputs:  JSON with additionalContext reminding depth limit and protocols
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'

$input_json = [Console]::In.ReadToEnd()
$agentName = 'unknown'
if ($input_json -match '"agentName"\s*:\s*"([^"]*)"') {
    $agentName = $Matches[1]
}

$context = "Subagent governance: max depth 3. Inherited protocols: PDCA cycle, Tool Protocol, Skill Protocol. Agent: ${agentName}."
$contextEscaped = $context -replace '\\', '\\\\' -replace '"', '\"'

@"
{
  "hookSpecificOutput": {
    "hookEventName": "SubagentStart",
    "additionalContext": "${contextEscaped}"
  }
}
"@
