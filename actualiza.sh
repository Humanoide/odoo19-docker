#!/bin/bash

CONTAINER="odoo18-web-1"

echo "========================================="
echo "  Actualizador de módulos Odoo (Docker)"
echo "========================================="
echo ""
read -p "Introduce el nombre de la base de datos: " DBNAME

if [ -z "$DBNAME" ]; then
    echo "❌ No has introducido ninguna base de datos. Abortando."
    exit 1
fi

echo ""
echo "🟦 Contenedor: $CONTAINER"
echo "🟦 Base de datos: $DBNAME"
echo ""

echo "🔧 Ejecutando actualización de módulos dentro del contenedor..."
echo ""

docker exec -it $CONTAINER odoo \
    --no-http \
    --workers=0 \
    --max-cron-threads=0 \
    --load=base,web \
    --db_host=odoo18-db-1 \
    --db_user=odoo \
    --db_password=odoo \
    --stop-after-init -u all -d "$DBNAME"

echo ""
echo "✅ Proceso completado."
