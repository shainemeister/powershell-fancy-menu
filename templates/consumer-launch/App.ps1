#requires -Version 5.1
<#
.SYNOPSIS
    Minimal consumer host for PsMenuKit (copy/adapt this pattern).
#>
$ErrorActionPreference = 'Stop'

$appRoot = $PSScriptRoot
# Default: this template lives at templates/consumer-launch under the repo.
$repoRoot = Split-Path -Parent (Split-Path -Parent $appRoot)
$pkg = Join-Path $repoRoot 'packages\PsMenuKit\PsMenuKit.psd1'

if (-not (Test-Path -LiteralPath $pkg)) {
    Write-Host "PsMenuKit not found at: $pkg" -ForegroundColor Red
    Write-Host 'Adjust $repoRoot / $pkg to point at your PsMenuKit install.' -ForegroundColor Yellow
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
