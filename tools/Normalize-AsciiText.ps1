#requires -Version 5.1
<#
.SYNOPSIS
    Replace fancy Unicode punctuation with ASCII-safe equivalents (UTF-8 files).
.DESCRIPTION
    One-shot hygiene for Windows console/editor safety. Not a product runtime tool.
#>
[CmdletBinding()]
param(
    [string]$Root,
    [switch]$WhatIf
)

if ([string]::IsNullOrWhiteSpace($Root)) {
    if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $Root = Split-Path -Parent $PSScriptRoot
    }
    else {
        $Root = (Get-Location).Path
    }
}

$ErrorActionPreference = 'Stop'

$include = @('*.md', '*.ps1', '*.psm1', '*.psd1', '*.cmd', '*.txt', '*.gitignore', 'pylintrc', '.pylintrc')
$excludeDirNames = @('.git')

# Ordered replacements: character -> ASCII
$replacements = @(
    @{ From = [char]0x2014; To = ' - ' }   # em dash
    @{ From = [char]0x2013; To = '-' }     # en dash
    @{ From = [char]0x00B7; To = ' | ' }   # middle dot
    @{ From = [char]0x2026; To = '...' }   # ellipsis
    @{ From = [char]0x2192; To = '->' }    # right arrow
    @{ From = [char]0x21D2; To = '=>' }    # double arrow
    @{ From = [char]0x2190; To = '<-' }    # left arrow
    @{ From = [char]0x2018; To = "'" }     # left single quote
    @{ From = [char]0x2019; To = "'" }     # right single quote
    @{ From = [char]0x201C; To = '"' }     # left double quote
    @{ From = [char]0x201D; To = '"' }     # right double quote
    @{ From = [char]0x2715; To = 'x' }     # multiplication X
    @{ From = [char]0x00D7; To = 'x' }     # multiplication sign
    @{ From = [char]0x2265; To = '>=' }    # greater or equal
    @{ From = [char]0x2264; To = '<=' }    # less or equal
    @{ From = [char]0x2260; To = '!=' }    # not equal
    @{ From = [char]0x00A0; To = ' ' }     # nbsp
    @{ From = [char]0x200B; To = '' }      # zero-width space
    @{ From = [char]0x200C; To = '' }      # ZWNJ
    @{ From = [char]0x200D; To = '' }      # ZWJ
    @{ From = [char]0xFEFF; To = '' }      # BOM as char in body
    @{ From = [char]0x00AB; To = '"' }     # guillemet left
    @{ From = [char]0x00BB; To = '"' }     # guillemet right
    @{ From = [char]0x2022; To = '*' }     # bullet
    @{ From = [char]0x00B1; To = '+/-' }   # plus-minus
)

function Get-TextFiles {
    param([string]$Path)
    Get-ChildItem -Path $Path -Recurse -File -Include $include | Where-Object {
        $full = $_.FullName
        foreach ($ex in $excludeDirNames) {
            if ($full -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $ex + [IO.Path]::DirectorySeparatorChar) -or
                $full -match [regex]::Escape([IO.Path]::DirectorySeparatorChar + $ex + '$')) {
                return $false
            }
        }
        # skip this tool's own history noise if any; always process tools
        return $true
    }
}

function ConvertTo-AsciiSafe {
    param([string]$Text)

    $result = $Text
    foreach ($pair in $replacements) {
        $from = [string]$pair.From
        $to = [string]$pair.To
        if ($result.IndexOf($from) -ge 0) {
            $result = $result.Replace($from, $to)
        }
    }

    # Collapse awkward double spaces from " - " replacements next to existing spaces
    while ($result.Contains(' - ')) {
        $result = $result.Replace(' - ', ' - ')
    }
    while ($result.Contains(' | ')) {
        $result = $result.Replace(' | ', ' | ')
    }

    return $result
}

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
$changed = New-Object System.Collections.Generic.List[string]
$scanned = 0

foreach ($file in (Get-TextFiles -Path $Root)) {
    $scanned++
    $bytes = [System.IO.File]::ReadAllBytes($file.FullName)
    # strip UTF-8 BOM if present for read
    $offset = 0
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $offset = 3
    }
    $text = $utf8NoBom.GetString($bytes, $offset, $bytes.Length - $offset)
    $newText = ConvertTo-AsciiSafe -Text $text

    # Final sweep: any remaining non-ASCII printable -> ?
    $sb = New-Object System.Text.StringBuilder
    $hadUnknown = $false
    foreach ($ch in $newText.ToCharArray()) {
        $code = [int]$ch
        if ($code -eq 9 -or $code -eq 10 -or $code -eq 13 -or ($code -ge 32 -and $code -le 126)) {
            [void]$sb.Append($ch)
        }
        else {
            $hadUnknown = $true
            # skip control chars except tab/lf/cr; replace other non-ascii with nothing or ascii approx
            if ($code -gt 126) {
                [void]$sb.Append('?')
            }
        }
    }
    $final = $sb.ToString()
    # Prefer dropping unknown rather than ? spam: if any ?, try empty strip of remaining
    if ($hadUnknown) {
        $final2 = New-Object System.Text.StringBuilder
        foreach ($ch in $newText.ToCharArray()) {
            $code = [int]$ch
            if ($code -eq 9 -or $code -eq 10 -or $code -eq 13 -or ($code -ge 32 -and $code -le 126)) {
                [void]$final2.Append($ch)
            }
            # drop all other
        }
        $final = $final2.ToString()
    }

    if ($final -ne $text) {
        $rel = $file.FullName.Substring($Root.Length).TrimStart('\', '/')
        if ($WhatIf) {
            Write-Host "WOULD UPDATE: $rel"
        }
        else {
            [System.IO.File]::WriteAllText($file.FullName, $final, $utf8NoBom)
            Write-Host "UPDATED: $rel"
        }
        $changed.Add($rel)
    }
}

Write-Host ""
Write-Host ("Scanned: {0}  Changed: {1}" -f $scanned, $changed.Count)
if ($changed.Count -gt 0) {
    exit 0
}
exit 0
