function Show-PsMenuFrame {
    <#
    .SYNOPSIS
        Renders one full menu frame (title, items, hints).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Menu,

        [Parameter(Mandatory = $true)]
        [object[]]$VisibleItems,

        [Parameter(Mandatory = $true)]
        [int]$SelectedIndex,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $false)]
        [string]$StatusLine,

        [Parameter(Mandatory = $false)]
        [string]$FilterText
    )

    Clear-Host

    $border = '+--------------------------------------------------+'
    Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
    Write-PsMenuLine -Text ('| {0}' -f $Menu.Title) -ForegroundColor $Theme.Title

    if (-not [string]::IsNullOrWhiteSpace($Menu.Subtitle)) {
        Write-PsMenuLine -Text ('| {0}' -f $Menu.Subtitle) -ForegroundColor $Theme.Subtitle
    }

    if (-not [string]::IsNullOrWhiteSpace($StatusLine)) {
        Write-PsMenuLine -Text ('| {0}' -f $StatusLine) -ForegroundColor $Theme.Hint
    }

    if (-not [string]::IsNullOrWhiteSpace($FilterText)) {
        Write-PsMenuLine -Text ('| Filter: {0}' -f $FilterText) -ForegroundColor $Theme.Hint
    }

    Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
    Write-PsMenuLine -Text ''

    if ($null -eq $VisibleItems -or $VisibleItems.Count -eq 0) {
        Write-PsMenuLine -Text '  (no items)' -ForegroundColor $Theme.Disabled
    }
    else {
        for ($i = 0; $i -lt $VisibleItems.Count; $i++) {
            $item = $VisibleItems[$i]
            $marker = if ($i -eq $SelectedIndex) { '>' } else { ' ' }
            $enabled = $true
            if ($null -ne $item.PSObject.Properties['Enabled']) {
                $enabled = [bool]$item.Enabled
            }

            $hotkeyPart = ''
            if ($null -ne $item.PSObject.Properties['Hotkey'] -and -not [string]::IsNullOrWhiteSpace([string]$item.Hotkey)) {
                $hotkeyPart = ' [{0}]' -f ([string]$item.Hotkey).ToUpperInvariant()
            }

            $label = ' {0} {1}{2}' -f $marker, $item.Label, $hotkeyPart
            if (-not $enabled) {
                $label = '   {0}{1} (disabled)' -f $item.Label, $hotkeyPart
                Write-PsMenuLine -Text $label -ForegroundColor $Theme.Disabled
            }
            elseif ($i -eq $SelectedIndex) {
                Write-PsMenuLine -Text $label -ForegroundColor $Theme.SelectedFg -BackgroundColor $Theme.SelectedBg
            }
            else {
                Write-PsMenuLine -Text $label -ForegroundColor $Theme.Normal
            }
        }
    }

    Write-PsMenuLine -Text ''
    Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
    Write-PsMenuLine -Text '  Up/Down  Enter=select  Esc/Q=quit  1-9=jump  hotkeys' -ForegroundColor $Theme.Hint
    Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
}
