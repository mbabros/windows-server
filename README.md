# WSL Docker Server & Automation

A complete Infrastructure as Code (IaC) and automation suite for running persistent Docker workloads, Coolify, and Immich on Windows via WSL2 (Ubuntu 26.04 LTS), with native background service management and server telemetry.

> **Architecture Documentation**: See [**`docs/ARCHITECTURE.md`**](docs/ARCHITECTURE.md) for comprehensive component flowcharts, mirrored networking sequences, dual-tier storage strategy, and remote mobile client ingress architecture.

---

## Features

- **Ansible Infrastructure as Code (`ansible/`)**:
  - Full end-to-end automation across both the Windows host (PowerShell over SSH) and the Ubuntu 26.04 WSL2 VM (native Linux over port 2222).
  - One-command orchestration via `site.yml`.
  - Dedicated playbooks for provisioning, Docker CE setup, Coolify installation, and Immich data migration & upgrades.
- **Windows Background WSL Service (`KeepWSLAlive.ps1` / Playbook 05)**:
  - Registers a Windows Scheduled Task (`KeepWSLAlive`) running at Windows startup (`AtStartup`) under the user's S4U token (runs whether logged on or not).
  - Starts a persistent zero-CPU background process (`wsl.exe -d <Distro> -u root --exec sleep infinity`) so the WSL utility VM and distribution never stop.
  - Keeps `systemd` background services (Docker, SSH, web proxies, databases) continuously alive and listening.
- **Custom Uptime Formatter (`profile.ps1`, `Install-UptimeProfile.ps1` / Playbook 05)**:
  - Replaces default PowerShell `uptime` / `Get-Uptime` with a human-readable format:
    ```text
    System Uptime: 0 days, 8 hours, 4 mins, 12 secs (Boot: 2026-11-08 16:01:48)
    ```
  - Compatible with both **PowerShell 7 (`pwsh`)** and **Windows PowerShell 5.1**.
  - Supports non-interactive SSH shells and interactive console sessions.
- **WSL 2 Configuration Templates (`wsl-config/`)**:
  - `.wslconfig`: Disables VM idle timeouts (`vmIdleTimeout=-1`, `instanceIdleTimeout=-1`), enables mirrored networking (`networkingMode=mirrored`), and DNS tunneling.
  - `wsl.conf`: Enables `systemd=true` and sets default non-root user.
- **Immich Photolab Suite & High-Capacity Storage (`ansible/playbooks/04-migrate-immich.yml`, `06-upgrade-immich.yml`)**:
  - High-capacity host NTFS storage mount (`D:\ImmichPhotos`) combined with fast Linux ext4 NVMe storage for PostgreSQL ACID transactions.
  - Support for read-only external libraries to index host photo libraries without data modification.
- **Dual-URL Mobile Routing & Direct Edge Ingress**:
  - Bypasses Cloudflare CDN 100 MB body size limits and 100-second timeouts by routing remote traffic through direct unproxied DNS to the edge reverse proxy.
  - Full support for large 4K 60fps HDR and ProRes video uploads directly from mobile devices.

---

## Installation & Usage

### 1. Automated Homelab Provisioning with Ansible

Run the full end-to-end orchestration from your control node (Mac/Linux):

```bash
cd ansible

# 1. Test connectivity across both Windows host and WSL guest
ansible all -m ping

# 2. Run end-to-end provisioning
ansible-playbook site.yml
```

Or execute individual playbooks modularly:
- `ansible-playbook playbooks/01-host-provision-wsl.yml`: Configures Windows host, installs Ubuntu 26.04 LTS, registers KeepWSLAlive task, and bootstraps SSH on port 2222.
- `ansible-playbook playbooks/05-windows-wsl-service-uptime.yml`: Consolidates PowerShell scripts to setup WSL as a permanent background service and deploys the custom `uptime` command into all PowerShell profiles.
- `ansible-playbook playbooks/02-guest-setup-docker.yml`: Installs official Docker CE, Compose plugin, and configures iptables bridging inside Ubuntu.
- `ansible-playbook playbooks/03-guest-install-coolify.yml`: Installs Coolify dashboard and Traefik reverse proxy.
- `ansible-playbook playbooks/04-migrate-immich.yml`: Restores PostgreSQL database and starts Immich pointing to host photos on `/mnt/d/ImmichPhotos`.
- `ansible-playbook playbooks/06-upgrade-immich.yml`: Pulls the latest Immich release images, recreates containers, applies schema migrations, and prunes older images.

---

### 2. Manual PowerShell Setup (Alternative)

If setting up directly on the Windows host without Ansible:

```powershell
# 1. Register persistent background WSL service
.\KeepWSLAlive.ps1 -Distro "Ubuntu-26.04"

# 2. Install custom uptime profile
.\Install-UptimeProfile.ps1
```

---

## Remote Ingress & Mobile App Setup (Dual-URL Routing)

To ensure reliable backups of large 4K/60fps smartphone videos and ProRes clips without running into Cloudflare Free Tier request body limits (100 MB) or timeouts (100s):

1. **DNS Ingress (Grey Cloud / Unproxied)**:
   - Configure your public DNS record (`immich.yourdomain.com`) as an **unproxied A record** (`proxied: false`) pointing directly to your edge reverse proxy (e.g. Caddy on OCI).
   - TLS is terminated directly at the edge reverse proxy using ACME / Let's Encrypt certificates (Cloudflare DNS-01 challenge).
   - Traffic is forwarded securely over a private Tailscale WireGuard mesh directly to WSL2 port `2283`.

2. **Immich Mobile App Configuration (iOS / Android)**:
   Under **Settings → Server** in the Immich mobile application:
   - **Server URL (External)**: `https://immich.yourdomain.com` (Used when on cellular or remote Wi-Fi).
   - **Internal Server URL**: `http://192.168.x.x:2283` (Direct LAN Wi-Fi address).

> **Why Dual URLs?** When your phone connects to your home Wi-Fi SSID, the Immich app automatically routes uploads directly across your local network at Gigabit LAN speed, bypassing the internet and consuming zero mobile data. When away from home, backups seamlessly switch to the direct edge reverse proxy without file upload caps.

For complete architectural flowcharts and dataflows, refer to [**`docs/ARCHITECTURE.md#6-remote-ingress--mobile-client-architecture-dual-url-routing`**](docs/ARCHITECTURE.md#6-remote-ingress--mobile-client-architecture-dual-url-routing).

---

## Repository Structure

```text
├── ansible/
│   ├── ansible.cfg            # Ansible CLI & SSH connection settings
│   ├── inventory.ini          # Windows host (:22) and WSL guest (:2222) inventory
│   ├── site.yml               # Master orchestration playbook (01 -> 05)
│   └── playbooks/
│       ├── 01-host-provision-wsl.yml            # Distro provisioning & SSH bootstrap
│       ├── 02-guest-setup-docker.yml            # Docker CE & iptables configuration
│       ├── 03-guest-install-coolify.yml         # Coolify deployment
│       ├── 04-migrate-immich.yml                # Immich database restore & compose stack
│       ├── 05-windows-wsl-service-uptime.yml    # WSL background service & uptime command
│       └── 06-upgrade-immich.yml                # Automated rolling release upgrades
├── docs/
│   └── ARCHITECTURE.md        # Comprehensive system diagrams, network topology & ingress guide
├── KeepWSLAlive.ps1           # Task Scheduler registration script
├── Install-UptimeProfile.ps1  # Installs uptime profile to all PowerShell versions
├── profile.ps1                # Standalone profile snippet with uptime function
├── wsl-config/
│   ├── .wslconfig             # Global host WSL2 settings (place in %USERPROFILE%\.wslconfig)
│   └── wsl.conf               # In-distro settings (place in /etc/wsl.conf)
└── README.md
```
