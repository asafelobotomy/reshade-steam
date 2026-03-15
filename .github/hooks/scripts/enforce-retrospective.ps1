# purpose:  Remind the agent to run the retrospective before stopping
# when:     Stop hook — fires when the agent session ends
# inputs:   JSON via stdin with stop_hook_active flag
# outputs:  JSON that can block stopping if retrospective was not run
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'
$input_json = $input | Out-String

try {
    $data = $input_json | ConvertFrom-Json
} catch {
    '{"continue": true}'; exit 0
}

# Prevent infinite loops — if already in a stop-hook continuation, allow exit
if ($data.stop_hook_active -eq $true) {
    '{"continue": true}'; exit 0
}

$transcriptPath = $data.transcript_path ?? ''
$retroRan = $false

if ($transcriptPath -and (Test-Path $transcriptPath)) {
    $content = Get-Content $transcriptPath -Raw -ErrorAction SilentlyContinue
    if ($content -imatch 'retrospective|HEARTBEAT|Q[1-8].*SOUL|Q[1-8].*MEMORY|Q[1-8].*USER') {
        $retroRan = $true
    }
}

# Also check if HEARTBEAT.md was modified in the last 5 minutes
if (-not $retroRan -and (Test-Path '.copilot/workspace/HEARTBEAT.md')) {
    $lastWrite = (Get-Item '.copilot/workspace/HEARTBEAT.md').LastWriteTime
    if ((Get-Date) - $lastWrite -lt [TimeSpan]::FromMinutes(5)) {
        $retroRan = $true
    }
}

if (-not $retroRan) {
    [PSCustomObject]@{
        hookSpecificOutput = [PSCustomObject]@{
            hookEventName = 'Stop'
            decision      = 'block'
            reason        = 'The retrospective has not been run this session. Before stopping, run the Retrospective section of HEARTBEAT.md (§8 procedure step 3) and persist insights to workspace files.'
        }
    } | ConvertTo-Json -Depth 5
    exit 0
}

'{"continue": true}'
