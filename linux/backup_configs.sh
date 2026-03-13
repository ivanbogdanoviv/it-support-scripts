#!/bin/bash
# backup_configs.sh — Backup /etc configs to timestamped archive

BACKUP_DIR="/tmp/config_backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/etc_backup_$TIMESTAMP.tar.gz"

mkdir -p "$BACKUP_DIR"
tar -czf "$ARCHIVE" /etc 2>/dev/null

echo "Backup created: $ARCHIVE"
echo "Size: $(du -sh "$ARCHIVE" | cut -f1)"
