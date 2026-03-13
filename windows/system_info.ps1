<#
.SYNOPSIS
    Full system information report: OS, CPU, RAM, disk, network, top processes, event log.

.DESCRIPTION
    Collects hostname, OS version, uptime, CPU load, RAM usage, disk usage,
    network adapter details (IP, MAC, status), top 5 processes by CPU and RAM,
    and the last 5 Windows Event Log errors. Outputs a formatted console report.
    Use -Html to export an HTML report to the current directory.

.PARAMETER Html
    Exports the report as a self-contained HTML file with a timestamp in the filename.

.EXAMPLE
    .\system_info.ps1
    .\system_info.ps1 -Html
#>

param([switch]$Html)

# Collect all data up front
$os      = Get-CimInstance Win32_OperatingSystem
$cpu     = Get-CimInstance Win32_Processor | Select-Object -First 1
$ram     = Get-CimInstance Win32_ComputerSystem
$uptime  = (Get-Date) - $os.LastBootUpTime
$totalGB = [math]::Round($ram.TotalPhysicalMemory / 1GB, 2)
$freeGB  = [math]::Round($os.FreePhysicalMemory / 1MB, 2)
$usedGB  = [math]::Round($totalGB - $freeGB, 2)

$disks = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 } | ForEach-Object {
    $t = [math]::Round(($_.Used + $_.Free) / 1GB, 2)
    $u = [math]::Round($_.Used / 1GB, 2)
    $p = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 1)
    [PSCustomObject]@{ Drive = $_.Name; TotalGB = $t; UsedGB = $u; PctUsed = "$p%" }
}

$adapters = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object {
    $ip  = (Get-NetIPAddress -InterfaceIndex $_.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).IPAddress
    [PSCustomObject]@{
        Name   = $_.Name
        Status = $_.Status
        MAC    = $_.MacAddress
        IP     = if ($ip) { $ip } else { "N/A" }
        Speed  = "$([math]::Round($_.LinkSpeed / 1MB, 0)) Mbps"
    }
}

$topCpu = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 |
    Select-Object Name, Id, @{N="CPU(s)";E={[math]::Round($_.CPU,1)}}, @{N="RAM(MB)";E={[math]::Round($_.WorkingSet64/1MB,1)}}

$topRam = Get-Process | Sort-Object WorkingSet64 -Descending | Select-Object -First 5 |
    Select-Object Name, Id, @{N="CPU(s)";E={[math]::Round($_.CPU,1)}}, @{N="RAM(MB)";E={[math]::Round($_.WorkingSet64/1MB,1)}}

$events = @()
try {
    $events = Get-EventLog -LogName System -EntryType Error -Newest 5 -ErrorAction Stop |
        Select-Object TimeGenerated, Source, EventID,
            @{N="Message";E={$_.Message.Split("`n")[0].Trim()}}
} catch { }

# ── Console output ───────────────────────────────────────────
Write-Host ""
Write-Host "========== SYSTEM INFO REPORT ==========" -ForegroundColor Cyan
Write-Host "Date     : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Hostname : $($env:COMPUTERNAME)"
Write-Host "User     : $($env:USERNAME)"
Write-Host ""

Write-Host "OS" -ForegroundColor Yellow
Write-Host "  $($os.Caption) $($os.OSArchitecture)"
Write-Host "  Build $($os.BuildNumber) | Version $($os.Version)"
Write-Host "  Uptime: $($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m"
Write-Host ""

Write-Host "CPU" -ForegroundColor Yellow
Write-Host "  $($cpu.Name)"
Write-Host "  Cores: $($cpu.NumberOfCores) physical / $($cpu.NumberOfLogicalProcessors) logical"
Write-Host "  Load : $($cpu.LoadPercentage)%"
Write-Host ""

Write-Host "MEMORY" -ForegroundColor Yellow
Write-Host "  Total : $totalGB GB"
Write-Host "  Used  : $usedGB GB"
Write-Host "  Free  : $freeGB GB"
Write-Host ""

Write-Host "DISK" -ForegroundColor Yellow
$disks | ForEach-Object {
    Write-Host "  $($_.Drive): $($_.UsedGB) GB used / $($_.TotalGB) GB total ($($_.PctUsed))"
}
Write-Host ""

Write-Host "NETWORK ADAPTERS (Up)" -ForegroundColor Yellow
if ($adapters) {
    $adapters | ForEach-Object {
        Write-Host "  $($_.Name) — IP: $($_.IP) | MAC: $($_.MAC) | $($_.Speed)"
    }
} else {
    Write-Host "  No active adapters found."
}
Write-Host ""

Write-Host "TOP 5 PROCESSES — CPU" -ForegroundColor Yellow
$topCpu | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "TOP 5 PROCESSES — RAM" -ForegroundColor Yellow
$topRam | Format-Table -AutoSize | Out-String | Write-Host

Write-Host "LAST 5 SYSTEM EVENT LOG ERRORS" -ForegroundColor Yellow
if ($events) {
    $events | ForEach-Object {
        Write-Host "  [$($_.TimeGenerated.ToString('yyyy-MM-dd HH:mm'))] $($_.Source) (ID $($_.EventID)): $($_.Message)"
    }
} else {
    Write-Host "  (None found or access denied)"
}
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── HTML export ──────────────────────────────────────────────
if ($Html) {
    $timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
    $htmlFile  = "SystemReport_$($env:COMPUTERNAME)_$timestamp.html"

    function ConvertTo-HtmlTable {
        param($Data, [string]$Title)
        $rows = $Data | ForEach-Object {
            $cells = ($_.PSObject.Properties | ForEach-Object { "<td>$($_.Value)</td>" }) -join ""
            "<tr>$cells</tr>"
        }
        $headers = ($Data[0].PSObject.Properties.Name | ForEach-Object { "<th>$_</th>" }) -join ""
        "<h2>$Title</h2><table><thead><tr>$headers</tr></thead><tbody>$($rows -join '')</tbody></table>"
    }

    $adapterRows = ($adapters | ForEach-Object {
        "<tr><td>$($_.Name)</td><td>$($_.Status)</td><td>$($_.IP)</td><td>$($_.MAC)</td><td>$($_.Speed)</td></tr>"
    }) -join ""

    $diskRows = ($disks | ForEach-Object {
        "<tr><td>$($_.Drive)</td><td>$($_.TotalGB)</td><td>$($_.UsedGB)</td><td>$($_.PctUsed)</td></tr>"
    }) -join ""

    $eventRows = ($events | ForEach-Object {
        "<tr><td>$($_.TimeGenerated)</td><td>$($_.Source)</td><td>$($_.EventID)</td><td>$($_.Message)</td></tr>"
    }) -join ""

    $html = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<title>System Report — $($env:COMPUTERNAME)</title>
<style>
  body { font-family: Consolas, monospace; background: #1e1e2e; color: #cdd6f4; padding: 2em; }
  h1   { color: #89b4fa; }
  h2   { color: #a6e3a1; margin-top: 2em; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 1em; }
  th   { background: #313244; color: #cba6f7; padding: 8px 12px; text-align: left; }
  td   { padding: 6px 12px; border-bottom: 1px solid #45475a; }
  tr:hover { background: #313244; }
  .meta { color: #a6adc8; font-size: 0.9em; margin-bottom: 2em; }
</style>
</head>
<body>
<h1>System Report — $($env:COMPUTERNAME)</h1>
<p class="meta">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | User: $($env:USERNAME)</p>

<h2>Operating System</h2>
<table><tbody>
  <tr><td>OS</td><td>$($os.Caption) $($os.OSArchitecture)</td></tr>
  <tr><td>Build</td><td>$($os.BuildNumber) (Version $($os.Version))</td></tr>
  <tr><td>Uptime</td><td>$($uptime.Days)d $($uptime.Hours)h $($uptime.Minutes)m</td></tr>
</tbody></table>

<h2>CPU</h2>
<table><tbody>
  <tr><td>Name</td><td>$($cpu.Name)</td></tr>
  <tr><td>Cores</td><td>$($cpu.NumberOfCores) physical / $($cpu.NumberOfLogicalProcessors) logical</td></tr>
  <tr><td>Load</td><td>$($cpu.LoadPercentage)%</td></tr>
</tbody></table>

<h2>Memory</h2>
<table><tbody>
  <tr><td>Total</td><td>$totalGB GB</td></tr>
  <tr><td>Used</td><td>$usedGB GB</td></tr>
  <tr><td>Free</td><td>$freeGB GB</td></tr>
</tbody></table>

<h2>Disk Usage</h2>
<table><thead><tr><th>Drive</th><th>Total (GB)</th><th>Used (GB)</th><th>Used %</th></tr></thead>
<tbody>$diskRows</tbody></table>

<h2>Network Adapters (Up)</h2>
<table><thead><tr><th>Name</th><th>Status</th><th>IP</th><th>MAC</th><th>Speed</th></tr></thead>
<tbody>$adapterRows</tbody></table>

$(ConvertTo-HtmlTable -Data $topCpu -Title "Top 5 Processes — CPU")
$(ConvertTo-HtmlTable -Data $topRam -Title "Top 5 Processes — RAM")

<h2>Last 5 System Event Log Errors</h2>
<table><thead><tr><th>Time</th><th>Source</th><th>Event ID</th><th>Message</th></tr></thead>
<tbody>$eventRows</tbody></table>

</body></html>
"@

    $html | Out-File -FilePath $htmlFile -Encoding UTF8
    Write-Host "HTML report saved to: $htmlFile" -ForegroundColor Green
    Write-Host ""
}
