function New-PsMenu {
    <#
    .SYNOPSIS
        Creates a menu model for PsMenuKit.
    .DESCRIPTION
        A menu holds a title, optional subtitle, and an ordered list of items.
    .PARAMETER Title
        Menu title shown above the item list.
    .PARAMETER Items
        Array of items from New-PsMenuItem (or compatible objects).
    .PARAMETER Subtitle
        Optional secondary line under the title.
    .PARAMETER Theme
        Optional theme name or hashtable (Theme module may interpret this).
    .PARAMETER MultiSelect
        When $true and MultiSelect module is loaded, Space toggles selection.
    .EXAMPLE
        New-PsMenu -Title 'Tools' -Items @(
            New-PsMenuItem -Label 'Hello' -Action { Write-Host 'Hi' }
        )
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory = $false)]
        [string]$Subtitle,

        [Parameter(Mandatory = $false)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [bool]$MultiSelect = $false
    )

    $menu = [ordered]@{
        PSTypeName  = 'PsMenuKit.Menu'
        Title       = $Title
        Subtitle    = $Subtitle
        Items       = @($Items)
        Theme       = $Theme
        MultiSelect = $MultiSelect
    }

    return [pscustomobject]$menu
}
