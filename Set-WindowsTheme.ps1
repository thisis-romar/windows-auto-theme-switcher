<#
.SYNOPSIS
    Sets Windows 11 theme to Light or Dark mode.

.DESCRIPTION
    Modifies Windows registry to change the system and app theme.
    Changes take effect immediately without requiring logout.

.PARAMETER Theme
    The theme to apply: "Light" or "Dark"

.PARAMETER LogPath
    Path to log file. If not specified, no logging is performed.

.EXAMPLE
    Set-WindowsTheme -Theme Dark
    Switches to dark mode.

.EXAMPLE
    Set-WindowsTheme -Theme Light -LogPath "C:\logs\theme.log"
    Switches to light mode and logs the action.

.NOTES
    Version: 1.0.0
    Author: Auto Theme Switcher
    Requires: Windows 11
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("Light", "Dark")]
    [string]$Theme,
    
    [Parameter(Mandatory = $false)]
    [string]$LogPath = $null
)

# Registry path for personalization settings
$registryPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"

# Log function
function Write-Log {
    param(
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    if ($LogPath) {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $logMessage = "$timestamp | $Level | $Message"
        
        try {
            # Ensure log directory exists
            $logDir = Split-Path -Path $LogPath -Parent
            if ($logDir -and -not (Test-Path -Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }
            
            # Write to log file
            Add-Content -Path $LogPath -Value $logMessage
            
            # Rotate log if it exceeds 1MB
            if (Test-Path -Path $LogPath) {
                $logFile = Get-Item -Path $LogPath
                if ($logFile.Length -gt 1MB) {
                    # Keep last 5 log files
                    for ($i = 4; $i -gt 0; $i--) {
                        $oldLog = "$LogPath.$i"
                        $newLog = "$LogPath.$($i + 1)"
                        if (Test-Path -Path $oldLog) {
                            Move-Item -Path $oldLog -Destination $newLog -Force
                        }
                    }
                    Move-Item -Path $LogPath -Destination "$LogPath.1" -Force
                }
            }
        }
        catch {
            Write-Warning "Failed to write to log: $_"
        }
    }
}

# Get current theme
function Get-CurrentTheme {
    try {
        $appsValue = Get-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -ErrorAction SilentlyContinue
        $systemValue = Get-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -ErrorAction SilentlyContinue
        
        if ($appsValue.AppsUseLightTheme -eq 1 -and $systemValue.SystemUsesLightTheme -eq 1) {
            return "Light"
        }
        elseif ($appsValue.AppsUseLightTheme -eq 0 -and $systemValue.SystemUsesLightTheme -eq 0) {
            return "Dark"
        }
        else {
            return "Mixed"
        }
    }
    catch {
        return "Unknown"
    }
}

try {
    # Check if registry path exists
    if (-not (Test-Path -Path $registryPath)) {
        Write-Log -Message "Registry path not found: $registryPath" -Level "ERROR"
        throw "Registry path not found. This script requires Windows 10/11."
    }
    
    # Get current theme
    $currentTheme = Get-CurrentTheme
    Write-Log -Message "Current theme: $currentTheme"
    
    # Check if theme change is needed
    if ($currentTheme -eq $Theme) {
        Write-Log -Message "Theme is already set to $Theme. No change needed."
        Write-Host "Theme is already set to $Theme." -ForegroundColor Green
        exit 0
    }
    
    # Set theme values (0 = Dark, 1 = Light)
    $themeValue = if ($Theme -eq "Light") { 1 } else { 0 }
    
    # Apply theme to both Apps and System
    Set-ItemProperty -Path $registryPath -Name "AppsUseLightTheme" -Value $themeValue -Type DWord
    Set-ItemProperty -Path $registryPath -Name "SystemUsesLightTheme" -Value $themeValue -Type DWord
    
    Write-Log -Message "Successfully switched theme from $currentTheme to $Theme"
    Write-Host "Successfully switched theme to $Theme mode." -ForegroundColor Green
    
    # Notify system of settings change (helps apply theme immediately)
    Add-Type -TypeDefinition @"
        using System;
        using System.Runtime.InteropServices;
        public class WinAPI {
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern IntPtr SendMessageTimeout(
                IntPtr hWnd,
                uint Msg,
                UIntPtr wParam,
                string lParam,
                uint fuFlags,
                uint uTimeout,
                out UIntPtr lpdwResult
            );
        }
"@
    
    $HWND_BROADCAST = [IntPtr]0xffff
    $WM_SETTINGCHANGE = 0x1a
    $result = [UIntPtr]::Zero
    
    [WinAPI]::SendMessageTimeout(
        $HWND_BROADCAST,
        $WM_SETTINGCHANGE,
        [UIntPtr]::Zero,
        "ImmersiveColorSet",
        2,
        5000,
        [ref]$result
    ) | Out-Null
    
    Write-Log -Message "Broadcast WM_SETTINGCHANGE message to apply theme"
    
    return [PSCustomObject]@{
        Success = $true
        PreviousTheme = $currentTheme
        NewTheme = $Theme
        Timestamp = Get-Date
    }
}
catch {
    $errorMessage = "Failed to set theme: $_"
    Write-Log -Message $errorMessage -Level "ERROR"
    Write-Error $errorMessage
    
    return [PSCustomObject]@{
        Success = $false
        Error = $_.Exception.Message
        Timestamp = Get-Date
    }
}
