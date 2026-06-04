#!/bin/bash

# =============================================================================
# execute_modules_install.sh – Clona repositorios OCA rama 19.0
# =============================================================================
# Lee modules_install_19.txt y clona cada repo con --depth 1 en la rama 19.0
# dentro de /data/compose/1/addons/
# Ignora líneas vacías y comentarios (#).
# Si el destino ya existe, hace git pull en lugar de clonar de nuevo.
# =============================================================================

set -euo pipefail

MODULES_FILE="$(dirname "${BASH_SOURCE[0]}")/modules_install_19.txt"
ADDONS_PATH="/data/compose/1/addons"
BRANCH="19.0"

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

  # Extraer URL del repo (puede haber texto extra al principio)
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
    git -C "${dest}" pull --ff-only 2>&1 && ((skipped++)) || {
      echo "⚠  No se pudo actualizar ${name} (continúa)"
      ((failed++))
    }
  else
    echo "⬇  Clonando (rama ${BRANCH}): ${repo}"
    if git clone --depth 1 --single-branch -b "${BRANCH}" "${repo}" "${dest}" 2>&1; then
      ((ok++))
    else
      echo "⚠  FALLO al clonar ${repo} (continúa)"
      ((failed++))
    fi
  fi

done < "${MODULES_FILE}"

echo ""
echo "════════════════════════════════════"
echo " Módulos OCA – resumen"
echo "  ✔ Clonados:     ${ok}"
echo "  ↻ Actualizados: ${skipped}"
echo "  ✗ Fallidos:     ${failed}"
echo "════════════════════════════════════"

if [[ "${failed}" -gt 0 ]]; then
  echo ""
  echo "⚠  Algunos repos fallaron (puede que la rama 19.0 aún no exista en OCA)."
  echo "   Revisa los mensajes anteriores y elimina o comenta esas líneas"
  echo "   en modules_install_19.txt antes de continuar."
  exit 1
fi
