<#
.SYNOPSIS
    PowerShell profile snippet providing custom uptime reporting.

.DESCRIPTION
    Overrides/defines the 'uptime' command in PowerShell to display uptime and boot timestamp
    matching the format:
    System Uptime: X days, Y hours, Z mins, W secs (Boot: YYYY-MM-DD HH:MM:SS)
#>
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
