# PsMenuKit.Status — status line builder for menu headers (PS 5.1)

function New-PsMenuStatusLine {
    <#
    .SYNOPSIS
        Builds a single status line from common slots and custom text.
    .DESCRIPTION
        Pieces are joined with ' · '. Omit switches you do not want.
    .PARAMETER Text
        Optional free-form segments (string or string[]).
    .PARAMETER IncludeUser
        Include $env:USERNAME.
    .PARAMETER IncludeComputer
        Include $env:COMPUTERNAME.
    .PARAMETER IncludeTime
        Include local time (HH:mm:ss).
    .PARAMETER IncludeDate
        Include local date (yyyy-MM-dd).
    .PARAMETER LastResult
        Optional last MenuResult or string to summarize.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]]$Text,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeUser,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeComputer,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeTime,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeDate,

        [Parameter(Mandatory = $false)]
        [object]$LastResult
    )

    $parts = New-Object System.Collections.Generic.List[string]

    if ($IncludeUser) {
        $parts.Add(('User: {0}' -f $env:USERNAME))
    }
    if ($IncludeComputer) {
        $parts.Add(('Host: {0}' -f $env:COMPUTERNAME))
    }
    if ($IncludeDate) {
        $parts.Add((Get-Date).ToString('yyyy-MM-dd'))
    }
    if ($IncludeTime) {
        $parts.Add((Get-Date).ToString('HH:mm:ss'))
    }
    if ($null -ne $LastResult) {
        if ($LastResult -is [string]) {
            $parts.Add(('Last: {0}' -f $LastResult))
        }
        elseif ($null -ne $LastResult.PSObject.Properties['Cancelled'] -and $LastResult.Cancelled) {
            $parts.Add('Last: cancelled')
        }
        elseif ($null -ne $LastResult.PSObject.Properties['Label']) {
            $parts.Add(('Last: {0}' -f $LastResult.Label))
        }
        else {
            $parts.Add(('Last: {0}' -f $LastResult.ToString()))
        }
    }
    if ($null -ne $Text) {
        foreach ($t in @($Text)) {
            if (-not [string]::IsNullOrWhiteSpace($t)) {
                $parts.Add($t)
            }
        }
    }

    if ($parts.Count -eq 0) {
        return ''
    }

    return ($parts -join ' · ')
}

Export-ModuleMember -Function @('New-PsMenuStatusLine')
