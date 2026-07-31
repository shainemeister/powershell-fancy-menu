# PsMenuKit.Config — load menu models from .psd1 / JSON (PS 5.1)

function Import-PsMenuConfig {
    <#
    .SYNOPSIS
        Loads a menu definition from a .psd1 or .json file.
    .DESCRIPTION
        Data files declare Title, Subtitle, Theme, MultiSelect, and Items.
        Each item may include Id, Label, Hotkey, Enabled, ConfirmMessage,
        Handler (name looked up in -HandlerMap), Children (nested), and Meta.

        Actions are never embedded as arbitrary code from disk. Map Handler
        names to scriptblocks via -HandlerMap for a trusted host app.
    .PARAMETER Path
        Path to .psd1 or .json menu file.
    .PARAMETER HandlerMap
        Hashtable of handler name -> scriptblock.
    .PARAMETER DefaultAction
        Fallback scriptblock when Handler is missing (optional).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [hashtable]$HandlerMap,

        [Parameter(Mandatory = $false)]
        [scriptblock]$DefaultAction
    )

    $newMenuCmd = Get-Command -Name 'New-PsMenu' -ErrorAction SilentlyContinue
    $newItemCmd = Get-Command -Name 'New-PsMenuItem' -ErrorAction SilentlyContinue
    if ($null -eq $newMenuCmd -or $null -eq $newItemCmd) {
        throw 'Import-PsMenuConfig requires PsMenuKit.Core (New-PsMenu, New-PsMenuItem).'
    }

    $fullPath = $Path
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        $fullPath = Join-Path -Path (Get-Location).Path -ChildPath $Path
    }
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Menu config not found: $fullPath"
    }

    $ext = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
    $data = $null
    if ($ext -eq '.psd1') {
        $data = Import-PowerShellDataFile -Path $fullPath
    }
    elseif ($ext -eq '.json') {
        $raw = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
        $data = $raw | ConvertFrom-Json
        # Convert PSCustomObject tree to hashtables for uniform access
        $data = ConvertTo-PsMenuHashtable -InputObject $data
    }
    else {
        throw "Unsupported menu config extension: $ext (use .psd1 or .json)"
    }

    if ($null -eq $data) {
        throw "Menu config is empty: $fullPath"
    }

    $title = Get-PsMenuConfigValue -Data $data -Name 'Title'
    if ([string]::IsNullOrWhiteSpace([string]$title)) {
        throw "Menu config missing Title: $fullPath"
    }

    $rawItems = Get-PsMenuConfigValue -Data $data -Name 'Items'
    if ($null -eq $rawItems) {
        $rawItems = @()
    }

    $items = ConvertTo-PsMenuItemModels -RawItems @($rawItems) -HandlerMap $HandlerMap -DefaultAction $DefaultAction -NewItemCommand $newItemCmd

    $params = @{
        Title = [string]$title
        Items = $items
    }
    $subtitle = Get-PsMenuConfigValue -Data $data -Name 'Subtitle'
    if (-not [string]::IsNullOrWhiteSpace([string]$subtitle)) {
        $params['Subtitle'] = [string]$subtitle
    }
    $theme = Get-PsMenuConfigValue -Data $data -Name 'Theme'
    if ($null -ne $theme) {
        $params['Theme'] = $theme
    }
    $multi = Get-PsMenuConfigValue -Data $data -Name 'MultiSelect'
    if ($null -ne $multi) {
        $params['MultiSelect'] = [bool]$multi
    }

    return & $newMenuCmd @params
}

function ConvertTo-PsMenuItemModels {
    [CmdletBinding()]
    param(
        [object[]]$RawItems,
        [hashtable]$HandlerMap,
        [scriptblock]$DefaultAction,
        [System.Management.Automation.CommandInfo]$NewItemCommand
    )

    $list = New-Object System.Collections.Generic.List[object]
    foreach ($raw in @($RawItems)) {
        if ($null -eq $raw) { continue }

        $label = Get-PsMenuConfigValue -Data $raw -Name 'Label'
        if ([string]::IsNullOrWhiteSpace([string]$label)) {
            throw 'Menu item missing Label in config.'
        }

        $itemParams = @{
            Label = [string]$label
        }

        $id = Get-PsMenuConfigValue -Data $raw -Name 'Id'
        if (-not [string]::IsNullOrWhiteSpace([string]$id)) {
            $itemParams['Id'] = [string]$id
        }

        $hotkey = Get-PsMenuConfigValue -Data $raw -Name 'Hotkey'
        if (-not [string]::IsNullOrWhiteSpace([string]$hotkey)) {
            $itemParams['Hotkey'] = [string]$hotkey
        }

        $enabled = Get-PsMenuConfigValue -Data $raw -Name 'Enabled'
        if ($null -ne $enabled) {
            $itemParams['Enabled'] = [bool]$enabled
        }

        $confirm = Get-PsMenuConfigValue -Data $raw -Name 'ConfirmMessage'
        if (-not [string]::IsNullOrWhiteSpace([string]$confirm)) {
            $itemParams['ConfirmMessage'] = [string]$confirm
        }

        $meta = Get-PsMenuConfigValue -Data $raw -Name 'Meta'
        if ($null -ne $meta) {
            if ($meta -is [hashtable]) {
                $itemParams['Meta'] = $meta
            }
            else {
                $itemParams['Meta'] = ConvertTo-PsMenuHashtable -InputObject $meta
            }
        }

        $childrenRaw = Get-PsMenuConfigValue -Data $raw -Name 'Children'
        if ($null -ne $childrenRaw -and @($childrenRaw).Count -gt 0) {
            $itemParams['Children'] = ConvertTo-PsMenuItemModels -RawItems @($childrenRaw) -HandlerMap $HandlerMap -DefaultAction $DefaultAction -NewItemCommand $NewItemCommand
        }

        $handlerName = Get-PsMenuConfigValue -Data $raw -Name 'Handler'
        $action = $null
        if (-not [string]::IsNullOrWhiteSpace([string]$handlerName) -and $null -ne $HandlerMap) {
            $key = [string]$handlerName
            if ($HandlerMap.ContainsKey($key)) {
                $action = $HandlerMap[$key]
            }
        }
        if ($null -eq $action -and $null -ne $DefaultAction) {
            $action = $DefaultAction
        }
        if ($null -ne $action) {
            $itemParams['Action'] = $action
        }

        $list.Add((& $NewItemCommand @itemParams))
    }
    return @($list.ToArray())
}

function Get-PsMenuConfigValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    if ($Data -is [hashtable] -or $Data -is [System.Collections.IDictionary]) {
        if ($Data.ContainsKey($Name)) {
            return $Data[$Name]
        }
        return $null
    }
    if ($null -ne $Data.PSObject.Properties[$Name]) {
        return $Data.$Name
    }
    return $null
}

function ConvertTo-PsMenuHashtable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [AllowNull()]
        [object]$InputObject
    )

    if ($null -eq $InputObject) {
        return $null
    }
    if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.IDictionary]) {
        return $InputObject
    }
    if ($InputObject -is [System.Collections.IEnumerable] -and -not ($InputObject -is [string])) {
        $arr = New-Object System.Collections.Generic.List[object]
        foreach ($el in $InputObject) {
            $arr.Add((ConvertTo-PsMenuHashtable -InputObject $el))
        }
        return @($arr.ToArray())
    }
    if ($InputObject -is [pscustomobject]) {
        $ht = @{}
        foreach ($prop in $InputObject.PSObject.Properties) {
            $ht[$prop.Name] = ConvertTo-PsMenuHashtable -InputObject $prop.Value
        }
        return $ht
    }
    return $InputObject
}

Export-ModuleMember -Function @('Import-PsMenuConfig')
