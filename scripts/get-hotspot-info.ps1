# Windows Mobile Hotspot Information Getter
# Returns: Status (ON/OFF), SSID, Password, Band configuration
# Compatible with Windows 10/11

param(
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
        # Try registry decoding first (more reliable for band after manual changes)
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
                    
                    # Decode Band (byte 200) - VERIFIED THROUGH WINDOWS UI TESTING
                    $band = "2.4GHz"  # default
                    if ($bytes.Length -gt 200) {
                        switch ($bytes[200]) {
                            1 { $band = "2.4GHz" }  # ✅ VERIFIED
                            2 { $band = "5GHz" }    # ✅ VERIFIED  
                            3 { $band = "Auto" }    # ✅ VERIFIED
                        }
                    }
                    
                    if ($ssid -and $password) {
                        return @{
                            SSID = $ssid
                            Password = $password
                            Band = $band
                            Source = "Registry Decoding (Preferred)"
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
                        Source = "Windows Runtime API (Backup)"
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
        }
        
    }
    catch {
        return @{
            SSID = "Error"
            Password = "Error"
            Band = "Error"
            Source = "Exception: $($_.Exception.Message)"
        }
    }
}

# Main execution
if (-not $NonInteractive) {
    Clear-Host
}

$currentDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if (-not $NonInteractive) {
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "      Windows Mobile Hotspot Information" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "Retrieved on: $currentDateTime" -ForegroundColor Gray
    Write-Host ""
}

# Get status information
$statusInfo = Get-HotspotStatus

# Get credentials information  
$credInfo = Get-HotspotCredentials

if ($NonInteractive) {
    # Output structured data for programmatic usage
    $result = @{
        Status = $statusInfo.Status
        Message = $statusInfo.Message
        ClientCount = $statusInfo.ClientCount
        SSID = $credInfo.SSID
        Password = $credInfo.Password
        Band = $credInfo.Band
        Source = $credInfo.Source
        Timestamp = $currentDateTime
    }
    
    # Output as JSON for easy parsing
    $result | ConvertTo-Json -Compress
    
    # Set appropriate exit code
    if ($statusInfo.Status -eq "ERROR" -or $credInfo.SSID -eq "Error") {
        exit 1
    } else {
        exit 0
    }
} else {
    # Display formatted results for interactive usage
    Write-Host "STATUS INFORMATION:" -ForegroundColor Yellow
    Write-Host "  Status: $($statusInfo.Status)" -ForegroundColor White
    Write-Host "  Message: $($statusInfo.Message)" -ForegroundColor Gray

    if ($statusInfo.Status -eq "ON") {
        Write-Host "  Connected Devices: $($statusInfo.ClientCount)" -ForegroundColor Cyan
    }

    Write-Host ""
    Write-Host "CREDENTIAL INFORMATION:" -ForegroundColor Yellow
    Write-Host "  SSID: '$($credInfo.SSID)'" -ForegroundColor White
    Write-Host "  Password: '$($credInfo.Password)'" -ForegroundColor White  
    Write-Host "  Band: $($credInfo.Band)" -ForegroundColor White
    Write-Host "  Source: $($credInfo.Source)" -ForegroundColor Gray

    Write-Host ""
    Write-Host "=============================================" -ForegroundColor Green

    # Additional network information if available
    try {
        $connectionProfile = [Windows.Networking.Connectivity.NetworkInformation,Windows.Networking.Connectivity,ContentType=WindowsRuntime]::GetInternetConnectionProfile()
        if ($connectionProfile) {
            $profileName = $connectionProfile.ProfileName
            $connectivityLevel = $connectionProfile.GetNetworkConnectivityLevel()
            
            Write-Host ""
            Write-Host "NETWORK INFORMATION:" -ForegroundColor Yellow
            Write-Host "  Primary Connection: $profileName" -ForegroundColor Gray
            Write-Host "  Connectivity Level: $connectivityLevel" -ForegroundColor Gray
        }
    } catch {
        # Network info not available
    }

    # Keep window open if running directly
    if ($Host.Name -eq "ConsoleHost") {
        Write-Host ""
        Write-Host "Press Enter to exit..."
        Read-Host
    }
    
    # Set appropriate exit code
    if ($statusInfo.Status -eq "ERROR" -or $credInfo.SSID -eq "Error") {
        exit 1
    } else {
        exit 0
    }
} 