function Get-PsMenuConsoleWidth {
    <#
    .SYNOPSIS
        Returns a safe console width for truncation (fallback 80).
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $false)]
        [int]$Fallback = 80
    )

    try {
        $w = [int]$Host.UI.RawUI.WindowSize.Width
        if ($w -ge 20) {
            return $w
        }
    }
    catch { }

    if ($Fallback -lt 20) {
        return 20
    }
    return $Fallback
}
