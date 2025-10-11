<#
.SYNOPSIS
    Updates Windows Task Scheduler tasks with new sunrise/sunset times.

.DESCRIPTION
    Recalculates sunrise/sunset times and updates the scheduled tasks accordingly.
    Should be run daily (typically at midnight) to keep times accurate.

.PARAMETER ConfigPath
    Path to configuration file. Defaults to config.json in script directory.

.EXAMPLE
    .\Update-ScheduledTasks.ps1
    Updates scheduled tasks with tomorrow's sunrise/sunset times.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = $null
)

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Warning "This script requires Administrator privileges to update scheduled tasks."
    Write-Host "Please run PowerShell as Administrator and try again."
    exit 1
}

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Set default config path
if (-not $ConfigPath) {
    $ConfigPath = Join-Path -Path $scriptDir -ChildPath "config.json"
}

# Load configuration
try {
    $config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
}
catch {
    Write-Error "Failed to load configuration: $_"
    exit 1
}

# Get location
function Get-Location {
    param($Config)
    
    if ($Config.Location.Latitude -and $Config.Location.Longitude) {
        return @{
            Latitude = $Config.Location.Latitude
            Longitude = $Config.Location.Longitude
        }
    }
    
    # Fallback to default (New York)
    return @{
        Latitude = 40.7128
        Longitude = -74.0060
    }
}

try {
    # Load Get-SunriseSunset script
    $getSunriseSunsetScript = Join-Path -Path $scriptDir -ChildPath "Get-SunriseSunset.ps1"
    
    if (-not (Test-Path -Path $getSunriseSunsetScript)) {
        Write-Error "Required script not found: $getSunriseSunsetScript"
        exit 1
    }
    
    # Get location
    $location = Get-Location -Config $config
    
    # Calculate sunrise/sunset for tomorrow
    $tomorrow = (Get-Date).AddDays(1)
    Write-Host "Calculating sunrise/sunset for $($tomorrow.ToString('yyyy-MM-dd'))..."
    
    $sunTimes = & $getSunriseSunsetScript -Latitude $location.Latitude -Longitude $location.Longitude -Date $tomorrow
    
    # Apply offsets
    $sunrise = $sunTimes.Sunrise.AddMinutes($config.Offsets.SunriseOffsetMinutes)
    $sunset = $sunTimes.Sunset.AddMinutes($config.Offsets.SunsetOffsetMinutes)
    
    Write-Host "Tomorrow's Sunrise: $($sunrise.ToString('hh:mm tt'))"
    Write-Host "Tomorrow's Sunset:  $($sunset.ToString('hh:mm tt'))"
    
    # Update Sunrise task
    $taskName = "AutoThemeSwitch_Sunrise"
    $existingSunriseTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingSunriseTask) {
        $trigger = New-ScheduledTaskTrigger -Daily -At $sunrise
        Set-ScheduledTask -TaskName $taskName -Trigger $trigger | Out-Null
        Write-Host "Updated sunrise task: $taskName" -ForegroundColor Green
    }
    else {
        Write-Warning "Sunrise task not found: $taskName"
    }
    
    # Update Sunset task
    $taskName = "AutoThemeSwitch_Sunset"
    $existingSunsetTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    
    if ($existingSunsetTask) {
        $trigger = New-ScheduledTaskTrigger -Daily -At $sunset
        Set-ScheduledTask -TaskName $taskName -Trigger $trigger | Out-Null
        Write-Host "Updated sunset task: $taskName" -ForegroundColor Green
    }
    else {
        Write-Warning "Sunset task not found: $taskName"
    }
    
    Write-Host "`nScheduled tasks updated successfully!" -ForegroundColor Green
    Write-Host "Next sunrise switch: $($sunrise.ToString('hh:mm tt on dddd, MMMM dd'))"
    Write-Host "Next sunset switch:  $($sunset.ToString('hh:mm tt on dddd, MMMM dd'))"
}
catch {
    Write-Error "Failed to update scheduled tasks: $_"
    exit 1
}
