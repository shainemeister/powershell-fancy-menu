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
        [AllowEmptyCollection()]
        [object[]]$VisibleItems,

        [Parameter(Mandatory = $true)]
        [int]$SelectedIndex,

        [Parameter(Mandatory = $true)]
        [hashtable]$Theme,

        [Parameter(Mandatory = $false)]
        [string]$StatusLine,

        [Parameter(Mandatory = $false)]
        [string]$FilterText,

        [Parameter(Mandatory = $false)]
        [bool]$MultiSelectMode = $false,

        [Parameter(Mandatory = $false)]
        [bool]$SearchEnabled = $false
    )

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        Clear-Host

        $width = Get-PsMenuConsoleWidth
        $innerWidth = $width - 4
        if ($innerWidth -lt 10) { $innerWidth = 10 }
        $border = '+' + ('-' * ($innerWidth + 2)) + '+'

        $titleText = Get-PsMenuDisplayText -Text $Menu.Title -MaxWidth $innerWidth
        Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
        Write-PsMenuLine -Text ('| {0}' -f $titleText) -ForegroundColor $Theme.Title

        if (-not [string]::IsNullOrWhiteSpace($Menu.Subtitle)) {
            $sub = Get-PsMenuDisplayText -Text $Menu.Subtitle -MaxWidth $innerWidth
            Write-PsMenuLine -Text ('| {0}' -f $sub) -ForegroundColor $Theme.Subtitle
        }

        if (-not [string]::IsNullOrWhiteSpace($StatusLine)) {
            $st = Get-PsMenuDisplayText -Text $StatusLine -MaxWidth $innerWidth
            Write-PsMenuLine -Text ('| {0}' -f $st) -ForegroundColor $Theme.Hint
        }

        if ($SearchEnabled) {
            $filterDisplay = $FilterText
            if ($null -eq $filterDisplay) { $filterDisplay = '' }
            $ft = Get-PsMenuDisplayText -Text ('Filter: {0}_' -f $filterDisplay) -MaxWidth $innerWidth
            Write-PsMenuLine -Text ('| {0}' -f $ft) -ForegroundColor $Theme.Hint
        }

        Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
        Write-PsMenuLine -Text ''

        $labelMax = $innerWidth - 4
        if ($labelMax -lt 8) { $labelMax = 8 }

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

                $check = ''
                if ($MultiSelectMode) {
                    $isSel = $false
                    if ($null -ne $item.PSObject.Properties['Selected']) {
                        $isSel = [bool]$item.Selected
                    }
                    if ($isSel) {
                        $check = '[x] '
                    }
                    else {
                        $check = '[ ] '
                    }
                }

                $hotkeyPart = ''
                if ($null -ne $item.PSObject.Properties['Hotkey'] -and -not [string]::IsNullOrWhiteSpace([string]$item.Hotkey)) {
                    $hotkeyPart = ' [{0}]' -f ([string]$item.Hotkey).ToUpperInvariant()
                }

                $childHint = ''
                if ($null -ne $item.PSObject.Properties['Children'] -and $null -ne $item.Children -and @($item.Children).Count -gt 0) {
                    $childHint = ' >'
                }

                $rawLabel = [string]$item.Label
                if (-not $enabled) {
                    $composed = '   {0}{1}{2} (disabled)' -f $check, $rawLabel, $hotkeyPart
                    $label = Get-PsMenuDisplayText -Text $composed -MaxWidth ($innerWidth + 2)
                    Write-PsMenuLine -Text $label -ForegroundColor $Theme.Disabled
                }
                else {
                    $composed = ' {0} {1}{2}{3}{4}' -f $marker, $check, $rawLabel, $hotkeyPart, $childHint
                    $label = Get-PsMenuDisplayText -Text $composed -MaxWidth ($innerWidth + 2)
                    if ($i -eq $SelectedIndex) {
                        Write-PsMenuLine -Text $label -ForegroundColor $Theme.SelectedFg -BackgroundColor $Theme.SelectedBg
                    }
                    else {
                        Write-PsMenuLine -Text $label -ForegroundColor $Theme.Normal
                    }
                }
            }
        }

        Write-PsMenuLine -Text ''
        Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border

        $hints = New-Object System.Collections.Generic.List[string]
        $hints.Add('Up/Down')
        $hints.Add('Enter=select')
        if ($MultiSelectMode) {
            $hints.Add('Space=toggle')
        }
        if ($SearchEnabled) {
            $hints.Add('type=filter')
            $hints.Add('Bksp=clear char')
        }
        $hints.Add('Esc/Q=quit')
        $hints.Add('1-9=jump')

        $hintLine = Get-PsMenuDisplayText -Text ('  {0}' -f ($hints -join '  ')) -MaxWidth ($width - 1)
        Write-PsMenuLine -Text $hintLine -ForegroundColor $Theme.Hint
        Write-PsMenuLine -Text $border -ForegroundColor $Theme.Border
    }
    finally {
        $ErrorActionPreference = $prevEap
    }
}
