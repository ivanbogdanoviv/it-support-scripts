#!/bin/bash
# system_health.sh — System health snapshot with color thresholds, process list,
#                    failed services, and recent log entries.
#
# Usage: ./system_health.sh
#
# Color coding:
#   Green  = healthy  (usage < 70%)
#   Yellow = warning  (70% – 89%)
#   Red    = critical (90%+)

set -uo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

color_pct() {
    local val="$1"
    local int_val="${val%.*}"
    if   [ "$int_val" -ge 90 ] 2>/dev/null; then echo -e "${RED}${val}%${NC}"
    elif [ "$int_val" -ge 70 ] 2>/dev/null; then echo -e "${YELLOW}${val}%${NC}"
    else                                          echo -e "${GREEN}${val}%${NC}"
    fi
}

echo ""
echo -e "${CYAN}${BOLD}========== SYSTEM HEALTH ==========${NC}"
echo -e "Date     : $(date '+%Y-%m-%d %H:%M:%S')"
echo -e "Hostname : $(hostname)"
echo ""

# ── CPU ─────────────────────────────────────────────────────
echo -e "${YELLOW}CPU${NC}"
cpu_idle=$(top -bn1 | grep "Cpu(s)" | awk '{print $8}' | tr -d '%id,' 2>/dev/null || echo "0")
cpu_usage=$(awk "BEGIN {printf \"%.1f\", 100 - ${cpu_idle}}" 2>/dev/null || echo "?")
echo -e "  Usage   : $(color_pct "$cpu_usage")"
echo -e "  Cores   : $(nproc) logical"
if [ -f /proc/loadavg ]; then
    load=$(cat /proc/loadavg | awk '{print $1, $2, $3}')
    echo -e "  Load avg: $load (1m 5m 15m)"
fi
echo ""

# ── Memory ──────────────────────────────────────────────────
echo -e "${YELLOW}MEMORY${NC}"
mem_info=$(free -m | awk 'NR==2{printf "%s %s %s", $2, $3, $4}')
mem_total=$(echo "$mem_info" | awk '{print $1}')
mem_used=$(echo  "$mem_info" | awk '{print $2}')
mem_free=$(echo  "$mem_info" | awk '{print $3}')
mem_pct=0
if [ "$mem_total" -gt 0 ] 2>/dev/null; then
    mem_pct=$(awk "BEGIN {printf \"%.1f\", ($mem_used/$mem_total)*100}")
fi
echo -e "  Total   : ${mem_total} MB"
echo -e "  Used    : ${mem_used} MB ($(color_pct "$mem_pct"))"
echo -e "  Free    : ${mem_free} MB"
echo ""

# ── Disk ────────────────────────────────────────────────────
echo -e "${YELLOW}DISK${NC}"
df -h --output=source,size,used,avail,pcent,target 2>/dev/null | \
grep -v tmpfs | grep -v udev | grep -v Filesystem | while IFS= read -r line; do
    pct=$(echo "$line" | awk '{print $5}' | tr -d '%')
    if [ -n "$pct" ] && [[ "$pct" =~ ^[0-9]+$ ]]; then
        colored_pct=$(color_pct "$pct")
        # Replace the percentage in the line with a colored version
        printf "  %-20s %-8s %-8s %-8s %s %s\n" \
            "$(echo "$line" | awk '{print $1}')" \
            "$(echo "$line" | awk '{print $2}')" \
            "$(echo "$line" | awk '{print $3}')" \
            "$(echo "$line" | awk '{print $4}')" \
            "$colored_pct" \
            "$(echo "$line" | awk '{print $6}')"
    fi
done
echo ""

# ── Top 5 Processes by CPU ───────────────────────────────────
echo -e "${YELLOW}TOP 5 PROCESSES — CPU${NC}"
printf "  %-8s %-25s %8s %10s\n" "PID" "Command" "CPU%" "MEM(MB)"
ps aux --sort=-%cpu 2>/dev/null | awk 'NR>1 && NR<=7 {
    mem_mb = $6 / 1024
    printf "  %-8s %-25s %8s %10.1f\n", $2, $11, $3, mem_mb
}'
echo ""

# ── Failed Systemd Services ──────────────────────────────────
echo -e "${YELLOW}FAILED SYSTEMD SERVICES${NC}"
if command -v systemctl &>/dev/null; then
    failed=$(systemctl --failed --no-legend --no-pager 2>/dev/null | grep "failed" || true)
    if [ -z "$failed" ]; then
        echo -e "  ${GREEN}No failed services.${NC}"
    else
        echo -e "${RED}$failed${NC}" | sed 's/^/  /'
    fi
else
    echo "  systemctl not available."
fi
echo ""

# ── Recent Log Entries ───────────────────────────────────────
echo -e "${YELLOW}LAST 5 LOG ENTRIES${NC}"
if command -v journalctl &>/dev/null; then
    journalctl -n 5 --no-pager -o short 2>/dev/null | sed 's/^/  /' || \
        echo "  (journalctl access denied)"
elif [ -f /var/log/syslog ]; then
    tail -5 /var/log/syslog | sed 's/^/  /'
elif [ -f /var/log/messages ]; then
    tail -5 /var/log/messages | sed 's/^/  /'
else
    echo "  No log source available."
fi
echo ""

echo -e "${CYAN}===================================${NC}"
echo ""
