#requires -Version 5.1
<#
.SYNOPSIS
    Non-interactive smoke tests for Core model builders.
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$coreManifest = Join-Path $repoRoot 'packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1'
Import-Module $coreManifest -Force

$item = New-PsMenuItem -Label 'Test' -Id 't1' -Hotkey 't' -Action { 'ok' }
if ($item.Label -ne 'Test') { throw 'Label mismatch' }
if ($item.Id -ne 't1') { throw 'Id mismatch' }
if ($item.Hotkey -ne 't') { throw 'Hotkey mismatch' }

$menu = New-PsMenu -Title 'T' -Items @($item) -Subtitle 'S'
if ($menu.Title -ne 'T') { throw 'Title mismatch' }
if ($menu.Items.Count -ne 1) { throw 'Items count mismatch' }

# Auto-id
$auto = New-PsMenuItem -Label 'Auto'
if ([string]::IsNullOrWhiteSpace($auto.Id)) { throw 'Auto Id missing' }

Write-Host 'Core.Model.Tests OK' -ForegroundColor Green
exit 0
