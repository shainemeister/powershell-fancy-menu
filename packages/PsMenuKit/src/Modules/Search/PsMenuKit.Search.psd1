@{
    RootModule        = 'PsMenuKit.Search.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'a5b6c7d8-e9f0-1234-0123-567890abcdef'
    Author            = 'powershell-fancy-menu contributors'
    Description       = 'PsMenuKit Search feature module: incremental label filter.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Select-PsMenuItem'
        'Test-PsMenuSearchAvailable'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
