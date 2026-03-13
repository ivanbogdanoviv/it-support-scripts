# user_audit.ps1 — Audit all local user accounts
Write-Host "========== LOCAL USER AUDIT ==========" -ForegroundColor Cyan
Get-LocalUser | Select-Object Name, Enabled, LastLogon, PasswordLastSet, Description |
    Format-Table -AutoSize
Write-Host "======================================" -ForegroundColor Cyan
