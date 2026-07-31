# PsMenuKit.Theme - named ConsoleColor palettes and banner helper (PS 5.1)

$script:PsMenuKitCurrentThemeName = 'Default'

$script:PsMenuKitThemes = @{
    Default = @{
        Name       = 'Default'
        Title      = [ConsoleColor]::Cyan
        Subtitle   = [ConsoleColor]::DarkCyan
        Normal     = [ConsoleColor]::Gray
        SelectedFg = [ConsoleColor]::Black
        SelectedBg = [ConsoleColor]::Cyan
        Disabled   = [ConsoleColor]::DarkGray
        Hint       = [ConsoleColor]::DarkGray
        Border     = [ConsoleColor]::DarkCyan
        Error      = [ConsoleColor]::Red
        Success    = [ConsoleColor]::Green
    }
    Dark = @{
        Name       = 'Dark'
        Title      = [ConsoleColor]::White
        Subtitle   = [ConsoleColor]::Gray
        Normal     = [ConsoleColor]::Gray
        SelectedFg = [ConsoleColor]::Black
        SelectedBg = [ConsoleColor]::DarkCyan
        Disabled   = [ConsoleColor]::DarkGray
        Hint       = [ConsoleColor]::DarkGray
        Border     = [ConsoleColor]::DarkGray
        Error      = [ConsoleColor]::Red
        Success    = [ConsoleColor]::DarkGreen
    }
    Light = @{
        Name       = 'Light'
        Title      = [ConsoleColor]::DarkBlue
        Subtitle   = [ConsoleColor]::DarkCyan
        Normal     = [ConsoleColor]::Black
        SelectedFg = [ConsoleColor]::White
        SelectedBg = [ConsoleColor]::DarkBlue
        Disabled   = [ConsoleColor]::DarkGray
        Hint       = [ConsoleColor]::DarkGray
        Border     = [ConsoleColor]::Gray
        Error      = [ConsoleColor]::DarkRed
        Success    = [ConsoleColor]::DarkGreen
    }
    HighContrast = @{
        Name       = 'HighContrast'
        Title      = [ConsoleColor]::Yellow
        Subtitle   = [ConsoleColor]::White
        Normal     = [ConsoleColor]::White
        SelectedFg = [ConsoleColor]::Black
        SelectedBg = [ConsoleColor]::Yellow
        Disabled   = [ConsoleColor]::DarkGray
        Hint       = [ConsoleColor]::Gray
        Border     = [ConsoleColor]::Yellow
        Error      = [ConsoleColor]::Red
        Success    = [ConsoleColor]::Green
    }
}

function Get-PsMenuTheme {
    <#
    .SYNOPSIS
        Returns a theme hashtable by name, or the current theme if Name is omitted.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Name
    )

    $themeName = $Name
    if ([string]::IsNullOrWhiteSpace($themeName)) {
        $themeName = $script:PsMenuKitCurrentThemeName
    }

    if (-not $script:PsMenuKitThemes.ContainsKey($themeName)) {
        throw "Unknown theme name: $themeName. Available: $($script:PsMenuKitThemes.Keys -join ', ')"
    }

    # Return a shallow copy so callers cannot mutate the catalog
    $src = $script:PsMenuKitThemes[$themeName]
    $copy = @{}
    foreach ($key in $src.Keys) {
        $copy[$key] = $src[$key]
    }
    return $copy
}

function Set-PsMenuTheme {
    <#
    .SYNOPSIS
        Sets the current default theme name used by Get-PsMenuTheme.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name
    )

    if (-not $script:PsMenuKitThemes.ContainsKey($Name)) {
        throw "Unknown theme name: $Name. Available: $($script:PsMenuKitThemes.Keys -join ', ')"
    }

    $script:PsMenuKitCurrentThemeName = $Name
    return Get-PsMenuTheme -Name $Name
}

function Get-PsMenuThemeName {
    <#
    .SYNOPSIS
        Lists built-in theme names, or returns the current theme name.
    #>
    [CmdletBinding(DefaultParameterSetName = 'List')]
    [OutputType([string])]
    param(
        [Parameter(ParameterSetName = 'Current')]
        [switch]$Current
    )

    if ($Current) {
        return $script:PsMenuKitCurrentThemeName
    }

    return @($script:PsMenuKitThemes.Keys | Sort-Object)
}

function Write-PsMenuBanner {
    <#
    .SYNOPSIS
        Writes a multi-line ASCII banner using the active or named theme.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Lines,

        [Parameter(Mandatory = $false)]
        [string]$ThemeName
    )

    $theme = Get-PsMenuTheme -Name $ThemeName
    $width = 50
    foreach ($line in $Lines) {
        if ($line.Length -gt $width) {
            $width = $line.Length
        }
    }
    $border = '+' + ('-' * ($width + 2)) + '+'
    Write-Host $border -ForegroundColor $theme.Border
    foreach ($line in $Lines) {
        $pad = $line.PadRight($width)
        Write-Host ('| {0} |' -f $pad) -ForegroundColor $theme.Title
    }
    Write-Host $border -ForegroundColor $theme.Border
}

function Register-PsMenuTheme {
    <#
    .SYNOPSIS
        Registers or replaces a named theme palette.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme
    )

    $base = Get-PsMenuTheme -Name 'Default'
    foreach ($key in $Theme.Keys) {
        $base[$key] = $Theme[$key]
    }
    $base['Name'] = $Name
    $script:PsMenuKitThemes[$Name] = $base
}

Export-ModuleMember -Function @(
    'Get-PsMenuTheme'
    'Set-PsMenuTheme'
    'Get-PsMenuThemeName'
    'Write-PsMenuBanner'
    'Register-PsMenuTheme'
)
