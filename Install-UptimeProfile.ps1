<#
.SYNOPSIS
    Installs the custom 'uptime' function into all PowerShell profiles on Windows.

.DESCRIPTION
    Deploys the custom 'uptime' formatter to both PowerShell 7 and Windows PowerShell 5.1
    user profiles ($PROFILE.CurrentUserAllHosts and $PROFILE.CurrentUserCurrentHost),
    and ensures ExecutionPolicy permits local scripts.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$profileFunction = @'

# --- Custom Uptime Function ---
function uptime {
    [CmdletBinding()]
    param(
        [switch]$Since
    )

    $boot = (Get-CimInstance -ClassName Win32_OperatingSystem).LastBootUpTime
    if ($Since) {
        return $boot
    }

    $span = (Get-Date) - $boot
    "System Uptime: $($span.Days) days, $($span.Hours) hours, $($span.Minutes) mins, $($span.Seconds) secs (Boot: $($boot.ToString('yyyy-MM-dd HH:mm:ss')))"
}
# ------------------------------
'@

$directories = @(
    (Join-Path $HOME "Documents\PowerShell"),
    (Join-Path $HOME "Documents\WindowsPowerShell")
)

foreach ($dir in $directories) {
    if (-not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    $allHosts = Join-Path $dir "profile.ps1"
    $currentHost = Join-Path $dir "Microsoft.PowerShell_profile.ps1"

    Set-Content -Path $allHosts -Value $profileFunction -Force
    Set-Content -Path $currentHost -Value $profileFunction -Force
    Write-Host "? Profile updated: $allHosts" -ForegroundColor Green
}

# Ensure CurrentUser execution policy is RemoteSigned for Windows PowerShell
try {
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force -ErrorAction SilentlyContinue
    Write-Host "? CurrentUser ExecutionPolicy set to RemoteSigned." -ForegroundColor Green
}
catch {
    Write-Warning "Could not set execution policy: $($_.Exception.Message)"
}

Write-Host "`nTest output:" -ForegroundColor Cyan
. (Join-Path $HOME "Documents\PowerShell\profile.ps1")
uptime
