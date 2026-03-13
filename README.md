# IT Support Scripts

A collection of sysadmin and IT support scripts for Windows and Linux environments — the kind of tasks you run on the job every day.

![PowerShell](https://img.shields.io/badge/PowerShell-5.1%2B-5391FE?style=flat&logo=powershell&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4%2B-4EAA25?style=flat&logo=gnubash&logoColor=white)
![Windows](https://img.shields.io/badge/Windows-10%2F11%2FServer-0078D4?style=flat&logo=windows)
![Linux](https://img.shields.io/badge/Linux-Ubuntu%2FDebian%2FRHEL-FCC624?style=flat&logo=linux&logoColor=black)

---

## Prerequisites

| Platform | Requirement |
|---|---|
| Windows | PowerShell 5.1+ (included in Windows 10/11/Server 2016+) |
| Windows | Run as **Administrator** for system changes, cleanup, and update scripts |
| Windows | `PSWindowsUpdate` module — `check_updates.ps1` will prompt to install if missing |
| Linux | Bash 4.0+ |
| Linux | Run as **root** (or `sudo`) for `user_cleanup.sh --remove` and log writes |
| Linux | `ss` (iproute2), `nc` (netcat-openbsd), `lastlog`, `systemctl` — standard on most distros |

---

## Windows Scripts (PowerShell)

| Script | What It Does |
|---|---|
| `windows/system_info.ps1` | Full system report: CPU, RAM, disk, uptime, network adapters, top processes, Event Log errors. `-Html` exports HTML report. |
| `windows/disk_cleanup.ps1` | Cleans `C:\Windows\Temp` and user `%TEMP%`, empties Recycle Bin, runs `cleanmgr` silently, reports MB freed. |
| `windows/user_audit.ps1` | Lists all local users, last login, and account status. |
| `windows/check_updates.ps1` | Lists pending Windows Updates (KB, title, size, severity). `-Install` installs all. Falls back to COM if PSWindowsUpdate unavailable. |
| `windows/network_info.ps1` | IP config, DNS, default gateway, open ports. |

## Linux Scripts (Bash)

| Script | What It Does |
|---|---|
| `linux/system_health.sh` | CPU/RAM/disk snapshot with color thresholds, top 5 processes by CPU, failed systemd services, last 5 log entries. |
| `linux/user_cleanup.sh` | Lists non-system users (UID ≥ 1000) with last login. Flags inactive 60+ days in red. `--remove` prompts to delete flagged users. |
| `linux/log_analyzer.sh` | Scans `/var/log` for errors and warnings. |
| `linux/backup_configs.sh` | Backs up `/etc` configs to a timestamped archive. |
| `linux/port_scanner.sh` | Shows listening TCP/UDP ports with `ss`, flags risky ports (Telnet, FTP, SMB, RDP) in red. Accepts an IP arg for remote scan via `nc`. |

---

## Quick Reference

```powershell
# Windows — run in PowerShell as Administrator

# Full system report
.\windows\system_info.ps1

# Full system report exported to HTML
.\windows\system_info.ps1 -Html

# Clean temp files and report space freed
.\windows\disk_cleanup.ps1

# Check for pending Windows Updates
.\windows\check_updates.ps1

# Check and install all pending updates
.\windows\check_updates.ps1 -Install

# List all local users and last login
.\windows\user_audit.ps1

# Show IP config, DNS, gateway, open ports
.\windows\network_info.ps1
```

```bash
# Linux — make executable first
chmod +x linux/*.sh

# System health snapshot (color-coded)
./linux/system_health.sh

# List non-system users and last login (flag inactive)
./linux/user_cleanup.sh

# List inactive users and prompt to delete them
sudo ./linux/user_cleanup.sh --remove

# Scan and display all listening local ports
./linux/port_scanner.sh

# Check open ports on a remote host
./linux/port_scanner.sh 192.168.1.50

# Analyze /var/log for errors and warnings
./linux/log_analyzer.sh

# Backup /etc configs to timestamped archive
./linux/backup_configs.sh
```

---

## Usage

```powershell
# Windows — run in PowerShell as Administrator
.\windows\system_info.ps1
.\windows\user_audit.ps1
```

```bash
# Linux — run in terminal
chmod +x linux/*.sh
./linux/system_health.sh
./linux/log_analyzer.sh
```

---

## Portfolio

[www.ivanbiv.com](https://www.ivanbiv.com)
