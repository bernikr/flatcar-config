#!/usr/bin/env sh

set -e

# restore /data backup
cp -r /nas/backups/flatcar/data/* /data/
