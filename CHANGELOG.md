# Changelog

All notable changes to Auto Theme Switcher will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-09

### Added
- Initial release of Auto Theme Switcher
- NOAA Solar Calculator implementation for accurate sunrise/sunset calculations
- Automatic location detection using Windows Location API
- Manual location override support via configuration
- Timezone-aware calculations with automatic DST handling
- Five scheduled tasks for comprehensive theme automation:
  - Startup theme switch
  - Wake from sleep theme switch
  - Daily sunrise light mode switch
  - Daily sunset dark mode switch
  - Midnight task scheduler updater
- Sunrise/sunset time offset configuration
- Comprehensive logging with automatic log rotation
- Registry-based theme switching for Windows 11
- WM_SETTINGCHANGE broadcast for immediate theme application
- One-command installation script
- Clean uninstallation script with optional config preservation
- Detailed README with troubleshooting guide
- Configuration validation and fallback mechanisms
- Error handling with graceful degradation

### Features
- Zero background resource usage (only runs on triggers)
- Automatic daily updates of sunrise/sunset times
- Support for custom latitude/longitude
- Configurable time offsets for sunrise/sunset
- Manual theme switching capability
- Rotating log files (1MB max, keeps 5 files)
- Task Scheduler integration for event-driven execution
- Cross-timezone support with system timezone detection

### Technical Details
- PowerShell 5.1+ compatible
- Windows 11 optimized (may work on Windows 10)
- Uses .NET Framework System.Device for location
- HKCU registry modifications (user-level only)
- Task Scheduler XML-based configuration
- Julian Day calculations for solar positioning
- Equation of time corrections
- Solar declination and hour angle calculations

### Documentation
- Complete README with installation guide
- Configuration reference
- Troubleshooting section
- Resource comparison with Auto Dark Mode
- Security and privacy notes
- Manual control examples
- Scheduled task descriptions

### Scripts Included
- `Get-SunriseSunset.ps1` - Solar calculation engine
- `Set-WindowsTheme.ps1` - Theme switching with logging
- `Switch-Theme.ps1` - Main orchestration script
- `Update-ScheduledTasks.ps1` - Task scheduler updater
- `Install-AutoThemeSwitcher.ps1` - Automated installer
- `Uninstall-AutoThemeSwitcher.ps1` - Clean uninstaller

### Known Limitations
- Requires administrator privileges for installation
- Location detection may fail in restricted environments
- Polar regions (midnight sun/polar night) use fixed times as fallback
- Does not detect manual theme changes between scheduled times
- Task Scheduler service must be running

### Performance
- Memory: 0 MB when idle
- CPU: 0% when idle, ~1-2% during 1-2 second execution
- Disk: ~10-50 KB logs (with rotation)
- Network: 0 bytes (fully offline after location detection)
- Executions: 5-10 times per day maximum

---

## Release Notes

### What's New in 1.0.0

This is the initial release of Auto Theme Switcher, a lightweight alternative to continuous background theme switching applications. Built from the ground up for Windows 11, it leverages Task Scheduler for event-driven execution, eliminating the need for continuous background processes.

**Key Highlights:**
- **Minimal Resource Usage**: No background processes consuming RAM or CPU
- **Astronomical Accuracy**: Uses NOAA algorithms for precise sunrise/sunset times
- **Smart Automation**: Handles startup, wake from sleep, and time-based switching
- **User-Friendly**: One-command installation and configuration

**Who Should Use This:**
Perfect for users who want automatic theme switching based purely on time without the overhead of continuous monitoring applications. Ideal for resource-constrained systems or users who prefer minimal background activity.

**Migration from Auto Dark Mode:**
If you're currently using Auto Dark Mode but want to reduce resource usage, Auto Theme Switcher provides the core time-based switching functionality with zero continuous background processes. The trade-off is that theme changes only occur at scheduled times rather than being continuously monitored.

---

## Future Versions

### Planned for 1.1.0
- GUI configuration tool
- System tray icon with manual controls
- Enhanced error reporting
- Configuration import/export

### Planned for 1.2.0
- Windows Terminal theme integration
- Per-application theme overrides
- Weather-based theme adjustments

### Planned for 2.0.0
- Multiple location profiles
- Vacation mode (manual location override)
- Advanced scheduling rules
- Integration with other automation tools

---

## Upgrade Path

### Upgrading to Future Versions

When upgrading:
1. Run the uninstaller with `-KeepConfig` flag
2. Install the new version
3. Existing configuration will be automatically migrated

```powershell
.\Uninstall-AutoThemeSwitcher.ps1 -KeepConfig
# Download new version
.\Install-AutoThemeSwitcher.ps1
```

---

**Versioning Scheme:**
- **Major** (X.0.0): Breaking changes, new architecture
- **Minor** (1.X.0): New features, backward compatible
- **Patch** (1.0.X): Bug fixes, improvements

**Support Policy:**
- Latest version: Full support
- Previous major version: Security fixes only
- Older versions: Community support

---

For detailed installation and usage instructions, see [README.md](README.md).
