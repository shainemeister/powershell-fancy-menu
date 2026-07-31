#requires -Version 5.1
<#
.SYNOPSIS
    Enterprise launcher policy: product .cmd must not Bypass ExecutionPolicy or weaken host policy.
.DESCRIPTION
    Scans demos/ and templates/ for .cmd launchers. Developer tooling under tests/
    and certification/ may use Bypass and is intentionally out of scope.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scanRoots = @(
    (Join-Path $repoRoot 'demos')
    (Join-Path $repoRoot 'templates')
)

$failed = $false
$fileCount = 0

function Test-LauncherContent {
    param(
        [string]$Path,
        [string]$Content
    )

    $localFail = $false

    # Strip REM / :: comments so documentation of "do not use Bypass" does not false-positive
    $lines = $Content -split "`r?`n"
    $codeLines = New-Object System.Collections.Generic.List[string]
    foreach ($line in $lines) {
        $trim = $line.Trim()
        if ($trim -match '^(?i)(rem\b|::)') {
            continue
        }
        # Inline: drop REM-style trailing is rare in .cmd; keep full non-comment lines
        [void]$codeLines.Add($line)
    }
    $code = $codeLines -join "`n"

    # Product launchers must not pass -ExecutionPolicy Bypass
    if ($code -match '(?i)-ExecutionPolicy\s+Bypass') {
        Write-Host ("FAIL: {0} contains -ExecutionPolicy Bypass (product launchers must not)." -f $Path) -ForegroundColor Red
        $localFail = $true
    }

    # Must not permanently weaken policy
    if ($code -match '(?i)\bSet-ExecutionPolicy\b') {
        Write-Host ("FAIL: {0} contains Set-ExecutionPolicy." -f $Path) -ForegroundColor Red
        $localFail = $true
    }

    # When invoking powershell, prefer -NoProfile
    if ($code -match '(?i)\bpowershell(\.exe)?\b') {
        if ($code -notmatch '(?i)-NoProfile') {
            Write-Host ("FAIL: {0} invokes powershell without -NoProfile." -f $Path) -ForegroundColor Red
            $localFail = $true
        }
    }

    return -not $localFail
}

foreach ($scanRoot in $scanRoots) {
    if (-not (Test-Path -LiteralPath $scanRoot)) {
        Write-Host ("SKIP scan root (missing): {0}" -f $scanRoot) -ForegroundColor Yellow
        continue
    }

    Get-ChildItem -Path $scanRoot -Recurse -File -Filter '*.cmd' |
        ForEach-Object {
            $fileCount++
            $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
            if (-not (Test-LauncherContent -Path $_.FullName -Content $content)) {
                $script:failed = $true
            }
            else {
                Write-Host ("OK: {0}" -f $_.FullName) -ForegroundColor DarkGray
            }
        }
}

if ($fileCount -eq 0) {
    Write-Host 'No product .cmd launchers found under demos/ or templates/.' -ForegroundColor Red
    exit 1
}

if ($failed) {
    Write-Host ("Security.Launcher FAILED ({0} file(s) scanned)." -f $fileCount) -ForegroundColor Red
    exit 1
}

Write-Host ("Security.Launcher OK ({0} product launcher(s))." -f $fileCount) -ForegroundColor Green
exit 0
