# Windows Server & WSL Automation Scripts

A collection of PowerShell scripts and configuration files designed for Windows homelab servers to manage persistent background WSL instances, custom shell profiles, and server telemetry.

## Features

- **KeepWSLAlive (`KeepWSLAlive.ps1`)**:
  - Registers a Windows Scheduled Task (`KeepWSLAlive`) running at Windows startup (`AtStartup`) under the user's S4U token (runs whether logged on or not).
  - Starts a persistent zero-CPU background process (`wsl.exe -d <Distro> -u root --exec sleep infinity`) so the WSL utility VM and distribution never stop.
  - Keeps `systemd` background services (Docker, SSH, web proxies, databases) continuously alive and listening.
- **Custom Uptime Formatter (`profile.ps1`, `Install-UptimeProfile.ps1`)**:
  - Replaces default PowerShell `uptime` / `Get-Uptime` with a human-readable format:
    ```text
    System Uptime: 1 days, 6 hours, 33 mins, 2 secs (Boot: 2026-11-07 07:16:53)
    ```
  - Compatible with both **PowerShell 7 (`pwsh`)** and **Windows PowerShell 5.1**.
  - Supports non-interactive SSH shells and interactive console sessions.
- **WSL 2 Configuration Templates (`wsl-config/`)**:
  - `.wslconfig`: Disables VM idle timeouts (`vmIdleTimeout=-1`), enables mirrored networking (`networkingMode=mirrored`), and DNS tunneling.
  - `wsl.conf`: Enables `systemd=true` and sets default non-root user.

---

## Installation & Usage

### 1. Setting Up Persistent WSL Service

Run PowerShell as Administrator or as your local user with Task Scheduler rights:

```powershell
.\KeepWSLAlive.ps1 -Distro "Ubuntu-26.04"
```

To verify the task and WSL state:

```powershell
Get-ScheduledTask KeepWSLAlive
wsl -l -v
```

### 2. Installing Custom Uptime Format

Run the installer script in PowerShell:

```powershell
.\Install-UptimeProfile.ps1
```

Test it immediately by running:

```powershell
uptime
```

---

## Repository Structure

```text
├── KeepWSLAlive.ps1           # Task Scheduler registration script
├── Install-UptimeProfile.ps1  # Installs uptime profile to all PowerShell versions
├── profile.ps1                # Standalone profile snippet with uptime function
├── wsl-config/
│   ├── .wslconfig             # Global host WSL2 settings (place in %USERPROFILE%\.wslconfig)
│   └── wsl.conf               # In-distro settings (place in /etc/wsl.conf)
└── README.md
```
