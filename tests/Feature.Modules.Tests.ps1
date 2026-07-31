#requires -Version 5.1
<#
.SYNOPSIS
    Non-interactive smoke tests for Phase 2 feature modules.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$pkg = Join-Path $repoRoot 'packages\PsMenuKit'

Import-Module (Join-Path $pkg 'src\Core\PsMenuKit.Core.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Theme\PsMenuKit.Theme.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Status\PsMenuKit.Status.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Confirm\PsMenuKit.Confirm.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Nested\PsMenuKit.Nested.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Search\PsMenuKit.Search.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\MultiSelect\PsMenuKit.MultiSelect.psd1') -Force
Import-Module (Join-Path $pkg 'src\Modules\Config\PsMenuKit.Config.psd1') -Force

# Theme
$names = @(Get-PsMenuThemeName)
if ($names -notcontains 'Dark') { throw 'Dark theme missing' }
Set-PsMenuTheme -Name 'Dark' | Out-Null
$theme = Get-PsMenuTheme
if ($theme.Name -ne 'Dark') { throw 'Set-PsMenuTheme failed' }

# Status
$line = New-PsMenuStatusLine -IncludeUser -IncludeTime -Text 'ok'
if ([string]::IsNullOrWhiteSpace($line)) { throw 'Status line empty' }
if ($line -notmatch 'User:') { throw 'Status missing user' }

# Search
$items = @(
    (New-PsMenuItem -Id 'a' -Label 'Alpha')
    (New-PsMenuItem -Id 'b' -Label 'Beta')
    (New-PsMenuItem -Id 'c' -Label 'Gamma')
)
$filtered = @(Select-PsMenuItem -Items $items -Query 'be')
if ($filtered.Count -ne 1 -or $filtered[0].Id -ne 'b') { throw 'Select-PsMenuItem failed' }

# MultiSelect
$item = New-PsMenuItem -Id 'm' -Label 'Multi'
Set-PsMenuItemSelection -Item $item -Toggle | Out-Null
if (-not $item.Selected) { throw 'Set-PsMenuItemSelection -Toggle failed' }
$sel = @(Get-PsMenuSelectedItems -Items @($item))
if ($sel.Count -ne 1) { throw 'Get-PsMenuSelectedItems failed' }
Clear-PsMenuItemSelections -Items @($item)
if ($item.Selected) { throw 'Clear selections failed' }

# Config
$cfg = Join-Path $repoRoot 'demos\menus\sample.menu.psd1'
$handlers = @{
    Hello   = { 'h' }
    Time    = { 't' }
    Version = { 'v' }
    About   = { 'a' }
    NestedA = { 'na' }
    NestedB = { 'nb' }
    Wipe    = { 'w' }
}
$menu = Import-PsMenuConfig -Path $cfg -HandlerMap $handlers
if ($menu.Title -ne 'PsMenuKit Demo') { throw 'Config title mismatch' }
if ($menu.Items.Count -lt 5) { throw 'Config items missing' }
$tools = $menu.Items | Where-Object { $_.Id -eq 'tools' }
if ($null -eq $tools -or @($tools.Children).Count -lt 2) { throw 'Config nested children missing' }
$wipe = $menu.Items | Where-Object { $_.Id -eq 'wipe' }
if ([string]::IsNullOrWhiteSpace($wipe.ConfirmMessage)) { throw 'ConfirmMessage not loaded' }
if ($null -eq $wipe.Action) { throw 'HandlerMap action not bound' }

# Nested export present
if ($null -eq (Get-Command Show-PsMenuNested -ErrorAction SilentlyContinue)) {
    throw 'Show-PsMenuNested not exported'
}
if ($null -eq (Get-Command Read-PsMenuConfirm -ErrorAction SilentlyContinue)) {
    throw 'Read-PsMenuConfirm not exported'
}

Write-Host 'Feature.Modules.Tests OK' -ForegroundColor Green
exit 0
