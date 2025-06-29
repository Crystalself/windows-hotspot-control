@echo off
title Windows Mobile Hotspot Configuration Backup

echo Running Windows Mobile Hotspot Configuration Backup Script...
echo.

REM Check if backup path was provided as parameter
if "%~1"=="" (
    REM No parameter - use default timestamp naming
    powershell -ExecutionPolicy Bypass -File "%~dp0backup-hotspot-config.ps1"
) else (
    REM Parameter provided - use it as backup path
    powershell -ExecutionPolicy Bypass -File "%~dp0backup-hotspot-config.ps1" -BackupPath "%~1"
)

REM Check if PowerShell execution failed
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: PowerShell script execution failed!
    echo Make sure you have Windows 10/11 with Mobile Hotspot support.
    echo.
    pause
    exit /b 1
)

REM Success - no additional pause needed as script handles it
exit /b 0 