#!/bin/bash
# user_cleanup.sh — List non-system users, flag inactive ones, optionally remove them
#
# Usage:
#   ./user_cleanup.sh            # list all non-system users with last login
#   ./user_cleanup.sh --remove   # prompt to delete users inactive 60+ days
#
# Logs actions to /var/log/user_cleanup.log (requires root for removal)

set -euo pipefail

LOG_FILE="/var/log/user_cleanup.log"
INACTIVE_DAYS=60
REMOVE_MODE=false

# Parse args
for arg in "$@"; do
    case $arg in
        --remove) REMOVE_MODE=true ;;
        *) echo "Unknown argument: $arg"; echo "Usage: $0 [--remove]"; exit 1 ;;
    esac
done

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE" >/dev/null
}

echo ""
echo -e "${CYAN}USER CLEANUP — $(date '+%Y-%m-%d %H:%M:%S')${NC}"
echo "========================================================"
log "Script started. REMOVE_MODE=$REMOVE_MODE"

# Get non-system users (UID >= 1000, exclude nobody)
NON_SYSTEM_USERS=$(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

if [ -z "$NON_SYSTEM_USERS" ]; then
    echo "No non-system users found."
    log "No non-system users found."
    exit 0
fi

CUTOFF_DATE=$(date -d "-${INACTIVE_DAYS} days" '+%Y-%m-%d' 2>/dev/null || \
              date -v "-${INACTIVE_DAYS}d" '+%Y-%m-%d' 2>/dev/null)

printf "\n%-20s %-25s %-10s %s\n" "Username" "Last Login" "UID" "Status"
echo "-----------------------------------------------------------------------"

FLAGGED_USERS=()

while IFS= read -r username; do
    uid=$(id -u "$username" 2>/dev/null || echo "?")

    # Get last login via lastlog
    last_login=$(lastlog -u "$username" 2>/dev/null | tail -1 | awk '{
        if ($2 == "**Never") print "Never";
        else {
            # Reconstruct date from lastlog output fields
            printf "%s %s %s %s", $4, $5, $6, $9
        }
    }')

    # Normalize: try to parse as a date for comparison
    if [ "$last_login" = "Never" ] || [ -z "$last_login" ]; then
        status="${RED}INACTIVE (never logged in)${NC}"
        FLAGGED_USERS+=("$username")
        printf "${RED}%-20s %-25s %-10s %s${NC}\n" "$username" "Never" "$uid" "INACTIVE"
    else
        # Try to convert last login to epoch for comparison
        last_epoch=$(date -d "$last_login" '+%s' 2>/dev/null || echo 0)
        cutoff_epoch=$(date -d "$CUTOFF_DATE" '+%s' 2>/dev/null || echo 0)

        if [ "$last_epoch" -lt "$cutoff_epoch" ] 2>/dev/null; then
            printf "${YELLOW}%-20s %-25s %-10s %s${NC}\n" "$username" "$last_login" "$uid" "INACTIVE (>${INACTIVE_DAYS}d)"
            FLAGGED_USERS+=("$username")
        else
            printf "${GREEN}%-20s %-25s %-10s %s${NC}\n" "$username" "$last_login" "$uid" "OK"
        fi
    fi
done <<< "$NON_SYSTEM_USERS"

echo ""
echo -e "${CYAN}Flagged users (inactive ${INACTIVE_DAYS}+ days or never logged in): ${#FLAGGED_USERS[@]}${NC}"
log "Found ${#FLAGGED_USERS[@]} inactive/never-logged-in users."

# Removal flow
if [ "${REMOVE_MODE}" = true ]; then
    if [ ${#FLAGGED_USERS[@]} -eq 0 ]; then
        echo "No users to remove."
        exit 0
    fi

    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Root privileges required for --remove. Run with sudo.${NC}"
        exit 1
    fi

    echo ""
    echo -e "${YELLOW}The following users will be considered for deletion:${NC}"
    for u in "${FLAGGED_USERS[@]}"; do echo "  - $u"; done
    echo ""

    for username in "${FLAGGED_USERS[@]}"; do
        read -rp "Delete user '$username' and their home directory? (y/N): " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            if userdel -r "$username" 2>/dev/null; then
                echo -e "${GREEN}Deleted: $username${NC}"
                log "DELETED user: $username"
            else
                echo -e "${RED}Failed to delete: $username${NC}"
                log "FAILED to delete user: $username"
            fi
        else
            echo "  Skipped: $username"
            log "SKIPPED user: $username"
        fi
    done
fi

echo ""
log "Script finished."
echo -e "${CYAN}Done. Log: $LOG_FILE${NC}"
echo ""
