# Changelog

All notable changes to the Windows Hotspot Control project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-01-16

### Added
- **Complete Mobile Hotspot Management Suite**
  - Get hotspot status and credentials (`get-hotspot-info`)
  - Enable/disable hotspot (`enable-hotspot`, `disable-hotspot`)
  - Set hotspot credentials with band support (`set-hotspot-credentials`)
  - Reset hotspot service (`reset-hotspot-service`)
  - Backup and restore configurations (`backup-hotspot-config`, `restore-hotspot-config`)
  - Connected devices discovery (`get-connected-devices`)
  - Unified management interface (`hotspot-manager`)

- **Windows Runtime API Integration**
  - Solved async operation hanging issues in PowerShell
  - Proper error handling with detailed Windows error codes
  - Fast operation completion (2-6 seconds vs 30+ second timeouts)

- **Registry Structure Support**
  - 208-byte binary structure encoding/decoding
  - Support for SSID, password, and band configuration
  - Windows-compatible encoding with perfect alignment
  - Band support: 2.4GHz, 5GHz, Auto

- **Connected Devices Manager**
  - ARP table analysis for device detection
  - Wi-Fi Direct Virtual Adapter identification
  - Hostname resolution and vendor identification
  - MAC address vendor database (25+ manufacturers)
  - Connectivity testing with ping verification
  - Both static and dynamic ARP entry support

- **Programmatic Usage Support**
  - Non-interactive mode with `-NonInteractive` parameter
  - JSON output for all operations
  - Proper exit codes (0=success, 1=failure)
  - Silent parameters: `-silent`, `-q`
  - Integration examples for Python, PowerShell, Node.js

- **Comprehensive Documentation**
  - Complete README with usage examples
  - Registry structure deep dive documentation
  - Windows 10 testing alternatives guide
  - Technical issues and solutions reference

- **Path Issue Resolution**
  - Fixed restore configuration file discovery
  - Delayed elevation for better user experience
  - Proper working directory handling
  - Eliminated duplicate output messages

### Technical Achievements
- **Windows Runtime Async Fix**: Converted `IAsyncOperation` to .NET Tasks using `WindowsRuntimeSystemExtensions.AsTask()`
- **Registry Alignment Solution**: Added 2-byte padding (bytes 68-69) for perfect password alignment
- **ARP Detection Enhancement**: Support for both static and dynamic ARP entries
- **Elevation Optimization**: Delayed admin privilege requests until actually needed
- **Error Handling**: Comprehensive validation and specific error messages

### Files Structure
```
├── scripts/                 # All PowerShell and batch scripts
├── docs/                    # Documentation files
├── examples/                # Example configuration files
├── README.md               # Main documentation
├── CONTRIBUTING.md         # Contribution guidelines
├── CHANGELOG.md           # This file
├── LICENSE                # MIT License
└── .gitignore             # Git ignore rules
```

### Windows Compatibility
- **Windows 10**: All versions (1607-22H2) - Full support
- **Windows 11**: All versions - Full support
- **PowerShell**: 5.1+ required
- **Admin Privileges**: Required for configuration changes

### Known Issues
- Device detection requires network traffic from connected devices
- Some network adapters may not support hosted network mode
- Registry modifications require Administrator privileges

---

## Future Releases

### Planned Features
- [ ] Automatic update checker
- [ ] GUI interface option
- [ ] Advanced scheduling capabilities
- [ ] Network traffic monitoring
- [ ] Multi-language support
- [ ] PowerShell Core (7.x) optimization

### Under Consideration
- [ ] Windows Server support
- [ ] Group Policy template
- [ ] MSI installer package
- [ ] Chocolatey package
- [ ] Windows Package Manager integration

---

**Legend:**
- `Added` for new features
- `Changed` for changes in existing functionality
- `Deprecated` for soon-to-be removed features
- `Removed` for now removed features
- `Fixed` for any bug fixes
- `Security` for vulnerability fixes 