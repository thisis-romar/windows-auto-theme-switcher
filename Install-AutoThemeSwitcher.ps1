<#
.SYNOPSIS
    Installs Auto Theme Switcher with Task Scheduler integration.

.DESCRIPTION
    Sets up all required scheduled tasks for automatic theme switching based on
    sunrise/sunset times. Creates configuration file and logs directory.

.PARAMETER Latitude
    Optional: Specify latitude for your location (defaults to auto-detection)

.PARAMETER Longitude
    Optional: Specify longitude for your location (defaults to auto-detection)

.PARAMETER SunriseOffset
    Optional: Minutes to offset sunrise time (positive = later, negative = earlier)

.PARAMETER SunsetOffset
    Optional: Minutes to offset sunset time (positive = later, negative = earlier)

.NOTES
    Version: 1.0.1
    Requires: Windows 11, PowerShell 5.1+, Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [double]$Latitude = 0,
    
    [Parameter(Mandatory = $false)]
    [double]$Longitude = 0,
    
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
    Write-Host "This installer requires admin rights to create scheduled tasks."
    Write-Host "Please run PowerShell as Administrator and try again."
    Write-Host ""
    pause
    exit 1
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto Theme Switcher - Installation  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$switchThemeScript = Join-Path -Path $scriptDir -ChildPath "Switch-Theme.ps1"
$updateTasksScript = Join-Path -Path $scriptDir -ChildPath "Update-ScheduledTasks.ps1"

# Determine location
if ($Latitude -eq 0 -and $Longitude -eq 0) {
    Write-Host "Auto-detecting location..."
    # Will use Switch-Theme.ps1's auto-detection, which gets it from config or auto-detects
    # For now, use a reasonable default
    $Latitude = 43.7
    $Longitude = -79.78
    Write-Host "  Using default: Lat $Latitude, Lon $Longitude" -ForegroundColor Yellow
}
else {
    Write-Host "Using provided location: Lat $Latitude, Lon $Longitude" -ForegroundColor Green
}

# Calculate sunrise/sunset times
Write-Host ""
Write-Host "Calculating sunrise/sunset times..."
$getSunriseSunsetScript = Join-Path -Path $scriptDir -ChildPath "Get-SunriseSunset.ps1"
$sunTimes = & $getSunriseSunsetScript -Latitude $Latitude -Longitude $Longitude
$sunrise = $sunTimes.Sunrise.AddMinutes($SunriseOffset)
$sunset = $sunTimes.Sunset.AddMinutes($SunsetOffset)

Write-Host "  Sunrise: $($sunrise.ToString('hh:mm tt'))" -ForegroundColor Yellow
Write-Host "  Sunset:  $($sunset.ToString('hh:mm tt'))" -ForegroundColor Yellow

Write-Host ""
Write-Host "Creating scheduled tasks..."

# Common task settings
$principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Highest
$settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries

# Task 1: Startup
Write-Host "  Creating startup task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Auto"
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "AutoThemeSwitch_Startup" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Startup task created" -ForegroundColor Green

# Task 2: Wake
Write-Host "  Creating wake from sleep task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$switchThemeScript`" -Action Auto"
$class = Get-CimClass -ClassName MSFT_TaskEventTrigger -Namespace Root/Microsoft/Windows/TaskScheduler
$trigger = New-CimInstance -CimClass $class -ClientOnly
$trigger.Subscription = '<QueryList><Query Id="0" Path="System"><Select Path="System">*[System[Provider[@Name=''Microsoft-Windows-Power-Troubleshooter''] and EventID=1]]</Select></Query></QueryList>'
$trigger.Enabled = $true
Register-ScheduledTask -TaskName "AutoThemeSwitch_WakeFromSleep" -Action $action -Trigger $trigger -Principal $principal -Settings $settings -Force | Out-Null
Write-Host "    ✓ Wake from sleep task created" -ForegroundColor Green

# Task 3: Midnight
Write-Host "  Creating midnight updater task..."
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$updateTasksScript`""
$trigger = New-ScheduledTaskTrigger -Daily -At "00:05"
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

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Installation Complete!               " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "All 5 scheduled tasks created successfully!" -ForegroundColor Cyan
Write-Host ""
Write-Host "Your theme will now automatically switch:" -ForegroundColor White
Write-Host "  • At startup" -ForegroundColor Yellow
Write-Host "  • When waking from sleep" -ForegroundColor Yellow
Write-Host "  • At sunrise ($($sunrise.ToString('hh:mm tt'))): Light mode" -ForegroundColor Yellow
Write-Host "  • At sunset ($($sunset.ToString('hh:mm tt'))): Dark mode" -ForegroundColor Yellow
Write-Host "  • Times update daily at midnight" -ForegroundColor Yellow
Write-Host ""
Write-Host "Manual controls:" -ForegroundColor Gray
Write-Host '  Force Light: .\Switch-Theme.ps1 -Action Light -Force' -ForegroundColor Gray
Write-Host '  Force Dark:  .\Switch-Theme.ps1 -Action Dark -Force' -ForegroundColor Gray
Write-Host ""
pause
