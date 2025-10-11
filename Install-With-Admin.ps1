<#
.SYNOPSIS
    Self-elevating launcher for Auto Theme Switcher installation.

.DESCRIPTION
    This script automatically requests administrator privileges and runs the installer.
    No need to manually "Run as Administrator" - just run this script normally!

.NOTES
    Version: 1.0.0
    Created: October 10, 2025
#>

# Get the directory where this script is located
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$installerPath = Join-Path -Path $scriptDir -ChildPath "Install-AutoThemeSwitcher.ps1"

# Check if running as administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "  Auto Theme Switcher - Easy Install" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Requesting administrator privileges..." -ForegroundColor Yellow
    Write-Host "Please click 'Yes' on the UAC prompt." -ForegroundColor Yellow
    Write-Host ""
    
    # Self-elevate
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$installerPath`"" -Verb RunAs -Wait
        
        Write-Host ""
        Write-Host "Installation completed!" -ForegroundColor Green
        Write-Host "You can close this window." -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "Installation was cancelled or failed." -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
    
    Write-Host ""
    pause
}
else {
    # Already running as admin, just run the installer
    & $installerPath
}
