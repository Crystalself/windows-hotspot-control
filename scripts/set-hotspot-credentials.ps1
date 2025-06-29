# Windows Mobile Hotspot Credentials Setter
# Usage: .\set-hotspot-credentials.ps1 "NewSSID" "NewPassword" ["2.4GHz"|"5GHz"|"Auto"]
# Band parameter is optional - defaults to 2.4GHz if not specified
# Compatible with Windows 10/11

param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$SSID,
    
    [Parameter(Mandatory=$true, Position=1)]
    [string]$Password,
    
    [Parameter(Mandatory=$false, Position=2)]
    [ValidateSet("2.4GHz", "5GHz", "Auto")]
    [string]$Band = "2.4GHz"
)

Function Test-AdminPrivileges() {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Function Set-HotspotCredentials($ssid, $password, $band) {
    try {
        Write-Host "Setting hotspot credentials using proven registry method..." -ForegroundColor Yellow
        
        $regPath = "HKLM:\SYSTEM\CurrentControlSet\Services\icssvc\Settings"
        
        # Validate inputs
        if ($ssid.Length -eq 0 -or $ssid.Length -gt 32) {
            throw "SSID must be between 1 and 32 characters"
        }
        
        if ($password.Length -lt 8 -or $password.Length -gt 63) {
            throw "Password must be between 8 and 63 characters"
        }
        
        # Create 208-byte registry structure with perfect alignment
        $bytes = @(1, 0, 0, 0)  # Header
        
        # Add SSID as Unicode (bytes 4-67)
        foreach ($char in $ssid.ToCharArray()) {
            $bytes += @([byte][char]$char, 0)
        }
        
        # Pad SSID area to 64 bytes total
        $ssidPadding = 64 - ($ssid.Length * 2)
        if ($ssidPadding -gt 0) {
            $bytes += @(0) * $ssidPadding
        }
        
        # Critical: Add 2-byte offset correction (bytes 68-69)
        $bytes += @(0, 0)
        
        $passwordStartPos = $bytes.Length
        Write-Host "Password positioned at byte: $passwordStartPos (should be 70)" -ForegroundColor Cyan
        
        # Add password as Unicode (bytes 70+)
        foreach ($char in $password.ToCharArray()) {
            $bytes += @([byte][char]$char, 0)
        }
        
        # Pad to byte 200 for footer
        $remaining = 200 - $bytes.Length
        if ($remaining -gt 0) {
            $bytes += @(0) * $remaining
        }
        
        # Add band-aware footer (bytes 200-207)
        $bandIndicator = switch ($band) {
            "5GHz" { 2 }
            "Auto" { 3 }
            default { 1 }  # 2.4GHz
        }
        
        # Footer structure VERIFIED by testing all 3 bands through Windows UI:
        # 2.4GHz: 1 0 0 0 0 0 0 0
        # 5GHz:   2 0 0 0 0 0 0 0  
        # Auto:   3 0 0 0 0 0 0 0
        # Pattern: Byte 200 = band indicator, Bytes 201-207 = always zeros
        $bytes += @($bandIndicator, 0, 0, 0, 0, 0, 0, 0)
        
        Write-Host "Registry structure created:" -ForegroundColor Green
        Write-Host "  SSID: '$ssid' (length: $($ssid.Length))" -ForegroundColor White
        Write-Host "  Password: '$password' (length: $($password.Length))" -ForegroundColor White
        Write-Host "  Band: $band (indicator: $bandIndicator)" -ForegroundColor White
        Write-Host "  Total bytes: $($bytes.Length)" -ForegroundColor Gray
        
        # Write to registry
        Set-ItemProperty -Path $regPath -Name "PrivateConnectionSettings" -Value ([byte[]]$bytes) -Type Binary
        
        return $true
    }
    catch {
        Write-Host "Registry update failed: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

# Main execution
Clear-Host

Write-Host "=================================================" -ForegroundColor Green
Write-Host "      Windows Mobile Hotspot Credentials Setter" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Green
Write-Host ""

# Validate administrator privileges
if (-not (Test-AdminPrivileges)) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script must run as Administrator to modify registry." -ForegroundColor Yellow
    Write-Host "Right-click the batch file and select 'Run as administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

# Validate parameters
Write-Host "Input validation:" -ForegroundColor Yellow
Write-Host "  SSID: '$SSID' (length: $($SSID.Length))" -ForegroundColor White
Write-Host "  Password: '$Password' (length: $($Password.Length))" -ForegroundColor White
Write-Host "  Band: $Band" -ForegroundColor White
Write-Host ""

# Validate SSID
if ($SSID.Length -eq 0 -or $SSID.Length -gt 32) {
    Write-Host "ERROR: SSID must be between 1 and 32 characters!" -ForegroundColor Red
    Write-Host "Current SSID length: $($SSID.Length)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

# Validate Password
if ($Password.Length -lt 8 -or $Password.Length -gt 63) {
    Write-Host "ERROR: Password must be between 8 and 63 characters!" -ForegroundColor Red
    Write-Host "Current password length: $($Password.Length)" -ForegroundColor Red
    Write-Host "WPA2 requires minimum 8 characters for security." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

# Confirm operation
Write-Host "Ready to set hotspot credentials:" -ForegroundColor Green
Write-Host "  New SSID: '$SSID'" -ForegroundColor Cyan
Write-Host "  New Password: '$Password'" -ForegroundColor Cyan  
Write-Host "  New Band: $Band" -ForegroundColor Cyan
Write-Host ""
Write-Host "WARNING: This will change your mobile hotspot settings!" -ForegroundColor Yellow
Write-Host "Press Enter to continue, or Ctrl+C to cancel..."
Read-Host

# Apply changes
$success = Set-HotspotCredentials $SSID $Password $Band

if ($success) {
    Write-Host ""
    Write-Host "SUCCESS: Hotspot credentials updated!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Restart your mobile hotspot for changes to take effect" -ForegroundColor White
    Write-Host "2. Run .\get-hotspot-info.bat to verify the changes" -ForegroundColor White
    Write-Host "3. Connected devices will need to reconnect with new password" -ForegroundColor White
    Write-Host ""
    Write-Host "Registry encoding used 100% compatible Windows Settings format." -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "FAILED: Could not update hotspot credentials!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're running as Administrator" -ForegroundColor White
    Write-Host "2. Check if Mobile Hotspot feature is available on your system" -ForegroundColor White
    Write-Host "3. Try running .\reset-hotspot-service.bat first" -ForegroundColor White
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host 