@{
    ModuleVersion     = '0.2.1'
    GUID              = 'b4d9f2a1-6c7e-4f0b-8d2e-9a1c3e5f7b20'
    Author            = 'powershell-fancy-menu contributors'
    CompanyName       = 'powershell-fancy-menu'
    Copyright         = 'Copyright (c) 2026 powershell-fancy-menu contributors'
    Description       = 'PsMenuKit: modular pure-PowerShell 5.1 console menu kit (Core + optional feature modules).'
    PowerShellVersion = '5.1'
    # NestedModules load order: Core first, then features (feature modules call Core by command name at runtime)
    NestedModules     = @(
        '.\src\Core\PsMenuKit.Core.psd1'
        '.\src\Modules\Theme\PsMenuKit.Theme.psd1'
        '.\src\Modules\Status\PsMenuKit.Status.psd1'
        '.\src\Modules\Confirm\PsMenuKit.Confirm.psd1'
        '.\src\Modules\Nested\PsMenuKit.Nested.psd1'
        '.\src\Modules\Search\PsMenuKit.Search.psd1'
        '.\src\Modules\MultiSelect\PsMenuKit.MultiSelect.psd1'
        '.\src\Modules\Config\PsMenuKit.Config.psd1'
    )
    FunctionsToExport = @(
        'New-PsMenu'
        'New-PsMenuItem'
        'Show-PsMenu'
        'Get-PsMenuTheme'
        'Set-PsMenuTheme'
        'Get-PsMenuThemeName'
        'Write-PsMenuBanner'
        'Register-PsMenuTheme'
        'New-PsMenuStatusLine'
        'Read-PsMenuConfirm'
        'Show-PsMenuNested'
        'Select-PsMenuItem'
        'Test-PsMenuSearchAvailable'
        'Set-PsMenuItemSelection'
        'Get-PsMenuSelectedItems'
        'Clear-PsMenuItemSelections'
        'Test-PsMenuMultiSelectAvailable'
        'Import-PsMenuConfig'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Menu', 'Console', 'Modular', 'Windows', 'PowerShell51')
            ReleaseNotes = '0.2.1: Enterprise security close-out; Config AllowedRoot; dual launchers.'
        }
    }
}
