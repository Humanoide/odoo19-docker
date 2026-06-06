#!/bin/bash

# =============================================================================
# crea_proxy_npm.sh – Crea un proxy host en Nginx Proxy Manager vía API
# =============================================================================

NPM_URL="http://localhost:81"
NPM_EMAIL="fgarcia@humanoide.es"
NPM_PASSWORD="000000000000"
ODOO_PORT="8069"

# IP del host (primera IP de la interfaz principal)
HOST_IP=$(hostname -I | awk '{print $1}')

# ── Pedir dominio ─────────────────────────────────────────────────────────────
if [[ -n "$1" ]]; then
    DOMAIN="$1"
else
    read -rp "Dominio a configurar (ej: cliente.humanoide.es): " DOMAIN
fi

if [[ -z "$DOMAIN" ]]; then
    echo "❌ Debes indicar un dominio"
    exit 1
fi

echo ""
echo "== Configurando proxy para: $DOMAIN → $HOST_IP:$ODOO_PORT =="

# ── Autenticarse y obtener token ──────────────────────────────────────────────
echo "== Autenticando en NPM =="
AUTH_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/tokens" \
    -H "Content-Type: application/json" \
    -d "{
        \"identity\": \"${NPM_EMAIL}\",
        \"secret\": \"${NPM_PASSWORD}\"
    }")

TOKEN=$(echo "$AUTH_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
    echo "❌ No se pudo obtener token. Comprueba usuario/contraseña de NPM"
    echo "$AUTH_RESPONSE"
    exit 1
fi
echo "✔ Token obtenido"

# ── Crear proxy host ──────────────────────────────────────────────────────────
echo "== Creando proxy host =="
PROXY_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/nginx/proxy-hosts" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "{
        \"domain_names\": [\"${DOMAIN}\"],
        \"forward_scheme\": \"http\",
        \"forward_host\": \"${HOST_IP}\",
        \"forward_port\": ${ODOO_PORT},
        \"access_list_id\": 0,
        \"certificate_id\": 0,
        \"ssl_forced\": false,
        \"hsts_enabled\": false,
        \"hsts_subdomains\": false,
        \"http2_support\": false,
        \"block_exploits\": true,
        \"caching_enabled\": false,
        \"allow_websocket_upgrade\": true,
        \"locations\": [],
        \"advanced_config\": \"\"
    }")

PROXY_ID=$(echo "$PROXY_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

if [[ -z "$PROXY_ID" ]]; then
    echo "❌ Error al crear el proxy host"
    echo "$PROXY_RESPONSE"
    exit 1
fi
echo "✔ Proxy host creado (ID: $PROXY_ID)"

# ── Solicitar certificado SSL Let's Encrypt ───────────────────────────────────
echo "== Solicitando certificado SSL para $DOMAIN =="
CERT_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/nginx/certificates" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "{
        \"provider\": \"letsencrypt\",
        \"domain_names\": [\"${DOMAIN}\"],
        \"meta\": {
            \"letsencrypt_agree\": true,
            \"letsencrypt_email\": \"${NPM_EMAIL}\"
        }
    }")

CERT_ID=$(echo "$CERT_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

if [[ -z "$CERT_ID" ]]; then
    echo "⚠  No se pudo obtener certificado SSL (¿el dominio apunta ya a este servidor?)"
    echo "   El proxy HTTP está activo pero sin SSL."
    echo "   Puedes añadir el certificado manualmente desde la interfaz de NPM."
    exit 0
fi
echo "✔ Certificado SSL obtenido (ID: $CERT_ID)"

# ── Actualizar proxy host con el certificado SSL ──────────────────────────────
echo "== Activando SSL en el proxy host =="
UPDATE_RESPONSE=$(curl -s -X PUT "${NPM_URL}/api/nginx/proxy-hosts/${PROXY_ID}" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer ${TOKEN}" \
    -d "{
        \"domain_names\": [\"${DOMAIN}\"],
        \"forward_scheme\": \"http\",
        \"forward_host\": \"${HOST_IP}\",
        \"forward_port\": ${ODOO_PORT},
        \"access_list_id\": 0,
        \"certificate_id\": ${CERT_ID},
        \"ssl_forced\": true,
        \"hsts_enabled\": false,
        \"hsts_subdomains\": false,
        \"http2_support\": true,
        \"block_exploits\": true,
        \"caching_enabled\": false,
        \"allow_websocket_upgrade\": true,
        \"locations\": [],
        \"advanced_config\": \"\"
    }")

echo "✔ SSL activado"
echo ""
echo "════════════════════════════════════════════════"
echo " Proxy configurado correctamente"
echo "  Dominio:  https://${DOMAIN}"
echo "  Destino:  http://${HOST_IP}:${ODOO_PORT}"
echo "  SSL:      Let's Encrypt (ID: ${CERT_ID})"
echo "════════════════════════════════════════════════"
