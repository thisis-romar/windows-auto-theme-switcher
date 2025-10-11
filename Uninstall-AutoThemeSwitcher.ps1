<#
.SYNOPSIS
    Uninstalls Auto Theme Switcher and removes all scheduled tasks.

.DESCRIPTION
    Removes all scheduled tasks created by the installer and optionally
    deletes configuration files and logs.

.PARAMETER KeepConfig
    Keep configuration and log files (only remove scheduled tasks)

.PARAMETER ResetTheme
    Reset Windows theme to Light mode after uninstallation

.EXAMPLE
    .\Uninstall-AutoThemeSwitcher.ps1
    Removes all tasks and files.

.EXAMPLE
    .\Uninstall-AutoThemeSwitcher.ps1 -KeepConfig
    Removes tasks but keeps configuration and logs.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Requires: Administrator privileges
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$KeepConfig,
    
    [Parameter(Mandatory = $false)]
    [switch]$ResetTheme
)

# Check for admin rights
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "======================================" -ForegroundColor Red
    Write-Host "  ADMINISTRATOR PRIVILEGES REQUIRED  " -ForegroundColor Red
    Write-Host "======================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "This uninstaller needs to remove scheduled tasks, which requires admin rights."
    Write-Host ""
    Write-Host "Please run PowerShell as Administrator and try again."
    Write-Host ""
    pause
    exit 1
}

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  Auto Theme Switcher - Uninstallation  " -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Get script directory
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Confirm uninstallation
Write-Host "This will remove Auto Theme Switcher from your system." -ForegroundColor Yellow
Write-Host ""
$confirm = Read-Host "Do you want to continue? (Y/N)"

if ($confirm -ne 'Y' -and $confirm -ne 'y') {
    Write-Host "Uninstallation cancelled." -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Removing scheduled tasks..."

# List of tasks to remove
$taskNames = @(
    "AutoThemeSwitch_Startup",
    "AutoThemeSwitch_WakeFromSleep",
    "AutoThemeSwitch_MidnightUpdater",
    "AutoThemeSwitch_Sunrise",
    "AutoThemeSwitch_Sunset"
)

$removedCount = 0
foreach ($taskName in $taskNames) {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
        if ($task) {
            Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
            Write-Host "  ✓ Removed: $taskName" -ForegroundColor Green
            $removedCount++
        }
        else {
            Write-Host "  - Not found: $taskName" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "  Failed to remove: $taskName - $_"
    }
}

Write-Host ""
Write-Host "Removed $removedCount scheduled task(s)." -ForegroundColor Green

# Handle configuration and logs
if (-not $KeepConfig) {
    Write-Host ""
    Write-Host "Cleaning up files..."
    
    $configPath = Join-Path -Path $scriptDir -ChildPath "config.json"
    $logsDir = Join-Path -Path $scriptDir -ChildPath "logs"
    
    # Remove config
    if (Test-Path -Path $configPath) {
        Remove-Item -Path $configPath -Force
        Write-Host "  ✓ Removed configuration file" -ForegroundColor Green
    }
    
    # Remove logs
    if (Test-Path -Path $logsDir) {
        Remove-Item -Path $logsDir -Recurse -Force
        Write-Host "  ✓ Removed logs directory" -ForegroundColor Green
    }
}
else {
    Write-Host ""
    Write-Host "Configuration and logs preserved." -ForegroundColor Yellow
}

# Reset theme if requested
if ($ResetTheme) {
    Write-Host ""
    Write-Host "Resetting theme to Light mode..."
    
    $setThemeScript = Join-Path -Path $scriptDir -ChildPath "Set-WindowsTheme.ps1"
    if (Test-Path -Path $setThemeScript) {
        & $setThemeScript -Theme Light
    }
    else {
        Write-Warning "Set-WindowsTheme.ps1 not found. Skipping theme reset."
    }
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Uninstallation Complete!             " -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "Auto Theme Switcher has been removed from your system." -ForegroundColor Cyan
Write-Host ""

if ($KeepConfig) {
    Write-Host "Note: Configuration and logs were preserved." -ForegroundColor Yellow
    Write-Host "You can manually delete the AutoThemeSwitcher folder if desired." -ForegroundColor Yellow
    Write-Host ""
}

Write-Host "Thank you for using Auto Theme Switcher!" -ForegroundColor Cyan
Write-Host ""
pause
