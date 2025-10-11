<#
.SYNOPSIS
    Verifies Auto Theme Switcher installation status.

.DESCRIPTION
    Checks if all scheduled tasks are properly installed and provides
    troubleshooting information if issues are found.

.NOTES
    Version: 1.0.0
    Created: October 10, 2025
#>

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto Theme Switcher - Verification  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Expected tasks
$expectedTasks = @(
    "AutoThemeSwitch_Startup",
    "AutoThemeSwitch_WakeFromSleep",
    "AutoThemeSwitch_MidnightUpdater",
    "AutoThemeSwitch_Sunrise",
    "AutoThemeSwitch_Sunset"
)

# Check each task
$foundTasks = @()
$missingTasks = @()

Write-Host "Checking for scheduled tasks..." -ForegroundColor Yellow
Write-Host ""

foreach ($taskName in $expectedTasks) {
    try {
        $task = Get-ScheduledTask -TaskName $taskName -ErrorAction Stop
        $foundTasks += $taskName
        
        $info = Get-ScheduledTaskInfo -TaskName $taskName
        Write-Host "  ✓ $taskName" -ForegroundColor Green
        Write-Host "    State: $($task.State)" -ForegroundColor Gray
        if ($info.NextRunTime) {
            Write-Host "    Next Run: $($info.NextRunTime)" -ForegroundColor Gray
        }
        Write-Host ""
    }
    catch {
        $missingTasks += $taskName
        Write-Host "  ✗ $taskName - NOT FOUND" -ForegroundColor Red
        Write-Host ""
    }
}

# Summary
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Summary:" -ForegroundColor Cyan
Write-Host "  Tasks Found: $($foundTasks.Count) / $($expectedTasks.Count)" -ForegroundColor $(if ($foundTasks.Count -eq $expectedTasks.Count) { "Green" } else { "Yellow" })

if ($missingTasks.Count -gt 0) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Red
    Write-Host "  INSTALLATION INCOMPLETE" -ForegroundColor Red
    Write-Host "========================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Missing tasks:" -ForegroundColor Yellow
    foreach ($task in $missingTasks) {
        Write-Host "  • $task" -ForegroundColor Red
    }
    Write-Host ""
    Write-Host "To fix this, run the installer as Administrator:" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  1. Right-click PowerShell" -ForegroundColor Cyan
    Write-Host "  2. Select 'Run as Administrator'" -ForegroundColor Cyan
    Write-Host "  3. Navigate to: $PSScriptRoot" -ForegroundColor Cyan
    Write-Host "  4. Run: .\Install-AutoThemeSwitcher.ps1" -ForegroundColor Cyan
    Write-Host ""
}
else {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "  INSTALLATION SUCCESSFUL! ✓" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Auto Theme Switcher is properly installed and will:" -ForegroundColor Cyan
    Write-Host "  • Switch theme at startup" -ForegroundColor White
    Write-Host "  • Switch theme when waking from sleep" -ForegroundColor White
    Write-Host "  • Switch to Light mode at sunrise" -ForegroundColor White
    Write-Host "  • Switch to Dark mode at sunset" -ForegroundColor White
    Write-Host "  • Update times daily at midnight" -ForegroundColor White
    Write-Host ""
}

# Check current theme
Write-Host "Current System Status:" -ForegroundColor Yellow
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
try {
    $appsValue = (Get-ItemProperty -Path $registryPath -Name "AppsUseLightTheme").AppsUseLightTheme
    $currentTheme = if ($appsValue -eq 1) { "Light Mode" } else { "Dark Mode" }
    Write-Host "  Current Theme: $currentTheme" -ForegroundColor Cyan
}
catch {
    Write-Host "  Could not determine current theme" -ForegroundColor Red
}

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
Write-Host "  Running as Admin: $isAdmin" -ForegroundColor $(if ($isAdmin) { "Green" } else { "Yellow" })

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
