function Resolve-PsMenuTheme {
    <#
    .SYNOPSIS
        Resolves an effective theme hashtable for rendering.
    .DESCRIPTION
        Preference order: explicit -Theme param (hashtable or name via Theme module),
        menu.Theme, then Core default. If Set-PsMenuTheme / Get-PsMenuTheme exist
        (Theme module), those are preferred for named themes.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $false)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [object]$MenuTheme
    )

    $candidate = $null
    if ($null -ne $Theme) {
        $candidate = $Theme
    }
    elseif ($null -ne $MenuTheme) {
        $candidate = $MenuTheme
    }

    if ($candidate -is [hashtable]) {
        $base = Get-PsMenuCoreTheme
        foreach ($key in $candidate.Keys) {
            $base[$key] = $candidate[$key]
        }
        return $base
    }

    if ($candidate -is [string] -and -not [string]::IsNullOrWhiteSpace($candidate)) {
        $getTheme = Get-Command -Name 'Get-PsMenuTheme' -ErrorAction SilentlyContinue
        if ($null -ne $getTheme) {
            try {
                $resolved = & $getTheme -Name $candidate
                if ($resolved -is [hashtable]) {
                    return $resolved
                }
            }
            catch {
                # Fall through to core default
            }
        }
    }

    return Get-PsMenuCoreTheme
}
