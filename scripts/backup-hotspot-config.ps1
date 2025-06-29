# Windows Mobile Hotspot Configuration Backup
# Saves current hotspot settings to a JSON file for later restoration
# Compatible with Windows 10/11

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$BackupPath = "",
    
    [switch]$NonInteractive = $false
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime

Function Get-TetheringManager() {
    try {
        $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
        if ($connectionProfile) {
            $tetheringManager = [Windows.Networking.NetworkOperators.NetworkOperatorTetheringManager,Windows.Networking.NetworkOperators,ContentType=WindowsRuntime]::CreateFromConnectionProfile($connectionProfile)
            return $tetheringManager
        }
        return $null
    }
    catch {
        return $null
    }
}

Function Get-HotspotStatus() {
    $tetheringManager = Get-TetheringManager
    
    if ($null -eq $tetheringManager) {
        return @{
            Status = "ERROR"
            Message = "Cannot access hotspot functionality"
            ClientCount = 0
        }
    }
    
    try {
        $status = $tetheringManager.TetheringOperationalState
        $clientCount = 0
        
        try {
            $clientCount = $tetheringManager.ClientCount
        } catch {
            # Client count not available
        }
        
        switch ($status) {
            0 { 
                return @{
                    Status = "OFF"
                    Message = "Mobile Hotspot is disabled"
                    ClientCount = 0
                }
            }
            "Off" { 
                return @{
                    Status = "OFF" 
                    Message = "Mobile Hotspot is disabled"
                    ClientCount = 0
                }
            }
            1 { 
                return @{
                    Status = "ON"
                    Message = "Mobile Hotspot is active"
                    ClientCount = $clientCount
                }
            }
            "On" { 
                return @{
                    Status = "ON"
                    Message = "Mobile Hotspot is active" 
                    ClientCount = $clientCount
                }
            }
            "InTransition" { 
                return @{
                    Status = "TRANSITIONING"
                    Message = "Mobile Hotspot is changing state"
                    ClientCount = 0
                }
            }
            default { 
                return @{
                    Status = "UNKNOWN"
                    Message = "Status could not be determined ($status)"
                    ClientCount = 0
                }
            }
        }
    }
    catch {
        return @{
            Status = "ERROR"
            Message = "Failed to get status: $($_.Exception.Message)"
            ClientCount = 0
        }
    }
}

Function Get-HotspotCredentials() {
    try {
        # Try registry decoding first (most reliable)
        $hotspotPath = "HKLM:\SYSTEM\CurrentControlSet\Services\icssvc\Settings"
        
        if (Test-Path $hotspotPath) {
            $regItems = Get-ItemProperty -Path $hotspotPath -ErrorAction SilentlyContinue
            if ($regItems -and $regItems.PrivateConnectionSettings) {
                
                $bytes = $regItems.PrivateConnectionSettings
                
                if ($bytes -is [byte[]] -and $bytes.Length -ge 72) {
                    # Decode SSID (starts at byte 4)
                    $ssid = ""
                    for ($i = 4; $i -lt 68; $i += 2) {
                        if ($bytes[$i] -eq 0) { break }
                        if ($bytes[$i] -ge 32 -and $bytes[$i] -le 126) {
                            $ssid += [char]$bytes[$i]
                        }
                    }
                    
                    # Decode Password (starts at byte 70)
                    $password = ""
                    for ($i = 70; $i -lt 200; $i += 2) {
                        if ($bytes[$i] -eq 0) { break }
                        if ($bytes[$i] -ge 32 -and $bytes[$i] -le 126) {
                            $password += [char]$bytes[$i]
                        }
                    }
                    
                    # Decode Band (byte 200)
                    $band = "2.4GHz"  # default
                    if ($bytes.Length -gt 200) {
                        switch ($bytes[200]) {
                            1 { $band = "2.4GHz" }
                            2 { $band = "5GHz" }    
                            3 { $band = "Auto" }
                        }
                    }
                    
                    if ($ssid -and $password) {
                        return @{
                            SSID = $ssid
                            Password = $password
                            Band = $band
                            Source = "Registry"
                            Success = $true
                        }
                    }
                }
            }
        }
        
        # Try Windows Runtime API as backup
        $tetheringManager = Get-TetheringManager
        if ($tetheringManager) {
            try {
                $config = $tetheringManager.GetCurrentAccessPointConfiguration()
                if ($config -and $config.Ssid -and $config.Passphrase) {
                    $band = switch ($config.Band) {
                        "TwoPointFourGigahertz" { "2.4GHz" }
                        "FiveGigahertz" { "5GHz" }
                        "Auto" { "Auto" }
                        default { "2.4GHz" }
                    }
                    
                    return @{
                        SSID = $config.Ssid
                        Password = $config.Passphrase
                        Band = $band
                        Source = "Windows Runtime API"
                        Success = $true
                    }
                }
            } catch {
                # Fall through to error case
            }
        }

        return @{
            SSID = "Unknown"
            Password = "Unknown"
            Band = "Unknown"
            Source = "Unable to read"
            Success = $false
        }
        
    }
    catch {
        return @{
            SSID = "Error"
            Password = "Error"  
            Band = "Error"
            Source = "Exception: $($_.Exception.Message)"
            Success = $false
        }
    }
}

Function Create-BackupConfig($credentials, $status) {
    $currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $computerName = $env:COMPUTERNAME
    $userName = $env:USERNAME
    $osVersion = [System.Environment]::OSVersion.VersionString
    
    $backupConfig = @{
        BackupInfo = @{
            Timestamp = $currentDateTime
            ComputerName = $computerName
            UserName = $userName
            OSVersion = $osVersion
            BackupVersion = "1.0"
        }
        HotspotConfiguration = @{
            SSID = $credentials.SSID
            Password = $credentials.Password
            Band = $credentials.Band
            Source = $credentials.Source
        }
        SystemStatus = @{
            StatusAtBackup = $status.Status
            ClientCountAtBackup = $status.ClientCount
            MessageAtBackup = $status.Message
        }
    }
    
    return $backupConfig
}

# Main execution
if (-not $NonInteractive) {
    Clear-Host
}

if (-not $NonInteractive) {
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host "      Windows Mobile Hotspot Configuration Backup" -ForegroundColor Green
    Write-Host "=================================================" -ForegroundColor Green
    Write-Host ""
}

# Get current hotspot configuration
Write-Host "Reading current hotspot configuration..." -ForegroundColor Cyan
$credentials = Get-HotspotCredentials
$status = Get-HotspotStatus

if (-not $credentials.Success) {
    Write-Host "ERROR: Unable to read hotspot configuration!" -ForegroundColor Red
    Write-Host "Source: $($credentials.Source)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure Mobile Hotspot is configured in Windows Settings" -ForegroundColor White
    Write-Host "2. Try running as Administrator" -ForegroundColor White
    Write-Host "3. Ensure Mobile Hotspot feature is available on your system" -ForegroundColor White
    Write-Host ""
    if (-not $NonInteractive) {
        Write-Host "Press Enter to exit..."
        Read-Host
    }
    exit 1
}

Write-Host "Current Configuration Found:" -ForegroundColor Green
Write-Host "  SSID: '$($credentials.SSID)'" -ForegroundColor White
Write-Host "  Password: '$($credentials.Password)'" -ForegroundColor White
Write-Host "  Band: $($credentials.Band)" -ForegroundColor White
Write-Host "  Source: $($credentials.Source)" -ForegroundColor Gray
Write-Host "  Current Status: $($status.Status)" -ForegroundColor White
Write-Host ""

# Determine backup file path
if ($BackupPath -eq "") {
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $BackupPath = "hotspot-backup-$timestamp.json"
}

# Ensure .json extension
if (-not $BackupPath.EndsWith(".json")) {
    $BackupPath += ".json"
}

Write-Host "Backup file: $BackupPath" -ForegroundColor Cyan
Write-Host ""

# Create backup configuration
$backupConfig = Create-BackupConfig $credentials $status

# Save to JSON file
try {
    $jsonContent = $backupConfig | ConvertTo-Json -Depth 4
    $jsonContent | Out-File -FilePath $BackupPath -Encoding UTF8
    
    Write-Host "SUCCESS: Hotspot configuration backed up!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Backup Details:" -ForegroundColor Yellow
    Write-Host "  File: $BackupPath" -ForegroundColor White
    Write-Host "  Size: $((Get-Item $BackupPath).Length) bytes" -ForegroundColor White
    Write-Host "  Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor White
    Write-Host ""
    Write-Host "To restore this configuration later:" -ForegroundColor Yellow
    Write-Host "  .\restore-hotspot-config.bat `"$BackupPath`"" -ForegroundColor Cyan
    
} catch {
    Write-Host "ERROR: Failed to save backup file!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check if you have write permissions to the current directory" -ForegroundColor White
    Write-Host "2. Ensure the file path is valid" -ForegroundColor White
    Write-Host "3. Check if the file is not in use by another program" -ForegroundColor White
}

Write-Host ""
if (-not $NonInteractive) {
    Write-Host "Press Enter to exit..."
    Read-Host
} 