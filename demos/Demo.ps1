#requires -Version 5.1
<#
.SYNOPSIS
    PsMenuKit interactive demo (Windows PowerShell 5.1).
.DESCRIPTION
    Launched by Launch.cmd (enterprise-standard). Demonstrates Theme, Status,
    Confirm, Nested, Search, MultiSelect, and Config composition.
.PARAMETER MultiSelect
    Load the multi-select sample menu instead of the default sample.
#>
[CmdletBinding()]
param(
    [switch]$MultiSelect
)

$ErrorActionPreference = 'Stop'

$demoRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $demoRoot
$pkgManifest = Join-Path -Path $repoRoot -ChildPath 'packages\PsMenuKit\PsMenuKit.psd1'

if (-not (Test-Path -LiteralPath $pkgManifest)) {
    Write-Error "PsMenuKit package not found: $pkgManifest"
    exit 1
}

# Single root import (nested modules load Core + features)
Import-Module -Name $pkgManifest -Force

Set-PsMenuTheme -Name 'Dark' | Out-Null

function Show-DemoResult {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Result
    )

    Write-Host ''
    if ($Result.Cancelled) {
        Write-Host 'Returned / cancelled.' -ForegroundColor DarkGray
        return
    }

    Write-Host ("Selected : {0}" -f $Result.Label) -ForegroundColor Cyan
    Write-Host ("Id       : {0}" -f $Result.ItemId) -ForegroundColor DarkCyan
    Write-Host ("Reason   : {0}" -f $Result.Reason) -ForegroundColor DarkGray

    if ($null -ne $Result.PSObject.Properties['Selections'] -and @($Result.Selections).Count -gt 1) {
        Write-Host ('Count    : {0}' -f @($Result.Selections).Count)
    }

    if ($null -ne $Result.ActionResult) {
        $actions = @($Result.ActionResult)
        foreach ($ar in $actions) {
            if ($null -eq $ar) { continue }
            if ($ar.Success) {
                Write-Host ('Action   : success - {0}' -f $ar.Label) -ForegroundColor Green
                if ($null -ne $ar.Output) {
                    Write-Host ("Output   : {0}" -f $ar.Output)
                }
            }
            else {
                Write-Host ('Action   : failed - {0}' -f $ar.Label) -ForegroundColor Red
                if ($null -ne $ar.Error) {
                    Write-Host ("Error    : {0}" -f $ar.Error.Exception.Message) -ForegroundColor Red
                }
            }
        }
    }

    Write-Host ''
    Write-Host 'Press any key to return to the menu...' -ForegroundColor DarkGray
    try {
        [void][Console]::ReadKey($true)
    }
    catch {
        $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    }
}

$handlerMap = @{
    Hello   = { return 'Hello from config-driven HandlerMap.' }
    Time    = { return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
    Version = { return $PSVersionTable.PSVersion.ToString() }
    About   = { return 'PsMenuKit 0.5.0 - modular pure-PS menu framework.' }
    NestedA = { return 'Nested action A' }
    NestedB = { return 'Nested action B' }
    Wipe    = { return 'Simulated wipe complete (demo).' }
    PickA   = { return 'Picked A' }
    PickB   = { return 'Picked B' }
    PickC   = { return 'Picked C' }
}

$menuRoot = Join-Path -Path $demoRoot -ChildPath 'menus'
if ($MultiSelect) {
    $configPath = Join-Path -Path $menuRoot -ChildPath 'sample-multi.menu.psd1'
    $bannerLines = @(
        'PsMenuKit Demo (MultiSelect)'
        'Space=toggle  Enter=batch'
    )
    $hint = 'Space toggles; Enter runs selected'
}
else {
    $configPath = Join-Path -Path $menuRoot -ChildPath 'sample.menu.psd1'
    $bannerLines = @(
        'PsMenuKit Demo'
        'Core + Theme Status Confirm Nested'
        'Search MultiSelect Config'
    )
    $hint = 'type to filter'
}

$menu = Import-PsMenuConfig -Path $configPath -HandlerMap $handlerMap -AllowedRoot $menuRoot

Write-PsMenuBanner -Lines $bannerLines -ThemeName 'Dark'
Write-Host ''
Write-Host 'Tip: re-run with -MultiSelect for batch selection demo.' -ForegroundColor DarkGray
Write-Host 'Starting menu...' -ForegroundColor DarkGray

$lastResult = $null

try {
    while ($true) {
        $status = New-PsMenuStatusLine -IncludeUser -IncludeTime -LastResult $lastResult -Text $hint
        $result = Show-PsMenu -Menu $menu -Theme 'Dark' -StatusLine $status
        $lastResult = $result
        if ($result.Cancelled) {
            break
        }
        Show-DemoResult -Result $result
    }
}
catch {
    Write-Host ''
    Write-Host ("Demo error: {0}" -f $_.Exception.Message) -ForegroundColor Red
    exit 1
}

exit 0
