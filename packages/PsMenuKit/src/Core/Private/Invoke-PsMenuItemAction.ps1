function Invoke-PsMenuItemAction {
    <#
    .SYNOPSIS
        Invokes a menu item Action scriptblock safely and returns an outcome.
    .DESCRIPTION
        Fail-closed: only [scriptblock] Actions are invoked. Strings and other
        types are rejected so mutated items cannot turn "& $Action" into
        arbitrary command-name execution.
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

    $action = $null
    if ($null -ne $Item.PSObject.Properties['Action']) {
        $action = $Item.Action
    }

    if ($null -eq $action) {
        $result['Success'] = $true
        $result['Output'] = $null
        return [pscustomobject]$result
    }

    if (-not ($action -is [scriptblock])) {
        $result['Success'] = $false
        $result['Error'] = [System.Management.Automation.ErrorRecord]::new(
            [System.InvalidOperationException]::new(
                ("Menu item Action must be a scriptblock (got {0}). Rejected to prevent command-name invocation." -f $action.GetType().FullName)
            ),
            'PsMenuKit.InvalidActionType',
            [System.Management.Automation.ErrorCategory]::InvalidType,
            $action
        )
        return [pscustomobject]$result
    }

    try {
        $output = & $action
        $result['Output'] = $output
        $result['Success'] = $true
    }
    catch {
        $result['Success'] = $false
        $result['Error'] = $_
    }

    return [pscustomobject]$result
}
