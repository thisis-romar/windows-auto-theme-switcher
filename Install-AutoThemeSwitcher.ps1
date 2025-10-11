<#
.SYNOPSIS
    Installs Auto Theme Switcher with Task Scheduler integration.

.DESCRIPTION
    Sets up all required scheduled tasks for automatic theme switching based on
    sunrise/sunset times. Creates configuration file and initial task schedule.

.PARAMETER Latitude
    Optional: Specify latitude for your location (overrides auto-detection)

.PARAMETER Longitude
    Optional: Specify longitude for your location (overrides auto-detection)

.PARAMETER SunriseOffset
    Optional: Minutes to offset sunrise time (positive = later, negative = earlier)

.PARAMETER SunsetOffset
    Optional: Minutes to offset sunset time (positive = later, negative = earlier)

.EXAMPLE
    .\Install-AutoThemeSwitcher.ps1
    Installs with auto-detected location.

.EXAMPLE
    .\Install-AutoThemeSwitcher.ps1 -Latitude 40.7128 -Longitude -74.0060
    Installs with specified location (New York City).

.EXAMPLE
    .\Install-AutoThemeSwitcher.ps1 -SunriseOffset 30 -SunsetOffset -15
    Installs with sunrise 30 min later and sunset 15 min earlier.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Requires: Windows 11, PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [double]$Latitude = $null,
    
    [Parameter(Mandatory = $false)]
    [double]$Longitude = $null,
    
    [Parameter(Mandatory = $false)]
    [int]$SunriseOffset = 0,
    
    [Parameter(Mandatory = $false)]
    [int]$SunsetOffset = 0
)

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "======================================" -ForegroundColor Red
    Write-Host "  ADMINISTRATOR PRIVILEGES REQUIRED  " -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This installer needs to create scheduled tasks, which requires admin rights."
    Write-Host ""
    Write-Host "Please:" -ForegroundColor Yellow
    Write-Host "  1. Close this window"
    Write-Host "  2. Right-click PowerShell and select 'Run as Administrator'"
    Write-Host "  3. Navigate to: $PSScriptRoot"
    Write-Host "  4. Run: .\Install-AutoThemeSwitcher.ps1"
    Write-Host ""
    pause
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto Theme Switcher - Installation  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$configPath = Join-Path -Path $scriptDir -ChildPath "config.json"
$logsDir = Join-Path -Path $scriptDir -ChildPath "logs"

# Create logs directory
if (-not (Test-Path -Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Host "✓ Created logs directory" -ForegroundColor Green
}

# Create configuration
Write-Host "Creating configuration..."

$useAutoLocation = ($null -eq $Latitude -or $null -eq $Longitude)

$config = @{
    Location = @{
        Latitude = $Latitude
        Longitude = $Longitude
        Timezone = [TimeZoneInfo]::Local.Id
        UseAutoLocation = $useAutoLocation
    }
    Offsets = @{
        SunriseOffsetMinutes = $SunriseOffset
        SunsetOffsetMinutes = $SunsetOffset
    }
    Logging = @{
        Enabled = $true
        LogPath = Join-Path -Path $logsDir -ChildPath "theme-switch.log"
    }
}

$config | ConvertTo-Json -Depth 10 | Set-Content -Path $configPath
Write-Host "✓ Configuration saved to: $configPath" -ForegroundColor Green

# Get location for initial calculation
if ($useAutoLocation) {
    Write-Host "Attempting to auto-detect location..."
    try {
        Add-Type -AssemblyName System.Device
        $geoWatcher = New-Object System.Device.Location.GeoCoordinateWatcher
        $geoWatcher.Start()
        
        $timeout = 0
        while ($geoWatcher.Status -ne 'Ready' -and $timeout -lt 50) {
            Start-Sleep -Milliseconds 100
            $timeout++
        }
        
        if ($geoWatcher.Status -eq 'Ready') {
            $Latitude = $geoWatcher.Position.Location.Latitude
            $Longitude = $geoWatcher.Position.Location.Longitude
            
            if ($Latitude -ne 0 -and $Longitude -ne 0) {
                Write-Host "✓ Location detected: Lat $Latitude, Lon $Longitude" -ForegroundColor Green
            }
            else {
                throw "Invalid coordinates"
            }
        }
        else {
            throw "Location service not ready"
        }
    }
    catch {
        Write-Warning "Could not auto-detect location. Using timezone-based default."
        # Default to New York
        $Latitude = 40.7128
        $Longitude = -74.0060
        Write-Host "  Using default: Lat $Latitude, Lon $Longitude" -ForegroundColor Yellow
    }
}

# Calculate initial sunrise/sunset times
Write-Host ""
Write-Host "Calculating sunrise/sunset times..."

$getSunriseSunsetScript = Join-Path -Path $scriptDir -ChildPath "Get-SunriseSunset.ps1"
$sunTimes = & $getSunriseSunsetScript -Latitude $Latitude -Longitude $Longitude

$sunrise = $sunTimes.Sunrise.AddMinutes($SunriseOffset)
$sunset = $sunTimes.Sunset.AddMinutes($SunsetOffset)

Write-Host "  Today's Sunrise: $($sunrise.ToString('hh:mm tt'))" -ForegroundColor Yellow
Write-Host "  Today's Sunset:  $($sunset.ToString('hh:mm tt'))" -ForegroundColor Yellow

# Create scheduled tasks
Write-Host ""
Write-Host "Creating scheduled tasks..."

$switchThemeScript = Join-Path -Path $scriptDir -ChildPath "Switch-Theme.ps1"
$updateTasksScript = Join-Path -Path $scriptDir -ChildPath "Update-ScheduledTasks.ps1"

# Task 1: Startup
Write-Host "  Creating startup task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Auto"
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

Register-ScheduledTask -TaskName "AutoThemeSwitch_Startup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Startup task created" -ForegroundColor Green

# Task 2: Wake from Sleep
Write-Host "  Creating wake from sleep task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Auto"

# Create CIM instance for event trigger (Event ID 1, Power-Troubleshooter, System log)
$class = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
$trigger = New-CimInstance -CimClass $class -ClientOnly
$trigger.Subscription = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]</Select>
  </Query>
</QueryList>
"@
$trigger.Enabled = $true

Register-ScheduledTask -TaskName "AutoThemeSwitch_WakeFromSleep" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Wake from sleep task created" -ForegroundColor Green

# Task 3: Midnight Updater (updates sunrise/sunset tasks daily)
Write-Host "  Creating midnight updater task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$updateTasksScript`""
$trigger = New-ScheduledTaskTrigger -Daily -At "00:05"  # 5 minutes after midnight
Register-ScheduledTask -TaskName "AutoThemeSwitch_MidnightUpdater" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Midnight updater task created" -ForegroundColor Green

# Task 4: Sunrise
Write-Host "  Creating sunrise task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Light"
$trigger = New-ScheduledTaskTrigger -Daily -At $sunrise
Register-ScheduledTask -TaskName "AutoThemeSwitch_Sunrise" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Sunrise task created (triggers at $($sunrise.ToString('hh:mm tt')))" -ForegroundColor Green

# Task 5: Sunset
Write-Host "  Creating sunset task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Dark"
$trigger = New-ScheduledTaskTrigger -Daily -At $sunset
Register-ScheduledTask -TaskName "AutoThemeSwitch_Sunset" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Sunset task created (triggers at $($sunset.ToString('hh:mm tt')))" -ForegroundColor Green

# Run initial theme switch
Write-Host ""
Write-Host "Setting initial theme..."
& $switchThemeScript -Action Auto

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!               " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Auto Theme Switcher is now active." -ForegroundColor Cyan
Write-Host ""
Write-Host "Scheduled Tasks:" -ForegroundColor Yellow
Write-Host "  • Startup:        Theme switches when PC starts"
Write-Host "  • Wake from Sleep: Theme switches when PC wakes"
Write-Host "  • Sunrise:        Switches to light mode at $($sunrise.ToString('hh:mm tt'))"
Write-Host "  • Sunset:         Switches to dark mode at $($sunset.ToString('hh:mm tt'))"
Write-Host "  • Midnight:       Updates sunrise/sunset times daily"
Write-Host ""
Write-Host "Configuration: $configPath" -ForegroundColor Yellow
Write-Host "Logs:          $($config.Logging.LogPath)" -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual Controls:" -ForegroundColor Yellow
Write-Host "  Force Light: .\Switch-Theme.ps1 -Action Light -Force"
Write-Host "  Force Dark:  .\Switch-Theme.ps1 -Action Dark -Force"
Write-Host ""
Write-Host "To uninstall: .\Uninstall-AutoThemeSwitcher.ps1" -ForegroundColor Yellow
Write-Host ""
pause
