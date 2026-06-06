#!/bin/bash

# =============================================================================
# crea_base_datos.sh – Crea bases de datos en Odoo 19 vía API
# =============================================================================

ODOO_URL="http://localhost:8069"
MASTER_PWD="000000000000"
ADMIN_PWD="000000000000"
LANG="es_ES"
COUNTRY="es"

crear_bd() {
    local DB_NAME="$1"

    echo ""
    echo "== Creando base de datos '$DB_NAME' =="

    RESPONSE=$(curl -s -o /tmp/odoo_create_response.txt -w "%{http_code}" \
        -X POST "${ODOO_URL}/web/database/create" \
        -F "master_pwd=${MASTER_PWD}" \
        -F "name=${DB_NAME}" \
        -F "login=admin" \
        -F "password=${ADMIN_PWD}" \
        -F "lang=${LANG}" \
        -F "country_code=${COUNTRY}" \
        -F "phone=")

    BODY=$(cat /tmp/odoo_create_response.txt)

    if [[ "$RESPONSE" == "200" ]] && ! echo "$BODY" | grep -qi "error"; then
        echo "✔ '$DB_NAME' creada correctamente (sin datos demo)"
        echo "   URL:      ${ODOO_URL}/web?db=${DB_NAME}"
        echo "   Usuario:  admin"
        echo "   Password: ${ADMIN_PWD}"
    else
        echo "❌ HTTP $RESPONSE al crear '$DB_NAME'"
        echo "$BODY"
        return 1
    fi
}

crear_bd "plantilla"

echo ""
echo "== Proceso finalizado =="
