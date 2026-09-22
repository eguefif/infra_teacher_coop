#!/bin/sh

docker service create \
  --name migration \
  --restart-condition none \
  --add-host host.docker.internal:host-gateway \
  --secret database_url \
  --secret secret_key_base \
  --secret meili_master_key \
  eguefif/teacher_coop:20260919130041 \
  sh -c 'export DATABASE_URL="$(cat /run/secrets/database_url)"; export SECRET_KEY_BASE="$(cat /run/secrets/secret_key_base)"; export MEILISEARCH_MASTERKEY="$(cat /run/secrets/meili_master_key)"; exec /app/bin/migrate'
