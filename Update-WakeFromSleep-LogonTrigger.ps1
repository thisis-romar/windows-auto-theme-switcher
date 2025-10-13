#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Updates the WakeFromSleep task to use a logon trigger instead of event-based trigger.

.DESCRIPTION
    Removes the existing WakeFromSleep task that uses Power-Troubleshooter events
    and recreates it with an AtLogOn trigger, which is more reliable on Windows 11.

.NOTES
    Run as Administrator
#>

Write-Host "`n🔧 Updating AutoThemeSwitch_WakeFromSleep Task" -ForegroundColor Cyan
Write-Host "=" * 60 -ForegroundColor Gray

# Check if running as admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "❌ This script must be run as Administrator!" -ForegroundColor Red
    exit 1
}

$TaskName = "AutoThemeSwitch_WakeFromSleep"
$ScriptPath = Join-Path $PSScriptRoot "Switch-Theme.ps1"

# Step 1: Remove existing task
Write-Host "`n📋 Step 1: Removing existing task..." -ForegroundColor Yellow
try {
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "   ✅ Removed existing task" -ForegroundColor Green
    } else {
        Write-Host "   ℹ️  Task does not exist (will create new)" -ForegroundColor Cyan
    }
} catch {
    Write-Host "   ⚠️  Error removing task: $_" -ForegroundColor Yellow
}

# Step 2: Create new task with logon trigger
Write-Host "`n📋 Step 2: Creating new task with logon trigger..." -ForegroundColor Yellow

# Create action
$action = New-ScheduledTaskAction `
    -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -WindowStyle Hidden -File `"$ScriptPath`""

# Create logon trigger for current user
$trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME

# Create task settings
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -StartWhenAvailable `
    -ExecutionTimeLimit (New-TimeSpan -Hours 1)

# Register the task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger $trigger `
        -Settings $settings `
        -User $env:USERNAME `
        -RunLevel Highest `
        -Description "Switch theme when user logs on (includes after wake from sleep)" `
        -Force | Out-Null
    
    Write-Host "   ✅ Task created successfully" -ForegroundColor Green
} catch {
    Write-Host "   ❌ Error creating task: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Verify the task
Write-Host "`n📋 Step 3: Verifying task..." -ForegroundColor Yellow

$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
if ($task) {
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    
    Write-Host "`n✅ Task Updated Successfully!" -ForegroundColor Green
    Write-Host "`n   Task Details:" -ForegroundColor Cyan
    Write-Host "   - Name: $($task.TaskName)" -ForegroundColor White
    Write-Host "   - State: $($task.State)" -ForegroundColor White
    Write-Host "   - Trigger: AtLogOn for user $env:USERNAME" -ForegroundColor White
    Write-Host "   - Action: Run Switch-Theme.ps1" -ForegroundColor White
    Write-Host "   - Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "   - Last Result: $($taskInfo.LastTaskResult)" -ForegroundColor White
    
    Write-Host "`n💡 How it works:" -ForegroundColor Cyan
    Write-Host "   - Task will run whenever you log in to Windows" -ForegroundColor White
    Write-Host "   - This includes after waking from sleep (if you unlock)" -ForegroundColor White
    Write-Host "   - More reliable than event-based triggers on Windows 11" -ForegroundColor White
    
    Write-Host "`n🧪 Testing the task now..." -ForegroundColor Yellow
    Start-ScheduledTask -TaskName $TaskName
    Start-Sleep -Seconds 3
    
    $taskInfo = Get-ScheduledTaskInfo -TaskName $TaskName
    Write-Host "   Last Run: $($taskInfo.LastRunTime)" -ForegroundColor White
    Write-Host "   Result: $($taskInfo.LastTaskResult) $(if($taskInfo.LastTaskResult -eq 0){'✅ Success'}else{'❌ Failed'})" -ForegroundColor White
    
    Write-Host "`n📄 Check the log:" -ForegroundColor Cyan
    Write-Host "   H:\Windows-Tools\AutoThemeSwitcher\logs\theme-switch.log" -ForegroundColor White
    
} else {
    Write-Host "❌ Task verification failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n" + "=" * 60 -ForegroundColor Gray
Write-Host "✅ Update Complete!" -ForegroundColor Green
Write-Host "`nThe task will now run when you:" -ForegroundColor Cyan
Write-Host "  • Log in to Windows" -ForegroundColor White
Write-Host "  • Unlock your screen after waking from sleep" -ForegroundColor White
Write-Host "`n"
