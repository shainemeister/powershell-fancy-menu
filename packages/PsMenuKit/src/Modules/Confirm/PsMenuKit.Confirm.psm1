# PsMenuKit.Confirm - Y/N confirmation prompt (PS 5.1)
# Core calls Read-PsMenuConfirm when an item has ConfirmMessage.

function Read-PsMenuConfirm {
    <#
    .SYNOPSIS
        Prompts the user for Yes/No confirmation.
    .PARAMETER Message
        Question to display.
    .PARAMETER DefaultYes
        When $true, Enter accepts; otherwise Enter declines.
    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [switch]$DefaultYes
    )

    # Sanitize before write so untrusted ConfirmMessage cannot inject controls/ANSI
    $safeMessage = $Message
    $sanitizeCmd = Get-Command -Name 'Get-PsMenuDisplayText' -ErrorAction SilentlyContinue
    if ($null -ne $sanitizeCmd) {
        $safeMessage = & $sanitizeCmd -Text $Message -MaxWidth 4000
    }
    else {
        $safeMessage = [regex]::Replace([string]$Message, '\x1B\[[0-9;?]*[ -/]*[@-~]', '')
        $safeMessage = [regex]::Replace($safeMessage, '\x1B\][^\x07\x1B]*(?:\x07|\x1B\\)?', '')
        $safeMessage = [regex]::Replace($safeMessage, '[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]', '')
        $safeMessage = $safeMessage -replace "[\r\n\t]+", ' '
    }

    Write-Host ''
    Write-Host $safeMessage -ForegroundColor Yellow
    if ($DefaultYes) {
        Write-Host '  [Y]es (default)  /  [N]o  /  Esc=cancel' -ForegroundColor DarkGray
    }
    else {
        Write-Host '  [Y]es  /  [N]o (default)  /  Esc=cancel' -ForegroundColor DarkGray
    }

    while ($true) {
        $keyInfo = $null
        try {
            $keyInfo = [Console]::ReadKey($true)
        }
        catch {
            $raw = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
            $keyInfo = [pscustomobject]@{
                Key     = $raw.VirtualKeyCode
                KeyChar = $raw.Character
            }
        }

        $key = $null
        $keyChar = $null
        if ($keyInfo -is [System.ConsoleKeyInfo]) {
            $key = $keyInfo.Key
            $keyChar = $keyInfo.KeyChar
        }
        else {
            if ($null -ne $keyInfo.Key) {
                $vk = [int]$keyInfo.Key
                if ($vk -eq 13) { $key = [ConsoleKey]::Enter }
                elseif ($vk -eq 27) { $key = [ConsoleKey]::Escape }
            }
            if ($null -ne $keyInfo.KeyChar) {
                $keyChar = $keyInfo.KeyChar
            }
        }

        if ($key -eq [ConsoleKey]::Escape) {
            return $false
        }
        if ($key -eq [ConsoleKey]::Enter -or $keyChar -eq "`r" -or $keyChar -eq "`n") {
            return [bool]$DefaultYes
        }
        if ($null -ne $keyChar) {
            $ch = ([string]$keyChar).ToLowerInvariant()
            if ($ch -eq 'y') { return $true }
            if ($ch -eq 'n') { return $false }
        }
    }
}

Export-ModuleMember -Function @('Read-PsMenuConfirm')
