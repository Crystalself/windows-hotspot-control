# Windows Mobile Hotspot Enabler
# Uses correct WinRT async operation handling for reliable operation
# Compatible with Windows 10/11

param(
    [switch]$NonInteractive = $false
)

Add-Type -AssemblyName System.Runtime.WindowsRuntime

# Function to properly await WinRT async operations
Function Await-WinRTOperation($WinRtTask, $ResultType) {
    try {
        # Get the AsTask method from WindowsRuntimeSystemExtensions
        $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
            $_.Name -eq 'AsTask' -and 
            $_.GetParameters().Count -eq 1 -and 
            $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
        })[0]
        
        # Convert WinRT async operation to .NET Task
        $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
        $netTask = $asTask.Invoke($null, @($WinRtTask))
        
        # Wait for completion and return result
        $netTask.Wait(-1) | Out-Null
        return $netTask.Result
    }
    catch {
        Write-Host "Error in async operation: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}

Function Test-AdminPrivileges() {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

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

Function Get-CurrentHotspotStatus() {
    $tetheringManager = Get-TetheringManager
    if ($tetheringManager) {
        try {
            return $tetheringManager.TetheringOperationalState
        } catch {
            return "Unknown"
        }
    }
    return "Error"
}

Function Enable-Hotspot() {
    try {
        $tetheringManager = Get-TetheringManager
        
        if (-not $tetheringManager) {
            if (-not $NonInteractive) {
                Write-Host "ERROR: Cannot access hotspot functionality!" -ForegroundColor Red
                Write-Host "Make sure you have an active network connection." -ForegroundColor Yellow
            }
            return $false
        }
        
        # Check current status
        $currentStatus = $tetheringManager.TetheringOperationalState
        
        if ($currentStatus -eq 1 -or $currentStatus -eq "On") {
            if (-not $NonInteractive) {
                Write-Host "Mobile Hotspot is already ON!" -ForegroundColor Green
            }
            return $true
        }
        
        if (-not $NonInteractive) {
            Write-Host "Enabling Mobile Hotspot using proper async handling..." -ForegroundColor Yellow
        }
        
        # Start tethering with proper async handling
        $asyncOperation = $tetheringManager.StartTetheringAsync()
        
        if (-not $NonInteractive) {
            Write-Host "Converting WinRT async operation to .NET Task..." -ForegroundColor Gray
        }
        
        # Properly await the operation
        $result = Await-WinRTOperation -WinRtTask $asyncOperation -ResultType ([Windows.Networking.NetworkOperators.NetworkOperatorTetheringOperationResult])
        
        if ($result) {
            if (-not $NonInteractive) {
                Write-Host "Async operation completed successfully!" -ForegroundColor Green
                Write-Host "Operation Status: $($result.Status)" -ForegroundColor White
                
                if ($result.AdditionalErrorMessage) {
                    Write-Host "Additional Message: $($result.AdditionalErrorMessage)" -ForegroundColor Yellow
                }
            }
            
            switch ($result.Status) {
                "Success" {
                    if (-not $NonInteractive) {
                        Write-Host "SUCCESS: Mobile Hotspot enabled!" -ForegroundColor Green
                    }
                    return $true
                }
                "UnknownError" {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: Unknown error occurred while enabling hotspot." -ForegroundColor Red
                    }
                    return $false
                }
                "MobileBroadbandAccountNotProvisioned" {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: Mobile broadband account not provisioned." -ForegroundColor Red
                    }
                    return $false
                }
                "InternetConnectionUnavailable" {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: Internet connection unavailable." -ForegroundColor Red
                        Write-Host "Make sure you have an active internet connection." -ForegroundColor Yellow
                    }
                    return $false
                }
                "BluetoothRadioOff" {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: Bluetooth radio is off." -ForegroundColor Red
                    }
                    return $false
                }
                "WlanRadioOff" {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: WiFi radio is off." -ForegroundColor Red
                        Write-Host "Please enable WiFi and try again." -ForegroundColor Yellow
                    }
                    return $false
                }
                default {
                    if (-not $NonInteractive) {
                        Write-Host "ERROR: Failed to enable hotspot. Status: $($result.Status)" -ForegroundColor Red
                    }
                    return $false
                }
            }
        } else {
            if (-not $NonInteractive) {
                Write-Host "ERROR: Async operation failed to complete or returned null result." -ForegroundColor Red
                
                # Fallback: Check if hotspot actually got enabled anyway
                Write-Host "Checking actual hotspot status as fallback..." -ForegroundColor Yellow
            }
            Start-Sleep -Seconds 2
            
            $finalStatus = Get-CurrentHotspotStatus
            if ($finalStatus -eq 1 -or $finalStatus -eq "On") {
                if (-not $NonInteractive) {
                    Write-Host "SUCCESS: Mobile Hotspot enabled! (Detected via status check)" -ForegroundColor Green
                }
                return $true
            } else {
                return $false
            }
        }
        
    }
    catch {
        if (-not $NonInteractive) {
            Write-Host "ERROR: Exception occurred: $($_.Exception.Message)" -ForegroundColor Red
        }
        return $false
    }
}

# Main execution
if ($NonInteractive) {
    # Non-interactive mode - output JSON
    try {
        $currentStatus = Get-CurrentHotspotStatus
        $isAdmin = Test-AdminPrivileges
        
        $statusText = switch ($currentStatus) {
            0 { "OFF" }
            "Off" { "OFF" }
            1 { "ON" }
            "On" { "ON" }
            "InTransition" { "IN TRANSITION" }
            default { "UNKNOWN" }
        }
        
        # Attempt to enable hotspot
        $success = Enable-Hotspot
        
        $result = @{
            Success = $success
            PreviousStatus = $statusText
            IsAdmin = $isAdmin
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $result | ConvertTo-Json -Compress
        
        if ($success) {
            exit 0
        } else {
            exit 1
        }
        
    } catch {
        $errorResult = @{
            Success = $false
            Error = $_.Exception.Message
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $errorResult | ConvertTo-Json -Compress
        exit 1
    }
} else {
    # Interactive mode - formatted output
    Clear-Host

    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "      Windows Mobile Hotspot Enabler" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""

    # Check for admin privileges
    if (-not (Test-AdminPrivileges)) {
        Write-Host "WARNING: Not running as Administrator" -ForegroundColor Yellow
        Write-Host "Some operations may require elevated privileges." -ForegroundColor Yellow
        Write-Host ""
    }

    # Check current status
    Write-Host "Checking current hotspot status..." -ForegroundColor Cyan
    $currentStatus = Get-CurrentHotspotStatus

    $statusText = switch ($currentStatus) {
        0 { "OFF" }
        "Off" { "OFF" }
        1 { "ON" }
        "On" { "ON" }
        "InTransition" { "IN TRANSITION" }
        default { "UNKNOWN ($currentStatus)" }
    }

    Write-Host "Current Status: $statusText" -ForegroundColor White
    Write-Host ""

    # Attempt to enable hotspot
    $success = Enable-Hotspot

    if ($success) {
        Write-Host ""
        Write-Host "Mobile Hotspot has been enabled successfully!" -ForegroundColor Green
        Write-Host ""
        Write-Host "Next steps:" -ForegroundColor Yellow
        Write-Host "1. Check connection settings in Windows Settings" -ForegroundColor White
        Write-Host "2. Run .\get-hotspot-info.bat to view current configuration" -ForegroundColor White
        Write-Host "3. Connected devices can now find and connect to your hotspot" -ForegroundColor White
        exit 0
    } else {
        Write-Host ""
        Write-Host "Failed to enable Mobile Hotspot!" -ForegroundColor Red
        Write-Host ""
        Write-Host "Troubleshooting:" -ForegroundColor Yellow
        Write-Host "1. Check if you have an active internet connection" -ForegroundColor White
        Write-Host "2. Make sure WiFi is enabled" -ForegroundColor White
        Write-Host "3. Try running as Administrator" -ForegroundColor White
        Write-Host "4. Check Windows Settings > Network & Internet > Mobile hotspot" -ForegroundColor White
        exit 1
    }

    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
} 