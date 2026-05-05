#!/bin/bash

### CONFIG ###
PORTAINER_URL="http://localhost:9000"
USERNAME="admin"
PASSWORD="000000000000"
ENDPOINT_ID="3"
STACK_NAME="odoo18"
COMPOSE_FILE="odoo18-docker-compose.yml"

echo "🚀 Iniciando despliegue Odoo 18 en Portainer..."

# -----------------------------
# 1. Comprobar jq
# -----------------------------
if ! command -v jq >/dev/null 2>&1; then
  echo "📦 jq no está instalado. Instalando..."
  apt update && apt install jq -y
fi

# -----------------------------
# 2. Obtener TOKEN
# -----------------------------
echo "🔑 Obteniendo token..."

TOKEN=$(curl -s -X POST "$PORTAINER_URL/api/auth" \
  -H "Content-Type: application/json" \
  -d "{\"Username\":\"$USERNAME\",\"Password\":\"$PASSWORD\"}" | jq -r .jwt)

if [ -z "$TOKEN" ] || [ "$TOKEN" == "null" ]; then
  echo "❌ Error: no se pudo obtener el token"
  exit 1
fi

echo "✔ Token OK"

# -----------------------------
# 3. Comprobar docker-compose
# -----------------------------
if [ ! -f "$COMPOSE_FILE" ]; then
  echo "❌ No existe $COMPOSE_FILE"
  exit 1
fi

# -----------------------------
# 4. Crear STACK
# -----------------------------
echo "📦 Creando stack $STACK_NAME..."

RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -X POST \
  "$PORTAINER_URL/api/stacks/create/standalone/string?endpointId=$ENDPOINT_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"Name\":\"$STACK_NAME\",\"StackFileContent\":$(jq -Rs . $COMPOSE_FILE)}")

HTTP_CODE=$(echo "$RESPONSE" | grep HTTP_CODE | cut -d: -f2)
BODY=$(echo "$RESPONSE" | sed '/HTTP_CODE/d')

echo "------------------------"
echo "HTTP: $HTTP_CODE"
echo "$BODY"
echo "------------------------"

if [ "$HTTP_CODE" == "200" ] || [ "$HTTP_CODE" == "201" ]; then
  echo "🎉 Stack creado correctamente"
else
  echo "❌ Error creando stack"
fi
