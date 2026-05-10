@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  wos-cleanup.bat  —  single-file launcher
::  Double-click to run.  No extraction needed.
::  Downloads phase scripts from GitHub and runs all phases.
:: ============================================================

:: ── Auto-elevation ───────────────────────────────────────────
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [*] Not running as Administrator. Re-launching elevated ...
    powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%~f0\"' -Verb RunAs"
    exit /b
)

:: ── Config ───────────────────────────────────────────────────
set "REPO=rubenalejandrocalderoncorona/wos-cleanup"
set "BRANCH=main"
set "BASE_URL=https://raw.githubusercontent.com/%REPO%/%BRANCH%/scripts"
set "TMP=%TEMP%\wos-cleanup"

:: ── Banner ───────────────────────────────────────────────────
echo.
echo  ==========================================
echo   WOS-Cleanup -- Windows Optimization Tool
echo  ==========================================
echo.
echo  This will run 3 phases:
echo    Phase 1 - Debloat  : Remove pre-installed bloatware
echo    Phase 2 - Optimize : Disable telemetry, tune services
echo    Phase 3 - Cleanup  : Deep disk clean, caches, WU cache
echo.
echo  A reboot is recommended after all phases complete.
echo.
echo  Press any key to begin, or close this window to cancel.
pause >nul

:: ── Create temp dir ──────────────────────────────────────────
if not exist "%TMP%" mkdir "%TMP%"

:: ── Download scripts ─────────────────────────────────────────
echo.
echo [*] Downloading phase scripts from GitHub ...

powershell -NoProfile -Command ^
    "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; " ^
    "Invoke-WebRequest '%BASE_URL%/phase1_debloat.ps1'  -OutFile '%TMP%\phase1_debloat.ps1'  -UseBasicParsing; " ^
    "Invoke-WebRequest '%BASE_URL%/phase2_optimize.ps1' -OutFile '%TMP%\phase2_optimize.ps1' -UseBasicParsing; " ^
    "Invoke-WebRequest '%BASE_URL%/phase3_cleanup.ps1'  -OutFile '%TMP%\phase3_cleanup.ps1'  -UseBasicParsing"

if %errorlevel% neq 0 (
    echo.
    echo [ERROR] Failed to download scripts. Check your internet connection.
    echo         Make sure GitHub is reachable and try again.
    echo.
    pause
    exit /b 1
)

echo [*] Download complete.

:: ── Phase 1 ──────────────────────────────────────────────────
echo.
echo  ==========================================
echo   Phase 1 of 3 -- Debloat
echo  ==========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TMP%\phase1_debloat.ps1"
echo.
echo [*] Phase 1 complete.

:: ── Phase 2 ──────────────────────────────────────────────────
echo.
echo  ==========================================
echo   Phase 2 of 3 -- Optimize
echo  ==========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TMP%\phase2_optimize.ps1"
echo.
echo [*] Phase 2 complete.

:: ── Phase 3 ──────────────────────────────────────────────────
echo.
echo  ==========================================
echo   Phase 3 of 3 -- Cleanup
echo  ==========================================
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%TMP%\phase3_cleanup.ps1"
echo.
echo [*] Phase 3 complete.

:: ── Done ─────────────────────────────────────────────────────
echo.
echo  ==========================================
echo   All phases complete!
echo   Reboot your system now to apply changes.
echo  ==========================================
echo.

:: Clean up temp scripts
del /q "%TMP%\phase1_debloat.ps1"  2>nul
del /q "%TMP%\phase2_optimize.ps1" 2>nul
del /q "%TMP%\phase3_cleanup.ps1"  2>nul
rmdir "%TMP%" 2>nul

pause
endlocal
