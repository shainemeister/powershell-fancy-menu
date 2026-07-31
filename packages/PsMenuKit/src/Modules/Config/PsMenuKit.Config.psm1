# PsMenuKit.Config — load menu models from .psd1 / JSON (PS 5.1)
# Security: local filesystem only; Handler names mapped by host; no code-from-file.

function Import-PsMenuConfig {
    <#
    .SYNOPSIS
        Loads a menu definition from a local .psd1 or .json file.
    .DESCRIPTION
        Data files declare Title, Subtitle, Theme, MultiSelect, and Items.
        Each item may include Id, Label, Hotkey, Enabled, ConfirmMessage,
        Handler (name looked up in -HandlerMap), Children (nested), and Meta.

        Actions are never embedded as arbitrary code from disk. Map Handler
        names to scriptblocks via -HandlerMap for a trusted host app.

        Security controls:
        - Local filesystem paths only (rejects http/https/ftp and URL-like paths)
        - Optional -AllowedRoot: resolved path must stay under that directory
        - Extensions .psd1 and .json only
        - Fail closed on missing/invalid files
    .PARAMETER Path
        Path to local .psd1 or .json menu file.
    .PARAMETER HandlerMap
        Hashtable of handler name -> scriptblock (trusted host code).
    .PARAMETER DefaultAction
        Fallback scriptblock when Handler is missing (optional).
    .PARAMETER AllowedRoot
        Optional directory; config path must resolve under this root.
    .PARAMETER AllowUnc
        When set, UNC paths are allowed (still must pass AllowedRoot if set).
        Default is to reject UNC for enterprise-safe defaults.
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
        [scriptblock]$DefaultAction,

        [Parameter(Mandatory = $false)]
        [string]$AllowedRoot,

        [Parameter(Mandatory = $false)]
        [switch]$AllowUnc
    )

    $newMenuCmd = Get-Command -Name 'New-PsMenu' -ErrorAction SilentlyContinue
    $newItemCmd = Get-Command -Name 'New-PsMenuItem' -ErrorAction SilentlyContinue
    if ($null -eq $newMenuCmd -or $null -eq $newItemCmd) {
        throw 'Import-PsMenuConfig requires PsMenuKit.Core (New-PsMenu, New-PsMenuItem).'
    }

    $fullPath = Resolve-PsMenuConfigPath -Path $Path -AllowedRoot $AllowedRoot -AllowUnc:$AllowUnc

    $ext = [System.IO.Path]::GetExtension($fullPath).ToLowerInvariant()
    $data = $null
    if ($ext -eq '.psd1') {
        $data = Import-PowerShellDataFile -Path $fullPath
    }
    elseif ($ext -eq '.json') {
        $raw = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
        $data = $raw | ConvertFrom-Json
        $data = ConvertTo-PsMenuHashtable -InputObject $data
    }
    else {
        throw "Unsupported menu config extension: $ext (use .psd1 or .json)"
    }

    if ($null -eq $data) {
        throw "Menu config is empty: $fullPath"
    }

    # Reject known dangerous keys that would imply code-from-file (fail closed)
    Assert-PsMenuConfigSchema -Data $data

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

function Resolve-PsMenuConfigPath {
    <#
    .SYNOPSIS
        Resolves and validates a local menu config path (security gate).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $false)]
        [string]$AllowedRoot,

        [Parameter(Mandatory = $false)]
        [switch]$AllowUnc
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw 'Menu config path is empty.'
    }

    $trimmed = $Path.Trim()

    # Reject URI / remote schemes early
    if ($trimmed -match '^(?i)(https?|ftp|file):') {
        throw "Remote or URI menu config paths are not allowed: $trimmed"
    }
    if ($trimmed -match '^(?i)[a-z]+://') {
        throw "URI-style menu config paths are not allowed: $trimmed"
    }

    $isUnc = $trimmed.StartsWith('\\')
    if ($isUnc -and -not $AllowUnc) {
        throw "UNC menu config paths are not allowed by default. Use a local path or pass -AllowUnc with IT approval."
    }

    $fullPath = $trimmed
    if (-not [System.IO.Path]::IsPathRooted($fullPath)) {
        $fullPath = Join-Path -Path (Get-Location).Path -ChildPath $fullPath
    }

    # Normalize (resolve .. and .) without requiring the file to exist yet for GetFullPath
    try {
        $fullPath = [System.IO.Path]::GetFullPath($fullPath)
    }
    catch {
        throw "Invalid menu config path: $trimmed"
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "Menu config not found: $fullPath"
    }

    if (-not [string]::IsNullOrWhiteSpace($AllowedRoot)) {
        $rootFull = $AllowedRoot
        if (-not [System.IO.Path]::IsPathRooted($rootFull)) {
            $rootFull = Join-Path -Path (Get-Location).Path -ChildPath $rootFull
        }
        try {
            $rootFull = [System.IO.Path]::GetFullPath($rootFull)
        }
        catch {
            throw "Invalid AllowedRoot path: $AllowedRoot"
        }
        if (-not (Test-Path -LiteralPath $rootFull -PathType Container)) {
            throw "AllowedRoot is not a directory: $rootFull"
        }

        # Ensure trailing separator so prefix check cannot match sibling prefixes
        $rootPrefix = $rootFull.TrimEnd('\') + '\'
        $filePath = $fullPath
        if (-not $filePath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase) -and
            -not ($filePath.Equals($rootFull.TrimEnd('\'), [System.StringComparison]::OrdinalIgnoreCase))) {
            throw "Menu config path is outside AllowedRoot. Path=$fullPath Root=$rootFull"
        }
    }

    return $fullPath
}

function Assert-PsMenuConfigSchema {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Data
    )

    $bannedKeys = @(
        'ActionScript'
        'ScriptBlock'
        'Script'
        'Command'
        'Invoke'
        'Expression'
        'Code'
        'PowerShell'
        'PSCode'
    )

    $queue = New-Object System.Collections.Generic.Queue[object]
    $queue.Enqueue($Data)

    while ($queue.Count -gt 0) {
        $node = $queue.Dequeue()
        if ($null -eq $node) { continue }

        if ($node -is [hashtable] -or $node -is [System.Collections.IDictionary]) {
            foreach ($key in @($node.Keys)) {
                $keyStr = [string]$key
                foreach ($banned in $bannedKeys) {
                    if ($keyStr.Equals($banned, [System.StringComparison]::OrdinalIgnoreCase)) {
                        throw "Menu config contains banned key '$keyStr' (code-from-file is not allowed). Use Handler names + HandlerMap only."
                    }
                }
                $queue.Enqueue($node[$key])
            }
        }
        elseif ($node -is [pscustomobject]) {
            foreach ($prop in $node.PSObject.Properties) {
                $keyStr = [string]$prop.Name
                foreach ($banned in $bannedKeys) {
                    if ($keyStr.Equals($banned, [System.StringComparison]::OrdinalIgnoreCase)) {
                        throw "Menu config contains banned key '$keyStr' (code-from-file is not allowed). Use Handler names + HandlerMap only."
                    }
                }
                $queue.Enqueue($prop.Value)
            }
        }
        elseif ($node -is [System.Collections.IEnumerable] -and -not ($node -is [string])) {
            foreach ($el in $node) {
                $queue.Enqueue($el)
            }
        }
    }
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

        # Per-item ban check for nested structures
        Assert-PsMenuConfigSchema -Data $raw

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
