@echo off
setlocal enabledelayedexpansion

REM Check for non-interactive parameter
set INTERACTIVE=true
set PS_PARAMS=

if /i "%1"=="-NonInteractive" (
    set INTERACTIVE=false
    set PS_PARAMS=-NonInteractive
) else if /i "%1"=="-silent" (
    set INTERACTIVE=false  
    set PS_PARAMS=-NonInteractive
) else if /i "%1"=="-q" (
    set INTERACTIVE=false
    set PS_PARAMS=-NonInteractive
)

if "%INTERACTIVE%"=="true" (
    title Windows Mobile Hotspot - Connected Devices

    echo Windows Mobile Hotspot - Connected Devices
    echo ============================================
    echo.
)

REM Run the PowerShell script
powershell -ExecutionPolicy Bypass -File "%~dp0get-connected-devices.ps1" %PS_PARAMS%

REM Check if PowerShell execution failed
if %ERRORLEVEL% neq 0 (
    if "%INTERACTIVE%"=="true" (
        echo.
        echo ERROR: PowerShell script execution failed!
        echo.
        echo Possible causes:
        echo - Mobile Hotspot not enabled or no devices connected
        echo - PowerShell execution policy restrictions
        echo - Network adapter detection issues
        echo - Insufficient permissions for network queries
        echo.
        pause
    )
    exit /b 1
)

REM Success - script completed normally
exit /b 0 