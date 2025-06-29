# Windows Mobile Hotspot Connected Devices Manager
# Discovers devices connected specifically to the mobile hotspot interface
# Compatible with Windows 10/11

param(
    [switch]$NonInteractive = $false
)

Function Get-HotspotInterface() {
    try {
        # Look for mobile hotspot network adapters
        $hotspotAdapters = Get-NetAdapter | Where-Object { 
            ($_.InterfaceDescription -like "*Microsoft Wi-Fi Direct Virtual Adapter*" -or
             $_.InterfaceDescription -like "*Mobile Hotspot*" -or
             $_.InterfaceDescription -like "*Hosted Network*") -and
            $_.Status -eq "Up"
        }
        
        foreach ($adapter in $hotspotAdapters) {
            # Get IP configuration for this adapter
            $ipConfig = Get-NetIPAddress -InterfaceIndex $adapter.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
            if ($ipConfig) {
                return @{
                    Name = $adapter.Name
                    Description = $adapter.InterfaceDescription
                    InterfaceIndex = $adapter.InterfaceIndex
                    GatewayIP = $ipConfig.IPAddress
                    NetworkPrefix = $ipConfig.IPAddress.Substring(0, $ipConfig.IPAddress.LastIndexOf('.'))
                    PrefixLength = $ipConfig.PrefixLength
                    Found = $true
                }
            }
        }
        
        return @{ Found = $false }
    } catch {
        return @{ Found = $false }
    }
}

Function Get-ARPEntriesForInterface($interfaceIndex) {
    try {
        $arpEntries = @()
        
        # Get ARP table for specific interface
        $arpOutput = arp -a 2>$null
        
        foreach ($line in $arpOutput) {
            if ($line -match '^\s*(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]{17})\s+(\w+)') {
                $arpEntries += [PSCustomObject]@{
                    IPAddress = $matches[1]
                    MACAddress = $matches[2].ToUpper()
                    Type = $matches[3]
                }
            }
        }
        
        return $arpEntries
    } catch {
        Write-Host "Warning: Could not retrieve ARP table." -ForegroundColor Yellow
        return @()
    }
}

Function Get-DeviceHostname($ipAddress) {
    try {
        $hostname = [System.Net.Dns]::GetHostByAddress($ipAddress).HostName
        return $hostname
    } catch {
        try {
            $dnsResult = Resolve-DnsName -Name $ipAddress -Type PTR -ErrorAction SilentlyContinue
            if ($dnsResult -and $dnsResult.NameHost) {
                return $dnsResult.NameHost
            }
        } catch {
            # Silent fail
        }
        return "Unknown"
    }
}

Function Get-DeviceVendor($macAddress) {
    try {
        $oui = $macAddress.Replace("-", "").Replace(":", "").Substring(0, 6).ToUpper()
        
        $vendors = @{
            # Apple devices
            "001122" = "Apple"; "004096" = "Apple"; "0050E4" = "Apple"; "0017F2" = "Apple"
            "001451" = "Apple"; "E85B5B" = "Apple"; "F0B479" = "Apple"; "D4619D" = "Apple"
            "E0F847" = "Apple"; "C82A14" = "Apple"; "7CD1C3" = "Apple"; "A4B197" = "Apple"
            
            # Microsoft devices  
            "00E04C" = "Microsoft"; "000D3A" = "Microsoft"; "7845C4" = "Microsoft"
            "00155D" = "Microsoft"; "001DD8" = "Microsoft"
            
            # Samsung devices
            "002248" = "Samsung"; "001632" = "Samsung"; "0018AF" = "Samsung"; "002566" = "Samsung"
            "30F9ED" = "Samsung"; "E8508B" = "Samsung"; "F0E77E" = "Samsung"; "CC07AB" = "Samsung"
            
            # LG devices
            "001E58" = "LG"; "002622" = "LG"; "00E091" = "LG"
            
            # Dell devices
            "001A8A" = "Dell"; "000476" = "Dell"; "001E4F" = "Dell"; "002564" = "Dell"
            "B499BA" = "Dell"; "D067E5" = "Dell"
            
            # Intel network adapters
            "001B21" = "Intel"; "001CC0" = "Intel"; "0015FF" = "Intel"; "7085C2" = "Intel"
            "9094E4" = "Intel"; "A0A8CD" = "Intel"
            
            # Google devices
            "F8A9D0" = "Google"; "40B0FA" = "Google"; "54BD79" = "Google"
            
            # Xiaomi devices
            "F8A2D6" = "Xiaomi"; "50EC50" = "Xiaomi"; "74051F" = "Xiaomi"
            
            # VMware (should not appear in hotspot)
            "005056" = "VMware"
        }
        
        if ($vendors.ContainsKey($oui)) {
            return $vendors[$oui]
        }
        
        return "Unknown"
    } catch {
        return "Unknown"
    }
}

Function Test-DeviceConnectivity($ipAddress) {
    try {
        $ping = Test-Connection -ComputerName $ipAddress -Count 1 -Quiet -TimeoutSeconds 3
        return $ping
    } catch {
        return $false
    }
}

Function Get-ConnectedDevices() {
    Write-Host "Scanning for mobile hotspot devices..." -ForegroundColor Cyan
    Write-Host ""
    
    # First, detect the mobile hotspot interface
    $hotspotInterface = Get-HotspotInterface
    
    if (-not $hotspotInterface.Found) {
        Write-Host "Mobile Hotspot interface not found or not active." -ForegroundColor Red
        Write-Host ""
        Write-Host "Please ensure:" -ForegroundColor Yellow
        Write-Host "  - Mobile Hotspot is turned ON" -ForegroundColor White
        Write-Host "  - At least one device is connected" -ForegroundColor White
        Write-Host "  - Windows Mobile Hotspot feature is enabled" -ForegroundColor White
        return @()
    }
    
    Write-Host "Mobile Hotspot detected:" -ForegroundColor Green
    Write-Host "  Network: $($hotspotInterface.NetworkPrefix).* ($($hotspotInterface.GatewayIP))" -ForegroundColor White
    Write-Host "  Interface: $($hotspotInterface.Description)" -ForegroundColor White
    Write-Host ""
    
    # Get ARP table entries for hotspot network
    $allArpOutput = arp -a 2>$null
    $hotspotArpEntries = @()
    
    foreach ($line in $allArpOutput) {
        if ($line -match '^\s*(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]{17})\s+(\w+)') {
            $ip = $matches[1]
            $mac = $matches[2].ToUpper()
            $type = $matches[3]
            
            # Check if this IP is in our hotspot network
            if ($ip.StartsWith($hotspotInterface.NetworkPrefix)) {
                $hotspotArpEntries += [PSCustomObject]@{
                    IP = $ip
                    MAC = $mac
                    Type = $type
                }
            }
        }
    }
    
    if ($hotspotArpEntries.Count -eq 0) {
        Write-Host "No ARP entries found in hotspot network range." -ForegroundColor Yellow
        return @()
    }
    
    # Filter for devices on the hotspot network only
    $connectedDevices = @()
    $networkPrefix = $hotspotInterface.NetworkPrefix
    $gatewayIP = $hotspotInterface.GatewayIP
    
    Write-Host ""
    Write-Host "Analyzing connected devices..." -ForegroundColor Cyan
    
    foreach ($arpEntry in $hotspotArpEntries) {
        $ip = $arpEntry.IP
        $mac = $arpEntry.MAC
        
        # Skip gateway IP and broadcast addresses
        if ($ip -eq $gatewayIP) {
            continue  # Skip gateway
        }
        
        # Skip broadcast addresses (xFF-FF-FF-FF-FF-FF MAC or .255 IP)
        if ($mac -eq "FF-FF-FF-FF-FF-FF" -or $ip.EndsWith(".255")) {
            continue  # Skip broadcast
        }
        
        # Include both dynamic and static entries (devices can appear as either)
        Write-Host "  Discovering: $ip" -ForegroundColor Gray
        
        # Gather detailed device information
        $hostname = Get-DeviceHostname $ip
        $vendor = Get-DeviceVendor $mac
        $isOnline = Test-DeviceConnectivity $ip
        
        # Skip VMware virtual adapters
        if ($vendor -eq "VMware") {
            continue
        }
        
        $device = [PSCustomObject]@{
            IPAddress = $ip
            MACAddress = $mac
            Hostname = $hostname
            Vendor = $vendor
            Status = if ($isOnline) { "Online" } else { "Offline" }
            LastSeen = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $connectedDevices += $device
    }
    
    return $connectedDevices
}

# Modified Get-ConnectedDevices function for non-interactive mode
Function Get-ConnectedDevicesQuiet() {
    # First, detect the mobile hotspot interface
    $hotspotInterface = Get-HotspotInterface
    
    if (-not $hotspotInterface.Found) {
        return @()
    }
    
    # Get ARP table entries for hotspot network
    $allArpOutput = arp -a 2>$null
    $hotspotArpEntries = @()
    
    foreach ($line in $allArpOutput) {
        if ($line -match '^\s*(\d+\.\d+\.\d+\.\d+)\s+([0-9a-f-]{17})\s+(\w+)') {
            $ip = $matches[1]
            $mac = $matches[2].ToUpper()
            $type = $matches[3]
            
            # Check if this IP is in our hotspot network
            if ($ip.StartsWith($hotspotInterface.NetworkPrefix)) {
                $hotspotArpEntries += [PSCustomObject]@{
                    IP = $ip
                    MAC = $mac
                    Type = $type
                }
            }
        }
    }
    
    if ($hotspotArpEntries.Count -eq 0) {
        return @()
    }
    
    # Filter for devices on the hotspot network only
    $connectedDevices = @()
    $networkPrefix = $hotspotInterface.NetworkPrefix
    $gatewayIP = $hotspotInterface.GatewayIP
    
    foreach ($arpEntry in $hotspotArpEntries) {
        $ip = $arpEntry.IP
        $mac = $arpEntry.MAC
        
        # Skip gateway IP and broadcast addresses
        if ($ip -eq $gatewayIP) {
            continue  # Skip gateway
        }
        
        # Skip broadcast addresses (xFF-FF-FF-FF-FF-FF MAC or .255 IP)
        if ($mac -eq "FF-FF-FF-FF-FF-FF" -or $ip.EndsWith(".255")) {
            continue  # Skip broadcast
        }
        
        # Gather detailed device information
        $hostname = Get-DeviceHostname $ip
        $vendor = Get-DeviceVendor $mac
        $isOnline = Test-DeviceConnectivity $ip
        
        # Skip VMware virtual adapters
        if ($vendor -eq "VMware") {
            continue
        }
        
        $device = [PSCustomObject]@{
            IPAddress = $ip
            MACAddress = $mac
            Hostname = $hostname
            Vendor = $vendor
            Status = if ($isOnline) { "Online" } else { "Offline" }
            LastSeen = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $connectedDevices += $device
    }
    
    return $connectedDevices
}

# Main execution
if ($NonInteractive) {
    # Non-interactive mode - output JSON
    try {
        $devices = Get-ConnectedDevicesQuiet
        
        $result = @{
            DeviceCount = $devices.Count
            Devices = $devices
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $result | ConvertTo-Json -Depth 3 -Compress
        exit 0
        
    } catch {
        # Output error as JSON
        $errorResult = @{
            Error = $true
            Message = $_.Exception.Message
            DeviceCount = 0
            Devices = @()
            Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        }
        
        $errorResult | ConvertTo-Json -Compress
        exit 1
    }
} else {
    # Interactive mode - formatted output
    Clear-Host

    Write-Host "=============================================" -ForegroundColor Green
    Write-Host "  Windows Mobile Hotspot - Connected Devices" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
    Write-Host ""

    try {
        $devices = Get-ConnectedDevices
        
        if ($devices.Count -eq 0) {
            Write-Host "No connected devices found." -ForegroundColor Yellow
            Write-Host ""
            Write-Host "Troubleshooting:" -ForegroundColor Cyan
            Write-Host "  - Make sure Mobile Hotspot is enabled and running" -ForegroundColor White
            Write-Host "  - Verify that devices are actually connected to your hotspot" -ForegroundColor White
            Write-Host "  - Wait a few moments after connecting before running this scan" -ForegroundColor White
        } else {
            Write-Host ""
            Write-Host "Found $($devices.Count) connected device$(if ($devices.Count -ne 1) { 's' }):" -ForegroundColor Green
            Write-Host ("=" * 65) -ForegroundColor Green
            
            $deviceNumber = 1
            foreach ($device in $devices) {
                Write-Host ""
                Write-Host " Device #$deviceNumber " -ForegroundColor White -BackgroundColor DarkBlue
                Write-Host "  IP Address : $($device.IPAddress)" -ForegroundColor Cyan
                Write-Host "  MAC Address: $($device.MACAddress)" -ForegroundColor Cyan
                Write-Host "  Hostname   : $($device.Hostname)" -ForegroundColor $(if ($device.Hostname -ne "Unknown") { "Green" } else { "Yellow" })
                Write-Host "  Vendor     : $($device.Vendor)" -ForegroundColor $(if ($device.Vendor -ne "Unknown") { "Green" } else { "Yellow" })
                Write-Host "  Status     : $($device.Status)" -ForegroundColor $(if ($device.Status -eq "Online") { "Green" } else { "Red" })
                Write-Host "  Last Seen  : $($device.LastSeen)" -ForegroundColor Gray
                $deviceNumber++
            }
            
            Write-Host ""
            Write-Host ("=" * 65) -ForegroundColor Green
            Write-Host "Scan completed successfully!" -ForegroundColor Green
        }
        
    } catch {
        Write-Host ""
        Write-Host "Error occurred during scan:" -ForegroundColor Red
        Write-Host "  $($_.Exception.Message)" -ForegroundColor White
        Write-Host ""
        Write-Host "This might be due to:" -ForegroundColor Yellow
        Write-Host "  - Insufficient permissions (try running as Administrator)" -ForegroundColor White
        Write-Host "  - Network adapter issues" -ForegroundColor White
        Write-Host "  - Mobile Hotspot not properly configured" -ForegroundColor White
        exit 1
    }

    exit 0
} 