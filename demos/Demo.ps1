#requires -Version 5.1
<#
.SYNOPSIS
    PsMenuKit interactive demo (Windows PowerShell 5.1) — Core + all feature modules.
.DESCRIPTION
    Launched by Launch.cmd. Demonstrates Theme, Status, Confirm, Nested, Search,
    MultiSelect, and Config composition.
#>
$ErrorActionPreference = 'Stop'

$demoRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $demoRoot
$pkgRoot = Join-Path -Path $repoRoot -ChildPath 'packages\PsMenuKit'

function Import-PsMenuKitModule {
    param([string]$RelativePath)
    $path = Join-Path -Path $pkgRoot -ChildPath $RelativePath
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Module not found: $path"
    }
    Import-Module -Name $path -Force
}

# Core first, then features (order matches capability dependencies)
Import-PsMenuKitModule 'src\Core\PsMenuKit.Core.psd1'
Import-PsMenuKitModule 'src\Modules\Theme\PsMenuKit.Theme.psd1'
Import-PsMenuKitModule 'src\Modules\Status\PsMenuKit.Status.psd1'
Import-PsMenuKitModule 'src\Modules\Confirm\PsMenuKit.Confirm.psd1'
Import-PsMenuKitModule 'src\Modules\Nested\PsMenuKit.Nested.psd1'
Import-PsMenuKitModule 'src\Modules\Search\PsMenuKit.Search.psd1'
Import-PsMenuKitModule 'src\Modules\MultiSelect\PsMenuKit.MultiSelect.psd1'
Import-PsMenuKitModule 'src\Modules\Config\PsMenuKit.Config.psd1'

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
                Write-Host ('Action   : success — {0}' -f $ar.Label) -ForegroundColor Green
                if ($null -ne $ar.Output) {
                    Write-Host ("Output   : {0}" -f $ar.Output)
                }
            }
            else {
                Write-Host ('Action   : failed — {0}' -f $ar.Label) -ForegroundColor Red
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

# Handler map for Config-loaded sample menu
$handlerMap = @{
    Hello   = { return 'Hello from config-driven HandlerMap.' }
    Time    = { return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss') }
    Version = { return $PSVersionTable.PSVersion.ToString() }
    About   = { return 'PsMenuKit 0.2.0 — modular pure-PS menu framework.' }
    NestedA = { return 'Nested action A' }
    NestedB = { return 'Nested action B' }
    Wipe    = { return 'Simulated wipe complete (demo).' }
}

$configPath = Join-Path -Path $demoRoot -ChildPath 'menus\sample.menu.psd1'
$menu = Import-PsMenuConfig -Path $configPath -HandlerMap $handlerMap

Write-PsMenuBanner -Lines @(
    'PsMenuKit Demo'
    'Core + Theme Status Confirm Nested'
    'Search MultiSelect Config'
) -ThemeName 'Dark'

Write-Host ''
Write-Host 'Starting menu in 1s...' -ForegroundColor DarkGray
Start-Sleep -Seconds 1

$lastResult = $null

try {
    while ($true) {
        $status = New-PsMenuStatusLine -IncludeUser -IncludeTime -LastResult $lastResult -Text 'type to filter'
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
