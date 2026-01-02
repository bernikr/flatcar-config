#!/usr/bin/env sh

SOURCE_DIR="/data"
SNAP_DIR="/data/.snapshots"
DEST_DIR="/nas/backups/flatcar/data"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
SNAP_NAME="backup_$TIMESTAMP"
LOG_FILE="/var/log/backup.log"

# Ensure script runs as root
if [ "$EUID" -ne 0 ]; then 
  echo "Please run as root"
  exit 1
fi

# 1. Create snapshot directory if it doesn't exist
mkdir -p "$SNAP_DIR"

echo "--- Backup Started: $(date) ---" >> "$LOG_FILE"

# 2. Create a Read-Only Btrfs Snapshot
# This is instant and takes 0 space initially
echo "Creating snapshot: $SNAP_NAME" >> "$LOG_FILE"
btrfs subvolume snapshot -r "$SOURCE_DIR" "$SNAP_DIR/$SNAP_NAME" >> "$LOG_FILE"

# 3. Trigger the SMB Automount
# Since you used systemd.automount, simply accessing the path triggers the connection
if [ ! -d "$DEST_DIR" ]; then
    echo "Creating destination directory..." >> "$LOG_FILE"
    mkdir -p "$DEST_DIR"
fi

# 4. Sync data to NAS
# -a: archive mode, -v: verbose, -z: compress, --delete: remove files at dest not in source
echo "Syncing data to NAS..." >> "$LOG_FILE"
rsync -avz --delete --exclude='.snapshots' "$SNAP_DIR/$SNAP_NAME/" "$DEST_DIR/" >> "$LOG_FILE" 2>&1

# 5. Check if rsync was successful
if [ $? -eq 0 ]; then
    echo "Sync successful." >> "$LOG_FILE"
else
    echo "ERROR: Sync failed." >> "$LOG_FILE"
fi

# 6. Cleanup: Remove the local snapshot
echo "Deleting local snapshot..." >> "$LOG_FILE"
btrfs subvolume delete "$SNAP_DIR/$SNAP_NAME" >> "$LOG_FILE"

echo "--- Backup Finished: $(date) ---" >> "$LOG_FILE"
