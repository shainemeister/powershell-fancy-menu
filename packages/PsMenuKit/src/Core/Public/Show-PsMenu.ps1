function Show-PsMenu {
    <#
    .SYNOPSIS
        Runs the interactive menu loop and returns a result object.
    .DESCRIPTION
        Core menu: arrow keys, Enter, Esc/Q, number jump, hotkeys.
        Optional feature modules enhance behavior when imported:
        Confirm, Nested, Search, MultiSelect, Theme, Status.

        Console title and cursor visibility are restored on exit (best effort).
        Ctrl+C may terminate the pipeline before restore on some hosts.
    .PARAMETER Menu
        Menu model from New-PsMenu.
    .PARAMETER Theme
        Optional theme name or hashtable overlay.
    .PARAMETER StatusLine
        Optional status text under the title (Status module may build this).
    .PARAMETER ClearOnExit
        Clear the screen when the loop ends (default $true).
    .PARAMETER NestDepth
        Current nested depth (used with Nested module; default 0).
    .PARAMETER MaxNestDepth
        Maximum nested submenu depth (default 8).
    .OUTPUTS
        PsMenuKit.MenuResult
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [pscustomobject]$Menu,

        [Parameter(Mandatory = $false)]
        [object]$Theme,

        [Parameter(Mandatory = $false)]
        [string]$StatusLine,

        [Parameter(Mandatory = $false)]
        [bool]$ClearOnExit = $true,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 64)]
        [int]$NestDepth = 0,

        [Parameter(Mandatory = $false)]
        [ValidateRange(1, 64)]
        [int]$MaxNestDepth = 8
    )

    $prevEap = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'

    $consoleState = $null
    $finalResult = $null

    try {
        $themeTable = Resolve-PsMenuTheme -Theme $Theme -MenuTheme $Menu.Theme

        $rawItems = $null
        if ($null -ne $Menu.PSObject.Properties['Items']) {
            $rawItems = $Menu.Items
        }
        if ($null -eq $rawItems) {
            return New-PsMenuResult -Cancelled $true -Reason 'EmptyMenu'
        }

        $allItems = @($rawItems)
        if ($allItems.Count -eq 0) {
            return New-PsMenuResult -Cancelled $true -Reason 'EmptyMenu'
        }

        $searchEnabled = $null -ne (Get-Command -Name 'Select-PsMenuItem' -ErrorAction SilentlyContinue)
        $multiAvailable = $null -ne (Get-Command -Name 'Set-PsMenuItemSelection' -ErrorAction SilentlyContinue)
        $multiSelectMode = $false
        if ($multiAvailable -and $null -ne $Menu.PSObject.Properties['MultiSelect'] -and [bool]$Menu.MultiSelect) {
            $multiSelectMode = $true
        }

        $filterText = ''
        $visibleItems = Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled
        $selectedIndex = Get-PsMenuFirstEnabledIndex -Items $visibleItems

        $consoleState = Save-PsMenuConsoleState
        try {
            if ($consoleState['CapturedTitle']) {
                $Host.UI.RawUI.WindowTitle = [string]$Menu.Title
            }
        }
        catch { }
        try {
            [Console]::CursorVisible = $false
        }
        catch { }

        while ($true) {
            $visibleItems = Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled
            if ($visibleItems.Count -eq 0) {
                $selectedIndex = 0
            }
            elseif ($selectedIndex -ge $visibleItems.Count) {
                $selectedIndex = Get-PsMenuFirstEnabledIndex -Items $visibleItems
            }
            elseif ($selectedIndex -lt 0) {
                $selectedIndex = 0
            }

            Show-PsMenuFrame -Menu $Menu -VisibleItems $visibleItems -SelectedIndex $selectedIndex `
                -Theme $themeTable -StatusLine $StatusLine -FilterText $filterText `
                -MultiSelectMode $multiSelectMode -SearchEnabled $searchEnabled

            $keyInfo = Read-PsMenuKey
            $key = $keyInfo.Key
            $keyChar = $keyInfo.KeyChar

            if ($key -eq [ConsoleKey]::Escape) {
                if ($searchEnabled -and -not [string]::IsNullOrEmpty($filterText)) {
                    $filterText = ''
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                    continue
                }
                $finalResult = New-PsMenuResult -Cancelled $true -Reason 'UserQuit'
                break
            }

            if ($key -eq [ConsoleKey]::UpArrow) {
                if ($visibleItems.Count -gt 0) {
                    $selectedIndex = Move-PsMenuSelection -Items $visibleItems -CurrentIndex $selectedIndex -Delta -1
                }
                continue
            }
            if ($key -eq [ConsoleKey]::DownArrow) {
                if ($visibleItems.Count -gt 0) {
                    $selectedIndex = Move-PsMenuSelection -Items $visibleItems -CurrentIndex $selectedIndex -Delta 1
                }
                continue
            }

            if ($searchEnabled -and ($key -eq [ConsoleKey]::Backspace)) {
                if ($filterText.Length -gt 0) {
                    $filterText = $filterText.Substring(0, $filterText.Length - 1)
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                }
                continue
            }

            if ($multiSelectMode -and $key -eq [ConsoleKey]::Spacebar) {
                if ($visibleItems.Count -gt 0 -and $selectedIndex -ge 0 -and $selectedIndex -lt $visibleItems.Count) {
                    $item = $visibleItems[$selectedIndex]
                    if (Test-PsMenuItemEnabled -Item $item) {
                        $null = Set-PsMenuItemSelection -Item $item -Toggle
                    }
                }
                continue
            }

            if ($key -eq [ConsoleKey]::Enter -or $keyChar -eq "`r" -or $keyChar -eq "`n") {
                if ($visibleItems.Count -eq 0) {
                    continue
                }

                if ($multiSelectMode) {
                    $selectedItems = @(Get-PsMenuSelectedItems -Items $allItems)
                    if ($selectedItems.Count -eq 0) {
                        $item = $visibleItems[$selectedIndex]
                        if (-not (Test-PsMenuItemEnabled -Item $item)) { continue }
                        $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable -NestDepth $NestDepth -MaxNestDepth $MaxNestDepth
                        if ($act.Continue) { continue }
                        $finalResult = $act.Result
                        break
                    }

                    $confirmCmd = Get-Command -Name 'Read-PsMenuConfirm' -ErrorAction SilentlyContinue
                    $batchCancelled = $false
                    foreach ($si in $selectedItems) {
                        if ($null -ne $confirmCmd -and $null -ne $si.PSObject.Properties['ConfirmMessage'] -and -not [string]::IsNullOrWhiteSpace([string]$si.ConfirmMessage)) {
                            $ok = & $confirmCmd -Message $si.ConfirmMessage
                            if (-not $ok) {
                                $batchCancelled = $true
                                break
                            }
                        }
                    }
                    if ($batchCancelled) {
                        continue
                    }

                    $batchResults = New-Object System.Collections.Generic.List[object]
                    foreach ($si in $selectedItems) {
                        $batchResults.Add((Invoke-PsMenuItemAction -Item $si))
                    }
                    $ids = @($selectedItems | ForEach-Object { $_.Id })
                    $labels = @($selectedItems | ForEach-Object { $_.Label })
                    $finalResult = New-PsMenuResult -Cancelled $false -Reason 'MultiSelected' -ItemId ($ids -join ',') -Label ($labels -join ', ') -ActionResult @($batchResults.ToArray()) -Selections @($selectedItems)
                    break
                }

                $item = $visibleItems[$selectedIndex]
                if (-not (Test-PsMenuItemEnabled -Item $item)) { continue }
                $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable -NestDepth $NestDepth -MaxNestDepth $MaxNestDepth
                if ($act.Continue) { continue }
                $finalResult = $act.Result
                break
            }

            if ($null -ne $keyChar -and $keyChar -ne [char]0 -and
                $key -ne [ConsoleKey]::Enter -and
                $keyChar -ne "`r" -and $keyChar -ne "`n" -and
                -not [char]::IsControl($keyChar)) {

                $ch = ([string]$keyChar)

                if (-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) {
                    if ($ch -eq 'q' -or $ch -eq 'Q') {
                        $hotIdx = Find-PsMenuHotkeyIndex -Items $visibleItems -HotkeyChar $ch
                        if ($hotIdx -ge 0) {
                            $selectedIndex = $hotIdx
                            if (-not $multiSelectMode) {
                                $item = $visibleItems[$selectedIndex]
                                $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable -NestDepth $NestDepth -MaxNestDepth $MaxNestDepth
                                if (-not $act.Continue) {
                                    $finalResult = $act.Result
                                    break
                                }
                            }
                            continue
                        }
                        $finalResult = New-PsMenuResult -Cancelled $true -Reason 'UserQuit'
                        break
                    }
                }

                if ((-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) -and $ch -match '^[1-9]$') {
                    $num = [int]$ch
                    $target = $num - 1
                    if ($target -ge 0 -and $target -lt $visibleItems.Count -and (Test-PsMenuItemEnabled -Item $visibleItems[$target])) {
                        $selectedIndex = $target
                    }
                    continue
                }

                if (-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) {
                    $hotIdx = Find-PsMenuHotkeyIndex -Items $visibleItems -HotkeyChar $ch
                    if ($hotIdx -ge 0) {
                        $selectedIndex = $hotIdx
                        if (-not $multiSelectMode) {
                            $item = $visibleItems[$selectedIndex]
                            $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable -NestDepth $NestDepth -MaxNestDepth $MaxNestDepth
                            if (-not $act.Continue) {
                                $finalResult = $act.Result
                                break
                            }
                        }
                        continue
                    }
                }

                if ($searchEnabled) {
                    $filterText = $filterText + $ch
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                    continue
                }
            }
        }
    }
    catch {
        # Ensure callers see a structured failure rather than a naked exception when possible
        $finalResult = New-PsMenuResult -Cancelled $true -Reason 'Error'
        $finalResult | Add-Member -NotePropertyName Error -NotePropertyValue $_ -Force
        throw
    }
    finally {
        if ($null -ne $consoleState) {
            Restore-PsMenuConsoleState -State $consoleState -ClearOnExit $ClearOnExit
        }
        $ErrorActionPreference = $prevEap
    }

    if ($null -eq $finalResult) {
        $finalResult = New-PsMenuResult -Cancelled $true -Reason 'Unknown'
    }

    return $finalResult
}

function Read-PsMenuKey {
    [CmdletBinding()]
    param()

    try {
        $keyInfo = [Console]::ReadKey($true)
        return [pscustomobject]@{
            Key     = $keyInfo.Key
            KeyChar = $keyInfo.KeyChar
        }
    }
    catch {
        $raw = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
        $key = $null
        $keyChar = $raw.Character
        switch ([int]$raw.VirtualKeyCode) {
            38 { $key = [ConsoleKey]::UpArrow }
            40 { $key = [ConsoleKey]::DownArrow }
            13 { $key = [ConsoleKey]::Enter }
            27 { $key = [ConsoleKey]::Escape }
            8  { $key = [ConsoleKey]::Backspace }
            32 { $key = [ConsoleKey]::Spacebar }
        }
        return [pscustomobject]@{
            Key     = $key
            KeyChar = $keyChar
        }
    }
}

function Get-PsMenuVisibleItems {
    [CmdletBinding()]
    param(
        [object[]]$AllItems,
        [string]$FilterText,
        [bool]$SearchEnabled
    )

    if ($null -eq $AllItems) {
        return @()
    }
    if ($SearchEnabled -and -not [string]::IsNullOrEmpty($FilterText)) {
        return @(Select-PsMenuItem -Items $AllItems -Query $FilterText)
    }
    return @($AllItems)
}

function Get-PsMenuFirstEnabledIndex {
    [CmdletBinding()]
    [OutputType([int])]
    param([object[]]$Items)

    if ($null -eq $Items -or $Items.Count -eq 0) { return 0 }
    for ($i = 0; $i -lt $Items.Count; $i++) {
        if (Test-PsMenuItemEnabled -Item $Items[$i]) { return $i }
    }
    return 0
}

function Test-PsMenuItemEnabled {
    [CmdletBinding()]
    [OutputType([bool])]
    param([pscustomobject]$Item)

    if ($null -eq $Item) { return $false }
    if ($null -ne $Item.PSObject.Properties['Enabled']) {
        return [bool]$Item.Enabled
    }
    return $true
}

function Find-PsMenuHotkeyIndex {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [object[]]$Items,
        [string]$HotkeyChar
    )

    if ($null -eq $Items) { return -1 }
    $ch = $HotkeyChar.ToLowerInvariant()
    for ($i = 0; $i -lt $Items.Count; $i++) {
        $hk = $null
        if ($null -ne $Items[$i].PSObject.Properties['Hotkey'] -and $null -ne $Items[$i].Hotkey) {
            $hk = ([string]$Items[$i].Hotkey).ToLowerInvariant()
        }
        if ($hk -eq $ch -and (Test-PsMenuItemEnabled -Item $Items[$i])) {
            return $i
        }
    }
    return -1
}

function Invoke-PsMenuActivateItem {
    [CmdletBinding()]
    param(
        [pscustomobject]$Menu,
        [pscustomobject]$Item,
        [hashtable]$ThemeTable,
        [int]$NestDepth = 0,
        [int]$MaxNestDepth = 8
    )

    $confirmCmd = Get-Command -Name 'Read-PsMenuConfirm' -ErrorAction SilentlyContinue
    $confirmMsg = $null
    if ($null -ne $Item.PSObject.Properties['ConfirmMessage']) {
        $confirmMsg = $Item.ConfirmMessage
    }
    if ($null -ne $confirmCmd -and -not [string]::IsNullOrWhiteSpace([string]$confirmMsg)) {
        $ok = & $confirmCmd -Message $confirmMsg
        if (-not $ok) {
            return [pscustomobject]@{ Continue = $true; Result = $null }
        }
    }

    $hasChildren = $false
    if ($null -ne $Item.PSObject.Properties['Children'] -and $null -ne $Item.Children -and @($Item.Children).Count -gt 0) {
        $hasChildren = $true
    }
    $nestedCmd = Get-Command -Name 'Show-PsMenuNested' -ErrorAction SilentlyContinue
    if ($hasChildren -and $null -ne $nestedCmd) {
        $nextDepth = $NestDepth + 1
        if ($nextDepth -gt $MaxNestDepth) {
            # Stay on parent menu; do not open another level
            return [pscustomobject]@{ Continue = $true; Result = $null }
        }
        $nestedResult = & $nestedCmd -ParentMenu $Menu -Item $Item -Theme $ThemeTable -NestDepth $nextDepth -MaxNestDepth $MaxNestDepth
        if ($null -ne $nestedResult -and -not $nestedResult.Cancelled) {
            return [pscustomobject]@{ Continue = $false; Result = $nestedResult }
        }
        # NestedDepthExceeded / EmptyChildren / UserQuit from child → redraw parent
        return [pscustomobject]@{ Continue = $true; Result = $null }
    }

    $result = Complete-PsMenuSelection -Item $Item
    return [pscustomobject]@{ Continue = $false; Result = $result }
}

function Move-PsMenuSelection {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items,

        [Parameter(Mandatory = $true)]
        [int]$CurrentIndex,

        [Parameter(Mandatory = $true)]
        [int]$Delta
    )

    $count = $Items.Count
    if ($count -le 0) { return 0 }

    $index = $CurrentIndex
    $attempts = 0
    do {
        $index = ($index + $Delta) % $count
        if ($index -lt 0) { $index = $count - 1 }
        if (Test-PsMenuItemEnabled -Item $Items[$index]) {
            return $index
        }
        $attempts++
    } while ($attempts -lt $count)

    return $CurrentIndex
}

function Complete-PsMenuSelection {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Item
    )

    $actionResult = Invoke-PsMenuItemAction -Item $Item
    return New-PsMenuResult -Cancelled $false -Reason 'Selected' -ItemId $Item.Id -Label $Item.Label -ActionResult $actionResult -Selections @($Item)
}

function New-PsMenuResult {
    [CmdletBinding()]
    param(
        [bool]$Cancelled = $false,
        [string]$Reason = '',
        [string]$ItemId = $null,
        [string]$Label = $null,
        [object]$ActionResult = $null,
        [object[]]$Selections
    )

    if (-not $PSBoundParameters.ContainsKey('Selections') -or $null -eq $Selections) {
        $Selections = @()
    }

    return [pscustomobject]@{
        PSTypeName   = 'PsMenuKit.MenuResult'
        Cancelled    = $Cancelled
        ItemId       = $ItemId
        Label        = $Label
        ActionResult = $ActionResult
        Reason       = $Reason
        Selections   = @($Selections)
    }
}
