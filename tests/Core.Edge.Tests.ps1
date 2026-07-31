#requires -Version 5.1
<#
.SYNOPSIS
    Non-interactive edge-case tests for Core hardening (Phase 3).
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$core = Join-Path $repoRoot 'packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1'
$nested = Join-Path $repoRoot 'packages\PsMenuKit\src\Modules\Nested\PsMenuKit.Nested.psd1'
Import-Module $core -Force
Import-Module $nested -Force

# Truncation
$short = Get-PsMenuDisplayText -Text 'abc' -MaxWidth 10
if ($short -ne 'abc') { throw 'short text should be unchanged' }

$long = Get-PsMenuDisplayText -Text ('x' * 50) -MaxWidth 10
if ($long.Length -ne 10) { throw "expected length 10, got $($long.Length)" }
if (-not $long.EndsWith('...')) { throw 'expected ellipsis truncation' }

$nullText = Get-PsMenuDisplayText -Text $null -MaxWidth 10
if ($nullText -ne '') { throw 'null text should be empty string' }

# Empty menu (no interactive loop)
$empty = New-PsMenu -Title 'E' -Items @()
$rEmpty = Show-PsMenu -Menu $empty -ClearOnExit $false
if (-not $rEmpty.Cancelled) { throw 'empty menu should cancel' }
if ($rEmpty.Reason -ne 'EmptyMenu') { throw "expected EmptyMenu, got $($rEmpty.Reason)" }
if ($null -eq $rEmpty.PSObject.Properties['Selections']) { throw 'Selections property required' }

# Nested depth exceeded path (no console)
$child = New-PsMenuItem -Id 'c' -Label 'Child' -Action { 'c' }
$parentItem = New-PsMenuItem -Id 'p' -Label 'Parent' -Children @($child)
$parentMenu = New-PsMenu -Title 'Root' -Items @($parentItem)
$depthResult = Show-PsMenuNested -ParentMenu $parentMenu -Item $parentItem -NestDepth 9 -MaxNestDepth 8
if (-not $depthResult.Cancelled) { throw 'depth exceeded should cancel' }
if ($depthResult.Reason -ne 'NestedDepthExceeded') { throw "expected NestedDepthExceeded, got $($depthResult.Reason)" }

# EAP leak check
$ErrorActionPreference = 'Continue'
$null = Show-PsMenu -Menu $empty -ClearOnExit $false
if ($ErrorActionPreference -ne 'Continue') { throw "EAP leaked: $ErrorActionPreference" }

# All-disabled model builds
$disabled = New-PsMenu -Title 'D' -Items @(
    (New-PsMenuItem -Label 'A' -Enabled $false)
    (New-PsMenuItem -Label 'B' -Enabled $false)
)
if ($disabled.Items.Count -ne 2) { throw 'disabled menu build failed' }

Write-Host 'Core.Edge.Tests OK' -ForegroundColor Green
exit 0
