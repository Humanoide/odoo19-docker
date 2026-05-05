#!/usr/bin/env bash
set -euo pipefail

# Orquestador: ejecuta en orden
# 1) makeswap.sh
# 2) docker-portainer.sh
# 3) webmin_install.sh
#
# Guarda logs por paso en ./logs y permite reanudar por "marcas" en ./state

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
STATE_DIR="${SCRIPT_DIR}/state"

mkdir -p "$LOG_DIR" "$STATE_DIR"

ts() { date +"%Y-%m-%d %H:%M:%S"; }
die() { echo "[$(ts)] ERROR: $*" >&2; exit 1; }

run_step() {
  local step="$1"
  local script="$2"
  local stamp="${STATE_DIR}/${step}.done"
  local log="${LOG_DIR}/${step}.log"

  [[ -f "$script" ]] || die "No existe el script: $script"

  if [[ -f "$stamp" ]]; then
    echo "[$(ts)] SKIP (ya hecho): $step"
    return 0
  fi

  echo "[$(ts)] START: $step"
  echo "[$(ts)] RUN: sudo $script" | tee -a "$log"
  sudo bash "$script" 2>&1 | tee -a "$log"
  touch "$stamp"
  echo "[$(ts)] OK: $step"
}

run_step "00_makeswap"         "${SCRIPT_DIR}/makeswap.sh"
run_step "10_docker_portainer" "${SCRIPT_DIR}/docker-portainer.sh"
run_step "20_webmin_install"   "${SCRIPT_DIR}/webmin_install.sh"

echo "[$(ts)] TODO COMPLETADO ✅"
echo "Logs:  $LOG_DIR"
echo "State: $STATE_DIR (borra *.done para re-ejecutar un paso)"
