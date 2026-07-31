function Get-PsMenuDisplayText {
    <#
    .SYNOPSIS
        Truncates text to a maximum character width for console display.
    .DESCRIPTION
        Uses simple character length (PS 5.1 safe). Wide Unicode glyphs may
        still wrap; truncation prevents hard failures on long labels.
    .PARAMETER Text
        Input string (null treated as empty).
    .PARAMETER MaxWidth
        Maximum characters. When omitted, uses console width minus margin.
    .PARAMETER Margin
        Columns reserved for borders/markers when MaxWidth is auto (default 6).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [ValidateRange(4, 10000)]
        [int]$MaxWidth,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 40)]
        [int]$Margin = 6
    )

    if ($null -eq $Text) {
        $Text = ''
    }

    if (-not $PSBoundParameters.ContainsKey('MaxWidth')) {
        $consoleWidth = Get-PsMenuConsoleWidth
        $MaxWidth = $consoleWidth - $Margin
        if ($MaxWidth -lt 4) {
            $MaxWidth = 4
        }
    }

    if ($Text.Length -le $MaxWidth) {
        return $Text
    }

    if ($MaxWidth -le 3) {
        return $Text.Substring(0, $MaxWidth)
    }

    return $Text.Substring(0, $MaxWidth - 3) + '...'
}
