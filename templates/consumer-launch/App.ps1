#requires -Version 5.1
<#
.SYNOPSIS
    Minimal consumer host for PsMenuKit (copy/adapt this pattern).
.DESCRIPTION
    Resolves PsMenuKit from (in order):
      1. $env:PSMENUKIT_HOME\PsMenuKit.psd1  (or the .psd1 path itself)
      2. $appRoot\vendor\PsMenuKit\PsMenuKit.psd1
      3. $appRoot\..\vendor\PsMenuKit\PsMenuKit.psd1
      4. $appRoot\..\..\vendor\PsMenuKit\PsMenuKit.psd1  (e.g. YourApp\tools\MyMenu)
      5. Monorepo: $appRoot\..\..\packages\PsMenuKit\PsMenuKit.psd1
#>
$ErrorActionPreference = 'Stop'

$appRoot = $PSScriptRoot

function Resolve-PsMenuKitManifest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppRoot
    )

    $candidates = New-Object System.Collections.Generic.List[string]

    if (-not [string]::IsNullOrWhiteSpace($env:PSMENUKIT_HOME)) {
        $homePath = $env:PSMENUKIT_HOME.Trim().TrimEnd('\', '/')
        if ($homePath -like '*.psd1') {
            [void]$candidates.Add($homePath)
        }
        else {
            [void]$candidates.Add((Join-Path $homePath 'PsMenuKit.psd1'))
            [void]$candidates.Add((Join-Path $homePath 'PsMenuKit\PsMenuKit.psd1'))
        }
    }

    [void]$candidates.Add((Join-Path $AppRoot 'vendor\PsMenuKit\PsMenuKit.psd1'))
    [void]$candidates.Add((Join-Path $AppRoot '..\vendor\PsMenuKit\PsMenuKit.psd1'))
    [void]$candidates.Add((Join-Path $AppRoot '..\..\vendor\PsMenuKit\PsMenuKit.psd1'))
    [void]$candidates.Add((Join-Path $AppRoot '..\..\packages\PsMenuKit\PsMenuKit.psd1'))

    foreach ($path in $candidates) {
        try {
            $resolved = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($path)
        }
        catch {
            continue
        }
        if (Test-Path -LiteralPath $resolved) {
            return $resolved
        }
    }

    return $null
}

$pkg = Resolve-PsMenuKitManifest -AppRoot $appRoot

if (-not $pkg) {
    Write-Host 'PsMenuKit not found.' -ForegroundColor Red
    Write-Host 'Tried (in order):' -ForegroundColor Yellow
    Write-Host '  1. $env:PSMENUKIT_HOME (folder or .psd1 path)'
    Write-Host '  2. .\vendor\PsMenuKit\PsMenuKit.psd1  (next to this script)'
    Write-Host '  3. ..\vendor\PsMenuKit\PsMenuKit.psd1  (sibling of app folder)'
    Write-Host '  4. ..\..\vendor\PsMenuKit\PsMenuKit.psd1  (e.g. YourApp\tools\MyMenu)'
    Write-Host '  5. ..\..\packages\PsMenuKit\PsMenuKit.psd1  (this monorepo layout)'
    Write-Host 'Vendor packages\PsMenuKit or set PSMENUKIT_HOME. See templates\consumer-launch\README.md' -ForegroundColor Yellow
    exit 1
}

Import-Module $pkg -Force

$handlers = @{
    Hello = { 'Hello from consumer HandlerMap.' }
    Quit  = { 'quit' }
}

$menus = Join-Path $appRoot 'menus'
$menuFile = Join-Path $menus 'app.menu.psd1'
$menu = Import-PsMenuConfig -Path $menuFile -HandlerMap $handlers -AllowedRoot $menus

while ($true) {
    $result = Show-PsMenu -Menu $menu
    if ($result.Cancelled) { break }
    if ($result.ItemId -eq 'quit' -or $result.Label -eq 'Quit') { break }
    Write-Host ''
    Write-Host ("Selected: {0}" -f $result.Label) -ForegroundColor Cyan
    if ($null -ne $result.ActionResult -and $null -ne $result.ActionResult.Output) {
        Write-Host ("Output  : {0}" -f $result.ActionResult.Output)
    }
    Write-Host 'Press any key...' -ForegroundColor DarkGray
    try { [void][Console]::ReadKey($true) } catch { $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown') }
}

exit 0
