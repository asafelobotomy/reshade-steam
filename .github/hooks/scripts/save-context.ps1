# purpose:  Save critical workspace context before conversation compaction
# when:     PreCompact hook — fires when context is about to be truncated
# inputs:   JSON via stdin with trigger field
# outputs:  JSON with additionalContext summarising saved state
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'
$summary = ''

# Heartbeat pulse
if (Test-Path '.copilot/workspace/HEARTBEAT.md') {
    $pulse = (Select-String -Path '.copilot/workspace/HEARTBEAT.md' -Pattern 'HEARTBEAT' |
              Select-Object -First 1).Line
    if ($pulse) { $summary += "Heartbeat: $pulse. " }
}

# Recent MEMORY.md entries
if (Test-Path '.copilot/workspace/MEMORY.md') {
    $recentMemory = (Get-Content '.copilot/workspace/MEMORY.md' -Tail 20 -ErrorAction SilentlyContinue) -join "`n"
    if ($recentMemory.Length -gt 500) { $recentMemory = $recentMemory.Substring(0,500) }
    if ($recentMemory) { $summary += "Recent memory: $recentMemory. " }
}

# SOUL.md heuristics
if (Test-Path '.copilot/workspace/SOUL.md') {
    $heuristics = (Select-String -Path '.copilot/workspace/SOUL.md' -Pattern 'heuristic|principle|rule|pattern' |
                   Select-Object -First 5 | ForEach-Object { $_.Line }) -join ' '
    if ($heuristics.Length -gt 300) { $heuristics = $heuristics.Substring(0,300) }
    if ($heuristics) { $summary += "Key heuristics: $heuristics. " }
}

# Git status snapshot
try {
    $gitStatus = & git status --porcelain 2>$null | Select-Object -First 10
    if ($gitStatus) {
        $modifiedCount = ($gitStatus | Measure-Object).Count
        $summary += "Git: $modifiedCount modified files. "
    }
} catch {}

# Truncate to safe length
if ($summary.Length -gt 2000) { $summary = $summary.Substring(0,2000) }

if ($summary) {
    [PSCustomObject]@{
        hookSpecificOutput = [PSCustomObject]@{
            hookEventName     = 'PreCompact'
            additionalContext = "Pre-compaction workspace snapshot: $summary"
        }
    } | ConvertTo-Json -Depth 5
} else {
    '{"continue": true}'
}
