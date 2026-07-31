#requires -Version 5.1
<#
.SYNOPSIS
    Negative and positive security tests for Import-PsMenuConfig path controls.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pkg = Join-Path $repoRoot 'packages\PsMenuKit'
$demoMenus = Join-Path $repoRoot 'demos\menus'
$sample = Join-Path $demoMenus 'sample.menu.psd1'
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
        throw "Expected script to throw."
    }
}

# Positive: sample under AllowedRoot
$handlers = @{ Hello = { 'ok' }; Time = { 't' }; Version = { 'v' }; About = { 'a' }; NestedA = { 'na' }; NestedB = { 'nb' }; Wipe = { 'w' } }
$menu = Import-PsMenuConfig -Path $sample -HandlerMap $handlers -AllowedRoot $demoMenus
if ($menu.Title -ne 'PsMenuKit Demo') { throw 'AllowedRoot positive load failed' }

# Reject http URL
Assert-Throws -Like '*not allowed*' -Script {
    Import-PsMenuConfig -Path 'https://example.com/menu.psd1' -HandlerMap $handlers
}

# Reject ftp
Assert-Throws -Like '*not allowed*' -Script {
    Import-PsMenuConfig -Path 'ftp://example.com/menu.psd1' -HandlerMap $handlers
}

# Reject missing file
Assert-Throws -Like '*not found*' -Script {
    Import-PsMenuConfig -Path (Join-Path $demoMenus 'no-such-menu.psd1') -HandlerMap $handlers -AllowedRoot $demoMenus
}

# Reject path outside AllowedRoot (valid menu file under tests\fixtures, root locked to demos\menus)
$outsideDir = Join-Path $fixtures 'outside-root'
if (-not (Test-Path -LiteralPath $outsideDir)) {
    New-Item -ItemType Directory -Path $outsideDir -Force | Out-Null
}
$outsidePsd1 = Join-Path $outsideDir 'other.menu.psd1'
@'
@{
    Title = 'Outside'
    Items = @(@{ Label = 'X'; Handler = 'Hello' })
}
'@ | Set-Content -LiteralPath $outsidePsd1 -Encoding UTF8
Assert-Throws -Like '*outside AllowedRoot*' -Script {
    Import-PsMenuConfig -Path $outsidePsd1 -HandlerMap $handlers -AllowedRoot $demoMenus
}

# Reject bad extension
$badExt = Join-Path $fixtures 'not-a-menu.txt'
if (-not (Test-Path -LiteralPath $fixtures)) {
    New-Item -ItemType Directory -Path $fixtures -Force | Out-Null
}
Set-Content -LiteralPath $badExt -Value 'not a menu' -Encoding UTF8
Assert-Throws -Like '*Unsupported menu config extension*' -Script {
    Import-PsMenuConfig -Path $badExt -HandlerMap $handlers -AllowedRoot $fixtures
}

# Reject banned schema key (code-from-file)
$bannedFile = Join-Path $fixtures 'banned-key.menu.psd1'
@'
@{
    Title = 'Bad'
    Items = @(
        @{
            Label = 'X'
            ActionScript = 'Write-Host evil'
        }
    )
}
'@ | Set-Content -LiteralPath $bannedFile -Encoding UTF8

Assert-Throws -Like '*banned key*' -Script {
    Import-PsMenuConfig -Path $bannedFile -HandlerMap $handlers -AllowedRoot $fixtures
}

# Handler miss: item loads but Action is null (no DefaultAction)
$noHandlerMenu = Join-Path $fixtures 'no-handler.menu.psd1'
@'
@{
    Title = 'NoHandler'
    Items = @(
        @{
            Id = 'x'
            Label = 'X'
            Handler = 'Missing'
        }
    )
}
'@ | Set-Content -LiteralPath $noHandlerMenu -Encoding UTF8

$m2 = Import-PsMenuConfig -Path $noHandlerMenu -HandlerMap @{} -AllowedRoot $fixtures
if ($null -eq $m2.Items -or $m2.Items.Count -ne 1) { throw 'no-handler menu item count' }
if ($null -ne $m2.Items[0].Action) { throw 'Missing handler should not bind Action' }

# Reject UNC by default
Assert-Throws -Like '*UNC*' -Script {
    Import-PsMenuConfig -Path '\\server\share\menu.psd1' -HandlerMap $handlers
}

# JSON config load
$jsonPath = Join-Path $fixtures 'sample.menu.json'
$jsonHandlers = @{ Hello = { 'h' }; About = { 'a' } }
$jsonMenu = Import-PsMenuConfig -Path $jsonPath -HandlerMap $jsonHandlers -AllowedRoot $fixtures
if ($jsonMenu.Title -ne 'JSON Sample Menu') { throw 'JSON config title mismatch' }
if ($jsonMenu.Items.Count -lt 2) { throw 'JSON config items missing' }
if ($null -eq $jsonMenu.Items[0].Action) { throw 'JSON HandlerMap action not bound' }

# MaxFileBytes: reject oversize before parse
$oversizePath = Join-Path $fixtures 'oversize.menu.psd1'
$pad = 'X' * 2048
@"
@{
    Title = 'Oversize'
    Items = @(
        @{ Label = 'L'; Handler = 'Hello' }
    )
    # pad: $pad
}
"@ | Set-Content -LiteralPath $oversizePath -Encoding UTF8
# Ensure file is larger than a tiny MaxFileBytes budget
Assert-Throws -Like '*MaxFileBytes*' -Script {
    Import-PsMenuConfig -Path $oversizePath -HandlerMap $handlers -AllowedRoot $fixtures -MaxFileBytes 1024
}

# Banned Action key (code-from-file)
$actionKeyFile = Join-Path $fixtures 'banned-action.menu.psd1'
@'
@{
    Title = 'BadAction'
    Items = @(
        @{
            Label  = 'X'
            Action = 'Get-Date'
        }
    )
}
'@ | Set-Content -LiteralPath $actionKeyFile -Encoding UTF8
Assert-Throws -Like '*banned key*' -Script {
    Import-PsMenuConfig -Path $actionKeyFile -HandlerMap $handlers -AllowedRoot $fixtures
}

# Unknown item key rejected (allowlist)
$unknownKeyFile = Join-Path $fixtures 'unknown-item-key.menu.psd1'
@'
@{
    Title = 'UnknownKey'
    Items = @(
        @{
            Label = 'X'
            FooBar = 'nope'
        }
    )
}
'@ | Set-Content -LiteralPath $unknownKeyFile -Encoding UTF8
Assert-Throws -Like '*unknown key*' -Script {
    Import-PsMenuConfig -Path $unknownKeyFile -HandlerMap $handlers -AllowedRoot $fixtures
}

# Missing AllowedRoot emits warning (compat) but still loads when path is valid
$warnMessages = @()
$prevWarn = $WarningPreference
$WarningPreference = 'Continue'
try {
    $null = Import-PsMenuConfig -Path $sample -HandlerMap $handlers -WarningVariable warnMessages -WarningAction SilentlyContinue
}
finally {
    $WarningPreference = $prevWarn
}
$warnText = ($warnMessages | ForEach-Object { [string]$_ }) -join ' '
if ($warnText -notlike '*AllowedRoot*') {
    throw 'Expected Write-Warning about missing AllowedRoot when parameter omitted'
}

Write-Host 'Security.Config.Tests OK' -ForegroundColor Green
exit 0
