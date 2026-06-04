#!/bin/bash

# =============================================================================
# execute_modules_install.sh – Clona repositorios OCA rama 19.0
# =============================================================================
# Lee modules_install_19.txt y clona cada repo con --depth 1 en la rama 19.0
# dentro de /data/compose/1/addons/
# Ignora líneas vacías y comentarios (#).
# Si el destino ya existe, hace git pull en lugar de clonar de nuevo.
# Los repos que fallen (ej: rama 19.0 aún no existe en OCA) se registran
# como advertencia pero NO abortan el proceso.
# =============================================================================

set -uo pipefail
# Nota: sin -e para que los fallos de git no abortan el script

MODULES_FILE="$(dirname "${BASH_SOURCE[0]}")/modules_install_19.txt"
ADDONS_PATH="/data/compose/1/addons"
BRANCH="19.0"
FAILED_REPOS=()

if [[ ! -f "${MODULES_FILE}" ]]; then
  echo "❌ No se encuentra el fichero de módulos: ${MODULES_FILE}"
  exit 1
fi

mkdir -p "${ADDONS_PATH}"

ok=0
skipped=0
failed=0

while IFS= read -r line || [[ -n "${line}" ]]; do
  # Ignorar líneas vacías y comentarios
  [[ -z "${line}" || "${line}" == \#* ]] && continue

  repo=$(echo "${line}" | awk '{for(i=1;i<=NF;i++) if ($i ~ /^https?:\/\//) print $i}')
  repo=$(echo "${repo}" | tr -d '\r' | xargs)

  if [[ -z "${repo}" ]]; then
    echo "⚠  Línea ignorada (sin URL): ${line}"
    continue
  fi

  name=$(basename "${repo}" .git)
  dest="${ADDONS_PATH}/${name}"

  if [[ -d "${dest}" ]]; then
    echo "↻  Ya existe, actualizando: ${name}"
    if git -C "${dest}" pull --ff-only 2>&1; then
      ((skipped++))
    else
      echo "⚠  No se pudo actualizar ${name}"
      FAILED_REPOS+=("${repo}")
      ((failed++))
    fi
  else
    echo "⬇  Clonando (rama ${BRANCH}): ${repo}"
    if git clone --depth 1 --single-branch -b "${BRANCH}" "${repo}" "${dest}" 2>&1; then
      ((ok++))
    else
      echo "⚠  FALLO al clonar ${repo} (rama ${BRANCH} no disponible aún, se omite)"
      # Limpiar directorio vacío si lo creó git
      [[ -d "${dest}" ]] && rm -rf "${dest}"
      FAILED_REPOS+=("${repo}")
      ((failed++))
    fi
  fi

done < "${MODULES_FILE}"

echo ""
echo "════════════════════════════════════════════════════"
echo " Módulos OCA – resumen"
echo "  ✔ Clonados:     ${ok}"
echo "  ↻ Actualizados: ${skipped}"
echo "  ✗ No disponibles en rama ${BRANCH}: ${failed}"
echo "════════════════════════════════════════════════════"

if [[ "${failed}" -gt 0 ]]; then
  echo ""
  echo "⚠  Los siguientes repos no tienen aún rama ${BRANCH} en OCA:"
  for r in "${FAILED_REPOS[@]}"; do
    echo "   - ${r}"
  done
  echo ""
  echo "   Puedes comentarlos con # en modules_install_19.txt"
  echo "   y volver a ejecutar este script cuando estén disponibles."
  echo ""
  echo "   ⚡ La instalación CONTINÚA con los repos disponibles."
fi

# Salida siempre 0 para no abortar el orquestador
exit 0
