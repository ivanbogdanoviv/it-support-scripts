#!/bin/bash
# system_health.sh — Quick system health snapshot

echo "========== SYSTEM HEALTH =========="
echo "Date: $(date)"
echo "Hostname: $(hostname)"
echo ""

echo "--- CPU ---"
top -bn1 | grep "Cpu(s)" | awk '{print "Usage: " $2 "%"}'

echo ""
echo "--- Memory ---"
free -h | awk 'NR==2{printf "Used: %s / Total: %s (%.1f%%)\n", $3, $2, $3/$2*100}'

echo ""
echo "--- Disk ---"
df -h | grep -v tmpfs | grep -v udev

echo ""
echo "--- Top 5 Processes by CPU ---"
ps aux --sort=-%cpu | head -6 | awk '{printf "%-20s %s%%\n", $11, $3}'

echo "==================================="
