# Windows Hotspot Control

This repository contains PowerShell scripts to monitor and manage Windows Mobile Hotspot functionality.

## ⚠️ **IMPORTANT: Admin Privileges Required**

**⚡ For best results, always run PowerShell or Command Prompt as Administrator before using these scripts.**

Most hotspot operations (enable, disable, set credentials, restore) require administrator privileges to access Windows system APIs and registry settings. While the scripts will attempt to auto-elevate when needed, starting with admin privileges ensures:
- ✅ **No interruptions** during script execution
- ✅ **Faster operations** (no elevation delays)
- ✅ **Better error handling** and system access
- ✅ **Reliable API access** to Windows Runtime

**To run as Administrator:**
1. Right-click **PowerShell** or **Command Prompt**
2. Select **"Run as administrator"**
3. Navigate to the script directory
4. Execute commands normally

---

## 📋 **Hotspot Manager Command Reference**

The **unified hotspot manager** (`hotspot-manager.ps1`) provides all functionality through a single interface. Here's what each command does with and without admin privileges:

| Command | Purpose | **✅ With Admin Privileges** | **⚠️ Without Admin Privileges** | Notes |
|---------|---------|------------------------------|----------------------------------|-------|
| **`status`** | Get hotspot info & current settings | ✅ **Full access**: Complete status, SSID, password, band, device count via Windows Runtime API | ⚠️ **Limited**: Basic status only, may fall back to registry reading | Read-only operation, works in both modes |
| **`enable`** | Turn ON mobile hotspot | ✅ **SUCCESS**: Hotspot enabled via Windows Runtime API<br/>📱 Returns: `{"Success":true, "Data":{"Status":"ON"}}` | ❌ **FAILS**: Access denied to Windows Runtime<br/>🚫 Returns: `{"Success":false, "Error":"Admin required"}` | **Requires Admin** - Must have system-level access |
| **`disable`** | Turn OFF mobile hotspot | ✅ **SUCCESS**: Hotspot disabled via Windows Runtime API<br/>📱 Returns: `{"Success":true, "Data":{"Status":"OFF"}}` | ❌ **FAILS**: Access denied to Windows Runtime<br/>🚫 Returns: `{"Success":false, "Error":"Admin required"}` | **Requires Admin** - Must have system-level access |
| **`devices`** | List connected devices | ✅ **Enhanced**: Full device detection, ARP table access, hostname resolution<br/>📱 Returns: Device list with IPs, MACs, hostnames, vendors | ⚠️ **Basic**: Limited ARP access, may miss some devices<br/>📱 Returns: Partial device information | Works better with admin for full network access |
| **`set-credentials`** | Update SSID/password/band | ✅ **SUCCESS**: Registry updated, settings applied immediately<br/>📱 Returns: `{"Success":true, "Data":{"SSID":"...", "Band":"..."}}` | ❌ **FAILS**: Registry access denied<br/>🚫 Returns: `{"Success":false, "Error":"Registry access denied"}` | **Requires Admin** - Must write to system registry |
| **`backup`** | Save current config to JSON | ✅ **Complete**: All settings backed up including secure data<br/>📱 Returns: `{"Success":true, "Data":{"BackupFile":"..."}}` | ⚠️ **Partial**: May miss some registry settings<br/>📱 Returns: Basic backup with limited data | Works in both modes, better data with admin |
| **`restore`** | Load config from backup file | ✅ **SUCCESS**: Configuration restored, registry updated<br/>📱 Returns: `{"Success":true, "Message":"Configuration restored"}` | ❌ **FAILS**: Cannot modify registry settings<br/>🚫 Returns: `{"Success":false, "Error":"Admin required"}` | **Requires Admin** - Calls `set-credentials` internally |
| **`reset`** | Restart hotspot service | ✅ **SUCCESS**: Internet Connection Sharing service restarted<br/>📱 Returns: `{"Success":true, "Message":"Service reset"}` | ❌ **FAILS**: Service control access denied<br/>🚫 Returns: `{"Success":false, "Error":"Service access denied"}` | **Requires Admin** - Must control Windows services |
| **`help`** | Show usage documentation | ✅ **Full help**: Complete command reference and examples | ✅ **Full help**: Complete command reference and examples | Documentation only, works in both modes |

### **🎯 Key Takeaways:**
- **📱 JSON Output**: All commands return structured JSON regardless of privilege level
- **🔒 Admin Required**: `enable`, `disable`, `set-credentials`, `restore`, `reset` need admin privileges
- **📊 Enhanced with Admin**: `status`, `devices`, `backup` work better with admin access
- **⚡ No Hanging**: All commands complete immediately with proper JSON responses
- **🛡️ Auto-Elevation**: Individual scripts attempt to request admin when needed (interactive mode only)

---

## Scripts Available

### 1. **get-hotspot-info.ps1** / **get-hotspot-info.bat**
- **Purpose**: Get hotspot status and credentials
- **Functions**: Shows status, SSID, password, band configuration, connected device count
- **Implementation**: Windows Runtime API with registry fallback
- **Usage**: `.\get-hotspot-info.bat`

### 2. **set-hotspot-credentials.ps1** / **set-hotspot-credentials.bat** (Requires Admin)
- **Purpose**: Set hotspot SSID, password, and band configuration
- **Parameters**: SSID (required), password (required), band (optional, defaults to 2.4GHz)
- **Implementation**: Registry modification with Windows-compatible encoding
- **Elevation**: Automatically requests admin privileges via UAC
- **Usage**: 
  ```bash
  # Basic usage (defaults to 2.4GHz)
  .\set-hotspot-credentials.bat "MyHotspot" "MyPassword123"
  
  # With specific band
  .\set-hotspot-credentials.bat "MyHotspot" "MyPassword123" "5GHz"
  .\set-hotspot-credentials.bat "MyHotspot" "MyPassword123" "Auto"
  ```

### 3. **enable-hotspot.ps1** / **enable-hotspot.bat** (Requires Admin)
- **Purpose**: Enable Mobile Hotspot
- **Implementation**: Windows Runtime API with async operation handling
- **Error handling**: Status checking, timeout protection (30s), specific error codes
- **Elevation**: Automatically requests admin privileges via UAC
- **Usage**: `.\enable-hotspot.bat`

### 4. **disable-hotspot.ps1** / **disable-hotspot.bat** (Requires Admin)
- **Purpose**: Disable Mobile Hotspot
- **Implementation**: Windows Runtime API with async operation handling
- **Error handling**: Status checking, timeout protection (30s), specific error codes
- **Elevation**: Automatically requests admin privileges via UAC
- **Usage**: `.\disable-hotspot.bat`

### 5. **reset-hotspot-service.ps1** / **reset-hotspot-service.bat** (Requires Admin)
- **Purpose**: Reset Mobile Hotspot service
- **Implementation**: Stops and restarts Internet Connection Sharing service
- **Elevation**: Automatically requests admin privileges via UAC
- **Usage**: `.\reset-hotspot-service.bat`

### 6. **backup-hotspot-config.ps1** / **backup-hotspot-config.bat**
- **Purpose**: Backup hotspot configuration to JSON file
- **Output**: SSID, password, band settings with timestamps
- **Filename**: Automatic timestamped or custom paths
- **Usage**: 
  ```bash
  # Automatic timestamped backup
  .\backup-hotspot-config.bat
  
  # Custom backup filename
  .\backup-hotspot-config.bat "my-backup.json"
  ```

### 7. **restore-hotspot-config.ps1** / **restore-hotspot-config.bat** (Requires Admin)
- **Purpose**: Restore hotspot configuration from JSON backup
- **Implementation**: Automatic backup detection, delegates to set-hotspot-credentials script
- **Validation**: JSON parsing and backup file verification
- **Elevation**: Automatically requests admin privileges via UAC
- **Usage**: 
  ```bash
  # Automatic - finds most recent valid backup
  .\restore-hotspot-config.bat
  
  # Specify backup file
  .\restore-hotspot-config.bat "my-backup.json"
  ```

### 8. **get-connected-devices.ps1** / **get-connected-devices.bat**
- **Purpose**: List devices connected to mobile hotspot
- **Detection**: Wi-Fi Direct Virtual Adapter identification, ARP table analysis
- **Information**: Hostname resolution, vendor identification, connectivity testing
- **Filtering**: Excludes virtual adapters and broadcast addresses
- **Requirements**: Active hotspot with connected devices
- **Usage**: `.\get-connected-devices.bat`

### 9. **hotspot-manager.ps1** / **hotspot-manager.bat** (Unified Interface)
- **Purpose**: Single command interface for all hotspot operations
- **Commands**: status, enable, disable, devices, set-credentials, backup, restore, reset
- **Output**: Consistent JSON format for programmatic integration
- **Structure**: `hotspot-manager.bat <command> [options]`
- **Compatibility**: PowerShell and batch versions available
- **Usage**: 
  ```bash
  # Basic commands
  .\hotspot-manager.bat status
  .\hotspot-manager.bat enable
  .\hotspot-manager.bat disable
  .\hotspot-manager.bat devices
  
  # Advanced commands
  .\hotspot-manager.bat set-credentials "MyWiFi" "SecurePass123" "5GHz"
  .\hotspot-manager.bat backup
  .\hotspot-manager.bat restore
  
  # Get help
  .\hotspot-manager.bat help
  ```

## 🎯 **Hotspot Manager - Unified Interface**

For maximum simplicity, use the **unified hotspot manager** that provides a single command interface:

### **PowerShell Usage**
```bash
# Check status
powershell -File hotspot-manager.ps1 status

# Enable/disable hotspot
powershell -File hotspot-manager.ps1 enable
powershell -File hotspot-manager.ps1 disable

# Set credentials
powershell -File hotspot-manager.ps1 set-credentials "MyWiFi" "SecurePass123" "5GHz"

# List connected devices
powershell -File hotspot-manager.ps1 devices

# Backup/restore configuration
powershell -File hotspot-manager.ps1 backup
powershell -File hotspot-manager.ps1 restore
```

### **Batch File Usage (Simplified)**
```bash
# Check status
.\hotspot-manager.bat status

# Enable/disable hotspot
.\hotspot-manager.bat enable
.\hotspot-manager.bat disable

# Set credentials
.\hotspot-manager.bat set-credentials "MyWiFi" "SecurePass123" "5GHz"

# List connected devices
.\hotspot-manager.bat devices

# Backup/restore configuration
.\hotspot-manager.bat backup
.\hotspot-manager.bat restore

# Get help
.\hotspot-manager.bat help
```

### **JSON Output for Programming**
All commands return structured JSON perfect for integration:
```json
{
  "Success": true,
  "Operation": "status",
  "Message": "Hotspot status retrieved successfully",
  "Data": {
    "Status": "ON",
    "SSID": "MyWiFi",
    "Password": "SecurePass123",
    "Band": "5GHz",
    "ClientCount": 2
  },
  "Timestamp": "2025-06-29 13:00:00"
}
```

## 🚀 Quick Start Guide

### Check Current Hotspot Status & Credentials
```bash
.\get-hotspot-info.bat
```

### Set New Hotspot Credentials
```bash
# Will automatically prompt for admin privileges
.\set-hotspot-credentials.bat "MyNewHotspot" "SecurePassword123"
```

### With Specific Band
```bash
# Will automatically prompt for admin privileges  
.\set-hotspot-credentials.bat "MyNewHotspot" "SecurePassword123" "5GHz"
```

### Turn Hotspot ON/OFF
```bash
# Turn ON the Mobile Hotspot (will auto-prompt for admin)
.\enable-hotspot.bat

# Turn OFF the Mobile Hotspot (will auto-prompt for admin) 
.\disable-hotspot.bat
```

### Backup and Restore Configuration
```bash
# Create a backup of current settings
.\backup-hotspot-config.bat

# Create backup with custom name
.\backup-hotspot-config.bat "office-settings.json"

# Restore from backup (will auto-prompt for admin)
.\restore-hotspot-config.bat "office-settings.json"

# Interactive restore - shows available backups
.\restore-hotspot-config.bat
```

### Monitor Connected Devices
```bash
# See which devices are connected to your hotspot
.\get-connected-devices.bat
```

## 📋 Example Usage Workflow

```bash
# 1. Check current hotspot information
.\get-hotspot-info.bat

# 2. Set new credentials (will auto-prompt for admin)
.\set-hotspot-credentials.bat "OfficeWiFi" "StrongPassword2024" "Auto"

# 3. Turn ON the hotspot (will auto-prompt for admin)
.\enable-hotspot.bat

# 4. Verify changes applied
.\get-hotspot-info.bat

# 5. Turn OFF the hotspot when done (will auto-prompt for admin) 
.\disable-hotspot.bat

# 6. Create a backup of your working configuration
.\backup-hotspot-config.bat "working-config.json"

# 7. If needed, reset service (will auto-prompt for admin)
.\reset-hotspot-service.bat

# 8. Restore from backup if needed (will auto-prompt for admin)
.\restore-hotspot-config.bat "working-config.json"

# 9. Check which devices are connected to your hotspot
.\get-connected-devices.bat
```

## 🖥️ **Programmatic Integration (RECOMMENDED)**

### **✅ Use Hotspot Manager for Programmatic Access**
For **automation, scripting, and integration** with other applications, **always use the unified hotspot manager**. It provides:
- **Consistent JSON output** for all operations
- **No hanging or user prompts** in programmatic mode
- **Proper error handling** with structured responses
- **Admin privilege management** built-in

### **PowerShell Integration Examples**

#### **Basic Usage**
```powershell
# Get status
$result = .\scripts\hotspot-manager.ps1 status | ConvertFrom-Json
Write-Host "Hotspot Status: $($result.Data.Status)"

# Enable hotspot
$enableResult = .\scripts\hotspot-manager.ps1 enable | ConvertFrom-Json
if ($enableResult.Success) {
    Write-Host "Hotspot enabled successfully"
}

# Set credentials
$credResult = .\scripts\hotspot-manager.ps1 set-credentials "MyWiFi" "Password123" "5GHz" | ConvertFrom-Json
Write-Host "SSID updated to: $($credResult.Data.SSID)"

# Get connected devices
$devices = .\scripts\hotspot-manager.ps1 devices | ConvertFrom-Json
Write-Host "Connected devices: $($devices.Data.DeviceCount)"
```

#### **Advanced Automation Script**
```powershell
# Complete hotspot management workflow
function Manage-Hotspot {
    param($Action, $SSID, $Password)
    
    try {
        # Check current status
        $status = .\scripts\hotspot-manager.ps1 status | ConvertFrom-Json
        Write-Host "Current Status: $($status.Data.Status)"
        
        # Perform action based on parameter
        switch ($Action) {
            "setup" {
                # Set credentials
                $cred = .\scripts\hotspot-manager.ps1 set-credentials $SSID $Password "Auto" | ConvertFrom-Json
                if ($cred.Success) {
                    # Enable hotspot
                    $enable = .\scripts\hotspot-manager.ps1 enable | ConvertFrom-Json
                    return $enable.Success
                }
            }
            "backup" {
                $backup = .\scripts\hotspot-manager.ps1 backup | ConvertFrom-Json
                Write-Host "Backup created: $($backup.Data.BackupFile)"
            }
            "disable" {
                $disable = .\scripts\hotspot-manager.ps1 disable | ConvertFrom-Json
                return $disable.Success
            }
        }
    } catch {
        Write-Error "Hotspot management failed: $($_.Exception.Message)"
        return $false
    }
}

# Usage examples
Manage-Hotspot -Action "setup" -SSID "OfficeWiFi" -Password "SecurePass2024"
Manage-Hotspot -Action "backup"
Manage-Hotspot -Action "disable"
```

### **Python Integration**
```python
import subprocess
import json

def hotspot_command(command, *args):
    """Execute hotspot manager command and return parsed JSON"""
    cmd = ['powershell', '-ExecutionPolicy', 'Bypass', '-File', 
           'scripts/hotspot-manager.ps1', command] + list(args)
    
    result = subprocess.run(cmd, capture_output=True, text=True, cwd='.')
    
    if result.returncode == 0:
        return json.loads(result.stdout)
    else:
        raise Exception(f"Command failed: {result.stderr}")

# Usage examples
status = hotspot_command('status')
print(f"Hotspot Status: {status['Data']['Status']}")

# Set credentials and enable
cred_result = hotspot_command('set-credentials', 'MyWiFi', 'Password123', '5GHz')
if cred_result['Success']:
    enable_result = hotspot_command('enable')
    print(f"Hotspot enabled: {enable_result['Success']}")

# Get devices
devices = hotspot_command('devices')
print(f"Connected devices: {devices['Data']['DeviceCount']}")
```

### **Node.js Integration**
```javascript
const { execSync } = require('child_process');

function hotspotCommand(command, ...args) {
    const cmd = `powershell -ExecutionPolicy Bypass -File scripts/hotspot-manager.ps1 ${command} ${args.join(' ')}`;
    try {
        const result = execSync(cmd, { encoding: 'utf8' });
        return JSON.parse(result);
    } catch (error) {
        throw new Error(`Hotspot command failed: ${error.message}`);
    }
}

// Usage examples
const status = hotspotCommand('status');
console.log(`Hotspot Status: ${status.Data.Status}`);

// Async workflow
async function setupHotspot() {
    try {
        const cred = hotspotCommand('set-credentials', 'MyWiFi', 'Password123', 'Auto');
        if (cred.Success) {
            const enable = hotspotCommand('enable');
            console.log(`Hotspot setup complete: ${enable.Success}`);
        }
    } catch (error) {
        console.error('Setup failed:', error.message);
    }
}
```

### **⚠️ Individual Scripts with NonInteractive Flag**

If you **must use individual scripts** (not recommended for automation), **always include the `-NonInteractive` parameter** to prevent hanging:

```powershell
# ✅ CORRECT - Won't hang
.\scripts\get-hotspot-info.ps1 -NonInteractive
.\scripts\get-connected-devices.ps1 -NonInteractive
.\scripts\set-hotspot-credentials.ps1 "WiFi" "Pass123" "5GHz" -NonInteractive
.\scripts\restore-hotspot-config.ps1 "backup.json" -NonInteractive

# ❌ WRONG - Will hang waiting for user input
.\scripts\get-hotspot-info.ps1
.\scripts\get-connected-devices.ps1
.\scripts\set-hotspot-credentials.ps1 "WiFi" "Pass123" "5GHz"
```

### **JSON Response Structure**
All hotspot manager commands return consistent JSON:
```json
{
  "Success": true,           // Boolean: operation success
  "Operation": "status",     // String: command executed
  "Message": "description",  // String: human-readable result
  "Data": {                  // Object: command-specific data
    "Status": "ON",
    "SSID": "MyWiFi",
    "ClientCount": 2
  },
  "Timestamp": "2025-06-29 15:30:00",  // String: operation time
  "Error": "error message"   // String: only present if Success=false
}
```

### **🎯 Best Practices for Integration**
1. **Always use `hotspot-manager.ps1`** instead of individual scripts
2. **Parse JSON responses** to check `Success` field
3. **Handle errors gracefully** using try-catch blocks
4. **Run with admin privileges** for enable/disable/credentials operations
5. **Use meaningful SSID and password validation** in your applications
6. **Consider backup/restore workflow** for configuration management

## 🔍 Example Output

### Get Hotspot Info:
```
=============================================
      Windows Mobile Hotspot Information
=============================================

STATUS INFORMATION:
  Status: ON
  Message: Mobile Hotspot is active
  Connected Devices: 3

CREDENTIAL INFORMATION:
  SSID: 'MyHotspot'
  Password: 'SecurePassword123'
  Band: Auto
  Source: Windows Runtime API

NETWORK INFORMATION:
  Primary Connection: Ethernet
  Connectivity Level: InternetAccess
```

### Set Hotspot Credentials:
```
=================================================
      Windows Mobile Hotspot Credentials Setter
=================================================

Input validation:
  SSID: 'MyNewHotspot' (length: 12)
  Password: 'SecurePassword123' (length: 17)
  Band: 5GHz

Ready to set hotspot credentials:
  New SSID: 'MyNewHotspot'
  New Password: 'SecurePassword123'
  New Band: 5GHz

SUCCESS: Hotspot credentials updated!
```

### Backup Configuration:
```
=================================================
      Windows Mobile Hotspot Configuration Backup
=================================================

Reading current hotspot configuration...
Current Configuration Found:
  SSID: 'MyHotspot'
  Password: 'SecurePassword123'
  Band: Auto
  Source: Registry
  Current Status: OFF

Backup file: hotspot-backup-2025-06-28_16-38-56.json

SUCCESS: Hotspot configuration backed up!

Backup Details:
  File: hotspot-backup-2025-06-28_16-38-56.json
  Size: 866 bytes
  Timestamp: 2025-06-28 16:38:56

To restore this configuration later:
  .\restore-hotspot-config.bat "hotspot-backup-2025-06-28_16-38-56.json"
```

### Restore Configuration (Automatic Detection):
```
=================================================
      Windows Mobile Hotspot Configuration Restore
=================================================

✅ Found set-hotspot-credentials.ps1

Searching for backup files in current directory...
Found 2 potential backup file(s):
  Checking: test-backup.json - 2025-06-28 17:30:15
  ✅ Valid backup found!

Latest valid backup:
  File: test-backup.json
  Created: 2025-06-28 17:30:15
  Size: 868 bytes
  SSID: 'MyHotspot'
  Band: Auto

AUTO-SELECTED: Using latest valid backup
Do you want to use this backup? (Y/n): y

Reading backup file: test-backup.json

Backup File Information:
  Created: 2025-06-28 17:30:15
  Computer: DESKTOP-EXAMPLE
  User: UserName
  OS Version: Microsoft Windows NT 10.0.26100.0

Configuration to Restore:
  SSID: 'MyHotspot'
  Password: 'SecurePassword123'
  Band: Auto

WARNING: This will replace your current mobile hotspot settings!

Do you want to proceed with the restoration? (y/N): y

Proceeding with restoration using set-hotspot-credentials...

Executing: set-hotspot-credentials.ps1 'MyHotspot' 'SecurePassword123' 'Auto'

=================================================
      Windows Mobile Hotspot Credentials Setter
=================================================

Input validation:
  SSID: 'MyHotspot' (length: 9)
  Password: 'SecurePassword123' (length: 17)
  Band: Auto

Ready to set hotspot credentials:
  New SSID: 'MyHotspot'
  New Password: 'SecurePassword123'
  New Band: Auto

SUCCESS: Hotspot credentials updated!

SUCCESS: Hotspot configuration restored!

Restored Configuration:
  SSID: 'MyHotspot'
  Password: 'SecurePassword123'
  Band: Auto

Next steps:
1. Restart your mobile hotspot for changes to take effect
2. Run .\get-hotspot-info.bat to verify the restoration
3. Connected devices will need to reconnect with the restored password
```

### Connected Devices Manager:
```
=============================================
  Windows Mobile Hotspot - Connected Devices
=============================================

Scanning for mobile hotspot devices...

Mobile Hotspot detected:
  Network: 192.168.137.* (192.168.137.1)
  Interface: Microsoft Wi-Fi Direct Virtual Adapter #2

Analyzing connected devices...

Found 2 connected devices:
=================================================================

 Device #1 
  IP Address : 192.168.137.45
  MAC Address: A4-B1-97-2F-1A-BC
  Hostname   : iPhone-John
  Vendor     : Apple
  Status     : Online
  Last Seen  : 2025-06-29 15:30:45

 Device #2 
  IP Address : 192.168.137.67
  MAC Address: 30-F9-ED-AA-BB-CC
  Hostname   : DESKTOP-WORK
  Vendor     : Samsung
  Status     : Offline
  Last Seen  : 2025-06-29 15:30:47

=================================================================
Scan completed successfully!
```

## Programmatic Usage

All scripts support **non-interactive mode** for integration with other applications:

### JSON Output Mode
```bash
# Get hotspot information as JSON
scripts\get-hotspot-info.bat -NonInteractive
# Output: {"Status":"ON","SSID":"MyHotspot","Password":"123456789","Band":"2.4GHz",...}

# Get connected devices as JSON  
scripts\get-connected-devices.bat -NonInteractive
# Output: {"DeviceCount":2,"Devices":[{"IPAddress":"192.168.137.45","Hostname":"iPhone-John",...}],...}

# Enable/disable hotspot programmatically
powershell -ExecutionPolicy Bypass -File scripts\enable-hotspot.ps1 -NonInteractive
# Output: {"Success":true,"PreviousStatus":"OFF",...}

powershell -ExecutionPolicy Bypass -File scripts\disable-hotspot.ps1 -NonInteractive
# Output: {"Success":true,"PreviousStatus":"ON",...}
```

### Exit Codes
- **0**: Success
- **1**: Error/Failure

### Integration Example (Python)
```python
import subprocess
import json

# Using Unified Hotspot Manager (Recommended)
def hotspot_command(cmd):
    result = subprocess.run(['powershell', '-File', 'scripts/hotspot-manager.ps1', cmd], 
                           capture_output=True, text=True)
    return json.loads(result.stdout), result.returncode

# Get hotspot status
data, code = hotspot_command('status')
if code == 0:
    print(f"Status: {data['Data']['Status']}")
    print(f"SSID: {data['Data']['SSID']}")

# Enable hotspot
data, code = hotspot_command('enable')
if code == 0:
    print("Hotspot enabled successfully!")

# Get connected devices
data, code = hotspot_command('devices')
if code == 0:
    print(f"Found {data['Data']['DeviceCount']} devices")

# Alternative: Using individual scripts
result = subprocess.run(['scripts/get-hotspot-info.bat', '-NonInteractive'], 
                       capture_output=True, text=True)
if result.returncode == 0:
    hotspot_info = json.loads(result.stdout)
    print(f"Status: {hotspot_info['Status']}")
    print(f"SSID: {hotspot_info['SSID']}")
```

### Silent Parameters
- `-NonInteractive`: Full JSON output mode
- `-silent`: Alias for non-interactive
- `-q`: Short alias for non-interactive

## Important Notes

- **Admin privileges**: Scripts automatically prompt for UAC elevation when required
- **Parameter format**: Use quotes around SSID and password containing spaces
- **SSID length**: 1-32 characters maximum
- **Password length**: 8-63 characters (WPA2 requirement)
- **Band options**: "2.4GHz", "5GHz", or "Auto" (case-sensitive)
- **Changes apply**: Restart mobile hotspot after configuration changes
- **Device detection**: Connected devices must generate network traffic to appear in ARP table
- **Non-interactive mode**: JSON output with proper exit codes, no prompts

## Technical Implementation

- **Configuration reading**: Windows Runtime API with registry fallback
- **Configuration writing**: Direct registry modification with 208-byte structure
- **Band support**: Full 2.4GHz/5GHz/Auto configuration
- **Device discovery**: ARP table parsing with Wi-Fi Direct adapter detection
- **Device information**: Hostname resolution and vendor identification via MAC database
- **Connectivity testing**: Ping-based status verification

## Technical Issues and Solutions

### Windows Runtime API Hanging Issue

**Problem**: `StartTetheringAsync()` and `StopTetheringAsync()` methods hang indefinitely in PowerShell
- Operations complete successfully but never signal completion
- Causes 30-second timeouts despite successful execution

**Cause**: PowerShell cannot directly handle Windows Runtime `IAsyncOperation` objects (appear as `System.__ComObject`)

**Solution**: Convert Windows Runtime async operations to .NET Tasks
```powershell
Function Await-WinRTOperation($WinRtTask, $ResultType) {
    $asTaskGeneric = ([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { 
        $_.Name -eq 'AsTask' -and 
        $_.GetParameters().Count -eq 1 -and 
        $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' 
    })[0]
    
    $asTask = $asTaskGeneric.MakeGenericMethod($ResultType)
    $netTask = $asTask.Invoke($null, @($WinRtTask))
    $netTask.Wait(-1) | Out-Null
    return $netTask.Result
}
```

**Result**: Operations complete in 2-6 seconds with proper error handling

## Registry Structure

**Location**: `HKLM:\SYSTEM\CurrentControlSet\Services\icssvc\Settings\PrivateConnectionSettings`

**Format**: 208-byte binary structure

> **⚠️ Important Note**: This registry structure interpretation is based on our own experimental testing and reverse engineering, not official Microsoft documentation. You might find other bytes that serve different configuration purposes or discover variations across different Windows versions.

| Byte Range | Purpose | Format |
|------------|---------|---------|
| 0-3 | Header | Fixed: `1 0 0 0` |
| 4-67 | SSID Area | Unicode + Zero Padding |
| 68-69 | Alignment | Fixed: `0 0` |
| 70-199 | Password Area | Unicode + Zero Padding |
| 200 | Band Setting | 1=2.4GHz, 2=5GHz, 3=Auto |
| 201-207 | Footer | Fixed: `0 0 0 0 0 0 0` |

### Band Configuration

| Setting | Byte 200 Value |
|---------|----------------|
| 2.4GHz | `1` |
| 5GHz | `2` |
| Auto | `3` |

### Alignment Issue

**Problem**: Dynamic SSID lengths caused password misalignment
**Cause**: Windows expects passwords at fixed position (byte 70)
**Solution**: Added 2 padding bytes (68-69) for proper alignment

## Restore Configuration Path Issue

### Problem
`restore-hotspot-config.bat` failed to find backup files after elevation

**Error**: 
```
Searching in directory: C:\Windows\System32
Found 0 files matching hotspot-backup-*.json
```

### Cause
- Batch file elevated immediately to Administrator
- Elevated process changed working directory to `C:\Windows\System32`
- PowerShell script searched wrong location
- Backup files remained in project directory

### Solution Evolution

**Phase 1**: Added `SearchDirectory` parameter to pass original path
- Result: Failed - elevation happened too early

**Phase 2**: Moved file discovery to batch file before elevation
- Added batch file scanning with `for %%f in (hotspot-backup-*.json)`
- Result: Found files but still elevated immediately

**Phase 3**: Delayed elevation (final solution)
- Elevation check moved inside `Restore-HotspotConfiguration` function
- Elevation only occurs after user confirmation

### Final Implementation
- Batch file scans for backups before elevation
- User sees restore preview before admin prompt
- Minimal elevation scope
- Fixed duplicate output messages

## Quick Start

1. Download or clone the repository
2. Navigate to the `scripts` folder
3. Run `.\get-hotspot-info.bat` to see current settings
4. Run `.\set-hotspot-credentials.bat "SSID" "Password" "Band"` (requires admin)
5. Restart mobile hotspot to apply changes

## Repository Structure

```
├── scripts/                          # All executable scripts
│   ├── get-hotspot-info.ps1/.bat     # Get hotspot status and credentials
│   ├── set-hotspot-credentials.ps1/.bat # Set SSID/password/band (requires admin)
│   ├── enable-hotspot.ps1/.bat       # Enable hotspot (requires admin)
│   ├── disable-hotspot.ps1/.bat      # Disable hotspot (requires admin)
│   ├── reset-hotspot-service.ps1/.bat # Reset hotspot service (requires admin)
│   ├── backup-hotspot-config.ps1/.bat # Backup configuration to JSON
│   ├── restore-hotspot-config.ps1/.bat # Restore from JSON backup (requires admin)
│   ├── get-connected-devices.ps1/.bat # List connected devices
│   └── hotspot-manager.ps1/.bat      # Unified interface for all operations
├── docs/                             # Documentation
│   ├── REGISTRY-STRUCTURE.md         # Technical registry details
│   └── windows10-testing-alternatives.txt # Windows 10 fallback methods
├── examples/                         # Example files
│   └── hotspot-backup-*.json         # Sample backup configurations
├── README.md                         # This file
├── CONTRIBUTING.md                   # Contribution guidelines
├── CHANGELOG.md                      # Version history
├── LICENSE                           # MIT License
└── .gitignore                        # Git ignore rules
```

**Requirements**: Windows 10/11 with Mobile Hotspot feature enabled