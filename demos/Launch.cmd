@echo off
setlocal
title PsMenuKit Demo
cd /d "%~dp0"

REM UTF-8 code page for broader glyph support (font-dependent)
chcp 65001 >nul

REM ============================================================================
REM Enterprise-standard demo launcher (default)
REM ----------------------------------------------------------------------------
REM - Uses -NoProfile (avoid profile-injected code)
REM - Does NOT pass -ExecutionPolicy Bypass
REM - Does NOT permanently change machine ExecutionPolicy
REM - Relies on existing host policy (e.g. RemoteSigned / AllSigned)
REM - Place this package under an IT-approved path (AppLocker/WDAC as applicable)
REM - See packages\PsMenuKit\SECURITY.md
REM - Developer gates (tests\) may use Bypass for CI only - not product install
REM ============================================================================

powershell.exe -NoProfile -File "%~dp0Demo.ps1" %*
set "ERR=%ERRORLEVEL%"

if not "%ERR%"=="0" (
  echo.
  echo Demo exited with code %ERR%.
  echo If scripts are blocked by ExecutionPolicy, use signed scripts or an IT-approved process.
  echo Do not permanently set ExecutionPolicy Unrestricted on enterprise hosts.
  echo See packages\PsMenuKit\SECURITY.md
  pause
)

endlocal & exit /b %ERR%
