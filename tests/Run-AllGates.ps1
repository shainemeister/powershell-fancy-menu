#requires -Version 5.1
<#
.SYNOPSIS
    Runs all required Domain B and kit Domain A security smoke gates for PsMenuKit.
.PARAMETER SkipAnalyzer
    Do not invoke Run-ScriptAnalyzer.ps1 even if PSScriptAnalyzer is installed.
.PARAMETER RequireAnalyzer
    Fail if PSScriptAnalyzer is not available.
#>
[CmdletBinding()]
param(
    [switch]$SkipAnalyzer,
    [switch]$RequireAnalyzer
)

$ErrorActionPreference = 'Stop'
$testsRoot = $PSScriptRoot
$failed = $false

function Invoke-Gate {
    param(
        [string]$Name,
        [string]$Path,
        [string[]]$ArgumentList = @()
    )

    Write-Host ''
    Write-Host "=== GATE: $Name ===" -ForegroundColor Cyan
    if (-not (Test-Path -LiteralPath $Path)) {
        Write-Host "FAIL: missing $Path" -ForegroundColor Red
        $script:failed = $true
        return
    }

    $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $Path) + $ArgumentList
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -NoNewWindow
    if ($p.ExitCode -ne 0) {
        Write-Host "FAIL: $Name (exit $($p.ExitCode))" -ForegroundColor Red
        $script:failed = $true
    }
    else {
        Write-Host "PASS: $Name" -ForegroundColor Green
    }
}

$gates = @(
    @{ Name = 'Parse-Gate'; Path = (Join-Path $testsRoot 'Parse-Gate.ps1') }
    @{ Name = 'Encoding.Ascii'; Path = (Join-Path $testsRoot 'Encoding.Ascii.Tests.ps1') }
    @{ Name = 'Core.Model'; Path = (Join-Path $testsRoot 'Core.Model.Tests.ps1') }
    @{ Name = 'Core.Edge'; Path = (Join-Path $testsRoot 'Core.Edge.Tests.ps1') }
    @{ Name = 'Feature.Modules'; Path = (Join-Path $testsRoot 'Feature.Modules.Tests.ps1') }
    @{ Name = 'Security.BanList'; Path = (Join-Path $testsRoot 'Security.BanList.Tests.ps1') }
    @{ Name = 'Security.Config'; Path = (Join-Path $testsRoot 'Security.Config.Tests.ps1') }
    @{ Name = 'Security.Action'; Path = (Join-Path $testsRoot 'Security.Action.Tests.ps1') }
    @{ Name = 'Security.Launcher'; Path = (Join-Path $testsRoot 'Security.Launcher.Tests.ps1') }
)

foreach ($g in $gates) {
    Invoke-Gate -Name $g.Name -Path $g.Path
}

if (-not $SkipAnalyzer) {
    $analyzer = Join-Path $testsRoot 'Run-ScriptAnalyzer.ps1'
    if ($RequireAnalyzer) {
        Invoke-Gate -Name 'ScriptAnalyzer' -Path $analyzer -ArgumentList @('-RequireModule')
    }
    else {
        Write-Host ''
        Write-Host '=== GATE: ScriptAnalyzer (optional if module missing) ===' -ForegroundColor Cyan
        if (-not (Test-Path -LiteralPath $analyzer)) {
            Write-Host 'FAIL: missing Run-ScriptAnalyzer.ps1' -ForegroundColor Red
            $failed = $true
        }
        else {
            $args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $analyzer)
            $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $args -Wait -PassThru -NoNewWindow
            if ($p.ExitCode -eq 0) {
                Write-Host 'PASS: ScriptAnalyzer' -ForegroundColor Green
            }
            elseif ($p.ExitCode -eq 2) {
                Write-Host 'SKIP: ScriptAnalyzer (module not installed)' -ForegroundColor Yellow
            }
            else {
                Write-Host "FAIL: ScriptAnalyzer (exit $($p.ExitCode))" -ForegroundColor Red
                $failed = $true
            }
        }
    }
}

Write-Host ''
if ($failed) {
    Write-Host 'Run-AllGates FAILED' -ForegroundColor Red
    exit 1
}

Write-Host 'Run-AllGates OK' -ForegroundColor Green
exit 0
