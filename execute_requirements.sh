#!/usr/bin/env bash

# =============================================================================
# execute_requirements.sh – Instala librerías Python OCA en el contenedor odoo19
# =============================================================================
# Entra en el contenedor Docker de Odoo 19 y ejecuta requirements_oca.sh
# desde el directorio de addons montado en el contenedor.
# =============================================================================

set -euo pipefail

CONTAINER="odoo19"
ADDONS_PATH="/mnt/extra-addons"
SCRIPT="requirements_oca.sh"

echo "== Comprobando contenedor =="
docker ps --format '{{.Names}}' | grep -qx "${CONTAINER}" || {
  echo "❌ El contenedor '${CONTAINER}' no está activo."
  echo "   Asegúrate de que el stack de Odoo 19 está levantado en Portainer."
  exit 1
}

echo "== Ejecutando requirements OCA dentro del contenedor =="
docker exec -i "${CONTAINER}" bash -c "
  set -e
  cd '${ADDONS_PATH}' || { echo '❌ No existe la ruta ${ADDONS_PATH} en el contenedor'; exit 1; }

  if [ ! -f '${SCRIPT}' ]; then
    echo '❌ No existe ${SCRIPT} en ${ADDONS_PATH}'
    exit 1
  fi

  echo '📦 Ejecutando requirements OCA...'
  bash '${SCRIPT}'
"

echo "✔ Ejecución terminada"
