#!/usr/bin/env sh
set -e

if test -f /data/.setup; then
  echo "There is already data here, rm /data/.setup to continue"
  exit
fi

# restore /data backup
rsync -az --delete --info=progress2 /nas/backups/flatcar/data/ /data/ 2>&1

touch /data/.setup
