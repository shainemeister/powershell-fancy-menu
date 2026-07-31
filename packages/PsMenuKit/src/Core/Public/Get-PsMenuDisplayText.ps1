function Get-PsMenuDisplayText {
    <#
    .SYNOPSIS
        Truncates and sanitizes text for safe console display.
    .DESCRIPTION
        Uses simple character length (PS 5.1 safe). Wide Unicode glyphs may
        still wrap; truncation prevents hard failures on long labels.

        Control characters and ANSI/OSC escape sequences are stripped so
        untrusted menu labels cannot rewrite the terminal title or inject
        misleading control sequences (best-effort display integrity).
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

    # Strip ANSI CSI/OSC and other C0 controls (keep tab/newline as spaces)
    $Text = [regex]::Replace($Text, '\x1B\[[0-9;?]*[ -/]*[@-~]', '')
    $Text = [regex]::Replace($Text, '\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)?', '')
    $Text = [regex]::Replace($Text, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '')
    $Text = $Text -replace "[\r\n\t]+", ' '

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
