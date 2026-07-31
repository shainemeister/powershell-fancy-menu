@echo off
setlocal
title PsMenuKit Demo
cd /d "%~dp0"

REM UTF-8 code page for broader glyph support (font-dependent)
chcp 65001 >nul

REM Windows PowerShell 5.1 only (not pwsh)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Demo.ps1" %*
set "ERR=%ERRORLEVEL%"

if not "%ERR%"=="0" (
  echo.
  echo Demo exited with code %ERR%.
  pause
)

endlocal & exit /b %ERR%

REM Optional Windows Terminal launch (uncomment if desired; not required):
REM wt -d "%~dp0" powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Demo.ps1"
