# PsMenuKit.Nested — submenu navigation with breadcrumb titles (PS 5.1)
# Core calls Show-PsMenuNested when an item has Children.

function Show-PsMenuNested {
    <#
    .SYNOPSIS
        Opens a child menu for an item that has Children.
    .DESCRIPTION
        Builds a submenu titled "Parent > Item" and runs Show-PsMenu.
        Esc/Q from the child returns Cancelled so Core can redraw the parent.
    .PARAMETER ParentMenu
        Parent menu model (for title breadcrumb).
    .PARAMETER Item
        Parent item containing Children.
    .PARAMETER Theme
        Theme hashtable or name passed through to Show-PsMenu.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$ParentMenu,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item,

        [Parameter(Mandatory = $false)]
        [object]$Theme
    )

    $showCmd = Get-Command -Name 'Show-PsMenu' -ErrorAction SilentlyContinue
    $newMenuCmd = Get-Command -Name 'New-PsMenu' -ErrorAction SilentlyContinue
    if ($null -eq $showCmd -or $null -eq $newMenuCmd) {
        throw 'Show-PsMenuNested requires PsMenuKit.Core (New-PsMenu, Show-PsMenu).'
    }

    $children = @()
    if ($null -ne $Item.PSObject.Properties['Children'] -and $null -ne $Item.Children) {
        $children = @($Item.Children)
    }
    if ($children.Count -eq 0) {
        return [pscustomobject]@{
            PSTypeName   = 'PsMenuKit.MenuResult'
            Cancelled    = $true
            ItemId       = $null
            Label        = $null
            ActionResult = $null
            Reason       = 'EmptyChildren'
            Selections   = @()
        }
    }

    $title = '{0} > {1}' -f $ParentMenu.Title, $Item.Label
    $subMenu = & $newMenuCmd -Title $title -Subtitle 'Esc returns to parent' -Items $children -Theme $Theme
    if ($null -ne $ParentMenu.PSObject.Properties['MultiSelect'] -and $ParentMenu.MultiSelect) {
        # Nested inherits MultiSelect only if property was set on New-PsMenu
        $subMenu | Add-Member -NotePropertyName MultiSelect -NotePropertyValue $true -Force
    }

    $result = & $showCmd -Menu $subMenu -Theme $Theme -ClearOnExit $true
    return $result
}

Export-ModuleMember -Function @('Show-PsMenuNested')
