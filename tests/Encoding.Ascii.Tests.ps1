#requires -Version 5.1
<#
.SYNOPSIS
    Fail if scoped source/docs contain non-ASCII characters (Windows console safety).
#>
$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$roots = @(
    (Join-Path $repoRoot 'packages')
    (Join-Path $repoRoot 'demos')
    (Join-Path $repoRoot 'tests')
    (Join-Path $repoRoot 'kit')
    (Join-Path $repoRoot 'tools')
)

$failed = $false
$fileCount = 0
$hitCount = 0

foreach ($root in $roots) {
    if (-not (Test-Path -LiteralPath $root)) { continue }
    Get-ChildItem -Path $root -Recurse -File -Include *.md, *.ps1, *.psm1, *.psd1, *.cmd, *.txt |
        ForEach-Object {
            $fileCount++
            $text = [System.IO.File]::ReadAllText($_.FullName)
            $m = [regex]::Matches($text, '[^\x09\x0A\x0D\x20-\x7E]')
            if ($m.Count -gt 0) {
                $failed = $true
                $hitCount += $m.Count
                Write-Host ("NON-ASCII: {0} ({1} char(s))" -f $_.FullName, $m.Count) -ForegroundColor Red
            }
        }
}

# Root markdown
Get-ChildItem -Path $repoRoot -File -Include README.md, PLAN.md, CHANGELOG.md, LICENSE |
    ForEach-Object {
        $fileCount++
        $text = [System.IO.File]::ReadAllText($_.FullName)
        $m = [regex]::Matches($text, '[^\x09\x0A\x0D\x20-\x7E]')
        if ($m.Count -gt 0) {
            $failed = $true
            $hitCount += $m.Count
            Write-Host ("NON-ASCII: {0} ({1} char(s))" -f $_.FullName, $m.Count) -ForegroundColor Red
        }
    }

# pylintrc without extension
$pyl = Join-Path $repoRoot 'kit\configs\pylintrc'
if (Test-Path -LiteralPath $pyl) {
    $fileCount++
    $text = [System.IO.File]::ReadAllText($pyl)
    $m = [regex]::Matches($text, '[^\x09\x0A\x0D\x20-\x7E]')
    if ($m.Count -gt 0) {
        $failed = $true
        $hitCount += $m.Count
        Write-Host ("NON-ASCII: {0} ({1} char(s))" -f $pyl, $m.Count) -ForegroundColor Red
    }
}

if ($fileCount -eq 0) {
    Write-Host 'No files scanned.' -ForegroundColor Yellow
    exit 1
}

if ($failed) {
    Write-Host ("Encoding.Ascii FAILED ({0} non-ASCII char(s))." -f $hitCount) -ForegroundColor Red
    exit 1
}

Write-Host ("Encoding.Ascii OK ({0} file(s))." -f $fileCount) -ForegroundColor Green
exit 0
