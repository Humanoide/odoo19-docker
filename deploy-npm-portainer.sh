#!/usr/bin/env bash
set -euo pipefail

PORTAINER_URL="http://localhost:9000"
USER="admin"
PASS="000000000000"
STACK_FILE="npm-compose.yml"

echo "== LOGIN =="

TOKEN=$(curl -s -X POST "$PORTAINER_URL/api/auth" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$USER\",\"Password\":\"$PASS\"}" \
  | jq -r .jwt)

if [[ -z "$TOKEN" || "$TOKEN" == "null" ]]; then
  echo "❌ No token"
  exit 1
fi

echo "== GET ENDPOINT =="

ENDPOINT_ID=$(curl -s "$PORTAINER_URL/api/endpoints" \
  -H "Authorization: Bearer $TOKEN" \
  | jq -r '.[0].Id')

echo "Endpoint ID: $ENDPOINT_ID"

echo "== DEPLOY STACK NPM =="

curl -s -X POST \
  "$PORTAINER_URL/api/stacks/create/standalone/file?endpointId=$ENDPOINT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -F "Name=npm" \
  -F "file=@$STACK_FILE"

echo "✅ Stack enviado correctamente"
