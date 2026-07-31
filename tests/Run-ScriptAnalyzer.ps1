#requires -Version 5.1
<#
.SYNOPSIS
    Domain A wrapper: PSScriptAnalyzer Error-severity gate (developer tooling only).
.PARAMETER RequireModule
    Exit 1 if PSScriptAnalyzer is not installed (default: exit 2 = skip).
.NOTES
    Install (developer machine only):
      Install-Module PSScriptAnalyzer -Scope CurrentUser
#>
[CmdletBinding()]
param(
    [switch]$RequireModule
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot

$mod = Get-Module -ListAvailable -Name PSScriptAnalyzer | Select-Object -First 1
if ($null -eq $mod) {
    $msg = 'PSScriptAnalyzer is not installed (developer tooling). Install-Module PSScriptAnalyzer -Scope CurrentUser'
    if ($RequireModule) {
        Write-Host "FAIL: $msg" -ForegroundColor Red
        exit 1
    }
    Write-Host "SKIP: $msg" -ForegroundColor Yellow
    exit 2
}

Import-Module PSScriptAnalyzer -ErrorAction Stop

$paths = @(
    (Join-Path $repoRoot 'packages')
    (Join-Path $repoRoot 'demos')
    (Join-Path $repoRoot 'tests')
    (Join-Path $repoRoot 'templates')
)

$results = New-Object System.Collections.Generic.List[object]
foreach ($path in $paths) {
    if (-not (Test-Path -LiteralPath $path)) { continue }
    $batch = @(Invoke-ScriptAnalyzer -Path $path -Recurse -Severity Error -ErrorAction Stop)
    foreach ($item in $batch) {
        $results.Add($item)
    }
}
$errorResults = @($results | Where-Object { $_.Severity -eq 'Error' })

if ($errorResults.Count -gt 0) {
    foreach ($hit in $errorResults) {
        $line = 'ERROR: {0}:{1} {2} - {3}' -f $hit.ScriptName, $hit.Line, $hit.RuleName, $hit.Message
        Write-Host $line -ForegroundColor Red
    }
    $summary = 'ScriptAnalyzer FAILED ({0} Error findings).' -f $errorResults.Count
    Write-Host $summary -ForegroundColor Red
    exit 1
}

Write-Host 'ScriptAnalyzer OK (zero Error findings).' -ForegroundColor Green
exit 0
