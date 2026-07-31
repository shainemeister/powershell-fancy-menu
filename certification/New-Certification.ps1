#requires -Version 5.1
<#
.SYNOPSIS
    Generate repo-kit Security and Code Validation certificate (developer tooling).
.DESCRIPTION
    Runs declared Domain B (quality) and Domain A (security) gates for this repo,
    then writes certification/last_certification.json and .txt (gitignored).

    Not a product launcher. Not a third-party audit.
.PARAMETER RequireAnalyzer
    Fail OverallPass if PSScriptAnalyzer is not installed.
.PARAMETER SkipAnalyzer
    Do not run ScriptAnalyzer (OverallPass may still be true if other gates pass).
#>
[CmdletBinding()]
param(
    [switch]$RequireAnalyzer,
    [switch]$SkipAnalyzer
)

$ErrorActionPreference = 'Stop'
$certRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $certRoot
$testsRoot = Join-Path $repoRoot 'tests'
$outJson = Join-Path $certRoot 'last_certification.json'
$outTxt = Join-Path $certRoot 'last_certification.txt'

function Invoke-CertCheck {
    param(
        [string]$Name,
        [string]$Domain,
        [string]$Language,
        [string]$ScriptPath,
        [string[]]$ArgumentList = @(),
        [bool]$Critical = $true
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $passed = $false
    $detail = ''
    $exitCode = -1

    if (-not (Test-Path -LiteralPath $ScriptPath)) {
        $detail = "Missing script: $ScriptPath"
        $sw.Stop()
        return [pscustomobject]@{
            Name       = $Name
            Domain     = $Domain
            Language   = $Language
            Passed     = $false
            Severity   = $(if ($Critical) { 'Critical' } else { 'Advisory' })
            Detail     = $detail
            DurationMs = [int]$sw.ElapsedMilliseconds
            Critical   = $Critical
        }
    }

    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath) + $ArgumentList
    $p = Start-Process -FilePath 'powershell.exe' -ArgumentList $argList -Wait -PassThru -NoNewWindow
    $exitCode = $p.ExitCode
    $sw.Stop()

    if ($exitCode -eq 0) {
        $passed = $true
        $detail = 'exit 0'
    }
    elseif ($Name -eq 'ScriptAnalyzer' -and $exitCode -eq 2 -and -not $RequireAnalyzer) {
        $passed = $true
        $detail = 'exit 2 (module not installed; skipped per policy)'
        $Critical = $false
    }
    else {
        $detail = "exit $exitCode"
    }

    return [pscustomobject]@{
        Name       = $Name
        Domain     = $Domain
        Language   = $Language
        Passed     = $passed
        Severity   = $(if ($Critical) { 'Critical' } else { 'Advisory' })
        Detail     = $detail
        DurationMs = [int]$sw.ElapsedMilliseconds
        Critical   = $Critical
    }
}

$checks = New-Object System.Collections.Generic.List[object]

# Domain B - code validation
$checks.Add((Invoke-CertCheck -Name 'Parse-Gate' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Parse-Gate.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Encoding.Ascii' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Encoding.Ascii.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Core.Model' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Core.Model.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Core.Edge' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Core.Edge.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Feature.Modules' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Feature.Modules.Tests.ps1')))

# Domain A - security
$checks.Add((Invoke-CertCheck -Name 'Security.BanList' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.BanList.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Security.Config' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.Config.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Security.Action' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.Action.Tests.ps1')))

if (-not $SkipAnalyzer) {
    $analyzerArgs = @()
    if ($RequireAnalyzer) { $analyzerArgs = @('-RequireModule') }
    $checks.Add((Invoke-CertCheck -Name 'ScriptAnalyzer' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Run-ScriptAnalyzer.ps1') -ArgumentList $analyzerArgs -Critical:$RequireAnalyzer))
}

$secChecks = @($checks | Where-Object { $_.Domain -eq 'Security' })
$valChecks = @($checks | Where-Object { $_.Domain -eq 'CodeValidation' })

$secCriticalFailed = @($secChecks | Where-Object { $_.Critical -and -not $_.Passed }).Count
$valCriticalFailed = @($valChecks | Where-Object { $_.Critical -and -not $_.Passed }).Count

$secPass = ($secCriticalFailed -eq 0)
$valPass = ($valCriticalFailed -eq 0)
$overall = $secPass -and $valPass

$gitCommit = ''
$gitBranch = ''
$gitDirty = $false
try {
    Push-Location $repoRoot
    $gitCommit = (& git rev-parse HEAD 2>$null)
    $gitBranch = (& git rev-parse --abbrev-ref HEAD 2>$null)
    $status = (& git status --porcelain 2>$null)
    if ($status) { $gitDirty = $true }
    Pop-Location
}
catch {
    try { Pop-Location } catch { }
}

$now = (Get-Date).ToUniversalTime().ToString('o')
$disclaimer = 'Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No secrets in this certificate.'

$cert = [ordered]@{
    CertificateType   = 'SecurityAndCodeValidationCertification'
    OverallPass       = $overall
    Success           = $overall
    TimestampUtc      = $now
    RepoRoot          = $repoRoot
    GitCommit         = [string]$gitCommit
    GitBranch         = [string]$gitBranch
    GitDirty          = $gitDirty
    LanguageSurfaces  = @('PowerShell')
    PackageVersions   = @{ PsMenuKit = '0.5.0' }
    ToolVersions      = @{ PowerShell = $PSVersionTable.PSVersion.ToString() }
    PassCriteria      = 'Critical checks exit 0; optional ScriptAnalyzer skip allowed unless -RequireAnalyzer'
    Domains           = @{
        Security = @{
            OverallPass    = $secPass
            CriticalFailed = $secCriticalFailed
        }
        CodeValidation = @{
            OverallPass    = $valPass
            CriticalFailed = $valCriticalFailed
        }
    }
    Checks            = @($checks | ForEach-Object {
            [ordered]@{
                Name       = $_.Name
                Domain     = $_.Domain
                Language   = $_.Language
                Passed     = $_.Passed
                Severity   = $_.Severity
                Detail     = $_.Detail
                DurationMs = $_.DurationMs
            }
        })
    Disclaimer        = $disclaimer
    Message           = $(if ($overall) { 'All critical declared gates passed.' } else { 'One or more critical gates failed.' })
}

$json = $cert | ConvertTo-Json -Depth 8
[System.IO.File]::WriteAllText($outJson, $json, (New-Object System.Text.UTF8Encoding $false))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('PsMenuKit Security and Code Validation Certificate')
[void]$sb.AppendLine(('Generated (UTC): {0}' -f $now))
[void]$sb.AppendLine(('OverallPass: {0}' -f $overall))
[void]$sb.AppendLine(('GitCommit: {0}' -f $gitCommit))
[void]$sb.AppendLine(('GitBranch: {0}' -f $gitBranch))
[void]$sb.AppendLine(('GitDirty: {0}' -f $gitDirty))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Security ==')
[void]$sb.AppendLine(('OverallPass: {0}  CriticalFailed: {1}' -f $secPass, $secCriticalFailed))
foreach ($c in $secChecks) {
    [void]$sb.AppendLine(('- [{0}] {1}: {2} ({3} ms) {4}' -f $(if ($c.Passed) { 'PASS' } else { 'FAIL' }), $c.Name, $c.Detail, $c.DurationMs, $c.Severity))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Code validation ==')
[void]$sb.AppendLine(('OverallPass: {0}  CriticalFailed: {1}' -f $valPass, $valCriticalFailed))
foreach ($c in $valChecks) {
    [void]$sb.AppendLine(('- [{0}] {1}: {2} ({3} ms) {4}' -f $(if ($c.Passed) { 'PASS' } else { 'FAIL' }), $c.Name, $c.Detail, $c.DurationMs, $c.Severity))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Disclaimer ==')
[void]$sb.AppendLine($disclaimer)
[void]$sb.AppendLine('Suggested IT one-liner: Automated security static analysis and code validation for declared PowerShell surfaces produced a self-attestation certificate for this commit. Not a third-party audit.')

[System.IO.File]::WriteAllText($outTxt, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-Host ''
Write-Host ('Certificate written: {0}' -f $outJson)
Write-Host ('Certificate written: {0}' -f $outTxt)
Write-Host ('OverallPass: {0}' -f $overall)
if (-not $overall) {
    exit 1
}
exit 0
