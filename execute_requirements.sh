#!/usr/bin/env bash

set -euo pipefail

CONTAINER="odoo19-web-1"
ADDONS_PATH="/mnt/extra-addons"
SCRIPT="requirements_oca.sh"

echo "== Comprobando contenedor =="
docker ps --format '{{.Names}}' | grep -qx "$CONTAINER" || {
    echo "❌ Contenedor $CONTAINER no está activo"
    exit 1
}

echo "== Ejecutando requirements OCA dentro del contenedor =="
docker exec -i "$CONTAINER" bash -c "
    set -e
    cd '$ADDONS_PATH' || exit 1

    if [ ! -f '$SCRIPT' ]; then
        echo '❌ No existe $SCRIPT en $ADDONS_PATH'
        exit 1
    fi

    echo '📦 Ejecutando requirements OCA...'
    bash '$SCRIPT'
"

echo "✔ Ejecución terminada"
