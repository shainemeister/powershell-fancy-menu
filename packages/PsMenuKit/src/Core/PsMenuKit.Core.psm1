# PsMenuKit.Core — dependency-free menu engine for Windows PowerShell 5.1
# Dot-sources Public and Private functions; exports public surface only.

$script:PsMenuKitCoreRoot = $PSScriptRoot

$privateDir = Join-Path -Path $PSScriptRoot -ChildPath 'Private'
$publicDir = Join-Path -Path $PSScriptRoot -ChildPath 'Public'

if (Test-Path -LiteralPath $privateDir) {
    Get-ChildItem -LiteralPath $privateDir -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}

if (Test-Path -LiteralPath $publicDir) {
    Get-ChildItem -LiteralPath $publicDir -Filter '*.ps1' -File | Sort-Object Name | ForEach-Object {
        . $_.FullName
    }
}

Export-ModuleMember -Function @(
    'New-PsMenu'
    'New-PsMenuItem'
    'Show-PsMenu'
    'Get-PsMenuDisplayText'
)
