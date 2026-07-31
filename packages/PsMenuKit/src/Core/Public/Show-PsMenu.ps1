function Show-PsMenu {
    <#
    .SYNOPSIS
        Runs the interactive menu loop and returns a result object.
    .DESCRIPTION
        Core menu: arrow keys, Enter, Esc/Q, number jump, hotkeys.
        Optional feature modules enhance behavior when imported:
        Confirm, Nested, Search, MultiSelect, Theme, Status.
    .PARAMETER Menu
        Menu model from New-PsMenu.
    .PARAMETER Theme
        Optional theme name or hashtable overlay.
    .PARAMETER StatusLine
        Optional status text under the title (Status module may build this).
    .PARAMETER ClearOnExit
        Clear the screen when the loop ends (default $true).
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
        [bool]$ClearOnExit = $true
    )

    $themeTable = Resolve-PsMenuTheme -Theme $Theme -MenuTheme $Menu.Theme
    $allItems = @($Menu.Items)
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

    $ui = $Host.UI.RawUI
    $oldTitle = $null
    try {
        $oldTitle = $ui.WindowTitle
        $ui.WindowTitle = $Menu.Title
    }
    catch { }

    $cursorVisible = $true
    try {
        $cursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false
    }
    catch { }

    $finalResult = $null

    try {
        while ($true) {
            $visibleItems = Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled
            if ($visibleItems.Count -eq 0) {
                $selectedIndex = 0
            }
            elseif ($selectedIndex -ge $visibleItems.Count) {
                $selectedIndex = Get-PsMenuFirstEnabledIndex -Items $visibleItems
            }

            Show-PsMenuFrame -Menu $Menu -VisibleItems $visibleItems -SelectedIndex $selectedIndex `
                -Theme $themeTable -StatusLine $StatusLine -FilterText $filterText `
                -MultiSelectMode $multiSelectMode -SearchEnabled $searchEnabled

            $keyInfo = Read-PsMenuKey
            $key = $keyInfo.Key
            $keyChar = $keyInfo.KeyChar

            # Quit (Esc always; Q only when not typing a filter that could use q as hotkey-only)
            if ($key -eq [ConsoleKey]::Escape) {
                if ($searchEnabled -and -not [string]::IsNullOrEmpty($filterText)) {
                    $filterText = ''
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                    continue
                }
                $finalResult = New-PsMenuResult -Cancelled $true -Reason 'UserQuit'
                break
            }

            # Navigation
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

            # Backspace clears filter char
            if ($searchEnabled -and ($key -eq [ConsoleKey]::Backspace)) {
                if ($filterText.Length -gt 0) {
                    $filterText = $filterText.Substring(0, $filterText.Length - 1)
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                }
                continue
            }

            # MultiSelect Space toggle
            if ($multiSelectMode -and $key -eq [ConsoleKey]::Spacebar) {
                if ($visibleItems.Count -gt 0 -and $selectedIndex -ge 0 -and $selectedIndex -lt $visibleItems.Count) {
                    $item = $visibleItems[$selectedIndex]
                    $en = Test-PsMenuItemEnabled -Item $item
                    if ($en) {
                        $null = Set-PsMenuItemSelection -Item $item -Toggle
                    }
                }
                continue
            }

            # Activate Enter
            if ($key -eq [ConsoleKey]::Enter -or $keyChar -eq "`r" -or $keyChar -eq "`n") {
                if ($visibleItems.Count -eq 0) {
                    continue
                }

                if ($multiSelectMode) {
                    $selectedItems = @(Get-PsMenuSelectedItems -Items $allItems)
                    if ($selectedItems.Count -eq 0) {
                        # No toggles — activate focused item like single-select
                        $item = $visibleItems[$selectedIndex]
                        if (-not (Test-PsMenuItemEnabled -Item $item)) { continue }
                        $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable
                        if ($act.Continue) { continue }
                        $finalResult = $act.Result
                        break
                    }

                    # Confirm batch if any item has ConfirmMessage
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
                    $finalResult = [pscustomobject]@{
                        PSTypeName   = 'PsMenuKit.MenuResult'
                        Cancelled    = $false
                        ItemId       = ($ids -join ',')
                        Label        = ($labels -join ', ')
                        ActionResult = @($batchResults.ToArray())
                        Reason       = 'MultiSelected'
                        Selections   = @($selectedItems)
                    }
                    break
                }

                $item = $visibleItems[$selectedIndex]
                if (-not (Test-PsMenuItemEnabled -Item $item)) { continue }
                $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable
                if ($act.Continue) { continue }
                $finalResult = $act.Result
                break
            }

            # Printable character handling
            if ($null -ne $keyChar -and $keyChar -ne [char]0 -and
                $key -ne [ConsoleKey]::Enter -and
                $keyChar -ne "`r" -and $keyChar -ne "`n" -and
                -not [char]::IsControl($keyChar)) {

                $ch = ([string]$keyChar)

                # Q quits only when filter empty (and not building filter)
                if (-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) {
                    if ($ch -eq 'q' -or $ch -eq 'Q') {
                        # Prefer hotkey match on 'q' first
                        $hotIdx = Find-PsMenuHotkeyIndex -Items $visibleItems -HotkeyChar $ch
                        if ($hotIdx -ge 0) {
                            $selectedIndex = $hotIdx
                            if (-not $multiSelectMode) {
                                $item = $visibleItems[$selectedIndex]
                                $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable
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

                # Number jump when filter empty
                if ((-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) -and $ch -match '^[1-9]$') {
                    $num = [int]$ch
                    $target = $num - 1
                    if ($target -ge 0 -and $target -lt $visibleItems.Count -and (Test-PsMenuItemEnabled -Item $visibleItems[$target])) {
                        $selectedIndex = $target
                    }
                    continue
                }

                # Hotkeys when filter empty (non-search or empty filter)
                if (-not $searchEnabled -or [string]::IsNullOrEmpty($filterText)) {
                    $hotIdx = Find-PsMenuHotkeyIndex -Items $visibleItems -HotkeyChar $ch
                    if ($hotIdx -ge 0) {
                        $selectedIndex = $hotIdx
                        if (-not $multiSelectMode) {
                            $item = $visibleItems[$selectedIndex]
                            $act = Invoke-PsMenuActivateItem -Menu $Menu -Item $item -ThemeTable $themeTable
                            if (-not $act.Continue) {
                                $finalResult = $act.Result
                                break
                            }
                        }
                        continue
                    }
                }

                # Search: append to filter
                if ($searchEnabled) {
                    $filterText = $filterText + $ch
                    $selectedIndex = Get-PsMenuFirstEnabledIndex -Items (Get-PsMenuVisibleItems -AllItems $allItems -FilterText $filterText -SearchEnabled $searchEnabled)
                    continue
                }
            }
        }
    }
    finally {
        try { [Console]::CursorVisible = $cursorVisible } catch { }
        try {
            if ($null -ne $oldTitle) { $ui.WindowTitle = $oldTitle }
        } catch { }
        if ($ClearOnExit) { Clear-Host }
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
        [hashtable]$ThemeTable
    )

    # Confirm hook
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

    # Nested hook
    $hasChildren = $false
    if ($null -ne $Item.PSObject.Properties['Children'] -and $null -ne $Item.Children -and @($Item.Children).Count -gt 0) {
        $hasChildren = $true
    }
    $nestedCmd = Get-Command -Name 'Show-PsMenuNested' -ErrorAction SilentlyContinue
    if ($hasChildren -and $null -ne $nestedCmd) {
        $nestedResult = & $nestedCmd -ParentMenu $Menu -Item $Item -Theme $ThemeTable
        if ($null -ne $nestedResult -and -not $nestedResult.Cancelled) {
            return [pscustomobject]@{ Continue = $false; Result = $nestedResult }
        }
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
    return [pscustomobject]@{
        PSTypeName   = 'PsMenuKit.MenuResult'
        Cancelled    = $false
        ItemId       = $Item.Id
        Label        = $Item.Label
        ActionResult = $actionResult
        Reason       = 'Selected'
        Selections   = @($Item)
    }
}

function New-PsMenuResult {
    [CmdletBinding()]
    param(
        [bool]$Cancelled = $false,
        [string]$Reason = '',
        [string]$ItemId = $null,
        [string]$Label = $null,
        [object]$ActionResult = $null
    )

    return [pscustomobject]@{
        PSTypeName   = 'PsMenuKit.MenuResult'
        Cancelled    = $Cancelled
        ItemId       = $ItemId
        Label        = $Label
        ActionResult = $ActionResult
        Reason       = $Reason
        Selections   = @()
    }
}
