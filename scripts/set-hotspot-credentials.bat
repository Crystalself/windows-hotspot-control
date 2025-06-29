@echo off
title Windows Mobile Hotspot Credentials Setter

REM Check for admin privileges and auto-elevate if needed
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrator privileges...
    echo This script needs admin rights to modify registry settings.
    echo.
    if "%*"=="" (
        powershell -Command "Start-Process '%~f0' -Verb RunAs"
    ) else (
        powershell -Command "Start-Process '%~f0' -ArgumentList '%*' -Verb RunAs"
    )
    exit /b
)

echo Windows Mobile Hotspot Credentials Setter
echo ==========================================
echo Running with Administrator privileges
echo.

REM Check if parameters were provided
if "%~1"=="" (
    echo Usage: %~nx0 "SSID" "Password" [Band]
    echo.
    echo Parameters:
    echo   SSID     - New hotspot name ^(1-32 characters^)
    echo   Password - New hotspot password ^(8-63 characters^)
    echo   Band     - Optional: "2.4GHz", "5GHz", or "Auto" ^(defaults to 2.4GHz^)
    echo.
    echo Examples:
    echo   %~nx0 "MyHotspot" "MyPassword123"
    echo   %~nx0 "MyHotspot" "MyPassword123" "5GHz"
    echo   %~nx0 "MyHotspot" "MyPassword123" "Auto"
    echo.
    echo Note: This script requires Administrator privileges!
    echo It will automatically prompt for elevation when you run it.
    echo.
    pause
    exit /b 1
)

if "%~2"=="" (
    echo ERROR: Password parameter is required!
    echo.
    echo Usage: %~nx0 "SSID" "Password" [Band]
    echo.
    pause
    exit /b 1
)

REM Run the PowerShell script with parameters
if "%~3"=="" (
    echo Running with default 2.4GHz band...
    powershell -ExecutionPolicy Bypass -File "%~dp0set-hotspot-credentials.ps1" "%~1" "%~2"
) else (
    echo Running with %~3 band...
    powershell -ExecutionPolicy Bypass -File "%~dp0set-hotspot-credentials.ps1" "%~1" "%~2" "%~3"
)

REM Check if PowerShell execution failed
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: PowerShell script execution failed!
    echo Make sure you're running as Administrator.
    echo.
    pause
    exit /b 1
)

REM Success
exit /b 0 