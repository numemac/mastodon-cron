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
    HOST_BUCKET="%(bucket)s.$BB_HOST"
    echo "s3cmd --access_key=$BB_KEY --secret_key=$BB_SECRET --host=$BB_HOST --host-bucket=$HOST_BUCKET ..."
    s3cmd --access_key="$BB_KEY" --secret_key="$BB_SECRET" --host="$BB_HOST" --host-bucket="$HOST_BUCKET" "$@"
}

BACKUP_DIR="/backups"
FILE_EXT="$BB_BUCKET.sql.gz"
UNIX_TIMESTAMP=$(date +%s)
BACKUP_FILE="$BACKUP_DIR/$UNIX_TIMESTAMP.$FILE_EXT"

# remove all previous backups in local dir with the same extension
rm -f "$BACKUP_DIR"/*."$FILE_EXT"

# Dump the database using the password, output progress to std out, and compress the output
PGPASSWORD=$DB_PASS pg_dump -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" -v | gzip > "$BACKUP_FILE"

# Upload the backup to Backblaze
s3cmd_a put "$BACKUP_FILE" "s3://$BB_BUCKET"

# Exit without error
exit 0