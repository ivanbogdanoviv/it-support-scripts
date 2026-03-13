# network_info.ps1 — Network configuration report
Write-Host "========== NETWORK INFO ==========" -ForegroundColor Cyan
Get-NetIPConfiguration | ForEach-Object {
    Write-Host "Interface: $($_.InterfaceAlias)"
    Write-Host "  IP: $($_.IPv4Address.IPAddress)"
    Write-Host "  Gateway: $($_.IPv4DefaultGateway.NextHop)"
    Write-Host "  DNS: $($_.DNSServer.ServerAddresses -join ', ')"
    Write-Host ""
}
Write-Host "Open Listening Ports:"
netstat -an | Select-String "LISTENING"
Write-Host "==================================" -ForegroundColor Cyan
