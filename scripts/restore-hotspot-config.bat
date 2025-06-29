@echo off
setlocal enabledelayedexpansion
title Windows Mobile Hotspot Configuration Restore

echo Windows Mobile Hotspot Configuration Restore
echo =============================================
echo.

REM Check if backup file parameter was provided
if "%~1"=="" (
    echo Usage: %~nx0 [BackupFile]
    echo.
    echo Parameters:
    echo   BackupFile - Optional: Path to backup JSON file
    echo                If not specified, will search for latest backup in current directory
    echo.
    echo Examples:
    echo   %~nx0                                    ^(auto-find latest backup^)
    echo   %~nx0 "hotspot-backup-2024-01-15_14-30-25.json"
    echo   %~nx0 "C:\Backups\my-hotspot-backup.json"
    echo.
    echo This script will:
    echo 1. Find or validate the backup file
    echo 2. Check if backup content is valid
    echo 3. Restore SSID, password, and band settings
    echo 4. Apply changes using set-hotspot-credentials
    echo.
    echo Note: This script requires Administrator privileges!
    echo Connected devices will need to reconnect after restore.
    echo.
    pause
    echo.
    echo Proceeding with auto-detection of latest backup...
    echo.
    
    REM Search for backup files in current directory before elevation
    echo Searching for backup files in current directory...
    set "FOUND_BACKUP="
    set "LATEST_FILE="
    set "LATEST_DATE="
    
    for %%f in (hotspot-backup-*.json) do (
        if exist "%%f" (
            echo Found backup file: %%f
            set "FOUND_BACKUP=1"
            REM Get file date and compare (simple approach - use most recent file)
            for %%d in ("%%f") do (
                if "!LATEST_DATE!"=="" (
                    set "LATEST_FILE=%%f"
                    set "LATEST_DATE=%%~td"
                ) else (
                    REM Compare dates - this is a simplified comparison
                    if "%%~td" GTR "!LATEST_DATE!" (
                        set "LATEST_FILE=%%f"
                        set "LATEST_DATE=%%~td"
                    )
                )
            )
        )
    )
    
    if "!FOUND_BACKUP!"=="" (
        echo.
        echo No backup files found in current directory!
        echo Looking for files matching pattern: hotspot-backup-*.json
        echo.
        echo Usage options:
        echo 1. Specify a backup file: %~nx0 "backup-file.json"
        echo 2. Create a backup first: .\backup-hotspot-config.bat
        echo.
        pause
        exit /b 1
    )
    
    echo.
    echo Found backup files. Using latest: !LATEST_FILE!
    echo.
    
    REM Convert to full path
    set "BACKUP_FILE=%~dp0!LATEST_FILE!"
    
) else (
    REM Use specified backup file
    set "BACKUP_FILE=%~1"
    echo Using specified backup file: %~1
)

REM Run the PowerShell script with the determined backup file
echo Calling PowerShell script with backup file: !BACKUP_FILE!
powershell -ExecutionPolicy Bypass -File "%~dp0restore-hotspot-config.ps1" "!BACKUP_FILE!"

REM Check if PowerShell execution failed
if %ERRORLEVEL% neq 0 (
    echo.
    echo ERROR: PowerShell script execution failed!
    echo.
    echo Possible causes:
    echo - Backup file not found or invalid
    echo - Administrator privileges required
    echo - Mobile Hotspot feature not available
    echo - set-hotspot-credentials.ps1 script missing
    echo.
    pause
    exit /b 1
)

REM Success
echo.
echo Restore operation completed successfully!
pause
exit /b 0 