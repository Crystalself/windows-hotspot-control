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
    title Windows Mobile Hotspot Information
    echo Running Windows Mobile Hotspot Information Script...
    echo.
)

REM Run the PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "%~dp0get-hotspot-info.ps1" %PS_PARAMS%

REM Check if PowerShell execution failed
if %ERRORLEVEL% neq 0 (
    if "%INTERACTIVE%"=="true" (
        echo.
        echo ERROR: PowerShell script execution failed!
        echo Make sure you have Windows 10/11 with Mobile Hotspot support.
        echo.
        pause
    )
    exit /b 1
)

REM Success
exit /b 0 