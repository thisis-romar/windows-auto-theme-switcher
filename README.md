# Auto Theme Switcher for Windows 11

A lightweight, resource-efficient PowerShell solution for automatic Windows 11 theme switching based on sunrise/sunset times. No continuous background processes—just smart Task Scheduler triggers.

## 🌟 Features

- **Zero Background Resources**: Runs only when triggered (startup, wake from sleep, scheduled times)
- **Astronomical Calculations**: Uses NOAA Solar Calculator algorithms for accurate sunrise/sunset times
- **Auto-Location Detection**: Automatically detects your location or uses manual coordinates
- **Fully Automated**: Set it and forget it—updates daily sunrise/sunset times automatically
- **Timezone Aware**: Handles DST transitions and timezone changes automatically
- **Customizable Offsets**: Adjust sunrise/sunset times to your preference
- **Comprehensive Logging**: Track all theme switches with rotating log files
- **Easy Installation**: One-command setup with Administrator privileges
- **Clean Uninstallation**: Complete removal with optional config preservation

## 📋 Requirements

- **Operating System**: Windows 11 (may work on Windows 10)
- **PowerShell**: Version 5.1 or higher
- **Permissions**: Administrator rights for installation (to create scheduled tasks)

## 🚀 Quick Start

### Installation

1. **Download** or clone this repository to `H:\Windows-Tools\AutoThemeSwitcher\`

2. **Open PowerShell as Administrator**:
   - Press `Win + X`
   - Select "Windows Terminal (Admin)" or "PowerShell (Admin)"

3. **Navigate to the installation directory**:
   ```powershell
   cd H:\Windows-Tools\AutoThemeSwitcher
   ```

4. **Run the installer**:
   ```powershell
   .\Install-AutoThemeSwitcher.ps1
   ```

5. **Done!** Your theme will now automatically switch based on sunrise/sunset times.

### Installation with Custom Location

If auto-detection fails or you want to specify a location:

```powershell
.\Install-AutoThemeSwitcher.ps1 -Latitude 40.7128 -Longitude -74.0060
```

### Installation with Time Offsets

Adjust when theme switches occur:

```powershell
# Sunrise 30 minutes later, sunset 15 minutes earlier
.\Install-AutoThemeSwitcher.ps1 -SunriseOffset 30 -SunsetOffset -15
```

## ⚙️ Configuration

The configuration file is located at `config.json`:

```json
{
  "Location": {
    "Latitude": null,
    "Longitude": null,
    "Timezone": "Eastern Standard Time",
    "UseAutoLocation": true
  },
  "Offsets": {
    "SunriseOffsetMinutes": 0,
    "SunsetOffsetMinutes": 0
  },
  "Logging": {
    "Enabled": true,
    "LogPath": "H:\\Windows-Tools\\AutoThemeSwitcher\\logs\\theme-switch.log"
  }
}
```

### Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| `Latitude` | Your latitude in decimal degrees | Auto-detected |
| `Longitude` | Your longitude in decimal degrees | Auto-detected |
| `Timezone` | System timezone identifier | Auto-detected |
| `UseAutoLocation` | Enable automatic location detection | `true` |
| `SunriseOffsetMinutes` | Minutes to offset sunrise (+ later, - earlier) | `0` |
| `SunsetOffsetMinutes` | Minutes to offset sunset (+ later, - earlier) | `0` |
| `Logging.Enabled` | Enable logging | `true` |
| `Logging.LogPath` | Path to log file | `logs/theme-switch.log` |

## 🎯 Manual Controls

### Force Theme Switch

```powershell
# Force light theme
.\Switch-Theme.ps1 -Action Light -Force

# Force dark theme
.\Switch-Theme.ps1 -Action Dark -Force

# Auto-determine based on current time
.\Switch-Theme.ps1 -Action Auto
```

### Update Scheduled Tasks

If you manually edit the configuration, update the scheduled tasks:

```powershell
.\Update-ScheduledTasks.ps1
```

## 📅 Scheduled Tasks

The installer creates 5 scheduled tasks:

| Task Name | Trigger | Purpose |
|-----------|---------|---------|
| `AutoThemeSwitch_Startup` | System startup | Sets correct theme when PC boots |
| `AutoThemeSwitch_WakeFromSleep` | Wake from sleep | Sets correct theme when PC wakes |
| `AutoThemeSwitch_Sunrise` | Daily at sunrise | Switches to light mode |
| `AutoThemeSwitch_Sunset` | Daily at sunset | Switches to dark mode |
| `AutoThemeSwitch_MidnightUpdater` | Daily at 12:05 AM | Updates sunrise/sunset times |

### View Scheduled Tasks

```powershell
Get-ScheduledTask | Where-Object { $_.TaskName -like "AutoThemeSwitch*" }
```

## 🗑️ Uninstallation

### Remove Everything

```powershell
.\Uninstall-AutoThemeSwitcher.ps1
```

### Keep Configuration

```powershell
.\Uninstall-AutoThemeSwitcher.ps1 -KeepConfig
```

### Reset Theme to Light

```powershell
.\Uninstall-AutoThemeSwitcher.ps1 -ResetTheme
```

## 📊 Resource Comparison

### Auto Dark Mode (Continuous Application)
- **Memory**: 10-20 MB constant
- **CPU**: <1% continuous polling every 60 seconds
- **Process Count**: 1-2 background processes
- **Response Time**: Instant detection of manual changes

### Auto Theme Switcher (This Solution)
- **Memory**: 0 MB when idle (only runs on triggers)
- **CPU**: 0% when idle, ~1-2% for 1-2 seconds during execution
- **Process Count**: 0 background processes
- **Executions**: 5-10 times per day maximum
- **Trade-off**: Only switches at scheduled times or events

**Perfect for users who:**
- Want minimal resource usage
- Prefer time-based switching only
- Have resource-constrained systems
- Don't need instant response to manual overrides

## 🔍 Troubleshooting

### Theme Doesn't Switch

1. **Check if tasks are enabled**:
   ```powershell
   Get-ScheduledTask -TaskName "AutoThemeSwitch*" | Select-Object TaskName, State
   ```

2. **Run manual switch test**:
   ```powershell
   .\Switch-Theme.ps1 -Action Auto -Verbose
   ```

3. **Check logs**:
   ```powershell
   Get-Content ".\logs\theme-switch.log" -Tail 20
   ```

### Location Detection Fails

Manually set your location in `config.json`:

```json
{
  "Location": {
    "Latitude": 40.7128,
    "Longitude": -74.0060,
    "UseAutoLocation": false
  }
}
```

Find your coordinates: [LatLong.net](https://www.latlong.net/)

### Tasks Don't Run

Ensure Task Scheduler service is running:

```powershell
Get-Service -Name "Schedule" | Start-Service
```

### PowerShell Execution Policy

If scripts won't run, adjust execution policy:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## 📝 Logging

Logs are stored in `logs/theme-switch.log` with automatic rotation:

- **Max Size**: 1 MB per log file
- **Retention**: Last 5 log files kept
- **Format**: `YYYY-MM-DD HH:MM:SS | LEVEL | Message`

### Example Log Entries

```
2025-10-09 07:15:23 | INFO | Current theme: Dark
2025-10-09 07:15:23 | INFO | Successfully switched theme from Dark to Light
2025-10-09 07:15:23 | INFO | Broadcast WM_SETTINGCHANGE message to apply theme
2025-10-09 19:47:12 | INFO | Successfully switched theme from Light to Dark
```

## 🔐 Security & Privacy

- **No Network Required**: All calculations are local (except optional location API)
- **User-Level Changes**: Only modifies current user's theme settings (HKCU registry)
- **No Data Collection**: No telemetry, analytics, or external connections
- **Local Storage**: All data stays on your computer
- **Code Signing**: Scripts can be self-signed for additional security

### Sign Scripts (Optional)

```powershell
# Create self-signed certificate
$cert = New-SelfSignedCertificate -Subject "AutoThemeSwitcher" -CertStoreLocation Cert:\CurrentUser\My -Type CodeSigningCert

# Sign all scripts
Get-ChildItem -Path "H:\Windows-Tools\AutoThemeSwitcher\*.ps1" | ForEach-Object {
    Set-AuthenticodeSignature -FilePath $_.FullName -Certificate $cert
}
```

## 🛣️ Roadmap

Future enhancements under consideration:

- [ ] GUI configuration tool (PowerShell + WPF)
- [ ] System tray icon with status and manual controls
- [ ] Windows Terminal theme integration
- [ ] Weather-based switching (darker on cloudy days)
- [ ] Multiple location profiles for travelers
- [ ] Per-application theme overrides
- [ ] Export/import configuration

## 🤝 Contributing

Contributions are welcome! Feel free to:

- Report bugs
- Suggest features
- Submit pull requests
- Improve documentation

## 📄 License

This project is provided "as-is" without warranty. Free to use, modify, and distribute.

## 🙏 Acknowledgments

- **NOAA Solar Calculator**: Solar calculation algorithms
- **Auto Dark Mode**: Inspiration for feature set
- **PowerShell Community**: Scripting best practices

## 📞 Support

For issues or questions:

1. Check this README
2. Review log files
3. Test manual execution
4. Create an issue with details

---

**Version**: 1.0.0  
**Last Updated**: October 9, 2025  
**Author**: Auto Theme Switcher Project
