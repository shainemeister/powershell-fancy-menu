#requires -Version 5.1
<#
.SYNOPSIS
    Generate repo-kit Security and Code Validation certificate (developer tooling).
.DESCRIPTION
    Runs declared Domain B (quality) and Domain A (security) gates for this repo,
    then writes certification/last_certification.json and .txt (gitignored).

    Certificate schema 1.1: SchemaVersion, tool versions, integrity hashes,
    launcher policy, optional Gitleaks, multi-surface inventory.

    Not a product launcher. Not a third-party audit.
.PARAMETER RequireAnalyzer
    Fail OverallPass if PSScriptAnalyzer is not installed (default: true for formal cert).
.PARAMETER SkipAnalyzer
    Do not run ScriptAnalyzer.
.PARAMETER RequireSecretsScan
    Fail OverallPass if gitleaks is missing or reports findings.
.PARAMETER SkipSecretsScan
    Do not attempt gitleaks (default when not RequireSecretsScan: try if present, else advisory skip).
.PARAMETER Quiet
    Reduce console noise (still writes certificate files).
#>
[CmdletBinding()]
param(
    [switch]$RequireAnalyzer,
    [switch]$SkipAnalyzer,
    [switch]$RequireSecretsScan,
    [switch]$SkipSecretsScan,
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
$certRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $certRoot
$testsRoot = Join-Path $repoRoot 'tests'
$outJson = Join-Path $certRoot 'last_certification.json'
$outTxt = Join-Path $certRoot 'last_certification.txt'

# Formal cert defaults: require analyzer unless explicitly skipped
if (-not $PSBoundParameters.ContainsKey('RequireAnalyzer') -and -not $SkipAnalyzer) {
    $RequireAnalyzer = $true
}

function Write-CertHost {
    param([string]$Message, [ConsoleColor]$Color = [ConsoleColor]::Gray)
    if (-not $Quiet) {
        Write-Host $Message -ForegroundColor $Color
    }
}

function Get-PsMenuKitModuleVersion {
    $manifestPath = Join-Path $repoRoot 'packages\PsMenuKit\PsMenuKit.psd1'
    if (-not (Test-Path -LiteralPath $manifestPath)) {
        return 'unknown'
    }
    try {
        $data = Import-PowerShellDataFile -Path $manifestPath
        if ($data.ModuleVersion) {
            return [string]$data.ModuleVersion
        }
    }
    catch { }
    return 'unknown'
}

function Get-FileSha256Hex {
    param([string]$Path)
    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }
    $hash = Get-FileHash -LiteralPath $Path -Algorithm SHA256
    return $hash.Hash.ToLowerInvariant()
}

function Get-TreeSha256Hex {
    <#
    .SYNOPSIS
        Deterministic hash of sorted relative paths + file SHA256 under a root.
    #>
    param(
        [string]$RootPath,
        [string[]]$Include = @('*.ps1', '*.psm1', '*.psd1')
    )

    if (-not (Test-Path -LiteralPath $RootPath)) {
        return $null
    }

    $rootFull = [System.IO.Path]::GetFullPath($RootPath)
    $lines = New-Object System.Collections.Generic.List[string]

    $files = Get-ChildItem -Path $rootFull -Recurse -File -Include $Include | Sort-Object FullName
    foreach ($f in $files) {
        $rel = $f.FullName.Substring($rootFull.Length).TrimStart('\', '/')
        $rel = $rel.Replace('\', '/')
        $h = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        $lines.Add(('{0}|{1}' -f $rel, $h))
    }

    $payload = ($lines -join "`n")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($payload)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $hashBytes = $sha.ComputeHash($bytes)
        return ([System.BitConverter]::ToString($hashBytes) -replace '-', '').ToLowerInvariant()
    }
    finally {
        $sha.Dispose()
    }
}

function Get-OsCaption {
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction SilentlyContinue
        if ($null -ne $os -and $os.Caption) {
            return [string]$os.Caption
        }
    }
    catch { }
    return [Environment]::OSVersion.VersionString
}

function Invoke-CertCheck {
    param(
        [string]$Name,
        [string]$Domain,
        [string]$Language,
        [string]$ScriptPath,
        [string[]]$ArgumentList = @(),
        [bool]$Critical = $true,
        [scriptblock]$Inline = $null
    )

    $sw = [System.Diagnostics.Stopwatch]::StartNew()
    $passed = $false
    $detail = ''
    $exitCode = -1

    if ($null -ne $Inline) {
        try {
            $inlineResult = & $Inline
            if ($inlineResult -is [hashtable]) {
                $passed = [bool]$inlineResult.Passed
                $detail = [string]$inlineResult.Detail
                if ($inlineResult.ContainsKey('Critical')) {
                    $Critical = [bool]$inlineResult.Critical
                }
            }
            else {
                $passed = [bool]$inlineResult
                $detail = 'inline'
            }
        }
        catch {
            $passed = $false
            $detail = $_.Exception.Message
        }
        $sw.Stop()
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
$pkgVersion = Get-PsMenuKitModuleVersion

# Domain B - code validation
$checks.Add((Invoke-CertCheck -Name 'Parse-Gate' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Parse-Gate.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Encoding.Ascii' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Encoding.Ascii.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Core.Model' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Core.Model.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Core.Edge' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Core.Edge.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Feature.Modules' -Domain 'CodeValidation' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Feature.Modules.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Manifest.VersionConsistency' -Domain 'CodeValidation' -Language 'PowerShell' -Critical $true -Inline {
        $manifestPath = Join-Path $repoRoot 'packages\PsMenuKit\PsMenuKit.psd1'
        $corePath = Join-Path $repoRoot 'packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1'
        $configPath = Join-Path $repoRoot 'packages\PsMenuKit\src\Modules\Config\PsMenuKit.Config.psd1'
        if ($pkgVersion -eq 'unknown') {
            return @{ Passed = $false; Detail = 'Could not read root ModuleVersion' }
        }
        $coreVer = 'missing'
        $configVer = 'missing'
        try { $coreVer = [string](Import-PowerShellDataFile -Path $corePath).ModuleVersion } catch { }
        try { $configVer = [string](Import-PowerShellDataFile -Path $configPath).ModuleVersion } catch { }
        if ($coreVer -ne $pkgVersion -or $configVer -ne $pkgVersion) {
            return @{
                Passed = $false
                Detail = ("Version mismatch root={0} Core={1} Config={2}" -f $pkgVersion, $coreVer, $configVer)
            }
        }
        return @{ Passed = $true; Detail = ("ModuleVersion {0} consistent (root/Core/Config)" -f $pkgVersion) }
    }))

# Domain A - security
$checks.Add((Invoke-CertCheck -Name 'Security.BanList' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.BanList.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Security.Config' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.Config.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Security.Action' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Security.Action.Tests.ps1')))
$checks.Add((Invoke-CertCheck -Name 'Security.Launcher' -Domain 'Security' -Language 'Shell' -ScriptPath (Join-Path $testsRoot 'Security.Launcher.Tests.ps1')))

$analyzerVersion = $null
if (-not $SkipAnalyzer) {
    $mod = Get-Module -ListAvailable -Name PSScriptAnalyzer | Sort-Object Version -Descending | Select-Object -First 1
    if ($null -ne $mod) {
        $analyzerVersion = $mod.Version.ToString()
    }
    $analyzerArgs = @()
    if ($RequireAnalyzer) { $analyzerArgs = @('-RequireModule') }
    $checks.Add((Invoke-CertCheck -Name 'ScriptAnalyzer' -Domain 'Security' -Language 'PowerShell' -ScriptPath (Join-Path $testsRoot 'Run-ScriptAnalyzer.ps1') -ArgumentList $analyzerArgs -Critical:$RequireAnalyzer))
}

# Secrets (Gitleaks) - optional surface
$gitleaksVersion = $null
$secretsSurface = $false
if (-not $SkipSecretsScan) {
    $secretsSurface = $true
    $checks.Add((Invoke-CertCheck -Name 'Secrets.Gitleaks' -Domain 'Security' -Language 'Secrets' -Critical:$RequireSecretsScan -Inline {
            $cmd = Get-Command -Name 'gitleaks' -ErrorAction SilentlyContinue
            if ($null -eq $cmd) {
                if ($RequireSecretsScan) {
                    return @{ Passed = $false; Detail = 'gitleaks not found on PATH'; Critical = $true }
                }
                return @{ Passed = $true; Detail = 'gitleaks not installed; advisory skip'; Critical = $false }
            }
            try {
                $verOut = & gitleaks version 2>&1 | Out-String
                $script:gitleaksVersion = ($verOut.Trim() -split "`n" | Select-Object -First 1)
            }
            catch {
                $script:gitleaksVersion = 'present'
            }
            $prev = Get-Location
            $prevEap = $ErrorActionPreference
            $code = -1
            try {
                # Native stderr (INF lines) must not become terminating errors under Stop
                $ErrorActionPreference = 'Continue'
                Set-Location $repoRoot
                $null = & gitleaks detect --source . --no-banner 2>&1 | Out-String
                $code = $LASTEXITCODE
            }
            finally {
                $ErrorActionPreference = $prevEap
                Set-Location $prev
            }
            # gitleaks: 0 = clean, 1 = leaks found
            if ($code -eq 0) {
                return @{ Passed = $true; Detail = 'gitleaks detect exit 0 (no leaks)'; Critical = $false }
            }
            if ($code -eq 1) {
                # Findings: critical only when secrets scan is required
                return @{
                    Passed   = $false
                    Detail   = 'gitleaks detect found potential secrets (exit 1)'
                    Critical = [bool]$RequireSecretsScan
                }
            }
            if ($RequireSecretsScan) {
                return @{ Passed = $false; Detail = ("gitleaks exit {0}" -f $code); Critical = $true }
            }
            return @{ Passed = $true; Detail = ("gitleaks exit {0}; treated advisory" -f $code); Critical = $false }
        }))
}

# Docs authority (advisory)
$checks.Add((Invoke-CertCheck -Name 'Docs.SecurityAuthority' -Domain 'CodeValidation' -Language 'PowerShell' -Critical $false -Inline {
        $sec = Join-Path $repoRoot 'packages\PsMenuKit\SECURITY.md'
        $certReadme = Join-Path $repoRoot 'certification\README.md'
        if (-not (Test-Path -LiteralPath $sec)) {
            return @{ Passed = $false; Detail = 'SECURITY.md missing' }
        }
        if (-not (Test-Path -LiteralPath $certReadme)) {
            return @{ Passed = $false; Detail = 'certification/README.md missing' }
        }
        $secText = Get-Content -LiteralPath $sec -Raw
        $readmeText = Get-Content -LiteralPath $certReadme -Raw
        if ($secText -match '\{\{[A-Z0-9_]+\}\}' -or $readmeText -match '\{\{[A-Z0-9_]+\}\}') {
            return @{ Passed = $false; Detail = 'Unresolved {{PLACEHOLDERS}} in security/cert docs' }
        }
        return @{ Passed = $true; Detail = 'SECURITY.md + certification README present' }
    }))

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

$gitShort = ''
if ($gitCommit -and $gitCommit.Length -ge 7) {
    $gitShort = $gitCommit.Substring(0, 7)
}

$manifestRel = 'packages/PsMenuKit/PsMenuKit.psd1'
$manifestFull = Join-Path $repoRoot ($manifestRel -replace '/', '\')
$srcRoot = Join-Path $repoRoot 'packages\PsMenuKit\src'
$manifestHash = Get-FileSha256Hex -Path $manifestFull
$srcTreeHash = Get-TreeSha256Hex -RootPath $srcRoot

$now = (Get-Date).ToUniversalTime().ToString('o')
$disclaimer = 'Self-attestation of automated checks only. Not a third-party audit. Not runtime package diagnostics. No secrets in this certificate.'

$languageSurfaces = New-Object System.Collections.Generic.List[string]
[void]$languageSurfaces.Add('PowerShell')
[void]$languageSurfaces.Add('Shell')
if ($secretsSurface) {
    [void]$languageSurfaces.Add('Secrets')
}

$toolVersions = [ordered]@{
    PowerShell = $PSVersionTable.PSVersion.ToString()
    OS         = Get-OsCaption
}
if ($analyzerVersion) {
    $toolVersions['PSScriptAnalyzer'] = $analyzerVersion
}
if ($gitleaksVersion) {
    $toolVersions['Gitleaks'] = [string]$gitleaksVersion
}

$passCriteria = 'Critical checks exit 0 / pass; ScriptAnalyzer required unless -SkipAnalyzer; Gitleaks advisory unless -RequireSecretsScan; product launchers enterprise policy'

$cert = [ordered]@{
    CertificateType   = 'SecurityAndCodeValidationCertification'
    SchemaVersion     = '1.1'
    OverallPass       = $overall
    Success           = $overall
    TimestampUtc      = $now
    RepoRoot          = $repoRoot
    GitCommit         = [string]$gitCommit
    GitCommitShort    = [string]$gitShort
    GitBranch         = [string]$gitBranch
    GitDirty          = $gitDirty
    LanguageSurfaces  = @($languageSurfaces)
    PackageVersions   = @{
        PsMenuKit = $pkgVersion
    }
    ToolVersions      = [hashtable]$toolVersions
    PassCriteria      = $passCriteria
    Policy            = @{
        RequireAnalyzer      = [bool]$RequireAnalyzer
        RequireSecretsScan   = [bool]$RequireSecretsScan
        RequireLauncherPolicy = $true
        SkipAnalyzer         = [bool]$SkipAnalyzer
        SkipSecretsScan      = [bool]$SkipSecretsScan
    }
    Integrity         = @{
        ManifestPath     = $manifestRel
        ManifestSha256   = $manifestHash
        PackagesSrcSha256 = $srcTreeHash
    }
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
    SuggestedItOneLiner = ('Automated security static analysis and code validation for declared surfaces produced a self-attestation certificate for commit {0} at {1}. Not a third-party audit.' -f $(if ($gitShort) { $gitShort } else { 'unknown' }), $now)
}

$json = $cert | ConvertTo-Json -Depth 10
[System.IO.File]::WriteAllText($outJson, $json, (New-Object System.Text.UTF8Encoding $false))

$sb = New-Object System.Text.StringBuilder
[void]$sb.AppendLine('PsMenuKit Security and Code Validation Certificate')
[void]$sb.AppendLine(('SchemaVersion: {0}' -f $cert.SchemaVersion))
[void]$sb.AppendLine(('Generated (UTC): {0}' -f $now))
[void]$sb.AppendLine(('OverallPass: {0}' -f $overall))
[void]$sb.AppendLine(('GitCommit: {0}' -f $gitCommit))
[void]$sb.AppendLine(('GitCommitShort: {0}' -f $gitShort))
[void]$sb.AppendLine(('GitBranch: {0}' -f $gitBranch))
[void]$sb.AppendLine(('GitDirty: {0}' -f $gitDirty))
[void]$sb.AppendLine(('Package PsMenuKit: {0}' -f $pkgVersion))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Policy ==')
[void]$sb.AppendLine(('RequireAnalyzer: {0}' -f $RequireAnalyzer))
[void]$sb.AppendLine(('RequireSecretsScan: {0}' -f $RequireSecretsScan))
[void]$sb.AppendLine(('LanguageSurfaces: {0}' -f ($languageSurfaces -join ', ')))
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Tool versions ==')
foreach ($k in $toolVersions.Keys) {
    [void]$sb.AppendLine(('- {0}: {1}' -f $k, $toolVersions[$k]))
}
[void]$sb.AppendLine('')
[void]$sb.AppendLine('== Integrity ==')
[void]$sb.AppendLine(('Manifest: {0}' -f $manifestRel))
[void]$sb.AppendLine(('ManifestSha256: {0}' -f $manifestHash))
[void]$sb.AppendLine(('PackagesSrcSha256: {0}' -f $srcTreeHash))
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
[void]$sb.AppendLine($cert.SuggestedItOneLiner)

[System.IO.File]::WriteAllText($outTxt, $sb.ToString(), (New-Object System.Text.UTF8Encoding $false))

Write-CertHost ''
Write-CertHost ('Certificate written: {0}' -f $outJson) ([ConsoleColor]::Cyan)
Write-CertHost ('Certificate written: {0}' -f $outTxt) ([ConsoleColor]::Cyan)
Write-CertHost ('SchemaVersion: 1.1  OverallPass: {0}' -f $overall) $(if ($overall) { [ConsoleColor]::Green } else { [ConsoleColor]::Red })

if (-not $overall) {
    # Exit 2 if a required tool was missing (analyzer / gitleaks)
    $missingTool = @($checks | Where-Object {
            -not $_.Passed -and $_.Critical -and (
                $_.Detail -like '*not installed*' -or
                $_.Detail -like '*not found*' -or
                $_.Detail -like '*module not installed*'
            )
        }).Count
    if ($missingTool -gt 0) {
        exit 2
    }
    exit 1
}
exit 0
