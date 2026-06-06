#!/bin/bash

# =============================================================================
# crea_proxy_npm.sh – Crea los 4 proxy hosts en Nginx Proxy Manager
# =============================================================================

NPM_URL="http://localhost:81"
NPM_EMAIL="fgarcia@humanoide.es"
NPM_PASSWORD="000000000000"

# ── Pedir proyecto y dominio base ─────────────────────────────────────────────
read -rp "Nombre del proyecto (ej: demo): " PROYECTO
read -rp "Dominio base (ej: aplicacionodoo.com): " DOMINIO_BASE

if [[ -z "$PROYECTO" || -z "$DOMINIO_BASE" ]]; then
    echo "❌ Debes indicar el nombre del proyecto y el dominio base"
    exit 1
fi

HOST_IP=$(hostname -I | awk '{print $1}')

# Dominios generados
DOMINIO_ODOO="${PROYECTO}.${DOMINIO_BASE}"
DOMINIO_NPM="nginx.${PROYECTO}.${DOMINIO_BASE}"
DOMINIO_PORTAINER="portainer.${PROYECTO}.${DOMINIO_BASE}"
DOMINIO_WEBMIN="webmin.${PROYECTO}.${DOMINIO_BASE}"

echo ""
echo "== Configuración =="
echo "   Odoo:      https://${DOMINIO_ODOO}      → http://${HOST_IP}:8069"
echo "   NPM:       https://${DOMINIO_NPM}  → http://${HOST_IP}:81"
echo "   Portainer: https://${DOMINIO_PORTAINER} → http://${HOST_IP}:9000"
echo "   Webmin:    https://${DOMINIO_WEBMIN}   → https://${HOST_IP}:10000"
echo ""

# ── Autenticarse ──────────────────────────────────────────────────────────────
echo "== Autenticando en NPM =="
AUTH_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/tokens" \
    -H "Content-Type: application/json" \
    -d "{\"identity\": \"${NPM_EMAIL}\", \"secret\": \"${NPM_PASSWORD}\"}")

TOKEN=$(echo "$AUTH_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['token'])" 2>/dev/null)

if [[ -z "$TOKEN" ]]; then
    echo "❌ No se pudo obtener token. Comprueba usuario/contraseña de NPM"
    echo "$AUTH_RESPONSE"
    exit 1
fi
echo "✔ Token obtenido"

# ── Función para crear proxy host ─────────────────────────────────────────────
crear_proxy() {
    local DOMINIO="$1"
    local PUERTO="$2"
    local SCHEME="$3"   # http o https

    echo ""
    echo "── Creando proxy: ${DOMINIO} → ${SCHEME}://${HOST_IP}:${PUERTO}"

    RESPONSE=$(curl -s -X POST "${NPM_URL}/api/nginx/proxy-hosts" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        -d "{
            \"domain_names\": [\"${DOMINIO}\"],
            \"forward_scheme\": \"${SCHEME}\",
            \"forward_host\": \"${HOST_IP}\",
            \"forward_port\": ${PUERTO},
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

    PROXY_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

    if [[ -z "$PROXY_ID" ]]; then
        echo "   ❌ Error al crear proxy para ${DOMINIO}"
        echo "   $RESPONSE"
        return 1
    fi

    # Solicitar certificado SSL
    CERT_RESPONSE=$(curl -s -X POST "${NPM_URL}/api/nginx/certificates" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        -d "{
            \"provider\": \"letsencrypt\",
            \"domain_names\": [\"${DOMINIO}\"],
            \"meta\": {
                \"letsencrypt_agree\": true,
                \"letsencrypt_email\": \"${NPM_EMAIL}\"
            }
        }")

    CERT_ID=$(echo "$CERT_RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])" 2>/dev/null)

    if [[ -z "$CERT_ID" ]]; then
        echo "   ⚠  Sin SSL (¿DNS propagado?). Proxy HTTP activo en ID: ${PROXY_ID}"
        return 0
    fi

    # Actualizar proxy con SSL
    curl -s -X PUT "${NPM_URL}/api/nginx/proxy-hosts/${PROXY_ID}" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${TOKEN}" \
        -d "{
            \"domain_names\": [\"${DOMINIO}\"],
            \"forward_scheme\": \"${SCHEME}\",
            \"forward_host\": \"${HOST_IP}\",
            \"forward_port\": ${PUERTO},
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
        }" > /dev/null

    echo "   ✔ https://${DOMINIO} (SSL ID: ${CERT_ID})"
}

# ── Crear los 4 proxies ───────────────────────────────────────────────────────
crear_proxy "$DOMINIO_ODOO"      8069  "http"
crear_proxy "$DOMINIO_NPM"       81    "http"
crear_proxy "$DOMINIO_PORTAINER" 9000  "http"
crear_proxy "$DOMINIO_WEBMIN"    10000 "https"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  Proxies configurados para proyecto: ${PROYECTO}"
echo "╠══════════════════════════════════════════════════════════════╣"
echo "║  Odoo:      https://${DOMINIO_ODOO}"
echo "║  NPM:       https://${DOMINIO_NPM}"
echo "║  Portainer: https://${DOMINIO_PORTAINER}"
echo "║  Webmin:    https://${DOMINIO_WEBMIN}"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
