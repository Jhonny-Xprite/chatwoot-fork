#!/bin/bash
#
# Rollback script for contact deduplication
# Usage: ./bin/rollback_contact_merge.sh [database_name] [merge_log_id]
#
# This script restores a contact that was merged by reversing the soft delete.
# Use this if a merge was performed in error.
#

set -e

DB_NAME="${1:-chatwoot_production}"
MERGE_LOG_ID="${2}"

if [ -z "$MERGE_LOG_ID" ]; then
  echo "Usage: $0 [database_name] [merge_log_id]"
  echo ""
  echo "Example: $0 chatwoot_production 123"
  exit 1
fi

echo "Rolling back merge #$MERGE_LOG_ID in database '$DB_NAME'..."

# Get merge details from contact_merge_logs
MERGE_INFO=$(psql "$DB_NAME" -t -c "SELECT source_contact_id, target_contact_id, merged_at FROM contact_merge_logs WHERE id = $MERGE_LOG_ID LIMIT 1")

if [ -z "$MERGE_INFO" ]; then
  echo "Error: Merge log #$MERGE_LOG_ID not found."
  exit 1
fi

SOURCE_ID=$(echo "$MERGE_INFO" | awk '{print $1}')
TARGET_ID=$(echo "$MERGE_INFO" | awk '{print $2}')
MERGED_AT=$(echo "$MERGE_INFO" | awk '{print $3}')

echo "Merge details:"
echo "  Merge ID: $MERGE_LOG_ID"
echo "  Source Contact ID: $SOURCE_ID"
echo "  Target Contact ID: $TARGET_ID"
echo "  Merged at: $MERGED_AT"
echo ""

# Restore source contact (set is_deleted = false)
echo "Restoring source contact #$SOURCE_ID..."
psql "$DB_NAME" -c "UPDATE contacts SET is_deleted = false, deleted_at = NULL WHERE id = $SOURCE_ID"

# Update merge_log to record the restoration
echo "Updating merge log record..."
psql "$DB_NAME" -c "UPDATE contact_merge_logs SET merge_data = merge_data || jsonb_build_object('restored_at', now()::text) WHERE id = $MERGE_LOG_ID"

# Verify restoration
RESTORED_STATUS=$(psql "$DB_NAME" -t -c "SELECT is_deleted FROM contacts WHERE id = $SOURCE_ID")
if [ "$RESTORED_STATUS" = "f" ]; then
  echo "✓ Rollback successful!"
  echo "  Source contact #$SOURCE_ID has been restored (is_deleted = false)"
  echo ""
  echo "Note: Messages remain assigned to target contact #$TARGET_ID for continuity."
  echo "To move messages back to source contact, use UPDATE conversation statements manually."
else
  echo "Error: Failed to restore source contact."
  exit 1
fi
