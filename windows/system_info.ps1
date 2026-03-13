# system_info.ps1 — Full system information report
Write-Host "========== SYSTEM INFO REPORT ==========" -ForegroundColor Cyan
Write-Host "Date: $(Get-Date)"
Write-Host ""

# OS Info
$os = Get-CimInstance Win32_OperatingSystem
Write-Host "OS: $($os.Caption) $($os.OSArchitecture)"
Write-Host "Version: $($os.Version)"
Write-Host "Uptime: $((Get-Date) - $os.LastBootUpTime)"

# CPU
$cpu = Get-CimInstance Win32_Processor
Write-Host "`nCPU: $($cpu.Name)"
Write-Host "Cores: $($cpu.NumberOfCores) / Logical: $($cpu.NumberOfLogicalProcessors)"

# RAM
$ram = Get-CimInstance Win32_ComputerSystem
Write-Host "`nRAM Total: $([math]::Round($ram.TotalPhysicalMemory/1GB, 2)) GB"
$ramFree = Get-CimInstance Win32_OperatingSystem
Write-Host "RAM Free: $([math]::Round($ramFree.FreePhysicalMemory/1MB, 2)) GB"

# Disk
Write-Host "`nDisk Usage:"
Get-PSDrive -PSProvider FileSystem | Where-Object {$_.Used -gt 0} | ForEach-Object {
    $total = [math]::Round(($_.Used + $_.Free)/1GB, 2)
    $used = [math]::Round($_.Used/1GB, 2)
    $pct = [math]::Round(($_.Used / ($_.Used + $_.Free)) * 100, 1)
    Write-Host "  $($_.Name): $used GB used / $total GB total ($pct%)"
}

Write-Host "`n========================================" -ForegroundColor Cyan
