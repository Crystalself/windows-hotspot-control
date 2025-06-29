@echo off
title Windows Mobile Hotspot Enabler

REM Check for admin privileges and auto-elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    echo This script may need admin rights for optimal operation.
    echo.
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Running Windows Mobile Hotspot Enabler...
echo Running with Administrator privileges
echo.

REM Run the PowerShell script with execution policy bypass
powershell -ExecutionPolicy Bypass -File "%~dp0enable-hotspot.ps1"

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