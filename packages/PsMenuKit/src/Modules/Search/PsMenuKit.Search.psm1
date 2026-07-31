# PsMenuKit.Search - incremental item filter helpers (PS 5.1)
# Core calls Filter-PsMenuItems when this module is imported.

function Select-PsMenuItem {
    <#
    .SYNOPSIS
        Filters menu items by label substring (case-insensitive).
    .PARAMETER Items
        Full item list.
    .PARAMETER Query
        Filter text; empty returns all items.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Items,

        [Parameter(Mandatory = $false)]
        [string]$Query
    )

    if ($null -eq $Items) {
        return @()
    }
    if ([string]::IsNullOrWhiteSpace($Query)) {
        return @($Items)
    }

    $q = $Query.ToLowerInvariant()
    $matched = New-Object System.Collections.Generic.List[object]
    foreach ($item in $Items) {
        $label = ''
        if ($null -ne $item.PSObject.Properties['Label'] -and $null -ne $item.Label) {
            $label = [string]$item.Label
        }
        if ($label.ToLowerInvariant().Contains($q)) {
            $matched.Add($item)
        }
    }
    return @($matched.ToArray())
}

function Test-PsMenuSearchAvailable {
    <#
    .SYNOPSIS
        Returns $true so Core can detect Search capability.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()
    return $true
}

Export-ModuleMember -Function @(
    'Select-PsMenuItem'
    'Test-PsMenuSearchAvailable'
)
