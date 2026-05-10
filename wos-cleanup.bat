@echo off
setlocal EnableDelayedExpansion

:: ============================================================
::  wos-cleanup.bat
::  Usage: wos-cleanup.bat phase [1|2|3|all]
::         or via START: start wos-cleanup phase [1|2|3|all]
:: ============================================================

:: ── Argument parsing ────────────────────────────────────────
set "ARG1=%~1"
set "PHASE_NUM="

if /i "%ARG1%"=="/?" goto :USAGE
if /i "%ARG1%"=="-h"  goto :USAGE
if /i "%ARG1%"=="--help" goto :USAGE

if /i "%ARG1%"=="start" (
    :: start wos-cleanup phase 1  ->  %1=start %2=wos-cleanup %3=phase %4=num
    set "PHASE_NUM=%~4"
    goto :VALIDATE
)
if /i "%ARG1%"=="phase" (
    :: wos-cleanup.bat phase 1  ->  %1=phase %2=num
    set "PHASE_NUM=%~2"
    goto :VALIDATE
)

:USAGE
echo.
echo   WOS-Cleanup -- Windows Optimization ^& Sanitization Tool
echo   ----------------------------------------------------------
echo   Usage:
echo     wos-cleanup.bat phase [1^|2^|3^|all]
echo.
echo   Phases:
echo     phase 1    Debloat  : Remove pre-installed bloatware and UWP junk
echo     phase 2    Optimize : Disable telemetry, tweak services and visuals
echo     phase 3    Cleanup  : Deep disk clean, WU cache, DISM component store
echo     phase all  Run all three phases back-to-back (reboots between phases)
echo.
goto :EOF

:VALIDATE
if "%PHASE_NUM%"=="" goto :USAGE
if "%PHASE_NUM%"=="1"   goto :ELEVATE
if "%PHASE_NUM%"=="2"   goto :ELEVATE
if "%PHASE_NUM%"=="3"   goto :ELEVATE
if /i "%PHASE_NUM%"=="all" goto :ELEVATE
echo [ERROR] Unknown phase: "%PHASE_NUM%"
goto :USAGE

:: ── Auto-elevation ──────────────────────────────────────────
:ELEVATE
net session >nul 2>&1
if %errorlevel% == 0 goto :RUN
echo [*] Not running as Administrator. Re-launching elevated ...
powershell -NoProfile -Command "Start-Process cmd -ArgumentList '/c \"%~f0\" phase %PHASE_NUM%' -Verb RunAs"
exit /b

:: ── Dispatch to PowerShell phase script ─────────────────────
:RUN
set "SCRIPT_DIR=%~dp0scripts"

if /i "%PHASE_NUM%"=="all" goto :RUN_ALL

if "%PHASE_NUM%"=="1" set "SCRIPT=%SCRIPT_DIR%\phase1_debloat.ps1"
if "%PHASE_NUM%"=="2" set "SCRIPT=%SCRIPT_DIR%\phase2_optimize.ps1"
if "%PHASE_NUM%"=="3" set "SCRIPT=%SCRIPT_DIR%\phase3_cleanup.ps1"

if not exist "%SCRIPT%" (
    echo [ERROR] Script not found: %SCRIPT%
    exit /b 1
)

echo.
echo [wos-cleanup] Starting Phase %PHASE_NUM% ...
echo [wos-cleanup] Script : %SCRIPT%
echo.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"

echo.
echo [wos-cleanup] Phase %PHASE_NUM% complete. Press any key to exit.
pause >nul
endlocal
goto :EOF

:: ── Run all phases sequentially ──────────────────────────────
:RUN_ALL
echo.
echo [wos-cleanup] Running ALL phases (1 → 2 → 3)
echo [wos-cleanup] Each phase will run to completion.
echo [wos-cleanup] A reboot is recommended between phases for best results.
echo.
echo   Press any key to begin Phase 1 (Debloat) ...
pause >nul

echo.
echo [wos-cleanup] === Phase 1 — Debloat ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\phase1_debloat.ps1"

echo.
echo [wos-cleanup] Phase 1 complete.
echo [wos-cleanup] Recommendation: reboot now, then re-run "wos-cleanup.bat phase 2" manually.
echo [wos-cleanup] OR press any key to continue directly to Phase 2 (skip reboot) ...
pause >nul

echo.
echo [wos-cleanup] === Phase 2 — Optimize ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\phase2_optimize.ps1"

echo.
echo [wos-cleanup] Phase 2 complete.
echo [wos-cleanup] Recommendation: reboot now, then re-run "wos-cleanup.bat phase 3" manually.
echo [wos-cleanup] OR press any key to continue directly to Phase 3 (skip reboot) ...
pause >nul

echo.
echo [wos-cleanup] === Phase 3 — Deep Cleanup ===
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\phase3_cleanup.ps1"

echo.
echo [wos-cleanup] All phases complete.
echo [wos-cleanup] Reboot your system now to apply all changes.
echo.
pause >nul
endlocal
