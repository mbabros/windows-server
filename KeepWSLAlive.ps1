<#
.SYNOPSIS
    Registers and maintains a Windows Scheduled Task to keep WSL running as a background service.

.DESCRIPTION
    Runs at Windows boot (whether user is logged in or not) and starts a persistent,
    zero-CPU background process inside WSL to keep the distribution and its systemd services
    continuously active.

.PARAMETER Distro
    The WSL distribution to keep alive (default: Ubuntu-26.04).

.PARAMETER TaskName
    Name of the scheduled task (default: KeepWSLAlive).
#>
[CmdletBinding()]
param(
    [string]$Distro = "Ubuntu-26.04",
    [string]$TaskName = "KeepWSLAlive"
)

$ErrorActionPreference = "Stop"

# 1. Define the Action (runs zero-CPU sleep infinity inside WSL as root)
$action = New-ScheduledTaskAction `
    -Execute "C:\Windows\System32\wsl.exe" `
    -Argument "-d $Distro -u root --exec sleep infinity"

# 2. Define the Triggers (startup with delay + logon fallback)
$triggerBoot = New-ScheduledTaskTrigger -AtStartup
$triggerBoot.Delay = 'PT15S'
$triggerLogon = New-ScheduledTaskTrigger -AtLogOn -User (whoami)

# 3. Define the Settings (unlimited execution time, auto-retry on failure, battery resilience)
$settings = New-ScheduledTaskSettingsSet `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries `
    -DontStopOnIdleEnd `
    -ExecutionTimeLimit (New-TimeSpan -Days 0) `
    -MultipleInstances IgnoreNew `
    -RestartCount 3 `
    -RestartInterval (New-TimeSpan -Minutes 1) `
    -StartWhenAvailable

# 4. Define the Principal (runs with highest elevation under S4U)
$principal = New-ScheduledTaskPrincipal `
    -UserId (whoami) `
    -LogonType S4U `
    -RunLevel Highest

# 5. Register the Task
try {
    Register-ScheduledTask `
        -TaskName $TaskName `
        -Action $action `
        -Trigger @($triggerBoot, $triggerLogon) `
        -Settings $settings `
        -Principal $principal `
        -Settings $settings `
        -Principal $principal `
        -Description "Runs at startup to ensure the $Distro WSL instance stays running permanently as a background service." `
        -Force | Out-Null

    Write-Host "? Scheduled Task '$TaskName' successfully registered for distro '$Distro'." -ForegroundColor Green
    
    # Attempt to start immediately
    Stop-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Start-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    Write-Host "? Task started." -ForegroundColor Green
}
catch {
    Write-Error "Failed to register scheduled task: $($_.Exception.Message)"
}
