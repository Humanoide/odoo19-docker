#!/bin/bash

# =============================================================================
# instala_modulos_plantilla.sh – Instala módulos en la BD plantilla de Odoo 19
# =============================================================================
# Lee modulos_plantilla.txt, construye la lista separada por comas
# y lanza odoo con -i dentro del contenedor.
# =============================================================================

CONTAINER="odoo19-web-1"
DB="plantilla"
MODULOS_FILE="$(dirname "${BASH_SOURCE[0]}")/modulos_plantilla.txt"

if [[ ! -f "$MODULOS_FILE" ]]; then
    echo "❌ No se encuentra: $MODULOS_FILE"
    exit 1
fi

# Construir lista separada por comas ignorando líneas vacías y comentarios
MODULOS=$(grep -v '^\s*#' "$MODULOS_FILE" | grep -v '^\s*$' | tr '\n' ',' | sed 's/,$//')

if [[ -z "$MODULOS" ]]; then
    echo "❌ El fichero de módulos está vacío o todo comentado"
    exit 1
fi

echo "== Comprobando contenedor =="
until docker ps --format '{{.Names}}\t{{.Status}}' | grep -q "^${CONTAINER}.*Up"; do
    echo "   Esperando a que el contenedor esté listo..."
    sleep 5
done
echo "✔ Contenedor listo"

echo ""
echo "== Instalando módulos en BD '$DB' =="
echo "   Módulos: $(echo $MODULOS | tr ',' '\n' | wc -l) módulos"
echo ""

docker exec -i "$CONTAINER" bash -c "
    odoo -d $DB -i $MODULOS --stop-after-init 2>&1
"

echo ""
echo "✔ Instalación de módulos completada"
