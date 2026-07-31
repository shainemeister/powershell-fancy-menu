function Save-PsMenuConsoleState {
    <#
    .SYNOPSIS
        Captures console UI state to restore after the menu loop.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()

    $state = @{
        WindowTitle     = $null
        CursorVisible   = $true
        CapturedTitle   = $false
        CapturedCursor  = $false
    }

    try {
        $state['WindowTitle'] = $Host.UI.RawUI.WindowTitle
        $state['CapturedTitle'] = $true
    }
    catch { }

    try {
        $state['CursorVisible'] = [Console]::CursorVisible
        $state['CapturedCursor'] = $true
    }
    catch { }

    return $state
}
