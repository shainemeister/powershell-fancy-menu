#requires -Version 5.1
<#
.SYNOPSIS
    PsMenuKit interactive demo (Windows PowerShell 5.1).
.DESCRIPTION
    Imports Core, builds a sample menu, and loops until the user quits.
    Launched by Launch.cmd for double-click use.
#>
$ErrorActionPreference = 'Stop'

$demoRoot = $PSScriptRoot
$repoRoot = Split-Path -Parent $demoRoot
$coreManifest = Join-Path -Path $repoRoot -ChildPath 'packages\PsMenuKit\src\Core\PsMenuKit.Core.psd1'

if (-not (Test-Path -LiteralPath $coreManifest)) {
    Write-Error "Core module not found: $coreManifest"
    exit 1
}

Import-Module -Name $coreManifest -Force

function Show-DemoResult {
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Result
    )

    Write-Host ''
    if ($Result.Cancelled) {
        Write-Host 'Menu closed.' -ForegroundColor DarkGray
        return
    }

    Write-Host ("Selected : {0} (Id={1})" -f $Result.Label, $Result.ItemId) -ForegroundColor Cyan
    if ($null -ne $Result.ActionResult) {
        if ($Result.ActionResult.Success) {
            Write-Host 'Action   : success' -ForegroundColor Green
            if ($null -ne $Result.ActionResult.Output) {
                Write-Host ("Output   : {0}" -f $Result.ActionResult.Output)
            }
        }
        else {
            Write-Host 'Action   : failed' -ForegroundColor Red
            if ($null -ne $Result.ActionResult.Error) {
                Write-Host ("Error    : {0}" -f $Result.ActionResult.Error.Exception.Message) -ForegroundColor Red
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

$menu = New-PsMenu -Title 'PsMenuKit Demo' -Subtitle 'Pure PowerShell 5.1 · zero dependencies' -Items @(
    New-PsMenuItem -Id 'hello' -Label 'Say hello' -Hotkey 'h' -Action {
        return 'Hello from PsMenuKit Core.'
    }
    New-PsMenuItem -Id 'time' -Label 'Show local time' -Hotkey 't' -Action {
        return (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')
    }
    New-PsMenuItem -Id 'env' -Label 'Show PowerShell version' -Hotkey 'v' -Action {
        return $PSVersionTable.PSVersion.ToString()
    }
    New-PsMenuItem -Id 'disabled' -Label 'Coming soon (disabled)' -Enabled $false
    New-PsMenuItem -Id 'about' -Label 'About this kit' -Hotkey 'a' -Action {
        return 'PsMenuKit: modular pure-PS menu framework (Core 0.1.0). Feature modules planned.'
    }
)

try {
    while ($true) {
        $result = Show-PsMenu -Menu $menu -StatusLine ("User: {0} · {1}" -f $env:USERNAME, (Get-Date).ToString('HH:mm:ss'))
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
