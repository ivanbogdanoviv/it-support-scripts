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

### Example Output

**`system_info.ps1`**
```
========== SYSTEM INFO REPORT ==========
Date     : 2026-03-13 09:14:22
Hostname : DESKTOP-GBC01
User     : ivan.ivanov

OS
  Windows 11 Pro 64-bit
  Build 22631 | Version 10.0.22631
  Uptime: 2d 4h 37m

CPU
  Intel(R) Core(TM) i5-12400 @ 2.50GHz
  Cores: 6 physical / 12 logical
  Load : 14%

MEMORY
  Total : 16.0 GB
  Used  : 6.42 GB
  Free  : 9.58 GB

DISK
  C: 87.3 GB used / 238.0 GB total (36.7%)

NETWORK ADAPTERS (Up)
  Ethernet  — IP: 192.168.1.105 | MAC: A4-BB-6D-12-3C-88 | 1000 Mbps
  Wi-Fi     — IP: 192.168.1.110 | MAC: 3C-22-FB-88-01-D4 | 433 Mbps

TOP 5 PROCESSES — CPU
Name                 Id     CPU(s)   RAM(MB)
chrome               4812   18.4     412.3
explorer             2144   3.1      98.7
svchost              988    1.8      44.2

LAST 5 SYSTEM EVENT LOG ERRORS
  [2026-03-13 08:55] Disk (ID 7) Disk error on \Device\Harddisk0
  [2026-03-13 06:12] DCOM (ID 10016) Permission denied for CLSID ...
========================================
```

**`disk_cleanup.ps1`**
```
[09:21:04] Disk cleanup started.
[09:21:04] C: free space before: 24318.5 MB
[09:21:05] C:\Windows\Temp — removed 312 item(s) (187.4 MB). Failed: 3.
[09:21:06] User %TEMP% (C:\Users\ivan\AppData\Local\Temp) — removed 84 item(s) (42.1 MB). Failed: 0.
[09:21:06] Emptying Recycle Bin...
[09:21:07] Recycle Bin emptied.
[09:21:07] Running cleanmgr /sagerun:1 silently...
[09:21:38] cleanmgr completed.

SUMMARY
----------------------------------------
[09:21:38] C: free before : 24318.5 MB
[09:21:38] C: free after  : 24736.2 MB
[09:21:38] Net space freed: 417.7 MB
[09:21:38] Log saved to   : C:\Logs\disk_cleanup_20260313_092104.log

Cleanup complete. Log: C:\Logs\disk_cleanup_20260313_092104.log
```

**`user_audit.ps1`**
```
Name                     Username        Dept         Last Login           Enabled  Status
-----------------------------------------------------------------------------------------
Administrator            Administrator                2026-03-10           True     [OK]
ivan.ivanov              ivan.ivanov     IT           2026-03-13           True     [OK]
jane.doe                 jane.doe        HR           2026-01-04           True     [WARN] inactive
test.account             test.account                Never                False    [DISABLED]

Total: 4 accounts | Enabled: 3 | Disabled: 1 | Never logged in: 1
```

**`check_updates.ps1`**
```
WINDOWS UPDATE CHECK — 2026-03-13 09:30:11
======================================================================
Update History:
  Last check   : 3/12/2026 11:45:00 PM
  Last install : 3/10/2026 02:30:00 AM

Pending updates: 3

KB            Title                                                    Size (MB)  Severity
KB5034441     2026-03 Cumulative Update for Windows 11 (22H2)          312.4     Critical
KB5034843     Security Update for .NET Framework 4.8                    48.2     Important
KB890830      Windows Malicious Software Removal Tool - v5.121          2.1      —

Run with -Install to install all pending updates.
```

**`network_info.ps1`**
```
NETWORK INFO — DESKTOP-GBC01 — 2026-03-13 09:35:44
============================================================
ADAPTERS
  [OK]  Ethernet        192.168.1.105/24   GW: 192.168.1.1   MAC: A4-BB-6D-12-3C-88
  [OK]  Wi-Fi           192.168.1.110/24   GW: 192.168.1.1   MAC: 3C-22-FB-88-01-D4

DNS SERVERS
  192.168.1.1  (primary)
  8.8.8.8      (secondary)

OPEN LISTENING PORTS
  TCP   0.0.0.0:135    svchost
  TCP   0.0.0.0:445    System
  TCP   0.0.0.0:3389   TermService   [WARN] RDP exposed
  UDP   0.0.0.0:5353   chrome
============================================================
```

---

## Linux Scripts (Bash)

| Script | What It Does |
|---|---|
| `linux/system_health.sh` | CPU/RAM/disk snapshot with color thresholds, top 5 processes by CPU, failed systemd services, last 5 log entries. |
| `linux/user_cleanup.sh` | Lists non-system users (UID ≥ 1000) with last login. Flags inactive 60+ days in red. `--remove` prompts to delete flagged users. |
| `linux/log_analyzer.sh` | Scans `/var/log` for errors and warnings. |
| `linux/backup_configs.sh` | Backs up `/etc` configs to a timestamped archive. |
| `linux/port_scanner.sh` | Shows listening TCP/UDP ports with `ss`, flags risky ports (Telnet, FTP, SMB, RDP) in red. Accepts an IP arg for remote scan via `nc`. |

### Example Output

**`system_health.sh`**
```
========== SYSTEM HEALTH ==========
Date     : 2026-03-13 09:14:02
Hostname : ubuntu-srv-01

CPU
  Usage   : 23.4%                  [OK]
  Cores   : 4 logical
  Load avg: 0.91 1.04 0.88 (1m 5m 15m)

MEMORY
  Total   : 7986 MB
  Used    : 5241 MB (65.6%)        [WARN]
  Free    : 2745 MB

DISK
  /dev/sda1   50G   38G   12G   76%  /     [WARN]
  /dev/sdb1  200G   44G  156G   22%  /data [OK]

TOP 5 PROCESSES — CPU
PID      Command                   CPU%     MEM(MB)
1842     /usr/bin/python3          44.2     312.1
998      /usr/sbin/apache2          8.7      88.4
1204     postgres                   3.1      224.8

FAILED SYSTEMD SERVICES
  No failed services.              [OK]

LAST 5 LOG ENTRIES
  Mar 13 09:13:44 ubuntu-srv-01 kernel: eth0: renamed from veth3a2b
  Mar 13 09:12:11 ubuntu-srv-01 sshd[2201]: Accepted publickey for ivan
===================================
```

**`user_cleanup.sh`**
```
USER CLEANUP — 2026-03-13 09:20:15
========================================================
Username             Last Login                UID        Status
-----------------------------------------------------------------------
ivan                 2026-03-13 08:44:01       1000       [OK]
deploy               2026-03-13 07:12:33       1001       [OK]
backup_agent         2026-01-02 22:00:04       1002       [WARN] inactive >60d
oldadmin             Never                     1003       [WARN] never logged in

Flagged users (inactive 60+ days or never logged in): 2
```

**`log_analyzer.sh`**
```
LOG ANALYZER — 2026-03-13 09:25:00
Scanning: /var/log/syslog  /var/log/auth.log  /var/log/kern.log
============================================================
[INFO]  /var/log/syslog       — 1842 lines scanned
[WARN]  /var/log/syslog       — 14 WARNING entries found
[FAIL]  /var/log/syslog       — 3 ERROR entries found
[INFO]  /var/log/auth.log     — 442 lines scanned
[WARN]  /var/log/auth.log     — 7 failed SSH login attempts (root)
[OK]    /var/log/kern.log     — no errors found

Recent errors:
  2026-03-13 08:55:12  syslog   kernel: EXT4-fs error on sdb1
  2026-03-13 07:44:01  auth.log sshd: Failed password for root from 45.33.32.156
  2026-03-12 23:10:44  syslog   systemd: apt-daily.service failed
============================================================
Summary: 3 errors, 21 warnings across 3 log files
```

**`backup_configs.sh`**
```
[2026-03-13 09:30:01] Starting /etc backup...
[2026-03-13 09:30:01] Source      : /etc
[2026-03-13 09:30:01] Destination : /var/backups/etc_backup_20260313_093001.tar.gz
[2026-03-13 09:30:03] Backup complete. Size: 2.4 MB
[2026-03-13 09:30:03] [OK] Archive verified: etc_backup_20260313_093001.tar.gz
[2026-03-13 09:30:03] Pruning backups older than 30 days...
[2026-03-13 09:30:03] Removed: etc_backup_20260101_020001.tar.gz
[2026-03-13 09:30:03] Done. 7 backup(s) retained.
```

**`port_scanner.sh`**
```
PORT SCANNER — 2026-03-13 09:40:11
========================================================
Showing all local listening TCP/UDP ports (ss -tulnp)

Proto    Port       Local Address                  Service/PID                    Risk
----------------------------------------------------------------------------------------------------
TCP      22         0.0.0.0:22                     ssh/sshd                       [OK]
TCP      80         0.0.0.0:80                     http/apache2                   [OK]
TCP      443        0.0.0.0:443                    https/apache2                  [OK]
TCP      3306       127.0.0.1:3306                 mysql/mysqld                   [OK]
TCP      445        0.0.0.0:445                    microsoft-ds/smbd              [WARN] SMB — frequent ransomware target
TCP      23         0.0.0.0:23                     telnet/telnetd                 [FAIL] Telnet — plaintext, use SSH instead
UDP      53         0.0.0.0:53                     domain/named                   [OK]

Risky ports flagged. Review and disable services you don't need.
```

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
