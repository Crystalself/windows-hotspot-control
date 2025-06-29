# Windows Mobile Hotspot Service Reset
# This script resets the Internet Connection Sharing service
# Run as Administrator to resolve hotspot service issues

Function Test-AdminPrivileges() {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$currentUser
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host

Write-Host "=============================================" -ForegroundColor Green
Write-Host "    Windows Mobile Hotspot Service Reset" -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor Green
Write-Host ""

# Check for admin privileges
if (-not (Test-AdminPrivileges)) {
    Write-Host "ERROR: Administrator privileges required!" -ForegroundColor Red
    Write-Host ""
    Write-Host "This script must run as Administrator to restart services." -ForegroundColor Yellow
    Write-Host "The batch file will auto-elevate when you run it." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press Enter to exit..."
    Read-Host
    exit 1
}

Write-Host "Resetting Internet Connection Sharing service..." -ForegroundColor Yellow
Write-Host ""

try {
    # Stop the Internet Connection Sharing service
    Write-Host "1. Stopping Internet Connection Sharing service (icssvc)..." -ForegroundColor Cyan
    Stop-Service -Name "icssvc" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    Write-Host "   Service stopped successfully." -ForegroundColor Green
    
    # Start the Internet Connection Sharing service
    Write-Host "2. Starting Internet Connection Sharing service (icssvc)..." -ForegroundColor Cyan
    Start-Service -Name "icssvc" -ErrorAction Stop
    Start-Sleep -Seconds 2
    Write-Host "   Service started successfully." -ForegroundColor Green
    
    Write-Host ""
    Write-Host "SUCCESS: Mobile Hotspot service has been reset!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Try turning your Mobile Hotspot on/off" -ForegroundColor White
    Write-Host "2. Run .\get-hotspot-info.bat to check status" -ForegroundColor White
    Write-Host "3. Use .\enable-hotspot.bat or .\disable-hotspot.bat to control state" -ForegroundColor White
    Write-Host "4. If issues persist, try restarting your computer" -ForegroundColor White
    
} catch {
    Write-Host ""
    Write-Host "ERROR: Failed to reset service!" -ForegroundColor Red
    Write-Host "Error details: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Make sure you're running as Administrator" -ForegroundColor White
    Write-Host "2. Check if Mobile Hotspot feature is available" -ForegroundColor White
    Write-Host "3. Try restarting your computer" -ForegroundColor White
}

Write-Host ""
Write-Host "Press Enter to exit..."
Read-Host 