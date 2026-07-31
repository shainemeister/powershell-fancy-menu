@echo off
setlocal
title PsMenuKit Consumer App
cd /d "%~dp0"

chcp 65001 >nul

REM Enterprise-standard launcher (no ExecutionPolicy Bypass; no permanent policy change).
REM See packages\PsMenuKit\SECURITY.md and templates\consumer-launch\README.md

powershell.exe -NoProfile -File "%~dp0App.ps1" %*
set "ERR=%ERRORLEVEL%"

if not "%ERR%"=="0" (
  echo.
  echo App exited with code %ERR%.
  echo If scripts are blocked, use signed scripts or an IT-approved process.
  echo Do not permanently set ExecutionPolicy Unrestricted on enterprise hosts.
  pause
)

endlocal & exit /b %ERR%
