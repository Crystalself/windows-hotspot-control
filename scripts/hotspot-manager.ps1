# Windows Mobile Hotspot Manager - Unified Interface
# Provides simple, programmatic access to all hotspot operations
# Compatible with Windows 10/11
#
# Usage: hotspot-manager.ps1 <command> [options]
# Commands: status, enable, disable, devices, set-credentials, backup, restore, reset
# Returns: JSON output with consistent structure

param(
    [Parameter(Mandatory=$true, Position=0)]
    [ValidateSet("status", "enable", "disable", "devices", "set-credentials", "backup", "restore", "reset", "help")]
    [string]$Command,
    
    [Parameter(Position=1)]
    [string]$SSID,
    
    [Parameter(Position=2)]
    [string]$Password,
    
    [Parameter(Position=3)]
    [ValidateSet("2.4GHz", "5GHz", "Auto")]
    [string]$Band = "2.4GHz",
    
    [string]$BackupFile,
    [switch]$Force = $false,
    [switch]$Quiet = $false
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Get script directory
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Helper function for consistent JSON output
Function New-Result {
    param(
        [bool]$Success,
        [string]$Operation,
        [object]$Data = $null,
        [string]$Message = "",
        [string]$ErrorMessage = ""
    )
    
    $result = @{
        Success = $Success
        Operation = $Operation
        Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }
    
    if ($Data) { $result.Data = $Data }
    if ($Message) { $result.Message = $Message }
    if ($ErrorMessage) { $result.Error = $ErrorMessage }
    
    return $result
}

# Helper function to run scripts and capture output
Function Invoke-HotspotScript {
    param(
        [string]$ScriptName,
        [string[]]$Arguments = @()
    )
    
    try {
        $scriptPath = Join-Path $ScriptDir $ScriptName
        if (-not (Test-Path $scriptPath)) {
            throw "Script not found: $ScriptName"
        }
        
        $allArgs = @("-ExecutionPolicy", "Bypass", "-File", $scriptPath) + $Arguments
        $result = & powershell @allArgs 2>&1
        
        return @{
            Success = $LASTEXITCODE -eq 0
            Output = $result
            ExitCode = $LASTEXITCODE
        }
    }
    catch {
        return @{
            Success = $false
            Output = $_.Exception.Message
            ExitCode = 1
        }
    }
}

# Command implementations
Function Get-HotspotStatus {
    $result = Invoke-HotspotScript "get-hotspot-info.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        try {
            $data = $result.Output | ConvertFrom-Json
            return New-Result -Success $true -Operation "status" -Data $data -Message "Hotspot status retrieved successfully"
        }
        catch {
            return New-Result -Success $false -Operation "status" -ErrorMessage "Failed to parse hotspot status: $($_.Exception.Message)"
        }
    }
    else {
        return New-Result -Success $false -Operation "status" -ErrorMessage "Failed to get hotspot status: $($result.Output)"
    }
}

Function Enable-HotspotService {
    $result = Invoke-HotspotScript "enable-hotspot.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        try {
            $data = $result.Output | ConvertFrom-Json
            $message = if ($data.Success) { "Hotspot enabled successfully" } else { "Failed to enable hotspot" }
            return New-Result -Success $data.Success -Operation "enable" -Data $data -Message $message
        }
        catch {
            return New-Result -Success $false -Operation "enable" -ErrorMessage "Failed to parse enable result: $($_.Exception.Message)"
        }
    }
    else {
        return New-Result -Success $false -Operation "enable" -ErrorMessage "Failed to enable hotspot: $($result.Output)"
    }
}

Function Disable-HotspotService {
    $result = Invoke-HotspotScript "disable-hotspot.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        try {
            # Parse the JSON output from disable script
            $jsonOutput = $result.Output | Where-Object { $_ -match '^{.*}$' } | Select-Object -First 1
            if ($jsonOutput) {
                $data = $jsonOutput | ConvertFrom-Json
                $message = if ($data.Success) { "Hotspot disabled successfully" } else { "Failed to disable hotspot" }
                return New-Result -Success $data.Success -Operation "disable" -Data $data -Message $message
            }
            else {
                return New-Result -Success $true -Operation "disable" -Message "Hotspot disabled successfully"
            }
        }
        catch {
            return New-Result -Success $true -Operation "disable" -Message "Hotspot operation completed"
        }
    }
    else {
        return New-Result -Success $false -Operation "disable" -ErrorMessage "Failed to disable hotspot: $($result.Output)"
    }
}

Function Get-ConnectedDevices {
    $result = Invoke-HotspotScript "get-connected-devices.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        try {
            $data = $result.Output | ConvertFrom-Json
            $message = "Found $($data.DeviceCount) connected device$(if ($data.DeviceCount -ne 1) { 's' })"
            return New-Result -Success $true -Operation "devices" -Data $data -Message $message
        }
        catch {
            return New-Result -Success $false -Operation "devices" -ErrorMessage "Failed to parse device list: $($_.Exception.Message)"
        }
    }
    else {
        return New-Result -Success $false -Operation "devices" -ErrorMessage "Failed to get connected devices: $($result.Output)"
    }
}

Function Set-HotspotCredentials {
    if (-not $SSID -or -not $Password) {
        return New-Result -Success $false -Operation "set-credentials" -ErrorMessage "SSID and Password are required"
    }
    
    $args = @($SSID, $Password, $Band, "-NonInteractive")
    $result = Invoke-HotspotScript "set-hotspot-credentials.ps1" $args
    
    if ($result.Success) {
        $message = "Credentials updated successfully - SSID: '$SSID', Band: $Band"
        return New-Result -Success $true -Operation "set-credentials" -Message $message -Data @{
            SSID = $SSID
            Band = $Band
            PasswordLength = $Password.Length
        }
    }
    else {
        return New-Result -Success $false -Operation "set-credentials" -ErrorMessage "Failed to set credentials: $($result.Output)"
    }
}

Function Backup-HotspotConfig {
    $result = Invoke-HotspotScript "backup-hotspot-config.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        # Find backup filename from output
        $backupFile = ""
        foreach ($line in $result.Output) {
            if ($line -match "hotspot-backup-.*\.json") {
                $backupFile = $matches[0]
                break
            }
        }
        
        return New-Result -Success $true -Operation "backup" -Message "Configuration backed up successfully" -Data @{
            BackupFile = $backupFile
            Location = (Get-Location).Path
        }
    }
    else {
        return New-Result -Success $false -Operation "backup" -ErrorMessage "Failed to backup configuration: $($result.Output)"
    }
}

Function Restore-HotspotConfig {
    # For restore command, allow backup file as positional parameter (using SSID position)
    if (-not $BackupFile -and $SSID) {
        $BackupFile = $SSID
    }
    
    # For programmatic use, require backup file to be specified
    if (-not $BackupFile) {
        return New-Result -Success $false -Operation "restore" -ErrorMessage "BackupFile parameter is required for programmatic restore operation. Use -BackupFile parameter or specify filename as argument."
    }
    
    # Validate backup file exists
    if (-not (Test-Path $BackupFile)) {
        # Try relative path from script directory
        $relativePath = Join-Path $ScriptDir $BackupFile
        if (Test-Path $relativePath) {
            $BackupFile = $relativePath
        } else {
            return New-Result -Success $false -Operation "restore" -ErrorMessage "Backup file not found: $BackupFile"
        }
    }
    
    $args = @("-NonInteractive", $BackupFile)
    
    $result = Invoke-HotspotScript "restore-hotspot-config.ps1" $args
    
    if ($result.Success) {
        return New-Result -Success $true -Operation "restore" -Message "Configuration restored successfully from $(Split-Path $BackupFile -Leaf)" -Data @{
            BackupFile = Split-Path $BackupFile -Leaf
            BackupPath = $BackupFile
        }
    }
    else {
        return New-Result -Success $false -Operation "restore" -ErrorMessage "Failed to restore configuration: $($result.Output)"
    }
}

Function Reset-HotspotService {
    $result = Invoke-HotspotScript "reset-hotspot-service.ps1" @("-NonInteractive")
    
    if ($result.Success) {
        return New-Result -Success $true -Operation "reset" -Message "Hotspot service reset successfully"
    }
    else {
        return New-Result -Success $false -Operation "reset" -ErrorMessage "Failed to reset hotspot service: $($result.Output)"
    }
}

Function Show-Help {
    $helpText = @"
Windows Mobile Hotspot Manager v1.0
===================================

USAGE:
    hotspot-manager.ps1 <command> [options]

COMMANDS:
    status                          Get hotspot status and configuration
    enable                          Enable mobile hotspot
    disable                         Disable mobile hotspot
    devices                         List connected devices
    set-credentials <ssid> <pass> [band]  Set hotspot credentials
    backup                          Backup current configuration
    restore [file]                  Restore configuration from backup
    reset                           Reset hotspot service
    help                            Show this help

OPTIONS:
    -SSID <name>                    Hotspot network name (1-32 characters)
    -Password <pass>                Network password (8-63 characters)
    -Band <band>                    Frequency band: 2.4GHz, 5GHz, or Auto
    -BackupFile <file>              Specific backup file to restore
    -Force                          Force operation without confirmation
    -Quiet                          Suppress non-essential output

EXAMPLES:
    # Get current status
    .\hotspot-manager.ps1 status

    # Enable hotspot
    .\hotspot-manager.ps1 enable

    # Set new credentials
    .\hotspot-manager.ps1 set-credentials "MyWiFi" "SecurePass123" "5GHz"

    # List connected devices
    .\hotspot-manager.ps1 devices

    # Backup and restore
    .\hotspot-manager.ps1 backup
    .\hotspot-manager.ps1 restore

OUTPUT:
    All commands return JSON with consistent structure:
    {
        "Success": true/false,
        "Operation": "command-name",
        "Message": "description",
        "Data": { ... },
        "Timestamp": "2025-06-29 13:00:00"
    }

INTEGRATION EXAMPLES:
    # PowerShell
    `$result = .\hotspot-manager.ps1 status | ConvertFrom-Json
    Write-Host "Status: `$(`$result.Data.Status)"

    # Python
    import subprocess, json
    result = subprocess.run(['powershell', '-File', 'hotspot-manager.ps1', 'status'], 
                           capture_output=True, text=True)
    data = json.loads(result.stdout)
    print(f"Status: {data['Data']['Status']}")

    # Node.js
    const { execSync } = require('child_process');
    const result = JSON.parse(execSync('powershell -File hotspot-manager.ps1 status'));
    console.log(`Status: `${result.Data.Status}`);

"@
    
    return New-Result -Success $true -Operation "help" -Message $helpText
}

# Main execution
try {
    $result = switch ($Command.ToLower()) {
        "status"           { Get-HotspotStatus }
        "enable"           { Enable-HotspotService }
        "disable"          { Disable-HotspotService }
        "devices"          { Get-ConnectedDevices }
        "set-credentials"  { Set-HotspotCredentials }
        "backup"           { Backup-HotspotConfig }
        "restore"          { Restore-HotspotConfig }
        "reset"            { Reset-HotspotService }
        "help"             { Show-Help }
        default            { New-Result -Success $false -Operation $Command -ErrorMessage "Unknown command: $Command. Use 'help' for usage information." }
    }
    
    # Output result as JSON
    if ($Command -eq "help" -and $result.Success) {
        # For help, output the message directly
        Write-Host $result.Message
    } else {
        $result | ConvertTo-Json -Depth 10 -Compress
    }
    
    # Set exit code
    if ($result.Success) {
        exit 0
    } else {
        exit 1
    }
}
catch {
    $errorResult = New-Result -Success $false -Operation $Command -ErrorMessage "Unexpected error: $($_.Exception.Message)"
    $errorResult | ConvertTo-Json -Compress
    exit 1
} 