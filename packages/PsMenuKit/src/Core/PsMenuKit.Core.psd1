@{
    RootModule        = 'PsMenuKit.Core.psm1'
    ModuleVersion     = '0.5.1'
    GUID              = 'a3c8e1f2-5b6d-4e9a-9c1d-7f2e8b4a0d15'
    Author            = 'powershell-fancy-menu contributors'
    CompanyName       = 'powershell-fancy-menu'
    Copyright         = 'Copyright (c) 2026 powershell-fancy-menu contributors'
    Description       = 'Dependency-free interactive console menu engine for Windows PowerShell 5.1.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'New-PsMenu'
        'New-PsMenuItem'
        'Show-PsMenu'
        'Get-PsMenuDisplayText'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
    PrivateData       = @{
        PSData = @{
            Tags         = @('Menu', 'Console', 'TUI', 'Windows', 'PowerShell51')
            LicenseUri   = ''
            ProjectUri   = ''
            ReleaseNotes = '0.5.1: WindowTitle sanitization; action fail-closed; display control strip.'
        }
    }
}
