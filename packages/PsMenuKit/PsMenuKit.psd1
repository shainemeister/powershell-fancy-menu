@{
    # Convenience root manifest — points consumers at Core for 0.1.0.
    # Feature modules ship as separate nested paths under src/Modules/.
    ModuleVersion     = '0.1.0'
    GUID              = 'b4d9f2a1-6c7e-4f0b-8d2e-9a1c3e5f7b20'
    Author            = 'powershell-fancy-menu contributors'
    CompanyName       = 'powershell-fancy-menu'
    Copyright         = 'Copyright (c) 2026 powershell-fancy-menu contributors'
    Description       = 'PsMenuKit: modular pure-PowerShell 5.1 console menu kit (Core + optional feature modules).'
    PowerShellVersion = '5.1'
    NestedModules     = @(
        '.\src\Core\PsMenuKit.Core.psd1'
    )
    FunctionsToExport = @(
        'New-PsMenu'
        'New-PsMenuItem'
        'Show-PsMenu'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags       = @('Menu', 'Console', 'Modular', 'Windows', 'PowerShell51')
            ReleaseNotes = '0.1.0: Core engine only. Feature modules planned.'
        }
    }
}
