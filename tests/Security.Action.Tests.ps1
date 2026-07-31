#requires -Version 5.1
<#
.SYNOPSIS
    Security tests: Action type fail-closed, display sanitization, HandlerMap types, config limits.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pkg = Join-Path $repoRoot 'packages\PsMenuKit'
$fixtures = Join-Path $PSScriptRoot 'fixtures'

Import-Module (Join-Path $pkg 'src\Core\PsMenuKit.Core.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Config\PsMenuKit.Config.psd1') -Force

function Assert-Throws {
    param(
        [scriptblock]$Script,
        [string]$Like
    )
    $threw = $false
    try {
        & $Script | Out-Null
    }
    catch {
        $threw = $true
        if ($Like -and $_.Exception.Message -notlike $Like) {
            throw ("Expected error like '{0}' but got: {1}" -f $Like, $_.Exception.Message)
        }
    }
    if (-not $threw) {
        throw 'Expected script to throw.'
    }
}

# --- A1: mutated string Action must not invoke a command ---
$item = New-PsMenuItem -Id 't1' -Label 'Trap' -Action { 'ok' }
$item.Action = 'Get-Date'
# Invoke via Complete path: build menu result helper is private; call through selection path
# Export only public surface - use reflection-free approach: New-PsMenuItem then call Show path
# Core private Invoke-PsMenuItemAction is in module scope. Test via selecting after force-set:
# Import-Module loads functions; private not exported. Use & (Get-Command) won't work.
# Dot-source private for unit test of fail-closed behavior:
$privateAction = Join-Path $pkg 'src\Core\Private\Invoke-PsMenuItemAction.ps1'
. $privateAction

$ar = Invoke-PsMenuItemAction -Item $item
if ($ar.Success) { throw 'String Action must fail closed (Success should be false)' }
if ($null -eq $ar.Error) { throw 'String Action must set Error' }
$errText = [string]$ar.Error
if ($errText -notlike '*scriptblock*') {
    throw ("Expected scriptblock error message, got: {0}" -f $errText)
}

# Valid scriptblock still works
$item2 = New-PsMenuItem -Id 't2' -Label 'Good' -Action { return 42 }
$ar2 = Invoke-PsMenuItemAction -Item $item2
if (-not $ar2.Success) { throw 'Valid scriptblock Action should succeed' }
if ($ar2.Output -ne 42) { throw 'Valid Action output mismatch' }

# Null Action is success / no-op
$item3 = New-PsMenuItem -Id 't3' -Label 'NoAction'
$ar3 = Invoke-PsMenuItemAction -Item $item3
if (-not $ar3.Success) { throw 'Null Action should succeed as no-op' }

# --- A4: display sanitization strips ESC / controls ---
$esc = [char]27
$bell = [char]7
$evil = "Hello${esc}[31mRed${esc}[0m`nWorld"
$clean = Get-PsMenuDisplayText -Text $evil -MaxWidth 80
if ($clean.Contains([string]$esc)) { throw 'ANSI ESC must be stripped from display text' }
if ($clean.Contains("`n")) { throw 'Newlines must be flattened in display text' }
if ($clean -notlike '*Hello*') { throw 'Sanitized text should retain printable content' }

$withOsc = "Title${esc}]0;Hacked${bell}Normal"
$cleanOsc = Get-PsMenuDisplayText -Text $withOsc -MaxWidth 80
if ($cleanOsc.Contains([string]$esc)) { throw 'OSC escape must be stripped' }
if ($cleanOsc.Contains([string]$bell)) { throw 'BEL control must be stripped' }

# --- A2: HandlerMap non-scriptblock rejected ---
if (-not (Test-Path -LiteralPath $fixtures)) {
    New-Item -ItemType Directory -Path $fixtures -Force | Out-Null
}
$okMenu = Join-Path $fixtures 'handler-type.menu.psd1'
@'
@{
    Title = 'HandlerType'
    Items = @(
        @{ Id = 'x'; Label = 'X'; Handler = 'Bad' }
    )
}
'@ | Set-Content -LiteralPath $okMenu -Encoding UTF8

Assert-Throws -Like '*scriptblock*' -Script {
    Import-PsMenuConfig -Path $okMenu -HandlerMap @{ Bad = 'Get-Date' } -AllowedRoot $fixtures
}

# Valid HandlerMap still loads
$good = Import-PsMenuConfig -Path $okMenu -HandlerMap @{ Bad = { 'ok' } } -AllowedRoot $fixtures
if ($null -eq $good.Items[0].Action) { throw 'Valid HandlerMap should bind Action' }
if (-not ($good.Items[0].Action -is [scriptblock])) { throw 'Bound Action must be scriptblock' }

# --- A5: MaxItems / MaxDepth / MaxLabelLength ---
$manyPath = Join-Path $fixtures 'max-items.menu.psd1'
$lines = New-Object System.Collections.Generic.List[string]
$lines.Add('@{')
$lines.Add("    Title = 'Many'")
$lines.Add('    Items = @(')
for ($i = 1; $i -le 5; $i++) {
    $comma = if ($i -lt 5) { ',' } else { '' }
    $lines.Add(("        @{{ Label = 'Item{0}' }}{1}" -f $i, $comma))
}
$lines.Add('    )')
$lines.Add('}')
$lines -join "`r`n" | Set-Content -LiteralPath $manyPath -Encoding UTF8

Assert-Throws -Like '*MaxItems*' -Script {
    Import-PsMenuConfig -Path $manyPath -AllowedRoot $fixtures -MaxItems 3
}

# MaxDepth: nest deeper than limit
$deepPath = Join-Path $fixtures 'max-depth.menu.psd1'
@'
@{
    Title = 'Deep'
    Items = @(
        @{
            Label = 'L1'
            Children = @(
                @{
                    Label = 'L2'
                    Children = @(
                        @{ Label = 'L3' }
                    )
                }
            )
        }
    )
}
'@ | Set-Content -LiteralPath $deepPath -Encoding UTF8

Assert-Throws -Like '*MaxDepth*' -Script {
    Import-PsMenuConfig -Path $deepPath -AllowedRoot $fixtures -MaxDepth 2
}

# MaxLabelLength
$longLabelPath = Join-Path $fixtures 'max-label.menu.psd1'
$longLabel = 'X' * 50
@"
@{
    Title = 'Long'
    Items = @(
        @{ Label = '$longLabel' }
    )
}
"@ | Set-Content -LiteralPath $longLabelPath -Encoding UTF8

Assert-Throws -Like '*MaxLabelLength*' -Script {
    Import-PsMenuConfig -Path $longLabelPath -AllowedRoot $fixtures -MaxLabelLength 10
}

# --- A3: reparse point under AllowedRoot (skip if cannot create junction) ---
$junctionTestRoot = Join-Path $fixtures 'reparse-test'
$outsideDir = Join-Path $fixtures 'outside-root'
$junctionPath = Join-Path $junctionTestRoot 'evil-link'
$outsideMenu = Join-Path $outsideDir 'other.menu.psd1'

if (-not (Test-Path -LiteralPath $outsideDir)) {
    New-Item -ItemType Directory -Path $outsideDir -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $outsideMenu)) {
    @'
@{
    Title = 'Outside'
    Items = @(@{ Label = 'X'; Handler = 'Hello' })
}
'@ | Set-Content -LiteralPath $outsideMenu -Encoding UTF8
}

$canJunction = $false
try {
    if (Test-Path -LiteralPath $junctionTestRoot) {
        Remove-Item -LiteralPath $junctionTestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
    New-Item -ItemType Directory -Path $junctionTestRoot -Force | Out-Null

    # cmd mklink /J does not require admin for directory junctions on modern Windows
    $null = cmd /c mklink /J "$junctionPath" "$outsideDir" 2>&1
    if (Test-Path -LiteralPath $junctionPath) {
        $canJunction = $true
    }
}
catch {
    $canJunction = $false
}

if ($canJunction) {
    $viaJunction = Join-Path $junctionPath 'other.menu.psd1'
    $threwReparse = $false
    try {
        Import-PsMenuConfig -Path $viaJunction -HandlerMap @{ Hello = { 'h' } } -AllowedRoot $junctionTestRoot | Out-Null
    }
    catch {
        $threwReparse = $true
        if ($_.Exception.Message -notlike '*reparse*' -and $_.Exception.Message -notlike '*outside AllowedRoot*') {
            throw ("Expected reparse or outside-root error, got: {0}" -f $_.Exception.Message)
        }
    }
    if (-not $threwReparse) {
        throw 'Path via junction under AllowedRoot should be rejected'
    }
    Write-Host 'Reparse/junction rejection OK' -ForegroundColor Green
}
else {
    Write-Host 'SKIP: could not create directory junction for reparse test' -ForegroundColor Yellow
}

# Cleanup junction test tree
try {
    if (Test-Path -LiteralPath $junctionPath) {
        cmd /c rmdir "$junctionPath" >$null 2>&1
    }
    if (Test-Path -LiteralPath $junctionTestRoot) {
        Remove-Item -LiteralPath $junctionTestRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}
catch { }

Write-Host 'Security.Action.Tests OK' -ForegroundColor Green
exit 0
