function Show-PsMenu {
    <#
    .SYNOPSIS
        Runs the interactive menu loop and returns a result object.
    .DESCRIPTION
        Core single-level menu: arrow keys, Enter, Esc/Q, number jump, hotkeys.
        Optional feature modules (Confirm, Nested, Search, MultiSelect) enhance
        behavior when imported and when the menu model uses their properties.
    .PARAMETER Menu
        Menu model from New-PsMenu.
    .PARAMETER Theme
        Optional theme name or hashtable overlay.
    .PARAMETER StatusLine
        Optional status text under the title (Status module may refresh this).
    .PARAMETER ClearOnExit
        Clear the screen when the loop ends (default $true).
    .OUTPUTS
        PsMenuKit.MenuResult
    .EXAMPLE
        $result = Show-PsMenu -Menu $menu
        if (-not $result.Cancelled) { $result.ItemId }
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
    $items = @($Menu.Items)
    if ($items.Count -eq 0) {
        return [pscustomobject]@{
            PSTypeName = 'PsMenuKit.MenuResult'
            Cancelled  = $true
            ItemId     = $null
            Label      = $null
            ActionResult = $null
            Reason     = 'EmptyMenu'
        }
    }

    $selectedIndex = 0
    # Move selection to first enabled item
    for ($i = 0; $i -lt $items.Count; $i++) {
        $en = $true
        if ($null -ne $items[$i].PSObject.Properties['Enabled']) {
            $en = [bool]$items[$i].Enabled
        }
        if ($en) {
            $selectedIndex = $i
            break
        }
    }

    $ui = $Host.UI.RawUI
    $oldTitle = $null
    try {
        $oldTitle = $ui.WindowTitle
        $ui.WindowTitle = $Menu.Title
    }
    catch {
        # Host may not support WindowTitle
    }

    $cursorVisible = $true
    try {
        $cursorVisible = [Console]::CursorVisible
        [Console]::CursorVisible = $false
    }
    catch {
        # Some hosts block CursorVisible
    }

    $finalResult = $null

    try {
        while ($true) {
            Show-PsMenuFrame -Menu $Menu -VisibleItems $items -SelectedIndex $selectedIndex -Theme $themeTable -StatusLine $StatusLine

            $keyInfo = $null
            try {
                $keyInfo = [Console]::ReadKey($true)
            }
            catch {
                # Fallback for hosts where [Console]::ReadKey fails
                $keyInfo = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
                $keyInfo = [pscustomobject]@{
                    Key        = $keyInfo.VirtualKeyCode
                    KeyChar    = $keyInfo.Character
                    Modifiers  = $keyInfo.ControlKeyState
                }
            }

            $key = $null
            $keyChar = $null
            if ($keyInfo -is [System.ConsoleKeyInfo]) {
                $key = $keyInfo.Key
                $keyChar = $keyInfo.KeyChar
            }
            else {
                # Normalized fallback object
                if ($null -ne $keyInfo.PSObject.Properties['Key']) {
                    $vk = [int]$keyInfo.Key
                    # Map common virtual key codes
                    switch ($vk) {
                        38 { $key = [ConsoleKey]::UpArrow }
                        40 { $key = [ConsoleKey]::DownArrow }
                        13 { $key = [ConsoleKey]::Enter }
                        27 { $key = [ConsoleKey]::Escape }
                        default {
                            if ($null -ne $keyInfo.KeyChar -and [char]$keyInfo.KeyChar -ne [char]0) {
                                $keyChar = [char]$keyInfo.KeyChar
                            }
                        }
                    }
                }
                if ($null -eq $keyChar -and $null -ne $keyInfo.PSObject.Properties['KeyChar']) {
                    $keyChar = $keyInfo.KeyChar
                }
            }

            # Quit
            if ($key -eq [ConsoleKey]::Escape -or
                ($null -ne $keyChar -and ($keyChar -eq 'q' -or $keyChar -eq 'Q'))) {
                $finalResult = [pscustomobject]@{
                    PSTypeName   = 'PsMenuKit.MenuResult'
                    Cancelled    = $true
                    ItemId       = $null
                    Label        = $null
                    ActionResult = $null
                    Reason       = 'UserQuit'
                }
                break
            }

            # Navigation
            if ($key -eq [ConsoleKey]::UpArrow) {
                $selectedIndex = Move-PsMenuSelection -Items $items -CurrentIndex $selectedIndex -Delta -1
                continue
            }
            if ($key -eq [ConsoleKey]::DownArrow) {
                $selectedIndex = Move-PsMenuSelection -Items $items -CurrentIndex $selectedIndex -Delta 1
                continue
            }

            # Number jump 1-9
            if ($null -ne $keyChar -and $keyChar -match '^[1-9]$') {
                $num = [int][string]$keyChar
                $target = $num - 1
                if ($target -ge 0 -and $target -lt $items.Count) {
                    $en = $true
                    if ($null -ne $items[$target].PSObject.Properties['Enabled']) {
                        $en = [bool]$items[$target].Enabled
                    }
                    if ($en) {
                        $selectedIndex = $target
                    }
                }
                continue
            }

            # Hotkeys
            if ($null -ne $keyChar -and $keyChar -ne [char]0 -and
                $key -ne [ConsoleKey]::Enter -and
                $keyChar -ne "`r" -and $keyChar -ne "`n") {
                $ch = ([string]$keyChar).ToLowerInvariant()
                for ($i = 0; $i -lt $items.Count; $i++) {
                    $hk = $null
                    if ($null -ne $items[$i].PSObject.Properties['Hotkey'] -and $null -ne $items[$i].Hotkey) {
                        $hk = ([string]$items[$i].Hotkey).ToLowerInvariant()
                    }
                    if ($hk -eq $ch) {
                        $en = $true
                        if ($null -ne $items[$i].PSObject.Properties['Enabled']) {
                            $en = [bool]$items[$i].Enabled
                        }
                        if ($en) {
                            $selectedIndex = $i
                            # Activate on hotkey
                            $finalResult = Complete-PsMenuSelection -Item $items[$i]
                            break
                        }
                    }
                }
                if ($null -ne $finalResult) {
                    break
                }
                continue
            }

            # Activate
            if ($key -eq [ConsoleKey]::Enter -or $keyChar -eq "`r" -or $keyChar -eq "`n") {
                $item = $items[$selectedIndex]
                $en = $true
                if ($null -ne $item.PSObject.Properties['Enabled']) {
                    $en = [bool]$item.Enabled
                }
                if (-not $en) {
                    continue
                }

                # Optional Confirm module hook
                $confirmCmd = Get-Command -Name 'Read-PsMenuConfirm' -ErrorAction SilentlyContinue
                $confirmMsg = $null
                if ($null -ne $item.PSObject.Properties['ConfirmMessage']) {
                    $confirmMsg = $item.ConfirmMessage
                }
                if ($null -ne $confirmCmd -and -not [string]::IsNullOrWhiteSpace([string]$confirmMsg)) {
                    $ok = & $confirmCmd -Message $confirmMsg
                    if (-not $ok) {
                        continue
                    }
                }

                # Optional Nested: Children without Action → return as nested request
                $hasChildren = $false
                if ($null -ne $item.PSObject.Properties['Children'] -and $null -ne $item.Children -and @($item.Children).Count -gt 0) {
                    $hasChildren = $true
                }
                $nestedCmd = Get-Command -Name 'Show-PsMenuNested' -ErrorAction SilentlyContinue
                if ($hasChildren -and $null -ne $nestedCmd) {
                    $nestedResult = & $nestedCmd -ParentMenu $Menu -Item $item -Theme $themeTable
                    if ($null -ne $nestedResult -and -not $nestedResult.Cancelled) {
                        $finalResult = $nestedResult
                        break
                    }
                    # Back from nested → continue parent
                    continue
                }

                $finalResult = Complete-PsMenuSelection -Item $item
                break
            }
        }
    }
    finally {
        try {
            [Console]::CursorVisible = $cursorVisible
        }
        catch { }
        try {
            if ($null -ne $oldTitle) {
                $ui.WindowTitle = $oldTitle
            }
        }
        catch { }

        if ($ClearOnExit) {
            Clear-Host
        }
    }

    if ($null -eq $finalResult) {
        $finalResult = [pscustomobject]@{
            PSTypeName   = 'PsMenuKit.MenuResult'
            Cancelled    = $true
            ItemId       = $null
            Label        = $null
            ActionResult = $null
            Reason       = 'Unknown'
        }
    }

    return $finalResult
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
    if ($count -le 0) {
        return 0
    }

    $index = $CurrentIndex
    $attempts = 0
    do {
        $index = ($index + $Delta) % $count
        if ($index -lt 0) {
            $index = $count - 1
        }
        $en = $true
        if ($null -ne $Items[$index].PSObject.Properties['Enabled']) {
            $en = [bool]$Items[$index].Enabled
        }
        if ($en) {
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
    }
}
