@echo off
setlocal enabledelayedexpansion

REM Windows Mobile Hotspot Manager - Batch Wrapper
REM Provides simple command-line interface to hotspot-manager.ps1
REM Usage: hotspot-manager.bat <command> [options]

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell available'" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: PowerShell is not available or not in PATH
    exit /b 1
)

REM If no arguments provided, show help
if "%1"=="" (
    powershell -ExecutionPolicy Bypass -File "%~dp0hotspot-manager.ps1" help
    exit /b 0
)

REM Pass all arguments to PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0hotspot-manager.ps1" %*

REM Exit with the same code as PowerShell script
exit /b %ERRORLEVEL% 