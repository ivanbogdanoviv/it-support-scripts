# IT Support Scripts

A collection of sysadmin and IT support scripts for Windows and Linux environments — the kind of tasks you run on the job every day.

![PowerShell](https://img.shields.io/badge/PowerShell-5391FE?style=flat&logo=powershell&logoColor=white)
![Bash](https://img.shields.io/badge/Bash-4EAA25?style=flat&logo=gnubash&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=flat&logo=python&logoColor=white)

## Windows Scripts (PowerShell)
| Script | What It Does |
|--------|-------------|
| `windows/system_info.ps1` | Full system report: CPU, RAM, disk, OS, uptime |
| `windows/disk_cleanup.ps1` | Cleans temp files, empties recycle bin, reports space saved |
| `windows/user_audit.ps1` | Lists all local users, last login, account status |
| `windows/check_updates.ps1` | Checks for pending Windows Updates |
| `windows/network_info.ps1` | IP config, DNS, default gateway, open ports |

## Linux Scripts (Bash)
| Script | What It Does |
|--------|-------------|
| `linux/system_health.sh` | CPU, RAM, disk usage snapshot |
| `linux/user_cleanup.sh` | Lists users with no recent login |
| `linux/log_analyzer.sh` | Scans /var/log for errors and warnings |
| `linux/backup_configs.sh` | Backs up /etc configs to a timestamped archive |
| `linux/port_scanner.sh` | Quick open port check using netstat |

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
