@{
    RootModule        = 'PsMenuKit.MultiSelect.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'b6c7d8e9-f0a1-2345-1234-67890abcdef0'
    Author            = 'powershell-fancy-menu contributors'
    Description       = 'PsMenuKit MultiSelect feature module: Space-toggle multi selection.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Set-PsMenuItemSelection'
        'Get-PsMenuSelectedItems'
        'Clear-PsMenuItemSelections'
        'Test-PsMenuMultiSelectAvailable'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
