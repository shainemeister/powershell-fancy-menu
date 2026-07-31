#requires -Version 5.1
$ErrorActionPreference = 'Stop'
$root = if ($PSScriptRoot) { Split-Path -Parent $PSScriptRoot } else { (Get-Location).Path }
$utf8 = New-Object System.Text.UTF8Encoding $false
$count = 0
Get-ChildItem -Path $root -Recurse -Filter *.md | Where-Object { $_.FullName -notmatch '\\\.git\\' } | ForEach-Object {
    $t = [System.IO.File]::ReadAllText($_.FullName)
    # Middle-dot between markdown links was turned into " | "; use " / " instead so tables stay valid.
    $n = $t.Replace(') | [', ') / [')
    if ($n -ne $t) {
        [System.IO.File]::WriteAllText($_.FullName, $n, $utf8)
        $count++
        Write-Host ('FIXED: ' + $_.FullName.Substring($root.Length + 1))
    }
}
Write-Host ('files_fixed=' + $count)
