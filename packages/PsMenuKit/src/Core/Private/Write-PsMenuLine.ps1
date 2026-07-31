function Write-PsMenuLine {
    <#
    .SYNOPSIS
        Writes one console line with optional colors (no newline control issues).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [string]$Text = '',

        [Parameter(Mandatory = $false)]
        [ConsoleColor]$ForegroundColor,

        [Parameter(Mandatory = $false)]
        [ConsoleColor]$BackgroundColor,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )

    $params = @{
        Object = $Text
    }
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) {
        $params['ForegroundColor'] = $ForegroundColor
    }
    if ($PSBoundParameters.ContainsKey('BackgroundColor')) {
        $params['BackgroundColor'] = $BackgroundColor
    }
    if ($NoNewline) {
        $params['NoNewline'] = $true
    }

    Microsoft.PowerShell.Utility\Write-Host @params
}
