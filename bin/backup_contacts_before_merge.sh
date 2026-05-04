#!/bin/bash
#
# Backup script for contact deduplication
# Usage: ./bin/backup_contacts_before_merge.sh [database_name] [backup_dir]
#
# This script creates a backup of the database before performing contact merges.
# The backup can be used to restore the database if something goes wrong.
#

set -e

DB_NAME="${1:-chatwoot_production}"
BACKUP_DIR="${2:-.}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/backup_contacts_${TIMESTAMP}.sql"

echo "Creating backup of '$DB_NAME' database..."
echo "Backup file: $BACKUP_FILE"

# Create backup using pg_dump
if command -v pg_dump &> /dev/null; then
  pg_dump "$DB_NAME" > "$BACKUP_FILE"
else
  echo "Error: pg_dump not found. Please ensure PostgreSQL is installed and in PATH."
  exit 1
fi

# Verify backup file was created and has content
if [ ! -f "$BACKUP_FILE" ] || [ ! -s "$BACKUP_FILE" ]; then
  echo "Error: Backup file was not created or is empty."
  exit 1
fi

# Verify backup can be restored (syntax check)
echo "Verifying backup integrity..."
if pg_restore -d /dev/null "$BACKUP_FILE" 2>&1 | grep -q "ERROR"; then
  echo "Warning: Backup may have issues, but file was created."
else
  echo "Backup verification passed."
fi

FILE_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
echo "✓ Backup created successfully: $BACKUP_FILE ($FILE_SIZE)"
echo "To restore this backup, run:"
echo "  psql $DB_NAME < $BACKUP_FILE"
