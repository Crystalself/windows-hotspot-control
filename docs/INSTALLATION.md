# Installation and Setup Guide

This guide will help you get the Windows Hotspot Control scripts up and running on your system.

## System Requirements

### Minimum Requirements
- **Operating System**: Windows 10 (version 1607+) or Windows 11
- **PowerShell**: Version 5.1 or higher
- **Admin Privileges**: Required for hotspot configuration changes
- **Network Adapter**: Wi-Fi adapter that supports hosted network mode

### Recommended Setup
- **PowerShell**: 7.x for best performance (optional)
- **Windows Terminal**: For better command-line experience
- **Git**: For easy updates and version control

## Installation Methods

### Method 1: Download from GitHub (Recommended)

1. **Download the Repository**
   ```bash
   # Option A: Clone with Git
   git clone https://github.com/Crystalself/windows-hotspot-control.git
   cd windows-hotspot-control
   
   # Option B: Download ZIP from GitHub
   # Extract to desired location
   ```

2. **Verify Installation**
   ```powershell
   # Navigate to scripts folder
   cd scripts
   
   # Test basic functionality
   .\get-hotspot-info.bat
   ```

### Method 2: Manual Download

1. Download individual files from the GitHub repository
2. Create this folder structure:
   ```
   your-folder/
   ├── scripts/          # All .ps1 and .bat files
   ├── docs/             # Documentation files
   └── examples/         # Sample configuration files
   ```

## Initial Setup

### 1. PowerShell Execution Policy

Check and set execution policy if needed:
```powershell
# Check current policy
Get-ExecutionPolicy

# If Restricted, set to RemoteSigned (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### 2. Verify Network Adapter Support

```powershell
# Check if your adapter supports hosted network
netsh wlan show drivers

# Look for "Hosted network supported: Yes"
```

### 3. Test Basic Functionality

```bash
# Navigate to scripts directory
cd scripts

# Check current hotspot status
.\get-hotspot-info.bat

# Test unified interface
.\hotspot-manager.bat help
```

## First Time Usage

### Enable Your First Hotspot

1. **Set Credentials** (requires admin)
   ```bash
   .\set-hotspot-credentials.bat "MyHotspot" "SecurePassword123" "2.4GHz"
   ```

2. **Enable Hotspot** (requires admin)
   ```bash
   .\enable-hotspot.bat
   ```

3. **Check Status**
   ```bash
   .\get-hotspot-info.bat
   ```

4. **Find Connected Devices**
   ```bash
   .\get-connected-devices.bat
   ```

### Create Your First Backup

```bash
# Create backup of current configuration
.\backup-hotspot-config.bat

# View created backup
dir ..\examples\hotspot-backup-*.json
```

## Troubleshooting Installation

### Common Issues

**Issue**: "Execution of scripts is disabled on this system"
```powershell
# Solution: Set execution policy
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Issue**: "The hosted network couldn't be started"
```bash
# Solution: Check adapter drivers
netsh wlan show drivers

# Update network adapter drivers if "Hosted network supported: No"
```

**Issue**: Scripts not found
```bash
   # Solution: Verify you're in the correct directory
   Get-Location
   cd path\to\windows-hotspot-control\scripts
```

### Windows 10 Fallback Methods

If the main scripts don't work on your Windows 10 system:

1. Check the fallback guide:
   ```bash
   notepad ..\docs\windows10-testing-alternatives.txt
   ```

2. Try legacy netsh commands:
   ```bash
   netsh wlan show drivers
   netsh wlan set hostednetwork mode=allow ssid="Test" key="12345678"
   netsh wlan start hostednetwork
   ```

## Integration Setup

### For Python Projects

1. **Install subprocess support** (usually built-in)
2. **Test integration**:
   ```python
   import subprocess
   import json
   
   # Test basic functionality
   result = subprocess.run(['scripts/hotspot-manager.bat', 'status'], 
                          capture_output=True, text=True)
   if result.returncode == 0:
       data = json.loads(result.stdout)
       print(f"Hotspot Status: {data['Status']}")
   ```

### For PowerShell Projects

```powershell
# Import functions
. .\scripts\hotspot-manager.ps1

# Use programmatically
$result = scripts\hotspot-manager.ps1 status | ConvertFrom-Json
Write-Host "Status: $($result.Status)"
```

### For Node.js Projects

```javascript
const { execSync } = require('child_process');

try {
    const result = execSync('scripts\\hotspot-manager.bat status', 
                          { encoding: 'utf8' });
    const data = JSON.parse(result);
    console.log(`Hotspot Status: ${data.Status}`);
} catch (error) {
    console.error('Error:', error.message);
}
```

## Updating

### With Git
```bash
# Update to latest version
git pull origin main

# Check what changed
git log --oneline -5
```

### Manual Update
1. Download new files from GitHub
2. Replace existing files in your installation
3. Check CHANGELOG.md for breaking changes

## Uninstallation

1. **Stop any running hotspot**:
   ```bash
   scripts\disable-hotspot.bat
   ```

2. **Remove files**:
   ```bash
   # Simply delete the installation folder
   rmdir /s windows-hotspot-control
   ```

3. **Reset PowerShell policy** (optional):
   ```powershell
   Set-ExecutionPolicy Restricted -Scope CurrentUser
   ```

## Next Steps

- Read the [README.md](../README.md) for detailed usage examples
- Check [REGISTRY-STRUCTURE.md](REGISTRY-STRUCTURE.md) for technical details
- Review [windows10-testing-alternatives.txt](windows10-testing-alternatives.txt) for fallback methods
- See [CONTRIBUTING.md](../CONTRIBUTING.md) if you want to contribute

## Getting Help

- **Check documentation**: All `.md` files in the repository
- **Try alternatives**: Use the Windows 10 testing alternatives guide
- **Create an issue**: On the GitHub repository for bugs or questions
- **Check system logs**: Windows Event Viewer → System logs for errors

---

**Quick Start Summary**:
1. Download repository → 2. `cd scripts` → 3. `.\get-hotspot-info.bat` → 4. Start managing your hotspot! 🚀 