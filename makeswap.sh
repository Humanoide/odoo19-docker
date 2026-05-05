#!/usr/bin/env bash
set -euo pipefail

# Crea un swapfile de 3G (idempotente) y lo activa.
# Ubuntu 24.04 / Debian-like
SWAPFILE="/swapfile"
SIZE="3G"

if [[ "$(id -u)" -ne 0 ]]; then
  echo "Este script debe ejecutarse como root: sudo $0" >&2
  exit 1
fi

if swapon --show | awk '{print $1}' | grep -qx "$SWAPFILE"; then
  echo "Swap ya activo en $SWAPFILE. No se hace nada."
  exit 0
fi

if [[ -f "$SWAPFILE" ]]; then
  echo "Existe $SWAPFILE pero no está activo. Reconfigurando..."
else
  echo "Creando swapfile de tamaño $SIZE en $SWAPFILE"
  fallocate -l "$SIZE" "$SWAPFILE"
  chmod 600 "$SWAPFILE"
  mkswap "$SWAPFILE" >/dev/null
fi

echo "Activando swap"
swapon "$SWAPFILE"

# Asegura persistencia en /etc/fstab
if ! grep -qE "^${SWAPFILE}[[:space:]]+none[[:space:]]+swap" /etc/fstab; then
  echo "Añadiendo entrada a /etc/fstab"
  echo "${SWAPFILE}   none    swap    sw    0   0" | tee -a /etc/fstab >/dev/null
else
  echo "Entrada de fstab ya existe."
fi

echo "OK: swap activo"
swapon --show

