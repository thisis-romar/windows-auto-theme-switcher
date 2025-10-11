<#
.SYNOPSIS
    Main script for automatic Windows theme switching based on time of day.

.DESCRIPTION
    Determines the appropriate theme (Light/Dark) based on sunrise/sunset times
    and switches the Windows theme accordingly. Can be run manually or by Task Scheduler.

.PARAMETER Action
    Action to perform: "Auto" (determine based on time), "Light", "Dark", or "UpdateTasks"

.PARAMETER Force
    Force theme switch even if already set to the correct theme

.PARAMETER ConfigPath
    Path to configuration file. Defaults to config.json in script directory.

.EXAMPLE
    .\Switch-Theme.ps1 -Action Auto
    Automatically determines and applies the correct theme based on current time.

.EXAMPLE
    .\Switch-Theme.ps1 -Action Dark -Force
    Forces dark theme regardless of time.

.EXAMPLE
    .\Switch-Theme.ps1 -Action UpdateTasks
    Updates scheduled tasks with new sunrise/sunset times.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Requires: Windows 11, PowerShell 5.1+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("Auto", "Light", "Dark", "UpdateTasks")]
    [string]$Action = "Auto",
    
    [Parameter(Mandatory = $false)]
    [switch]$Force,
    
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = $null
)

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set default config path
if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $scriptDir -ChildPath "config.json"
}

# Load configuration
function Get-Configuration {
    try {
        if (-not (Test-Path -Path $ConfigPath)) {
            Write-Warning "Configuration file not found: $ConfigPath"
            Write-Host "Creating default configuration..."
            
            # Create default configuration
            $defaultConfig = @{
                Location = @{
                    Latitude = $null
                    Longitude = $null
                    Timezone = [TimeZoneInfo]::Local.Id
                    UseAutoLocation = $true
                }
                Offsets = @{
                    SunriseOffsetMinutes = 0
                    SunsetOffsetMinutes = 0
                }
                Logging = @{
                    Enabled = $true
                    LogPath = Join-Path -Path $scriptDir -ChildPath "logs\theme-switch.log"
                }
            }
            
            $defaultConfig | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigPath
            return $defaultConfig
        }
        
        $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        Write-Error "Failed to load configuration: $_"
        exit 1
    }
}

# Get location (auto-detect or from config)
function Get-Location {
    param($Config)
    
    if ($Config.Location.Latitude -and $Config.Location.Longitude) {
        return @{
            Latitude = $Config.Location.Latitude
            Longitude = $Config.Location.Longitude
        }
    }
    
    if ($Config.Location.UseAutoLocation) {
        try {
            # Try to get location from Windows Location API
            Add-Type -AssemblyName System.Device
            $geoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
            $geoWatcher.Start()
            
            # Wait up to 5 seconds for location
            $timeout = 0
            while ($geoWatcher.Status -ne 'Ready' -and $timeout -lt 50) {
                Start-Sleep -Milliseconds 100
                $timeout++
            }
            
            if ($geoWatcher.Status -eq 'Ready') {
                $latitude = $geoWatcher.Position.Location.Latitude
                $longitude = $geoWatcher.Position.Location.Longitude
                
                if ($latitude -ne 0 -and $longitude -ne 0) {
                    Write-Host "Auto-detected location: Lat $latitude, Lon $longitude"
                    return @{
                        Latitude = $latitude
                        Longitude = $longitude
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not auto-detect location: $_"
        }
    }
    
    # Fallback to approximate location based on timezone
    Write-Warning "Using approximate location based on timezone"
    $tzInfo = [TimeZoneInfo]::Local
    
    # Default coordinates for common US timezones
    $timezoneDefaults = @{
        "Eastern Standard Time" = @{ Latitude = 40.7128; Longitude = -74.0060 }  # New York
        "Central Standard Time" = @{ Latitude = 41.8781; Longitude = -87.6298 }  # Chicago
        "Mountain Standard Time" = @{ Latitude = 39.7392; Longitude = -104.9903 } # Denver
        "Pacific Standard Time" = @{ Latitude = 34.0522; Longitude = -118.2437 } # Los Angeles
    }
    
    if ($timezoneDefaults.ContainsKey($tzInfo.Id)) {
        return $timezoneDefaults[$tzInfo.Id]
    }
    
    # Ultimate fallback (New York)
    Write-Warning "Using default location (New York)"
    return @{
        Latitude = 40.7128
        Longitude = -74.0060
    }
}

# Main execution
try {
    $config = Get-Configuration
    $logPath = if ($config.Logging.Enabled) { $config.Logging.LogPath } else { $null }
    
    # Load helper scripts
    $getSunriseSunsetScript = Join-Path -Path $scriptDir -ChildPath "Get-SunriseSunset.ps1"
    $setThemeScript = Join-Path -Path $scriptDir -ChildPath "Set-WindowsTheme.ps1"
    
    if (-not (Test-Path -Path $getSunriseSunsetScript)) {
        Write-Error "Required script not found: $getSunriseSunsetScript"
        exit 1
    }
    
    if (-not (Test-Path -Path $setThemeScript)) {
        Write-Error "Required script not found: $setThemeScript"
        exit 1
    }
    
    # Handle UpdateTasks action
    if ($Action -eq "UpdateTasks") {
        $updateTasksScript = Join-Path -Path $scriptDir -ChildPath "Update-ScheduledTasks.ps1"
        if (Test-Path -Path $updateTasksScript) {
            & $updateTasksScript -ConfigPath $ConfigPath
        }
        else {
            Write-Error "Update-ScheduledTasks.ps1 not found"
            exit 1
        }
        exit 0
    }
    
    # Get location
    $location = Get-Location -Config $config
    
    # Calculate sunrise/sunset
    Write-Host "Calculating sunrise/sunset times..."
    $sunTimes = & $getSunriseSunsetScript -Latitude $location.Latitude -Longitude $location.Longitude
    
    # Apply offsets
    $sunrise = $sunTimes.Sunrise.AddMinutes($config.Offsets.SunriseOffsetMinutes)
    $sunset = $sunTimes.Sunset.AddMinutes($config.Offsets.SunsetOffsetMinutes)
    
    Write-Host "Sunrise: $($sunrise.ToString('hh:mm tt'))"
    Write-Host "Sunset:  $($sunset.ToString('hh:mm tt'))"
    
    # Determine theme based on action
    $targetTheme = $null
    
    if ($Action -eq "Auto") {
        $now = Get-Date
        
        if ($now -ge $sunrise -and $now -lt $sunset) {
            $targetTheme = "Light"
            Write-Host "Current time is during daylight hours." -ForegroundColor Yellow
        }
        else {
            $targetTheme = "Dark"
            Write-Host "Current time is during night hours." -ForegroundColor Yellow
        }
    }
    elseif ($Action -eq "Light") {
        $targetTheme = "Light"
    }
    elseif ($Action -eq "Dark") {
        $targetTheme = "Dark"
    }
    
    # Apply theme
    Write-Host "Applying $targetTheme theme..."
    
    if ($Force) {
        & $setThemeScript -Theme $targetTheme -LogPath $logPath
    }
    else {
        & $setThemeScript -Theme $targetTheme -LogPath $logPath
    }
    
    Write-Host "Theme switch complete." -ForegroundColor Green
    
    # Show next switch time
    if ($Action -eq "Auto") {
        $now = Get-Date
        if ($targetTheme -eq "Light") {
            $nextSwitch = $sunset
            $nextTheme = "Dark"
        }
        else {
            # Next switch is tomorrow's sunrise
            $nextSwitch = $sunrise.AddDays(1)
            $nextTheme = "Light"
        }
        
        Write-Host "Next switch to $nextTheme mode: $($nextSwitch.ToString('hh:mm tt on dddd, MMMM dd'))" -ForegroundColor Cyan
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
