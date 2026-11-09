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

### 3. Automated VM & Homelab Provisioning with Ansible

This repository includes full Infrastructure as Code (IaC) playbooks to provision a clean Ubuntu 26.04 LTS instance under WSL2, configure Docker CE, install Coolify, and deploy Immich with data migration:

```bash
cd ansible

# 1. Test connectivity
ansible all -m ping

# 2. Run end-to-end homelab provisioning
ansible-playbook site.yml
```

Or execute individual playbooks:
- `ansible-playbook playbooks/01-host-provision-wsl.yml`: Configures Windows host, installs Ubuntu 26.04, registers KeepWSLAlive task, bootstraps SSH on port 2222.
- `ansible-playbook playbooks/02-guest-setup-docker.yml`: Installs official Docker CE and systemd services inside Ubuntu.
- `ansible-playbook playbooks/03-guest-install-coolify.yml`: Installs Coolify dashboard and Traefik reverse proxy.
- `ansible-playbook playbooks/04-migrate-immich.yml`: Restores Immich PostgreSQL database and starts Immich pointing to host photos on `/mnt/d/ImmichPhotos`.

---

## Repository Structure

```text
├── ansible/
│   ├── ansible.cfg            # Ansible CLI & SSH connection settings
│   ├── inventory.ini          # Windows host (:22) and WSL guest (:2222) inventory
│   ├── site.yml               # Master orchestration playbook
│   └── playbooks/
│       ├── 01-host-provision-wsl.yml    # Distro provisioning & SSH bootstrap
│       ├── 02-guest-setup-docker.yml    # Docker CE installation
│       ├── 03-guest-install-coolify.yml # Coolify deployment
│       └── 04-migrate-immich.yml        # Immich database restore & compose stack
├── KeepWSLAlive.ps1           # Task Scheduler registration script
├── Install-UptimeProfile.ps1  # Installs uptime profile to all PowerShell versions
├── profile.ps1                # Standalone profile snippet with uptime function
├── wsl-config/
│   ├── .wslconfig             # Global host WSL2 settings (place in %USERPROFILE%\.wslconfig)
│   └── wsl.conf               # In-distro settings (place in /etc/wsl.conf)
└── README.md
```
