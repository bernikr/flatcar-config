#!/usr/bin/env sh

cd /data
for dir in /data/*/
do
  cd "${dir}"
	docker compose up -d --remove-orphans
	cd ..
done
