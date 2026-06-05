#!/usr/bin/env bash

set -euo pipefail

CONTAINER="odoo19-web-1"
ADDONS_PATH="/mnt/extra-addons"
SCRIPT="requirements_oca.sh"
MAX_WAIT=120  # segundos máximo esperando

echo "== Esperando a que el contenedor esté listo =="
elapsed=0
until docker ps --format '{{.Names}}\t{{.Status}}' | grep -q "^${CONTAINER}.*Up"; do
    if [ "$elapsed" -ge "$MAX_WAIT" ]; then
        echo "❌ El contenedor $CONTAINER no arrancó en ${MAX_WAIT}s"
        exit 1
    fi
    echo "   Esperando... (${elapsed}s)"
    sleep 5
    elapsed=$((elapsed + 5))
done
echo "✔ Contenedor listo"

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
