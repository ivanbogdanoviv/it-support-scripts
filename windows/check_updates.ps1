<#
.SYNOPSIS
    Checks for pending Windows Updates and optionally installs them.

.DESCRIPTION
    Uses the PSWindowsUpdate module if available (prompts to install if
    not). Falls back to the built-in Microsoft.Update.Session COM object
    if PSWindowsUpdate cannot be installed. Lists all pending updates with
    KB number, title, size, and severity. Shows last update check date and
    last install date.

.PARAMETER Install
    If specified, installs all available updates (requires reboot afterward).

.EXAMPLE
    .\check_updates.ps1
    .\check_updates.ps1 -Install
#>

param(
    [switch]$Install
)

# Require elevation
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Error "Run this script as Administrator."
    exit 1
}

Write-Host ""
Write-Host "WINDOWS UPDATE CHECK — $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host ("=" * 70)

# Show last update timestamps from registry
function Show-LastUpdateDates {
    Write-Host ""
    Write-Host "Update History:" -ForegroundColor Yellow
    $au = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\Results"
    try {
        $lastCheck   = (Get-ItemProperty "$au\Detect"  -ErrorAction Stop).LastSuccessTime
        $lastInstall = (Get-ItemProperty "$au\Install" -ErrorAction Stop).LastSuccessTime
        Write-Host "  Last check   : $lastCheck"
        Write-Host "  Last install : $lastInstall"
    } catch {
        Write-Host "  (Could not read update history from registry)" -ForegroundColor DarkGray
    }
    Write-Host ""
}

Show-LastUpdateDates

# Try PSWindowsUpdate first
$usePSWU = $false
if (Get-Module -ListAvailable -Name PSWindowsUpdate) {
    Import-Module PSWindowsUpdate -ErrorAction SilentlyContinue
    $usePSWU = $true
} else {
    Write-Host "PSWindowsUpdate module not found." -ForegroundColor Yellow
    $answer = Read-Host "Install PSWindowsUpdate from PSGallery? (y/n)"
    if ($answer -eq 'y') {
        try {
            Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser -ErrorAction Stop
            Import-Module PSWindowsUpdate -ErrorAction Stop
            $usePSWU = $true
            Write-Host "PSWindowsUpdate installed." -ForegroundColor Green
        } catch {
            Write-Host "Could not install PSWindowsUpdate: $_" -ForegroundColor Yellow
            Write-Host "Falling back to COM object..." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Falling back to COM object..." -ForegroundColor Yellow
    }
}

if ($usePSWU) {
    # --- PSWindowsUpdate path ---
    Write-Host "Scanning for updates via PSWindowsUpdate..." -ForegroundColor Cyan

    $updates = Get-WindowsUpdate -MicrosoftUpdate -ErrorAction Stop

    if (-not $updates) {
        Write-Host "No pending updates found." -ForegroundColor Green
    } else {
        Write-Host "Pending updates: $($updates.Count)`n" -ForegroundColor Yellow
        $fmt = "{0,-12} {1,-60} {2,10} {3}"
        Write-Host ($fmt -f "KB", "Title", "Size (MB)", "Severity") -ForegroundColor Yellow
        Write-Host ("-" * 100)
        foreach ($u in $updates) {
            $kb       = if ($u.KBArticleIDs) { "KB$($u.KBArticleIDs -join ',')" } else { "N/A" }
            $title    = if ($u.Title.Length -gt 58) { $u.Title.Substring(0,55) + "..." } else { $u.Title }
            $sizeMB   = if ($u.MaxDownloadSize) { [math]::Round($u.MaxDownloadSize / 1MB, 1) } else { "?" }
            $severity = if ($u.MsrcSeverity) { $u.MsrcSeverity } else { "—" }
            $color    = switch ($severity) { "Critical" {"Red"} "Important" {"Yellow"} default {"White"} }
            Write-Host ($fmt -f $kb, $title, $sizeMB, $severity) -ForegroundColor $color
        }

        if ($Install) {
            Write-Host ""
            Write-Host "Installing updates..." -ForegroundColor Cyan
            Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -Verbose
        } else {
            Write-Host ""
            Write-Host "Run with -Install to install all pending updates." -ForegroundColor DarkGray
        }
    }

} else {
    # --- COM object fallback ---
    Write-Host "Scanning for updates via Microsoft.Update.Session COM..." -ForegroundColor Cyan
    try {
        $session    = New-Object -ComObject Microsoft.Update.Session
        $searcher   = $session.CreateUpdateSearcher()
        $result     = $searcher.Search("IsInstalled=0 and Type='Software'")
        $updates    = $result.Updates

        if ($updates.Count -eq 0) {
            Write-Host "No pending updates found." -ForegroundColor Green
        } else {
            Write-Host "Pending updates: $($updates.Count)`n" -ForegroundColor Yellow
            $fmt = "{0,-12} {1,-65} {2,10}"
            Write-Host ($fmt -f "KB", "Title", "Size (MB)") -ForegroundColor Yellow
            Write-Host ("-" * 90)
            foreach ($u in $updates) {
                $kb     = if ($u.KBArticleIDs.Count -gt 0) { "KB$($u.KBArticleIDs.Item(0))" } else { "N/A" }
                $title  = if ($u.Title.Length -gt 63) { $u.Title.Substring(0,60) + "..." } else { $u.Title }
                $sizeMB = if ($u.MaxDownloadSize -gt 0) { [math]::Round($u.MaxDownloadSize / 1MB, 1) } else { "?" }
                Write-Host ($fmt -f $kb, $title, $sizeMB)
            }

            if ($Install) {
                Write-Host ""
                Write-Host "Installing via COM object..." -ForegroundColor Cyan
                $downloader         = $session.CreateUpdateDownloader()
                $downloader.Updates = $updates
                Write-Host "Downloading..."
                $downloader.Download() | Out-Null

                $installer         = $session.CreateUpdateInstaller()
                $installer.Updates = $updates
                Write-Host "Installing..."
                $installResult = $installer.Install()
                Write-Host "Result code: $($installResult.ResultCode)" -ForegroundColor Green
                if ($installResult.RebootRequired) {
                    Write-Host "Reboot required to complete installation." -ForegroundColor Yellow
                }
            } else {
                Write-Host ""
                Write-Host "Run with -Install to install all pending updates." -ForegroundColor DarkGray
            }
        }
    } catch {
        Write-Error "COM update search failed: $_"
    }
}

Write-Host ""
