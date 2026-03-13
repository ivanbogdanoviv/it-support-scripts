#!/bin/bash
# port_scanner.sh — Show listening ports locally or check open ports on a remote host
#
# Usage:
#   ./port_scanner.sh                    # show all local listening ports
#   ./port_scanner.sh 192.168.1.1        # scan common ports on a remote host via nc

set -uo pipefail

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Ports to flag as risky
declare -A RISKY_PORTS
RISKY_PORTS[21]="FTP — plaintext, use SFTP instead"
RISKY_PORTS[23]="Telnet — plaintext, use SSH instead"
RISKY_PORTS[69]="TFTP — unauthenticated file transfer"
RISKY_PORTS[139]="NetBIOS — SMB legacy, limit exposure"
RISKY_PORTS[445]="SMB — frequent ransomware target"
RISKY_PORTS[3389]="RDP — brute-force target, restrict access"
RISKY_PORTS[5900]="VNC — often unauthenticated"

# Common ports for remote scan
REMOTE_PORTS=(21 22 23 25 53 80 110 139 143 443 445 3306 3389 5900 8080 8443)

REMOTE_HOST="${1:-}"

echo ""
echo -e "${CYAN}PORT SCANNER — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo "========================================================"

if [ -n "$REMOTE_HOST" ]; then
    # ── Remote scan via nc ──────────────────────────────────────
    echo -e "Remote host : ${BOLD}$REMOTE_HOST${NC}"
    echo -e "Ports       : ${REMOTE_PORTS[*]}"
    echo ""

    # Check nc is available
    if ! command -v nc &>/dev/null; then
        echo -e "${RED}nc (netcat) not found. Install with: apt install netcat-openbsd${NC}"
        exit 1
    fi

    printf "${BOLD}%-8s %-20s %s${NC}\n" "Port" "Service" "Status"
    echo "------------------------------------------------"

    for port in "${REMOTE_PORTS[@]}"; do
        # nc with 1-second timeout
        if nc -z -w1 "$REMOTE_HOST" "$port" 2>/dev/null; then
            svc=$(getent services "$port/tcp" 2>/dev/null | awk '{print $1}' || echo "—")
            if [[ -v "RISKY_PORTS[$port]" ]]; then
                printf "${RED}%-8s %-20s OPEN  ⚠  %s${NC}\n" "$port" "$svc" "${RISKY_PORTS[$port]}"
            else
                printf "${GREEN}%-8s %-20s OPEN${NC}\n" "$port" "$svc"
            fi
        else
            printf "%-8s %-20s CLOSED/FILTERED\n" "$port" ""
        fi
    done

else
    # ── Local listening ports via ss ────────────────────────────
    if ! command -v ss &>/dev/null; then
        echo -e "${RED}ss not found. Install iproute2: apt install iproute2${NC}"
        exit 1
    fi

    echo -e "Showing all local listening TCP/UDP ports (ss -tulnp)"
    echo ""

    # Header
    printf "${BOLD}%-6s %-8s %-30s %-30s %s${NC}\n" "Proto" "Port" "Local Address" "Service/PID" "Risk"
    echo "$(printf '%0.s-' {1..100})"

    # Parse ss output (skip header line)
    ss -tulnp 2>/dev/null | tail -n +2 | while read -r proto recvq sendq local_addr peer_addr proc; do
        # Extract port from local address (handle IPv4, IPv6, *)
        port=$(echo "$local_addr" | rev | cut -d: -f1 | rev)

        # Skip non-numeric ports
        [[ "$port" =~ ^[0-9]+$ ]] || continue

        # Service name
        svc=$(getent services "$port/tcp" 2>/dev/null | awk '{print $1}')
        [ -z "$svc" ] && svc=$(getent services "$port/udp" 2>/dev/null | awk '{print $1}')
        [ -z "$svc" ] && svc="—"

        # Process info
        pid_info=$(echo "$proc" | grep -oP 'pid=\K[0-9]+' || echo "")
        proc_name=""
        if [ -n "$pid_info" ] && [ -f "/proc/$pid_info/comm" ]; then
            proc_name=$(cat "/proc/$pid_info/comm" 2>/dev/null)
        fi
        label="${svc}${proc_name:+/$proc_name}"

        proto_short=$(echo "$proto" | tr '[:lower:]' '[:upper:]' | cut -c1-3)

        if [[ -v "RISKY_PORTS[$port]" ]]; then
            printf "${RED}%-6s %-8s %-30s %-30s %s${NC}\n" \
                "$proto_short" "$port" "$local_addr" "$label" "⚠  ${RISKY_PORTS[$port]}"
        else
            printf "${GREEN}%-6s %-8s %-30s %-30s${NC}\n" \
                "$proto_short" "$port" "$local_addr" "$label"
        fi
    done

    echo ""
    echo -e "${YELLOW}Risky ports flagged in red. Review and disable services you don't need.${NC}"
fi

echo ""
echo -e "${CYAN}Done.${NC}"
echo ""
