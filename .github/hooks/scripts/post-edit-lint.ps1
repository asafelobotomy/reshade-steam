# purpose:  Auto-format files after agent edits them
# when:     PostToolUse hook — fires after a tool completes successfully
# inputs:   JSON via stdin with tool_name and tool_input
# outputs:  JSON with additionalContext if lint errors found
# risk:     safe

$ErrorActionPreference = 'SilentlyContinue'
$input_json = $input | Out-String

try {
    $data = $input_json | ConvertFrom-Json
} catch {
    '{"continue": true}'; exit 0
}

$toolName = $data.tool_name ?? ''

# Only run after file-editing tools
if ($toolName -notmatch 'edit|create|write|replace') {
    '{"continue": true}'; exit 0
}

$ti = $data.tool_input
$files = @()

foreach ($key in @('filePath','file','path','files','file_path')) {
    $val = $ti.$key
    if ($null -ne $val) {
        if ($val -is [array]) { $files += $val }
        elseif ($val) { $files += $val }
    }
}

if ($files.Count -eq 0) {
    '{"continue": true}'; exit 0
}

foreach ($filepath in $files) {
    if (-not $filepath -or -not (Test-Path $filepath)) { continue }
    $ext = [System.IO.Path]::GetExtension($filepath).TrimStart('.')

    switch ($ext) {
        { $_ -in 'js','jsx','ts','tsx','mjs','cjs' } {
            if ((Get-Command npx -ErrorAction SilentlyContinue) -and (Test-Path 'node_modules/.bin/prettier')) {
                npx prettier --write $filepath 2>$null | Out-Null
            }
        }
        'py' {
            if (Get-Command black -ErrorAction SilentlyContinue) {
                black --quiet $filepath 2>$null | Out-Null
            } elseif (Get-Command ruff -ErrorAction SilentlyContinue) {
                ruff format $filepath 2>$null | Out-Null
            }
        }
        'rs' {
            if (Get-Command rustfmt -ErrorAction SilentlyContinue) {
                rustfmt $filepath 2>$null | Out-Null
            }
        }
        'go' {
            if (Get-Command gofmt -ErrorAction SilentlyContinue) {
                gofmt -w $filepath 2>$null | Out-Null
            }
        }
    }
}

'{"continue": true}'
