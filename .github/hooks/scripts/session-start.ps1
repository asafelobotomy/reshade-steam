# purpose:  Inject project context into every new agent session
# when:     SessionStart hook — fires when a new agent session begins
# inputs:   JSON via stdin (common hook fields)
# outputs:  JSON with additionalContext for the agent
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'

function Invoke-Git {
    param([string[]]$Args)
    try { & git @Args 2>$null } catch { 'unknown' }
}

$branch  = (Invoke-Git 'rev-parse', '--abbrev-ref', 'HEAD') ?? 'unknown'
$commit  = (Invoke-Git 'rev-parse', '--short', 'HEAD') ?? 'unknown'
$nodeVer = (node --version 2>$null) ?? 'n/a'
$pyVer   = try { (python --version 2>&1) -replace '^Python ','' } catch { 'n/a' }

$projectName = 'unknown'
$projectVer  = 'n/a'

if (Test-Path 'package.json') {
    $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json
    $projectName = $pkg.name    ?? 'unknown'
    $projectVer  = $pkg.version ?? 'unknown'
} elseif (Test-Path 'pyproject.toml') {
    $content = Get-Content 'pyproject.toml' -Raw
    $projectName = [regex]::Match($content, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $projectVer  = [regex]::Match($content, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
} elseif (Test-Path 'Cargo.toml') {
    $content = Get-Content 'Cargo.toml' -Raw
    $projectName = [regex]::Match($content, '(?m)^name\s*=\s*"([^"]+)"').Groups[1].Value
    $projectVer  = [regex]::Match($content, '(?m)^version\s*=\s*"([^"]+)"').Groups[1].Value
} else {
    $projectName = Split-Path -Leaf $PWD
}

$pulse = 'unknown'
if (Test-Path '.copilot/workspace/HEARTBEAT.md') {
    $pulse = (Select-String -Path '.copilot/workspace/HEARTBEAT.md' -Pattern 'HEARTBEAT' |
              Select-Object -First 1).Line ?? 'unknown'
}

[PSCustomObject]@{
    hookSpecificOutput = [PSCustomObject]@{
        hookEventName     = 'SessionStart'
        additionalContext = "Project: $projectName v$projectVer | Branch: $branch ($commit) | Node: $nodeVer | Python: $pyVer | Heartbeat: $pulse"
    }
} | ConvertTo-Json -Depth 5
