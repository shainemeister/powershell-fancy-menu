#requires -Version 5.1
<#
.SYNOPSIS
    Fail if product / template PowerShell code contains banned security-sensitive patterns.
.DESCRIPTION
    Domain A companion: static content scan (not a full SAST). Scopes to packages/
    and templates/ so documentation examples that mention banned APIs do not fail the gate.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$scanRoots = @(
    (Join-Path $repoRoot 'packages')
    (Join-Path $repoRoot 'templates')
)

# Patterns that must not appear in product module/script source
$banned = @(
    @{ Name = 'Invoke-Expression';    Regex = '(?i)\bInvoke-Expression\b' }
    @{ Name = 'IEX alias';             Regex = '(?i)(?<![A-Za-z])IEX\s*[\(\|]' }
    @{ Name = 'DownloadString';        Regex = '(?i)\bDownloadString\b' }
    @{ Name = 'DownloadFile';          Regex = '(?i)\bDownloadFile\b' }
    @{ Name = 'DownloadData';          Regex = '(?i)\bDownloadData\b' }
    @{ Name = 'Invoke-WebRequest';     Regex = '(?i)\bInvoke-WebRequest\b' }
    @{ Name = 'Invoke-RestMethod';     Regex = '(?i)\bInvoke-RestMethod\b' }
    @{ Name = 'Net.WebClient';         Regex = '(?i)System\.Net\.WebClient' }
    @{ Name = 'Net.Http.HttpClient';   Regex = '(?i)System\.Net\.Http\.HttpClient' }
    @{ Name = 'Start-Process RunAs';   Regex = '(?i)Start-Process[\s\S]{0,80}-Verb\s+RunAs' }
    @{ Name = 'Set-ExecutionPolicy';   Regex = '(?i)\bSet-ExecutionPolicy\b' }
    @{ Name = 'FromBase64String exec';  Regex = '(?i)FromBase64String' }
    @{ Name = 'Install-Module product'; Regex = '(?i)\bInstall-Module\b' }
    @{ Name = 'scriptblock.Create';    Regex = '(?i)\[scriptblock\]::Create' }
    @{ Name = 'Add-Type';               Regex = '(?i)\bAdd-Type\b' }
    @{ Name = 'System.Reflection';     Regex = '(?i)System\.Reflection' }
    @{ Name = 'Invoke-Command';        Regex = '(?i)\bInvoke-Command\b' }
    @{ Name = 'Start-Job';             Regex = '(?i)\bStart-Job\b' }
    @{ Name = 'Start-ThreadJob';       Regex = '(?i)\bStart-ThreadJob\b' }
    @{ Name = 'New-Object ComObject';  Regex = '(?i)New-Object\s+(-ComObject|System\.ComObject)' }
    @{ Name = 'EncodedCommand';        Regex = '(?i)-EncodedCommand\b' }
)

$failed = $false
$hitCount = 0
$fileCount = 0

foreach ($scanRoot in $scanRoots) {
    if (-not (Test-Path -LiteralPath $scanRoot)) {
        Write-Host ("SKIP scan root (missing): {0}" -f $scanRoot) -ForegroundColor Yellow
        continue
    }

    Get-ChildItem -Path $scanRoot -Recurse -File -Include *.ps1, *.psm1, *.psd1 |
        ForEach-Object {
            $fileCount++
            $content = Get-Content -LiteralPath $_.FullName -Raw -ErrorAction Stop
            if ($null -eq $content) { return }

            # Strip block and line comments to reduce doc false positives inside scripts
            $stripped = [regex]::Replace($content, '(?s)<#.*?#>', ' ')
            $stripped = [regex]::Replace($stripped, '(?m)^\s*#.*$', ' ')

            foreach ($rule in $banned) {
                if ([regex]::IsMatch($stripped, $rule.Regex)) {
                    $failed = $true
                    $hitCount++
                    Write-Host ("BAN HIT: {0} in {1}" -f $rule.Name, $_.FullName) -ForegroundColor Red
                }
            }
        }
}

if ($fileCount -eq 0) {
    Write-Host 'No package/template PowerShell files to scan.' -ForegroundColor Yellow
    exit 1
}

if ($failed) {
    Write-Host ("Security ban-list FAILED ({0} hit(s) in {1} file(s))." -f $hitCount, $fileCount) -ForegroundColor Red
    exit 1
}

Write-Host ("Security ban-list OK ({0} file(s) scanned)." -f $fileCount) -ForegroundColor Green
exit 0
