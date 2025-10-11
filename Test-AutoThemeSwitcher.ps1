<#
.SYNOPSIS
    Tests Auto Theme Switcher functionality.

.DESCRIPTION
    Validates all components of Auto Theme Switcher including:
    - Sunrise/sunset calculations
    - Theme switching
    - Configuration loading
    - Scheduled task existence
    - Log file creation

.EXAMPLE
    .\Test-AutoThemeSwitcher.ps1
    Runs all tests and displays results.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
#>

[CmdletBinding()]
param()

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$testResults = @()

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Auto Theme Switcher - Test Suite    " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Configuration exists
Write-Host "Test 1: Configuration file..." -NoNewline
$configPath = Join-Path -Path $scriptDir -ChildPath "config.json"
if (Test-Path -Path $configPath) {
    try {
        $config = Get-Content -Path $configPath -Raw | ConvertFrom-Json
        Write-Host " PASS" -ForegroundColor Green
        $testResults += @{ Test = "Configuration"; Result = "PASS" }
    }
    catch {
        Write-Host " FAIL (Invalid JSON)" -ForegroundColor Red
        $testResults += @{ Test = "Configuration"; Result = "FAIL"; Error = $_.Exception.Message }
    }
}
else {
    Write-Host " FAIL (Not found)" -ForegroundColor Red
    $testResults += @{ Test = "Configuration"; Result = "FAIL"; Error = "File not found" }
}

# Test 2: Sunrise/Sunset calculation
Write-Host "Test 2: Sunrise/Sunset calculation..." -NoNewline
$getSunriseSunsetScript = Join-Path -Path $scriptDir -ChildPath "Get-SunriseSunset.ps1"
if (Test-Path -Path $getSunriseSunsetScript) {
    try {
        $sunTimes = & $getSunriseSunsetScript -Latitude 40.7128 -Longitude -74.0060
        if ($sunTimes.Sunrise -and $sunTimes.Sunset) {
            Write-Host " PASS" -ForegroundColor Green
            Write-Host "   Sunrise: $($sunTimes.Sunrise.ToString('hh:mm tt'))" -ForegroundColor Gray
            Write-Host "   Sunset:  $($sunTimes.Sunset.ToString('hh:mm tt'))" -ForegroundColor Gray
            $testResults += @{ Test = "Solar Calculation"; Result = "PASS" }
        }
        else {
            Write-Host " FAIL (Invalid result)" -ForegroundColor Red
            $testResults += @{ Test = "Solar Calculation"; Result = "FAIL"; Error = "Invalid sun times" }
        }
    }
    catch {
        Write-Host " FAIL" -ForegroundColor Red
        $testResults += @{ Test = "Solar Calculation"; Result = "FAIL"; Error = $_.Exception.Message }
    }
}
else {
    Write-Host " FAIL (Script not found)" -ForegroundColor Red
    $testResults += @{ Test = "Solar Calculation"; Result = "FAIL"; Error = "Script missing" }
}

# Test 3: Theme switching script exists
Write-Host "Test 3: Theme switching script..." -NoNewline
$setThemeScript = Join-Path -Path $scriptDir -ChildPath "Set-WindowsTheme.ps1"
if (Test-Path -Path $setThemeScript) {
    Write-Host " PASS" -ForegroundColor Green
    $testResults += @{ Test = "Theme Script"; Result = "PASS" }
}
else {
    Write-Host " FAIL (Not found)" -ForegroundColor Red
    $testResults += @{ Test = "Theme Script"; Result = "FAIL"; Error = "Script missing" }
}

# Test 4: Main orchestrator script
Write-Host "Test 4: Main orchestrator script..." -NoNewline
$switchThemeScript = Join-Path -Path $scriptDir -ChildPath "Switch-Theme.ps1"
if (Test-Path -Path $switchThemeScript) {
    Write-Host " PASS" -ForegroundColor Green
    $testResults += @{ Test = "Orchestrator Script"; Result = "PASS" }
}
else {
    Write-Host " FAIL (Not found)" -ForegroundColor Red
    $testResults += @{ Test = "Orchestrator Script"; Result = "FAIL"; Error = "Script missing" }
}

# Test 5: Scheduled tasks
Write-Host "Test 5: Scheduled tasks..." -NoNewline
$expectedTasks = @(
    "AutoThemeSwitch_Startup",
    "AutoThemeSwitch_WakeFromSleep",
    "AutoThemeSwitch_MidnightUpdater",
    "AutoThemeSwitch_Sunrise",
    "AutoThemeSwitch_Sunset"
)

$foundTasks = @()
$missingTasks = @()

foreach ($taskName in $expectedTasks) {
    $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
    if ($task) {
        $foundTasks += $taskName
    }
    else {
        $missingTasks += $taskName
    }
}

if ($missingTasks.Count -eq 0) {
    Write-Host " PASS (All 5 tasks found)" -ForegroundColor Green
    $testResults += @{ Test = "Scheduled Tasks"; Result = "PASS" }
}
else {
    Write-Host " FAIL ($($foundTasks.Count)/5 tasks found)" -ForegroundColor Red
    foreach ($missing in $missingTasks) {
        Write-Host "   Missing: $missing" -ForegroundColor Yellow
    }
    $testResults += @{ Test = "Scheduled Tasks"; Result = "FAIL"; Error = "Missing: $($missingTasks -join ', ')" }
}

# Test 6: Log directory
Write-Host "Test 6: Log directory..." -NoNewline
$logsDir = Join-Path -Path $scriptDir -ChildPath "logs"
if (Test-Path -Path $logsDir) {
    Write-Host " PASS" -ForegroundColor Green
    $testResults += @{ Test = "Log Directory"; Result = "PASS" }
}
else {
    Write-Host " FAIL (Not found)" -ForegroundColor Red
    $testResults += @{ Test = "Log Directory"; Result = "FAIL"; Error = "Directory missing" }
}

# Test 7: Registry access
Write-Host "Test 7: Registry access..." -NoNewline
try {
    $registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    if (Test-Path -Path $registryPath) {
        $appsValue = Get-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction Stop
        Write-Host " PASS" -ForegroundColor Green
        $testResults += @{ Test = "Registry Access"; Result = "PASS" }
    }
    else {
        Write-Host " FAIL (Registry path not found)" -ForegroundColor Red
        $testResults += @{ Test = "Registry Access"; Result = "FAIL"; Error = "Path not found" }
    }
}
catch {
    Write-Host " FAIL" -ForegroundColor Red
    $testResults += @{ Test = "Registry Access"; Result = "FAIL"; Error = $_.Exception.Message }
}

# Summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Test Summary                         " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

$passCount = ($testResults | Where-Object { $_.Result -eq "PASS" }).Count
$failCount = ($testResults | Where-Object { $_.Result -eq "FAIL" }).Count
$totalCount = $testResults.Count

Write-Host ""
Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed:      $passCount" -ForegroundColor Green
Write-Host "Failed:      $failCount" -ForegroundColor $(if ($failCount -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($failCount -eq 0) {
    Write-Host "All tests passed! Auto Theme Switcher is properly configured." -ForegroundColor Green
}
else {
    Write-Host "Some tests failed. Please review the errors above." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Common fixes:" -ForegroundColor Yellow
    Write-Host "  - If tasks are missing, run: .\Install-AutoThemeSwitcher.ps1" -ForegroundColor Gray
    Write-Host "  - If scripts are missing, re-download the complete package" -ForegroundColor Gray
    Write-Host "  - If registry access fails, ensure you're on Windows 10/11" -ForegroundColor Gray
}

Write-Host ""
