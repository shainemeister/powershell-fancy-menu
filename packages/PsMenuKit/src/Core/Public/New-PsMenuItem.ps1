function New-PsMenuItem {
    <#
    .SYNOPSIS
        Creates one menu item for PsMenuKit.
    .DESCRIPTION
        Builds a menu item object. Optional properties (Children, ConfirmMessage, etc.)
        are reserved for feature modules; Core ignores unknown fields.
    .PARAMETER Label
        Display text for the item.
    .PARAMETER Id
        Stable identifier. Auto-generated if omitted.
    .PARAMETER Action
        ScriptBlock invoked when the item is activated (Enter).
    .PARAMETER Enabled
        When $false, the item is shown but cannot be activated.
    .PARAMETER Hotkey
        Optional single character hotkey (case-insensitive).
    .PARAMETER Meta
        Optional hashtable for consumer metadata.
    .PARAMETER Children
        Optional nested items (used when Nested feature module is loaded).
    .PARAMETER ConfirmMessage
        Optional confirmation prompt text (used when Confirm feature module is loaded).
    .EXAMPLE
        New-PsMenuItem -Label 'Quit' -Action { } -Hotkey 'q'
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Label,

        [Parameter(Mandatory = $false)]
        [string]$Id,

        [Parameter(Mandatory = $false)]
        [scriptblock]$Action,

        [Parameter(Mandatory = $false)]
        [bool]$Enabled = $true,

        [Parameter(Mandatory = $false)]
        [ValidateLength(1, 1)]
        [string]$Hotkey,

        [Parameter(Mandatory = $false)]
        [hashtable]$Meta,

        [Parameter(Mandatory = $false)]
        [object[]]$Children,

        [Parameter(Mandatory = $false)]
        [string]$ConfirmMessage
    )

    if ([string]::IsNullOrWhiteSpace($Id)) {
        $Id = [guid]::NewGuid().ToString('N').Substring(0, 8)
    }

    $item = [ordered]@{
        PSTypeName = 'PsMenuKit.MenuItem'
        Id         = $Id
        Label      = $Label
        Enabled    = $Enabled
        Action     = $Action
        Hotkey     = $Hotkey
        Meta       = $Meta
    }

    if ($PSBoundParameters.ContainsKey('Children')) {
        $item['Children'] = @($Children)
    }
    if ($PSBoundParameters.ContainsKey('ConfirmMessage')) {
        $item['ConfirmMessage'] = $ConfirmMessage
    }

    return [pscustomobject]$item
}
