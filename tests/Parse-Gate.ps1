#requires -Version 5.1
<#
.SYNOPSIS
    Domain B parse gate: all product PowerShell files must parse with zero errors.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$roots = @(
    (Join-Path $repoRoot 'packages')
    (Join-Path $repoRoot 'demos')
    (Join-Path $repoRoot 'tests')
)

$failed = $false
$fileCount = 0

foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) {
        continue
    }

    Get-ChildItem -Path $root -Recurse -File -Include *.ps1, *.psm1 |
        ForEach-Object {
            $fileCount++
            $tokens = $null
            $errors = $null
            [void][System.Management.Automation.Language.Parser]::ParseFile(
                $_.FullName,
                [ref]$tokens,
                [ref]$errors
            )
            if ($errors -and $errors.Count -gt 0) {
                $failed = $true
                Write-Host ("PARSE FAIL: {0}" -f $_.FullName) -ForegroundColor Red
                foreach ($e in $errors) {
                    Write-Host ("  {0}" -f $e.ToString()) -ForegroundColor Red
                }
            }
        }
}

if ($fileCount -eq 0) {
    Write-Host 'No PowerShell files found to parse.' -ForegroundColor Yellow
    exit 1
}

if ($failed) {
    Write-Host ("Parse gate FAILED ({0} file(s) scanned)." -f $fileCount) -ForegroundColor Red
    exit 1
}

Write-Host ("Parse gate OK ({0} file(s))." -f $fileCount) -ForegroundColor Green
exit 0
