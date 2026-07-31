function Invoke-PsMenuItemAction {
    <#
    .SYNOPSIS
        Invokes a menu item Action scriptblock safely and returns an outcome.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item
    )

    $result = [ordered]@{
        PSTypeName = 'PsMenuKit.ActionResult'
        ItemId     = $Item.Id
        Label      = $Item.Label
        Success    = $true
        Error      = $null
        Output     = $null
    }

    if ($null -eq $Item.Action) {
        $result['Success'] = $true
        $result['Output'] = $null
        return [pscustomobject]$result
    }

    try {
        $output = & $Item.Action
        $result['Output'] = $output
        $result['Success'] = $true
    }
    catch {
        $result['Success'] = $false
        $result['Error'] = $_
    }

    return [pscustomobject]$result
}
