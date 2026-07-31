function Get-PsMenuCoreTheme {
    <#
    .SYNOPSIS
        Returns the built-in Core color palette.
    .DESCRIPTION
        Uses System.ConsoleColor only (Windows PowerShell 5.1 safe).
        Feature module Theme may replace this via Set-PsMenuTheme when loaded.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    return @{
        Name            = 'CoreDefault'
        Title           = [ConsoleColor]::Cyan
        Subtitle        = [ConsoleColor]::DarkCyan
        Normal          = [ConsoleColor]::Gray
        SelectedFg      = [ConsoleColor]::Black
        SelectedBg      = [ConsoleColor]::Cyan
        Disabled        = [ConsoleColor]::DarkGray
        Hint            = [ConsoleColor]::DarkGray
        Border          = [ConsoleColor]::DarkCyan
        Error           = [ConsoleColor]::Red
        Success         = [ConsoleColor]::Green
    }
}
