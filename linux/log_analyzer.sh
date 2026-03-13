#!/bin/bash
# log_analyzer.sh — Scan system logs for errors and warnings

LOG="/var/log/syslog"
[ ! -f "$LOG" ] && LOG="/var/log/messages"

echo "========== LOG ANALYZER =========="
echo "Scanning: $LOG"
echo "Date: $(date)"
echo ""

echo "--- Errors (last 50) ---"
grep -i "error" "$LOG" | tail -50

echo ""
echo "--- Warnings (last 20) ---"
grep -i "warning" "$LOG" | tail -20

echo ""
echo "--- Failed login attempts ---"
grep -i "failed" /var/log/auth.log 2>/dev/null | tail -20

echo "=================================="
