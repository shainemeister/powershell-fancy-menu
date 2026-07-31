# PsMenuKit.MultiSelect — toggle selection markers on items (PS 5.1)
# Core uses these helpers when Menu.MultiSelect is $true.

function Set-PsMenuItemSelection {
    <#
    .SYNOPSIS
        Sets or toggles the Selected flag on a menu item (in place).
    .PARAMETER Item
        Menu item object.
    .PARAMETER Selected
        Explicit selected state. Ignored when -Toggle is used.
    .PARAMETER Toggle
        Flip current Selected state.
    #>
    [CmdletBinding(DefaultParameterSetName = 'Set')]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item,

        [Parameter(ParameterSetName = 'Set', Mandatory = $false)]
        [bool]$Selected = $true,

        [Parameter(ParameterSetName = 'Toggle', Mandatory = $true)]
        [switch]$Toggle
    )

    $current = $false
    if ($null -ne $Item.PSObject.Properties['Selected']) {
        $current = [bool]$Item.Selected
    }

    $newValue = $Selected
    if ($PSCmdlet.ParameterSetName -eq 'Toggle') {
        $newValue = -not $current
    }

    $Item | Add-Member -NotePropertyName Selected -NotePropertyValue $newValue -Force
    return $Item
}

function Get-PsMenuSelectedItems {
    <#
    .SYNOPSIS
        Returns items where Selected is $true.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items
    )

    $selected = New-Object System.Collections.Generic.List[object]
    foreach ($item in @($Items)) {
        if ($null -ne $item.PSObject.Properties['Selected'] -and [bool]$item.Selected) {
            $selected.Add($item)
        }
    }
    return @($selected.ToArray())
}

function Clear-PsMenuItemSelections {
    <#
    .SYNOPSIS
        Clears Selected on all items.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items
    )

    foreach ($item in @($Items)) {
        $item | Add-Member -NotePropertyName Selected -NotePropertyValue $false -Force
    }
}

function Test-PsMenuMultiSelectAvailable {
    <#
    .SYNOPSIS
        Returns $true so Core can detect MultiSelect capability.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return $true
}

Export-ModuleMember -Function @(
    'Set-PsMenuItemSelection'
    'Get-PsMenuSelectedItems'
    'Clear-PsMenuItemSelections'
    'Test-PsMenuMultiSelectAvailable'
)
