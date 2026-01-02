#!/usr/bin/env sh

set -e

# restore /data backup
rsync -az --info=progress2 /nas/backups/flatcar/data/ /data/ 2>&1
