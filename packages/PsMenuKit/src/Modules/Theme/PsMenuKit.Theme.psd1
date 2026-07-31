@{
    RootModule        = 'PsMenuKit.Theme.psm1'
    ModuleVersion     = '0.2.0'
    GUID              = 'c1d2e3f4-a5b6-7890-cdef-1234567890ab'
    Author            = 'powershell-fancy-menu contributors'
    Description       = 'PsMenuKit Theme feature module: named palettes and banners.'
    PowerShellVersion = '5.1'
    FunctionsToExport = @(
        'Get-PsMenuTheme'
        'Set-PsMenuTheme'
        'Get-PsMenuThemeName'
        'Write-PsMenuBanner'
        'Register-PsMenuTheme'
    )
    CmdletsToExport   = @()
    VariablesToExport = @()
    AliasesToExport   = @()
}
