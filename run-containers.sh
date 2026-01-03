#!/usr/bin/env sh

for dir in /data/*/
do
  cd "${dir}"
  docker compose up -d --remove-orphans
done
