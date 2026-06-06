#!/bin/bash

# =============================================================================
# crea_base_datos.sh – Crea bases de datos en Odoo 19 vía API
# =============================================================================

ODOO_URL="http://localhost:8069"
MASTER_PWD="000000000000"
ADMIN_PWD="000000000000"
LANG="es_ES"
COUNTRY="es"
DEMO_DATA="false"

crear_bd() {
    local DB_NAME="$1"

    echo ""
    echo "== Creando base de datos '$DB_NAME' =="

    RESPONSE=$(curl -s -o /tmp/odoo_create_response.txt -w "%{http_code}" \
        -X POST "${ODOO_URL}/web/database/create" \
        -H "Content-Type: application/json" \
        -d "{
            \"jsonrpc\": \"2.0\",
            \"method\": \"call\",
            \"params\": {
                \"master_pwd\": \"${MASTER_PWD}\",
                \"name\": \"${DB_NAME}\",
                \"login\": \"admin\",
                \"password\": \"${ADMIN_PWD}\",
                \"lang\": \"${LANG}\",
                \"country_code\": \"${COUNTRY}\",
                \"phone\": \"\",
                \"demo\": ${DEMO_DATA}
            }
        }")

    BODY=$(cat /tmp/odoo_create_response.txt)

    if echo "$BODY" | grep -q '"error"'; then
        echo "❌ Error al crear '$DB_NAME':"
        echo "$BODY" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('error',{}).get('data',{}).get('message','Error desconocido'))" 2>/dev/null || echo "$BODY"
        return 1
    fi

    if [ "$RESPONSE" = "200" ]; then
        echo "✔ '$DB_NAME' creada correctamente"
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
