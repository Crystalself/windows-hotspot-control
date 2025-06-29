# Windows Mobile Hotspot Configuration Restore
# Restores hotspot settings from a JSON backup file
# Compatible with Windows 10/11

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$BackupFile = ""
)

Function Test-AdminPrivileges() {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Function Test-BackupFileValid($filePath) {
    try {
        if (-not (Test-Path $filePath)) {
            Write-Host "ERROR: Backup file not found: $filePath" -ForegroundColor Red
            return $false
        }

        Write-Host "Validating backup file..." -ForegroundColor Cyan
        
        # Read and parse JSON
        $jsonContent = Get-Content -Path $filePath -Raw -Encoding UTF8
        $backupConfig = $jsonContent | ConvertFrom-Json

        # Validate required structure
        if (-not $backupConfig.BackupInfo) {
            Write-Host "ERROR: Invalid backup file - missing BackupInfo section" -ForegroundColor Red
            return $false
        }

        if (-not $backupConfig.HotspotConfiguration) {
            Write-Host "ERROR: Invalid backup file - missing HotspotConfiguration section" -ForegroundColor Red
            return $false
        }

        # Validate hotspot configuration fields
        $config = $backupConfig.HotspotConfiguration
        if (-not $config.SSID -or -not $config.Password) {
            Write-Host "ERROR: Invalid backup file - missing SSID or Password" -ForegroundColor Red
            return $false
        }

        # Validate SSID and Password constraints
        if ($config.SSID.Length -eq 0 -or $config.SSID.Length -gt 32) {
            Write-Host "ERROR: Invalid SSID length in backup (must be 1-32 characters)" -ForegroundColor Red
            return $false
        }

        if ($config.Password.Length -lt 8 -or $config.Password.Length -gt 63) {
            Write-Host "ERROR: Invalid password length in backup (must be 8-63 characters)" -ForegroundColor Red
            return $false
        }

        # Validate band setting
        $validBands = @("2.4GHz", "5GHz", "Auto")
        if ($config.Band -and $config.Band -notin $validBands) {
            Write-Host "WARNING: Unknown band setting '$($config.Band)', will use 2.4GHz" -ForegroundColor Yellow
        }

        Write-Host "Backup file validation successful!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Backup Information:" -ForegroundColor Yellow
        Write-Host "  Created: $($backupConfig.BackupInfo.Timestamp)" -ForegroundColor White
        Write-Host "  Computer: $($backupConfig.BackupInfo.ComputerName)" -ForegroundColor White
        Write-Host "  User: $($backupConfig.BackupInfo.UserName)" -ForegroundColor White
        Write-Host "  OS: $($backupConfig.BackupInfo.OSVersion)" -ForegroundColor White
        Write-Host ""
        Write-Host "Configuration to Restore:" -ForegroundColor Yellow
        Write-Host "  SSID: '$($config.SSID)'" -ForegroundColor White
        Write-Host "  Password: '$($config.Password)'" -ForegroundColor White
        Write-Host "  Band: $($config.Band)" -ForegroundColor White
        Write-Host ""

        return $true
    } catch {
        Write-Host "ERROR: Failed to validate backup file!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "The file may be corrupted or not a valid hotspot backup." -ForegroundColor Yellow
        return $false
    }
}

Function Get-BackupConfiguration($filePath) {
    try {
        $jsonContent = Get-Content -Path $filePath -Raw -Encoding UTF8
        $backupConfig = $jsonContent | ConvertFrom-Json
        return $backupConfig.HotspotConfiguration
    } catch {
        return $null
    }
}

Function Restore-HotspotConfiguration($config, $backupFilePath) {
    try {
        # Determine band parameter
        $band = if ($config.Band -and $config.Band -in @("2.4GHz", "5GHz", "Auto")) { 
            $config.Band 
        } else { 
            "2.4GHz" 
        }

        # Check if we need admin privileges now
        if (-not (Test-AdminPrivileges)) {
            Write-Host "Administrator privileges required to apply hotspot configuration..." -ForegroundColor Yellow
            Write-Host "Requesting elevation..." -ForegroundColor Yellow
            Write-Host ""
            
            # Elevate with current parameters
            $scriptPath = $MyInvocation.ScriptName
            $arguments = "`"$backupFilePath`""
            
            try {
                # Start new elevated process
                $startInfo = New-Object System.Diagnostics.ProcessStartInfo
                $startInfo.FileName = "powershell.exe"
                $startInfo.Arguments = "-ExecutionPolicy Bypass -File `"$scriptPath`" $arguments"
                $startInfo.Verb = "runas"
                $startInfo.UseShellExecute = $true
                
                $process = [System.Diagnostics.Process]::Start($startInfo)
                
                if ($process) {
                    Write-Host "Elevated process started successfully." -ForegroundColor Green
                    Write-Host "This window will close and the elevated process will continue." -ForegroundColor Green
                    exit 0
                } else {
                    throw "Failed to start elevated process"
                }
            } catch {
                Write-Host "ERROR: Failed to elevate privileges!" -ForegroundColor Red
                Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
                Write-Host ""
                Write-Host "Please run this script as Administrator manually:" -ForegroundColor Yellow
                Write-Host "Right-click the batch file and select 'Run as administrator'" -ForegroundColor Yellow
                return $false
            }
        }

        Write-Host "Calling set-hotspot-credentials to apply configuration..." -ForegroundColor Yellow
        
        # Get the path to set-hotspot-credentials.ps1
        $setCredentialsScript = Join-Path $PSScriptRoot "set-hotspot-credentials.ps1"
        
        if (-not (Test-Path $setCredentialsScript)) {
            Write-Host "ERROR: set-hotspot-credentials.ps1 not found!" -ForegroundColor Red
            Write-Host "Expected location: $setCredentialsScript" -ForegroundColor Red
            return $false
        }

        # Execute the set-hotspot-credentials script
        $result = & $setCredentialsScript $config.SSID $config.Password $band
        
        # Check if the script succeeded (assumes it returns appropriate exit codes)
        if ($LASTEXITCODE -eq 0 -or $LASTEXITCODE -eq $null) {
            return $true
        } else {
            Write-Host "ERROR: set-hotspot-credentials script failed with exit code: $LASTEXITCODE" -ForegroundColor Red
            return $false
        }
        
    } catch {
        Write-Host "ERROR: Failed to execute set-hotspot-credentials!" -ForegroundColor Red
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Clear-Host

Write-Host "==================================================" -ForegroundColor Green
Write-Host "      Windows Mobile Hotspot Configuration Restore" -ForegroundColor Green
Write-Host "==================================================" -ForegroundColor Green
Write-Host ""

# Note: Admin privileges will be requested only when needed (before applying changes)

# Validate backup file was provided and exists
if ($BackupFile -eq "" -or -not (Test-Path $BackupFile)) {
    if ($BackupFile -eq "") {
        Write-Host "ERROR: No backup file specified by batch script!" -ForegroundColor Red
        Write-Host "This usually means the batch file couldn't find any backup files." -ForegroundColor Yellow
    } else {
        Write-Host "ERROR: Backup file not found: $BackupFile" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Usage options:" -ForegroundColor Yellow
    Write-Host "1. Specify a backup file: .\restore-hotspot-config.bat `"backup-file.json`"" -ForegroundColor White
    Write-Host "2. Create a backup first: .\backup-hotspot-config.bat" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

Write-Host "Using backup file: $BackupFile" -ForegroundColor Cyan

Write-Host ""

# Validate backup file
if (-not (Test-BackupFileValid $BackupFile)) {
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

# Get configuration from backup
$config = Get-BackupConfiguration $BackupFile
if (-not $config) {
    Write-Host "ERROR: Failed to read configuration from backup file!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

# Confirm restore operation
Write-Host "WARNING: This will change your current hotspot settings!" -ForegroundColor Yellow
Write-Host "Any devices currently connected will be disconnected." -ForegroundColor Yellow
Write-Host ""
Write-Host "Press Enter to continue with restore, or Ctrl+C to cancel..."
Read-Host

# Perform restore
Write-Host "Restoring hotspot configuration..." -ForegroundColor Green
$success = Restore-HotspotConfiguration $config $BackupFile

if ($success) {
    Write-Host ""
    Write-Host "✅ RESTORE COMPLETE: Configuration successfully restored from backup!" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "❌ RESTORE FAILED: Could not restore hotspot configuration!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're running as Administrator" -ForegroundColor White
    Write-Host "2. Check if Mobile Hotspot feature is available on your system" -ForegroundColor White
    Write-Host "3. Try running .\reset-hotspot-service.bat first" -ForegroundColor White
    Write-Host "4. Verify the backup file is not corrupted" -ForegroundColor White
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
} 