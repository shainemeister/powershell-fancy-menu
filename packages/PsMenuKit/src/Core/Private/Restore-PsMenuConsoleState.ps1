function Restore-PsMenuConsoleState {
    <#
    .SYNOPSIS
        Restores console UI state captured by Save-PsMenuConsoleState.
    .DESCRIPTION
        Best-effort restore. Ctrl+C may still prevent finally blocks on some hosts;
        see SECURITY / CLI-GUIDE environment notes.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$State,

        [Parameter(Mandatory = $false)]
        [bool]$ClearOnExit = $false
    )

    if ($null -eq $State) {
        return
    }

    if ($State['CapturedCursor']) {
        try {
            [Console]::CursorVisible = [bool]$State['CursorVisible']
        }
        catch { }
    }

    if ($State['CapturedTitle'] -and $null -ne $State['WindowTitle']) {
        try {
            $Host.UI.RawUI.WindowTitle = [string]$State['WindowTitle']
        }
        catch { }
    }

    if ($ClearOnExit) {
        try {
            Clear-Host
        }
        catch { }
    }
}
