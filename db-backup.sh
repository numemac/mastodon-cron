#!/bin/bash

# Runs pgdump on the database and uploads it to Backblaze using s3cmd
# Available ENV vars: $DB_NAME, $DB_USER, $DB_PASS, $DB_HOST, $DB_PORT, $BB_KEY, $BB_SECRET, $BB_BUCKET, $BB_HOST

# Exit on error
set -e

# Validate that all required ENV vars are set
required_vars=(DB_NAME DB_USER DB_PASS DB_HOST DB_PORT BB_KEY BB_SECRET BB_BUCKET BB_HOST)
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "[db-backup] Error: $var is not set"
        exit 1
    fi
done

s3cmd_a() {
    s3cmd --access_key="$BB_KEY" --secret_key "$BB_SECRET" --host-bucket="$BB_HOST" "$@"
}

BACKUP_DIR="/backups"
BACKUP_FILE="$BACKUP_DIR/$DB_NAME-$BB_BUCKET"

# Remove the previous local backup copy
rm -f "$BACKUP_FILE"

# Dump the database using the password
PGPASSWORD=$DB_PASS pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" "$DB_NAME" | gzip > "$BACKUP_FILE"

# Upload the backup to Backblaze
s3cmd_a put "$BACKUP_FILE" "s3://$BB_BUCKET"

# Keep the 3 most recent backups
backups=$(s3cmd_a ls "s3://$BB_BUCKET")
file_names=$(echo "$backups" | awk '{print $4}' | grep "$DB_NAME")
file_count=$(echo "$file_names" | wc -l)
if [ "$file_count" -gt 3 ]; then
    old_files=$(echo "$file_names" | head -n -"$file_count")
    for old_file in $old_files; do
        s3cmd_a del "$old_file"
    done
fi

# Exit without error
exit 0