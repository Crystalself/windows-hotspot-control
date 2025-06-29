# Contributing to Windows Hotspot Control

Thank you for your interest in contributing to this project! This guide outlines how you can help improve the Windows Hotspot Control scripts.

## Ways to Contribute

### 🐛 Bug Reports
- Use the GitHub Issues tab to report bugs
- Include your Windows version and PowerShell version
- Provide steps to reproduce the issue
- Include error messages and screenshots if applicable

### 💡 Feature Requests
- Suggest new features or improvements via GitHub Issues
- Explain the use case and expected behavior
- Consider backward compatibility with Windows 10/11

### 🔧 Code Contributions
- Fork the repository
- Create a feature branch: `git checkout -b feature/your-feature-name`
- Make your changes following the coding standards below
- Test thoroughly on different Windows versions
- Submit a pull request with a clear description

## Coding Standards

### PowerShell Scripts
- Use approved PowerShell verbs (`Get-`, `Set-`, `Enable-`, etc.)
- Include comprehensive error handling with try/catch blocks
- Add parameter validation and help documentation
- Support both interactive and non-interactive modes
- Follow PowerShell naming conventions (PascalCase for functions)

### Batch Files
- Keep batch files simple and focused
- Include error checking with appropriate exit codes
- Add comments explaining complex logic
- Ensure compatibility with all Windows versions

### Documentation
- Update README.md if adding new functionality
- Include usage examples for new features
- Document any new command-line parameters
- Update the Windows 10 testing alternatives if needed

## Testing Requirements

### Before Submitting
- Test on both Windows 10 and Windows 11
- Verify both interactive and non-interactive modes work
- Test with and without admin privileges
- Ensure scripts handle missing dependencies gracefully
- Validate JSON output format for programmatic usage

### Test Cases
- Enable/disable hotspot functionality
- Credential setting with various SSID/password lengths
- Device detection on different network configurations
- Backup and restore operations
- Error handling for edge cases

## Pull Request Process

1. **Description**: Clearly describe what your PR does and why
2. **Testing**: List what you tested and on which Windows versions
3. **Breaking Changes**: Highlight any breaking changes
4. **Documentation**: Update docs if functionality changes
5. **Examples**: Add usage examples for new features

## Code Review Process

- All PRs require review before merging
- Address feedback promptly and constructively
- Be prepared to make revisions based on testing results
- Ensure backwards compatibility unless it's a major version

## Development Setup

### Prerequisites
- Windows 10/11 with PowerShell 5.1+
- Administrative privileges for testing
- Git for version control

### Local Testing
```bash
# Clone your fork
git clone https://github.com/Crystalself/windows-hotspot-control.git
cd windows-hotspot-control

# Test basic functionality
cd scripts
.\get-hotspot-info.bat
.\hotspot-manager.bat status
```

### Alternative Testing
If main scripts fail, test with the alternatives in `docs/windows10-testing-alternatives.txt`

## Questions or Help

- Check existing GitHub Issues first
- Create a new issue for questions
- Tag maintainers if urgent: @Crystalself

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

Thank you for helping make Windows Hotspot Control better! 🚀 