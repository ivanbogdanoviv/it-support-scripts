<#
.SYNOPSIS
    Cleans temporary files, empties Recycle Bin, and reports space freed.

.DESCRIPTION
    Removes files from C:\Windows\Temp and the current user's %TEMP%
    folder, empties the Recycle Bin, and optionally runs Windows Disk
    Cleanup (cleanmgr) silently. Reports disk space before and after
    in MB and logs results to a timestamped file in C:\Logs\.

.PARAMETER SkipCleanmgr
    Skip running the Windows Disk Cleanup utility (cleanmgr).

.EXAMPLE
    .\disk_cleanup.ps1
    .\disk_cleanup.ps1 -SkipCleanmgr
#>

param(
    [switch]$SkipCleanmgr
)

# Require elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "Run this script as Administrator."
    exit 1
}

# Ensure log directory
$logDir = "C:\Logs"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$logFile   = "$logDir\disk_cleanup_$timestamp.log"

function Write-Log {
    param([string]$Msg, [string]$Color = "White")
    $entry = "[$(Get-Date -Format 'HH:mm:ss')] $Msg"
    $entry | Out-File -FilePath $logFile -Append -Encoding UTF8
    Write-Host $entry -ForegroundColor $Color
}

function Get-DriveFreeGB {
    $d = Get-PSDrive C -ErrorAction SilentlyContinue
    if ($d) { return [math]::Round($d.Free / 1MB, 2) }
    return 0
}

function Remove-TempFiles {
    param([string]$Path, [string]$Label)
    if (-not (Test-Path $Path)) {
        Write-Log "$Label — path not found, skipping." "Yellow"
        return 0
    }
    $items   = Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue
    $sizeMB  = [math]::Round(($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB, 2)
    $deleted = 0
    $failed  = 0
    foreach ($item in $items) {
        try {
            Remove-Item $item.FullName -Recurse -Force -ErrorAction Stop
            $deleted++
        } catch { $failed++ }
    }
    Write-Log "$Label — removed $deleted item(s) ($sizeMB MB). Failed: $failed." "Cyan"
    return $sizeMB
}

Write-Host ""
Write-Host "DISK CLEANUP — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ("=" * 60)
Write-Log "Disk cleanup started."

$freeBefore = Get-DriveFreeGB
Write-Log "C: free space before: $freeBefore MB"

# 1 — Windows Temp
$freed1 = Remove-TempFiles -Path "C:\Windows\Temp" -Label "C:\Windows\Temp"

# 2 — User Temp
$userTemp = $env:TEMP
$freed2   = Remove-TempFiles -Path $userTemp -Label "User %TEMP% ($userTemp)"

# 3 — Recycle Bin
Write-Log "Emptying Recycle Bin..."
try {
    Clear-RecycleBin -Force -ErrorAction Stop
    Write-Log "Recycle Bin emptied." "Cyan"
} catch {
    Write-Log "Recycle Bin: $_" "Yellow"
}

# 4 — Windows Disk Cleanup (cleanmgr)
if (-not $SkipCleanmgr) {
    $cleanmgr = "$env:SystemRoot\System32\cleanmgr.exe"
    if (Test-Path $cleanmgr) {
        Write-Log "Running cleanmgr /sagerun:1 silently..."
        # Pre-configure sageset:1 to select all cleanup categories
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"
        Get-ChildItem $regPath -ErrorAction SilentlyContinue | ForEach-Object {
            Set-ItemProperty -Path $_.PSPath -Name StateFlags0001 -Value 2 -ErrorAction SilentlyContinue
        }
        $proc = Start-Process -FilePath $cleanmgr -ArgumentList "/sagerun:1" -PassThru -WindowStyle Hidden
        $proc.WaitForExit(120000) | Out-Null   # wait up to 2 minutes
        Write-Log "cleanmgr completed." "Cyan"
    } else {
        Write-Log "cleanmgr.exe not found — skipping." "Yellow"
    }
} else {
    Write-Log "SkipCleanmgr specified — skipping cleanmgr."
}

# Report
$freeAfter = Get-DriveFreeGB
$netFreed  = [math]::Round($freeAfter - $freeBefore, 2)

Write-Host ""
Write-Host "SUMMARY" -ForegroundColor Yellow
Write-Host ("-" * 40)
Write-Log "C: free before : $freeBefore MB"
Write-Log "C: free after  : $freeAfter MB"
Write-Log "Net space freed: $netFreed MB"
Write-Log "Log saved to   : $logFile"
Write-Host ""
Write-Host "Cleanup complete. Log: $logFile" -ForegroundColor Green
Write-Host ""
